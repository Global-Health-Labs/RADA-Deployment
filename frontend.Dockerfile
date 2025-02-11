# syntax=docker/dockerfile:1.4
FROM node:18-alpine as build

WORKDIR /app

# Add git and openssh
RUN apk add --no-cache git openssh

# Install pnpm
RUN npm install -g pnpm@10.0.0

# Download public key for bitbucket.org
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

# Clone repository using SSH
RUN --mount=type=ssh,id=default git clone --branch main git@bitbucket.org:catchshyam/rada-frontend-ts.git . && git pull origin main

# Copy .env file for build
COPY frontend/.env .env

# Install dependencies and build
RUN pnpm install --no-frozen-lockfile
RUN pnpm build

# Production stage
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=build /app/dist /usr/share/nginx/html

# Copy env.sh script
COPY frontend/env.sh /docker-entrypoint.d/40-env.sh
RUN chmod +x /docker-entrypoint.d/40-env.sh

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
