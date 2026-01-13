# Docker Setup for YardSale Thailand WordPress

This project uses a standalone Dockerfile for running WordPress in a container.

## Prerequisites

- Docker installed on your system
- MySQL/MariaDB database server (can be on host machine or external)
- Port 8000 available (or choose another port)

## Quick Start

### 1. Build the Docker Image

```bash
docker build -t yardsale-wordpress .
```

### 2. Run the Container

**If your database is on the host machine:**
```bash
docker run -d \
  --name yardsale-wordpress \
  -p 8000:80 \
  --add-host=host.docker.internal:host-gateway \
  yardsale-wordpress
```

**If your database is external:**
```bash
docker run -d \
  --name yardsale-wordpress \
  -p 8000:80 \
  yardsale-wordpress
```

### 3. Access Your WordPress Site

Open your browser and go to: **http://localhost:8000**

## Database Configuration

### Update wp-config.php

You need to configure your database connection in `wordpress/wp-config.php`:

**If database is on host machine:**
```php
define( 'DB_HOST', 'host.docker.internal:3306' );
```

**If database is external:**
```php
define( 'DB_HOST', 'your-database-host:3306' );
```

**Current configuration in wp-config.php:**
- Database Name: `nuxtcommerce_db`
- Database User: `root`
- Database Password: `root`
- Update `DB_HOST` as shown above

## Useful Docker Commands

### View running containers
```bash
docker ps
```

### View container logs
```bash
docker logs yardsale-wordpress
```

### Follow container logs
```bash
docker logs -f yardsale-wordpress
```

### Stop the container
```bash
docker stop yardsale-wordpress
```

### Start the container
```bash
docker start yardsale-wordpress
```

### Remove the container
```bash
docker stop yardsale-wordpress
docker rm yardsale-wordpress
```

### Access container shell
```bash
docker exec -it yardsale-wordpress bash
```

### Rebuild the image
```bash
docker build -t yardsale-wordpress .
docker stop yardsale-wordpress
docker rm yardsale-wordpress
docker run -d --name yardsale-wordpress -p 8000:80 --add-host=host.docker.internal:host-gateway yardsale-wordpress
```

### Remove the image
```bash
docker rmi yardsale-wordpress
```

## Running with Volume Mount (for development)

If you want to edit WordPress files and see changes without rebuilding:

```bash
docker run -d \
  --name yardsale-wordpress \
  -p 8000:80 \
  -v $(pwd)/wordpress:/var/www/html \
  --add-host=host.docker.internal:host-gateway \
  yardsale-wordpress
```

**Note:** Using volume mount will override the files copied during build, so your local `wordpress/` directory will be used directly.

## Troubleshooting

### WordPress can't connect to database
- Ensure your database server is running and accessible
- If database is on host machine, use `host.docker.internal` as DB_HOST
- Check that `DB_HOST` in `wp-config.php` matches your database location
- Verify database credentials in `wp-config.php` are correct
- Test database connection from host machine first

### Permission issues
- WordPress files should be owned by `www-data:www-data` (handled automatically in the image)
- If you encounter permission issues with volume mount, run:
  ```bash
  docker exec -it yardsale-wordpress chown -R www-data:www-data /var/www/html
  ```

### Port already in use
- Change the port mapping (e.g., use `-p 8080:80` instead of `-p 8000:80`)

### Container won't start
- Check logs: `docker logs yardsale-wordpress`
- Verify the image was built successfully: `docker images | grep yardsale-wordpress`

## Production Considerations

⚠️ **This setup is for development only!** For production:

1. Use environment-specific secrets
2. Use proper SSL/TLS certificates
3. Set up proper backups
4. Use production-grade database passwords
5. Disable debug mode (`WP_DEBUG = false`)
6. Consider using a reverse proxy (nginx)
7. Ensure database is properly secured and accessible
8. Use Docker secrets or environment variables for sensitive data
