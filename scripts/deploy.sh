#!/bin/bash

# Pull latest changes from deployment repo
git pull origin main

# Pull and recreate containers
docker-compose pull
docker-compose up -d --build

# Clean up unused images
docker image prune -f
