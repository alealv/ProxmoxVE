#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.ghostfolio.dev/

# App Default Values
APP="Ghostfolio"
var_tags="media"
var_cpu="4"
var_ram="4096"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core 
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/ghostfolio ]]; then 
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    msg_info "Updating $APP"
    cd /opt/ghostfolio
    output=$(git pull --no-rebase)
    
    if echo "$output" | grep -q "Already up to date."; then
        msg_ok "$APP is already up to date."
        exit
    fi

    systemctl stop ghostfolio
    rm -rf dist .next node_modules
    export NODE_OPTIONS="--max-old-space-size=3072"

    npm install
    node decorate-angular-cli.js
    npm run build:production
    cd /opt/ghostfolio/dist/apps/api
    npm install
    cp /opt/ghostfolio/prisma /opt/ghostfolio/dist/apps/api/prisma
    cp /opt/ghostfolio/package.json /opt/ghostfolio/dist/apps/api
    npm run database:generate-typings

    systemctl daemon-reload
    systemctl start ghostfolio
    msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3333${CL}"