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
    sed -i "s/getenv('DB_PASSWORD') ?: 'Beer057055263'/getenv('DB_PASSWORD') ?: '${DB_PASSWORD}'/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_HOST" ]; then
    # Handle DB_HOST with port
    sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '${DB_HOST}' );/" /var/www/html/wp-config.php || \
    sed -i "s/'yardsalethailandwp-yardsalethailandwp-6nsrgl:3306'/'${DB_HOST}'/" /var/www/html/wp-config.php
  fi
  
  # Update WP_DEBUG for production
  if [ ! -z "$WP_DEBUG" ]; then
    sed -i "s/define( 'WP_DEBUG', .* );/define( 'WP_DEBUG', ${WP_DEBUG} );/" /var/www/html/wp-config.php || \
    echo "define( 'WP_DEBUG', ${WP_DEBUG} );" >> /var/www/html/wp-config.php
  fi
  
  # Add/Update subdirectory configuration if needed
  if [ ! -z "$WP_SITEURL_SUBDIRECTORY" ]; then
    # Remove old WP_SITEURL and WP_HOME definitions if they exist
    # Remove the entire if block that defines WP_HOME and WP_SITEURL
    sed -i '/\/\/ WordPress subdirectory configuration/,/^}/d' /var/www/html/wp-config.php
    sed -i '/define(.*WP_SITEURL.*)/d' /var/www/html/wp-config.php
    sed -i '/define(.*WP_HOME.*)/d' /var/www/html/wp-config.php
    
    # Add new definitions before "That's all, stop editing!"
    # WP_HOME = root domain (https://domain.com)
    # WP_SITEURL = subdirectory (https://domain.com/wordpress)
    # Use HTTP_X_FORWARDED_PROTO to detect protocol
    sed -i "/That's all, stop editing!/i\\
// WordPress subdirectory configuration for /wordpress/\\
// WP_HOME = root domain (https://domain.com)\\
// WP_SITEURL = subdirectory (https://domain.com/wordpress)\\
// This will be overridden by entrypoint script if WP_SITEURL_SUBDIRECTORY is set\\
if ( ! defined( 'WP_HOME' ) || ! defined( 'WP_SITEURL' ) ) {\\
    \\\$protocol = (!empty(\\\$_SERVER['HTTP_X_FORWARDED_PROTO']))\\
        ? \\\$_SERVER['HTTP_X_FORWARDED_PROTO']\\
        : ((!empty(\\\$_SERVER['HTTPS']) && \\\$_SERVER['HTTPS'] !== 'off') ? 'https' : 'http');\\
\\
    \\\$host = \\\$_SERVER['HTTP_HOST'];\\
\\
    if ( ! defined( 'WP_HOME' ) ) {\\
        define('WP_HOME', \\\$protocol . '://' . \\\$host);\\
    }\\
    if ( ! defined( 'WP_SITEURL' ) ) {\\
        define('WP_SITEURL', \\\$protocol . '://' . \\\$host . '${WP_SITEURL_SUBDIRECTORY}');\\
    }\\
}\\
" /var/www/html/wp-config.php
  fi
fi

# Fix .htaccess RewriteBase
# WordPress receives /wordpress/ path directly (no strip prefix)
# So RewriteBase should be /wordpress/ not /
if [ -f /var/www/html/.htaccess ]; then
  # Replace all RewriteBase to /wordpress/ because WordPress receives full path
  sed -i "s|RewriteBase /yardsale_thailand/wordpress/|RewriteBase /wordpress/|g" /var/www/html/.htaccess
  sed -i "s|RewriteBase /$|RewriteBase /wordpress/|g" /var/www/html/.htaccess
  # Replace RewriteRule paths
  sed -i "s|/yardsale_thailand/wordpress/index.php|/wordpress/index.php|g" /var/www/html/.htaccess
  sed -i "s|/index\.php|/wordpress/index.php|g" /var/www/html/.htaccess
  # Ensure RewriteBase is /wordpress/
  if ! grep -q "RewriteBase /wordpress/" /var/www/html/.htaccess; then
    sed -i "s|^RewriteBase|RewriteBase /wordpress/|g" /var/www/html/.htaccess
  fi
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/uploads || true
chown -R www-data:www-data /var/www/html/wp-content/cache || true
chmod -R 775 /var/www/html/wp-content/uploads || true
chmod -R 775 /var/www/html/wp-content/cache || true

# Execute the original command
exec "$@"
