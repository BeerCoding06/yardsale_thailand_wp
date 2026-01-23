#!/bin/bash

echo "🔍 กำลังตรวจสอบความพร้อมก่อน Deploy..."
echo "=========================================="
echo ""

# สีสำหรับ output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# 1. ตรวจสอบ Git status
echo "1️⃣ ตรวจสอบ Git Status..."
cd /Users/statff/Desktop/yardsale_thailand03 2>/dev/null || cd /Users/statff/Desktop/yardsale_thailand_wp
if [ -d .git ]; then
    UNCOMMITTED=$(git status --short 2>/dev/null | grep -v "^??" | wc -l | tr -d ' ')
    if [ "$UNCOMMITTED" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  มี uncommitted changes:${NC}"
        git status --short 2>/dev/null | grep -v "^??" | head -5
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅ Git working tree clean${NC}"
    fi
    
    AHEAD=$(git status 2>/dev/null | grep "Your branch is ahead" | wc -l | tr -d ' ')
    if [ "$AHEAD" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  มี commits ที่ยังไม่ได้ push${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}❌ ไม่พบ .git directory${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. ตรวจสอบ Docker configuration
echo "2️⃣ ตรวจสอบ Docker Configuration..."
if [ -f "docker-compose.yml" ]; then
    echo -e "${GREEN}✅ พบ docker-compose.yml${NC}"
    
    # ตรวจสอบ DB_HOST
    DB_HOST=$(grep "DB_HOST=" docker-compose.yml | head -1 | sed 's/.*DB_HOST=\([^ ]*\).*/\1/')
    if [ -z "$DB_HOST" ]; then
        echo -e "${RED}❌ ไม่พบ DB_HOST ใน docker-compose.yml${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo "   DB_HOST: $DB_HOST"
    fi
    
    # ตรวจสอบ production URL
    PROD_URL=$(grep "WP_SITEURL=" docker-compose.yml | head -1 | sed 's/.*WP_SITEURL=\([^ ]*\).*/\1/')
    if [ -z "$PROD_URL" ]; then
        echo -e "${RED}❌ ไม่พบ WP_SITEURL ใน docker-compose.yml${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo "   Production URL: $PROD_URL"
        if [[ "$PROD_URL" == *"localhost"* ]] || [[ "$PROD_URL" == *"127.0.0.1"* ]]; then
            echo -e "${RED}❌ Production URL ยังใช้ localhost/127.0.0.1${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    fi
    
    # ตรวจสอบ Traefik labels
    TRAEFIK_ENABLE=$(grep "traefik.enable=true" docker-compose.yml | wc -l | tr -d ' ')
    if [ "$TRAEFIK_ENABLE" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  ไม่พบ Traefik labels${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅ พบ Traefik configuration${NC}"
    fi
else
    echo -e "${RED}❌ ไม่พบ docker-compose.yml${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. ตรวจสอบ wp-config.php
echo "3️⃣ ตรวจสอบ wp-config.php..."
if [ -f "wordpress/wp-config.php" ]; then
    echo -e "${GREEN}✅ พบ wp-config.php${NC}"
    
    # ตรวจสอบ DB_HOST ใน wp-config.php
    WP_DB_HOST=$(grep "define( 'DB_HOST'" wordpress/wp-config.php | sed "s/.*'DB_HOST', '\([^']*\)'.*/\1/")
    if [ -z "$WP_DB_HOST" ]; then
        echo -e "${RED}❌ ไม่พบ DB_HOST ใน wp-config.php${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo "   DB_HOST: $WP_DB_HOST"
        # ตรวจสอบว่าใช้ external database หรือไม่
        if [[ "$WP_DB_HOST" == *"157.85.98.150"* ]]; then
            echo -e "${GREEN}✅ ใช้ external database${NC}"
        elif [[ "$WP_DB_HOST" == "mysql" ]] || [[ "$WP_DB_HOST" == "localhost" ]]; then
            echo -e "${YELLOW}⚠️  ใช้ local database (ตรวจสอบว่า docker-compose มี mysql service)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
    
    # ตรวจสอบ WP_DEBUG
    WP_DEBUG=$(grep "define( 'WP_DEBUG'" wordpress/wp-config.php | grep -o "true\|false" | head -1)
    if [ "$WP_DEBUG" = "true" ]; then
        echo -e "${YELLOW}⚠️  WP_DEBUG=true (ควรปิดใน production)${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅ WP_DEBUG=false${NC}"
    fi
    
    # ตรวจสอบ WP_ENVIRONMENT_TYPE
    WP_ENV=$(grep "WP_ENVIRONMENT_TYPE" wordpress/wp-config.php | sed "s/.*'WP_ENVIRONMENT_TYPE', '\([^']*\)'.*/\1/" | head -1)
    if [ -z "$WP_ENV" ]; then
        echo -e "${YELLOW}⚠️  ไม่พบ WP_ENVIRONMENT_TYPE${NC}"
        WARNINGS=$((WARNINGS + 1))
    elif [ "$WP_ENV" = "local" ]; then
        echo -e "${YELLOW}⚠️  WP_ENVIRONMENT_TYPE='local' (ควรเปลี่ยนเป็น 'production')${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅ WP_ENVIRONMENT_TYPE='$WP_ENV'${NC}"
    fi
    
    # ตรวจสอบ WP_SITEURL และ WP_HOME
    WP_SITEURL=$(grep "define( 'WP_SITEURL'" wordpress/wp-config.php | sed "s/.*'WP_SITEURL', '\([^']*\)'.*/\1/" | head -1)
    WP_HOME=$(grep "define( 'WP_HOME'" wordpress/wp-config.php | sed "s/.*'WP_HOME', '\([^']*\)'.*/\1/" | head -1)
    
    if [ -n "$WP_SITEURL" ] && [ -n "$WP_HOME" ]; then
        echo "   WP_SITEURL: $WP_SITEURL"
        echo "   WP_HOME: $WP_HOME"
        if [[ "$WP_SITEURL" == *"localhost"* ]] || [[ "$WP_SITEURL" == *"127.0.0.1"* ]]; then
            echo -e "${RED}❌ WP_SITEURL ยังใช้ localhost/127.0.0.1${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        if [[ "$WP_HOME" == *"localhost"* ]] || [[ "$WP_HOME" == *"127.0.0.1"* ]]; then
            echo -e "${RED}❌ WP_HOME ยังใช้ localhost/127.0.0.1${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  ไม่พบ WP_SITEURL หรือ WP_HOME ใน wp-config.php${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}❌ ไม่พบ wordpress/wp-config.php${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. ตรวจสอบ Dockerfile
echo "4️⃣ ตรวจสอบ Dockerfile..."
if [ -f "Dockerfile.prod" ]; then
    echo -e "${GREEN}✅ พบ Dockerfile.prod${NC}"
    
    # ตรวจสอบว่าใช้ base image ที่ถูกต้อง
    BASE_IMAGE=$(grep "^FROM" Dockerfile.prod | head -1)
    if [ -n "$BASE_IMAGE" ]; then
        echo "   Base image: $BASE_IMAGE"
    fi
else
    echo -e "${YELLOW}⚠️  ไม่พบ Dockerfile.prod${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 5. ตรวจสอบ .htaccess
echo "5️⃣ ตรวจสอบ .htaccess..."
if [ -f "wordpress/.htaccess" ]; then
    echo -e "${GREEN}✅ พบ .htaccess${NC}"
    
    # ตรวจสอบ RewriteBase
    REWRITE_BASE=$(grep "RewriteBase" wordpress/.htaccess | head -1)
    if [ -n "$REWRITE_BASE" ]; then
        echo "   $REWRITE_BASE"
        if [[ "$REWRITE_BASE" == *"/yardsale"* ]] || [[ "$REWRITE_BASE" == *"/wordpress"* ]]; then
            echo -e "${YELLOW}⚠️  RewriteBase อาจไม่ถูกต้องสำหรับ production${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo -e "${YELLOW}⚠️  ไม่พบ .htaccess (WordPress จะสร้างให้อัตโนมัติ)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 6. ตรวจสอบ sensitive files
echo "6️⃣ ตรวจสอบ Sensitive Files..."
SENSITIVE_FILES=("wordpress/wp-config.php" ".env" "docker-compose.yml")
for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        # ตรวจสอบว่าไฟล์มี password หรือ secret
        if grep -q -i "password\|secret\|key" "$file" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  $file มี sensitive information (ตรวจสอบว่าไม่ commit ไปที่ public repo)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done
echo ""

# 7. ตรวจสอบ Docker containers
echo "7️⃣ ตรวจสอบ Docker Containers..."
if command -v docker &> /dev/null; then
    RUNNING=$(docker ps --format "{{.Names}}" | grep -E "yardsale|app" | wc -l | tr -d ' ')
    if [ "$RUNNING" -gt 0 ]; then
        echo -e "${GREEN}✅ พบ running containers: $RUNNING${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "yardsale|app|NAMES"
    else
        echo -e "${YELLOW}⚠️  ไม่พบ running containers${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Docker ไม่ได้ install หรือไม่สามารถเข้าถึงได้${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# สรุปผล
echo "=========================================="
echo "📊 สรุปผลการตรวจสอบ:"
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ พร้อม Deploy! ไม่พบปัญหา${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  พร้อม Deploy แต่มี $WARNINGS warnings${NC}"
    echo "   ควรแก้ไข warnings ก่อน deploy เพื่อความปลอดภัย"
    exit 0
else
    echo -e "${RED}❌ พบ $ERRORS errors และ $WARNINGS warnings${NC}"
    echo "   ต้องแก้ไข errors ก่อน deploy"
    exit 1
fi
