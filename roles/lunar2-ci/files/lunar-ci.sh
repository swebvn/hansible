#!/bin/bash

# Lunar CI deployment script
# Manages SSH keys and domain configurations for deployment user

set -euo pipefail

# Constants
DEPLOY_KEY="/root/.ssh/deploy_rsa.pem"
DEPLOY_USER="deploy"
USER_HOME="/home/${DEPLOY_USER}"
SSH_DIR="${USER_HOME}/.ssh"
USER_DEPLOY_KEY="${SSH_DIR}/deploy_rsa.pem"

# Setup SSH directory and permissions
setup_ssh_dir() {
    if [ ! -d "${SSH_DIR}" ]; then
        mkdir -p "${SSH_DIR}"
        chown "${DEPLOY_USER}:${DEPLOY_USER}" "${SSH_DIR}"
        chmod 700 "${SSH_DIR}"
    fi
}

# Copy and configure deploy key
setup_deploy_key() {
    if [ ! -f "${USER_DEPLOY_KEY}" ]; then
        cp "${DEPLOY_KEY}" "${USER_DEPLOY_KEY}"
        chown "${DEPLOY_USER}:${DEPLOY_USER}" "${USER_DEPLOY_KEY}"
        chmod 600 "${USER_DEPLOY_KEY}"
    fi
}

# Run deploy script
deploy_code() {
    WEBSITE_DIR=$(find /home/deploy/ -maxdepth 1 -type d -name "*.tdalunar.com" | head -n 1)
    if [ ! -d "${WEBSITE_DIR}" ]; then
        echo "Website directory not found."
        exit 1
    fi

    DOMAIN=$(basename "${WEBSITE_DIR}")

    su - "${DEPLOY_USER}" -c "
        cd ${WEBSITE_DIR}
        GIT_SSH_COMMAND='ssh -i ${USER_DEPLOY_KEY}' git pull origin 2.x

        if [ -f pnpm-lock.yaml ]; then
            git checkout pnpm-lock.yaml
        fi

        if [ -f composer.lock ]; then
            git checkout composer.lock
        fi

        composer install --no-dev --optimize-autoloader --no-ansi --no-interaction

        CI=1 pnpm install && pnpm run build
        php artisan optimize
        php artisan route:clear
        php artisan filament:cache-components
        php artisan icons:cache
        php artisan horizon:terminate

        echo 'Deployment complete.'
    "

    systemctl reload php8.2-fpm

    curl -s --location 'https://ping2.me/@daudau/sweb-stuff' --data-urlencode "message=$DOMAIN deployed!" > /dev/null
}

main() {
    setup_ssh_dir
    setup_deploy_key
    deploy_code
}

main