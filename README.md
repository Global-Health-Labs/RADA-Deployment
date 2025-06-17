# RADA Deployment

## Environment Setup

1. Copy the environment template to create your deployment-specific .env file:

   ```bash
   cp .env.template .env
   ```

2. Edit the .env file with your deployment-specific values:

   ```bash
   # For staging
   DOMAIN_NAME=rada.ghlab.it

   # For production
   DOMAIN_NAME=rada.ghlab.it
   ```

3. Run docker-compose:
   ```bash
   docker-compose up -d
   ```

The .env file is gitignored to prevent committing environment-specific values. Each deployment environment should maintain its own .env file.
