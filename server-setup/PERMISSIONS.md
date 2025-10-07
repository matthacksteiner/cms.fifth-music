# Kirby CMS Permissions Guide

This document explains the file ownership and permissions structure used in the Baukasten Kirby CMS
deployments.

## Overview

Kirby needs specific directories to be writable by both:

- **Deploy user** (e.g., `kirbyuser`) - for SFTP uploads, backups, deployments
- **Web server** (`www-data`) - for PHP operations like cache, accounts, sessions

## Required Permissions

### Writable Directories

These directories MUST have `kirbyuser:www-data` ownership with `2775` permissions:

```
content/                    # User-uploaded content files
site/languages/             # Language configuration files
site/accounts/              # User accounts (rarely used, created by PHP)
site/sessions/              # User sessions (rarely used, created by PHP)
site/cache/                 # Panel cache (rarely used, created by PHP)
public/media/               # Generated thumbnails and media
storage/accounts/           # User account storage
storage/cache/              # Application cache
storage/sessions/           # Session storage
```

### Permission Breakdown

- **Owner:** `kirbyuser` (deploy user)
- **Group:** `www-data` (web server group)
- **Directory Permissions:** `2775` (drwxrwsr-x)
  - `2` = setgid bit (new files inherit `www-data` group)
  - `7` = owner has rwx (read, write, execute)
  - `7` = group has rwx
  - `5` = others have rx (read, execute only)
- **File Permissions:** `664` (rw-rw-r--)
  - Owner and group can read/write
  - Others can only read

### Why These Permissions?

1. **`kirbyuser:www-data` ownership:**

   - `kirbyuser` can upload/modify via SFTP and run backups
   - `www-data` (PHP-FPM) can write cache, sessions, accounts

2. **`2775` directory permissions:**

   - Deploy user and web server can both create/modify files
   - Setgid (2) ensures new files inherit `www-data` group
   - Execute bit allows accessing directory contents

3. **`664` file permissions:**
   - Both user and group can read/write
   - No execute needed for files
   - Others can read (for web serving)

## Common Permission Issues

### Problem: Backup Plugin Doesn't Work

**Symptom:** Backup plugin shows errors or can't create backups

**Cause:** `storage/` directories are owned by `www-data:www-data` with `755`

**Fix:**

```bash
ssh hetzner-root "cd /var/www/YOUR-SITE && \
  chown -R kirbyuser:www-data storage && \
  find storage -type d -exec chmod 2775 {} + && \
  find storage -type f -exec chmod 664 {} +"
```

### Problem: Can't Delete Cache from SFTP

**Symptom:** Permission denied when trying to delete cache files via SFTP

**Cause:** PHP created cache files owned by `www-data:www-data`

**Fix:**

```bash
ssh hetzner-root "cd /var/www/YOUR-SITE && \
  chown -R kirbyuser:www-data storage/cache && \
  find storage/cache -type d -exec chmod 2775 {} +"
```

### Problem: Content Upload Fails

**Symptom:** Can't upload content files via SFTP

**Cause:** Wrong ownership/permissions on `content/` directory

**Fix:**

```bash
ssh hetzner-root "cd /var/www/YOUR-SITE && \
  chown -R kirbyuser:www-data content && \
  find content -type d -exec chmod 2775 {} + && \
  find content -type f -exec chmod 664 {} +"
```

## Automated Setup

The `add-site` script automatically creates all required directories with correct permissions:

```bash
sudo /usr/local/bin/add-site cms.example.com kirbyuser
```

This creates:

- All writable directories
- Default English language file (`site/languages/en.php`)
- Panel plugin asset placeholders (`public/media/plugins/index.{css,js}`)
- Correct ownership and permissions

## Manual Permission Fix

If permissions get messed up, run this comprehensive fix:

```bash
ssh hetzner-root "cd /var/www/YOUR-SITE && \
  chown -R kirbyuser:www-data content site/languages site/accounts site/sessions site/cache public/media storage && \
  find content site/languages site/accounts site/sessions site/cache public/media storage -type d -exec chmod 2775 {} + && \
  find content site/languages site/accounts site/sessions site/cache public/media storage -type f -exec chmod 664 {} +"
```

## Deployment Workflow

The GitHub Actions workflow handles permissions correctly by:

1. **Excluding writable dirs from rsync:**
   `--exclude="content" --exclude="storage/cache" --exclude="storage/sessions"`
2. **Using bash for cache clearing:**
   `bash -c 'rm -rf storage/cache/* storage/sessions/* 2>/dev/null || true'`
   - Wraps command in bash (handles fish shell on server)
   - Suppresses permission errors (`2>/dev/null || true`)
   - Gracefully fails if some files can't be deleted

## Why `setgid` (2 in 2775)?

The setgid bit ensures that when PHP creates new files/directories:

- They inherit the `www-data` **group** (not user)
- This allows `kirbyuser` to still modify them
- Without setgid, PHP-created files would be `www-data:www-data` and inaccessible to `kirbyuser`

## Checking Permissions

```bash
# Check directory ownership and permissions
ssh hetzner-kirby "ls -la /var/www/cms.example.com/"

# Check specific writable directories
ssh hetzner-kirby "ls -la /var/www/cms.example.com/storage/"

# Find directories with wrong permissions
ssh hetzner-kirby "find /var/www/cms.example.com/storage -type d ! -perm 2775"

# Find files with wrong permissions
ssh hetzner-kirby "find /var/www/cms.example.com/storage -type f ! -perm 664"
```

## Best Practices

1. **Always use `add-site` script** - Don't create directories manually
2. **Let PHP create what it needs** - Cache, sessions, accounts will be created on first use
3. **Don't change permissions manually** - Use the automated fixes above
4. **Monitor for permission drift** - Check after deployments
5. **Use fish-compatible commands** - Always wrap wildcards in `bash -c` when using fish shell
