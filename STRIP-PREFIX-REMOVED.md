# ✅ เอาออก Strip Prefix แล้ว

## สิ่งที่แก้ไข:

### 1. Docker Compose Files:
- ✅ `docker-compose.prod.yml` - ไม่มี strip prefix แล้ว
- ✅ `docker-compose.desktop.yml` - **แก้ไขแล้ว** (เอาออก strip prefix)
- ✅ `docker-compose.prod-fix.yml` - **แก้ไขแล้ว** (เอาออก strip prefix)

### 2. Configuration ที่ถูกต้อง:

**ไม่มี strip prefix middleware:**
- ❌ ไม่มี `traefik.http.middlewares.*.stripprefix`
- ❌ ไม่มี `wordpress-stripprefix` ใน middlewares list

**WordPress รับ path ตรงๆ:**
- ✅ `PathPrefix(/wordpress)` - Traefik route ไปที่ `/wordpress`
- ✅ **ไม่มี strip prefix** - WordPress รับ `/wordpress/wp-admin` ตรงๆ
- ✅ `.htaccess` ใช้ `RewriteBase /wordpress/`

## ⚠️ สำคัญ: ต้องตรวจสอบ Traefik UI

โค้ด `event.path.replace(/^\/wordpress\/?/, '')` อาจอยู่ใน **Traefik UI Configuration**

### ตรวจสอบใน Traefik UI:

1. **เปิด Traefik UI/Dashboard**
2. **ไปที่ Domain Configuration** สำหรับ WordPress
3. **ตรวจสอบ:**
   - **Path**: `/wordpress`
   - **Strip Path**: **OFF** ⚠️ (ต้องปิด!)
   - **Container Port**: `80`

### ถ้า Strip Path = ON:

1. **เปลี่ยนเป็น OFF**
2. **Save Configuration**
3. **Restart Container**

## หลังจากแก้ไข:

### 1. Restart Container:

```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### 2. ตรวจสอบ Labels:

```bash
docker inspect yardsale_wordpress_prod | grep -i stripprefix
```

**ต้องไม่มี output** (ไม่มี strip prefix)

### 3. ทดสอบ:

- `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`

## ตรวจสอบว่า WordPress รับ path ตรงๆ:

```bash
docker exec yardsale_wordpress_prod curl -I http://localhost/wordpress/wp-admin/
```

ควรเห็น: `GET /wordpress/wp-admin/ HTTP/1.1` (ไม่ใช่ `GET /wp-admin/`)

## ถ้ายังมีปัญหา:

### ตรวจสอบ Traefik Logs:

```bash
docker logs <traefik_container_name> | grep wordpress
```

### ตรวจสอบ Apache Access Logs:

```bash
docker exec yardsale_wordpress_prod tail -f /var/log/apache2/access.log
```

แล้วลองเข้า `/wordpress/wp-admin/` ดูว่า log แสดง path อะไร
