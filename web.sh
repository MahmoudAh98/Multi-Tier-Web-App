#!/bin/bash
echo "ok" > /tmp/test.txt
apt update -y
apt install nginx -y

systemctl enable nginx
systemctl start nginx

echo "This is an app server in AWS Region US-EAST-2" > /var/www/html/index.html