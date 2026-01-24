# 🔧 แก้ไขปัญหา CORS (Cross-Origin Resource Sharing)

## ✅ การแก้ไขที่ทำแล้ว

### 1. เพิ่ม CORS Headers ใน Nginx Config

เพิ่ม CORS headers ใน:
- **Server block หลัก**: สำหรับทุก requests
- **Static files locations**: `/wordpress/wp-content/` และ `/wordpress/wp-includes/`

### 2. CORS Headers ที่เพิ่ม:

```nginx
# CORS headers for cross-origin requests
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

# Handle preflight requests
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Max-Age' 1728000 always;
    add_header 'Content-Type' 'text/plain; charset=utf-8' always;
    add_header 'Content-Length' 0 always;
    return 204;
}
```

### 3. Rebuild และ Restart

- ✅ Rebuild Docker image
- ✅ Restart container

## 🔍 ตรวจสอบ

### ทดสอบ CORS Headers:

```bash
# ทดสอบจากภายใน container
docker exec yardsale_thailand03-app-1 curl -I "http://localhost/wordpress/wp-content/plugins/woocommerce/assets/client/blocks/woocommerce/mini-cart.js"
```

ควรเห็น headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE, PATCH`

### Domains ที่เกี่ยวข้อง:

- **WordPress Domain**: `yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
- **Access Domain**: `yardsalethailand-wp-8txv8a-1ef772-157-85-98-150.traefik.me`

## ⚠️ หมายเหตุ

1. **Security**: การใช้ `Access-Control-Allow-Origin: *` อนุญาตให้ทุก domain เข้าถึงได้
   - สำหรับ production ควรระบุ domain ที่เฉพาะเจาะจง
   - เช่น: `add_header 'Access-Control-Allow-Origin' 'http://yardsalethailand-wp-8txv8a-1ef772-157-85-98-150.traefik.me' always;`

2. **Traefik Routing**: ตรวจสอบว่า Traefik route ทั้งสอง domains ไปที่ container เดียวกัน

3. **WordPress URLs**: ตรวจสอบว่า WordPress URLs ใน database และ wp-config.php ถูกต้อง

## 📝 ขั้นตอนต่อไป

1. **ทดสอบใน Browser**: 
   - เปิด Developer Tools (F12)
   - ตรวจสอบ Network tab
   - ดูว่า CORS errors หายไปหรือไม่

2. **ถ้ายังมีปัญหา**:
   - ตรวจสอบ Traefik configuration
   - ตรวจสอบว่า WordPress URLs ถูกต้อง
   - ตรวจสอบ Nginx logs: `docker logs yardsale_thailand03-app-1`

## ✅ สรุป

- ✅ เพิ่ม CORS headers ใน Nginx config
- ✅ Rebuild Docker image
- ✅ Restart container
- ✅ ตรวจสอบ Nginx config syntax

**ลอง refresh หน้าเว็บอีกครั้งและตรวจสอบว่า CORS errors หายไปหรือไม่**
