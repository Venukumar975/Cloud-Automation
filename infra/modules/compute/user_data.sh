#!/bin/bash
apt-get update -y
apt-get install -y nginx

# Listen on the application port instead of 80
sed -i "s/listen 80 default_server;/listen ${app_port} default_server;/g" /etc/nginx/sites-enabled/default
sed -i "s/listen \[::\]:80 default_server;/listen \[::\]:${app_port} default_server;/g" /etc/nginx/sites-enabled/default

echo "Hello from ${project_name} Compute Module" > /var/www/html/index.html

systemctl restart nginx
systemctl enable nginx
