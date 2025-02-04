#!/bin/bash

# Update the system
sudo dnf update -y

# Install Docker and Git
sudo dnf install -y docker git

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose v2 manually
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker compose version

# Generate SSH key for private repositories (if needed)
ssh-keygen -t ed25519 -C "ec2-deployment"

echo "Setup complete. Add the generated SSH key (~/.ssh/id_ed25519.pub) to your GitHub/GitLab deploy keys."
echo "Installation complete! Please log out and log back in for the group changes to take effect."
echo "After logging back in, run: docker info to verify the installation."
