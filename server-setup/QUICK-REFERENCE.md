# Quick Reference Guide

Quick command reference for managing multiple Kirby CMS instances on Hetzner VPS.

## 🚀 Initial Setup

```bash
# Upload setup script to VPS
scp server-setup/setup-server.sh root@YOUR_SERVER_IP:/tmp/

# Run setup on VPS (one-time)
ssh root@YOUR_SERVER_IP "bash /tmp/setup-server.sh"

# Add your SSH key to deploy user
cat ~/.ssh/id_ed25519.pub | ssh root@YOUR_SERVER_IP "cat >> /home/deploy/.ssh/authorized_keys"
```

## 📦 Deploy a Site

### Manual Deployment

```bash
# From your local machine
./server-setup/deploy-site.sh cms.yourproject.com YOUR_SERVER_IP
```

### GitHub Actions Deployment

1. Add GitHub Secrets:
   - `HETZNER_HOST` = Your server IP
   - `HETZNER_USER` = `deploy`
   - `DEPLOY_KEY_PRIVATE` = Contents of `~/.ssh/id_ed25519`
   - `HETZNER_PATH` = `cms.yourproject.com`
   - `DEPLOY_URL` = Netlify build hook URL

2. Push to main:
   ```bash
   git push origin main
   ```

## 🔒 SSL Certificate

```bash
# On server
sudo /usr/local/bin/add-ssl-cert cms.yourproject.com admin@yourproject.com
```

## 🛠️ Site Management (On Server)

```bash
# Add new site
sudo /usr/local/bin/add-site cms.newproject.com

# Remove site (with backup)
sudo /usr/local/bin/remove-site cms.oldproject.com

# List all sites
ls -la /var/www/

# Backup site
sudo /usr/local/bin/backup-kirby-site cms.yourproject.com

# Backup all sites
sudo /usr/local/bin/backup-all-kirby-sites

# Restore from backup
sudo /usr/local/bin/restore-kirby-site cms.yourproject.com /var/backups/kirby-cms/BACKUP_FILE.tar.gz
```

## 📊 Monitoring

```bash
# Check service status
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
sudo systemctl status fail2ban

# View logs
sudo tail -f /var/log/nginx/cms.yourproject.com.error.log
sudo tail -f /var/log/nginx/cms.yourproject.com.access.log
sudo tail -f /var/log/php8.3-fpm.log

# Check resources
htop
df -h
du -sh /var/www/cms.yourproject.com/*

# Firewall status
sudo ufw status
```

## 🔧 Maintenance

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Composer dependencies
cd /var/www/cms.yourproject.com
composer update

# Writable dirs and cache
# The deploy script creates: content/, site/languages/, site/{accounts,sessions,cache}/, storage/, public/media/plugins/
# It also clears storage/cache and storage/sessions and adds empty media/plugins files to avoid first-load 404s.

# Reload services
sudo service nginx reload
sudo service php8.3-fpm reload

# Test Nginx config
sudo nginx -t

# Restart services
sudo systemctl restart nginx
sudo systemctl restart php8.3-fpm
```

## 🔐 SSL Management

```bash
# Test certificate renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# List certificates
sudo certbot certificates

# Delete certificate
sudo certbot delete --cert-name cms.yourproject.com
```

## 📝 File Permissions

```bash
# Fix permissions for a site
sudo chown -R deploy:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
sudo chmod -R 775 /var/www/cms.yourproject.com/public/media
sudo chmod -R 775 /var/www/cms.yourproject.com/site/cache
```

## 🗂️ Directory Structure

```
/var/www/cms.yourproject.com/
├── public/              # Document root (Nginx points here)
├── content/             # Content files (not in git)
├── storage/             # Cache & sessions (not in git)
├── public/media/        # User uploads (not in git)
├── vendor/              # Composer dependencies (auto-installed)
├── kirby/               # Kirby core (auto-installed)
├── site/                # Your configuration
│   ├── blueprints/
│   ├── config/
│   ├── plugins/
│   └── templates/
├── composer.json
└── .env                 # Environment config (auto-created)
```

## 🔍 Troubleshooting

### Site not loading

```bash
# Check Nginx
sudo nginx -t
sudo systemctl status nginx

# Check PHP-FPM
sudo systemctl status php8.3-fpm

# Check logs
sudo tail -f /var/log/nginx/error.log
```

### Permission errors

```bash
# Fix ownership and permissions
sudo chown -R deploy:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
```

### Composer errors

```bash
# Clear Composer cache
composer clear-cache

# Reinstall dependencies
rm -rf vendor
composer install --no-dev --optimize-autoloader
```

## 🔗 Important Paths

| Path | Purpose |
|------|---------|
| `/var/www/` | All sites |
| `/etc/nginx/sites-available/` | Nginx configs |
| `/etc/nginx/sites-enabled/` | Active sites |
| `/var/log/nginx/` | Nginx logs |
| `/var/log/php8.3-fpm.log` | PHP logs |
| `/var/backups/kirby-cms/` | Backups |
| `/usr/local/bin/` | Management scripts |
| `/home/deploy/.ssh/` | SSH keys |

## 📞 Get Help

- **Full Documentation**: See `server-setup/README.md`
- **Deployment Guide**: See `docs/deployment-hetzner.md`
- **Kirby Docs**: https://getkirby.com/docs
- **Nginx Docs**: https://nginx.org/en/docs/

## 💡 Common Tasks

### Deploy after code changes

```bash
# Via GitHub Actions: just push
git push origin main

# Or manual:
./server-setup/deploy-site.sh cms.yourproject.com
```

### Add a new CMS instance

```bash
# 1. On server: create site
ssh deploy@YOUR_SERVER_IP
sudo /usr/local/bin/add-site cms.newproject.com
exit

# 2. From local: deploy
./server-setup/deploy-site.sh cms.newproject.com

# 3. On server: add SSL
ssh deploy@YOUR_SERVER_IP
sudo /usr/local/bin/add-ssl-cert cms.newproject.com admin@newproject.com
```

### Update Kirby CMS

```bash
ssh deploy@YOUR_SERVER_IP
cd /var/www/cms.yourproject.com
composer update getkirby/cms
```

---

**Pro Tip**: Save this file to your local machine for quick reference!

