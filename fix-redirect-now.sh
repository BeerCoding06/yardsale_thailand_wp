#!/bin/bash
# Fix WordPress redirect to wrong domain - IMMEDIATE FIX

echo "=== Fix WordPress Redirect Domain - IMMEDIATE ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

# New domain (correct)
NEW_DOMAIN="yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me"
NEW_HOME="https://${NEW_DOMAIN}"
NEW_SITEURL="https://${NEW_DOMAIN}/wordpress"

# Old domain (wrong - to be replaced)
OLD_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"
OLD_HOME="https://${OLD_DOMAIN}"
OLD_SITEURL="https://${OLD_DOMAIN}/wordpress"

echo "🔧 Fixing redirect from: ${OLD_DOMAIN}"
echo "   To: ${NEW_DOMAIN}"
echo ""

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Step 1: Fix database URLs
echo "1. Fixing database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Update home (root domain) - MUST be root domain without /wordpress
UPDATE wp_options 
SET option_value = '${NEW_HOME}' 
WHERE option_name = 'home';

-- Update siteurl (subdirectory) - MUST include /wordpress
UPDATE wp_options 
SET option_value = '${NEW_SITEURL}' 
WHERE option_name = 'siteurl';

-- Replace ALL old domain references in wp_options
UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_DOMAIN}', '${NEW_DOMAIN}')
WHERE option_value LIKE '%${OLD_DOMAIN}%';

-- Also replace old URLs
UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_HOME}', '${NEW_HOME}')
WHERE option_value LIKE '%${OLD_HOME}%';

UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_SITEURL}', '${NEW_SITEURL}')
WHERE option_value LIKE '%${OLD_SITEURL}%';
EOF

echo "✅ Database updated"
echo ""

# Step 2: Verify database URLs
echo "2. Verifying database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo ""
echo "3. Checking for any remaining old domain references..."
OLD_COUNT=$(docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT COUNT(*) as count FROM wp_options WHERE option_value LIKE '%${OLD_DOMAIN}%';" 2>/dev/null | tail -1 | awk '{print $1}')
if [ "$OLD_COUNT" -gt 0 ]; then
    echo "⚠️  Found $OLD_COUNT records with old domain. Showing first 10:"
    docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, LEFT(option_value, 100) as option_value FROM wp_options WHERE option_value LIKE '%${OLD_DOMAIN}%' LIMIT 10;"
else
    echo "✅ No old domain references found"
fi

echo ""
echo "4. Clearing WordPress cache (if exists)..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true

echo ""
echo "5. Checking wp-config.php for hardcoded domains..."
docker exec $CONTAINER grep -i "yardsalethailand-nuxt" /var/www/html/wp-config.php 2>/dev/null && echo "⚠️  Found old domain in wp-config.php!" || echo "✅ No old domain in wp-config.php"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "   1. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "   2. Clear browser cookies for both domains"
echo "   3. Try accessing: ${NEW_HOME}/wordpress/wp-admin/"
echo "   4. If still redirecting, try incognito/private window"
echo ""
echo "If still redirecting, check:"
echo "   - WordPress Admin → Settings → General"
echo "   - WordPress Address (URL): should be ${NEW_SITEURL}"
echo "   - Site Address (URL): should be ${NEW_HOME}"
echo ""
