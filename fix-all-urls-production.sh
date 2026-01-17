#!/bin/bash

PRODUCTION_DOMAIN="yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me"
PRODUCTION_URL="http://${PRODUCTION_DOMAIN}/wordpress"
OLD_URLS=("http://127.0.0.1:8000" "http://localhost:8000" "http://127.0.0.1/" "http://localhost/")

echo "🔧 กำลังแก้ไข WordPress URLs ทั้งหมดสำหรับ Production..."
echo "   Production URL: ${PRODUCTION_URL}"
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
docker ps | grep -E "yardsale|8000"

echo ""
echo "2️⃣ กำลังแก้ไข URLs ใน wp_options..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE option_value LIKE '%127.0.0.1:8000%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE option_value LIKE '%localhost:8000%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1/', '${PRODUCTION_URL}/') WHERE option_value LIKE 'http://127.0.0.1/%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost/', '${PRODUCTION_URL}/') WHERE option_value LIKE 'http://localhost/%';
SELECT 'Updated wp_options' as status;
EOF

echo ""
echo "3️⃣ กำลังแก้ไข URLs ใน wp_postmeta..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE meta_value LIKE '%127.0.0.1:8000%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE meta_value LIKE '%localhost:8000%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1/', '${PRODUCTION_URL}/') WHERE meta_value LIKE 'http://127.0.0.1/%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://localhost/', '${PRODUCTION_URL}/') WHERE meta_value LIKE 'http://localhost/%';
SELECT 'Updated wp_postmeta' as status;
EOF

echo ""
echo "4️⃣ กำลังแก้ไข URLs ใน wp_posts..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE post_content LIKE '%127.0.0.1:8000%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE post_content LIKE '%localhost:8000%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE guid LIKE '%127.0.0.1:8000%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE guid LIKE '%localhost:8000%';
SELECT 'Updated wp_posts' as status;
EOF

echo ""
echo "5️⃣ กำลังแก้ไข URLs ใน wp_usermeta..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1:8000', '${PRODUCTION_URL}') WHERE meta_value LIKE '%127.0.0.1:8000%';
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, 'http://localhost:8000', '${PRODUCTION_URL}') WHERE meta_value LIKE '%localhost:8000%';
SELECT 'Updated wp_usermeta' as status;
EOF

echo ""
echo "6️⃣ ตรวจสอบ URLs ที่เหลือ..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
SELECT COUNT(*) as remaining_localhost_urls FROM wp_options WHERE option_value LIKE '%127.0.0.1%' OR option_value LIKE '%localhost%';
EOF

echo ""
echo "7️⃣ Restart container..."
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
echo "   - ตรวจสอบ Network tab ใน Browser DevTools เพื่อดูว่าไฟล์ไหนที่ยังโหลดไม่ได้"
