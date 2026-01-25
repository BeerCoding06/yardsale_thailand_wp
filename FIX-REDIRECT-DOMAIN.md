# แก้ไขปัญหา WordPress Redirect ไป Domain ผิด

## ปัญหา:
เมื่อเข้า `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/` 
WordPress redirect ไปที่ `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`

## สาเหตุ:
Database `siteurl` และ `home` ยังชี้ไปที่ domain เก่า (`yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`)

## วิธีแก้ไข:

### วิธีที่ 1: ใช้ Script (แนะนำ)

```bash
# 1. ให้สิทธิ์ execute
chmod +x fix-redirect-domain.sh

# 2. รัน script
./fix-redirect-domain.sh
```

### วิธีที่ 2: ใช้ SQL Command (รวดเร็ว)

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<EOF
UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' WHERE option_name = 'home';
UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = REPLACE(option_value, 'yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me') WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';
EOF
```

### วิธีที่ 3: ใช้ SQL File

```bash
docker exec -i yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db < fix-all-urls.sql
```

### วิธีที่ 4: ใช้ MySQL Interactive

```bash
# 1. เชื่อมต่อ MySQL
docker exec -it yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db

# 2. ใน MySQL prompt:
UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' WHERE option_name = 'home';
UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = REPLACE(option_value, 'yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me') WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';

# 3. ตรวจสอบ:
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');

# 4. ออก:
EXIT;
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
| home        | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me                              |
| siteurl     | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
+-------------+--------------------------------------------------------------------------------------------------+
```

## หลังจากแก้ไข:

1. **Clear browser cache** (สำคัญมาก!)
2. **ลองเข้า:** `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/`
3. **ควรไม่ redirect ไป domain เก่าอีกแล้ว**

## ถ้ายังมีปัญหา:

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 5 "WP_HOME\|WP_SITEURL"
```

ควรเห็นโค้ดที่ใช้ `$_SERVER['HTTP_HOST']` แบบ dynamic

### ตรวจสอบ Traefik Headers:

```bash
docker logs <traefik_container> | grep wordpress
```

ตรวจสอบว่า Traefik ส่ง `X-Forwarded-Proto` header มาหรือไม่
