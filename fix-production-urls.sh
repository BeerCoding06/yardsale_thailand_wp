#!/bin/bash

echo "🔧 กำลังแก้ไข WordPress URLs สำหรับ Production..."
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
docker ps | grep -E "yardsale|8000"

echo ""
echo "2️⃣ กำลังแก้ไข WordPress URLs ใน database..."

# แก้ไข URLs ทั้งหมด
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข siteurl และ home
UPDATE wp_options SET option_value = 'http://127.0.0.1:8000' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://127.0.0.1:8000' WHERE option_name = 'home';

-- แก้ไข URLs ที่มี /wordpress ใน path
UPDATE wp_options SET option_value = REPLACE(option_value, '/wordpress', '') WHERE option_value LIKE '%/wordpress%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://127.0.0.1/', 'http://127.0.0.1:8000/') WHERE option_value LIKE 'http://127.0.0.1/%' AND option_value NOT LIKE '%:8000%';
UPDATE wp_options SET option_value = REPLACE(option_value, 'http://localhost/', 'http://127.0.0.1:8000/') WHERE option_value LIKE 'http://localhost/%';

-- แสดงผล
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "3️⃣ กำลังแก้ไข URLs ใน wp_posts..."
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
-- แก้ไข URLs ใน post content
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://127.0.0.1/wordpress/', 'http://127.0.0.1:8000/') WHERE post_content LIKE '%127.0.0.1/wordpress%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://localhost/wordpress/', 'http://127.0.0.1:8000/') WHERE post_content LIKE '%localhost/wordpress%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://127.0.0.1/wordpress/', 'http://127.0.0.1:8000/') WHERE guid LIKE '%127.0.0.1/wordpress%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://localhost/wordpress/', 'http://127.0.0.1:8000/') WHERE guid LIKE '%localhost/wordpress%';
EOF

echo ""
echo "4️⃣ Restart container..."
docker restart yardsale_thailand03-app-1

echo ""
echo "✅ เสร็จแล้ว!"
echo ""
echo "🌐 เปิดเบราว์เซอร์ไปที่:"
echo "   http://127.0.0.1:8000/wp-admin"
echo ""
echo "💡 ถ้ายังมีปัญหา:"
echo "   - Clear browser cache (Cmd+Shift+R)"
echo "   - ลองใช้ Incognito/Private mode"
echo "   - ตรวจสอบว่า container ทำงานอยู่: docker ps"
