# WordPress Backup, Migration & Restore Tool

**Version:** 1.0.0
**Author:** Gabriel Rosca
**Website:** [https://gabirosca.com](https://gabirosca.com)
**Donate:** [https://ko-fi.com/gabrielrosca](https://ko-fi.com/gabrielrosca)

---

Complete WordPress management tool for backups, migrations, and restores. Fully interactive with automatic WordPress detection and WP-CLI integration.

[![License: Custom](https://img.shields.io/badge/License-Custom%20Non--Commercial-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/gabirosca/wp-backup/releases)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-brightgreen.svg)](https://www.gnu.org/software/bash/)

## ✨ Features

- ✅ **Backup** - Create complete WordPress backups (files + database)
- ✅ **Migration** - Backup with domain replacement and new database credentials
- ✅ **Restore** - Restore from backup with automatic database import
- ✅ **Auto-Detection** - Finds WordPress installations and backup directories automatically
- ✅ **WP-CLI Support** - Uses WP-CLI for safe, serialization-aware database operations
- ✅ **Bricks Builder** - Full support for Bricks Builder site migrations
- ✅ **Interactive** - No configuration files needed, everything is prompted
- ✅ **Single File** - One standalone script, no dependencies

## 📋 Requirements

- Bash shell
- `zip`/`unzip` commands
- `find`, `sed`, `grep` utilities
- **WP-CLI** (recommended) or `mysqldump`/`mysql`
- WordPress installation

## 🚀 Installation

### Quick Install

```bash
# Download the script
wget https://raw.githubusercontent.com/gabirosca/wp-backup/main/wp-backup.sh

# Make it executable
chmod +x wp-backup.sh

# Run it
./wp-backup.sh
```

### Git Clone

```bash
git clone https://github.com/gabirosca/wp-backup.git
cd wp-backup
chmod +x wp-backup.sh
./wp-backup.sh
```

That's it! The script is fully interactive.

## 📖 Usage

### Interactive Menu

When you run the script, you'll see:

```
========================================
WordPress Backup & Restore Tool
========================================
Select operation:

  1. Backup (regular backup)
  2. Migration (backup with domain replacement)
  3. Restore (restore from backup)

Select operation [1-3]:
```

### Operation Details

#### 1️⃣ Backup Mode

Creates a complete backup of your WordPress site.

**Steps:**
1. Select WordPress installation (auto-detected or enter manually)
2. Choose backup directory (auto-suggested or enter manually)
3. Confirm settings
4. Backup is created

**Output:** `domain-com-backup-DD-MM-YYYY-HH-MM-SS.zip` (domain auto-detected from WordPress database)

**What's included:**
- All WordPress files (core, themes, plugins, uploads)
- Complete database dump
- Excludes: cache, node_modules, .git

---

#### 2️⃣ Migration Mode

Creates a migration-ready backup with domain and database changes.

**Steps:**
1. Select WordPress installation
2. Choose backup directory
3. Enter old domain (e.g., `staging.mysite.com`)
4. Enter new domain (e.g., `mysite.com`)
5. Enter new database credentials
6. Confirm and backup

**What it does:**
- ✅ Exports database from source
- ✅ Performs WP-CLI search-replace (serialization-safe)
- ✅ Replaces ALL occurrences of old domain with new domain
- ✅ Updates `wp-config.php` with new database credentials
- ✅ Creates ready-to-deploy backup

**Perfect for:**
- Moving site to new server
- Changing domain names
- Dev → Staging → Production migrations
- Bricks Builder site migrations

---

#### 3️⃣ Restore Mode

Restores WordPress from a backup.

**Steps:**
1. Select backup directory (auto-detected)
2. Choose backup file from list (sorted by date)
3. Select restore destination (auto-detected or manual)
4. Choose automatic or manual database import
5. Confirm and restore

**Database Import Options:**
- **Automatic (y)** - Uses WP-CLI or mysql to import database
- **Manual (n)** - Copies database.sql to WordPress root for manual import

---

## 💼 Example Usage

### Regular Backup

```bash
./wp-backup.sh
# Select: 1 (Backup)
# Choose WordPress installation
# Choose backup directory
# Confirm
# ✓ Backup Complete!
```

### Migration

```bash
./wp-backup.sh
# Select: 2 (Migration)
# Old domain: staging.mysite.com
# New domain: mysite.com
# New DB name: mysite_prod
# New DB user: mysite_user
# New DB password: [password]
# ✓ Migration backup ready!
```

### Restore

```bash
./wp-backup.sh
# Select: 3 (Restore)
# Choose backup file
# Choose destination
# Auto-import DB: y
# ✓ Restore Complete!
```

## 🧱 Bricks Builder Support

This script fully supports **Bricks Builder** sites:

**Included in backup:**
- ✅ Bricks plugin files and configurations
- ✅ All Bricks database tables and page builder data
- ✅ Bricks assets in uploads directory
- ✅ Bricks templates and custom CSS
- ✅ Bricks theme settings

**Post-restore checklist:**
1. Verify Bricks plugin is activated
2. Check Bricks license (if domain changed)
3. Clear WordPress and Bricks cache
4. Test pages in Bricks editor
5. Verify dynamic content and integrations

## 🛠️ Troubleshooting

### Database Export Fails

**Solutions:**
1. Install WP-CLI (more reliable than mysqldump)
2. Check wp-config.php has correct credentials
3. Test database connection

### WordPress Not Detected

**Solutions:**
1. Ensure wp-config.php, wp-load.php, and wp-content exist
2. Select option 0 to enter path manually
3. Use absolute path

### Database Import Fails

**Solutions:**
1. Ensure database exists on target server
2. Check user permissions
3. Manual import: `wp db import database.sql` or `mysql -u user -p dbname < database.sql`

## 🔒 Security

- ⚠️ Backups contain sensitive data (credentials, user data)
- ✅ Store backups in secure, non-public directory
- ✅ Use SFTP/SCP for transfers
- ✅ Delete old backups regularly
- ❌ Never commit backups to version control

## 📝 Migration Checklist

### Before Migration
- [ ] Create backup on source server
- [ ] Create database on destination server
- [ ] Note new database credentials
- [ ] Test connection to new server

### During Migration
- [ ] Run migration backup (option 2)
- [ ] Provide old and new domains
- [ ] Provide new database credentials
- [ ] Transfer backup to new server

### After Migration
- [ ] Restore backup on new server
- [ ] Verify wp-config.php credentials
- [ ] Update DNS records
- [ ] Install SSL certificate
- [ ] Clear all caches
- [ ] Test site thoroughly

## ❓ FAQ

**Q: Can I use this for multisite?**
A: Yes, but test carefully. WP-CLI handles multisite search-replace correctly.

**Q: What if I don't have WP-CLI?**
A: The script falls back to mysqldump and sed, but WP-CLI is strongly recommended for migrations.

**Q: How long does a backup take?**
A: Depends on site size. Typical small-medium site (5GB) takes 2-5 minutes.

**Q: Does it work with managed WordPress hosting?**
A: It should work on most hosting, but some managed hosts restrict certain commands.

## 📄 License

**Custom Non-Commercial License**

Copyright (c) 2025 Gabriel Rosca

**You MAY:**
- ✅ Use this script for free (personal or commercial use)
- ✅ Distribute this script **without modifications**
- ✅ Use it on unlimited websites
- ✅ Use it for client projects

**You MAY NOT:**
- ❌ Sell this script or charge for it
- ❌ Modify and redistribute it
- ❌ Remove author credits
- ❌ Claim it as your own work

**Warranty Disclaimer:**

THIS SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY ARISING FROM THE USE OF THIS SCRIPT.

See [LICENSE](LICENSE) file for full terms.

## 💝 Support the Author

If you find this script useful, consider supporting the author:

**☕ Buy me a coffee:** [https://ko-fi.com/gabrielrosca](https://ko-fi.com/gabrielrosca)

**🌐 Website:** [https://gabirosca.com](https://gabirosca.com)

Your support helps maintain and improve this tool!

## 📞 Contact

- **Author:** Gabriel Rosca
- **Website:** [https://gabirosca.com](https://gabirosca.com)
- **Support:** [https://ko-fi.com/gabrielrosca](https://ko-fi.com/gabrielrosca)

## 🎯 Version History

**v1.0.0** (2025-11-29)
- Initial release
- Backup, migration, and restore functionality
- Auto-detection of WordPress installations
- WP-CLI integration
- Bricks Builder support
- Interactive menu system
- Single standalone file

---

**Made with ❤️ by Gabriel Rosca**

If this script saved you time, consider [buying me a coffee](https://ko-fi.com/gabrielrosca)! ☕
