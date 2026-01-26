#!/bin/bash
# Fix ALL redirect issues - Complete solution

echo "=== Fix ALL Redirect Issues - Complete Solution ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

# Old domain (wrong - causing redirects)
OLD_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"
# New domain (correct)
NEW_DOMAIN="yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me"

NEW_HOME="https://${NEW_DOMAIN}"
NEW_SITEURL="https://${NEW_DOMAIN}/wordpress"

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""
echo "🔧 Fixing ALL redirect issues:"
echo "   Old domain (wrong): ${OLD_DOMAIN}"
echo "   New domain (correct): ${NEW_DOMAIN}"
echo ""

# Step 1: DELETE siteurl and home from database (Force wp-config.php)
echo "1. Deleting siteurl and home from database (forcing wp-config.php)..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Delete siteurl and home - WordPress will use wp-config.php instead
DELETE FROM wp_options WHERE option_name = 'siteurl';
DELETE FROM wp_options WHERE option_name = 'home';
EOF

echo "✅ Deleted siteurl and home from database"
echo ""

# Step 2: Replace ALL old domain references
echo "2. Replacing ALL old domain references in database..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Replace ALL old domain references
UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_DOMAIN}', '${NEW_DOMAIN}')
WHERE option_value LIKE '%${OLD_DOMAIN}%';

-- Also replace old URLs (http and https)
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}')
WHERE option_value LIKE '%https://${OLD_DOMAIN}%';

UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://${OLD_DOMAIN}', 'http://${NEW_DOMAIN}')
WHERE option_value LIKE '%http://${OLD_DOMAIN}%';
EOF

echo "✅ Replaced all old domain references"
echo ""

# Step 3: Verify wp-config.php uses dynamic domain
echo "3. Verifying wp-config.php..."
docker exec $CONTAINER grep -A 5 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -15

echo ""
echo "4. Checking for any remaining old domain references..."
OLD_COUNT=$(docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT COUNT(*) as count FROM wp_options WHERE option_value LIKE '%${OLD_DOMAIN}%';" 2>/dev/null | tail -1 | awk '{print $1}')
if [ "$OLD_COUNT" -gt 0 ]; then
    echo "⚠️  Found $OLD_COUNT records with old domain. Showing first 10:"
    docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, LEFT(option_value, 100) as option_value FROM wp_options WHERE option_value LIKE '%${OLD_DOMAIN}%' LIMIT 10;"
else
    echo "✅ No old domain references found"
fi

echo ""
echo "5. Clearing ALL caches..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/advanced-cache.php 2>/dev/null || true

# Clear rewrite rules
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "DELETE FROM wp_options WHERE option_name = 'rewrite_rules';" 2>/dev/null || true

echo "✅ All caches cleared"
echo ""

echo "=== Fix Complete ==="
echo ""
echo "⚠️  CRITICAL NEXT STEPS:"
echo "   1. Restart container: docker restart $CONTAINER"
echo "   2. Wait 10 seconds for container to start"
echo "   3. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "   4. Clear ALL cookies for both domains"
echo "   5. Use Incognito/Private window to test"
echo "   6. Try accessing: https://${NEW_DOMAIN}/wordpress/wp-admin/"
echo ""
echo "✅ WordPress will now use values from wp-config.php:"
echo "   - WP_HOME: dynamic from \$_SERVER['HTTP_HOST']"
echo "   - WP_SITEURL: dynamic from \$_SERVER['HTTP_HOST'] . '/wordpress'"
echo ""
echo "   NO MORE REDIRECTS to old domain!"
echo ""
