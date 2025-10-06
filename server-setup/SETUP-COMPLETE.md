# ✅ Hetzner VPS Setup Files Created

All automated setup files for hosting multiple Kirby CMS instances on Hetzner VPS have been created
successfully!

## 📁 Created Files

### Server Setup Scripts (`server-setup/`)

- ✅ `setup-server.sh` - Complete automated server setup (executable)
- ✅ `deploy-site.sh` - Manual deployment script (executable)
- ✅ `nginx-site.conf.template` - Nginx configuration template
- ✅ `README.md` - Comprehensive setup documentation
- ✅ `QUICK-REFERENCE.md` - Command quick reference guide

### GitHub Actions (`.github/workflows/`)

- ✅ `deploy-hetzner.yml` - Automated deployment workflow

### Documentation (`docs/`)

- ✅ `deployment-hetzner.md` - Complete deployment guide
- ✅ Updated `deployment-hosting.md` - Added Hetzner quick start
- ✅ Updated `index.md` - Added Hetzner documentation link

### Main Files

- ✅ Updated `README.md` - Added Hetzner deployment section

## 🎯 Next Steps

### 1. Review the Files

Check out the created files to understand the setup:

```bash
cd /Users/matthiashacksteiner/Sites/baukasten-stack/cms.baukasten
cat server-setup/README.md
```

### 2. Get a Hetzner VPS

- Go to [Hetzner Cloud](https://www.hetzner.com/cloud)
- Create an account
- Spin up an Ubuntu 24.04 LTS VPS
- Choose size based on needs (CX11 for 1-2 sites, CX21 for 3-5 sites)
- Note the IP address

### 3. Run Initial Setup

Once you have your VPS:

```bash
# Upload setup script
scp server-setup/setup-server.sh root@YOUR_VPS_IP:/tmp/

# Run setup (takes 5-10 minutes)
ssh root@YOUR_VPS_IP "bash /tmp/setup-server.sh"
```

### 4. Add Your SSH Key

```bash
# Copy your public key to the server
cat ~/.ssh/id_ed25519.pub | ssh root@YOUR_VPS_IP "cat >> /home/deploy/.ssh/authorized_keys"
```

If you don't have an SSH key:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 5. Deploy Your First Site

**Option A: Manual Deployment**

```bash
./server-setup/deploy-site.sh cms.yourproject.com YOUR_VPS_IP
```

**Option B: GitHub Actions**

1. Add GitHub Secrets:

   - `HETZNER_HOST` = Your VPS IP
   - `HETZNER_USER` = `deploy`
   - `DEPLOY_KEY_PRIVATE` = Contents of `~/.ssh/id_ed25519`
   - `HETZNER_PATH` = `cms.yourproject.com`
   - `DEPLOY_URL` = Netlify build hook URL

2. Push to main:
   ```bash
   git add .
   git commit -m "Add Hetzner VPS setup"
   git push origin main
   ```

### 6. Configure DNS

Point your domain to the VPS:

```
Type: A
Name: cms.yourproject.com
Value: YOUR_VPS_IP
TTL: 3600
```

### 7. Add SSL Certificate

```bash
ssh deploy@YOUR_VPS_IP
sudo /usr/local/bin/add-ssl-cert cms.yourproject.com admin@yourproject.com
```

### 8. Access Your CMS

Visit `https://cms.yourproject.com/panel` to set up your Kirby CMS!

## 📚 Documentation

- **Main Setup Guide**: `server-setup/README.md`
- **Complete Deployment Guide**: `docs/deployment-hetzner.md`
- **Quick Reference**: `server-setup/QUICK-REFERENCE.md`

## 🔧 What the Setup Includes

### Server Software

- ✅ Nginx (web server)
- ✅ PHP 8.3-FPM (with all required extensions)
- ✅ Composer (dependency management)
- ✅ Certbot (free SSL certificates)
- ✅ UFW Firewall (ports 22, 80, 443)
- ✅ Fail2ban (brute force protection)

### Security Features

- ✅ Firewall configured
- ✅ Fail2ban active
- ✅ SSH key authentication
- ✅ Automatic SSL certificates
- ✅ Directory protection in Nginx
- ✅ Security headers enabled

### Management Tools

- ✅ `add-site` - Create new CMS instance
- ✅ `remove-site` - Remove CMS instance
- ✅ `add-ssl-cert` - Add SSL certificate
- ✅ `backup-kirby-site` - Backup single site
- ✅ `backup-all-kirby-sites` - Backup all sites
- ✅ `restore-kirby-site` - Restore from backup
- ✅ Automated daily backups (2 AM)

### Deployment Options

- ✅ GitHub Actions (automated)
- ✅ Manual script (interactive)
- ✅ Rsync-based (efficient)

## 💡 Tips

1. **Start Small**: Begin with CX11 VPS (~€4/month) and upgrade as needed
2. **Use GitHub Actions**: Automated deployment is easier and less error-prone
3. **Regular Backups**: Daily automated backups are configured, but consider offsite backups too
4. **Monitor Resources**: Use `htop` to monitor CPU/RAM usage
5. **Keep Updated**: Regularly update system packages and Kirby CMS

## 🆘 Need Help?

- **Quick Commands**: See `server-setup/QUICK-REFERENCE.md`
- **Full Guide**: See `docs/deployment-hetzner.md`
- **Troubleshooting**: Check logs with `sudo tail -f /var/log/nginx/error.log`
- **Kirby Docs**: https://getkirby.com/docs

## ✨ Features Compared to Uberspace

| Feature            | Hetzner VPS                     | Uberspace                     |
| ------------------ | ------------------------------- | ----------------------------- |
| **Cost**           | €4-19/month (fixed)             | €5+/month (pay what you want) |
| **Control**        | Full root access                | User-level access             |
| **Performance**    | Dedicated resources             | Shared resources              |
| **Setup**          | Automated (5-10 min)            | Mostly managed                |
| **Multiple Sites** | Unlimited (resource-limited)    | Multiple allowed              |
| **Scalability**    | Easy VPS upgrades               | Limited                       |
| **Best For**       | Multiple projects, full control | Simple single projects        |

## 🎉 You're Ready!

Everything is set up and ready to go. You now have:

- ✅ Production-ready server setup scripts
- ✅ Automated deployment workflows
- ✅ Comprehensive documentation
- ✅ Security best practices built-in
- ✅ Management tools for multiple sites
- ✅ Automated backup system

**Happy deploying! 🚀**

---

**Created**: January 2025 **For**: Baukasten CMS Template **Target**: Hetzner VPS (Ubuntu 24.04 LTS)
