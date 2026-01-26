# แก้ไขปัญหา Redirect กลับไป Root

## ปัญหา:
เมื่อเข้า `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/` 
แล้วคลิกอะไรหรือไปหน้าอื่น จะ redirect กลับไป root (`/`) หมดเลย

## สาเหตุ:
1. **Root domain (`/`) ไม่ได้ route ไปที่ WordPress container** - Traefik route ไปที่ `/wordpress` เท่านั้น
2. Root domain อาจ route ไปที่ Nuxt container แทน
3. WordPress redirect logic ที่ redirect ไป root เพราะ WP_HOME เป็น root domain

## วิธีแก้ไข:

### วิธีที่ 1: เพิ่ม Traefik Route สำหรับ Root Domain

แก้ไข `docker-compose.prod.yml` เพื่อเพิ่ม route สำหรับ root domain:

```yaml
labels:
  # Existing /wordpress route
  - "traefik.enable=true"
  - "traefik.http.routers.wordpress.rule=PathPrefix(`/wordpress`)"
  - "traefik.http.routers.wordpress.entrypoints=web"
  - "traefik.http.services.wordpress.loadbalancer.server.port=80"
  - "traefik.http.middlewares.wordpress-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
  - "traefik.http.routers.wordpress.middlewares=wordpress-headers"
  
  # NEW: Add root domain route (redirect to /wordpress)
  - "traefik.http.routers.wordpress-root.rule=Host(`yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`) && PathPrefix(`/`)"
  - "traefik.http.routers.wordpress-root.entrypoints=web"
  - "traefik.http.middlewares.wordpress-redirect.redirectregex.regex=^https?://([^/]+)/?$$"
  - "traefik.http.middlewares.wordpress-redirect.redirectregex.replacement=https://$$1/wordpress/"
  - "traefik.http.middlewares.wordpress-redirect.redirectregex.permanent=true"
  - "traefik.http.routers.wordpress-root.middlewares=wordpress-redirect"
```

### วิธีที่ 2: แก้ไขใน Traefik UI

1. เปิด Traefik UI/Dashboard
2. เพิ่ม route สำหรับ root domain:
   - **Rule**: `Host(yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me) && PathPrefix(/)`
   - **Middleware**: Redirect to `/wordpress/`
   - **Service**: WordPress container

### วิธีที่ 3: แก้ไข WordPress Configuration

ถ้า root domain ต้องแสดง Nuxt app (ไม่ใช่ WordPress):

1. **ตรวจสอบว่า root domain route ไปที่ container ไหน:**
   ```bash
   docker logs <traefik_container> | grep "yardsalethailand-nuxt"
   ```

2. **แก้ไข WordPress redirect logic:**
   - WordPress ไม่ควร redirect ไป root ถ้าไม่ได้อยู่ใน `/wordpress/` path
   - ตรวจสอบ `wp-config.php` ว่า WP_HOME และ WP_SITEURL ถูกต้อง

## ตรวจสอบ:

### ตรวจสอบ Traefik Routes:

```bash
# ดู Traefik dashboard หรือ
docker logs <traefik_container> | grep wordpress
```

### ตรวจสอบ WordPress Configuration:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 3 "WP_HOME\|WP_SITEURL"
```

ควรเห็น:
- `WP_HOME` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
- `WP_SITEURL` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`

### ตรวจสอบ Database:

```bash
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

## ถ้ายังมีปัญหา:

### ตรวจสอบ Apache Logs:

```bash
docker exec yardsale_wordpress_prod tail -f /var/log/apache2/access.log
```

ดูว่า request มาถึง WordPress container หรือไม่

### ตรวจสอบ Traefik Logs:

```bash
docker logs <traefik_container> | grep -i "yardsalethailand-nuxt" | tail -20
```

ดูว่า Traefik route ไปที่ container ไหน
