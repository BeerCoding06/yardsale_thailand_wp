#!/bin/bash

PRODUCTION_URL="http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress"

echo "🔧 กำลังแก้ไข URLs จาก 127.0.0.1 เป็น Production URL..."
echo "   Production URL: ${PRODUCTION_URL}"
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
docker ps | grep -E "yardsale|8000"

echo ""
echo "2️⃣ กำลังแก้ไข URLs ใน wp_options..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข URLs ทั้งหมด
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1/wordpress', '${PRODUCTION_URL}') WHERE option_value LIKE '%127.0.0.1/wordpress%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost/wordpress', '${PRODUCTION_URL}') WHERE option_value LIKE '%localhost/wordpress%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1/', '${PRODUCTION_URL}/') WHERE option_value LIKE 'http://127.0.0.1/%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost/', '${PRODUCTION_URL}/') WHERE option_value LIKE 'http://localhost/%';

-- ตั้งค่า siteurl และ home
UPDATE wp_options SET option_value = '${PRODUCTION_URL}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '${PRODUCTION_URL}' WHERE option_name = 'home';

-- ลบ upload_url_path และ fileupload_url ถ้ามี
DELETE FROM wp_options WHERE option_name IN ('upload_url_path', 'fileupload_url');

-- แสดงผล
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "3️⃣ กำลังแก้ไข URLs ใน wp_postmeta..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1/wordpress', '${PRODUCTION_URL}') WHERE meta_value LIKE '%127.0.0.1/wordpress%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://localhost/wordpress', '${PRODUCTION_URL}') WHERE meta_value LIKE '%localhost/wordpress%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://127.0.0.1/', '${PRODUCTION_URL}/') WHERE meta_value LIKE 'http://127.0.0.1/%';
SELECT 'Updated wp_postmeta' as status;
EOF

echo ""
echo "4️⃣ กำลังแก้ไข URLs ใน wp_posts..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://127.0.0.1/wordpress', '${PRODUCTION_URL}') WHERE post_content LIKE '%127.0.0.1/wordpress%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://127.0.0.1/wordpress', '${PRODUCTION_URL}') WHERE guid LIKE '%127.0.0.1/wordpress%';
SELECT 'Updated wp_posts' as status;
EOF

echo ""
echo "5️⃣ ตรวจสอบ URLs ที่เหลือ..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
SELECT COUNT(*) as remaining_127_urls FROM wp_options WHERE option_value LIKE '%127.0.0.1%' OR option_value LIKE '%localhost%';
EOF

echo ""
echo "6️⃣ Restart container..."
docker restart yardsale_thailand03-app-1

echo ""
echo "✅ เสร็จแล้ว!"
echo ""
echo "🌐 Production URL:"
echo "   ${PRODUCTION_URL}"
echo ""
echo "💡 ถ้ายังมีปัญหา:"
echo "   - Clear browser cache (Cmd+Shift+R)"
echo "   - ลองใช้ Incognito/Private mode"
echo "   - ตรวจสอบ Network tab ใน Browser DevTools"
