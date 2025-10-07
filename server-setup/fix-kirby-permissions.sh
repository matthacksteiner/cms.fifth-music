#!/bin/bash

################################################################################
# Fix Kirby CMS Permissions
#
# This script fixes file ownership and permissions for Kirby CMS writable
# directories to ensure both the deploy user and web server can write to them.
#
# Usage: ./fix-kirby-permissions.sh <domain>
################################################################################

SITE_DOMAIN=$1

if [ -z "$SITE_DOMAIN" ]; then
    echo "Usage: fix-kirby-permissions <domain>"
    echo "Example: fix-kirby-permissions cms.example.com"
    exit 1
fi

SITE_PATH="/var/www/$SITE_DOMAIN"

if [ ! -d "$SITE_PATH" ]; then
    echo "Error: Site directory $SITE_PATH does not exist"
    exit 1
fi

echo "Fixing permissions for $SITE_DOMAIN..."

# Determine the owner (usually kirbyuser, but check the site directory)
OWNER=$(stat -c '%U' "$SITE_PATH" 2>/dev/null || stat -f '%Su' "$SITE_PATH")

echo "Setting ownership to $OWNER:www-data..."

# Ensure all writable directories exist
mkdir -p "$SITE_PATH/content" \
         "$SITE_PATH/site/languages" \
         "$SITE_PATH/site/accounts" \
         "$SITE_PATH/site/sessions" \
         "$SITE_PATH/site/cache" \
         "$SITE_PATH/public/media" \
         "$SITE_PATH/public/media/plugins" \
         "$SITE_PATH/storage" \
         "$SITE_PATH/storage/accounts" \
         "$SITE_PATH/storage/cache" \
         "$SITE_PATH/storage/sessions" \
         2>/dev/null || true

# Fix ownership for all writable directories
chown -R $OWNER:www-data \
    "$SITE_PATH/content" \
    "$SITE_PATH/site/languages" \
    "$SITE_PATH/site/accounts" \
    "$SITE_PATH/site/sessions" \
    "$SITE_PATH/site/cache" \
    "$SITE_PATH/public/media" \
    "$SITE_PATH/storage" \
    2>/dev/null || true

echo "Setting directory permissions (2775)..."

# Set directory permissions (2775 = rwxrwsr-x with setgid)
find "$SITE_PATH/content" \
     "$SITE_PATH/site/languages" \
     "$SITE_PATH/site/accounts" \
     "$SITE_PATH/site/sessions" \
     "$SITE_PATH/site/cache" \
     "$SITE_PATH/public/media" \
     "$SITE_PATH/storage" \
     -type d -exec chmod 2775 {} + 2>/dev/null || true

echo "Setting file permissions (664)..."

# Set file permissions (664 = rw-rw-r--)
find "$SITE_PATH/content" \
     "$SITE_PATH/site/languages" \
     "$SITE_PATH/site/accounts" \
     "$SITE_PATH/site/sessions" \
     "$SITE_PATH/site/cache" \
     "$SITE_PATH/public/media" \
     "$SITE_PATH/storage" \
     -type f -exec chmod 664 {} + 2>/dev/null || true

echo ""
echo "✓ Permissions fixed for $SITE_DOMAIN"
echo ""
echo "Summary:"
echo "  Owner: $OWNER:www-data"
echo "  Directories: 2775 (rwxrwsr-x)"
echo "  Files: 664 (rw-rw-r--)"
echo ""

