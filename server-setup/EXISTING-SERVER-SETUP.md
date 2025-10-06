# Quick Setup for Existing Hetzner Server

Since you already have a Hetzner VPS with `kirbyuser` and SSH configured as `hetzner-kirby`, here's how to use the setup scripts with your existing configuration.

## Your Current Setup

- **SSH Config Alias**: `hetzner-kirby`
- **Existing User**: `kirbyuser`
- **SSH Command**: `ssh hetzner-kirby`

## Step 1: Run Server Setup (One-Time)

Upload and run the setup script. When prompted for username, enter `kirbyuser`:

```bash
# Upload setup script
scp server-setup/setup-server.sh kirbyuser@hetzner-kirby:/tmp/

# SSH into your server (you may need root for initial setup)
ssh hetzner-kirby

# If you have sudo access as kirbyuser:
sudo bash /tmp/setup-server.sh
# When prompted for "Enter deployment username", type: kirbyuser

# OR if you need to run as root:
# ssh root@YOUR_SERVER_IP
# bash /tmp/setup-server.sh
# When prompted for "Enter deployment username", type: kirbyuser
```

**What this does:**
- Installs Nginx, PHP 8.3, Composer, Certbot, etc.
- Configures `kirbyuser` for deployments (adds to www-data group, sudo permissions)
- Sets up firewall and security
- Creates management scripts
- Configures automated backups

## Step 2: Deploy Your First CMS Site

Use the deploy script with your SSH alias:

```bash
# From your local machine, in the cms.baukasten directory
./server-setup/deploy-site.sh cms.yourproject.com hetzner-kirby kirbyuser
```

Or use it interactively (just provide the site domain):

```bash
./server-setup/deploy-site.sh cms.yourproject.com
# When prompted for server: hetzner-kirby
# When prompted for user: kirbyuser
```

**What this does:**
- Creates site directory on server
- Syncs your CMS files via rsync
- Creates `.env` file
- Installs Composer dependencies
- Sets correct permissions
- Clears cache

## Step 3: Add SSL Certificate

```bash
ssh hetzner-kirby
sudo /usr/local/bin/add-ssl-cert cms.yourproject.com admin@yourproject.com
```

## Step 4: Configure DNS

Point your domain to your Hetzner VPS IP:

```
Type: A
Name: cms.yourproject.com
Value: YOUR_HETZNER_IP
TTL: 3600
```

## Quick Command Reference

### Deploy a site

```bash
# Full command
./server-setup/deploy-site.sh cms.mysite.com hetzner-kirby kirbyuser

# Or let it prompt you
./server-setup/deploy-site.sh cms.mysite.com
```

### Manage sites on server

```bash
# SSH into your server
ssh hetzner-kirby

# Add new site
sudo /usr/local/bin/add-site cms.newsite.com kirbyuser

# Add SSL
sudo /usr/local/bin/add-ssl-cert cms.newsite.com admin@example.com

# Backup site
sudo /usr/local/bin/backup-kirby-site cms.mysite.com

# List all sites
ls -la /var/www/

# View logs
sudo tail -f /var/log/nginx/cms.mysite.com.error.log
```

### Update deployed site

```bash
# Just run deploy again - it will sync changes
./server-setup/deploy-site.sh cms.mysite.com hetzner-kirby kirbyuser
```

## GitHub Actions Setup (Optional)

If you want automated deployment on git push, add these secrets to your GitHub repository:

- `HETZNER_HOST` = The hostname from your SSH config: `hetzner-kirby` (or the actual IP)
- `HETZNER_USER` = `kirbyuser`
- `DEPLOY_KEY_PRIVATE` = Your SSH private key (contents of `~/.ssh/id_ed25519` or similar)
- `HETZNER_PATH` = `cms.yourproject.com`
- `DEPLOY_URL` = Your Netlify build hook URL

Then just push to main:

```bash
git push origin main
# GitHub Actions will automatically deploy to your server!
```

## Directory Structure on Server

After deployment, your site will be at:

```
/var/www/cms.yourproject.com/
├── public/              # Nginx points here
├── content/             # Your content (not synced from git)
├── storage/             # Cache & sessions
├── site/                # Your config & plugins
├── vendor/              # Composer dependencies
└── .env                 # Environment variables
```

## Troubleshooting

### Permission issues

```bash
ssh hetzner-kirby
sudo chown -R kirbyuser:www-data /var/www/cms.yourproject.com
sudo chmod -R 755 /var/www/cms.yourproject.com
sudo chmod -R 775 /var/www/cms.yourproject.com/storage
sudo chmod -R 775 /var/www/cms.yourproject.com/public/media
```

### Check services

```bash
ssh hetzner-kirby
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
```

### View logs

```bash
ssh hetzner-kirby
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/cms.yourproject.com.error.log
```

## What's Different from Fresh Setup?

Since you're using an existing server:

1. ✅ Your SSH alias `hetzner-kirby` works everywhere
2. ✅ Uses your existing `kirbyuser` instead of creating new `deploy` user
3. ✅ Server setup script will detect and configure existing user
4. ✅ All scripts now accept custom usernames and SSH aliases

## Next Steps

1. ✅ Run `setup-server.sh` on your VPS (enter `kirbyuser` when prompted)
2. ✅ Deploy your first CMS: `./server-setup/deploy-site.sh cms.yourproject.com hetzner-kirby kirbyuser`
3. ✅ Add SSL certificate
4. ✅ Visit `https://cms.yourproject.com/panel`

That's it! 🎉

---

**Note**: The setup script will work with your existing `kirbyuser` and won't create a new user. It will just add the necessary permissions and configurations to `kirbyuser` for CMS deployments.

