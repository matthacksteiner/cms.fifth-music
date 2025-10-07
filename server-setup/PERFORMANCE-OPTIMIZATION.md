# Kirby CMS Performance Optimization Guide

This guide provides comprehensive performance optimization strategies for your Kirby CMS instances
on Hetzner VPS.

## Table of Contents

1. [PHP-FPM Optimization](#php-fpm-optimization)
2. [Nginx Optimization](#nginx-optimization)
3. [Kirby Cache Configuration](#kirby-cache-configuration)
4. [OPcache Configuration](#opcache-configuration)
5. [Image Optimization](#image-optimization)
6. [HTTP/2 and Gzip](#http2-and-gzip)
7. [CDN Integration](#cdn-integration)
8. [Monitoring and Benchmarking](#monitoring-and-benchmarking)

---

## PHP-FPM Optimization

### 1. Configure PHP-FPM Pool Settings

Edit `/etc/php/8.3/fpm/pool.d/www.conf` on your server:

```bash
ssh hetzner-root
nano /etc/php/8.3/fpm/pool.d/www.conf
```

**Optimized Settings** (for a server with 4GB RAM):

```ini
; Process Manager Settings
pm = dynamic
pm.max_children = 50        ; Maximum number of child processes
pm.start_servers = 10       ; Number started on boot
pm.min_spare_servers = 5    ; Minimum idle processes
pm.max_spare_servers = 15   ; Maximum idle processes
pm.max_requests = 500       ; Restart workers after N requests (prevents memory leaks)

; Performance tuning
pm.process_idle_timeout = 10s
request_terminate_timeout = 300s

; Status page (useful for monitoring)
pm.status_path = /status
ping.path = /ping
```

**For servers with more RAM**, scale accordingly:

- 8GB RAM: `pm.max_children = 100`, `pm.start_servers = 20`
- 16GB RAM: `pm.max_children = 200`, `pm.start_servers = 40`

### 2. Apply PHP-FPM Changes

```bash
# Validate configuration
php-fpm8.3 -t

# Restart PHP-FPM
systemctl restart php8.3-fpm
```

---

## Nginx Optimization

### 1. Worker Processes and Connections

Update `/etc/nginx/nginx.conf`:

```nginx
# Set to number of CPU cores (use 'auto' for automatic detection)
worker_processes auto;

# Increase worker connections
events {
    worker_connections 4096;    # Increased from 2048
    multi_accept on;
    use epoll;
}

# Set worker priority (nice value)
worker_priority -10;

# Increase worker file descriptors
worker_rlimit_nofile 10000;
```

### 2. HTTP Performance Settings

```nginx
http {
    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;    # Increased from default

    # Client settings
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;

    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # File cache
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # Reset headers
    reset_timedout_connection on;
}
```

### 3. Site-Specific Optimizations

**IMPORTANT:** Kirby 5 serves Panel plugin assets and media files dynamically through PHP. Do NOT
add `location` blocks for `.css`, `.js`, or image files as they will prevent Kirby from generating
files on-demand.

The optimized site config (already applied to your server):

```nginx
server {
    # ... SSL and other config ...

    # Kirby front controller pattern
    # All requests go through index.php if file doesn't exist
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    # PHP handling (optimized buffers)
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_intercept_errors on;

        # Performance: Optimized buffers
        fastcgi_buffer_size 32k;
        fastcgi_buffers 16 32k;
        fastcgi_busy_buffers_size 64k;
        fastcgi_read_timeout 300;
    }
}
```

**Why no static file caching location blocks?**

Kirby 5 generates Panel plugin assets (`/media/plugins/index.css`, `/media/plugins/index.js`) and
media files dynamically through the front controller (`index.php`). If you add
`location ~* \.(css|js)$` blocks, Nginx will try to serve these files directly and return 404s
before PHP can generate them, **breaking all Panel plugins**.

**For browser caching**, rely on:

1. Kirby's built-in cache headers for generated media
2. HTTP/2 push for critical assets
3. Service Worker for offline caching (frontend)

### 4. Apply Nginx Changes

```bash
# Test configuration
nginx -t

# Reload Nginx
systemctl reload nginx
```

---

## Kirby Cache Configuration

### 1. Enable Page Cache

Edit `/var/www/cms.yoursite.com/site/config/config.php`:

```php
<?php

return [
    // Enable page cache
    'cache' => [
        'pages' => [
            'active' => true,
            'ignore' => function ($page) {
                // Don't cache panel pages
                if ($page->kirby()->user()) {
                    return true;
                }
                // Don't cache pages with specific template or field
                if ($page->intendedTemplate()->name() === 'no-cache') {
                    return true;
                }
                return $page->nocache()->toBool() ?? false;
            }
        ],

        // Cache for data/api responses
        'api' => [
            'active' => true,
            'type'   => 'file'
        ]
    ],

    // Performance options
    'thumbs' => [
        'srcsets' => [
            'default' => [320, 640, 960, 1280, 1920, 2560],
        ],
        'quality' => 80,  // Reduce quality for smaller files
        'format' => 'webp', // Use WebP for better compression
        'driver' => 'im',   // Use ImageMagick if available
    ],

    // Optimize routes
    'routes' => [
        // Add cache headers to JSON responses
        [
            'pattern' => '(:all).json',
            'action'  => function ($path) {
                header('Cache-Control: public, max-age=3600');
                // ... your JSON response logic
            }
        ]
    ]
];
```

### 2. Redis Cache (Optional - Best Performance)

If you install Redis:

```bash
# Install Redis
apt install -y redis-server php8.3-redis

# Start Redis
systemctl enable redis-server
systemctl start redis-server
```

Then update Kirby config:

```php
'cache' => [
    'pages' => [
        'active'   => true,
        'type'     => 'redis',
        'host'     => '127.0.0.1',
        'port'     => 6379,
        'database' => 0
    ],
    'api' => [
        'active'   => true,
        'type'     => 'redis',
        'host'     => '127.0.0.1',
        'port'     => 6379,
        'database' => 1  // Use different database
    ]
]
```

---

## OPcache Configuration

### 1. Optimize OPcache Settings

Edit `/etc/php/8.3/fpm/conf.d/10-opcache.ini`:

```ini
; Enable OPcache
opcache.enable=1
opcache.enable_cli=0

; Memory Settings
opcache.memory_consumption=256          ; Increased from 128
opcache.interned_strings_buffer=16     ; String memory
opcache.max_accelerated_files=20000    ; Increased from 10000

; Performance
opcache.revalidate_freq=2              ; Check for file changes every 2 seconds
opcache.fast_shutdown=1
opcache.validate_timestamps=1          ; Set to 0 in production for max speed

; Advanced optimizations
opcache.save_comments=1
opcache.enable_file_override=1
opcache.optimization_level=0x7FFEBFFF
opcache.file_cache=/var/cache/opcache
opcache.file_cache_only=0
```

**For Production** (even faster but requires manual cache clear on updates):

```ini
opcache.validate_timestamps=0    ; Don't check for file changes
opcache.revalidate_freq=0
```

Then restart PHP-FPM:

```bash
systemctl restart php8.3-fpm
```

---

## Image Optimization

### 1. Install Image Processing Tools

```bash
# Install ImageMagick and WebP tools
apt install -y imagemagick webp

# Install jpegoptim and optipng
apt install -y jpegoptim optipng
```

### 2. Kirby Thumbs Configuration

Update your Kirby config:

```php
'thumbs' => [
    'driver' => 'im',  // Use ImageMagick
    'quality' => 80,
    'format' => 'webp',

    // Presets for common sizes
    'presets' => [
        'default' => ['width' => 1024, 'quality' => 80, 'format' => 'webp'],
        'thumbnail' => ['width' => 300, 'height' => 300, 'crop' => true],
        'hero' => ['width' => 1920, 'quality' => 85, 'format' => 'webp'],
    ],

    // Srcset for responsive images
    'srcsets' => [
        'default' => [320, 640, 960, 1280, 1920],
    ],
]
```

---

## HTTP/2 and Gzip

### 1. Gzip Compression

Update `/etc/nginx/nginx.conf`:

```nginx
# Gzip Settings (already in base config, but optimized)
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;           # 6 is optimal (1-9, higher = more CPU)
gzip_min_length 1000;        # Don't compress files < 1KB
gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/json
    application/javascript
    application/xml+rss
    application/rss+xml
    application/atom+xml
    image/svg+xml
    font/truetype
    font/opentype
    application/vnd.ms-fontobject;
gzip_disable "msie6";
```

### 2. Brotli Compression (Better than Gzip)

```bash
# Install Brotli module
apt install -y nginx-module-brotli

# Load module in /etc/nginx/nginx.conf (at the top)
load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;
```

Then add to `http` block:

```nginx
# Brotli Settings
brotli on;
brotli_comp_level 6;
brotli_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/json
    application/javascript
    application/xml+rss
    image/svg+xml;
```

---

## CDN Integration

### 1. Cloudinary or KeyCDN Setup

For Kirby with CDN, create a plugin `/site/plugins/cdn/index.php`:

```php
<?php

Kirby::plugin('yourname/cdn', [
    'components' => [
        'url' => function ($kirby, $path, $options) {
            $original = $kirby->nativeComponent('url');

            // Only apply CDN to assets and media
            if (preg_match('!^(assets|media)/!', $path)) {
                $cdnDomain = option('cdn.domain');

                if ($cdnDomain && option('cdn.enabled', false)) {
                    // Add cache busting
                    $version = option('cdn.version', time());
                    return $cdnDomain . '/' . $path . '?v=' . $version;
                }
            }

            return $original($kirby, $path, $options);
        }
    ]
]);
```

Then in `config.php`:

```php
'cdn' => [
    'enabled' => true,
    'domain' => 'https://cdn.yoursite.com',
    'version' => filemtime(__DIR__ . '/../../public/assets')  // Auto version
]
```

---

## Monitoring and Benchmarking

### 1. Enable Nginx Status Page

Add to your server config:

```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

### 2. Monitor Performance

```bash
# Check Nginx status
curl http://localhost/nginx_status

# Check PHP-FPM status
curl http://localhost/status?full

# Monitor in real-time
watch -n 1 'curl -s http://localhost/nginx_status'
```

### 3. Benchmarking Tools

```bash
# Apache Bench (simple)
ab -n 1000 -c 10 https://cms.yoursite.com/

# wrk (advanced)
wrk -t4 -c100 -d30s https://cms.yoursite.com/
```

### 4. Monitor Logs

```bash
# Real-time error monitoring
tail -f /var/log/nginx/error.log | grep -i 'error\|warn'

# PHP errors
tail -f /var/log/php8.3-fpm.log

# Slow query detection (add to PHP-FPM pool config)
# slowlog = /var/log/php8.3-fpm-slow.log
# request_slowlog_timeout = 5s
```

---

## Performance Checklist

### Server Level

- [ ] PHP-FPM pool settings optimized for RAM
- [ ] OPcache enabled with proper memory allocation
- [ ] Nginx worker processes set to CPU cores
- [ ] File cache enabled in Nginx
- [ ] Gzip/Brotli compression enabled
- [ ] HTTP/2 enabled (automatic with SSL)

### Kirby Level

- [ ] Page cache enabled
- [ ] Redis cache installed (optional)
- [ ] Image thumbnails using WebP
- [ ] Responsive srcsets configured
- [ ] API responses cached
- [ ] Ignored admin/panel from cache

### Content Level

- [ ] Images optimized before upload
- [ ] Large images resized via Kirby thumbs
- [ ] Unnecessary plugins disabled
- [ ] Static assets served with long cache headers

---

## Quick Optimization Script

Run this on your server to apply all optimizations:

```bash
#!/bin/bash

# Apply all performance optimizations

# 1. Update PHP-FPM settings
sed -i 's/pm.max_children = .*/pm.max_children = 50/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.start_servers = .*/pm.start_servers = 10/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.max_requests = .*/pm.max_requests = 500/' /etc/php/8.3/fpm/pool.d/www.conf

# 2. Update Nginx workers
sed -i 's/worker_connections .*/worker_connections 4096;/' /etc/nginx/nginx.conf

# 3. Create cache directories
mkdir -p /var/cache/nginx/kirby
mkdir -p /var/cache/opcache
chown -R www-data:www-data /var/cache/nginx
chown -R www-data:www-data /var/cache/opcache

# 4. Restart services
systemctl restart php8.3-fpm
systemctl reload nginx

echo "✓ Performance optimizations applied!"
echo "  - PHP-FPM pool optimized"
echo "  - Nginx workers increased"
echo "  - Cache directories created"
echo ""
echo "Next: Enable Kirby page cache in site/config/config.php"
```

---

## Expected Performance Gains

With these optimizations, you should see:

- **Page load time**: 50-70% faster
- **TTFB (Time to First Byte)**: < 200ms (from 500ms+)
- **Concurrent requests**: 3-5x increase
- **Memory usage**: More efficient (10-20% reduction)
- **CPU usage**: Lower under load

---

## Troubleshooting

### High Memory Usage

```bash
# Check PHP-FPM memory
ps aux | grep php-fpm | awk '{sum+=$6} END {print sum/1024 " MB"}'

# Reduce pm.max_children if needed
```

### Slow Page Loads

```bash
# Enable slow log in PHP-FPM
echo "request_slowlog_timeout = 3s" >> /etc/php/8.3/fpm/pool.d/www.conf
echo "slowlog = /var/log/php8.3-fpm-slow.log" >> /etc/php/8.3/fpm/pool.d/www.conf
systemctl restart php8.3-fpm

# Monitor slow requests
tail -f /var/log/php8.3-fpm-slow.log
```

### Cache Not Working

```bash
# Check Kirby cache directory permissions
ls -la /var/www/cms.yoursite.com/storage/cache/

# Clear and regenerate
rm -rf /var/www/cms.yoursite.com/storage/cache/*
```

---

**References:**

- [Kirby Performance Guide](https://getkirby.com/docs/cookbook/performance)
- [Nginx Performance Tuning](https://www.nginx.com/blog/tuning-nginx/)
- [PHP-FPM Optimization](https://www.php.net/manual/en/install.fpm.configuration.php)
