# 🔧 แก้ไขปัญหา "Page not found" สำหรับ wp-admin

## ✅ การแก้ไขที่ทำแล้ว

### 1. อัปเดต wp-config.php
- `WP_HOME`: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
- `WP_SITEURL`: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`

### 2. อัปเดต WordPress URLs ใน Database
- `siteurl`: Production URL with `/wordpress` path
- `home`: Production URL without `/wordpress` path
- แก้ไข URLs ใน `wp_posts`, `wp_postmeta`, `wp_usermeta`

### 3. Restart Container
- Container ถูก restart เพื่อ apply changes

## 🔍 ตรวจสอบ

### URLs ที่ถูกต้อง:
- **WordPress Admin**: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`
- **WordPress Login**: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-login.php`
- **WordPress Home**: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`

### ถ้ายังมีปัญหา:

1. **ตรวจสอบ Nginx logs**:
   ```bash
   docker logs yardsale_thailand03-app-1 | tail -50
   ```

2. **ตรวจสอบ PHP-FPM logs**:
   ```bash
   docker exec yardsale_thailand03-app-1 tail -50 /var/log/php-fpm/error.log
   ```

3. **ตรวจสอบ WordPress URLs ใน database**:
   ```bash
   docker exec yardsale_thailand03-db-1 mysql -u root -proot nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
   ```

4. **ทดสอบจากภายใน container**:
   ```bash
   docker exec yardsale_thailand03-app-1 curl -I http://localhost/wordpress/wp-admin/
   ```

## 📝 สรุป

- ✅ wp-config.php: ตั้งค่า WP_HOME และ WP_SITEURL ถูกต้อง
- ✅ Database: อัปเดต URLs ทั้งหมดเป็น production domain
- ✅ Container: Restart แล้ว
- ✅ Nginx: Configuration ถูกต้อง

**ลองเข้าหน้า wp-admin อีกครั้ง:**
`http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`
