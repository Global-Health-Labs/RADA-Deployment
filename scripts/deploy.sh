#!/bin/bash

set -e  # Exit on error

# Get the absolute path of the deployment directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

# Check if Docker daemon is accessible
if ! docker info > /dev/null 2>&1; then
    echo "Error: Cannot connect to Docker daemon. Please run:"
    echo "1. sudo usermod -aG docker \$USER"
    echo "2. Log out and log back in"
    exit 1
fi

# Check SSH key permissions
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Error: SSH key not found at ~/.ssh/id_ed25519"
    exit 1
fi

# Check for deployment .env file
if [ ! -f "${DEPLOY_DIR}/.env" ]; then
    echo "Error: .env file not found in deployment directory"
    echo "Please copy .env.template to .env and set your environment variables"
    exit 1
fi

# Load deployment environment variables
echo "Loading deployment environment variables..."
export $(cat "${DEPLOY_DIR}/.env" | grep -v '^#' | xargs)

if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: DOMAIN_NAME must be set in .env"
    exit 1
fi

# Create necessary directories
mkdir -p backend frontend

# Create env.sh script for frontend
cat > frontend/env.sh << EOL
#!/bin/sh

# Recreate config file
NGINX_ROOT=/usr/share/nginx/html
ENV_FILE="\${NGINX_ROOT}/env-config.js"

# Add runtime environment variables with actual values
echo "window._env_ = {" > \$ENV_FILE
echo "  VITE_BACKEND_URL: \"\${VITE_BACKEND_URL}\"," >> \$ENV_FILE
echo "}" >> \$ENV_FILE

# For debugging
echo "Generated env-config.js with content:"
cat \$ENV_FILE
EOL

# Make env.sh executable
chmod +x frontend/env.sh

# Check for backend .env file
if [ ! -f backend/.env ]; then
    echo "Error: backend/.env file not found"
    echo "Please create backend/.env with your environment variables"
    exit 1
fi

# Create frontend .env file with the correct backend URL
cat > frontend/.env << EOL
VITE_BACKEND_URL=https://${DOMAIN_NAME}/api
EOL

# Check for SSL certificate if DB_USE_SSL is true
if grep -q "DB_USE_SSL=true" backend/.env; then
    if [ ! -f backend/db-ssl-certificate.pem ]; then
        echo "Error: SSL certificate (backend/db-ssl-certificate.pem) not found"
        echo "Please add the SSL certificate file as it's required when DB_USE_SSL=true"
        exit 1
    fi
fi

# Kill any existing SSH agents
pkill ssh-agent || true

# Ensure correct permissions on SSH key
chmod 600 ~/.ssh/id_ed25519

# Start SSH agent and add key
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519

echo "Pulling latest changes..."
git pull origin main

echo "Stopping existing containers..."
docker-compose --env-file "${DEPLOY_DIR}/.env" down

echo "Building containers..."
export DOCKER_BUILDKIT=1
docker-compose --env-file "${DEPLOY_DIR}/.env" build --no-cache backend
docker-compose --env-file "${DEPLOY_DIR}/.env" build --no-cache frontend

echo "Starting containers..."
docker-compose --env-file "${DEPLOY_DIR}/.env" up -d

echo "Cleaning up..."
docker image prune -f
docker builder prune -f

# Clean up SSH agent
eval $(ssh-agent -k)

echo "Deployment complete!"
