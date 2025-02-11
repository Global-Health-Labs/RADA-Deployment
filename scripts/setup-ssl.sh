#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Function to check and free ports
free_ports() {
    local ports=("80" "443" "3000" "8443")
    for port in "${ports[@]}"; do
        # Check if port is in use
        if netstat -tuln | grep ":$port " > /dev/null; then
            echo "Port $port is in use. Attempting to free it..."
            # Try to find and stop the process using the port
            pid=$(lsof -t -i:$port)
            if [ ! -z "$pid" ]; then
                echo "Stopping process $pid using port $port"
                kill -TERM $pid || kill -KILL $pid
            fi
        fi
    done
    # Wait a moment for ports to be freed
    sleep 2
}

# Load environment variables safely
if [ -f "../backend/.env" ]; then
    # Read each line and export variables that start with DOMAIN or USE_HTTPS
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Only process DOMAIN and USE_HTTPS variables
        if [[ $key == DOMAIN_NAME ]] || [[ $key == API_DOMAIN ]] || [[ $key == USE_HTTPS ]]; then
            # Remove any surrounding quotes and port numbers from the value
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" -e 's/:[0-9]*$//')
            export "$key=$value"
        fi
    done < "../backend/.env"
else
    echo "Error: backend/.env file not found"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ] || [ -z "$API_DOMAIN" ]; then
    echo "Error: DOMAIN_NAME and API_DOMAIN must be set in backend/.env"
    exit 1
fi

echo "Using domains:"
echo "Frontend: $DOMAIN_NAME"
echo "Backend: $API_DOMAIN"

# Update package list and install certbot
dnf update -y
dnf install -y certbot python3-certbot-nginx

# Stop Docker containers and free ports
echo "Stopping Docker containers..."
cd ..
docker-compose down || true
free_ports

# Stop nginx temporarily
systemctl stop nginx || true

# Get certificates for frontend
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email shyam.p@appzoy.com \
    -d ${DOMAIN_NAME}

# Get certificates for backend
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email shyam.p@appzoy.com \
    -d ${API_DOMAIN}

# Free ports again before starting containers
free_ports

# Start nginx
systemctl start nginx || true

# Restart Docker containers
echo "Restarting Docker containers..."
docker-compose up -d

# Set up automatic renewal
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

echo "SSL certificates have been installed and configured for auto-renewal"
echo "Certificates installed for:"
echo "Frontend: ${DOMAIN_NAME}"
echo "Backend: ${API_DOMAIN}"

echo "Setup complete! Your certificates are installed and will auto-renew."
