#!/bin/sh

# Replace environment variables in nginx config
envsubst '${NGINX_DOMAIN}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Test nginx configuration
nginx -t

# Start nginx
nginx -g 'daemon off;'
