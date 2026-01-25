# แก้ไข 404 my-account และ WooCommerce endpoints

## ปัญหา: 404 Page not found: /wordpress/my-account/

## สาเหตุ:
1. Database URLs ยังไม่ได้แก้ไข
2. Permalink structure ไม่ถูกต้อง
3. Rewrite rules ยังไม่ได้ flush

## วิธีแก้ไข (รันคำสั่งเดียวนี้):

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl'; UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home'; UPDATE wp_options SET option_value = '/%postname%/' WHERE option_name = 'permalink_structure';"
```

## หรือใช้ SQL File:

```bash
docker exec -i yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db < fix-all-urls.sql
```

## หลังจากแก้ไข Database:

### 1. Flush Rewrite Rules (สำคัญ!)

เข้าไปที่ WordPress Admin:
- `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`
- Settings → Permalinks
- คลิก "Save Changes" (ไม่ต้องเปลี่ยนอะไร แค่ save)

### 2. หรือใช้ WP-CLI (ถ้ามี):

```bash
docker exec yardsale_wordpress_prod wp rewrite flush --allow-root
```

### 3. หรือใช้ SQL:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = REPLACE(option_value, 'https://', 'https://') WHERE option_name = 'rewrite_rules'; DELETE FROM wp_options WHERE option_name = 'rewrite_rules';"
```

## ตรวจสอบ:

### 1. Database URLs:
```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home', 'permalink_structure');"
```

### 2. .htaccess:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/.htaccess
```
ควรมี rewrite rules สำหรับ WordPress

### 3. wp-config.php:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 1 "WP_SITEURL"
```

## หลังจากแก้ไข:

1. **Clear browser cache**
2. ลองเข้า:
   - `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/my-account/`
   - `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`

## ถ้ายังไม่ได้ผล:

### 1. ตรวจสอบ WooCommerce Settings:
- WooCommerce → Settings → Advanced
- ตรวจสอบว่า "Page setup" ถูกต้อง

### 2. ตรวจสอบ .htaccess permissions:
```bash
docker exec yardsale_wordpress_prod ls -la /var/www/html/.htaccess
```

### 3. Restart container:
```bash
docker restart yardsale_wordpress_prod
```

### 4. ตรวจสอบ logs:
```bash
docker logs yardsale_wordpress_prod -f
```
