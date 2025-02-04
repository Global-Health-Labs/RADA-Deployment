#!/bin/bash

# Check if Docker daemon is accessible
if ! docker info > /dev/null 2>&1; then
    echo "Error: Cannot connect to Docker daemon. Please run:"
    echo "1. sudo usermod -aG docker \$USER"
    echo "2. Log out and log back in"
    exit 1
fi

# Pull latest changes from deployment repo
git pull origin main

# Pull and recreate containers
docker compose pull
docker compose up -d --build

# Clean up unused images
docker image prune -f
