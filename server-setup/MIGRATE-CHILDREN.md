# Migrating Child CMS Repositories from Uberspace to Hetzner

This guide shows how to migrate child repositories (created from the cms.baukasten template) from Uberspace to your Hetzner VPS.

## 📋 Quick Overview

For each child CMS project, you need to:
1. ✅ Copy `deploy-hetzner.yml` workflow
2. ✅ Set 4 GitHub Secrets (2 are project-specific)
3. ✅ Push to deploy
4. ✅ Add SSL certificate
5. ✅ Update DNS

**Time per project**: ~5 minutes

---

## 🚀 **Option A: Use the Automated Script** (Recommended)

### Usage

```bash
cd /Users/matthiashacksteiner/Sites/baukasten-stack/cms.baukasten/server-setup

./migrate-child-to-hetzner.sh \
  /path/to/child/repo \
  cms.childname.matthiashacksteiner.net \
  https://api.netlify.com/build_hooks/NETLIFY_HOOK_ID
```

### Examples

```bash
# Migrate cms.dr-miller
./migrate-child-to-hetzner.sh \
  ../../cms.dr-miller \
  cms.dr-miller.matthiashacksteiner.net \
  https://api.netlify.com/build_hooks/DR_MILLER_HOOK_ID

# Migrate cms.kinderlosfrei
./migrate-child-to-hetzner.sh \
  ../../cms.kinderlosfrei \
  cms.kinderlosfrei.matthiashacksteiner.net \
  https://api.netlify.com/build_hooks/KINDERLOSFREI_HOOK_ID

# Migrate cms.super
./migrate-child-to-hetzner.sh \
  ../../cms.super \
  cms.super.matthiashacksteiner.net \
  https://api.netlify.com/build_hooks/SUPER_HOOK_ID
```

### What the Script Does

1. Copies `deploy-hetzner.yml` to child repo
2. Sets all required GitHub Secrets
3. Extracts SSH keys from 1Password
4. Commits and pushes to trigger deployment
5. The deployment script on the server now:
   - creates required writable dirs (content, site/languages, accounts/sessions/cache, storage, public/media/plugins)
   - ensures default `site/languages/en.php` exists
   - pre-creates empty `public/media/plugins/index.css/js` so Panel has no 404s on first load
   - fixes permissions (dirs 2775, files 664)
   - clears caches
6. Shows next manual steps

---

## 🛠️ **Option B: Manual Migration** (Step-by-Step)

If you prefer to do it manually for each child:

### Step 1: Copy Workflow

```bash
cd /path/to/cms.yourchild
cp ../cms.baukasten/.github/workflows/deploy-hetzner.yml .github/workflows/
```

### Step 2: Set GitHub Secrets

```bash
# In the child repository directory
echo "91.98.120.110" | gh secret set DEPLOYMENT_HOST
echo "kirbyuser" | gh secret set DEPLOYMENT_USER
echo "cms.yourchild.matthiashacksteiner.net" | gh secret set DEPLOYMENT_PATH
echo "https://api.netlify.com/build_hooks/YOUR_HOOK" | gh secret set DEPLOY_URL

# Reuse SSH keys from 1Password
op item get "Hetzner-kirbyuser" --fields "Private-Key" --reveal | sed '1d;$d' | gh secret set DEPLOY_KEY_PRIVATE
op item get "SSH-Key uberspace" --fields "Private-Key" --reveal | sed '1d;$d' | gh secret set UBERSPACE_DEPLOY_KEY
```

### Step 3: Deploy

```bash
git add .github/workflows/deploy-hetzner.yml
git commit -m "Add Hetzner deployment"
git push origin main
```

### Step 4: Add SSL (After Deployment)

```bash
ssh hetzner-root
/usr/local/bin/add-ssl-cert cms.yourchild.matthiashacksteiner.net contact@matthiashacksteiner.net
```

### Step 5: Update DNS on Gandi

Change from:
```
cms.yourchild 10800 IN CNAME matthiashacksteiner.net.
```

To:
```
cms.yourchild 10800 IN A 91.98.120.110
```

---

## 📊 **GitHub Secrets Summary**

### Shared Secrets (Same for All Children)
- `DEPLOYMENT_HOST` = `91.98.120.110`
- `DEPLOYMENT_USER` = `kirbyuser`
- `DEPLOY_KEY_PRIVATE` = Hetzner SSH key from 1Password
- `UBERSPACE_DEPLOY_KEY` = Uberspace SSH key from 1Password

### Project-Specific Secrets (Different for Each)
- `DEPLOYMENT_PATH` = `cms.childname.matthiashacksteiner.net`
- `DEPLOY_URL` = Netlify build hook for THIS project

---

## ✅ **Migration Checklist**

For each child project:

- [ ] Run migration script OR copy workflow manually
- [ ] Verify GitHub Actions completes successfully
- [ ] SSH to server and add SSL certificate
- [ ] Update DNS A record on Gandi
- [ ] Wait for DNS propagation (1-3 hours)
- [ ] Test: `https://cms.childname.matthiashacksteiner.net/panel`
- [ ] Verify JSON API: `https://cms.childname.matthiashacksteiner.net/global.json`

---

## 🔄 **Deployment Behavior After Migration**

Once migrated, every `git push origin main` will deploy to:
- ✅ **Hetzner VPS** (your new server)
- ✅ **Uberspace** (your old server - unless you disable it)

### To Disable Uberspace Deployment (Optional)

Once you're confident Hetzner is working:

```bash
# In child repository
mv .github/workflows/deploy.yml .github/workflows/deploy.yml.disabled
git add .github/workflows/
git commit -m "Disable Uberspace deployment"
git push
```

---

## 💡 **Pro Tips**

1. **Migrate one at a time** - Test each before moving to the next
2. **Keep Uberspace active** during migration for safety
3. **Monitor GitHub Actions** - Watch for any deployment errors
4. **Test JSON API** after each migration
5. **Lower DNS TTL** before migration for faster switching (optional)

---

## 🎯 **Summary**

**Easiest Method**: Run the migration script for each child
**Time**: ~5 minutes per project
**Risk**: Low (both servers deploy, easy rollback)

---

**Ready to migrate your first child? Just run:**

```bash
cd /Users/matthiashacksteiner/Sites/baukasten-stack/cms.baukasten/server-setup
./migrate-child-to-hetzner.sh /path/to/child DOMAIN NETLIFY_HOOK
```
