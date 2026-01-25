# แก้ไขปัญหา 404 wp-admin - Step by Step

## ปัญหา: 404 Page not found: /wordpress/wp-admin/

## สาเหตุหลัก:
WordPress database ยังไม่ได้ตั้งค่า `siteurl` และ `home` ให้ถูกต้อง

## วิธีแก้ไข (เลือกวิธีใดวิธีหนึ่ง):

### วิธีที่ 1: ใช้ MySQL Command Line (แนะนำ)

```bash
# 1. เชื่อมต่อ MySQL
docker exec -it yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db

# 2. ใน MySQL prompt รันคำสั่ง:
UPDATE wp_options SET option_value = 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home';

# 3. ตรวจสอบ:
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');

# 4. ออกจาก MySQL:
EXIT;
```

### วิธีที่ 2: ใช้ SQL File

```bash
# 1. Copy SQL file ไปที่ container
docker cp fix-database-urls.sql yardsale_wordpress_prod:/tmp/

# 2. รัน SQL
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db < /tmp/fix-database-urls.sql
```

### วิธีที่ 3: ใช้ phpMyAdmin หรือ Database Tool

1. เชื่อมต่อ database:
   - Host: `157.85.98.150:3306`
   - Database: `nuxtcommerce_db`
   - User: `root`
   - Password: `RootBeer06032534`

2. เปิด table `wp_options`

3. หาและแก้ไข 2 records:
   - `siteurl` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`
   - `home` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`

### วิธีที่ 4: ใช้ WordPress CLI (ถ้ามี wp-cli)

```bash
docker exec yardsale_wordpress_prod wp option update siteurl 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' --allow-root
docker exec yardsale_wordpress_prod wp option update home 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress' --allow-root
```

## ตรวจสอบหลังแก้ไข:

### 1. ตรวจสอบ database:
```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
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
ควรเห็น: `define( 'WP_SITEURL', 'https://' . $_SERVER['HTTP_HOST'] . '/wordpress' );`

### 4. Clear browser cache และทดสอบ:
- ลบ browser cache
- ลองเข้า: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`

## ถ้ายังไม่ได้ผล:

1. **ตรวจสอบว่า container รันอยู่:**
   ```bash
   docker ps | grep wordpress
   ```

2. **ตรวจสอบ logs:**
   ```bash
   docker logs yardsale_wordpress_prod -f
   ```

3. **ตรวจสอบว่า Traefik Strip Path เปิดอยู่:**
   - ใน UI ตรวจสอบว่า Strip Path = ON
   - Path = `/wordpress`

4. **Restart container:**
   ```bash
   docker restart yardsale_wordpress_prod
   ```

5. **ตรวจสอบ network:**
   ```bash
   docker network inspect yardsale_thailand03_default | grep wordpress
   ```
