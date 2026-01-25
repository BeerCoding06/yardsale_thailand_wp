#!/bin/bash
set -e

# Update wp-config.php with environment variables if they exist
if [ -f /var/www/html/wp-config.php ]; then
  # Update database settings from environment variables
  if [ ! -z "$DB_NAME" ]; then
    sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', '${DB_NAME}' );/" /var/www/html/wp-config.php || \
    sed -i "s/getenv('DB_NAME') ?: 'nuxtcommerce_db'/getenv('DB_NAME') ?: '${DB_NAME}'/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_USER" ]; then
    sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '${DB_USER}' );/" /var/www/html/wp-config.php || \
    sed -i "s/getenv('DB_USER') ?: 'root'/getenv('DB_USER') ?: '${DB_USER}'/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_PASSWORD" ]; then
    sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '${DB_PASSWORD}' );/" /var/www/html/wp-config.php || \
    sed -i "s/getenv('DB_PASSWORD') ?: 'RootBeer06032534'/getenv('DB_PASSWORD') ?: '${DB_PASSWORD}'/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_HOST" ]; then
    # Handle DB_HOST with port
    sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '${DB_HOST}' );/" /var/www/html/wp-config.php || \
    sed -i "s/'157.85.98.150:3306'/'${DB_HOST}'/" /var/www/html/wp-config.php
  fi
  
  # Update WP_DEBUG for production
  if [ ! -z "$WP_DEBUG" ]; then
    sed -i "s/define( 'WP_DEBUG', .* );/define( 'WP_DEBUG', ${WP_DEBUG} );/" /var/www/html/wp-config.php || \
    echo "define( 'WP_DEBUG', ${WP_DEBUG} );" >> /var/www/html/wp-config.php
  fi
  
  # Add subdirectory configuration if needed
  if [ ! -z "$WP_SITEURL_SUBDIRECTORY" ]; then
    # Check if WP_SITEURL and WP_HOME are already defined
    if ! grep -q "WP_SITEURL" /var/www/html/wp-config.php; then
      # Add before "That's all, stop editing!"
      cat >> /var/www/html/wp-config.php << EOF

// WordPress subdirectory configuration
define( 'WP_SITEURL', 'https://' . \$_SERVER['HTTP_HOST'] . '${WP_SITEURL_SUBDIRECTORY}' );
define( 'WP_HOME', 'https://' . \$_SERVER['HTTP_HOST'] . '${WP_SITEURL_SUBDIRECTORY}' );
EOF
    fi
  fi
fi

# Fix .htaccess RewriteBase for /wordpress/ subdirectory
if [ -f /var/www/html/.htaccess ]; then
  # Update RewriteBase to /wordpress/ if it's different
  if [ ! -z "$WP_SITEURL_SUBDIRECTORY" ]; then
    # Replace old paths with new subdirectory path
    sed -i "s|RewriteBase /yardsale_thailand/wordpress/|RewriteBase ${WP_SITEURL_SUBDIRECTORY}/|g" /var/www/html/.htaccess
    sed -i "s|/yardsale_thailand/wordpress/index.php|${WP_SITEURL_SUBDIRECTORY}/index.php|g" /var/www/html/.htaccess
    # If RewriteBase is /, change it to subdirectory
    sed -i "s|^RewriteBase /$|RewriteBase ${WP_SITEURL_SUBDIRECTORY}/|g" /var/www/html/.htaccess
  fi
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/uploads || true
chown -R www-data:www-data /var/www/html/wp-content/cache || true
chmod -R 775 /var/www/html/wp-content/uploads || true
chmod -R 775 /var/www/html/wp-content/cache || true

# Execute the original command
exec "$@"
