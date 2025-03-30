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
  -p 80:8000 \
  registry.gitlab.com/saxionnl/hbo-ict/2.2-project-client-on-board/or1on/or1on-server:latest
