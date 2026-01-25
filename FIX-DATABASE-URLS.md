# แก้ไข Database URLs สำหรับ WordPress Subdirectory

## การตั้งค่าที่ถูกต้อง:

- **WP_HOME**: `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me` (root domain)
- **WP_SITEURL**: `https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress` (subdirectory)

## วิธีแก้ไข Database:

### วิธีที่ 1: ใช้ SQL File

```bash
docker exec -i <container_name> mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db < fix-all-urls.sql
```

### วิธีที่ 2: ใช้ Command Line

```bash
docker exec <container_name> mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' WHERE option_name = 'home'; UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl'; UPDATE wp_options SET option_value = '/%postname%/' WHERE option_name = 'permalink_structure'; DELETE FROM wp_options WHERE option_name = 'rewrite_rules';"
```

### วิธีที่ 3: ใช้ Docker Desktop

1. เปิด Docker Desktop
2. คลิกที่ container
3. ไปที่ tab **Exec** → คลิก **"New"**
4. รัน:
   ```bash
   mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db
   ```
5. ใน MySQL:
   ```sql
   UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me' WHERE option_name = 'home';
   UPDATE wp_options SET option_value = 'https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress' WHERE option_name = 'siteurl';
   EXIT;
   ```

## ตรวจสอบ:

```bash
docker exec <container_name> mysql -h 157.85.98.150 -P 3306 -u root -pRootBeer06032534 nuxtcommerce_db -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

ควรเห็น:
```
+-------------+--------------------------------------------------------------------------------------------------+
| option_name | option_value                                                                                      |
+-------------+--------------------------------------------------------------------------------------------------+
| home        | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me                                |
| siteurl     | https://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress                    |
+-------------+--------------------------------------------------------------------------------------------------+
```

## หลังจากแก้ไข:

1. **Flush Rewrite Rules:**
   - ไปที่: `http://yardsalethailand-wp-8txv8a-1b65c7-157-85-98-150.traefik.me/wordpress/wp-admin/`
   - Settings → Permalinks
   - คลิก "Save Changes"

2. **Restart Container:**
   ```bash
   docker restart <container_name>
   ```

3. **Clear Browser Cache**
