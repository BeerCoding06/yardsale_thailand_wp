#!/bin/bash
# Script to fix wp-admin 404 issue

echo "=== Fixing WordPress wp-admin 404 Issue ==="

# Check if container is running
if ! docker ps | grep -q yardsale_wordpress_prod; then
    echo "❌ Container yardsale_wordpress_prod is not running"
    echo "Starting container..."
    docker-compose -f docker-compose.prod.yml up -d
    sleep 5
fi

CONTAINER="yardsale_wordpress_prod"

echo ""
echo "1. Checking container status..."
docker ps | grep wordpress || echo "Container not found"

echo ""
echo "2. Checking .htaccess..."
docker exec $CONTAINER cat /var/www/html/.htaccess 2>/dev/null | grep -A 2 "RewriteBase" || echo "Cannot read .htaccess"

echo ""
echo "3. Checking wp-config.php WP_SITEURL and WP_HOME..."
docker exec $CONTAINER cat /var/www/html/wp-config.php 2>/dev/null | grep -A 1 "WP_SITEURL\|WP_HOME" || echo "Cannot read wp-config.php"

echo ""
echo "4. Testing internal connection..."
docker exec $CONTAINER curl -I http://localhost/wp-admin/ 2>/dev/null | head -3 || echo "Cannot test"

echo ""
echo "5. Checking WordPress database settings (if accessible)..."
docker exec $CONTAINER mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');" 2>/dev/null || echo "Cannot connect to database or tables don't exist"

echo ""
echo "=== Fix Instructions ==="
echo "If database shows wrong URLs, run this SQL:"
echo ""
echo "UPDATE wp_options SET option_value = 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';"
echo "UPDATE wp_options SET option_value = 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home';"
echo ""
echo "Or use WordPress CLI:"
echo "docker exec $CONTAINER wp option update siteurl 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' --allow-root"
echo "docker exec $CONTAINER wp option update home 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' --allow-root"
