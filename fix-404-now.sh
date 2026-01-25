#!/bin/bash
# Quick fix for 404 wp-admin issue

echo "=== Fixing 404 wp-admin Issue ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150:3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"
SITE_URL="https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    echo "Please start it with: docker-compose -f docker-compose.prod.yml up -d"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Fix database URLs
echo "1. Fixing database URLs..."
docker exec $CONTAINER mysql -h 157.85.98.150 -P 3306 -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
UPDATE wp_options SET option_value = '$SITE_URL' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '$SITE_URL' WHERE option_name = 'home';
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "2. Checking .htaccess..."
docker exec $CONTAINER cat /var/www/html/.htaccess | grep -A 2 "RewriteBase" || echo "Cannot read .htaccess"

echo ""
echo "3. Checking wp-config.php..."
docker exec $CONTAINER cat /var/www/html/wp-config.php | grep -A 1 "WP_SITEURL\|WP_HOME" || echo "Cannot read wp-config.php"

echo ""
echo "4. Testing internal connection..."
docker exec $CONTAINER curl -I http://localhost/wp-admin/ 2>&1 | head -3 || echo "Cannot test"

echo ""
echo "=== Done ==="
echo "Try accessing: $SITE_URL/wp-admin/"
