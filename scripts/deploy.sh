#!/bin/bash

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

# Ensure correct permissions on SSH key
chmod 600 ~/.ssh/id_ed25519

# Start SSH agent if not running
eval $(ssh-agent -s)

# Add SSH key to agent
ssh-add ~/.ssh/id_ed25519

# Pull latest changes from deployment repo
git pull origin main

# Stop existing containers
docker-compose down

# Generate cache buster
export CACHE_DATE=$(date +%s)

# Build and start containers with SSH agent forwarding and no cache
export DOCKER_BUILDKIT=1
docker-compose build --no-cache --ssh default="$SSH_AUTH_SOCK"

# Start the containers in detached mode
docker-compose up -d

# Clean up unused images and build cache
docker image prune -f
docker builder prune -f

# Clean up SSH agent
ssh-agent -k
