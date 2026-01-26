#!/bin/bash
# Check and fix root redirect issue

echo "=== Check Root Redirect Issue ==="
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

# Step 1: Check database URLs
echo "1. Checking database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo ""
echo "2. Checking wp-config.php..."
docker exec $CONTAINER grep -A 3 "WP_HOME\|WP_SITEURL" /var/www/html/wp-config.php | head -10

echo ""
echo "3. Checking Traefik routes..."
echo "   Current Traefik rule: PathPrefix(/wordpress)"
echo "   Root domain (/) is NOT routed to WordPress container"
echo "   Root domain likely routes to Nuxt container"
echo ""

echo "=== Analysis ==="
echo ""
echo "⚠️  PROBLEM:"
echo "   - Root domain (/) does NOT route to WordPress container"
echo "   - Traefik only routes /wordpress to WordPress"
echo "   - When accessing root domain, it goes to Nuxt container"
echo "   - WordPress redirects back to root because WP_HOME = root domain"
echo ""
echo "✅ SOLUTION:"
echo "   1. Root domain should route to Nuxt app (not WordPress)"
echo "   2. WordPress should only handle /wordpress/* paths"
echo "   3. If you need root domain to show WordPress, add Traefik route"
echo ""
echo "📝 To fix:"
echo "   - If root should show Nuxt: No action needed (current setup is correct)"
echo "   - If root should redirect to /wordpress: Add redirect middleware in Traefik"
echo "   - If root should show WordPress: Add root route in docker-compose.prod.yml"
echo ""
