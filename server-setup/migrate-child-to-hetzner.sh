#!/bin/bash

################################################################################
# Migrate Child CMS Repository from Uberspace to Hetzner
#
# This script automates the migration of a child CMS repository to Hetzner VPS
#
# Usage: ./migrate-child-to-hetzner.sh <repo-path> <domain> <netlify-hook>
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
CHILD_REPO_PATH=$1
DOMAIN=$2
NETLIFY_HOOK=$3

if [ -z "$CHILD_REPO_PATH" ] || [ -z "$DOMAIN" ] || [ -z "$NETLIFY_HOOK" ]; then
    log_error "Usage: ./migrate-child-to-hetzner.sh <repo-path> <domain> <netlify-hook>"
    echo ""
    echo "Example:"
    echo "  ./migrate-child-to-hetzner.sh \\"
    echo "    /Users/matthiashacksteiner/Sites/fifth-music \\"
    echo "    cms.fifth-music.com \\"
    echo "    https://api.netlify.com/build_hooks/YOUR_HOOK_ID"
    exit 1
fi

# Get absolute path
CHILD_REPO_PATH=$(cd "$CHILD_REPO_PATH" && pwd)

# Get script directory and template path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_DIR="$SCRIPT_DIR/.."

log_info "==================================================================="
log_info "  Migrating $(basename $CHILD_REPO_PATH) to Hetzner VPS"
log_info "==================================================================="
echo ""
log_info "Repository: $CHILD_REPO_PATH"
log_info "Domain: $DOMAIN"
log_info "Netlify Hook: ${NETLIFY_HOOK:0:50}..."
echo ""

# Confirm
read -p "Continue with migration? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Migration cancelled"
    exit 1
fi

cd "$CHILD_REPO_PATH"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    log_error "Not a git repository: $CHILD_REPO_PATH"
    exit 1
fi

# Get GitHub repository name
GITHUB_REPO=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')

if [ -z "$GITHUB_REPO" ]; then
    log_error "Could not determine GitHub repository name"
    exit 1
fi

log_info "GitHub Repository: $GITHUB_REPO"
echo ""

# Check if deploy-hetzner.yml exists in template
if [ ! -f "$TEMPLATE_DIR/.github/workflows/deploy-hetzner.yml" ]; then
    log_error "Template workflow not found at: $TEMPLATE_DIR/.github/workflows/deploy-hetzner.yml"
    echo ""
    echo "Template directory: $TEMPLATE_DIR"
    echo "Please ensure you're running this script from the cms.baukasten/server-setup directory"
    exit 1
fi

# Pull latest changes
log_info "Pulling latest changes from remote..."
git pull origin main || log_warn "Pull had conflicts or errors, continuing..."

# Copy workflow
log_info "Copying deploy-hetzner.yml workflow..."
mkdir -p .github/workflows
cp "$TEMPLATE_DIR/.github/workflows/deploy-hetzner.yml" .github/workflows/
log_info "✓ Workflow copied"

# Set GitHub secrets
log_info "Configuring GitHub secrets..."

echo "91.98.120.110" | gh secret set DEPLOYMENT_HOST -R "$GITHUB_REPO"
log_info "✓ Set DEPLOYMENT_HOST"

echo "kirbyuser" | gh secret set DEPLOYMENT_USER -R "$GITHUB_REPO"
log_info "✓ Set DEPLOYMENT_USER"

echo "$DOMAIN" | gh secret set DEPLOYMENT_PATH -R "$GITHUB_REPO"
log_info "✓ Set DEPLOYMENT_PATH = $DOMAIN"

echo "$NETLIFY_HOOK" | gh secret set DEPLOY_URL -R "$GITHUB_REPO"
log_info "✓ Set DEPLOY_URL"

# Set SSH keys from 1Password
log_info "Setting SSH keys from 1Password..."

op item get "Hetzner-kirbyuser" --fields "Private-Key" --reveal | sed '1d;$d' | gh secret set DEPLOY_KEY_PRIVATE -R "$GITHUB_REPO"
log_info "✓ Set DEPLOY_KEY_PRIVATE (Hetzner)"

op item get "SSH-Key uberspace" --fields "Private-Key" --reveal | sed '1d;$d' | gh secret set UBERSPACE_DEPLOY_KEY -R "$GITHUB_REPO"
log_info "✓ Set UBERSPACE_DEPLOY_KEY"

# Commit and push
log_info "Committing and pushing changes..."
git add .github/workflows/deploy-hetzner.yml
git commit -m "Add Hetzner VPS deployment"
git pull --rebase origin main || log_warn "Rebase had issues, trying regular push..."
git push origin main

log_info "==================================================================="
log_info "  Migration Initiated!"
log_info "==================================================================="
echo ""
log_info "✓ GitHub Actions deployment triggered"
echo ""
log_info "Waiting for GitHub Actions to complete (checking every 10 seconds)..."

# Wait for GitHub Actions to complete (with timeout)
TIMEOUT=300  # 5 minutes
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check workflow status
    STATUS=$(gh run list -R "$GITHUB_REPO" --limit 1 --json status --jq '.[0].status' 2>/dev/null || echo "unknown")

    if [ "$STATUS" = "completed" ]; then
        CONCLUSION=$(gh run list -R "$GITHUB_REPO" --limit 1 --json conclusion --jq '.[0].conclusion')
        if [ "$CONCLUSION" = "success" ]; then
            log_info "✓ GitHub Actions deployment completed successfully!"
            break
        elif [ "$CONCLUSION" = "failure" ]; then
            log_warn "GitHub Actions deployment failed, but continuing with permission fix..."
            break
        fi
    fi

    sleep 10
    ELAPSED=$((ELAPSED + 10))
    echo -n "."
done
echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    log_warn "Timeout waiting for deployment, continuing with permission fix..."
fi

# Fix permissions on server (this ensures rsync can write on next deployment)
log_info "Fixing permissions on server for $DOMAIN..."
ssh hetzner-root "chown -R kirbyuser:www-data /var/www/$DOMAIN 2>/dev/null || true" || log_warn "Could not set ownership (site may not exist yet)"
ssh hetzner-kirby "sudo fix-kirby-permissions $DOMAIN 2>/dev/null || true" || log_warn "Could not fix permissions (site may not exist yet)"
log_info "✓ Permissions fixed"
echo ""

# Re-run deployment if it failed due to permissions
log_info "Re-running GitHub Actions deployment to ensure all files are synced..."
gh workflow run deploy-hetzner.yml -R "$GITHUB_REPO" 2>/dev/null || log_warn "Could not trigger re-run automatically"

echo ""
echo "📝 Next Manual Steps:"
echo ""
echo "1. ⏳ Wait for final GitHub Actions deployment to complete"
echo "   Check: https://github.com/$GITHUB_REPO/actions"
echo ""
echo "2. 🔒 Add SSL certificate on server:"
echo "   ssh hetzner-root"
echo "   /usr/local/bin/add-ssl-cert $DOMAIN contact@matthiashacksteiner.net"
echo "   exit"
echo ""
echo "3. 🌐 Update DNS on Gandi:"
echo "   Change DNS record to: A 91.98.120.110"
echo ""
echo "4. ✅ Test after DNS propagates:"
echo "   https://$DOMAIN/panel"
echo "   https://$DOMAIN/global.json"
echo ""
log_info "✅ Migration script completed for $(basename $CHILD_REPO_PATH)!"
