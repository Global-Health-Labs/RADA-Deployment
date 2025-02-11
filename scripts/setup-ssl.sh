#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Load environment variables
if [ -f "../backend/.env" ]; then
    source ../backend/.env
else
    echo "Error: backend/.env file not found"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ] || [ -z "$API_DOMAIN" ]; then
    echo "Error: DOMAIN_NAME and API_DOMAIN must be set in backend/.env"
    exit 1
fi

# Install certbot and nginx plugin
amazon-linux-extras install epel -y
yum install certbot python3-certbot-nginx -y

# Stop nginx temporarily
systemctl stop nginx

# Get certificates for frontend
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email your-email@example.com \
    -d ${DOMAIN_NAME}

# Get certificates for backend
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email your-email@example.com \
    -d ${API_DOMAIN}

# Start nginx
systemctl start nginx

# Set up automatic renewal
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

echo "SSL certificates have been installed and configured for auto-renewal"
echo "Certificates installed for:"
echo "Frontend: ${DOMAIN_NAME}"
echo "Backend: ${API_DOMAIN}"
