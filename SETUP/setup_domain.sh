#!/bin/bash

# Usage: ./setup_domain.sh rstudio.timosachs.de

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 domain.name"
    exit 1
fi

DOMAIN="$1"

# Check if running from SETUP directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJ_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ "$(basename "$SCRIPT_DIR")" != "SETUP" ]]; then
    echo "Warning: This script should be run from within the SETUP directory."
    echo "Current directory: $(pwd)"
    echo "Script directory: $SCRIPT_DIR"
fi

echo "Project root directory: $PROJ_ROOT"
echo "Data directory: $PROJ_ROOT/DATA"
echo "Source directory: $PROJ_ROOT/SRC"

# Install Nginx if not already installed
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Configure Nginx to proxy RStudio and Shiny
cat > /etc/nginx/sites-available/$DOMAIN <<EOF
# WebSocket support
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    server_name $DOMAIN;

    # RStudio Server at root
    location / {
        proxy_pass http://localhost:8787;
        proxy_redirect http://localhost:8787/ \$scheme://$DOMAIN/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }

    # Shiny Server at /shiny
    location /shiny/ {
        proxy_pass http://localhost:3838/;
        proxy_redirect http://localhost:3838/ \$scheme://$DOMAIN/shiny/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 20d;
        proxy_buffering off;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Test Nginx config
nginx -t

# Restart Nginx
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d $DOMAIN

echo "Setup complete! Your domain is configured at: https://$DOMAIN"
echo "RStudio Server: https://$DOMAIN"
echo "Shiny Server: https://$DOMAIN/shiny/"
echo "Project directories:"
echo "- DATA: $PROJ_ROOT/DATA"
echo "- SRC: $PROJ_ROOT/SRC"