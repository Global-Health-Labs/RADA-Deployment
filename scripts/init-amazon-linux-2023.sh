#!/bin/bash

# Update the system
sudo dnf update -y

# Install Docker
sudo dnf install docker -y

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER
sudo systemctl restart docker

# Install Docker Compose
sudo dnf install docker-compose-plugin -y

# Print Docker version and info
docker --version
docker compose version

echo "Installation complete! Please log out and log back in for the group changes to take effect."
echo "After logging back in, run: docker info to verify the installation."
