#!/bin/bash

################################################################################
# Kirby CMS Performance Optimization Script
#
# This script applies performance optimizations to your Hetzner VPS for
# maximum Kirby CMS performance.
#
# Usage: Run as root on the server
#        bash optimize-server-performance.sh
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root"
    exit 1
fi

log_info "==================================================================="
log_info "  Kirby CMS Performance Optimization"
log_info "==================================================================="
echo ""

# Get RAM size
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
log_info "Detected RAM: ${TOTAL_RAM}MB"

# Calculate PHP-FPM settings based on RAM
if [ $TOTAL_RAM -lt 2048 ]; then
    PM_MAX_CHILDREN=25
    PM_START_SERVERS=5
elif [ $TOTAL_RAM -lt 4096 ]; then
    PM_MAX_CHILDREN=50
    PM_START_SERVERS=10
elif [ $TOTAL_RAM -lt 8192 ]; then
    PM_MAX_CHILDREN=100
    PM_START_SERVERS=20
else
    PM_MAX_CHILDREN=200
    PM_START_SERVERS=40
fi

log_info "Calculated PHP-FPM settings: max_children=$PM_MAX_CHILDREN, start_servers=$PM_START_SERVERS"
echo ""

################################################################################
# 1. OPTIMIZE PHP-FPM
################################################################################

log_info "Step 1/6: Optimizing PHP-FPM pool configuration..."

# Backup original config
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup

# Update settings
sed -i "s/^pm.max_children = .*/pm.max_children = $PM_MAX_CHILDREN/" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/^pm.start_servers = .*/pm.start_servers = $PM_START_SERVERS/" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = 15/" /etc/php/8.3/fpm/pool.d/www.conf

# Add max_requests if not exists
if ! grep -q "^pm.max_requests" /etc/php/8.3/fpm/pool.d/www.conf; then
    sed -i "/^pm.max_spare_servers/a pm.max_requests = 500" /etc/php/8.3/fpm/pool.d/www.conf
fi

# Add process idle timeout
if ! grep -q "^pm.process_idle_timeout" /etc/php/8.3/fpm/pool.d/www.conf; then
    sed -i "/^pm.max_requests/a pm.process_idle_timeout = 10s" /etc/php/8.3/fpm/pool.d/www.conf
fi

# Enable status page
if ! grep -q "^pm.status_path" /etc/php/8.3/fpm/pool.d/www.conf; then
    echo "pm.status_path = /fpm-status" >> /etc/php/8.3/fpm/pool.d/www.conf
fi

log_info "✓ PHP-FPM pool optimized"

################################################################################
# 2. OPTIMIZE OPCACHE
################################################################################

log_info "Step 2/6: Optimizing OPcache..."

# Create optimized OPcache config
cat > /etc/php/8.3/fpm/conf.d/10-opcache.ini << 'EOF'
; OPcache Configuration
opcache.enable=1
opcache.enable_cli=0

; Memory Settings
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000

; Performance
opcache.revalidate_freq=2
opcache.fast_shutdown=1
opcache.validate_timestamps=1

; Advanced
opcache.save_comments=1
opcache.enable_file_override=1
opcache.optimization_level=0x7FFEBFFF
EOF

# Create OPcache file cache directory
mkdir -p /var/cache/opcache
chown www-data:www-data /var/cache/opcache
chmod 755 /var/cache/opcache

log_info "✓ OPcache optimized"

################################################################################
# 3. OPTIMIZE NGINX
################################################################################

log_info "Step 3/6: Optimizing Nginx configuration..."

# Backup original
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Get CPU cores
CPU_CORES=$(nproc)

# Update worker settings
sed -i "s/^worker_processes .*/worker_processes auto;/" /etc/nginx/nginx.conf
sed -i "s/worker_connections [0-9]*/worker_connections 4096/" /etc/nginx/nginx.conf

# Add file cache settings if not exists
if ! grep -q "open_file_cache" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    # File cache\n    open_file_cache max=200000 inactive=20s;\n    open_file_cache_valid 30s;\n    open_file_cache_min_uses 2;\n    open_file_cache_errors on;\n' /etc/nginx/nginx.conf
fi

# Add keepalive optimization
if ! grep -q "keepalive_requests" /etc/nginx/nginx.conf; then
    sed -i '/keepalive_timeout/a \    keepalive_requests 1000;' /etc/nginx/nginx.conf
fi

# Add reset_timedout_connection
if ! grep -q "reset_timedout_connection" /etc/nginx/nginx.conf; then
    sed -i '/keepalive_requests/a \    reset_timedout_connection on;' /etc/nginx/nginx.conf
fi

log_info "✓ Nginx optimized (workers: auto, connections: 4096)"

################################################################################
# 4. CREATE CACHE DIRECTORIES
################################################################################

log_info "Step 4/6: Creating cache directories..."

mkdir -p /var/cache/nginx/kirby
mkdir -p /var/cache/nginx/fastcgi
chown -R www-data:www-data /var/cache/nginx
chmod -R 755 /var/cache/nginx

log_info "✓ Cache directories created"

################################################################################
# 5. INSTALL IMAGE OPTIMIZATION TOOLS
################################################################################

log_info "Step 5/6: Installing image optimization tools..."

apt install -y imagemagick webp jpegoptim optipng 2>/dev/null || log_warn "Some packages may already be installed"

log_info "✓ Image optimization tools installed"

################################################################################
# 6. RESTART SERVICES
################################################################################

log_info "Step 6/6: Restarting services..."

# Test configs first
php-fpm8.3 -t
nginx -t

# Restart services
systemctl restart php8.3-fpm
systemctl reload nginx

log_info "✓ Services restarted"

################################################################################
# COMPLETION
################################################################################

echo ""
log_info "==================================================================="
log_info "  Performance Optimization Complete!"
log_info "==================================================================="
echo ""
log_info "Applied Optimizations:"
echo ""
echo "  ✓ PHP-FPM: max_children=$PM_MAX_CHILDREN, start_servers=$PM_START_SERVERS"
echo "  ✓ OPcache: 256MB memory, 20000 files"
echo "  ✓ Nginx: auto workers, 4096 connections"
echo "  ✓ File cache: enabled"
echo "  ✓ Image tools: installed (ImageMagick, WebP, jpegoptim, optipng)"
echo ""
log_info "Next Steps:"
echo ""
echo "  1. Enable Kirby page cache in each site's config.php:"
echo "     'cache' => ['pages' => ['active' => true]]"
echo ""
echo "  2. Optional: Install Redis for even better caching:"
echo "     apt install -y redis-server php8.3-redis"
echo "     systemctl enable redis-server && systemctl start redis-server"
echo ""
echo "  3. Monitor performance:"
echo "     curl http://localhost/fpm-status?full"
echo ""
log_info "==================================================================="
echo ""

# Display current status
log_info "Current Service Status:"
systemctl is-active nginx && echo "  ✓ Nginx: running" || echo "  ✗ Nginx: stopped"
systemctl is-active php8.3-fpm && echo "  ✓ PHP-FPM: running" || echo "  ✗ PHP-FPM: stopped"
echo ""

# Display memory usage
log_info "Memory Usage:"
free -h | grep -E 'Mem|Swap'
echo ""

log_info "Optimization complete! Your Kirby CMS should now be significantly faster."

