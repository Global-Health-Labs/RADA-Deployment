# syntax=docker/dockerfile:1.4
FROM node:18-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache git openssh wget python3 py3-pip python3-venv

# Install pnpm
RUN npm install -g pnpm@10.0.0

# Download public key for bitbucket.org
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

# Clone repository using SSH
RUN --mount=type=ssh,id=default git clone --branch main git@bitbucket.org:catchshyam/rada-backend.git . && git pull origin main

# Setup Python virtual environment and install dependencies
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"
RUN . /app/venv/bin/activate && \
    pip install --no-cache-dir -r resources/lfa-py/requirements.txt

# Create empty .env and SSL cert file if not copied
RUN touch .env && touch db-ssl-certificate.pem

# Copy environment variables and SSL certificate if they exist
COPY --chmod=600 .env* .env || true
COPY --chmod=600 db-ssl-certificate.pem db-ssl-certificate.pem || true

# Set proper permissions for SSL certificate
RUN chmod 600 db-ssl-certificate.pem

# Install Node.js dependencies and build
RUN pnpm install --no-frozen-lockfile
RUN pnpm build

EXPOSE 8080 8443
# Ensure we activate the venv in the CMD
CMD ["sh", "-c", ". /app/venv/bin/activate && pnpm start"]
