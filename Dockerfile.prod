FROM wordpress:php8.2-apache

# Set working directory
WORKDIR /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Increase PHP memory limit and upload size
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "upload_max_filesize = 64M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini

# Remove default WordPress files (we'll copy our own)
RUN rm -rf /var/www/html/* /var/www/html/..?* /var/www/html/.[!.]*

# Copy WordPress files
COPY wordpress/ /var/www/html/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

