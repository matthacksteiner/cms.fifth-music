# Hetzner VPS Server Setup for Multiple Kirby CMS Instances

This directory contains automated scripts for setting up and managing multiple Kirby CMS instances
on a Hetzner VPS.

## 📋 Overview

The setup enables you to:

- Host multiple Kirby CMS instances (template children) on a single VPS
- Automatic SSL certificates via Let's Encrypt
- Secure, production-ready configuration following best practices
- Easy deployment via GitHub Actions or manual scripts
- Automated backups and maintenance

## 🏗️ Architecture

```
Hetzner VPS (Ubuntu 24.04 LTS)
├── Nginx (Web Server)
├── PHP 8.3-FPM (PHP Processor)
├── Composer (Dependency Management)
├── Certbot (SSL Certificates)
├── Fail2ban (Security)
└── UFW (Firewall)

/var/www/
├── cms.project1.com/
│   ├── public/          # Document root
│   ├── content/
│   ├── storage/
│   └── .env
├── cms.project2.com/
│   ├── public/
│   ├── content/
│   ├── storage/
│   └── .env
└── ...
```

## 🚀 Quick Start

### 1. Initial Server Setup (One-Time)

On your **local machine**, run:

```bash
# Upload and execute the server setup script
scp server-setup/setup-server.sh root@YOUR_SERVER_IP:/tmp/
ssh root@YOUR_SERVER_IP "bash /tmp/setup-server.sh"
```

This will:

- Install Nginx, PHP 8.3, Composer, Certbot, Fail2ban, UFW
- Configure security settings
- Set up firewall rules
- Create deployment user
- Optimize PHP and Nginx for Kirby CMS

### 2. Deploy a New CMS Instance

Choose **Option A** (GitHub Actions - Recommended) or **Option B** (Manual):

#### Option A: Automated Deployment via GitHub Actions

1. Configure GitHub Secrets in your repository:

   - `HETZNER_HOST` - Your server IP or hostname
   - `HETZNER_USER` - SSH user (default: `deploy`)
   - `DEPLOY_KEY_PRIVATE` - SSH private key
   - `HETZNER_PATH` - Site directory name (e.g., `cms.yourproject.com`)
   - `DEPLOY_URL` - Netlify build hook URL

2. Push to `main` branch - automatic deployment happens!

#### Option B: Manual Deployment

On your **local machine** (from this directory):

```bash
./deploy-site.sh cms.yourproject.com
```

Follow the interactive prompts to configure your site.

### 3. Configure SSL Certificate

SSH into your server and run:

```bash
sudo /usr/local/bin/add-ssl-cert cms.yourproject.com admin@yourproject.com
```

## 📁 Files in This Directory

### Setup Scripts

- **`setup-server.sh`** - Initial VPS configuration (run once)
- **`deploy-site.sh`** - Deploy/update a CMS instance (run from local machine)
- **`optimize-server-performance.sh`** - Apply performance optimizations to server
- **`fix-kirby-permissions.sh`** - Fix file permissions for Kirby sites
- **`add-site.sh`** - Add new site on server (run on server) - created by setup-server.sh
- **`remove-site.sh`** - Remove site from server (run on server) - created by setup-server.sh

### Configuration Templates

- **`nginx-site.conf.template`** - Nginx virtual host template (optimized for Kirby)

### Documentation

- **`PERFORMANCE-OPTIMIZATION.md`** - Comprehensive performance tuning guide
- **`PERMISSIONS.md`** - Kirby permissions reference and troubleshooting
- **`QUICK-REFERENCE.md`** - Quick command reference
- **`EXISTING-SERVER-SETUP.md`** - Guide for existing Hetzner server setup
- **`MIGRATE-CHILDREN.md`** - Guide for migrating child repositories

### GitHub Actions

- **`../.github/workflows/deploy-hetzner.yml`** - Automated deployment workflow

## 🔒 Security Best Practices

The setup automatically implements:

✅ **Firewall (UFW)** - Only ports 22, 80, 443 open ✅ **Fail2ban** - Protects against brute force
attacks ✅ **SSH Key Authentication** - Password auth disabled ✅ **SSL/TLS** - Let's Encrypt
certificates with auto-renewal ✅ **Directory Protection** - Sensitive directories blocked via Nginx
✅ **File Permissions** - Proper ownership and permissions ✅ **Regular Updates** - Automatic
security updates enabled

## 📦 Managing Multiple Sites

### Add a New Site

```bash
# On server
sudo /usr/local/bin/add-site cms.newproject.com

# Then deploy from local machine or via GitHub Actions
```

### List All Sites

```bash
# On server
ls -la /var/www/
```

### Remove a Site

```bash
# On server
sudo /usr/local/bin/remove-site cms.oldproject.com
```

## 🔄 Deployment Workflow

### Via GitHub Actions (Recommended)

1. Make changes to your CMS repository
2. Commit and push to `main` branch
3. GitHub Actions automatically:
   - Syncs files to server (excluding content, media, vendor)
   - Creates `.env` file
   - Runs `composer install`
   - Clears cache
   - Triggers Netlify rebuild

### Via Manual Script

```bash
# From your local machine
cd /path/to/cms.baukasten
./server-setup/deploy-site.sh cms.yourproject.com
```

## 💾 Backups

### Automated Daily Backups

Backups run automatically at 2 AM daily:

```bash
# Backup location: /var/backups/kirby-cms/
# Retention: 30 days
```

### Manual Backup

```bash
# On server
sudo /usr/local/bin/backup-kirby-site cms.yourproject.com
```

### Restore from Backup

```bash
# On server
sudo /usr/local/bin/restore-kirby-site cms.yourproject.com /var/backups/kirby-cms/cms.yourproject.com-20250106_020000.tar.gz
```

## 🔧 Troubleshooting

### Check Nginx Status

```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

### Check PHP-FPM Status

```bash
sudo systemctl status php8.3-fpm
```

### View Logs

```bash
# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Site-specific logs
sudo tail -f /var/log/nginx/cms.yourproject.com.error.log

# PHP-FPM logs
sudo tail -f /var/log/php8.3-fpm.log
```

### Permission Issues

```bash
# Fix permissions for a site
sudo chown -R deploy:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
sudo chmod -R 775 /var/www/cms.yourproject.com/public/media
sudo chmod -R 775 /var/www/cms.yourproject.com/site/cache
```

### SSL Certificate Issues

```bash
# Renew certificate manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

## 📊 Performance Monitoring

### Check Resource Usage

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Site-specific disk usage
du -sh /var/www/cms.yourproject.com/*
```

### Optimize PHP-FPM

Edit `/etc/php/8.3/fpm/pool.d/www.conf`:

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

## 🔄 Updates and Maintenance

### Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Update Composer Dependencies

```bash
cd /var/www/cms.yourproject.com
sudo -u deploy composer update
```

### Clear Kirby Cache

```bash
cd /var/www/cms.yourproject.com
sudo -u deploy rm -rf storage/cache/* storage/sessions/*
```

## 📞 Support

For issues or questions:

1. Check the troubleshooting section above
2. Review logs for error messages
3. Consult [Kirby CMS Documentation](https://getkirby.com/docs)
4. Check [Nginx Documentation](https://nginx.org/en/docs/)

## 🔐 SSH Key Setup

If you haven't set up SSH keys yet:

```bash
# On your local machine
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@YOUR_SERVER_IP

# Add to GitHub Secrets
cat ~/.ssh/id_ed25519  # Copy this as DEPLOY_KEY_PRIVATE
```

## 📝 DNS Configuration

For each CMS instance, configure DNS:

```
Type: A
Name: cms.yourproject.com
Value: YOUR_SERVER_IP
TTL: 3600
```

## ⚡ Performance Optimization

After initial setup, optimize your server for maximum performance:

```bash
# Upload and run optimization script
scp server-setup/optimize-server-performance.sh hetzner-root:/tmp/
ssh hetzner-root "bash /tmp/optimize-server-performance.sh"
```

**See `PERFORMANCE-OPTIMIZATION.md` for complete performance tuning guide.**

---

## 🎯 Next Steps

1. ✅ Run `setup-server.sh` on your fresh Hetzner VPS
2. ✅ Configure SSH keys and GitHub Secrets
3. ✅ Deploy your first CMS instance
4. ✅ Set up SSL certificate
5. ✅ Configure DNS
6. ✅ **Optimize server performance** (run `optimize-server-performance.sh`)
7. ✅ Enable Kirby page cache in each site's `config.php`

---

## 📚 Complete Documentation

- **Quick Start:** This file
- **Performance:** `PERFORMANCE-OPTIMIZATION.md`
- **Permissions:** `PERMISSIONS.md`
- **Commands:** `QUICK-REFERENCE.md`
- **Migration:** `MIGRATE-CHILDREN.md`
- **Existing Server:** `EXISTING-SERVER-SETUP.md`

---

**Created for Baukasten CMS Template**  
**Last Updated:** October 2025  
**Optimized for:** Hetzner VPS + Kirby 5.1.2+
