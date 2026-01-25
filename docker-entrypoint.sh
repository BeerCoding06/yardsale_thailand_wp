#!/bin/bash
set -e

# Wait for database to be ready
until mysqladmin ping -h "${DB_HOST:-db}" -u "${DB_USER:-wordpress}" -p"${DB_PASSWORD}" --silent; do
  echo "Waiting for database connection..."
  sleep 2
done

# Update wp-config.php with environment variables if they exist
if [ -f /var/www/html/wp-config.php ]; then
  # Update database settings from environment variables
  if [ ! -z "$DB_NAME" ]; then
    sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', '${DB_NAME}' );/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_USER" ]; then
    sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '${DB_USER}' );/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_PASSWORD" ]; then
    sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '${DB_PASSWORD}' );/" /var/www/html/wp-config.php
  fi
  
  if [ ! -z "$DB_HOST" ]; then
    sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '${DB_HOST}' );/" /var/www/html/wp-config.php
  fi
  
  # Update WP_DEBUG for production
  if [ ! -z "$WP_DEBUG" ]; then
    sed -i "s/define( 'WP_DEBUG', .* );/define( 'WP_DEBUG', ${WP_DEBUG} );/" /var/www/html/wp-config.php || \
    echo "define( 'WP_DEBUG', ${WP_DEBUG} );" >> /var/www/html/wp-config.php
  fi
fi

# Fix .htaccess RewriteBase if needed (remove subdirectory path for root installation)
if [ -f /var/www/html/.htaccess ]; then
  # Remove subdirectory paths from RewriteBase
  sed -i 's|RewriteBase /yardsale_thailand/wordpress/|RewriteBase /|g' /var/www/html/.htaccess
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/uploads || true
chown -R www-data:www-data /var/www/html/wp-content/cache || true
chmod -R 775 /var/www/html/wp-content/uploads || true
chmod -R 775 /var/www/html/wp-content/cache || true

# Execute the original command
exec "$@"
