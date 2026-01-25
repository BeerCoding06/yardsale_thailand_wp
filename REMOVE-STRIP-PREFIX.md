# เอาออก Strip Prefix - WordPress ต้องได้รับ path /wordpress/ ตรงๆ

## ⚠️ สำคัญ: ต้องปิด Strip Path ใน Traefik UI

โค้ด `event.path.replace(/^\/wordpress\/?/, '')` อาจอยู่ใน:
1. **Traefik UI Configuration** (สำคัญที่สุด!)
2. Frontend/API layer ที่เรียก WordPress

## การตั้งค่าใน Traefik UI:

### ตรวจสอบและแก้ไข:

1. **เปิด Traefik UI/Dashboard**
2. **ไปที่ Domain Configuration**
3. **ตรวจสอบว่า Strip Path = OFF** (ปิด)
   - ถ้าเป็น **ON** ให้เปลี่ยนเป็น **OFF**
   - **Path**: `/wordpress`
   - **Strip Path**: **OFF** ⚠️ (สำคัญมาก!)
   - **Container Port**: `80`

### ถ้าใช้ Docker Desktop:

1. เปิด Docker Desktop
2. ไปที่ container ที่เกี่ยวข้องกับ Traefik หรือ domain configuration
3. ตรวจสอบ labels หรือ environment variables
4. ตรวจสอบว่าไม่มี strip prefix configuration

## ตรวจสอบ Configuration:

### 1. ตรวจสอบ Docker Compose Labels:

```bash
docker inspect <container_name> | grep -A 20 "Labels"
```

**ต้องไม่มี:**
- `traefik.http.middlewares.*.stripprefix`
- หรือ middleware ที่ strip prefix

**ควรมี:**
- `traefik.http.routers.wordpress.rule=PathPrefix(/wordpress)`
- แต่ไม่มี strip prefix middleware

### 2. ตรวจสอบ Traefik Configuration File:

ถ้ามี Traefik config file (เช่น `traefik.yml` หรือ dynamic config):
- ตรวจสอบว่าไม่มี strip prefix rule สำหรับ `/wordpress`
- ตรวจสอบว่าไม่มี `ReplacePathRegex` หรือ `StripPrefix` middleware

### 3. ตรวจสอบ Frontend Code:

ถ้ามี frontend ที่เรียก WordPress API:
- ตรวจสอบว่าไม่มี `event.path.replace(/^\/wordpress\/?/, '')`
- ตรวจสอบว่า path ที่ส่งไปยัง WordPress ยังมี `/wordpress/` prefix

## Configuration ที่ถูกต้อง:

### docker-compose.prod.yml:

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
- `traefik.http.middlewares.*.stripprefix`
- `traefik.http.routers.wordpress.middlewares=wordpress-stripprefix`

### .htaccess:

```apache
RewriteBase /wordpress/
RewriteRule . /wordpress/index.php [L]
```

## หลังจากแก้ไข:

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

### ตรวจสอบว่า Request ถึง Container:

```bash
docker exec <wordpress_container> tail -f /var/log/apache2/access.log
```

แล้วลองเข้า `/wordpress/wp-admin/` ดูว่า log แสดง path อะไร
