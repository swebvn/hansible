#!/bin/bash

# Lunar CI Zero-Downtime Deployment Script
# Uses symlink-based atomic releases for zero-downtime deployments

set -euo pipefail

# Constants
DEPLOY_KEY="/root/.ssh/deploy_rsa.pem"
DEPLOY_USER="deploy"
USER_HOME="/home/${DEPLOY_USER}"
SSH_DIR="${USER_HOME}/.ssh"
USER_DEPLOY_KEY="${SSH_DIR}/deploy_rsa.pem"

# Release management
RELEASES_DIR="${USER_HOME}/releases"
SHARED_DIR="${USER_HOME}/shared"
CURRENT_LINK="${USER_HOME}/current"
KEEP_RELEASES=5
REPO_URL="git@github.com:swebvn/lucommerce.git"
BRANCH="main"

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

# Get domain from current release
get_domain() {
    if [ -L "${CURRENT_LINK}" ] && [ -f "${SHARED_DIR}/.env" ]; then
        grep "^APP_URL=" "${SHARED_DIR}/.env" | cut -d'/' -f3 | cut -d':' -f1
    else
        hostname
    fi
}

# Create release directory structure
create_release_dir() {
    RELEASE_NAME=$(date +%Y%m%d-%H%M%S)
    RELEASE_DIR="${RELEASES_DIR}/${RELEASE_NAME}"

    echo "Creating release: ${RELEASE_NAME}" >&2
    mkdir -p "${RELEASE_DIR}"
    chown "${DEPLOY_USER}:${DEPLOY_USER}" "${RELEASE_DIR}"

    echo "${RELEASE_DIR}"
}

# Clone repository to release directory
clone_release() {
    local release_dir=$1

    echo "Cloning repository to ${release_dir}..."
    su - "${DEPLOY_USER}" -c "
        export GIT_SSH_COMMAND='ssh -i ${USER_DEPLOY_KEY} -o StrictHostKeyChecking=no'
        git clone --depth 1 --branch ${BRANCH} ${REPO_URL} ${release_dir}
    "
}

# Link shared directories to release
link_shared() {
    local release_dir=$1

    echo "Linking shared directories..."

    # Remove existing directories/files that will be symlinked
    rm -rf "${release_dir}/.env"
    rm -rf "${release_dir}/storage"
    rm -rf "${release_dir}/database"

    # Create symlinks to shared directories
    ln -s "${SHARED_DIR}/.env" "${release_dir}/.env"
    ln -s "${SHARED_DIR}/storage" "${release_dir}/storage"
    ln -s "${SHARED_DIR}/database" "${release_dir}/database"

    # Create public/storage symlink for Laravel's storage:link
    rm -rf "${release_dir}/public/storage"
    ln -s "${SHARED_DIR}/storage/app/public" "${release_dir}/public/storage"

    chown -h "${DEPLOY_USER}:${DEPLOY_USER}" "${release_dir}/.env"
    chown -h "${DEPLOY_USER}:${DEPLOY_USER}" "${release_dir}/storage"
    chown -h "${DEPLOY_USER}:${DEPLOY_USER}" "${release_dir}/database"
    chown -h "${DEPLOY_USER}:${DEPLOY_USER}" "${release_dir}/public/storage"
}

# Install dependencies and build assets
build_release() {
    local release_dir=$1

    echo "Building release..."
    su - "${DEPLOY_USER}" -c "
        cd ${release_dir}

        # Always install composer dependencies for new release
        composer install --no-dev --optimize-autoloader --no-ansi --no-interaction

        # Always build frontend assets
        CI=1 pnpm install && pnpm run build
    "
}

# Run database migrations (before symlink switch)
run_migrations() {
    local release_dir=$1

    echo "Running database migrations..."
    su - "${DEPLOY_USER}" -c "
        cd ${release_dir}
        php artisan hub:migrate
        php artisan tenants:migrate --force
    "
}

# Warm up caches in new release (views cached after PHP-FPM reload to avoid race condition)
warmup_caches() {
    local release_dir=$1

    echo "Warming up caches..."
    su - "${DEPLOY_USER}" -c "
        cd ${release_dir}
        php artisan config:cache
        php artisan event:cache
        php artisan filament:cache-components
        php artisan icons:cache
    "
}

# Atomic symlink switch
switch_release() {
    local release_dir=$1

    echo "Switching to new release (atomic)..."
    # ln -sfn is atomic on Linux - replaces symlink in single operation
    ln -sfn "${release_dir}" "${CURRENT_LINK}"
    chown -h "${DEPLOY_USER}:${DEPLOY_USER}" "${CURRENT_LINK}"
}

# Reload services gracefully
reload_services() {
    echo "Reloading services gracefully..."


    # Clear caches after PHP-FPM reload
    su - "${DEPLOY_USER}" -c "
        cd ${CURRENT_LINK}
        php artisan responsecache:clear
        php artisan view:cache
        php artisan route:clear
        php artisan horizon:terminate
    "

    # Graceful PHP-FPM reload (workers finish current requests)
    systemctl restart php8.2-fpm

    echo "Services reloaded."
}

# Cleanup old releases, keep only KEEP_RELEASES
cleanup_old_releases() {
    echo "Cleaning up old releases (keeping ${KEEP_RELEASES})..."

    cd "${RELEASES_DIR}"
    # List releases sorted by date (oldest first), skip the newest KEEP_RELEASES
    local releases_to_delete=$(ls -1t | tail -n +$((KEEP_RELEASES + 1)))

    if [ -n "${releases_to_delete}" ]; then
        echo "Removing old releases: ${releases_to_delete}"
        echo "${releases_to_delete}" | xargs -I {} rm -rf "${RELEASES_DIR}/{}"
    else
        echo "No old releases to remove."
    fi
}

# Send deployment notification
send_notification() {
    local domain=$1
    local status=$2

    curl -s --location 'https://ping2.me/@daudau/sweb-stuff' \
        --data-urlencode "message=${domain} ${status}!" > /dev/null || true
}

# Rollback to previous release
rollback() {
    echo "Rolling back to previous release..."

    cd "${RELEASES_DIR}"
    local previous_release=$(ls -1t | sed -n '2p')

    if [ -z "${previous_release}" ]; then
        echo "ERROR: No previous release found to rollback to!"
        exit 1
    fi

    echo "Rolling back to: ${previous_release}"
    ln -sfn "${RELEASES_DIR}/${previous_release}" "${CURRENT_LINK}"

    systemctl reload php8.2-fpm

    su - "${DEPLOY_USER}" -c "
        cd ${CURRENT_LINK}
        php artisan horizon:terminate
    "

    echo "Rollback complete!"
}

# Main deployment function
deploy() {
    local domain=$(get_domain)
    echo "Starting zero-downtime deployment for ${domain}..."

    # Verify shared directory exists
    if [ ! -d "${SHARED_DIR}" ]; then
        echo "ERROR: Shared directory not found. Run migration playbook first."
        exit 1
    fi

    # Create new release
    local release_dir=$(create_release_dir)

    # Clone code to new release
    clone_release "${release_dir}"

    # Link shared directories
    link_shared "${release_dir}"

    # Build release (composer, pnpm)
    build_release "${release_dir}"

    # Run migrations BEFORE switch (backward-compatible migrations only!)
    run_migrations "${release_dir}"

    # Warm up caches
    warmup_caches "${release_dir}"

    # Atomic switch to new release
    switch_release "${release_dir}"

    # Reload services gracefully
    reload_services

    # Cleanup old releases
    cleanup_old_releases

    # Send success notification
    send_notification "${domain}" "deployed"

    echo "✅ Zero-downtime deployment complete!"
}

# Main entry point
main() {
    setup_ssh_dir
    setup_deploy_key

    # Check for rollback flag
    if [ "${1:-}" = "--rollback" ]; then
        rollback
    else
        deploy
    fi
}

main "$@"