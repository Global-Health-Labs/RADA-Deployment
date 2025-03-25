# RADA Application Deployment Guide

This document outlines the hosting architecture and deployment process for the RADA application.

## 1. Hosting Architecture

The RADA application follows a modern three-tier architecture with the following components:

```ascii
                          ┌─────────────────┐
                          │                 │
                          │  User Browser   │
                          │                 │
                          └────────┬────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │                 │
                          │   AWS Lightsail │
                          │                 │
                          └────────┬────────┘
                                   │
                 ┌─────────────────┴─────────────────┐
                 │                                   │
        ┌────────▼───────┐                 ┌─────────▼────────┐
        │                │                 │                  │
        │  Frontend      │◄───────────────►│  Backend         │
        │  (React + Nginx)│                 │  (Node.js)       │
        │                │                 │                  │
        └────────────────┘                 └─────────┬────────┘
                                                     │
                                                     │
                                           ┌─────────▼────────┐
                                           │                  │
                                           │  Amazon RDS      │
                                           │  (PostgreSQL)    │
                                           │                  │
                                           └──────────────────┘
```

<div style="page-break-after: always;"></div>

### Database Tier

- **Amazon RDS**: Hosts the application database
- Supports SSL encryption for secure connections
- The backend connects to RDS using environment variables defined in `backend/.env`

### Application Tier

- **AWS Lightsail**: Hosts both the backend and frontend services
- **Docker**: Containerizes the application components for consistent deployment
- **Docker Compose**: Orchestrates the multi-container application

### Backend Service

- **Node.js**: Runtime environment (Node 18)
- **Python**: Used for specific functionality via a virtual environment
- Exposes ports:
  - 8080: HTTP API
  - 8443: HTTPS API (when SSL is enabled)
- Clones code from the `catchshyam/rada-backend` repository
- Configured via environment variables in `backend/.env`

### Frontend Service

- **ReactJS**: Used for building the frontend (v 18)
- **Nginx**: Serves the static frontend assets and acts as a reverse proxy
- **Vite**: Used as the build tool for the frontend
- Clones code from the `catchshyam/rada-frontend-ts` repository
- Exposes ports:
  - 80: HTTP (redirects to HTTPS)
  - 443: HTTPS

### Networking

- **Nginx**: Handles SSL termination and routes traffic:
  - Frontend requests served directly from `/usr/share/nginx/html`
  - API requests (`/api/*`) proxied to the backend service
- **SSL/TLS**: Managed by Certbot with auto-renewal
- Custom Docker network (`rada-network`) for inter-service communication

<div style="page-break-after: always;"></div>

## 2. Deployment Process

### 2.1 Initial Server Setup

To prepare a new AWS Lightsail instance running Amazon Linux 2023:

1. Connect to your AWS Lightsail instance via SSH and install Git:
   ```bash
   sudo dnf install -y git
   ```
2. Clone the deployment repository:
   ```bash
   git clone git@bitbucket.org:catchshyam/rada-deployment.git
   cd rada-deployment
   ```
3. Run the initialization script:
   ```bash
   sudo chmod +x scripts/init-amazon-linux-2023.sh
   sudo ./scripts/init-amazon-linux-2023.sh
   ```

This script will:

- Update the system packages
- Install Docker and Git
- Configure Docker to start on boot
- Add your user to the Docker group
- Install Docker Compose
- Generate an SSH key for repository access

4. Add the generated SSH key to your Bitbucket repository deploy keys:

   - The public key is located at `~/.ssh/id_ed25519.pub`
   - Add this key to the Bitbucket repository settings for both frontend and backend repositories

5. Log out and log back in for the Docker group permissions to take effect

<div style="page-break-after: always;"></div>

### 2.2 Environment Configuration

1. Create the main deployment environment file:

   ```bash
   cp .env.template .env
   ```

2. Edit the `.env` file to set your domain name:

   ```makefile
   DOMAIN_NAME=your-domain.com
   ```

3. Create the backend environment file:

   ```bash
   mkdir -p backend
   cp /path/to/rada-backend/.env.template backend/.env
   ```

4. Configure the backend environment variables in `backend/.env`, including:

   - Database connection details (host, port, username, password)
   - SSL settings
   - Other application-specific settings

   The backend `.env.template` contains all required variables:

   ```properties
   # Database
   DATABASE_URL=postgresql://postgres:root@localhost:5432/ghl_rada
   DB_USE_SSL=false

   # JWT
   JWT_SECRET_KEY="jgkYVR&^%&^RIYTFHjgfdjfjdj"
   JWT_ACCESS_TOKEN_EXPIRES=1d

   # AWS
   AWS_ACCESS_KEY_ID=XXXXX
   AWS_SECRET_ACCESS_KEY=XXXXX
   AWS_REGION=us-east-2
   DOCUMENTS_BUCKET_NAME=XXXXX

   # Domain Configuration
   DOMAIN_NAME=localhost
   DOMAIN_PORT=8080
   CLOUDFRONT_DOMAIN_NAME=your.cloudfront.domain

   # SMTP Configuration
   SMTP_HOST=mail.example.com
   SMTP_PORT=465
   SMTP_SECURE=true
   SMTP_USER=hello@ghl.com
   SMTP_PASS=XXXX
   SMTP_FROM="RADA <noreply@appzoy.com>"

   # Frontend URL (for email links)
   FRONTEND_URL=http://localhost:5173
   ```

5. Create the frontend environment file:

   ```bash
   mkdir -p frontend
   cp /path/to/rada-frontend-vite/.env.template frontend/.env
   ```

   The frontend `.env.template` is simple and contains:

   ```properties
   VITE_BACKEND_URL=http://localhost:8080
   ```

   For production deployment, this will be automatically set to `https://${DOMAIN_NAME}/api` by the deployment script.

6. If using SSL for the database connection (DB_USE_SSL=true), add the SSL certificate:
   ```bash
   # Copy your RDS SSL certificate to the backend directory
   cp your-certificate.pem backend/db-ssl-certificate.pem
   ```

### 2.3 SSL Certificate Setup

1. Run the SSL setup script:
   ```bash
   sudo chmod +x scripts/setup-ssl.sh
   sudo ./scripts/setup-ssl.sh
   ```

This script will:

- Install Certbot and its dependencies
- Stop any running containers to free up ports 80 and 443
- Obtain an SSL certificate for your domain
- Configure automatic certificate renewal
- Restart the application containers

<div style="page-break-after: always;"></div>

### 2.4 Application Deployment

To deploy or update the application:

1. Run the deployment script:
   ```bash
   chmod +x scripts/deploy.sh
   ./scripts/deploy.sh
   ```

This script will:

- Verify the required environment files exist
- Set up the necessary directory structure
- Create runtime environment configuration scripts
- Pull the latest code changes
- Stop existing containers
- Build new Docker images for both frontend and backend
- Start the updated containers
- Clean up unused Docker resources

## 3. Updating the Application

To update the application to the latest version:

1. Connect to your AWS Lightsail instance via SSH
2. Navigate to the deployment directory:
   ```bash
   cd rada-deployment
   ```
3. Run the deployment script:
   ```bash
   ./scripts/deploy.sh
   ```

The script will:

- Pull the latest code from the repositories
- Rebuild the Docker containers with the updated code
- Restart the services with minimal downtime
- Clean up old Docker images to save disk space

<div style="page-break-after: always;"></div>

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**:

   - Check certificate status: `sudo certbot certificates`
   - Renew certificates manually: `sudo certbot renew --dry-run`

2. **Docker Connectivity Issues**:

   - Check Docker service: `sudo systemctl status docker`
   - Restart Docker: `sudo systemctl restart docker`

3. **Application Not Responding**:

   - Check container status: `docker-compose ps`
   - View container logs: `docker-compose logs -f backend` or `docker-compose logs -f frontend`

4. **Database Connection Issues**:
   - Verify RDS security group allows connections from your Lightsail instance
   - Check SSL certificate if DB_USE_SSL=true
   - Verify database credentials in backend/.env

### Health Checks

The application includes health checks for both services:

- Backend: `http://localhost:8080/health`
- Frontend: `http://localhost:80/`

You can monitor the health status with:

```bash
docker-compose ps
```
