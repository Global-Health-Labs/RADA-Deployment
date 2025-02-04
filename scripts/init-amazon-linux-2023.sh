#!/bin/bash

# Update system packages
sudo dnf update -y

# Install Docker and Git
sudo dnf install -y docker git

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to the Docker group (optional, requires re-login to take effect)
sudo usermod -aG docker $USER

# Install Docker Compose v2 (comes as a plugin for Docker in Amazon Linux 2023)
sudo dnf install -y docker-compose-plugin

# Verify installations
docker --version
docker compose version

# Generate SSH key for private repositories (if needed)
ssh-keygen -t ed25519 -C "ec2-deployment"

echo "Setup complete. Add the generated SSH key (~/.ssh/id_ed25519.pub) to your GitHub/GitLab deploy keys."
