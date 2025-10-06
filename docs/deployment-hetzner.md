# Hetzner VPS Deployment Guide

This guide covers deploying multiple Kirby CMS instances to a Hetzner VPS using the automated setup
scripts.

## Overview

The Hetzner VPS deployment setup provides:

- **Multiple Sites Support**: Host multiple Kirby CMS instances on a single VPS
- **Automated Setup**: One-command server configuration
- **Production Ready**: Security best practices built-in
- **Easy Deployment**: GitHub Actions or manual deployment
- **SSL Management**: Automatic Let's Encrypt certificates
- **Backup System**: Automated daily backups with 30-day retention

## Prerequisites

### 1. Hetzner VPS

- **Operating System**: Ubuntu 24.04 LTS (recommended) or Ubuntu 22.04 LTS
- **Resources**:
  - Minimum: 2GB RAM, 1 vCPU, 20GB storage
  - Recommended: 4GB RAM, 2 vCPU, 40GB storage (for multiple sites)
- **Root Access**: SSH access with root privileges

### 2. Local Machine Requirements

- SSH client installed
- Git installed
- rsync installed (for manual deployments)

### 3. Domain Configuration

- DNS access to configure A records
- Domain(s) pointing to your VPS IP address

## Initial Server Setup

### Step 1: Upload Setup Script

From your local machine, upload the setup script to your VPS:

```bash
cd /path/to/cms.baukasten
scp server-setup/setup-server.sh root@YOUR_SERVER_IP:/tmp/
```

### Step 2: Execute Setup Script

SSH into your VPS and run the setup:

```bash
ssh root@YOUR_SERVER_IP
bash /tmp/setup-server.sh
```

The script will:

1. Update system packages
2. Install Nginx web server
3. Install PHP 8.3-FPM with all required extensions
4. Install Composer for dependency management
5. Install Certbot for SSL certificates
6. Configure UFW firewall (ports 22, 80, 443 open)
7. Install and configure Fail2ban for security
8. Create `deploy` user for deployments
9. Install management scripts
10. Configure automated backups

**Duration**: Approximately 5-10 minutes depending on server speed.

### Step 3: Configure SSH Keys

Add your SSH public key to the deploy user:

```bash
# On your local machine
cat ~/.ssh/id_ed25519.pub | ssh root@YOUR_SERVER_IP "cat >> /home/deploy/.ssh/authorized_keys"
```

If you don't have an SSH key, generate one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

## Deploying a CMS Instance

You can deploy using **GitHub Actions** (recommended) or **manual deployment**.

### Option A: GitHub Actions Deployment (Recommended)

#### 1. Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

| Secret Name          | Description                | Example                                   |
| -------------------- | -------------------------- | ----------------------------------------- |
| `HETZNER_HOST`       | Your server IP or hostname | `1.2.3.4` or `server.example.com`         |
| `HETZNER_USER`       | SSH username               | `deploy`                                  |
| `DEPLOY_KEY_PRIVATE` | SSH private key            | Contents of `~/.ssh/id_ed25519`           |
| `HETZNER_PATH`       | Site directory name        | `cms.yourproject.com`                     |
| `DEPLOY_URL`         | Netlify build hook URL     | `https://api.netlify.com/build_hooks/...` |

#### 2. Deploy

Simply push to the `main` branch:

```bash
git add .
git commit -m "Deploy to Hetzner"
git push origin main
```

GitHub Actions will automatically:

- Create site directory on server
- Sync files via rsync
- Create `.env` file
- Install Composer dependencies
- Set proper permissions
- Clear cache
- Reload services

### Option B: Manual Deployment

#### 1. Run Deployment Script

From your local machine:

```bash
cd /path/to/cms.baukasten
./server-setup/deploy-site.sh cms.yourproject.com YOUR_SERVER_IP
```

Follow the interactive prompts to configure your site.

#### 2. What Happens During Deployment

The script will:

1. Create site directory: `/var/www/cms.yourproject.com/`
2. Configure Nginx virtual host
3. Deploy files via rsync (excluding content, media, vendor)
4. Create `.env` file with your configuration
5. Run `composer install`
6. Set proper file permissions
7. Clear Kirby cache

## SSL Certificate Setup

After deployment, add an SSL certificate:

```bash
ssh deploy@YOUR_SERVER_IP
sudo /usr/local/bin/add-ssl-cert cms.yourproject.com admin@yourproject.com
```

This will:

- Request a Let's Encrypt certificate
- Configure Nginx for HTTPS
- Set up automatic certificate renewal
- Redirect HTTP to HTTPS

## Server Management

### Add New Site

```bash
# On server
sudo /usr/local/bin/add-site cms.newproject.com
```

Then deploy using GitHub Actions or the manual script.

### Remove Site

```bash
# On server
sudo /usr/local/bin/remove-site cms.oldproject.com
```

This will:

- Create a backup before removal
- Remove Nginx configuration
- Delete SSL certificate
- Remove site directory

### List All Sites

```bash
ls -la /var/www/
```

### Backup Site

Manual backup:

```bash
sudo /usr/local/bin/backup-kirby-site cms.yourproject.com
```

Backup all sites:

```bash
sudo /usr/local/bin/backup-all-kirby-sites
```

Backups are stored in `/var/backups/kirby-cms/` with 30-day retention.

### Restore from Backup

```bash
sudo /usr/local/bin/restore-kirby-site cms.yourproject.com /var/backups/kirby-cms/cms.yourproject.com-YYYYMMDD_HHMMSS.tar.gz
```

## Directory Structure

```
/var/www/cms.yourproject.com/
├── composer.json           # Dependencies
├── composer.lock
├── .env                    # Environment variables
├── content/                # Your content (excluded from deployment)
├── kirby/                  # Kirby CMS core (installed via Composer)
├── public/                 # Document root
│   ├── index.php          # Entry point
│   ├── assets/            # Static assets
│   └── media/             # User uploads (excluded from deployment)
├── site/                   # Your site configuration
│   ├── blueprints/
│   ├── config/
│   ├── plugins/
│   └── templates/
├── storage/                # Cache and sessions
│   ├── cache/
│   └── sessions/
└── vendor/                 # Composer dependencies
```

## File Permissions

The setup automatically configures:

- **Owner**: `deploy:www-data`
- **Directories**: `755` (readable/executable by all, writable by owner)
- **Files**: `644` (readable by all, writable by owner)
- **Writable Directories**: `775` (readable/writable by owner and group)
  - `storage/`
  - `public/media/`
  - `site/cache/`

If you need to fix permissions manually:

```bash
sudo chown -R deploy:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
sudo chmod -R 775 /var/www/cms.yourproject.com/public/media
sudo chmod -R 775 /var/www/cms.yourproject.com/site/cache
```

## Monitoring and Logs

### Nginx Logs

```bash
# Access logs
sudo tail -f /var/log/nginx/cms.yourproject.com.access.log

# Error logs
sudo tail -f /var/log/nginx/cms.yourproject.com.error.log
```

### PHP-FPM Logs

```bash
sudo tail -f /var/log/php8.3-fpm.log
```

### Check Service Status

```bash
# Nginx
sudo systemctl status nginx

# PHP-FPM
sudo systemctl status php8.3-fpm

# Fail2ban
sudo systemctl status fail2ban

# Firewall
sudo ufw status
```

## Performance Optimization

### PHP-FPM Tuning

For better performance with multiple sites, edit `/etc/php/8.3/fpm/pool.d/www.conf`:

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

Restart PHP-FPM:

```bash
sudo systemctl restart php8.3-fpm
```

### Nginx Tuning

The setup script already optimizes Nginx for:

- Gzip compression
- Browser caching
- FastCGI buffering
- Worker connections

### Kirby Cache

Ensure caching is enabled in `site/config/config.php`:

```php
'cache' => [
    'pages' => [
        'active' => true,
        'type'   => 'file'
    ]
],
```

## Security Features

### Firewall (UFW)

Only essential ports are open:

- **22**: SSH
- **80**: HTTP
- **443**: HTTPS

### Fail2ban

Protects against:

- SSH brute force attacks
- Nginx authentication failures
- Bad bots
- Script injections

Check banned IPs:

```bash
sudo fail2ban-client status sshd
```

### SSL/TLS

- **Automatic HTTPS**: All HTTP traffic redirected to HTTPS
- **Modern Protocols**: TLS 1.2 and 1.3 only
- **Auto-renewal**: Certificates renew automatically via certbot

### Directory Protection

Nginx blocks access to:

- `.git`, `.env` files
- `content/`, `site/`, `kirby/`, `storage/`, `vendor/` directories
- Sensitive files like `composer.json`, `composer.lock`

## Troubleshooting

### Site Not Loading

1. Check Nginx configuration:

   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   ```

2. Check DNS:

   ```bash
   nslookup cms.yourproject.com
   ```

3. Check permissions:
   ```bash
   ls -la /var/www/cms.yourproject.com/public/
   ```

### SSL Certificate Issues

```bash
# Test certificate renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

### PHP Errors

Check PHP-FPM status and logs:

```bash
sudo systemctl status php8.3-fpm
sudo tail -f /var/log/php8.3-fpm.log
```

### Permission Denied Errors

Run the permission fix script:

```bash
sudo chown -R deploy:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
sudo chmod -R 775 /var/www/cms.yourproject.com/public/media
```

## Updating

### System Updates

```bash
sudo apt update
sudo apt upgrade -y
```

### Composer Updates

```bash
cd /var/www/cms.yourproject.com
composer update
```

### Kirby Updates

Kirby is installed via Composer, so update with:

```bash
cd /var/www/cms.yourproject.com
composer update getkirby/cms
```

## Cost Estimation

### Hetzner VPS Pricing (as of 2025)

| Plan | vCPU | RAM  | Storage | Price/Month | Suitable For     |
| ---- | ---- | ---- | ------- | ----------- | ---------------- |
| CX11 | 1    | 2GB  | 20GB    | ~€4         | 1-2 small sites  |
| CX21 | 2    | 4GB  | 40GB    | ~€6         | 3-5 medium sites |
| CX31 | 2    | 8GB  | 80GB    | ~€11        | 5-10 sites       |
| CX41 | 4    | 16GB | 160GB   | ~€19        | 10+ sites        |

## Comparison: Hetzner vs Uberspace

| Feature            | Hetzner VPS                     | Uberspace                   |
| ------------------ | ------------------------------- | --------------------------- |
| **Control**        | Full root access                | Shared environment          |
| **Performance**    | Dedicated resources             | Shared resources            |
| **Cost**           | €4-19/month                     | €5+/month                   |
| **Setup**          | Manual (automated with scripts) | Mostly automated            |
| **Scalability**    | Easily upgrade VPS              | Limited by shared resources |
| **Multiple Sites** | Unlimited (resource-limited)    | Multiple allowed            |
| **SSH Access**     | Full root access                | User-level only             |
| **Best For**       | Multiple projects, custom needs | Single project, simplicity  |

## Best Practices

1. **Regular Backups**: Automated daily backups are configured, but consider offsite backups for
   critical data
2. **Keep Updated**: Regularly update system packages and Kirby
3. **Monitor Resources**: Use `htop` to monitor CPU/RAM usage
4. **Separate Sites**: Use separate databases/configs for each site
5. **Use SSL**: Always enable SSL for production sites
6. **Test Before Deploy**: Use staging environments when possible
7. **Document Changes**: Keep notes of custom configurations

## Support and Resources

- **Server Setup Script**: `/server-setup/setup-server.sh`
- **Deployment Script**: `/server-setup/deploy-site.sh`
- **Nginx Config Template**: `/server-setup/nginx-site.conf.template`
- **GitHub Actions**: `/.github/workflows/deploy-hetzner.yml`
- **Kirby Documentation**: https://getkirby.com/docs
- **Nginx Documentation**: https://nginx.org/en/docs/
- **Hetzner Docs**: https://docs.hetzner.com/

---

**Last Updated**: January 2025 **Tested On**: Ubuntu 24.04 LTS, Kirby CMS 5.x
