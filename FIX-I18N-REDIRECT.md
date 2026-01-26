# แก้ไขปัญหา i18n Redirect กลับไป Root

## ปัญหา:
เมื่อเข้า `http://yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me/` 
แล้วคลิกอะไรหรือไปหน้าอื่น จะ redirect กลับไป root (`/`) หมดเลย

## สาเหตุ:
1. **Cookie `i18n_redirected`** ใน browser ที่เก็บ redirect state
2. **Nuxt i18n configuration** ที่มี redirect logic
3. **redirectOn** ยังเปิดอยู่

## วิธีแก้ไข:

### Step 1: ลบ Cookie ใน Browser

#### Chrome/Edge:
1. เปิด Developer Tools (F12)
2. ไปที่ **Application** tab
3. ไปที่ **Storage** → **Cookies**
4. เลือก domain: `yardsalethailand-nuxt-8p0ykj-f4d600-157-85-98-150.traefik.me`
5. หา cookie ชื่อ `i18n_redirected`
6. คลิกขวา → **Delete** หรือกด **Delete** key
7. หรือ **Clear All Cookies** สำหรับ domain นี้

#### Firefox:
1. เปิด Developer Tools (F12)
2. ไปที่ **Storage** tab
3. ไปที่ **Cookies**
4. เลือก domain และลบ cookie `i18n_redirected`

#### Safari:
1. เปิด Developer Tools (Cmd+Option+I)
2. ไปที่ **Storage** tab
3. ไปที่ **Cookies**
4. ลบ cookie `i18n_redirected`

### Step 2: เปลี่ยน Nuxt i18n Strategy

แก้ไข Nuxt configuration file (เช่น `nuxt.config.js` หรือ `nuxt.config.ts`):

```javascript
export default {
  // ... other config
  i18n: {
    // ... other i18n config
    strategy: 'no_prefix', // ไม่ใช้ locale prefix เลย
    // หรือ
    // strategy: 'prefix_except_default', // ใช้ prefix ยกเว้น default locale
    redirectOn: false, // ปิด redirect อัตโนมัติ
    // หรือ
    // redirectOn: 'root', // redirect เฉพาะ root
  }
}
```

### Step 3: Restart Container

```bash
# Restart WordPress container
docker restart yardsale_wordpress_prod

# หรือ restart ทั้งหมด
docker-compose -f docker-compose.prod.yml restart
```

### Step 4: Clear Browser Cache

1. **Clear All Cookies** สำหรับ domain
2. **Clear Cache** (Ctrl+Shift+Delete)
3. **Hard Refresh** (Ctrl+Shift+R หรือ Cmd+Shift+R)
4. หรือใช้ **Incognito/Private Window**

## ตรวจสอบ:

### ตรวจสอบว่า Cookie ถูกลบแล้ว:

1. เปิด Developer Tools (F12)
2. ไปที่ **Application** → **Cookies**
3. ตรวจสอบว่าไม่มี cookie `i18n_redirected`

### ตรวจสอบ Nuxt Configuration:

```bash
# ถ้า Nuxt config อยู่ใน repo นี้
grep -r "i18n" nuxt.config.* 2>/dev/null || echo "Nuxt config not found in this repo"
```

### ตรวจสอบ Network Requests:

1. เปิด Developer Tools (F12)
2. ไปที่ **Network** tab
3. ลอง navigate ไปหน้าอื่น
4. ดูว่าไม่มี redirect (301/302) ไป root

## ถ้ายังมีปัญหา:

### ตรวจสอบ Traefik Logs:

```bash
docker logs <traefik_container> | grep -i redirect | tail -20
```

### ตรวจสอบ Nuxt Logs:

```bash
docker logs <nuxt_container> | grep -i redirect | tail -20
```

### ตรวจสอบ WordPress Logs:

```bash
docker logs yardsale_wordpress_prod | grep -i redirect | tail -20
```

## สรุป:

**สิ่งที่ต้องทำ:**
1. ✅ ลบ cookie `i18n_redirected` ใน browser
2. ✅ เปลี่ยน Nuxt i18n strategy เป็น `no_prefix`
3. ✅ ปิด `redirectOn` หรือตั้งเป็น `false`
4. ✅ Restart container
5. ✅ Clear browser cache

**หลังจากแก้ไข:**
- ไม่ควร redirect กลับไป root แล้ว
- จะ preserve current route เมื่อ navigate
- Traefik ไม่มี redirect rules (ถูกต้องแล้ว)
