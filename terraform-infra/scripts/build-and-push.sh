#!/bin/bash
# Build frontend and backend images and push them to ECR.
#
# Usage:
#   terraform-infra/scripts/build-and-push.sh [tag]
#
# tag defaults to the short git SHA of HEAD. Tags are immutable in ECR,
# so an existing tag is skipped rather than overwritten.
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
status()  { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
fail()    { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform-infra/dev"

for cmd in docker aws terraform git; do
  command -v "$cmd" >/dev/null 2>&1 || fail "$cmd not found"
done
[ -d "$PROJECT_ROOT/frontend" ] && [ -d "$PROJECT_ROOT/backend" ] \
  || fail "Expected $PROJECT_ROOT/{frontend,backend}"

if [ -n "${1:-}" ]; then
  TAG="$1"
else
  if [ -n "$(git -C "$PROJECT_ROOT" status --porcelain -- . ':!**/image_tag.auto.tfvars')" ]; then
    fail "Working tree has uncommitted changes. Commit first, or pass an explicit tag."
  fi
  TAG="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD)"
fi
[ "$TAG" = "latest" ] && fail "Refusing to push 'latest'. Use a versioned tag."

status "Reading ECR repositories from Terraform outputs"
FRONTEND_REPO="$(terraform -chdir="$TF_DIR" output -raw frontend_ecr_repository_url 2>/dev/null)" \
  || fail "frontend_ecr_repository_url output missing. Run: terraform apply -target=module.ecr"
BACKEND_REPO="$(terraform -chdir="$TF_DIR" output -raw backend_ecr_repository_url 2>/dev/null)" \
  || fail "backend_ecr_repository_url output missing. Run: terraform apply -target=module.ecr"
REGION="$(terraform -chdir="$TF_DIR" output -raw region 2>/dev/null)" || fail "region output missing"
REGISTRY="${FRONTEND_REPO%%/*}"

status "Logging in to $REGISTRY"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY" >/dev/null
success "Logged in to ECR"

build_and_push() {
  local name="$1" context="$2" repo="$3"
  local image="$repo:$TAG"

  if aws ecr describe-images --region "$REGION" \
       --repository-name "${repo#*/}" --image-ids imageTag="$TAG" >/dev/null 2>&1; then
    warn "$name: $image already exists, skipping"
    return
  fi

  status "$name: building $image"
  docker build --platform linux/amd64 -t "$image" "$context"

  status "$name: pushing $image"
  docker push "$image"
  success "$name: pushed $image"
}

build_and_push "backend"  "$PROJECT_ROOT/backend"  "$BACKEND_REPO"
build_and_push "frontend" "$PROJECT_ROOT/frontend" "$FRONTEND_REPO"

echo ""
success "Images ready with tag: $TAG"
echo "Deploy it with: terraform-infra/scripts/deploy.sh $TAG"