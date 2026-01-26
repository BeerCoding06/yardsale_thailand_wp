#!/bin/bash
# Fix CORS error - WordPress loading resources from wrong domain

echo "=== Fix CORS Domain Issue ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

# Old domain (wrong - causing CORS)
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
echo "🔧 Fixing domain mismatch:"
echo "   Old domain (wrong): ${OLD_DOMAIN}"
echo "   New domain (correct): ${NEW_DOMAIN}"
echo ""

# Step 1: Fix database URLs
echo "1. Fixing database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Update home (root domain)
UPDATE wp_options 
SET option_value = '${NEW_HOME}' 
WHERE option_name = 'home';

-- Update siteurl (subdirectory)
UPDATE wp_options 
SET option_value = '${NEW_SITEURL}' 
WHERE option_name = 'siteurl';

-- Replace ALL old domain references in wp_options
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
echo "4. Clearing WordPress cache..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true

echo "✅ Cache cleared"
echo ""

echo "5. Checking wp-config.php..."
docker exec $CONTAINER grep -A 3 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -10

echo ""
echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "   1. Restart container: docker restart $CONTAINER"
echo "   2. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "   3. Clear browser cookies for both domains"
echo "   4. Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   5. Try accessing: https://${NEW_DOMAIN}/wordpress/"
echo ""
echo "   Resources should now load from: ${NEW_DOMAIN}"
echo "   No more CORS errors!"
echo ""
