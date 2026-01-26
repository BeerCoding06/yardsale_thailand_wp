# Force Fix WordPress Redirect - แก้ไขแบบบังคับ

## ปัญหา:
เข้า `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin` 
แต่ redirect ไป `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/` **ตลอดเลย**

## สาเหตุ:
WordPress ใช้ค่าจาก database (`wp_options`) ก่อน wp-config.php ถ้า database มีค่าอยู่แล้ว

## วิธีแก้ไข (Force wp-config.php):

### วิธีที่ 1: ใช้ Script (แนะนำ)

```bash
chmod +x force-fix-redirect.sh
./force-fix-redirect.sh
```

Script นี้จะ:
1. **ลบ `siteurl` และ `home` ออกจาก database** - บังคับให้ WordPress ใช้ค่าจาก wp-config.php
2. แทนที่ domain เก่าทั้งหมดใน database
3. Clear cache ทั้งหมด
4. Restart container

### วิธีที่ 2: ใช้ SQL Command

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<'EOF'
-- Delete siteurl and home - Force WordPress to use wp-config.php
DELETE FROM wp_options WHERE option_name = 'siteurl';
DELETE FROM wp_options WHERE option_name = 'home';

-- Replace ALL old domain references
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me')
WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';
EOF
```

### วิธีที่ 3: แก้ไข wp-config.php (ทำแล้ว)

`wp-config.php` ถูกแก้ไขให้ **force override** database values:

```php
// Force override database values - always use current domain
define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wordpress');
```

## หลังจากแก้ไข:

### 1. Restart Container:

```bash
docker restart yardsale_wordpress_prod
```

### 2. Clear Browser Cache:

- **Chrome**: Ctrl+Shift+Delete → Clear browsing data
- **หรือใช้ Incognito/Private window**

### 3. ลองเข้าใหม่:

- `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin`

## ตรวจสอบว่าแก้ไขสำเร็จ:

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 5 "WP_HOME\|WP_SITEURL"
```

ควรเห็น:
```php
define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wordpress');
```

### ตรวจสอบว่า database ไม่มี siteurl และ home:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

**ต้องไม่มี output** (ไม่มี siteurl และ home ใน database)

## ถ้ายัง redirect อยู่:

### ตรวจสอบ Traefik Headers:

```bash
docker logs <traefik_container> | grep wordpress | tail -20
```

ตรวจสอบว่า Traefik ส่ง `Host` header มาถูกต้องหรือไม่

### ตรวจสอบ Apache Logs:

```bash
docker exec yardsale_wordpress_prod tail -f /var/log/apache2/access.log
```

แล้วลองเข้า `/wordpress/wp-admin/` ดูว่า log แสดงอะไร

### ตรวจสอบ WordPress Debug Log:

```bash
docker exec yardsale_wordpress_prod tail -f /var/www/html/wp-content/debug.log
```

## สิ่งที่แก้ไข:

1. ✅ `wp-config.php` - Force override database values
2. ✅ `force-fix-redirect.sh` - Script ลบ database values และ clear cache
3. ✅ แทนที่ domain เก่าทั้งหมดใน database
