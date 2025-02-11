#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Function to clean up Docker
cleanup_docker() {
    echo "Cleaning up Docker..."
    # Stop all containers
    docker-compose --env-file ../.env down || true
    
    # Remove all containers
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    
    # Remove all networks
    docker network prune -f || true
    
    # Restart Docker daemon
    systemctl restart docker
    
    # Wait for Docker to be ready
    echo "Waiting for Docker to restart..."
    sleep 5
}

# Load deployment environment variables
if [ -f "../.env" ]; then
    echo "Loading deployment environment variables..."
    export $(cat ../.env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found in deployment directory"
    exit 1
fi

# Load backend environment variables
if [ -f "../backend/.env" ]; then
    echo "Loading backend environment variables..."
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Only process USE_HTTPS variable
        if [[ $key == USE_HTTPS ]]; then
            # Remove any surrounding quotes
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            export "$key=$value"
        fi
    done < "../backend/.env"
else
    echo "Error: backend/.env file not found"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: DOMAIN_NAME must be set in .env"
    exit 1
fi

echo "Using domain: $DOMAIN_NAME"

# Update package list and install certbot
dnf update -y
dnf install -y certbot python3-certbot-nginx

# Clean up Docker and ensure ports are free
cd ..
cleanup_docker

# Get certificate for the domain
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email shyam.p@appzoy.com \
    -d ${DOMAIN_NAME}

# Clean up again before starting containers
cleanup_docker

# Start Docker containers with explicit env file
echo "Starting Docker containers..."
docker-compose --env-file .env up -d

echo "SSL certificate has been installed and configured for auto-renewal"
echo "Certificate installed for: ${DOMAIN_NAME}"

# Set up automatic renewal
echo "Setting up automatic renewal..."
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

echo "Setup complete! Your certificate is installed and will auto-renew."
