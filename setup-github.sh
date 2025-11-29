#!/bin/bash

################################################################################
# GitHub Setup Script for wp-backup
# This script prepares the repository for GitHub publishing
################################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GitHub Setup for wp-backup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "wp-backup.sh" ]; then
    echo -e "${RED}Error: wp-backup.sh not found${NC}"
    echo "Please run this script from the wp-backup directory"
    exit 1
fi

echo -e "${YELLOW}Step 1: Cleaning up old files...${NC}"

# Remove old files
files_to_remove=(
    "wp-backup.config"
    "wp-backup.config.example"
    "wp-backup-helper.sh"
    "wp-restore.sh"
    "QUICKSTART.md"
    "FILES_OVERVIEW.txt"
    ".cleanup"
)

for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ Removed: $file"
    fi
done

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo -e "${YELLOW}Step 2: Verifying required files...${NC}"

# Check required files
required_files=(
    "wp-backup.sh"
    "README.md"
    "LICENSE"
    ".gitignore"
    "CONTRIBUTING.md"
)

all_present=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MISSING)"
        all_present=false
    fi
done

if [ "$all_present" = false ]; then
    echo -e "${RED}Error: Some required files are missing${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required files present${NC}"
echo ""

echo -e "${YELLOW}Step 3: Listing final files...${NC}"
echo ""
echo "Files ready for GitHub:"
ls -lh wp-backup.sh README.md LICENSE .gitignore CONTRIBUTING.md GITHUB_SETUP.md setup-github.sh 2>/dev/null || ls -lh
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Your repository is ready for GitHub!"
echo ""
echo "Next steps:"
echo ""
echo "1. Create repository on GitHub:"
echo "   https://github.com/new"
echo "   Repository name: wp-backup"
echo ""
echo "2. Initialize git (if not already done):"
echo "   git init"
echo "   git add ."
echo '   git commit -m "Initial commit: WordPress Backup Tool v1.0.0"'
echo ""
echo "3. Connect to GitHub:"
echo "   git remote add origin https://github.com/gabirosca/wp-backup.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "For detailed instructions, see GITHUB_SETUP.md"
echo ""
