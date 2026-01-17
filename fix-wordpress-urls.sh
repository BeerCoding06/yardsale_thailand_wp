#!/bin/bash

echo "🔧 กำลังแก้ไข WordPress URLs..."
echo ""

# ตรวจสอบ containers
echo "1️⃣ ตรวจสอบ containers..."
docker ps | grep -E "yardsale|8000"

echo ""
echo "2️⃣ กำลังแก้ไข WordPress URLs ใน database..."

# แก้ไขผ่าน database container
docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db <<EOF
UPDATE wp_options SET option_value = 'http://127.0.0.1:8000' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://127.0.0.1:8000' WHERE option_name = 'home';
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF

echo ""
echo "3️⃣ Restart container..."
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
