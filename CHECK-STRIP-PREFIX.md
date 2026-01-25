# ตรวจสอบและเอาออก Strip Prefix

## ⚠️ สำคัญ: ต้องปิด Strip Path ใน Traefik UI

โค้ด `event.path.replace(/^\/wordpress\/?/, '')` อาจอยู่ใน:
1. **Traefik UI Configuration** (สำคัญที่สุด!)
2. Frontend/API layer ที่เรียก WordPress

## การตั้งค่าใน Traefik UI:

### ตรวจสอบ Domain Configuration:

1. **เปิด Traefik UI/Dashboard**
2. **ไปที่ Domain Configuration** สำหรับ WordPress
3. **ตรวจสอบ:**
   - **Path**: `/wordpress`
   - **Strip Path**: **OFF** ⚠️ (ต้องปิด!)
   - **Container Port**: `80`

### ถ้า Strip Path = ON:

1. **เปลี่ยนเป็น OFF**
2. **Save Configuration**
3. **Restart Container** (ถ้าจำเป็น)

## ตรวจสอบ Docker Compose:

### ตรวจสอบ Labels:

```bash
docker inspect <container_name> | grep -i stripprefix
```

**ต้องไม่มี output** (ไม่มี strip prefix)

### ตรวจสอบ docker-compose.prod.yml:

ไฟล์นี้**ไม่มี strip prefix** แล้ว:
- ✅ ไม่มี `traefik.http.middlewares.*.stripprefix`
- ✅ ไม่มี `wordpress-stripprefix` ใน middlewares

## Configuration ที่ถูกต้อง:

### docker-compose.prod.yml (ปัจจุบัน):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.wordpress.rule=PathPrefix(`/wordpress`)"
  - "traefik.http.routers.wordpress.entrypoints=web"
  - "traefik.http.services.wordpress.loadbalancer.server.port=80"
  # NO strip prefix - WordPress receives /wordpress/ path directly
  - "traefik.http.middlewares.wordpress-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
  - "traefik.http.routers.wordpress.middlewares=wordpress-headers"
```

**ต้องไม่มี:**
- ❌ `traefik.http.middlewares.*.stripprefix`
- ❌ `wordpress-stripprefix` ใน middlewares list

### .htaccess (ปัจจุบัน):

```apache
RewriteBase /wordpress/
RewriteRule . /wordpress/index.php [L]
```

## หลังจากแก้ไขใน UI:

1. **Restart Container:**
   ```bash
   docker restart <container_name>
   ```

2. **ตรวจสอบว่า WordPress รับ path ตรงๆ:**
   ```bash
   docker exec <container_name> curl -I http://localhost/wordpress/wp-admin/
   ```

3. **ทดสอบ:**
   - `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`

## ถ้ายังมีปัญหา:

### ตรวจสอบ Traefik Logs:

```bash
docker logs <traefik_container_name> | grep wordpress
```

### ตรวจสอบ Apache Access Logs:

```bash
docker exec <wordpress_container> tail -f /var/log/apache2/access.log
```

แล้วลองเข้า `/wordpress/wp-admin/` ดูว่า log แสดง path อะไร

ควรเห็น: `GET /wordpress/wp-admin/ HTTP/1.1` (ไม่ใช่ `GET /wp-admin/`)
