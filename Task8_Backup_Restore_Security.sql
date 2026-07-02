-- ============================================================
-- Task 8: Backup, Restore & Security
-- RD INFRO TECHNOLOGY — SQL Internship Program
-- Tools: mysqldump, pgAdmin, phpMyAdmin
-- ============================================================

-- ============================================================
-- SECTION 1: BACKUP COMMANDS (run in terminal/bash, not SQL)
-- ============================================================

-- ── Full database backup ──────────────────────────────────
--   mysqldump -u root -p rd_infro_ecommerce > backup_full.sql

-- ── Backup specific tables only ───────────────────────────
--   mysqldump -u root -p rd_infro_ecommerce customers orders > backup_customers_orders.sql

-- ── Backup with timestamp in filename ─────────────────────
--   mysqldump -u root -p rd_infro_ecommerce > backup_$(date +%Y%m%d_%H%M%S).sql

-- ── Backup with compression (smaller file) ────────────────
--   mysqldump -u root -p rd_infro_ecommerce | gzip > backup.sql.gz

-- ── Backup structure ONLY (no data) ──────────────────────
--   mysqldump -u root -p --no-data rd_infro_ecommerce > schema_only.sql

-- ── Backup data ONLY (no CREATE TABLE statements) ─────────
--   mysqldump -u root -p --no-create-info rd_infro_ecommerce > data_only.sql

-- ── Backup all databases on the server ────────────────────
--   mysqldump -u root -p --all-databases > all_databases_backup.sql


-- ============================================================
-- SECTION 2: RESTORE COMMANDS (run in terminal/bash)
-- ============================================================

-- ── Restore from a backup file ────────────────────────────
--   mysql -u root -p rd_infro_ecommerce < backup_full.sql

-- ── Restore from a compressed backup ──────────────────────
--   gunzip < backup.sql.gz | mysql -u root -p rd_infro_ecommerce

-- ── Restore into a brand-new database ─────────────────────
--   mysql -u root -p -e "CREATE DATABASE rd_infro_ecommerce_restored;"
--   mysql -u root -p rd_infro_ecommerce_restored < backup_full.sql


-- ============================================================
-- SECTION 3: USER MANAGEMENT & ACCESS CONTROL
-- (Run as root / DBA user)
-- ============================================================

USE rd_infro_ecommerce;

-- ── Create users ──────────────────────────────────────────

-- Read-only user (can only SELECT)
CREATE USER IF NOT EXISTS 'readonly_user'@'localhost'
    IDENTIFIED BY 'ReadOnly@2024';

-- Application user (standard CRUD)
CREATE USER IF NOT EXISTS 'app_user'@'localhost'
    IDENTIFIED BY 'AppUser@2024';

-- Reporting user (can SELECT and create temp tables)
CREATE USER IF NOT EXISTS 'report_user'@'localhost'
    IDENTIFIED BY 'Report@2024';

-- DBA backup user (needs LOCK TABLES + SELECT for mysqldump)
CREATE USER IF NOT EXISTS 'backup_user'@'localhost'
    IDENTIFIED BY 'Backup@2024';

-- Remote developer user (can connect from any host)
CREATE USER IF NOT EXISTS 'dev_user'@'%'
    IDENTIFIED BY 'DevUser@2024';


-- ── Grant Privileges ──────────────────────────────────────

-- readonly_user: SELECT only on all tables
GRANT SELECT
    ON rd_infro_ecommerce.*
    TO 'readonly_user'@'localhost';

-- app_user: Standard CRUD (no DROP/ALTER)
GRANT SELECT, INSERT, UPDATE, DELETE
    ON rd_infro_ecommerce.*
    TO 'app_user'@'localhost';

-- report_user: SELECT + CREATE TEMPORARY TABLES
GRANT SELECT, CREATE TEMPORARY TABLES
    ON rd_infro_ecommerce.*
    TO 'report_user'@'localhost';

-- backup_user: SELECT + LOCK TABLES (required for mysqldump)
GRANT SELECT, LOCK TABLES, SHOW VIEW, TRIGGER
    ON rd_infro_ecommerce.*
    TO 'backup_user'@'localhost';

-- dev_user: Full privileges on dev database only
GRANT ALL PRIVILEGES
    ON rd_infro_ecommerce.*
    TO 'dev_user'@'%';

-- Apply all privilege changes immediately
FLUSH PRIVILEGES;


-- ── Verify privileges ─────────────────────────────────────
SHOW GRANTS FOR 'readonly_user'@'localhost';
SHOW GRANTS FOR 'app_user'@'localhost';
SHOW GRANTS FOR 'report_user'@'localhost';
SHOW GRANTS FOR 'backup_user'@'localhost';
SHOW GRANTS FOR 'dev_user'@'%';


-- ── Revoke privileges ─────────────────────────────────────

-- Remove DELETE permission from app_user
-- REVOKE DELETE ON rd_infro_ecommerce.* FROM 'app_user'@'localhost';

-- Remove all privileges from a user
-- REVOKE ALL PRIVILEGES ON rd_infro_ecommerce.* FROM 'readonly_user'@'localhost';


-- ── Change user password ──────────────────────────────────
-- ALTER USER 'app_user'@'localhost' IDENTIFIED BY 'NewSecurePass@2024';
-- FLUSH PRIVILEGES;


-- ── Drop users ────────────────────────────────────────────
-- DROP USER IF EXISTS 'dev_user'@'%';
-- FLUSH PRIVILEGES;


-- ============================================================
-- SECTION 4: VIEWS FOR ROW-LEVEL SECURITY
-- (Give users access to a VIEW instead of the raw table)
-- ============================================================

-- View: Only shows delivered orders (safe for report_user)
CREATE OR REPLACE VIEW vw_delivered_orders AS
SELECT
    o.order_id,
    c.full_name      AS customer_name,
    o.total_amount,
    o.ordered_at
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'delivered';

-- Grant SELECT only on the view, not the raw tables
GRANT SELECT ON rd_infro_ecommerce.vw_delivered_orders
    TO 'readonly_user'@'localhost';

-- View: Public-safe product listing (hides stock levels)
CREATE OR REPLACE VIEW vw_public_products AS
SELECT
    p.product_id,
    p.name          AS product_name,
    cat.name        AS category,
    p.price
FROM products p
INNER JOIN categories cat ON p.category_id = cat.category_id;

GRANT SELECT ON rd_infro_ecommerce.vw_public_products
    TO 'readonly_user'@'localhost';


-- ============================================================
-- SECTION 5: ADDITIONAL SECURITY BEST PRACTICES (SQL)
-- ============================================================

-- ── List all users on the server ─────────────────────────
SELECT User, Host, account_locked, password_expired
FROM   mysql.user
ORDER BY User;

-- ── Check current connected user ──────────────────────────
SELECT CURRENT_USER();

-- ── Lock an account (temporarily disable login) ───────────
-- ALTER USER 'dev_user'@'%' ACCOUNT LOCK;

-- ── Unlock the account ────────────────────────────────────
-- ALTER USER 'dev_user'@'%' ACCOUNT UNLOCK;

-- ── Force password expiry (user must change on next login) ─
-- ALTER USER 'app_user'@'localhost' PASSWORD EXPIRE;

-- ── Set a password policy (require change every 90 days) ──
-- ALTER USER 'app_user'@'localhost'
--     PASSWORD EXPIRE INTERVAL 90 DAY;


-- ============================================================
-- SECTION 6: AUTOMATED BACKUP SCRIPT (save as backup.sh)
-- Run this in bash/terminal (not SQL)
-- ============================================================

/*
#!/bin/bash

DB_NAME="rd_infro_ecommerce"
DB_USER="backup_user"
DB_PASS="Backup@2024"
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Run mysqldump with compression
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > $FILENAME

# Verify success
if [ $? -eq 0 ]; then
    echo "Backup successful: $FILENAME"
else
    echo "Backup FAILED!"
    exit 1
fi

# Delete backups older than 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
echo "Old backups cleaned up."
*/
