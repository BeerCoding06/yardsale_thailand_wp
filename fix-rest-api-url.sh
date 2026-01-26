#!/bin/bash
# Fix WordPress REST API URL - ensure it uses correct domain

echo "=== Fix WordPress REST API URL ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

# Old domain (wrong)
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
echo "🔧 Fixing REST API URL:"
echo "   Old domain (wrong): ${OLD_DOMAIN}"
echo "   New domain (correct): ${NEW_DOMAIN}"
echo ""

# Step 1: Fix database URLs (ensure siteurl and home are correct)
echo "1. Fixing database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Update home (root domain)
UPDATE wp_options 
SET option_value = '${NEW_HOME}' 
WHERE option_name = 'home';

-- Update siteurl (subdirectory) - This is what WordPress uses for REST API
UPDATE wp_options 
SET option_value = '${NEW_SITEURL}' 
WHERE option_name = 'siteurl';

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

echo "✅ Database updated"
echo ""

# Step 2: Verify database URLs
echo "2. Verifying database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo ""
echo "3. Checking wp-config.php..."
docker exec $CONTAINER grep -A 3 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -10

echo ""
echo "4. Clearing WordPress cache..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true

echo "✅ Cache cleared"
echo ""

echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "   1. Restart container: docker restart $CONTAINER"
echo "   2. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "   3. Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   4. Test REST API: curl -I https://${NEW_DOMAIN}/wordpress/wp-json/"
echo ""
echo "   REST API URL should now be: https://${NEW_DOMAIN}/wordpress/wp-json/"
echo "   Link header should show: <https://${NEW_DOMAIN}/wordpress/wp-json/>; rel=\"https://api.w.org/\""
echo ""
