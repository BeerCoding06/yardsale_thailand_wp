# 📋 Deploy Checklist - WordPress Production

## ✅ การตรวจสอบความพร้อมก่อน Deploy

### 1. Git Status
- [x] Git working tree clean
- [x] Commits ถูกต้อง

### 2. Configuration Files

#### wp-config.php
- [x] `DB_HOST` = `157.85.98.150:3306` (external database)
- [x] `WP_DEBUG` = `false` ✅ แก้ไขแล้ว
- [x] `WP_ENVIRONMENT_TYPE` = `production` ✅ แก้ไขแล้ว
- [x] `WP_SITEURL` = `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`
- [x] `WP_HOME` = `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress`

#### docker-compose.yml
- [x] `DB_HOST` = `mysql` (หรือ external database)
- [x] `WP_SITEURL` = Production URL
- [x] Traefik labels configured

#### .htaccess
- [x] `RewriteBase /` (ถูกต้องสำหรับ production)
- [x] Rewrite rules configured

### 3. Security
- [x] `WP_DEBUG` = `false` (production)
- [x] `WP_DEBUG_LOG` = `false`
- [x] `WP_ENVIRONMENT_TYPE` = `production`
- [ ] ตรวจสอบว่า sensitive files ไม่ถูก commit ไปที่ public repo

### 4. Docker
- [x] Dockerfile.prod exists
- [x] docker-compose.yml configured
- [x] Containers running

### 5. URLs
- [x] Production domain: `yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
- [x] WordPress path: `/wordpress`
- [x] No localhost/127.0.0.1 references

## ⚠️ Warnings ที่เหลืออยู่

1. **Sensitive Files**: `wp-config.php` และ `docker-compose.yml` มี sensitive information
   - ✅ ตรวจสอบว่าไม่ commit ไปที่ public repository
   - ✅ ใช้ environment variables หรือ secrets management

2. **RewriteBase**: Script อาจอ่านผิด แต่ `.htaccess` มี `RewriteBase /` ซึ่งถูกต้องแล้ว

## 🚀 ขั้นตอน Deploy

1. **Commit changes**:
   ```bash
   cd /Users/statff/Desktop/yardsale_thailand03
   git add wordpress/wp-config.php
   git commit -m "[PRODUCTION] Update wp-config for production: disable debug, set environment type"
   ```

2. **Push to remote**:
   ```bash
   git push origin main
   ```

3. **Build and deploy**:
   ```bash
   docker-compose down
   docker-compose build
   docker-compose up -d
   ```

4. **Verify**:
   - ตรวจสอบ WordPress admin: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/wordpress/wp-admin/`
   - ตรวจสอบ frontend: `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/`
   - ตรวจสอบ database connection
   - ตรวจสอบ logs: `docker-compose logs -f app`

## 📝 สรุปการเปลี่ยนแปลง

### wp-config.php
- ✅ `WP_DEBUG`: `true` → `false`
- ✅ `WP_DEBUG_LOG`: `true` → `false`
- ✅ `WP_ENVIRONMENT_TYPE`: `local` → `production`

### Status
- ✅ **พร้อม Deploy** (มี warnings ที่ไม่ critical)
