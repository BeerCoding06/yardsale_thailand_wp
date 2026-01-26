#!/bin/bash
# Fix WordPress redirect to root issue

echo "=== Fix WordPress Root Redirect Issue ==="
echo ""

CONTAINER="yardsale_wordpress_prod"
DB_HOST="157.85.98.150"
DB_PORT="3306"
DB_USER="root"
DB_PASS="RootBeer06032534"
DB_NAME="nuxtcommerce_db"

DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Step 1: Disable WordPress canonical redirects for root
echo "1. Disabling WordPress canonical redirects..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME <<EOF
-- Disable canonical redirects
UPDATE wp_options SET option_value = '0' WHERE option_name = 'redirect_guess_404_to_fitler';
EOF

echo "✅ Disabled canonical redirects"
echo ""

# Step 2: Verify database URLs
echo "2. Verifying database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo ""
echo "3. Checking wp-config.php..."
docker exec $CONTAINER grep -A 3 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -10

echo ""
echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT:"
echo "   - WP_HOME should be: https://${DOMAIN} (root domain)"
echo "   - WP_SITEURL should be: https://${DOMAIN}/wordpress (subdirectory)"
echo ""
echo "   If pages still redirect to root, check:"
echo "   1. WordPress Admin → Settings → General"
echo "   2. Make sure 'WordPress Address (URL)' = https://${DOMAIN}/wordpress"
echo "   3. Make sure 'Site Address (URL)' = https://${DOMAIN}"
echo ""
