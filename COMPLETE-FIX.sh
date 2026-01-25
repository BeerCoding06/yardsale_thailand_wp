#!/bin/bash
# Complete fix for WordPress subdirectory issues

echo "=== Complete WordPress Fix ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"
SITE_URL="https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress"

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    echo "Starting container..."
    docker-compose -f docker-compose.prod.yml up -d
    sleep 5
fi

echo "✅ Container is running"
echo ""

# Fix database URLs
echo "1. Fixing database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
UPDATE wp_options SET option_value = '$SITE_URL' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '$SITE_URL' WHERE option_name = 'home';
UPDATE wp_options SET option_value = '/%postname%/' WHERE option_name = 'permalink_structure';
DELETE FROM wp_options WHERE option_name = 'rewrite_rules';
EOF

echo ""
echo "2. Verifying database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home', 'permalink_structure');"

echo ""
echo "3. Checking .htaccess..."
docker exec $CONTAINER cat /var/www/html/.htaccess | grep -A 2 "RewriteBase" || echo "Cannot read .htaccess"

echo ""
echo "4. Checking wp-config.php..."
docker exec $CONTAINER cat /var/www/html/wp-config.php | grep -A 1 "WP_SITEURL\|WP_HOME" || echo "Cannot read wp-config.php"

echo ""
echo "5. Testing internal connection..."
docker exec $CONTAINER curl -I http://localhost/wp-admin/ 2>&1 | head -3 || echo "Cannot test"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT: Go to WordPress Admin and flush rewrite rules:"
echo "   1. Visit: $SITE_URL/wp-admin/"
echo "   2. Go to: Settings → Permalinks"
echo "   3. Click: 'Save Changes' (don't change anything, just save)"
echo ""
echo "Then try accessing:"
echo "   - $SITE_URL/wp-admin/"
echo "   - $SITE_URL/my-account/"
echo "   - $SITE_URL/"
