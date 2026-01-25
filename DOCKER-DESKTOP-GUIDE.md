# วิธีใช้ Docker Desktop สำหรับ WordPress

## การใช้งาน Docker Desktop

### 1. เปิด Docker Desktop

- เปิด Docker Desktop application
- รอให้ Docker engine เริ่มทำงาน (ไอคอน Docker ด้านบนจะแสดงว่า running)

### 2. Build และ Start Container

#### วิธีที่ 1: ใช้ Docker Desktop UI

1. เปิด Docker Desktop
2. ไปที่ **Containers** tab
3. คลิก **"Add"** หรือ **"New"**
4. เลือก **"Compose"** หรือ **"From Dockerfile"**
5. เลือกไฟล์ `docker-compose.prod.yml`
6. คลิก **"Run"**

#### วิธีที่ 2: ใช้ Command Line (ใน Terminal)

```bash
cd /Users/statff/Desktop/yardsale_thailand_wp
docker-compose -f docker-compose.prod.yml up -d --build
```

### 3. ตรวจสอบ Container ใน Docker Desktop

1. เปิด Docker Desktop
2. ไปที่ **Containers** tab
3. ควรเห็น container ชื่อ `yardsale_wordpress_prod`
4. ตรวจสอบว่า status เป็น **Running** (สีเขียว)

### 4. ดู Logs ใน Docker Desktop

1. คลิกที่ container `yardsale_wordpress_prod`
2. ไปที่ tab **Logs**
3. จะเห็น logs แบบ real-time

### 5. เปิด Terminal ใน Container

1. คลิกที่ container `yardsale_wordpress_prod`
2. ไปที่ tab **Exec**
3. คลิก **"New"** เพื่อเปิด terminal ใหม่
4. หรือใช้ command line:
   ```bash
   docker exec -it yardsale_wordpress_prod bash
   ```

### 6. ตรวจสอบ Network

1. ไปที่ **Networks** tab ใน Docker Desktop
2. ตรวจสอบว่า network `yardsale_thailand03_default` มีอยู่
3. ตรวจสอบว่า container `yardsale_wordpress_prod` เชื่อมต่อกับ network นี้

### 7. ตรวจสอบ Volumes

1. ไปที่ **Volumes** tab ใน Docker Desktop
2. ควรเห็น volumes:
   - `yardsale_thailand_wp_wp_uploads`
   - `yardsale_thailand_wp_wp_cache`

## การแก้ไข Database URLs ผ่าน Docker Desktop

### วิธีที่ 1: ใช้ Terminal ใน Container

1. เปิด Docker Desktop
2. คลิกที่ container `yardsale_wordpress_prod`
3. ไปที่ tab **Exec**
4. คลิก **"New"** เพื่อเปิด terminal
5. รันคำสั่ง:
   ```bash
   mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db
   ```
6. ใน MySQL prompt:
   ```sql
   UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';
   UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home';
   SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
   EXIT;
   ```

### วิธีที่ 2: ใช้ Command Line

```bash
docker exec -it yardsale_wordpress_prod mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl'; UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'home';"
```

## การ Restart Container

### ผ่าน Docker Desktop UI:

1. คลิกที่ container `yardsale_wordpress_prod`
2. คลิกปุ่ม **Restart** (หรือคลิกขวา → Restart)

### ผ่าน Command Line:

```bash
docker restart yardsale_wordpress_prod
```

## การ Stop/Start Container

### ผ่าน Docker Desktop UI:

1. คลิกที่ container `yardsale_wordpress_prod`
2. คลิกปุ่ม **Stop** หรือ **Start**

### ผ่าน Command Line:

```bash
# Stop
docker stop yardsale_wordpress_prod

# Start
docker start yardsale_wordpress_prod
```

## การดู Resource Usage

1. เปิด Docker Desktop
2. ไปที่ **Containers** tab
3. คลิกที่ container `yardsale_wordpress_prod`
4. ดู **Stats** tab เพื่อดู CPU, Memory, Network usage

## การแก้ไข Configuration

### แก้ไข docker-compose.prod.yml:

1. แก้ไขไฟล์ `docker-compose.prod.yml`
2. ใน Docker Desktop:
   - คลิกที่ container
   - คลิก **Restart** หรือ
   - Stop แล้ว Start ใหม่

### Rebuild Container:

```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

## Troubleshooting

### Container ไม่ start:

1. ดู **Logs** ใน Docker Desktop
2. ตรวจสอบ error messages
3. ตรวจสอบว่า port ไม่ conflict

### Network Issues:

1. ไปที่ **Networks** tab
2. ตรวจสอบว่า container อยู่ใน network `yardsale_thailand03_default`
3. ถ้าไม่มี ให้ connect container เข้า network:
   ```bash
   docker network connect yardsale_thailand03_default yardsale_wordpress_prod
   ```

### Volume Issues:

1. ไปที่ **Volumes** tab
2. ตรวจสอบว่า volumes มีอยู่
3. ถ้าไม่มี ให้ recreate:
   ```bash
   docker-compose -f docker-compose.prod.yml down -v
   docker-compose -f docker-compose.prod.yml up -d
   ```

## Tips

1. **ใช้ Docker Desktop UI** สำหรับดู logs และ stats แบบ real-time
2. **ใช้ Command Line** สำหรับ operations ที่ซับซ้อน
3. **ตรวจสอบ Logs** เป็นประจำเพื่อ debug issues
4. **ใช้ Exec tab** เพื่อรัน commands ใน container
