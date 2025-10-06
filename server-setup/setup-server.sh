#!/bin/bash

################################################################################
# Hetzner VPS Initial Setup Script for Multiple Kirby CMS Instances
#
# This script sets up a production-ready LEMP stack optimized for hosting
# multiple Kirby CMS instances with security best practices.
#
# Usage: bash setup-server.sh
# Run as: root
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root"
    exit 1
fi

log_info "==================================================================="
log_info "  Hetzner VPS Setup for Multiple Kirby CMS Instances"
log_info "==================================================================="
echo ""

# Confirm before proceeding
read -p "This will configure your server for hosting multiple Kirby CMS instances. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Setup cancelled"
    exit 1
fi

################################################################################
# 1. SYSTEM UPDATE
################################################################################

log_info "Step 1/12: Updating system packages..."
apt update
apt upgrade -y

################################################################################
# 2. INSTALL ESSENTIAL PACKAGES
################################################################################

log_info "Step 2/12: Installing essential packages..."
apt install -y \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    vim \
    htop \
    tree \
    rsync \
    zip

################################################################################
# 3. INSTALL NGINX
################################################################################

log_info "Step 3/12: Installing Nginx..."
apt install -y nginx

# Create backup of original config
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Optimize Nginx configuration
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 100M;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';

    ##
    # Logging Settings
    ##
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Remove default site
rm -f /etc/nginx/sites-enabled/default

systemctl enable nginx
systemctl restart nginx

################################################################################
# 4. INSTALL PHP 8.3
################################################################################

log_info "Step 4/12: Installing PHP 8.3 and extensions..."

# Add PHP repository
add-apt-repository -y ppa:ondrej/php
apt update

# Install PHP 8.3 and required extensions
apt install -y \
    php8.3-fpm \
    php8.3-cli \
    php8.3-common \
    php8.3-curl \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-intl \
    php8.3-opcache \
    php8.3-imagick

# Configure PHP-FPM
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/8.3/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/g' /etc/php/8.3/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.3/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/8.3/fpm/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/fpm/php.ini

# Enable opcache
cat >> /etc/php/8.3/fpm/conf.d/10-opcache.ini << 'EOF'
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF

systemctl enable php8.3-fpm
systemctl restart php8.3-fpm

################################################################################
# 5. INSTALL COMPOSER
################################################################################

log_info "Step 5/12: Installing Composer..."

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

################################################################################
# 6. INSTALL CERTBOT (Let's Encrypt)
################################################################################

log_info "Step 6/12: Installing Certbot for SSL certificates..."

apt install -y certbot python3-certbot-nginx

# Setup auto-renewal
systemctl enable certbot.timer

################################################################################
# 7. CONFIGURE FIREWALL (UFW)
################################################################################

log_info "Step 7/12: Configuring firewall..."

# Install UFW
apt install -y ufw

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (CRITICAL - Don't lock yourself out!)
ufw allow 22/tcp comment 'SSH'

# Allow HTTP and HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Enable UFW
echo "y" | ufw enable

################################################################################
# 8. INSTALL FAIL2BAN
################################################################################

log_info "Step 8/12: Installing Fail2ban..."

apt install -y fail2ban

# Configure Fail2ban for SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

systemctl enable fail2ban
systemctl restart fail2ban

################################################################################
# 9. CONFIGURE DEPLOYMENT USER
################################################################################

log_info "Step 9/12: Configuring deployment user..."

# Ask for username
read -p "Enter deployment username (default: deploy): " DEPLOY_USER
DEPLOY_USER=${DEPLOY_USER:-deploy}

# Create user if doesn't exist
if ! id -u $DEPLOY_USER > /dev/null 2>&1; then
    useradd -m -s /bin/bash $DEPLOY_USER
    usermod -aG www-data $DEPLOY_USER
    log_info "Created '$DEPLOY_USER' user"
else
    log_warn "'$DEPLOY_USER' user already exists, configuring it for deployment..."
    usermod -aG www-data $DEPLOY_USER
fi

# Create .ssh directory for deploy user
mkdir -p /home/$DEPLOY_USER/.ssh
chmod 700 /home/$DEPLOY_USER/.ssh
touch /home/$DEPLOY_USER/.ssh/authorized_keys
chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh

# Add deploy user to sudoers for specific commands
cat > /etc/sudoers.d/$DEPLOY_USER << EOF
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/sbin/service nginx reload
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/sbin/service nginx restart
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/sbin/service php8.3-fpm reload
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/sbin/service php8.3-fpm restart
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/certbot
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/local/bin/add-site
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/local/bin/remove-site
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/local/bin/add-ssl-cert
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/chown -R $DEPLOY_USER\:www-data /var/www/*
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/chmod -R * /var/www/*
EOF

chmod 0440 /etc/sudoers.d/$DEPLOY_USER

log_info "Configured user: $DEPLOY_USER"

################################################################################
# 10. CREATE DIRECTORY STRUCTURE
################################################################################

log_info "Step 10/12: Creating directory structure..."

# Create web root
mkdir -p /var/www
chown -R $DEPLOY_USER:www-data /var/www
chmod -R 755 /var/www

# Create backup directory
mkdir -p /var/backups/kirby-cms
chown -R $DEPLOY_USER:$DEPLOY_USER /var/backups/kirby-cms

# Create scripts directory
mkdir -p /usr/local/bin

################################################################################
# 11. CREATE MANAGEMENT SCRIPTS
################################################################################

log_info "Step 11/12: Creating management scripts..."

# Script to add new site
cat > /usr/local/bin/add-site << EOFSCRIPT
#!/bin/bash

SITE_DOMAIN=\$1
DEPLOY_USER=\${2:-$DEPLOY_USER}

if [ -z "\$SITE_DOMAIN" ]; then
    echo "Usage: add-site <domain> [deploy-user]"
    echo "Example: add-site cms.myproject.com kirbyuser"
    exit 1
fi

# Create site directory
mkdir -p /var/www/\$SITE_DOMAIN
chown -R \$DEPLOY_USER:www-data /var/www/\$SITE_DOMAIN
chmod -R 755 /var/www/\$SITE_DOMAIN

# Create Nginx config
cat > /etc/nginx/sites-available/$SITE_DOMAIN << 'EOF'
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name SITE_DOMAIN;

    # For Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/SITE_DOMAIN/public;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name SITE_DOMAIN;

    root /var/www/SITE_DOMAIN/public;
    index index.php;

    # SSL Configuration (will be managed by Certbot)
    # ssl_certificate /etc/letsencrypt/live/SITE_DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/SITE_DOMAIN/privkey.pem;

    # Logging
    access_log /var/log/nginx/SITE_DOMAIN.access.log;
    error_log /var/log/nginx/SITE_DOMAIN.error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Main location
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP handling
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_read_timeout 300;
    }

    # Media files caching
    location ~* \.(jpg|jpeg|png|gif|webp|svg|ico|pdf|woff|woff2|ttf|eot)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # CSS and JS caching
    location ~* \.(css|js)$ {
        expires 1w;
        add_header Cache-Control "public";
    }

    # API endpoints caching
    location ~* \.json$ {
        expires 1h;
        add_header Cache-Control "public";
    }

    # Security: Block access to sensitive files and directories
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ /(content|site|kirby|storage|vendor)/ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Prevent access to specific files
    location ~ /(\.git|\.env|composer\.json|composer\.lock|package\.json)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Replace SITE_DOMAIN placeholder
sed -i "s/SITE_DOMAIN/$SITE_DOMAIN/g" /etc/nginx/sites-available/$SITE_DOMAIN

# Enable site
ln -sf /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/

# Test Nginx config
nginx -t

# Reload Nginx
systemctl reload nginx

echo "✓ Site $SITE_DOMAIN added successfully"
echo ""
echo "Next steps:"
echo "1. Deploy your Kirby CMS files to /var/www/$SITE_DOMAIN/"
echo "2. Run: sudo /usr/local/bin/add-ssl-cert $SITE_DOMAIN your-email@example.com"
echo "3. Configure DNS: A record pointing to this server's IP"
EOFSCRIPT

chmod +x /usr/local/bin/add-site

# Script to remove site
cat > /usr/local/bin/remove-site << 'EOFSCRIPT'
#!/bin/bash

SITE_DOMAIN=$1

if [ -z "$SITE_DOMAIN" ]; then
    echo "Usage: remove-site <domain>"
    exit 1
fi

read -p "Are you sure you want to remove $SITE_DOMAIN? This will delete all files! (yes/no): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "Cancelled"
    exit 1
fi

# Backup before removal
if [ -d "/var/www/$SITE_DOMAIN" ]; then
    BACKUP_FILE="/var/backups/kirby-cms/${SITE_DOMAIN}-removal-$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$BACKUP_FILE" -C /var/www "$SITE_DOMAIN"
    echo "✓ Backup created: $BACKUP_FILE"
fi

# Remove Nginx config
rm -f /etc/nginx/sites-enabled/$SITE_DOMAIN
rm -f /etc/nginx/sites-available/$SITE_DOMAIN

# Remove SSL certificate
if [ -d "/etc/letsencrypt/live/$SITE_DOMAIN" ]; then
    certbot delete --cert-name $SITE_DOMAIN --non-interactive
fi

# Remove site directory
rm -rf /var/www/$SITE_DOMAIN

# Reload Nginx
systemctl reload nginx

echo "✓ Site $SITE_DOMAIN removed successfully"
EOFSCRIPT

chmod +x /usr/local/bin/remove-site

# Script to add SSL certificate
cat > /usr/local/bin/add-ssl-cert << 'EOFSCRIPT'
#!/bin/bash

SITE_DOMAIN=$1
EMAIL=$2

if [ -z "$SITE_DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: add-ssl-cert <domain> <email>"
    echo "Example: add-ssl-cert cms.myproject.com admin@myproject.com"
    exit 1
fi

# Request certificate
certbot --nginx -d $SITE_DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

echo "✓ SSL certificate added for $SITE_DOMAIN"
EOFSCRIPT

chmod +x /usr/local/bin/add-ssl-cert

# Script to backup a site
cat > /usr/local/bin/backup-kirby-site << 'EOFSCRIPT'
#!/bin/bash

SITE_DOMAIN=$1

if [ -z "$SITE_DOMAIN" ]; then
    echo "Usage: backup-kirby-site <domain>"
    exit 1
fi

if [ ! -d "/var/www/$SITE_DOMAIN" ]; then
    echo "Error: Site directory /var/www/$SITE_DOMAIN does not exist"
    exit 1
fi

BACKUP_DIR="/var/backups/kirby-cms"
BACKUP_FILE="$BACKUP_DIR/${SITE_DOMAIN}-$(date +%Y%m%d_%H%M%S).tar.gz"

mkdir -p $BACKUP_DIR

# Backup content, storage, and .env
tar -czf "$BACKUP_FILE" \
    -C /var/www \
    --exclude="$SITE_DOMAIN/public/media/*" \
    --exclude="$SITE_DOMAIN/storage/cache/*" \
    --exclude="$SITE_DOMAIN/storage/sessions/*" \
    "$SITE_DOMAIN/content" \
    "$SITE_DOMAIN/storage" \
    "$SITE_DOMAIN/.env" 2>/dev/null

echo "✓ Backup created: $BACKUP_FILE"

# Remove backups older than 30 days
find $BACKUP_DIR -name "${SITE_DOMAIN}-*.tar.gz" -mtime +30 -delete

# Count remaining backups
BACKUP_COUNT=$(find $BACKUP_DIR -name "${SITE_DOMAIN}-*.tar.gz" | wc -l)
echo "  Total backups for $SITE_DOMAIN: $BACKUP_COUNT"
EOFSCRIPT

chmod +x /usr/local/bin/backup-kirby-site

# Script to restore a site
cat > /usr/local/bin/restore-kirby-site << 'EOFSCRIPT'
#!/bin/bash

SITE_DOMAIN=$1
BACKUP_FILE=$2

if [ -z "$SITE_DOMAIN" ] || [ -z "$BACKUP_FILE" ]; then
    echo "Usage: restore-kirby-site <domain> <backup-file>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file $BACKUP_FILE does not exist"
    exit 1
fi

read -p "This will restore $SITE_DOMAIN from backup. Continue? (yes/no): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "Cancelled"
    exit 1
fi

# Extract backup
tar -xzf "$BACKUP_FILE" -C /var/www/

# Fix permissions
chown -R deploy:www-data /var/www/$SITE_DOMAIN
chmod -R 755 /var/www/$SITE_DOMAIN
chmod -R 775 /var/www/$SITE_DOMAIN/storage
chmod -R 775 /var/www/$SITE_DOMAIN/public/media 2>/dev/null || true

echo "✓ Restore completed successfully"
EOFSCRIPT

chmod +x /usr/local/bin/restore-kirby-site

################################################################################
# 12. SETUP AUTOMATED BACKUPS
################################################################################

log_info "Step 12/12: Setting up automated backups..."

# Create backup script
cat > /usr/local/bin/backup-all-kirby-sites << 'EOFSCRIPT'
#!/bin/bash

# Backup all Kirby sites
for SITE_DIR in /var/www/*/; do
    if [ -d "$SITE_DIR" ]; then
        SITE_DOMAIN=$(basename "$SITE_DIR")
        /usr/local/bin/backup-kirby-site "$SITE_DOMAIN"
    fi
done
EOFSCRIPT

chmod +x /usr/local/bin/backup-all-kirby-sites

# Add to crontab for deploy user
(crontab -u $DEPLOY_USER -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-all-kirby-sites") | crontab -u $DEPLOY_USER -

################################################################################
# COMPLETION
################################################################################

log_info "==================================================================="
log_info "  Setup Complete!"
log_info "==================================================================="
echo ""
log_info "✓ Nginx installed and configured"
log_info "✓ PHP 8.3-FPM installed with all required extensions"
log_info "✓ Composer installed"
log_info "✓ Certbot (Let's Encrypt) installed"
log_info "✓ Firewall (UFW) configured"
log_info "✓ Fail2ban installed and configured"
log_info "✓ Deployment user 'deploy' created"
log_info "✓ Management scripts installed"
log_info "✓ Automated backups configured (daily at 2 AM)"
echo ""
log_info "==================================================================="
log_info "  Next Steps"
log_info "==================================================================="
echo ""
echo "1. Add your SSH public key to /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "   Example: echo 'your-ssh-public-key' >> /home/$DEPLOY_USER/.ssh/authorized_keys"
echo ""
echo "2. Add a new CMS site:"
echo "   sudo /usr/local/bin/add-site cms.yourproject.com $DEPLOY_USER"
echo ""
echo "3. Deploy your Kirby CMS files to:"
echo "   /var/www/cms.yourproject.com/"
echo ""
echo "4. Add SSL certificate:"
echo "   sudo /usr/local/bin/add-ssl-cert cms.yourproject.com your-email@example.com"
echo ""
echo "5. Configure DNS:"
echo "   Point cms.yourproject.com A record to this server's IP"
echo ""
echo "NOTE: Deployment user configured: $DEPLOY_USER"
echo ""
log_info "==================================================================="
log_info "  Available Commands"
log_info "==================================================================="
echo ""
echo "  sudo /usr/local/bin/add-site <domain>              - Add new site"
echo "  sudo /usr/local/bin/remove-site <domain>           - Remove site"
echo "  sudo /usr/local/bin/add-ssl-cert <domain> <email>  - Add SSL"
echo "  sudo /usr/local/bin/backup-kirby-site <domain>     - Backup site"
echo "  sudo /usr/local/bin/restore-kirby-site <domain> <backup> - Restore"
echo "  sudo /usr/local/bin/backup-all-kirby-sites         - Backup all"
echo ""
log_info "Server is ready for multiple Kirby CMS instances!"

