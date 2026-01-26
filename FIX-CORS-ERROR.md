# แก้ไขปัญหา CORS Error

## ปัญหา:
```
Access to script at 'http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/...' 
from origin 'http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' 
has been blocked by CORS policy
```

## สาเหตุ:
WordPress กำลัง generate URLs ด้วย domain เก่า (`yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`) 
แต่ page ถูกโหลดจาก domain ใหม่ (`yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me`)

**สาเหตุหลัก:**
1. Database `siteurl` และ `home` ยังมี domain เก่า
2. WordPress ใช้ค่าจาก database แทน wp-config.php
3. Resources (JS, CSS, fonts) ถูก generate ด้วย domain เก่า

## วิธีแก้ไข:

### Step 1: ใช้ Script (แนะนำ)

```bash
chmod +x fix-cors-domain.sh
./fix-cors-domain.sh
docker restart yardsale_wordpress_prod
```

### Step 2: ใช้ SQL Command

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<'EOF'
-- Update home (root domain)
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
   - Or use Incognito/Private window

## ตรวจสอบ:

### ตรวจสอบ Database URLs:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

ควรเห็น:
- `home` = `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me`
- `siteurl` = `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress`

### ตรวจสอบว่าไม่มี Domain เก่าเหลืออยู่:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, LEFT(option_value, 100) as option_value FROM wp_options WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%' LIMIT 20;"
```

**ต้องไม่มี output** (ไม่มี domain เก่าเหลืออยู่)

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 3 "WP_HOME\|WP_SITEURL"
```

ควรเห็น:
```php
define('WP_HOME', $protocol . '://' . $host);
define('WP_SITEURL', $protocol . '://' . $host . '/wordpress');
```

### ตรวจสอบ Network Requests:

1. เปิด Developer Tools (F12)
2. ไปที่ **Network** tab
3. Reload page
4. ตรวจสอบว่า resources โหลดจาก domain ใหม่:
   - `yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me`
   - ไม่ใช่ `yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`

## ถ้ายังมีปัญหา:

### เพิ่ม CORS Headers ใน Apache (ถ้าจำเป็น):

แก้ไข `.htaccess`:

```apache
# CORS headers for static resources
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
    Header set Access-Control-Allow-Headers "Content-Type, Authorization"
</IfModule>
```

หรือแก้ไข `Dockerfile.prod`:

```dockerfile
# Add CORS headers
RUN { \
    echo 'Header always set Access-Control-Allow-Origin "*"'; \
    echo 'Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"'; \
    echo 'Header always set Access-Control-Allow-Headers "Content-Type, Authorization"'; \
} >> /etc/apache2/apache2.conf
```

## สรุป:

**สิ่งที่ต้องทำ:**
1. ✅ แก้ไข database URLs ให้ใช้ domain ใหม่
2. ✅ Replace domain เก่าทั้งหมดใน database
3. ✅ Restart container
4. ✅ Clear WordPress cache
5. ✅ Clear browser cache
6. ✅ Hard refresh

**หลังจากแก้ไข:**
- Resources ควรโหลดจาก domain ใหม่
- ไม่มี CORS errors
- Page ทำงานปกติ
