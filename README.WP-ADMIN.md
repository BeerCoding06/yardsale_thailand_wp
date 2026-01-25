# การแก้ไขให้ wp-admin ทำงาน

## สิ่งที่แก้ไขแล้ว:

1. **wp-config.php**:
   - เพิ่ม `WP_SITEURL` และ `WP_HOME` สำหรับ subdirectory `/wordpress/`
   - ตั้งค่าให้ใช้ HTTPS และ subdirectory path

2. **.htaccess**:
   - แก้ไข RewriteBase จาก `/yardsale_thailand/wordpress/` เป็น `/wordpress/`
   - แก้ไข RewriteRule ให้ชี้ไปที่ `/wordpress/index.php`

3. **docker-entrypoint.sh**:
   - อัปเดต script ให้แก้ไข wp-config.php และ .htaccess อัตโนมัติ

4. **Traefik Configuration**:
   - เพิ่ม headers middleware สำหรับ WordPress
   - ตั้งค่า strip prefix middleware

## วิธีใช้งาน:

### 1. Rebuild และ restart container:

```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### 2. ตรวจสอบ logs:

```bash
docker logs yardsale_wordpress_prod -f
```

### 3. ตรวจสอบ wp-config.php ใน container:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 2 "WP_SITEURL"
```

### 4. ตรวจสอบ .htaccess ใน container:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/.htaccess
```

## URL ที่ควรใช้งาน:

- WordPress Admin: `https://your-domain.traefik.me/wordpress/wp-admin`
- WordPress Site: `https://your-domain.traefik.me/wordpress`

## ถ้ายังไม่ทำงาน:

1. **ตรวจสอบว่า container รันอยู่:**
   ```bash
   docker ps | grep wordpress
   ```

2. **ตรวจสอบว่า Traefik รู้จัก service:**
   - ดู Traefik dashboard หรือ logs

3. **ตรวจสอบ database connection:**
   ```bash
   docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 -e "SHOW DATABASES;"
   ```

4. **ตรวจสอบ WordPress installation:**
   - เข้าไปที่ `/wordpress/wp-admin/install.php` เพื่อติดตั้งใหม่ (ถ้ายังไม่ได้ติดตั้ง)

5. **Clear cache:**
   ```bash
   docker exec yardsale_wordpress_prod rm -rf /var/www/html/wp-content/cache/*
   ```

## ปัญหาที่อาจเจอ:

### 404 Error:
- ตรวจสอบว่า `.htaccess` ถูกต้อง
- ตรวจสอบว่า Apache mod_rewrite เปิดอยู่

### Redirect Loop:
- ตรวจสอบ `WP_SITEURL` และ `WP_HOME` ใน wp-config.php
- ตรวจสอบว่า Traefik strip prefix ทำงานถูกต้อง

### Database Connection Error:
- ตรวจสอบ database credentials
- ตรวจสอบว่า database server accessible จาก container
