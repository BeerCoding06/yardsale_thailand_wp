# แก้ไขปัญหา Redirect กลับไป Root - แบบง่าย

## ปัญหา:
เมื่อเข้า `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/` 
แล้วคลิกอะไรหรือไปหน้าอื่น จะ redirect กลับไป root (`/`) หมดเลย

## สาเหตุ:
**Root domain (`/`) ไม่ได้ route ไปที่ WordPress container** - มัน route ไปที่ Nuxt container แทน

- Traefik route ไปที่ `/wordpress` เท่านั้น
- Root domain (`/`) route ไปที่ Nuxt container
- เมื่อเข้า root domain แล้ว WordPress redirect กลับไป root เพราะ WP_HOME = root domain

## วิธีแก้ไข:

### ถ้า Root Domain ต้องแสดง Nuxt App (ไม่ใช่ WordPress):

**ไม่ต้องทำอะไร** - Setup ปัจจุบันถูกต้องแล้ว:
- Root domain (`/`) → Nuxt container
- `/wordpress/*` → WordPress container

**แต่ต้องแก้ไข WordPress redirect logic:**

```bash
# ตรวจสอบว่า WordPress ไม่ redirect ไป root ถ้าไม่ได้อยู่ใน /wordpress/ path
docker exec yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

ควรเห็น:
- `home` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
- `siteurl` = `https://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`

### ถ้า Root Domain ต้อง Redirect ไป `/wordpress/`:

เพิ่ม redirect middleware ใน Traefik UI:

1. เปิด Traefik UI/Dashboard
2. เพิ่ม middleware:
   - **Name**: `wordpress-root-redirect`
   - **Type**: `RedirectRegex`
   - **Regex**: `^https?://([^/]+)/?$`
   - **Replacement**: `https://$1/wordpress/`
   - **Permanent**: `true`

3. เพิ่ม route:
   - **Rule**: `Host(yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me) && PathPrefix(/)`
   - **Middleware**: `wordpress-root-redirect`
   - **Service**: WordPress container (หรือ Nuxt container แล้วแต่ต้องการ)

### ถ้า Root Domain ต้องแสดง WordPress:

แก้ไข `docker-compose.prod.yml` เพิ่ม route สำหรับ root:

```yaml
labels:
  # Existing /wordpress route
  - "traefik.enable=true"
  - "traefik.http.routers.wordpress.rule=PathPrefix(`/wordpress`)"
  - "traefik.http.routers.wordpress.entrypoints=web"
  - "traefik.http.services.wordpress.loadbalancer.server.port=80"
  - "traefik.http.middlewares.wordpress-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
  - "traefik.http.routers.wordpress.middlewares=wordpress-headers"
  
  # NEW: Root domain route (same service, different path)
  - "traefik.http.routers.wordpress-root.rule=Host(`yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`) && PathPrefix(`/`)"
  - "traefik.http.routers.wordpress-root.entrypoints=web"
  - "traefik.http.routers.wordpress-root.middlewares=wordpress-headers"
  - "traefik.http.routers.wordpress-root.priority=1"  # Lower priority than /wordpress
```

## ตรวจสอบ:

```bash
# ตรวจสอบ Traefik routes
docker logs <traefik_container> | grep wordpress | tail -20

# ตรวจสอบ WordPress config
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 3 "WP_HOME\|WP_SITEURL"
```

## สรุป:

**Setup ปัจจุบัน:**
- ✅ Root domain (`/`) → Nuxt container (ถูกต้อง)
- ✅ `/wordpress/*` → WordPress container (ถูกต้อง)

**ถ้ายัง redirect กลับไป root:**
- ตรวจสอบว่า Nuxt app ไม่ redirect ไป root
- ตรวจสอบว่า WordPress ไม่ redirect ไป root ถ้าไม่ได้อยู่ใน `/wordpress/` path
