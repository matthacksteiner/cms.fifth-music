#!/bin/bash

################################################################################
# Deploy Kirby CMS Site to Hetzner VPS
#
# This script deploys a Kirby CMS instance from your local machine to the
# Hetzner VPS server.
#
# Usage: ./deploy-site.sh <site-domain> [server-ip] [ssh-user]
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
SITE_DOMAIN=$1
SERVER_HOST=${2:-}
SSH_USER=${3:-}

if [ -z "$SITE_DOMAIN" ]; then
    log_error "Usage: ./deploy-site.sh <site-domain> [server-host] [ssh-user]"
    log_error "Example: ./deploy-site.sh cms.myproject.com hetzner-kirby kirbyuser"
    log_error "         ./deploy-site.sh cms.myproject.com 1.2.3.4 deploy"
    exit 1
fi

# Prompt for server host if not provided
if [ -z "$SERVER_HOST" ]; then
    read -p "Enter server hostname/IP or SSH config alias (e.g., hetzner-kirby): " SERVER_HOST
fi

# Prompt for SSH user if not provided
if [ -z "$SSH_USER" ]; then
    read -p "Enter SSH username (default: deploy): " SSH_USER
    SSH_USER=${SSH_USER:-deploy}
fi

log_info "==================================================================="
log_info "  Deploying $SITE_DOMAIN to $SERVER_HOST as $SSH_USER"
log_info "==================================================================="
echo ""

# Get current directory (should be cms.baukasten root or server-setup)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine project root
if [ -f "$SCRIPT_DIR/../composer.json" ]; then
    PROJECT_ROOT="$SCRIPT_DIR/.."
elif [ -f "$SCRIPT_DIR/composer.json" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
else
    log_error "Cannot find project root. Run this script from the cms.baukasten directory or its server-setup subdirectory."
    exit 1
fi

cd "$PROJECT_ROOT"

# Check if site directory exists on server, if not create it
log_info "Ensuring site directory exists on server..."
ssh $SSH_USER@$SERVER_HOST "sudo /usr/local/bin/add-site $SITE_DOMAIN $SSH_USER" || log_warn "Site may already exist"

# Deploy files using rsync
log_info "Deploying files via rsync..."

rsync -avz --progress \
    --exclude=".git" \
    --exclude=".github" \
    --exclude=".env" \
    --exclude=".env.*" \
    --exclude="node_modules" \
    --exclude="content" \
    --exclude="storage/cache/*" \
    --exclude="storage/sessions/*" \
    --exclude="public/media/*" \
    --exclude="vendor" \
    --exclude="kirby" \
    --exclude=".vscode" \
    --exclude=".DS_Store" \
    --exclude="server-setup" \
    --exclude="docs" \
    ./ \
    $SSH_USER@$SERVER_HOST:/var/www/$SITE_DOMAIN/

# Prompt for DEPLOY_URL
echo ""
read -p "Enter Netlify Deploy Hook URL (or press Enter to skip): " DEPLOY_URL

# Create .env file on server
log_info "Creating .env file on server..."
ssh $SSH_USER@$SERVER_HOST "bash -c 'cat > /var/www/$SITE_DOMAIN/.env << EOF
# Kirby CMS Environment Variables
DEPLOY_URL=$DEPLOY_URL
KIRBY_DEBUG=false
KIRBY_CACHE=true
EOF'"

# Run composer install on server
log_info "Installing Composer dependencies on server..."
ssh $SSH_USER@$SERVER_HOST "cd /var/www/$SITE_DOMAIN && composer install --no-dev --optimize-autoloader"

# Fix permissions for writable directories (in case rsync changed them)
log_info "Setting correct permissions for writable directories..."
ssh $SSH_USER@$SERVER_HOST "bash -lc 'cd /var/www/$SITE_DOMAIN && \
  sudo chown -R $SSH_USER:www-data content site/languages site/accounts site/sessions site/cache public/media storage 2>/dev/null || true && \
  find content site/languages site/accounts site/sessions site/cache public/media storage -type d -exec chmod 2775 {} + 2>/dev/null || true && \
  find content site/languages site/accounts site/sessions site/cache public/media storage -type f -exec chmod 664 {} + 2>/dev/null || true && \
  bash -c \"rm -rf storage/cache/* storage/sessions/* 2>/dev/null || true\"'"

# No-op cache clear already handled above

log_info "==================================================================="
log_info "  Deployment Complete!"
log_info "==================================================================="
echo ""
log_info "Site deployed to: /var/www/$SITE_DOMAIN/"
echo ""
echo "Next steps:"
echo "1. Configure DNS: Point $SITE_DOMAIN to your server IP"
echo "2. Add SSL certificate: ssh $SSH_USER@$SERVER_HOST 'sudo /usr/local/bin/add-ssl-cert $SITE_DOMAIN your-email@example.com'"
echo "3. Visit: https://$SITE_DOMAIN/panel to set up Kirby"
echo ""

