# syntax=docker/dockerfile:1.4
FROM node:18-alpine

WORKDIR /app

# Add git and openssh
RUN apk add --no-cache git openssh

# Download public key for bitbucket.org
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

# Clone repository using SSH
RUN --mount=type=ssh,id=default git clone --branch main git@bitbucket.org:catchshyam/rada-backend.git .

# Install dependencies and build
RUN npm install
RUN npm run build

# Start the application
CMD ["npm", "start"]
