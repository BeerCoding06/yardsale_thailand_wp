# แก้ไขปัญหา Redirect ไป Domain เก่า - แก้ทันที

## ปัญหา:
เข้า `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin` 
แต่ redirect ไป `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`

## สาเหตุ:
Database `wp_options` table ยังมี domain เก่าอยู่ และ WordPress ใช้ค่าจาก database ก่อน wp-config.php

## วิธีแก้ไข (รันคำสั่งนี้):

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db <<'EOF'
-- Update home (root domain - NO /wordpress)
UPDATE wp_options 
SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' 
WHERE option_name = 'home';

-- Update siteurl (subdirectory - WITH /wordpress)
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

## หรือใช้ Script:

```bash
chmod +x fix-redirect-now.sh
./fix-redirect-now.sh
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

## ตรวจสอบว่ามี domain เก่าเหลืออยู่หรือไม่:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, LEFT(option_value, 100) as option_value FROM wp_options WHERE option_value LIKE '%yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me%' LIMIT 20;"
```

**ต้องไม่มี output** (ไม่มี domain เก่าเหลืออยู่)

## หลังจากแก้ไข:

1. **Clear browser cache และ cookies** (สำคัญมาก!)
   - Chrome: Ctrl+Shift+Delete → Clear browsing data
   - หรือใช้ Incognito/Private window

2. **Clear WordPress cache** (ถ้ามี):
   ```bash
   docker exec yardsale_wordpress_prod rm -rf /var/www/html/wp-content/cache/*
   ```

3. **ลองเข้าใหม่:**
   - `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin`

## ถ้ายัง redirect อยู่:

### ตรวจสอบ WordPress Admin Settings:

1. เข้า WordPress Admin (ถ้าเข้าได้)
2. ไปที่ **Settings → General**
3. ตรวจสอบ:
   - **WordPress Address (URL)**: ต้องเป็น `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress`
   - **Site Address (URL)**: ต้องเป็น `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me`
4. **Save Changes**

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -i "WP_HOME\|WP_SITEURL"
```

ควรเห็นโค้ดที่ใช้ `$_SERVER['HTTP_HOST']` แบบ dynamic

### ตรวจสอบ Traefik Headers:

```bash
docker logs <traefik_container> | grep wordpress | tail -20
```

ตรวจสอบว่า Traefik ส่ง `X-Forwarded-Proto` และ `Host` headers มาถูกต้องหรือไม่
