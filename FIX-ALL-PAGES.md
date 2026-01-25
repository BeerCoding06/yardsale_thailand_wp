# แก้ไขปัญหา: เข้า /wordpress/ ต่างๆไม่ได้

## ปัญหา: 
- `/wordpress/wp-admin/` เข้าไม่ได้
- ไฟล์ต่างๆใน `/wordpress/` เข้าไม่ได้
- 404 error

## สาเหตุหลัก:
1. **Database URLs ยังไม่ได้แก้ไข** (สำคัญที่สุด!)
2. Permalink structure ไม่ถูกต้อง
3. Rewrite rules ยังไม่ได้ flush

## วิธีแก้ไข (Step by Step):

### Step 1: แก้ไข Database URLs

รันคำสั่งนี้:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl'; UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home'; UPDATE wp_options SET option_value = '/%postname%/' WHERE option_name = 'permalink_structure'; DELETE FROM wp_options WHERE option_name = 'rewrite_rules';"
```

### Step 2: ตรวจสอบว่าแก้ไขสำเร็จ

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home', 'permalink_structure');"
```

ควรเห็น:
```
+------------------+--------------------------------------------------------------------------------------------------+
| option_name      | option_value                                                                                      |
+------------------+--------------------------------------------------------------------------------------------------+
| home             | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
| permalink_structure | /%postname%/                                                                                  |
| siteurl          | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
+------------------+--------------------------------------------------------------------------------------------------+
```

### Step 3: Flush Rewrite Rules (สำคัญมาก!)

**วิธีที่ 1: ผ่าน WordPress Admin (แนะนำ)**
1. ลองเข้า: `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`
2. ไปที่: **Settings → Permalinks**
3. คลิก: **"Save Changes"** (ไม่ต้องเปลี่ยนอะไร แค่ save)

**วิธีที่ 2: ใช้ SQL (ถ้าเข้า admin ไม่ได้)**
```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "DELETE FROM wp_options WHERE option_name = 'rewrite_rules';"
```

### Step 4: Restart Container

```bash
docker restart yardsale_wordpress_prod
```

### Step 5: Clear Browser Cache

- ลบ browser cache
- หรือใช้ Incognito/Private mode

## ตรวจสอบ Configuration:

### 1. ตรวจสอบ .htaccess:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/.htaccess
```

ควรเห็น:
- `RewriteBase /`
- `RewriteRule . /index.php [L]`

### 2. ตรวจสอบ wp-config.php:
```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 1 "WP_SITEURL"
```

ควรเห็น:
```php
define( 'WP_SITEURL', 'https://' . $_SERVER['HTTP_HOST'] . '/wordpress' );
define( 'WP_HOME', 'https://' . $_SERVER['HTTP_HOST'] . '/wordpress' );
```

### 3. ตรวจสอบ Container Status:
```bash
docker ps | grep wordpress
docker logs yardsale_wordpress_prod --tail 50
```

### 4. ตรวจสอบ Traefik Configuration:
- ตรวจสอบใน UI ว่า:
  - **Path**: `/wordpress`
  - **Strip Path**: **ON** (เปิด)
  - **Container Port**: `80`

## หลังจากแก้ไข:

ลองเข้า:
- `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/`
- `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`
- `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/my-account/`

## ถ้ายังไม่ได้ผล:

### 1. ตรวจสอบว่า container รันอยู่:
```bash
docker ps | grep wordpress
```

### 2. ตรวจสอบ logs:
```bash
docker logs yardsale_wordpress_prod -f
```

### 3. ตรวจสอบ network:
```bash
docker network inspect yardsale_thailand03_default | grep wordpress
```

### 4. ทดสอบจากภายใน container:
```bash
docker exec yardsale_wordpress_prod curl -I http://localhost/
docker exec yardsale_wordpress_prod curl -I http://localhost/wp-admin/
```

## ใช้ Script อัตโนมัติ:

```bash
./COMPLETE-FIX.sh
```

Script นี้จะแก้ไขทุกอย่างให้อัตโนมัติ
