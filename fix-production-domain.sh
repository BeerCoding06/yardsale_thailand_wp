#!/bin/bash

PRODUCTION_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"
PRODUCTION_URL="http://${PRODUCTION_DOMAIN}/wordpress"

echo "🔧 กำลังแก้ไข WordPress URLs สำหรับ Production Domain..."
echo "   Domain: ${PRODUCTION_DOMAIN}"
echo "   URL: ${PRODUCTION_URL}"
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
docker ps | grep -E "yardsale|8000"

echo ""
echo "2️⃣ กำลังแก้ไข WordPress URLs ใน database..."

# แก้ไข URLs ทั้งหมด
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข siteurl และ home
UPDATE wp_options SET option_value = '${PRODUCTION_URL}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '${PRODUCTION_URL}' WHERE option_name = 'home';

-- แก้ไข URLs ที่มี localhost หรือ 127.0.0.1
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE option_value LIKE '%127.0.0.1:8000%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE option_value LIKE '%localhost:8000%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1/', '${PRODUCTION_URL}/') WHERE option_value LIKE 'http://127.0.0.1/%';

-- แสดงผล
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "3️⃣ กำลังแก้ไข URLs ใน wp_posts..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข URLs ใน post content
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE post_content LIKE '%127.0.0.1:8000%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE post_content LIKE '%localhost:8000%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE guid LIKE '%127.0.0.1:8000%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE guid LIKE '%localhost:8000%';
EOF

echo ""
echo "4️⃣ Restart container..."
docker restart yardsale_thailand03-app-1

echo ""
echo "✅ เสร็จแล้ว!"
echo ""
echo "🌐 Production URLs:"
echo "   ${PRODUCTION_URL}"
echo "   ${PRODUCTION_URL}/wp-admin"
echo "   ${PRODUCTION_URL}/wp-login.php"
echo ""
echo "💡 ถ้ายังมีปัญหา:"
echo "   - Clear browser cache (Cmd+Shift+R)"
echo "   - ลองใช้ Incognito/Private mode"
echo "   - ตรวจสอบว่า container ทำงานอยู่: docker ps"
