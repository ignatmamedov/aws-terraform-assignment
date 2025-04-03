#!/bin/bash
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

docker login registry.gitlab.com -u "${dt_username}" -p "${dt_password}"

docker run -d \
  -e DB_CONNECTION=pgsql \
  -e DB_HOST=${db_host} \
  -e DB_PORT=${db_port} \
  -e DB_DATABASE=${db_name} \
  -e DB_USERNAME=${db_user} \
  -e DB_PASSWORD=${db_password} \
  -e APP_DEBUG=true \
  -e APP_KEY=${app_key} \
  -e APP_NAME=${app_name} \
  -p 80:80 \
  ${container_url} \
  bash -lc "php artisan migrate --force & apache2-foreground"
