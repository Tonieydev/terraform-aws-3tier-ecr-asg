#!/bin/bash
# Backend bootstrap: rendered by Terraform templatefile().
# Terraform interpolates dollar-brace expressions; shell variables use $NAME (no braces).
# Write a literal dollar-brace as $$ followed by a brace.
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

log() { echo "[$(date '+%F %T')] $*"; }
retry() {
  local n=0
  until "$@"; do
    n=$((n + 1))
    [ "$n" -ge 10 ] && return 1
    sleep 10
  done
}

export DEBIAN_FRONTEND=noninteractive
REGION="${region}"
CONTAINER="goal-tracker-backend"
LOG_GROUP="/aws/ec2/${environment}-${project}/backend"

log "Installing packages"
retry apt-get update -y
apt-get install -y docker.io jq curl unzip

# Log rotation must exist before Docker first starts
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
EOF
systemctl enable --now docker
usermod -aG docker ubuntu

if ! command -v aws >/dev/null 2>&1; then
  log "Installing AWS CLI v2"
  retry curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# IMDSv2
IMDS_TOKEN=$(curl -fsS -X PUT http://169.254.169.254/latest/api/token \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')
INSTANCE_ID=$(curl -fsS -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

log "Logging in to ECR"
ecr_login() {
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "${ecr_registry}"
}
retry ecr_login

log "Fetching database credentials"
SECRET=$(retry aws secretsmanager get-secret-value \
  --region "$REGION" --secret-id "${db_secret_arn}" \
  --query SecretString --output text)
DB_USERNAME=$(jq -r '.username // empty' <<<"$SECRET")
DB_PASSWORD=$(jq -r '.password // empty' <<<"$SECRET")
if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
  log "ERROR: secret is missing username or password"
  exit 1
fi

log "Pulling ${docker_image}"
retry docker pull "${docker_image}"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p 8080:8080 \
  --log-driver awslogs \
  --log-opt awslogs-region="$REGION" \
  --log-opt awslogs-group="$LOG_GROUP" \
  --log-opt awslogs-stream="$INSTANCE_ID/app" \
  -e PORT=8080 \
  -e SSL=require \
  -e DB_HOST="${db_host}" \
  -e DB_PORT="${db_port}" \
  -e DB_NAME="${db_name}" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  "${docker_image}"
unset SECRET DB_USERNAME DB_PASSWORD

log "Waiting for backend health"
for i in $(seq 1 30); do
  if curl -fsS -o /dev/null http://localhost:8080/goals; then
    log "Backend healthy"
    break
  fi
  if [ "$i" -eq 30 ]; then
    log "ERROR: backend did not become healthy"
    docker logs --tail 100 "$CONTAINER" || true
    exit 1
  fi
  sleep 5
done

log "Installing CloudWatch agent"
retry curl -fsSL https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
rm -f /tmp/amazon-cloudwatch-agent.deb

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/${environment}-${project}/backend",
            "log_stream_name": "{instance_id}/user-data"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${environment}/${project}/Backend",
    "append_dimensions": { "AutoScalingGroupName": "$${aws:AutoScalingGroupName}", "InstanceId": "$${aws:InstanceId}" },
    "metrics_collected": {
      "cpu":  { "measurement": [{ "name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent" }], "metrics_collection_interval": 60 },
      "mem":  { "measurement": [{ "name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent" }], "metrics_collection_interval": 60 },
      "disk": { "measurement": [{ "name": "used_percent", "rename": "DISK_USED", "unit": "Percent" }], "resources": ["/"], "metrics_collection_interval": 60 }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

log "Backend bootstrap complete"
