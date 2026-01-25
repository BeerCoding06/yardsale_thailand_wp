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
  
  # Add/Update subdirectory configuration if needed
  if [ ! -z "$WP_SITEURL_SUBDIRECTORY" ]; then
    # Remove old WP_SITEURL and WP_HOME definitions if they exist
    sed -i '/define(.*WP_SITEURL.*)/d' /var/www/html/wp-config.php
    sed -i '/define(.*WP_HOME.*)/d' /var/www/html/wp-config.php
    
    # Add new definitions before "That's all, stop editing!"
    sed -i "/That's all, stop editing!/i\\
// WordPress subdirectory configuration\\
define( 'WP_SITEURL', 'https://' . \\\$_SERVER['HTTP_HOST'] . '${WP_SITEURL_SUBDIRECTORY}' );\\
define( 'WP_HOME', 'https://' . \\\$_SERVER['HTTP_HOST'] . '${WP_SITEURL_SUBDIRECTORY}' );\\
" /var/www/html/wp-config.php
  fi
fi

# Fix .htaccess RewriteBase
# Since Traefik strips /wordpress prefix, container receives requests without /wordpress
# So RewriteBase should be / (root) not /wordpress/
if [ -f /var/www/html/.htaccess ]; then
  # Replace all RewriteBase to / because Traefik strips prefix
  sed -i "s|RewriteBase /yardsale_thailand/wordpress/|RewriteBase /|g" /var/www/html/.htaccess
  sed -i "s|RewriteBase /wordpress/|RewriteBase /|g" /var/www/html/.htaccess
  # Replace RewriteRule paths
  sed -i "s|/yardsale_thailand/wordpress/index.php|/index.php|g" /var/www/html/.htaccess
  sed -i "s|/wordpress/index.php|/index.php|g" /var/www/html/.htaccess
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/uploads || true
chown -R www-data:www-data /var/www/html/wp-content/cache || true
chmod -R 775 /var/www/html/wp-content/uploads || true
chmod -R 775 /var/www/html/wp-content/cache || true

# Execute the original command
exec "$@"
