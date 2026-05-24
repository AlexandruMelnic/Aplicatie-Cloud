#!/bin/sh
# Inject environment variables into the HTML at container start
# This allows BACKEND_URL to be set per-environment (local, k8s, cloud)

BACKEND_URL=${BACKEND_URL:-"http://localhost:3001"}

# Replace placeholder in index.html and write to nginx root
sed "s|http://localhost:3001|${BACKEND_URL}|g" /usr/share/nginx/html/index.html > /tmp/index_patched.html

# Also inject as window._env_ for dynamic reading
INJECT="<script>window._env_ = { BACKEND_URL: '${BACKEND_URL}' };<\/script>"
sed -i "s|</head>|${INJECT}</head>|" /tmp/index_patched.html

cp /tmp/index_patched.html /usr/share/nginx/html/index.html

# Start nginx
exec nginx -g 'daemon off;'
