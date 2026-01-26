# แก้ไขปัญหา Redirect กลับไป Domain เก่า - แก้ไขแบบสมบูรณ์

## ปัญหา:
เมื่อเข้า `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin` 
จะ redirect กลับไปที่ `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/` 
**ทุกครั้งและทุกลิงก์ด้วย**

## สาเหตุ:
1. **Database `siteurl` และ `home` ยังมี domain เก่า** - WordPress ใช้ค่าจาก database ก่อน wp-config.php
2. **WordPress redirect logic** ที่ redirect ไป domain เก่า
3. **Cache** ที่เก็บ domain เก่าไว้

## วิธีแก้ไข (แก้ไขแบบสมบูรณ์):

### วิธีที่ 1: ใช้ Script (แนะนำ - แก้ไขทุกอย่าง)

```bash
chmod +x fix-all-redirects-final.sh
./fix-all-redirects-final.sh
docker restart yardsale_wordpress_prod
```

Script นี้จะ:
1. **ลบ `siteurl` และ `home` ออกจาก database** - บังคับให้ WordPress ใช้ wp-config.php
2. แทนที่ domain เก่าทั้งหมดใน database
3. Clear cache ทั้งหมด
4. Clear rewrite rules

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

-- Also replace old URLs
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me')
WHERE option_value LIKE '%https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';

UPDATE wp_options 
SET option_value = REPLACE(option_value, 'http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me')
WHERE option_value LIKE '%http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';

-- Clear rewrite rules
DELETE FROM wp_options WHERE option_name = 'rewrite_rules';
EOF

docker restart yardsale_wordpress_prod
```

## หลังจากแก้ไข:

### Step 1: Restart Container

```bash
docker restart yardsale_wordpress_prod
# รอ 10 วินาทีให้ container start
sleep 10
```

### Step 2: Clear Browser Cache และ Cookies

1. **Clear All Cookies:**
   - Chrome: Settings → Privacy → Clear browsing data → Cookies
   - หรือ Developer Tools (F12) → Application → Cookies → Clear All

2. **Clear Cache:**
   - Press Ctrl+Shift+Delete
   - Select "Cached images and files"
   - Click "Clear data"

3. **Use Incognito/Private Window:**
   - Chrome: Ctrl+Shift+N (Cmd+Shift+N on Mac)
   - Firefox: Ctrl+Shift+P (Cmd+Shift+P on Mac)

### Step 3: ทดสอบ

ลองเข้า:
- `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`
- `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/`

**ไม่ควร redirect ไป domain เก่าอีกแล้ว**

## ตรวจสอบ:

### ตรวจสอบว่า Database ไม่มี siteurl และ home:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

**ต้องไม่มี output** (ไม่มี siteurl และ home ใน database)

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 5 "WP_HOME\|WP_SITEURL"
```

ควรเห็น:
```php
define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wordpress');
```

### ตรวจสอบว่าไม่มี Domain เก่าเหลืออยู่:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, LEFT(option_value, 100) as option_value FROM wp_options WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%' LIMIT 20;"
```

**ต้องไม่มี output** (ไม่มี domain เก่าเหลืออยู่)

### ตรวจสอบ Network Requests:

1. เปิด Developer Tools (F12)
2. ไปที่ **Network** tab
3. ลอง navigate ไปหน้าอื่น
4. ดูว่าไม่มี redirect (301/302) ไป domain เก่า

## ถ้ายัง redirect อยู่:

### ตรวจสอบ Traefik Logs:

```bash
docker logs <traefik_container> | grep -i redirect | tail -20
```

### ตรวจสอบ Apache Logs:

```bash
docker exec yardsale_wordpress_prod tail -f /var/log/apache2/access.log
```

ดูว่า request มาถึง WordPress container หรือไม่ และ redirect ไปไหน

### ตรวจสอบ WordPress Debug Log:

```bash
docker exec yardsale_wordpress_prod tail -f /var/www/html/wp-content/debug.log
```

## สรุป:

**สิ่งที่ต้องทำ:**
1. ✅ ลบ `siteurl` และ `home` ออกจาก database
2. ✅ แทนที่ domain เก่าทั้งหมดใน database
3. ✅ Clear cache ทั้งหมด
4. ✅ Restart container
5. ✅ Clear browser cache และ cookies
6. ✅ ใช้ Incognito/Private window

**หลังจากแก้ไข:**
- WordPress จะใช้ค่าจาก wp-config.php (dynamic domain)
- ไม่ redirect ไป domain เก่าอีกแล้ว
- ทุกลิงก์จะใช้ domain ใหม่
