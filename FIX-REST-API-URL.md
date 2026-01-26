# แก้ไขปัญหา WordPress REST API URL

## ปัญหา:
Link header แสดง REST API endpoint จาก domain เก่า:
```
<link rel="https://api.w.org/" href="http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-json/" />
```

ควรเป็น:
```
<link rel="https://api.w.org/" href="https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-json/" />
```

## สาเหตุ:
WordPress ใช้ `get_rest_url()` ซึ่งจะใช้ `get_home_url()` ที่มาจาก:
1. Database `home` option (ถ้ามี)
2. `WP_HOME` constant จาก wp-config.php

ถ้า database ยังมี domain เก่า WordPress จะใช้ค่าจาก database ก่อน wp-config.php

## วิธีแก้ไข:

### Step 1: ใช้ Script (แนะนำ)

```bash
chmod +x fix-rest-api-url.sh
./fix-rest-api-url.sh
docker restart yardsale_wordpress_prod
```

### Step 2: ใช้ SQL Command

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<'EOF'
-- Update home (root domain) - WordPress REST API uses this
UPDATE wp_options 
SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' 
WHERE option_name = 'home';

-- Update siteurl (subdirectory)
UPDATE wp_options 
SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' 
WHERE option_name = 'siteurl';

-- Replace ALL old domain references
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me')
WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';

-- Also replace old URLs
UPDATE wp_options 
SET option_value = REPLACE(option_value, 'https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me', 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me')
WHERE option_value LIKE '%https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%';

-- Verify
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOF
```

### Step 3: Restart Container

```bash
docker restart yardsale_wordpress_prod
```

### Step 4: Clear Cache

1. **Clear WordPress cache:**
   ```bash
   docker exec yardsale_wordpress_prod rm -rf /var/www/html/wp-content/cache/*
   ```

2. **Clear browser cache:**
   - Press Ctrl+Shift+Delete
   - Select "Cached images and files"
   - Click "Clear data"

3. **Hard refresh:**
   - Press Ctrl+Shift+R (or Cmd+Shift+R on Mac)

## ตรวจสอบ:

### ตรวจสอบ Database URLs:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

ควรเห็น:
- `home` = `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me`
- `siteurl` = `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress`

### ตรวจสอบ REST API URL:

```bash
# Test REST API endpoint
curl -I https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-json/
```

ควรเห็น Link header:
```
Link: <https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-json/>; rel="https://api.w.org/"
```

### ตรวจสอบ HTML Source:

1. เปิด Developer Tools (F12)
2. ไปที่ **Elements** tab
3. หา `<head>` section
4. ตรวจสอบ link tag:
   ```html
   <link rel="https://api.w.org/" href="https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-json/" />
   ```

## ถ้ายังมีปัญหา:

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 3 "WP_HOME\|WP_SITEURL"
```

ควรเห็น:
```php
define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wordpress');
```

### ลบ siteurl และ home จาก Database (Force wp-config.php):

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<'EOF'
-- Delete siteurl and home - Force WordPress to use wp-config.php
DELETE FROM wp_options WHERE option_name = 'siteurl';
DELETE FROM wp_options WHERE option_name = 'home';
EOF

docker restart yardsale_wordpress_prod
```

## สรุป:

**สิ่งที่ต้องทำ:**
1. ✅ แก้ไข database `home` และ `siteurl` ให้ใช้ domain ใหม่
2. ✅ Replace domain เก่าทั้งหมดใน database
3. ✅ Restart container
4. ✅ Clear WordPress cache
5. ✅ Clear browser cache
6. ✅ Hard refresh

**หลังจากแก้ไข:**
- REST API URL ควรชี้ไปที่ domain ใหม่
- Link header ควรแสดง domain ใหม่
- ไม่มี CORS errors
