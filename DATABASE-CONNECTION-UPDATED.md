# Database Connection Updated

## Database Connection String:
```
mysql://root:Beer057055263@yardsalethailandwp-yardsalethailandwp-6nsrgl:3306/nuxtcommerce_db
```

## สิ่งที่อัปเดตแล้ว:

### 1. `wordpress/wp-config.php`:
- ✅ `DB_HOST` = `yardsalethailandwp-yardsalethailandwp-6nsrgl:3306`
- ✅ `DB_PASSWORD` = `Beer057055263`

### 2. `docker-compose.prod.yml`:
- ✅ `DB_HOST=yardsalethailandwp-yardsalethailandwp-6nsrgl:3306`
- ✅ `DB_PASSWORD=Beer057055263`

### 3. `docker-compose.desktop.yml`:
- ✅ `DB_HOST=yardsalethailandwp-yardsalethailandwp-6nsrgl:3306`
- ✅ `DB_PASSWORD=Beer057055263`

### 4. `docker-entrypoint.sh`:
- ✅ อัปเดต default values

## หลังจากอัปเดต:

### 1. Rebuild Container:

```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### 2. ตรวจสอบ Database Connection:

```bash
docker exec yardsale_wordpress_prod mysql -h yardsalethailandwp-yardsalethailandwp-6nsrgl -P 3306 -u root -pBeer057055263 nuxtcommerce_db -e "SELECT 1;"
```

ควรเห็น: `1`

### 3. ตรวจสอบ WordPress Logs:

```bash
docker logs yardsale_wordpress_prod | tail -20
```

ตรวจสอบว่าไม่มี database connection errors

## Database Connection Details:

- **Host**: `yardsalethailandwp-yardsalethailandwp-6nsrgl`
- **Port**: `3306`
- **User**: `root`
- **Password**: `Beer057055263`
- **Database**: `nuxtcommerce_db`

## ถ้ามีปัญหา:

### ตรวจสอบ Network Connectivity:

```bash
docker exec yardsale_wordpress_prod ping -c 3 yardsalethailandwp-yardsalethailandwp-6nsrgl
```

### ตรวจสอบ MySQL Connection:

```bash
docker exec yardsale_wordpress_prod mysql -h yardsalethailandwp-yardsalethailandwp-6nsrgl -P 3306 -u root -pBeer057055263 nuxtcommerce_db -e "SHOW DATABASES;"
```

### ตรวจสอบ wp-config.php:

```bash
docker exec yardsale_wordpress_prod cat /var/www/html/wp-config.php | grep -A 1 "DB_HOST\|DB_PASSWORD"
```

ควรเห็น:
- `DB_HOST` = `yardsalethailandwp-yardsalethailandwp-6nsrgl:3306`
- `DB_PASSWORD` = `Beer057055263`
