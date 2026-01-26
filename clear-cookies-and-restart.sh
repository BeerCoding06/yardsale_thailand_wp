#!/bin/bash
# Clear cookies and restart containers

echo "=== Clear Cookies and Restart ==="
echo ""

CONTAINER="yardsale_wordpress_prod"

# Check container
if ! docker ps | grep -q "$CONTAINER"; then
    echo "❌ Container $CONTAINER is not running!"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Step 1: Restart WordPress container
echo "1. Restarting WordPress container..."
docker restart $CONTAINER
sleep 3

echo "✅ Container restarted"
echo ""

# Step 2: Clear WordPress cache
echo "2. Clearing WordPress cache..."
docker exec $CONTAINER rm -rf /var/www/html/wp-content/cache/* 2>/dev/null || true
docker exec $CONTAINER rm -rf /var/www/html/wp-content/object-cache.php 2>/dev/null || true

echo "✅ Cache cleared"
echo ""

echo "=== Complete ==="
echo ""
echo "⚠️  IMPORTANT: Now you need to:"
echo ""
echo "1. Clear browser cookies:"
echo "   - Open Developer Tools (F12)"
echo "   - Go to Application/Storage > Cookies"
echo "   - Delete cookie 'i18n_redirected'"
echo "   - Or Clear All Cookies for the domain"
echo ""
echo "2. Clear browser cache:"
echo "   - Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)"
echo "   - Select 'Cached images and files'"
echo "   - Click 'Clear data'"
echo ""
echo "3. Hard refresh:"
echo "   - Press Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   - Or use Incognito/Private window"
echo ""
echo "4. Test navigation:"
echo "   - Try navigating to different pages"
echo "   - Should NOT redirect back to root"
echo ""
