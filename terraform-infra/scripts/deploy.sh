#!/bin/bash
# Full deployment: ECR repositories -> images -> infrastructure.
#
# Usage:
#   terraform-infra/scripts/deploy.sh [tag]
#
# tag defaults to the short git SHA of HEAD. It is written to
# image_tag.auto.tfvars so later plain `terraform apply` runs keep the
# same release instead of drifting. Commit that file.
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
status()  { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
fail()    { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform-infra/environments/dev"

status "Checking prerequisites"
for cmd in terraform aws docker git; do
  command -v "$cmd" >/dev/null 2>&1 || fail "$cmd not found"
done
aws sts get-caller-identity >/dev/null 2>&1 || fail "AWS credentials not configured"
success "Prerequisites met"

cd "$TF_DIR"

status "Initialising and validating"
terraform init -input=false
terraform validate
success "Configuration valid"

# Step 1: the registry must exist before images can be pushed,
# and images must exist before the ASGs launch instances.
status "Ensuring ECR repositories exist"
terraform apply -target=module.ecr -input=false -auto-approve
success "ECR repositories ready"

# Step 2: build and push
if [ -n "${1:-}" ]; then
  TAG="$1"
else
  if [ -n "$(git -C "$PROJECT_ROOT" status --porcelain -- . ':!**/image_tag.auto.tfvars')" ]; then
    fail "Working tree has uncommitted changes. Commit first, or pass an explicit tag."
  fi
  TAG="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD)"
fi
"$SCRIPT_DIR/build-and-push.sh" "$TAG"

echo "image_tag = \"$TAG\"" > image_tag.auto.tfvars
success "Release pinned to $TAG (image_tag.auto.tfvars)"

# Step 3: full plan and apply
status "Planning"
terraform plan -input=false -out=tfplan

echo ""
warn "Review the plan above. Applying will create or change billable AWS resources."
read -r -p "Proceed? (yes/no) " REPLY
if [ "$REPLY" != "yes" ]; then
  rm -f tfplan
  warn "Deployment cancelled"
  exit 0
fi

terraform apply -input=false tfplan
rm -f tfplan

echo ""
success "Deployed $TAG"
terraform output helpful_commands
echo ""
echo "Application: $(terraform output -raw application_url)"
echo "Instance refresh rolls new instances automatically. Allow 5-10 minutes."
