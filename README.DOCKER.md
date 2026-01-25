# Docker Production Setup สำหรับ WordPress

## การใช้งาน

### 1. ตรวจสอบ Traefik Network

ก่อนรัน ต้องตรวจสอบว่า Traefik network ชื่ออะไร:

```bash
docker network ls | grep traefik
```

ถ้า network ชื่อ `traefik` หรือ `traefik_default` ให้แก้ไขใน `docker-compose.prod.yml`:

```yaml
networks:
  traefik_network:
    external: true
    name: traefik  # หรือ traefik_default ตามที่เจอ
```

### 2. Build และ Start

```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

### 3. ตรวจสอบ Logs

```bash
# ดู logs ของ WordPress container
docker-compose -f docker-compose.prod.yml logs -f wordpress

# ตรวจสอบว่า container รันอยู่
docker-compose -f docker-compose.prod.yml ps
```

### 4. ตรวจสอบ Traefik Configuration

ตรวจสอบว่า Traefik รู้จัก service นี้:

```bash
# ดู Traefik dashboard (ถ้ามี)
# หรือตรวจสอบ logs ของ Traefik
docker logs <traefik_container_name>
```

## ปัญหาที่อาจเจอ

### 502 Bad Gateway

1. **ตรวจสอบว่า WordPress container รันอยู่:**
   ```bash
   docker ps | grep wordpress
   ```

2. **ตรวจสอบ logs:**
   ```bash
   docker logs yardsale_wordpress_prod
   ```

3. **ตรวจสอบว่า Traefik network ถูกต้อง:**
   ```bash
   docker network inspect traefik_network
   ```

4. **ตรวจสอบว่า container อยู่ใน network เดียวกัน:**
   ```bash
   docker network inspect traefik_network | grep -A 5 wordpress
   ```

### Database Connection Error

- ตรวจสอบว่า database credentials ใน `docker-compose.prod.yml` ถูกต้อง
- ตรวจสอบว่า database server `157.85.98.150:3306` accessible จาก container

### Subdirectory Path Issues

- ตรวจสอบว่า `.htaccess` มี RewriteBase เป็น `/wordpress/`
- ตรวจสอบว่า `wp-config.php` มี `WP_SITEURL` และ `WP_HOME` ถูกต้อง

## การ Restart

```bash
# Restart container
docker-compose -f docker-compose.prod.yml restart wordpress

# หรือ rebuild และ restart
docker-compose -f docker-compose.prod.yml up -d --build --force-recreate wordpress
```

## การ Clean Up

```bash
# Stop และ remove containers
docker-compose -f docker-compose.prod.yml down

# Stop และ remove containers + volumes (ระวัง! จะลบข้อมูล uploads)
docker-compose -f docker-compose.prod.yml down -v
```
