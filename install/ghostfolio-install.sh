#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y g++
$STD apt-get install -y git
$STD apt-get install -y make
$STD apt-get install -y openssl
$STD apt-get install -y python3
$STD apt-get install -y curl
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing Ghostfolio (Patience)"
git clone -q https://github.com/ghostfolio/ghostfolio.git /opt/ghostfolio
cd /opt/ghostfolio
$STD git checkout main
export NODE_OPTIONS="--max-old-space-size=3072"


$STD npm install
$STD node decorate-angular-cli.js
$STD npm run build:production
$STD cd /opt/ghostfolio/dist/apps/api
$STD npm install
$STD cp /opt/ghostfolio/prisma /opt/ghostfolio/dist/apps/api/prisma
$STD cp /opt/ghostfolio/package.json /opt/ghostfolio/dist/apps/api
$STD npm run database:generate-typings

mkdir -p /etc/ghostfolio/
cat <<EOF >/etc/ghostfolio/ghostfolio.conf
PORT=3333
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?connect_timeout=300&sslmode=prefer
REDIS_HOST=redis
REDIS_PASSWORD=${REDIS_PASSWORD}
EOF
msg_ok "Installed Ghostfolio"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ghostfolio.service
[Unit]
Description=ghostfolio Service
After=network.target

[Service]
EnvironmentFile=/etc/ghostfolio/ghostfolio.conf
Environment=NODE_ENV=production
Restart=on-failure
Type=exec
WorkingDirectory=/opt/ghostfolio
ExecStart=/bin/bash /opt/ghostfolio/ghostfolio/docker/entrypoint.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ghostfolio.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
