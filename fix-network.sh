#!/bin/bash
# Script to fix network connection for WordPress container

echo "Checking Traefik network..."

# Check if Traefik network exists
TRAEFIK_NETWORK=$(docker network ls | grep -i traefik | awk '{print $2}' | head -1)

if [ -z "$TRAEFIK_NETWORK" ]; then
    echo "No Traefik network found. Creating traefik_network..."
    docker network create traefik_network
    TRAEFIK_NETWORK="traefik_network"
else
    echo "Found Traefik network: $TRAEFIK_NETWORK"
fi

# Check if WordPress container exists
if docker ps -a | grep -q yardsale_wordpress_prod; then
    echo "Connecting WordPress container to $TRAEFIK_NETWORK..."
    docker network connect $TRAEFIK_NETWORK yardsale_wordpress_prod 2>/dev/null || echo "Container already connected or error occurred"
else
    echo "WordPress container not found. Please start it first with:"
    echo "docker-compose -f docker-compose.prod.yml up -d"
fi

echo "Done! Check with: docker network inspect $TRAEFIK_NETWORK"
