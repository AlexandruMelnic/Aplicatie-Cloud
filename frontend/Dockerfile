FROM nginx:alpine

# Copy static files
COPY index.html /usr/share/nginx/html/index.html

# Nginx config to allow env injection and SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Script to inject BACKEND_URL at runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
