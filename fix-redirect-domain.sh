#!/bin/bash
# Fix WordPress redirect to wrong domain

echo "=== Fix WordPress Redirect Domain ==="
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

echo "Current domain (wrong): ${OLD_DOMAIN}"
echo "New domain (correct): ${NEW_DOMAIN}"
echo ""

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Fix database URLs
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

-- Also update any old domain references in other options
UPDATE wp_options 
SET option_value = REPLACE(option_value, '${OLD_DOMAIN}', '${NEW_DOMAIN}')
WHERE option_value LIKE '%${OLD_DOMAIN}%';
EOF

echo ""
echo "2. Verifying database URLs..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo ""
echo "3. Checking for any remaining old domain references..."
docker exec $CONTAINER mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_value LIKE '%${OLD_DOMAIN}%' LIMIT 10;" || echo "No old domain references found"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "⚠️  IMPORTANT:"
echo "   1. Clear browser cache"
echo "   2. Try accessing: ${NEW_HOME}/"
echo "   3. Should NOT redirect to old domain anymore"
echo ""
