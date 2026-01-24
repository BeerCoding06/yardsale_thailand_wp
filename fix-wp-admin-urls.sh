#!/bin/bash

PRODUCTION_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"
PRODUCTION_HOME="http://${PRODUCTION_DOMAIN}"
PRODUCTION_SITEURL="http://${PRODUCTION_DOMAIN}/wordpress"

echo "🔧 กำลังแก้ไข WordPress URLs สำหรับ wp-admin..."
echo "   Production Home: ${PRODUCTION_HOME}"
echo "   Production SiteURL: ${PRODUCTION_SITEURL}"
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "yardsale.*app|app.*yardsale" | head -1)
DB_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "yardsale.*db|db.*yardsale" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ ไม่พบ app container"
    exit 1
fi

if [ -z "$DB_CONTAINER" ]; then
    echo "❌ ไม่พบ db container"
    exit 1
fi

echo "   App Container: $CONTAINER"
echo "   DB Container: $DB_CONTAINER"
echo ""

# แก้ไข URLs ใน database
echo "2️⃣ กำลังแก้ไข WordPress URLs ใน database..."
docker exec $DB_CONTAINER mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข siteurl และ home
UPDATE wp_options SET option_value = '${PRODUCTION_SITEURL}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '${PRODUCTION_HOME}' WHERE option_name = 'home';

-- แก้ไข URLs ที่มี localhost หรือ 127.0.0.1
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost', '${PRODUCTION_HOME}') WHERE option_value LIKE '%localhost%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1', '${PRODUCTION_HOME}') WHERE option_value LIKE '%127.0.0.1%';

-- แก้ไข URLs ใน wp_posts
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://localhost', '${PRODUCTION_HOME}') WHERE post_content LIKE '%localhost%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://127.0.0.1', '${PRODUCTION_HOME}') WHERE post_content LIKE '%127.0.0.1%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://localhost', '${PRODUCTION_HOME}') WHERE guid LIKE '%localhost%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://127.0.0.1', '${PRODUCTION_HOME}') WHERE guid LIKE '%127.0.0.1%';

-- แก้ไข URLs ใน wp_postmeta
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://localhost', '${PRODUCTION_HOME}') WHERE meta_value LIKE '%localhost%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1', '${PRODUCTION_HOME}') WHERE meta_value LIKE '%127.0.0.1%';

-- แก้ไข URLs ใน wp_usermeta
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, 'http://localhost', '${PRODUCTION_HOME}') WHERE meta_value LIKE '%localhost%';
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1', '${PRODUCTION_HOME}') WHERE meta_value LIKE '%127.0.0.1%';

-- แสดงผล
SELECT 'Updated URLs' as status;
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "3️⃣ กำลัง restart container เพื่อ apply changes..."
docker restart $CONTAINER 2>/dev/null || echo "⚠️  ไม่สามารถ restart container ได้ (อาจต้อง restart manual)"

echo ""
echo "✅ เสร็จสิ้น!"
echo ""
echo "📋 ตรวจสอบ:"
echo "   - WordPress Admin: ${PRODUCTION_SITEURL}/wp-admin/"
echo "   - WordPress Login: ${PRODUCTION_SITEURL}/wp-login.php"
echo ""
