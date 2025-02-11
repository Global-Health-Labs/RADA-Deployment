#!/bin/bash

set -e  # Exit on error

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

# Create necessary directories
mkdir -p backend frontend

# Check for .env files
if [ ! -f backend/.env ]; then
    echo "Error: backend/.env file not found"
    echo "Please create backend/.env with your environment variables"
    exit 1
fi

# Check for SSL certificate if DB_USE_SSL is true
if grep -q "DB_USE_SSL=true" backend/.env; then
    if [ ! -f backend/db-ssl-certificate.pem ]; then
        echo "Error: SSL certificate (backend/db-ssl-certificate.pem) not found"
        echo "Please add the SSL certificate file as it's required when DB_USE_SSL=true"
        exit 1
    fi
fi

if [ ! -f frontend/.env ]; then
    echo "Warning: frontend/.env file not found"
    echo "Creating empty frontend/.env"
    touch frontend/.env
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
docker-compose down

echo "Building containers..."
export DOCKER_BUILDKIT=1
docker-compose build --no-cache backend
docker-compose build --no-cache frontend

echo "Starting containers..."
docker-compose up -d

echo "Cleaning up..."
docker image prune -f
docker builder prune -f

# Clean up SSH agent
eval $(ssh-agent -k)
