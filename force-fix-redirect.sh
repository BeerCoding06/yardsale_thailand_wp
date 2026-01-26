#!/bin/bash
# Force fix WordPress redirect - Remove database values to force wp-config.php

echo "=== Force Fix WordPress Redirect ==="
echo ""
echo "⚠️  This script will DELETE siteurl and home from database"
echo "    WordPress will use values from wp-config.php instead"
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

NEW_DOMAIN="yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me"
OLD_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Step 1: Delete siteurl and home from database
# WordPress will use wp-config.php values instead
echo "1. Deleting siteurl and home from database (forcing wp-config.php)..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Delete siteurl and home - WordPress will use wp-config.php
DELETE FROM wp_options WHERE option_name = 'siteurl';
DELETE FROM wp_options WHERE option_name = 'home';
EOF

echo "✅ Deleted siteurl and home from database"
echo ""

# Step 2: Replace ALL old domain references
echo "2. Replacing ALL old domain references..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Replace ALL old domain references
UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_DOMAIN}', '${NEW_DOMAIN}')
WHERE option_value LIKE '%${OLD_DOMAIN}%';

-- Also replace old URLs
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}')
WHERE option_value LIKE '%https://${OLD_DOMAIN}%';

UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://${OLD_DOMAIN}', 'http://${NEW_DOMAIN}')
WHERE option_value LIKE '%http://${OLD_DOMAIN}%';
EOF

echo "✅ Replaced all old domain references"
echo ""

# Step 3: Clear all caches
echo "3. Clearing all caches..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/advanced-cache.php 2>/dev/null || true

# Clear rewrite rules
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "DELETE FROM wp_options WHERE option_name = 'rewrite_rules';" 2>/dev/null || true

echo "✅ Cleared all caches"
echo ""

# Step 4: Verify wp-config.php
echo "4. Verifying wp-config.php..."
docker exec $CONTAINER grep -A 10 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -15

echo ""
echo "=== Fix Complete ==="
echo ""
echo "✅ WordPress will now use values from wp-config.php:"
echo "   - WP_HOME: dynamic from \$_SERVER['HTTP_HOST']"
echo "   - WP_SITEURL: dynamic from \$_SERVER['HTTP_HOST'] . '/wordpress'"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "   1. Restart container: docker restart $CONTAINER"
echo "   2. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "   3. Clear browser cookies for both domains"
echo "   4. Try accessing: http://${NEW_DOMAIN}/wordpress/wp-admin/"
echo "   5. If still redirecting, try incognito/private window"
echo ""
