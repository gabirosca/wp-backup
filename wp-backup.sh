#!/bin/bash

################################################################################
# WordPress Backup, Migration & Restore Script
# Purpose: Complete WordPress management - backup, migrate, and restore
# Handles: Standard WordPress and Bricks Builder sites
# Author: Gabriel Rosca | https://gabirosca.com
# License: Non-Commercial License
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to find WordPress installations
find_wordpress_installations() {
    echo -e "${CYAN}Scanning for WordPress installations...${NC}" >&2

    # Determine search starting point
    local current_user_home=$(eval echo ~)
    local search_locations=()

    # If running as root, search all locations
    if [ "$(whoami)" = "root" ]; then
        # Add /home directory (all user directories)
        if [ -d "/home" ]; then
            search_locations+=("/home")
        fi

        # Add /var/www (common web server location)
        if [ -d "/var/www" ]; then
            search_locations+=("/var/www")
        fi

        # Add current user's home directory if not already covered by /home
        if [[ ! "$current_user_home" =~ ^/home/ ]]; then
            search_locations+=("$current_user_home")
        fi

        # Add parent of script directory (in case WP is nearby)
        local script_parent=$(dirname "$SCRIPT_DIR")
        if [ -d "$script_parent" ] && [ "$script_parent" != "/home" ] && [ "$script_parent" != "/var/www" ]; then
            search_locations+=("$script_parent")
        fi
    else
        # Running as normal user - only search current user's home
        search_locations+=("$current_user_home")
    fi

    # Search in each location
    local found_installations=()
    for search_dir in "${search_locations[@]}"; do
        while IFS= read -r config_file; do
            local wp_dir=$(dirname "$config_file")
            # Verify it's a valid WordPress installation
            if [ -f "$wp_dir/wp-load.php" ] && [ -d "$wp_dir/wp-content" ]; then
                # Check if already in list (avoid duplicates)
                local is_duplicate=false
                for existing in "${found_installations[@]}"; do
                    if [ "$existing" = "$wp_dir" ]; then
                        is_duplicate=true
                        break
                    fi
                done
                if [ "$is_duplicate" = false ]; then
                    found_installations+=("$wp_dir")
                    echo "$wp_dir"
                fi
            fi
        done < <(find "$search_dir" -maxdepth 5 -name "wp-config.php" -type f 2>/dev/null)
    done
}

# Function to detect backup directories
find_backup_directories() {
    # Determine search starting point
    local current_user_home=$(eval echo ~)
    local search_locations=()

    # If running as root, search all locations
    if [ "$(whoami)" = "root" ]; then
        # Add /home directory (all user directories)
        if [ -d "/home" ]; then
            search_locations+=("/home")
        fi

        # Add /var/www (common web server location)
        if [ -d "/var/www" ]; then
            search_locations+=("/var/www")
        fi

        # Add current user's home directory if not already covered by /home
        if [[ ! "$current_user_home" =~ ^/home/ ]]; then
            search_locations+=("$current_user_home")
        fi

        # Add parent of script directory
        local script_parent=$(dirname "$SCRIPT_DIR")
        if [ -d "$script_parent" ] && [ "$script_parent" != "/home" ] && [ "$script_parent" != "/var/www" ]; then
            search_locations+=("$script_parent")
        fi
    else
        # Running as normal user - only search current user's home
        search_locations+=("$current_user_home")
    fi

    # Search for common backup directory names
    local found_backups=()
    for search_dir in "${search_locations[@]}"; do
        while IFS= read -r backup_dir; do
            # Check if already in list (avoid duplicates)
            local is_duplicate=false
            for existing in "${found_backups[@]}"; do
                if [ "$existing" = "$backup_dir" ]; then
                    is_duplicate=true
                    break
                fi
            done
            if [ "$is_duplicate" = false ]; then
                found_backups+=("$backup_dir")
                echo "$backup_dir"
            fi
        done < <(find "$search_dir" -maxdepth 4 -type d \( -name "backup*" -o -name "*backup" \) 2>/dev/null)
    done
}

# Function to find backup files
find_backup_files() {
    local backup_dir="$1"
    find "$backup_dir" -maxdepth 1 -name "*-backup-*.zip" -type f 2>/dev/null | sort -r
}

# Main interactive menu
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WordPress Backup & Restore Tool${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Select operation:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} Backup (regular backup)"
echo -e "  ${GREEN}2.${NC} Migration (backup with domain replacement)"
echo -e "  ${GREEN}3.${NC} Restore (restore from backup)"
echo ""
read -p "Select operation [1-3]: " operation

case "$operation" in
    1|2)
        # BACKUP or MIGRATION MODE
        IS_MIGRATION=false
        if [ "$operation" = "2" ]; then
            IS_MIGRATION=true
        fi

        echo ""
        echo -e "${GREEN}========================================${NC}"
        if [ "$IS_MIGRATION" = true ]; then
            echo -e "${GREEN}Migration Mode${NC}"
        else
            echo -e "${GREEN}Backup Mode${NC}"
        fi
        echo -e "${GREEN}========================================${NC}"
        echo ""

        # Step 1: Select WordPress installation
        echo -e "${BLUE}[1/4] WordPress Installation Path${NC}"
        echo ""

        # Find WordPress installations
        mapfile -t wp_installations < <(find_wordpress_installations)

        if [ ${#wp_installations[@]} -gt 0 ]; then
            echo -e "${YELLOW}Found WordPress installations:${NC}"
            for i in "${!wp_installations[@]}"; do
                echo -e "  ${GREEN}$((i+1)).${NC} ${wp_installations[$i]}"
            done
            echo -e "  ${GREEN}0.${NC} Enter custom path"
            echo ""
            read -p "Select WordPress installation [1-${#wp_installations[@]}] or 0 for custom: " wp_choice

            if [ "$wp_choice" = "0" ]; then
                read -p "Enter WordPress installation path: " WORDPRESS_ROOT
            elif [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "${#wp_installations[@]}" ]; then
                WORDPRESS_ROOT="${wp_installations[$((wp_choice-1))]}"
            else
                WORDPRESS_ROOT="${wp_installations[0]}"
            fi
        else
            echo -e "${YELLOW}No WordPress installations found automatically.${NC}"
            read -p "Enter WordPress installation path: " WORDPRESS_ROOT
        fi

        echo -e "${GREEN}✓ WordPress path: $WORDPRESS_ROOT${NC}"
        echo ""

        # Step 2: Select backup directory
        echo -e "${BLUE}[2/4] Backup Destination Directory${NC}"
        echo ""

        # Find backup directories
        mapfile -t backup_dirs < <(find_backup_directories)

        # Suggest default: one level up from WordPress
        WP_PARENT=$(dirname "$WORDPRESS_ROOT")
        SUGGESTED_BACKUP="$WP_PARENT/backups"

        if [ ${#backup_dirs[@]} -gt 0 ]; then
            echo -e "${YELLOW}Found backup directories:${NC}"
            for i in "${!backup_dirs[@]}"; do
                echo -e "  ${GREEN}$((i+1)).${NC} ${backup_dirs[$i]}"
            done
            echo -e "  ${GREEN}$((${#backup_dirs[@]}+1)).${NC} ${SUGGESTED_BACKUP} ${CYAN}(suggested)${NC}"
            echo -e "  ${GREEN}0.${NC} Enter custom path"
            echo ""
            read -p "Select backup directory [1-$((${#backup_dirs[@]}+1))] or 0 for custom: " backup_choice

            if [ "$backup_choice" = "0" ]; then
                read -p "Enter backup directory path: " BACKUP_DIR
            elif [ "$backup_choice" = "$((${#backup_dirs[@]}+1))" ]; then
                BACKUP_DIR="$SUGGESTED_BACKUP"
            elif [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le "${#backup_dirs[@]}" ]; then
                BACKUP_DIR="${backup_dirs[$((backup_choice-1))]}"
            else
                BACKUP_DIR="$SUGGESTED_BACKUP"
            fi
        else
            echo -e "${YELLOW}Suggested: $SUGGESTED_BACKUP${NC}"
            read -p "Use suggested path? (y/n) or enter custom path: " backup_input

            # Convert to lowercase for comparison
            backup_input_lower=$(echo "$backup_input" | tr '[:upper:]' '[:lower:]')

            if [[ "$backup_input_lower" =~ ^(y|yes)$ ]] || [ -z "$backup_input" ]; then
                BACKUP_DIR="$SUGGESTED_BACKUP"
            elif [[ "$backup_input_lower" =~ ^(n|no)$ ]]; then
                read -p "Enter backup directory path: " BACKUP_DIR
            else
                BACKUP_DIR="$backup_input"
            fi
        fi

        # Create backup directory if it doesn't exist
        if [ ! -d "$BACKUP_DIR" ]; then
            mkdir -p "$BACKUP_DIR"
            echo -e "${GREEN}✓ Created backup directory: $BACKUP_DIR${NC}"
        else
            echo -e "${GREEN}✓ Backup directory: $BACKUP_DIR${NC}"
        fi
        echo ""

        # Step 3: Migration settings
        echo -e "${BLUE}[3/4] Migration Settings${NC}"
        echo ""

        OLD_DOMAIN=""
        NEW_DOMAIN=""
        NEW_DB_NAME=""
        NEW_DB_USER=""
        NEW_DB_PASSWORD=""
        NEW_DB_HOST="127.0.0.1"

        if [ "$IS_MIGRATION" = true ]; then
            echo -e "${YELLOW}Domain Replacement:${NC}"
            read -p "Enter OLD domain (current): " OLD_DOMAIN
            read -p "Enter NEW domain (target): " NEW_DOMAIN
            echo ""

            echo -e "${YELLOW}New Database Credentials (for wp-config.php):${NC}"
            read -p "Enter NEW database name: " NEW_DB_NAME
            read -p "Enter NEW database user: " NEW_DB_USER
            read -p "Enter NEW database password: " NEW_DB_PASSWORD
            read -p "Enter NEW database host [127.0.0.1]: " input_host
            if [ -n "$input_host" ]; then
                NEW_DB_HOST="$input_host"
            fi

            echo -e "${GREEN}✓ Will replace domain: $OLD_DOMAIN → $NEW_DOMAIN${NC}"
            echo -e "${GREEN}✓ Will update wp-config.php with new database credentials${NC}"
        else
            echo -e "${GREEN}✓ Regular backup mode (no modifications)${NC}"
        fi
        echo ""

        # Step 4: Confirmation
        echo -e "${BLUE}[4/4] Confirmation${NC}"
        echo ""
        echo -e "${CYAN}Summary:${NC}"
        echo -e "  WordPress: ${YELLOW}$WORDPRESS_ROOT${NC}"
        echo -e "  Backup to: ${YELLOW}$BACKUP_DIR${NC}"
        if [ "$IS_MIGRATION" = true ]; then
            echo -e "  Type: ${YELLOW}Migration${NC}"
            echo -e "  Domain: ${YELLOW}$OLD_DOMAIN → $NEW_DOMAIN${NC}"
            echo -e "  New DB: ${YELLOW}$NEW_DB_NAME (user: $NEW_DB_USER)${NC}"
        else
            echo -e "  Type: ${YELLOW}Regular Backup${NC}"
        fi
        echo ""
        read -p "Proceed with backup? (y/n): " confirm

        # Convert to lowercase for comparison
        confirm_lower=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

        if [[ ! "$confirm_lower" =~ ^(y|yes)$ ]]; then
            echo -e "${RED}Backup cancelled.${NC}"
            exit 0
        fi
        echo ""

        # Execute Backup
        BACKUP_DATE=$(date +%d-%m-%Y)
        BACKUP_TIME=$(date +%H-%M-%S)

        # Temporary directories for backup process
        TEMP_BACKUP_DIR=$(mktemp -d)
        FILES_BACKUP_DIR="${TEMP_BACKUP_DIR}/files_backup"
        trap "rm -rf $TEMP_BACKUP_DIR" EXIT

        # Verify WordPress installation
        if [ ! -f "$WORDPRESS_ROOT/wp-config.php" ]; then
            echo -e "${RED}Error: wp-config.php not found in $WORDPRESS_ROOT${NC}"
            exit 1
        fi

        echo -e "${YELLOW}[1/4] Reading WordPress configuration...${NC}"

        # Extract database credentials from wp-config.php
        DB_NAME=$(grep -E "define\s*\(\s*['\"]DB_NAME['\"]" "$WORDPRESS_ROOT/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_USER=$(grep -E "define\s*\(\s*['\"]DB_USER['\"]" "$WORDPRESS_ROOT/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_PASSWORD=$(grep -E "define\s*\(\s*['\"]DB_PASSWORD['\"]" "$WORDPRESS_ROOT/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_HOST=$(grep -E "define\s*\(\s*['\"]DB_HOST['\"]" "$WORDPRESS_ROOT/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")

        if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
            echo -e "${RED}Error: Could not extract database credentials from wp-config.php${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Database: $DB_NAME${NC}"
        echo -e "${GREEN}✓ User: $DB_USER${NC}"
        echo -e "${GREEN}✓ Host: $DB_HOST${NC}"

        # Detect WordPress file owner
        WP_OWNER=$(stat -c '%U' "$WORDPRESS_ROOT/wp-config.php")
        echo -e "${GREEN}✓ WordPress owner: $WP_OWNER${NC}"

        # Detect WordPress domain from database
        SITE_DOMAIN=""
        if command -v wp >/dev/null 2>&1; then
            if [ "$(whoami)" = "root" ] && [ "$WP_OWNER" != "root" ]; then
                SITE_DOMAIN=$(su "$WP_OWNER" -s /bin/bash -c "cd '$WORDPRESS_ROOT' && wp option get siteurl --quiet 2>/dev/null" | sed 's|https\?://||' | sed 's|/.*||')
            else
                SITE_DOMAIN=$(wp option get siteurl --path="$WORDPRESS_ROOT" --quiet 2>/dev/null | sed 's|https\?://||' | sed 's|/.*||')
            fi
        fi

        # Fallback: try to get domain from database directly
        if [ -z "$SITE_DOMAIN" ] && command -v mysql >/dev/null 2>&1; then
            # Parse host and port from DB_HOST
            MYSQL_HOST="$DB_HOST"
            MYSQL_PORT=""
            if [[ "$DB_HOST" == *:* ]]; then
                MYSQL_HOST="${DB_HOST%:*}"
                MYSQL_PORT="${DB_HOST##*:}"
            fi

            # Build mysql command
            MYSQL_CMD="mysql -h \"$MYSQL_HOST\""
            if [ -n "$MYSQL_PORT" ]; then
                MYSQL_CMD="$MYSQL_CMD -P $MYSQL_PORT"
            fi
            MYSQL_CMD="$MYSQL_CMD -u \"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_NAME\" -sN -e \"SELECT option_value FROM wp_options WHERE option_name='siteurl' LIMIT 1;\""

            SITE_DOMAIN=$(eval "$MYSQL_CMD" 2>/dev/null | sed 's|https\?://||' | sed 's|/.*||')
        fi

        # If domain detection failed, use folder name as fallback
        if [ -z "$SITE_DOMAIN" ]; then
            SITE_DOMAIN=$(basename "$(cd "$WORDPRESS_ROOT" && pwd)")
            echo -e "${YELLOW}⚠ Could not detect domain, using folder name: $SITE_DOMAIN${NC}"
        else
            echo -e "${GREEN}✓ Domain: $SITE_DOMAIN${NC}"
        fi

        # Replace dots with dashes for filename (domain.com -> domain-com)
        SITE_DOMAIN_CLEAN=$(echo "$SITE_DOMAIN" | tr '.' '-')

        # Set final backup filename with domain
        FINAL_BACKUP_NAME="${SITE_DOMAIN_CLEAN}-backup-${BACKUP_DATE}-${BACKUP_TIME}.zip"
        echo ""

        echo -e "${YELLOW}[2/4] Backing up files...${NC}"

        # Create backup directories
        mkdir -p "$FILES_BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"

        # Copy WordPress files
        cd "$WORDPRESS_ROOT"
        find . -maxdepth 1 -type f -exec cp {} "$FILES_BACKUP_DIR/" \;
        find . -maxdepth 1 -type d ! -name '.' ! -name '..' ! -name '.git' ! -name '.github' -exec cp -r {} "$FILES_BACKUP_DIR/" \;

        # Remove unnecessary directories
        rm -rf "$FILES_BACKUP_DIR/wp-content/cache" 2>/dev/null || true
        rm -rf "$FILES_BACKUP_DIR/wp-content/backup"* 2>/dev/null || true
        rm -rf "$FILES_BACKUP_DIR/node_modules" 2>/dev/null || true
        rm -rf "$FILES_BACKUP_DIR/.git" 2>/dev/null || true
        rm -rf "$FILES_BACKUP_DIR/.github" 2>/dev/null || true

        # Update wp-config.php if migration
        if [ "$IS_MIGRATION" = true ]; then
            echo -e "${CYAN}Updating wp-config.php with new database credentials...${NC}"

            sed -i "s/define\s*(\s*['\"]DB_NAME['\"]\s*,\s*['\"][^'\"]*['\"]\s*)/define('DB_NAME', '$NEW_DB_NAME')/g" "$FILES_BACKUP_DIR/wp-config.php"
            sed -i "s/define\s*(\s*['\"]DB_USER['\"]\s*,\s*['\"][^'\"]*['\"]\s*)/define('DB_USER', '$NEW_DB_USER')/g" "$FILES_BACKUP_DIR/wp-config.php"
            sed -i "s/define\s*(\s*['\"]DB_PASSWORD['\"]\s*,\s*['\"][^'\"]*['\"]\s*)/define('DB_PASSWORD', '$NEW_DB_PASSWORD')/g" "$FILES_BACKUP_DIR/wp-config.php"
            sed -i "s/define\s*(\s*['\"]DB_HOST['\"]\s*,\s*['\"][^'\"]*['\"]\s*)/define('DB_HOST', '$NEW_DB_HOST')/g" "$FILES_BACKUP_DIR/wp-config.php"

            echo -e "${GREEN}✓ wp-config.php updated with new credentials${NC}"
        fi

        # Check for Bricks Builder
        if [ -d "$FILES_BACKUP_DIR/wp-content/uploads" ]; then
            echo -e "${GREEN}✓ Bricks Builder assets in uploads preserved${NC}"
        fi
        if [ -d "$FILES_BACKUP_DIR/wp-content/plugins/bricks" ]; then
            echo -e "${GREEN}✓ Bricks Builder plugin preserved${NC}"
        fi

        echo -e "${GREEN}✓ Files backed up successfully${NC}"
        echo ""

        echo -e "${YELLOW}[3/4] Backing up database...${NC}"

        DATABASE_FILE="${TEMP_BACKUP_DIR}/database.sql"

        # Try WP-CLI first, fallback to mysqldump
        DB_EXPORT_SUCCESS=false
        if command -v wp >/dev/null 2>&1; then
            if [ "$(whoami)" = "root" ] && [ "$WP_OWNER" != "root" ]; then
                # Running as root, execute WP-CLI as the WordPress owner
                # Use su without login (-) to preserve current directory and environment
                if su "$WP_OWNER" -s /bin/bash -c "cd '$WORDPRESS_ROOT' && wp db export '$DATABASE_FILE' --quiet 2>/dev/null"; then
                    DB_EXPORT_SUCCESS=true
                fi
            else
                # Running as normal user or WordPress is owned by root
                if wp db export "$DATABASE_FILE" --path="$WORDPRESS_ROOT" --quiet 2>/dev/null; then
                    DB_EXPORT_SUCCESS=true
                fi
            fi

            if [ "$DB_EXPORT_SUCCESS" = true ]; then
                DUMP_SIZE=$(du -h "$DATABASE_FILE" | cut -f1)
                echo -e "${GREEN}✓ Database exported (via WP-CLI): $DUMP_SIZE${NC}"
            else
                echo -e "${YELLOW}⚠ WP-CLI export failed, trying mysqldump...${NC}"
            fi
        fi

        # Fallback to mysqldump if WP-CLI failed or not available
        if [ "$DB_EXPORT_SUCCESS" = false ] && command -v mysqldump >/dev/null 2>&1; then
            # Parse host and port from DB_HOST (handle "host:port" format)
            MYSQL_HOST="$DB_HOST"
            MYSQL_PORT=""
            if [[ "$DB_HOST" == *:* ]]; then
                MYSQL_HOST="${DB_HOST%:*}"
                MYSQL_PORT="${DB_HOST##*:}"
            fi

            # Build mysqldump command
            MYSQLDUMP_CMD="mysqldump -h \"$MYSQL_HOST\""
            if [ -n "$MYSQL_PORT" ]; then
                MYSQLDUMP_CMD="$MYSQLDUMP_CMD -P $MYSQL_PORT"
            fi
            MYSQLDUMP_CMD="$MYSQLDUMP_CMD -u \"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_NAME\""

            if eval "$MYSQLDUMP_CMD" > "$DATABASE_FILE" 2>/dev/null; then
                DUMP_SIZE=$(du -h "$DATABASE_FILE" | cut -f1)
                echo -e "${GREEN}✓ Database exported (via mysqldump): $DUMP_SIZE${NC}"
                DB_EXPORT_SUCCESS=true
            else
                echo -e "${RED}Error: Failed to export database via mysqldump${NC}"
                exit 1
            fi
        fi

        # Final check if database export succeeded
        if [ "$DB_EXPORT_SUCCESS" = false ]; then
            echo -e "${RED}Error: Could not export database (neither WP-CLI nor mysqldump succeeded)${NC}"
            exit 1
        fi

        # Perform search & replace for migration
        if [ "$IS_MIGRATION" = true ] && [ -n "$OLD_DOMAIN" ] && [ -n "$NEW_DOMAIN" ]; then
            echo ""
            echo -e "${YELLOW}Performing domain search & replace...${NC}"

            cp "$DATABASE_FILE" "${DATABASE_FILE}.original"

            if command -v wp >/dev/null 2>&1; then
                echo -e "${CYAN}Using WP-CLI search-replace (serialization-safe)...${NC}"

                if [ "$(whoami)" = "root" ] && [ "$WP_OWNER" != "root" ]; then
                    # Running as root, execute WP-CLI as the WordPress owner
                    REPLACE_COUNT=$(su "$WP_OWNER" -s /bin/bash -c "cd '$WORDPRESS_ROOT' && wp search-replace '$OLD_DOMAIN' '$NEW_DOMAIN' --dry-run --format=count 2>/dev/null" || echo "0")

                    if [ "$REPLACE_COUNT" != "0" ]; then
                        su "$WP_OWNER" -s /bin/bash -c "cd '$WORDPRESS_ROOT' && wp search-replace '$OLD_DOMAIN' '$NEW_DOMAIN' --export='$DATABASE_FILE' --quiet 2>/dev/null" || {
                            echo -e "${YELLOW}⚠ WP-CLI search-replace export failed, using sed fallback${NC}"
                            sed -i "s|$OLD_DOMAIN|$NEW_DOMAIN|g" "$DATABASE_FILE"
                        }
                        echo -e "${GREEN}✓ Replaced $REPLACE_COUNT occurrences: $OLD_DOMAIN → $NEW_DOMAIN${NC}"
                    else
                        echo -e "${YELLOW}⚠ No occurrences of $OLD_DOMAIN found${NC}"
                    fi
                else
                    # Running as normal user or WordPress is owned by root
                    REPLACE_COUNT=$(wp search-replace "$OLD_DOMAIN" "$NEW_DOMAIN" \
                        --path="$WORDPRESS_ROOT" \
                        --dry-run \
                        --format=count 2>/dev/null || echo "0")

                    if [ "$REPLACE_COUNT" != "0" ]; then
                        wp search-replace "$OLD_DOMAIN" "$NEW_DOMAIN" \
                            --path="$WORDPRESS_ROOT" \
                            --export="$DATABASE_FILE" \
                            --quiet 2>/dev/null || {
                            echo -e "${YELLOW}⚠ WP-CLI search-replace export failed, using sed fallback${NC}"
                            sed -i "s|$OLD_DOMAIN|$NEW_DOMAIN|g" "$DATABASE_FILE"
                        }
                        echo -e "${GREEN}✓ Replaced $REPLACE_COUNT occurrences: $OLD_DOMAIN → $NEW_DOMAIN${NC}"
                    else
                        echo -e "${YELLOW}⚠ No occurrences of $OLD_DOMAIN found${NC}"
                    fi
                fi
            else
                echo -e "${YELLOW}⚠ Using basic sed replacement${NC}"
                sed -i "s|$OLD_DOMAIN|$NEW_DOMAIN|g" "$DATABASE_FILE"
                echo -e "${GREEN}✓ Basic domain replacement completed${NC}"
            fi

            FINAL_SIZE=$(du -h "$DATABASE_FILE" | cut -f1)
            echo -e "${GREEN}✓ Migration database ready: $FINAL_SIZE${NC}"
        fi
        echo ""

        echo -e "${YELLOW}[4/4] Creating final archive...${NC}"

        cd "$TEMP_BACKUP_DIR"

        zip -r -q "files.zip" "files_backup" 2>/dev/null || {
            echo -e "${RED}Error: Failed to create files.zip${NC}"
            exit 1
        }

        zip -q "$FINAL_BACKUP_NAME" "files.zip" "database.sql" || {
            echo -e "${RED}Error: Failed to create final backup archive${NC}"
            exit 1
        }

        mv "$FINAL_BACKUP_NAME" "$BACKUP_DIR/" || {
            echo -e "${RED}Error: Failed to move backup to $BACKUP_DIR${NC}"
            exit 1
        }

        FINAL_SIZE=$(du -h "$BACKUP_DIR/$FINAL_BACKUP_NAME" | cut -f1)

        echo -e "${GREEN}✓ Final archive created: $FINAL_SIZE${NC}"
        echo ""

        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Backup Complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "Location: ${GREEN}$BACKUP_DIR/$FINAL_BACKUP_NAME${NC}"
        echo -e "Size: ${GREEN}$FINAL_SIZE${NC}"
        echo ""

        if [ "$IS_MIGRATION" = true ]; then
            echo -e "${CYAN}========================================${NC}"
            echo -e "${CYAN}Migration Backup${NC}"
            echo -e "${CYAN}========================================${NC}"
            echo ""
            echo -e "${YELLOW}Changes applied:${NC}"
            echo -e "  • Domain: ${RED}$OLD_DOMAIN${NC} → ${GREEN}$NEW_DOMAIN${NC}"
            echo -e "  • Database: ${GREEN}$NEW_DB_NAME${NC} (user: ${GREEN}$NEW_DB_USER${NC})"
            echo -e "  • wp-config.php updated with new credentials"
            echo ""
            echo -e "${YELLOW}Migration Instructions:${NC}"
            echo "  1. Transfer backup to new server"
            echo "  2. Create database: $NEW_DB_NAME"
            echo "  3. Extract backup and restore files"
            echo "  4. Import database.sql into $NEW_DB_NAME"
            echo "  5. Update DNS to point to new server"
            echo "  6. Clear WordPress cache"
            echo "  7. Test site thoroughly"
            echo ""
        fi
        ;;

    3)
        # RESTORE MODE
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Restore Mode${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""

        # Step 1: Select backup file
        echo -e "${BLUE}[1/4] Select Backup File${NC}"
        echo ""

        mapfile -t backup_dirs < <(find_backup_directories)

        BACKUP_DIR=""
        if [ ${#backup_dirs[@]} -gt 0 ]; then
            echo -e "${YELLOW}Found backup directories:${NC}"
            for i in "${!backup_dirs[@]}"; do
                echo -e "  ${GREEN}$((i+1)).${NC} ${backup_dirs[$i]}"
            done
            echo -e "  ${GREEN}0.${NC} Enter custom path"
            echo ""
            read -p "Select backup directory [1-${#backup_dirs[@]}] or 0 for custom: " backup_choice

            if [ "$backup_choice" = "0" ]; then
                read -p "Enter backup directory path: " BACKUP_DIR
            elif [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le "${#backup_dirs[@]}" ]; then
                BACKUP_DIR="${backup_dirs[$((backup_choice-1))]}"
            else
                BACKUP_DIR="${backup_dirs[0]}"
            fi
        else
            read -p "Enter backup directory path: " BACKUP_DIR
        fi

        echo ""
        echo -e "${CYAN}Available backups in $BACKUP_DIR:${NC}"
        mapfile -t backup_files < <(find_backup_files "$BACKUP_DIR")

        if [ ${#backup_files[@]} -eq 0 ]; then
            echo -e "${RED}No backup files found in $BACKUP_DIR${NC}"
            exit 1
        fi

        for i in "${!backup_files[@]}"; do
            filename=$(basename "${backup_files[$i]}")
            filesize=$(du -h "${backup_files[$i]}" | cut -f1)
            echo -e "  ${GREEN}$((i+1)).${NC} $filename (${filesize})"
        done
        echo ""
        read -p "Select backup file [1-${#backup_files[@]}]: " file_choice

        if [ "$file_choice" -ge 1 ] && [ "$file_choice" -le "${#backup_files[@]}" ]; then
            BACKUP_FILE="${backup_files[$((file_choice-1))]}"
        else
            echo -e "${RED}Invalid selection${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Selected: $(basename "$BACKUP_FILE")${NC}"
        echo ""

        # Step 2: Select restore destination
        echo -e "${BLUE}[2/4] Restore Destination${NC}"
        echo ""

        mapfile -t wp_installations < <(find_wordpress_installations)

        if [ ${#wp_installations[@]} -gt 0 ]; then
            echo -e "${YELLOW}Found WordPress installations:${NC}"
            for i in "${!wp_installations[@]}"; do
                echo -e "  ${GREEN}$((i+1)).${NC} ${wp_installations[$i]}"
            done
            echo -e "  ${GREEN}0.${NC} Enter custom path (new installation)"
            echo ""
            read -p "Select restore destination [1-${#wp_installations[@]}] or 0 for custom: " wp_choice

            if [ "$wp_choice" = "0" ]; then
                read -p "Enter restore destination path: " RESTORE_DIR
            elif [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "${#wp_installations[@]}" ]; then
                RESTORE_DIR="${wp_installations[$((wp_choice-1))]}"
            else
                RESTORE_DIR="${wp_installations[0]}"
            fi
        else
            echo -e "${YELLOW}No WordPress installations found.${NC}"
            read -p "Enter restore destination path: " RESTORE_DIR
        fi

        echo -e "${GREEN}✓ Restore to: $RESTORE_DIR${NC}"
        echo ""

        # Step 3: Database import settings
        echo -e "${BLUE}[3/4] Database Import Settings${NC}"
        echo ""

        read -p "Import database automatically? (y/n): " auto_import

        # Convert to lowercase for comparison
        auto_import_lower=$(echo "$auto_import" | tr '[:upper:]' '[:lower:]')

        AUTO_IMPORT=false
        if [[ "$auto_import_lower" =~ ^(y|yes)$ ]]; then
            AUTO_IMPORT=true
        fi
        echo ""

        # Step 4: Confirmation
        echo -e "${BLUE}[4/4] Confirmation${NC}"
        echo ""
        echo -e "${CYAN}Summary:${NC}"
        echo -e "  Backup: ${YELLOW}$(basename "$BACKUP_FILE")${NC}"
        echo -e "  Restore to: ${YELLOW}$RESTORE_DIR${NC}"
        echo -e "  Auto-import DB: ${YELLOW}$([ "$AUTO_IMPORT" = true ] && echo "Yes" || echo "No")${NC}"
        echo ""

        if [ -f "$RESTORE_DIR/wp-config.php" ]; then
            echo -e "${RED}⚠ WARNING: WordPress exists at destination!${NC}"
            echo -e "${RED}This will OVERWRITE the existing installation.${NC}"
            echo ""
        fi

        read -p "Proceed with restore? (yes/no): " confirm

        # Convert to lowercase for comparison
        confirm_lower=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

        if [[ ! "$confirm_lower" =~ ^(y|yes)$ ]]; then
            echo -e "${RED}Restore cancelled.${NC}"
            exit 0
        fi
        echo ""

        # Execute Restore
        TEMP_EXTRACT=$(mktemp -d)
        trap "rm -rf $TEMP_EXTRACT" EXIT

        echo -e "${YELLOW}[1/5] Extracting backup archive...${NC}"

        if ! unzip -q "$BACKUP_FILE" -d "$TEMP_EXTRACT" 2>/dev/null; then
            echo -e "${RED}Error: Failed to extract backup archive${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Backup extracted${NC}"
        echo ""

        # Validate backup contents
        if [ ! -f "$TEMP_EXTRACT/database.sql" ]; then
            echo -e "${RED}Error: database.sql not found in backup${NC}"
            exit 1
        fi

        if [ ! -f "$TEMP_EXTRACT/files.zip" ]; then
            echo -e "${RED}Error: files.zip not found in backup${NC}"
            exit 1
        fi

        echo -e "${YELLOW}[2/5] Extracting files archive...${NC}"

        if ! unzip -q "$TEMP_EXTRACT/files.zip" -d "$TEMP_EXTRACT" 2>/dev/null; then
            echo -e "${RED}Error: Failed to extract files.zip${NC}"
            exit 1
        fi

        FILES_SOURCE="$TEMP_EXTRACT/files_backup"

        if [ ! -d "$FILES_SOURCE" ]; then
            echo -e "${RED}Error: files_backup directory not found${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Files extracted${NC}"
        echo ""

        echo -e "${YELLOW}[3/5] Restoring files to $RESTORE_DIR...${NC}"

        mkdir -p "$RESTORE_DIR"

        # Use rsync if available for better permission handling, fallback to cp with force
        if command -v rsync >/dev/null 2>&1; then
            if rsync -a --delete "$FILES_SOURCE/" "$RESTORE_DIR/" 2>/dev/null; then
                echo -e "${GREEN}✓ Files restored (via rsync)${NC}"
            else
                echo -e "${RED}Error: Failed to restore files via rsync${NC}"
                echo -e "${YELLOW}⚠ You may need to run this script with sudo for this restore${NC}"
                exit 1
            fi
        else
            # Fallback: use cp with force flag
            if cp -rf "$FILES_SOURCE"/* "$RESTORE_DIR/" 2>/dev/null; then
                echo -e "${GREEN}✓ Files restored (via cp)${NC}"
            else
                echo -e "${RED}Error: Failed to restore files${NC}"
                echo -e "${YELLOW}⚠ You may need to run this script with sudo for this restore${NC}"
                exit 1
            fi
        fi
        echo ""

        echo -e "${YELLOW}[4/5] Reading database credentials...${NC}"

        if [ ! -f "$RESTORE_DIR/wp-config.php" ]; then
            echo -e "${RED}Error: wp-config.php not found after restore${NC}"
            exit 1
        fi

        DB_NAME=$(grep -E "define\s*\(\s*['\"]DB_NAME['\"]" "$RESTORE_DIR/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_USER=$(grep -E "define\s*\(\s*['\"]DB_USER['\"]" "$RESTORE_DIR/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_PASSWORD=$(grep -E "define\s*\(\s*['\"]DB_PASSWORD['\"]" "$RESTORE_DIR/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")
        DB_HOST=$(grep -E "define\s*\(\s*['\"]DB_HOST['\"]" "$RESTORE_DIR/wp-config.php" | grep -oP "['\"][^'\"]+['\"]" | sed -n 2p | tr -d "'\"")

        if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
            echo -e "${RED}Error: Could not extract database credentials${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Database: $DB_NAME${NC}"
        echo -e "${GREEN}✓ User: $DB_USER${NC}"
        echo -e "${GREEN}✓ Host: $DB_HOST${NC}"

        # Detect WordPress file owner for restore
        WP_OWNER=$(stat -c '%U' "$RESTORE_DIR/wp-config.php")
        echo -e "${GREEN}✓ WordPress owner: $WP_OWNER${NC}"
        echo ""

        echo -e "${YELLOW}[5/5] Importing database...${NC}"

        if [ "$AUTO_IMPORT" = true ]; then
            if command -v wp >/dev/null 2>&1; then
                DB_IMPORT_SUCCESS=false
                if [ "$(whoami)" = "root" ] && [ "$WP_OWNER" != "root" ]; then
                    # Running as root, execute WP-CLI as the WordPress owner
                    if su "$WP_OWNER" -s /bin/bash -c "cd '$RESTORE_DIR' && wp db import '$TEMP_EXTRACT/database.sql' 2>/dev/null"; then
                        DB_IMPORT_SUCCESS=true
                    fi
                else
                    # Running as normal user or WordPress is owned by root
                    if wp db import "$TEMP_EXTRACT/database.sql" --path="$RESTORE_DIR" 2>/dev/null; then
                        DB_IMPORT_SUCCESS=true
                    fi
                fi

                if [ "$DB_IMPORT_SUCCESS" = true ]; then
                    echo -e "${GREEN}✓ Database imported (via WP-CLI)${NC}"
                else
                    echo -e "${RED}Error: Failed to import database via WP-CLI${NC}"
                    echo -e "${YELLOW}Database file saved at: $TEMP_EXTRACT/database.sql${NC}"
                    cp "$TEMP_EXTRACT/database.sql" "$RESTORE_DIR/"
                    echo -e "${YELLOW}Copied to: $RESTORE_DIR/database.sql${NC}"
                    AUTO_IMPORT=false
                fi
            elif command -v mysql >/dev/null 2>&1; then
                # Parse host and port from DB_HOST
                MYSQL_HOST="$DB_HOST"
                MYSQL_PORT=""
                if [[ "$DB_HOST" == *:* ]]; then
                    MYSQL_HOST="${DB_HOST%:*}"
                    MYSQL_PORT="${DB_HOST##*:}"
                fi

                # Build mysql command
                MYSQL_CMD="mysql -h \"$MYSQL_HOST\""
                if [ -n "$MYSQL_PORT" ]; then
                    MYSQL_CMD="$MYSQL_CMD -P $MYSQL_PORT"
                fi
                MYSQL_CMD="$MYSQL_CMD -u \"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_NAME\""

                if eval "$MYSQL_CMD" < "$TEMP_EXTRACT/database.sql" 2>/dev/null; then
                    echo -e "${GREEN}✓ Database imported (via mysql)${NC}"
                else
                    echo -e "${RED}Error: Failed to import database via mysql${NC}"
                    echo -e "${YELLOW}Database file saved at: $TEMP_EXTRACT/database.sql${NC}"
                    cp "$TEMP_EXTRACT/database.sql" "$RESTORE_DIR/"
                    echo -e "${YELLOW}Copied to: $RESTORE_DIR/database.sql${NC}"
                    AUTO_IMPORT=false
                fi
            else
                echo -e "${YELLOW}⚠ Neither WP-CLI nor mysql found${NC}"
                cp "$TEMP_EXTRACT/database.sql" "$RESTORE_DIR/"
                echo -e "${YELLOW}Database file copied to: $RESTORE_DIR/database.sql${NC}"
                AUTO_IMPORT=false
            fi
        else
            cp "$TEMP_EXTRACT/database.sql" "$RESTORE_DIR/"
            echo -e "${YELLOW}Database file copied to: $RESTORE_DIR/database.sql${NC}"
            echo -e "${YELLOW}Import manually: wp db import database.sql --path=$RESTORE_DIR${NC}"
        fi
        echo ""

        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Restore Complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "WordPress restored to: ${GREEN}$RESTORE_DIR${NC}"
        echo ""

        if [ "$AUTO_IMPORT" = false ]; then
            echo -e "${YELLOW}Manual database import required:${NC}"
            echo "  cd $RESTORE_DIR"
            echo "  wp db import database.sql"
            echo "  OR"
            echo "  mysql -h $DB_HOST -u $DB_USER -p $DB_NAME < database.sql"
            echo ""
        fi

        echo -e "${YELLOW}Next Steps:${NC}"
        echo "  1. Verify wp-config.php database credentials"
        echo "  2. Clear WordPress cache"
        echo "  3. Test site in browser"
        echo "  4. Check Bricks Builder (if applicable)"
        echo ""
        ;;

    *)
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac
