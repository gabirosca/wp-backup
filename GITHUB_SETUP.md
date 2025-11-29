# Publishing to GitHub

Follow these steps to publish the WordPress Backup tool to GitHub.

## Step 1: Create Repository on GitHub

1. Go to https://github.com/gabirosca
2. Click the **"+"** button (top right) → **"New repository"**
3. Repository settings:
   - **Repository name:** `wp-backup`
   - **Description:** `Complete WordPress backup, migration & restore tool. Single standalone script with WP-CLI integration.`
   - **Visibility:** Public
   - **Initialize:** Do NOT check any boxes (no README, no .gitignore, no license)
4. Click **"Create repository"**

## Step 2: Prepare Local Files

First, clean up the directory:

```bash
cd /home/tmfestival/backups/script

# Remove old files (keep only needed ones)
rm -f wp-backup.config wp-backup.config.example
rm -f wp-backup-helper.sh wp-restore.sh
rm -f QUICKSTART.md FILES_OVERVIEW.txt .cleanup
```

Your directory should now contain only:
```
wp-backup.sh          # Main script
README.md             # Documentation
LICENSE               # License file
.gitignore            # Git ignore file
CONTRIBUTING.md       # Contribution guide
GITHUB_SETUP.md       # This file (optional, can delete after setup)
```

## Step 3: Initialize Git Repository

```bash
cd /home/tmfestival/backups/script

# Initialize git
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: WordPress Backup, Migration & Restore Tool v1.0.0"
```

## Step 4: Connect to GitHub

```bash
# Add remote (replace with your actual GitHub username if different)
git remote add origin https://github.com/gabirosca/wp-backup.git

# Set main branch
git branch -M main

# Push to GitHub
git push -u origin main
```

**Note:** You'll be prompted for GitHub credentials. Use:
- **Username:** gabirosca
- **Password:** Use a Personal Access Token (not your GitHub password)

### Creating a Personal Access Token

If you don't have a token:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click **"Generate new token (classic)"**
3. Give it a name: `wp-backup-repo`
4. Select scopes: `repo` (full control of private repositories)
5. Click **"Generate token"**
6. Copy the token and use it as your password when pushing

## Step 5: Verify on GitHub

1. Go to https://github.com/gabirosca/wp-backup
2. You should see all your files
3. GitHub will automatically display README.md on the homepage

## Step 6: Create First Release (Optional but Recommended)

1. On your GitHub repository page, click **"Releases"** (right sidebar)
2. Click **"Create a new release"**
3. Release settings:
   - **Tag:** `v1.0.0`
   - **Title:** `WordPress Backup Tool v1.0.0`
   - **Description:**
     ```
     Initial release of WordPress Backup, Migration & Restore Tool

     Features:
     - Complete WordPress backups (files + database)
     - Migration mode with domain replacement
     - Restore from backup with auto database import
     - WP-CLI integration for serialization-safe operations
     - Bricks Builder support
     - Fully interactive, no config files needed
     - Single standalone file

     Installation:
     wget https://raw.githubusercontent.com/gabirosca/wp-backup/main/wp-backup.sh
     chmod +x wp-backup.sh
     ./wp-backup.sh
     ```
4. Click **"Publish release"**

## Step 7: Update Repository Settings

1. Go to repository **Settings**
2. **About** section (top right of main page):
   - Click the gear icon ⚙️
   - **Website:** `https://gabirosca.com`
   - **Topics:** Add tags: `wordpress`, `backup`, `migration`, `wp-cli`, `bricks-builder`, `bash-script`
   - **Releases:** Check "Releases"
   - Click **"Save changes"**

## Step 8: Add Social Preview (Optional)

1. Go to repository **Settings** → **Options**
2. Scroll to **Social preview**
3. Upload an image (1280x640px recommended)
   - Could be a screenshot of the script running
   - Or a simple graphic with the tool name

## Step 9: Enable Issues

Issues should be enabled by default. Verify:
1. Go to repository **Settings** → **Features**
2. Ensure **"Issues"** is checked

## Repository Structure

Your GitHub repository will look like this:

```
wp-backup/
├── wp-backup.sh          # Main script
├── README.md             # Full documentation
├── LICENSE               # Custom non-commercial license
├── CONTRIBUTING.md       # Contribution guidelines
├── .gitignore           # Git ignore rules
└── GITHUB_SETUP.md      # Setup guide (delete after setup if you want)
```

## Sharing the Repository

Once published, share the repository:

**Clone URL:**
```
https://github.com/gabirosca/wp-backup.git
```

**Direct download:**
```
https://raw.githubusercontent.com/gabirosca/wp-backup/main/wp-backup.sh
```

**Repository page:**
```
https://github.com/gabirosca/wp-backup
```

## Updating the Repository Later

When you make changes:

```bash
cd /home/tmfestival/backups/script

# Stage changes
git add .

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push origin main
```

For new versions:
```bash
# Tag the version
git tag -a v1.1.0 -m "Version 1.1.0"

# Push tags
git push origin --tags
```

Then create a new release on GitHub using the new tag.

## Troubleshooting

### Authentication Failed
- Make sure you're using a Personal Access Token, not your password
- Ensure the token has `repo` scope

### Permission Denied
- Check you're logged in to the correct GitHub account
- Verify repository name matches

### Files Not Showing
- Make sure you ran `git add .` before committing
- Check `.gitignore` isn't excluding important files

## Done!

Your WordPress Backup tool is now on GitHub! 🎉

**Repository:** https://github.com/gabirosca/wp-backup

**Share it:**
- Add to your website
- Share on social media
- Submit to WordPress communities
- Add to your portfolio

---

**Remember:** This file (GITHUB_SETUP.md) was just for setup. You can delete it after publishing if you want, or keep it for reference.
