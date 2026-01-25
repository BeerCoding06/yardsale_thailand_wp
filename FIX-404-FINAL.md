# แก้ไข 404 wp-admin - คำสั่งเดียวจบ

## ปัญหา: 404 Page not found: /wordpress/wp-admin/

## วิธีแก้ไข (รันคำสั่งเดียวนี้):

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl'; UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home';"
```

## หรือใช้ SQL File:

```bash
docker exec -i yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db < fix-database-urls.sql
```

## ตรวจสอบว่าแก้ไขสำเร็จ:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

ควรเห็น:
```
+-------------+--------------------------------------------------------------------------------------------------+
| option_name | option_value                                                                                      |
+-------------+--------------------------------------------------------------------------------------------------+
| home        | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
| siteurl     | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
+-------------+--------------------------------------------------------------------------------------------------+
```

## หลังจากแก้ไข:

1. **Clear browser cache** (สำคัญ!)
2. ลองเข้า: `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`

## ถ้ายังไม่ได้ผล:

### 1. ตรวจสอบ container:
```bash
docker ps | grep wordpress
```

### 2. ตรวจสอบ .htaccess:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/.htaccess | grep RewriteBase
```
ควรเห็น: `RewriteBase /`

### 3. ตรวจสอบ wp-config.php:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 1 "WP_SITEURL"
```

### 4. Restart container:
```bash
docker restart yardsale_wordpress_prod
```

### 5. ตรวจสอบ logs:
```bash
docker logs yardsale_wordpress_prod -f
```
