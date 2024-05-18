#!/bin/bash

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Canvas LMS environment
. /opt/bitnami/scripts/canvaslms-env.sh

# Load libraries
. /opt/bitnami/scripts/libcanvaslms.sh
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/liblog.sh

# Enable configuration files
# Based on https://github.com/instructure/canvas-lms/wiki/Production-Start#canvas-default-configuration
# and https://github.com/instructure/canvas-lms/wiki/Production-Start#redis
# and https://github.com/instructure/canvas-rce-api/blob/master/README.md#canvas
for config in amazon_s3 database delayed_jobs domain file_store outgoing_mail security external_migration cache_store redis dynamic_settings; do
    if [[ ! -f "${CANVASLMS_CONF_DIR}/${config}.yml" ]]; then
        cp "${CANVASLMS_CONF_DIR}/${config}.yml.example" "${CANVASLMS_BASE_DIR}/config/${config}.yml"
    fi
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#making-sure-other-users-cant-read-private-canvas-files
    chmod o-rwx "${CANVASLMS_BASE_DIR}/config/${config}.yml"
done

# Ensure the Canvas LMS base directory exists and has proper permissions
info "Configuring file permissions for Canvas LMS"
ensure_user_exists "$CANVASLMS_DAEMON_USER" --group "$CANVASLMS_DAEMON_GROUP"
declare -a writable_dirs=(
    # Folders that need to be writable for the app to work
    # Skipping CANVASLMS_BASE_DIR intentionally because it contains a lot of files/folders that should not be writable
    "${CANVASLMS_BASE_DIR}/log"
    "${CANVASLMS_BASE_DIR}/tmp"
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#generate-assets
    "${CANVASLMS_BASE_DIR}/public/dist/brandable_css"
    # Canvas RCE API folders
    "${CANVASLMS_RCE_API_DIR}/tmp"
    "${CANVASLMS_RCE_API_DIR}/log"
)
for dir in "${writable_dirs[@]}"; do
    ensure_dir_exists "$dir"
    # Use daemon:root ownership for compatibility when running as a non-root user
    configure_permissions_ownership "$dir" -d "775" -f "664" -u "$CANVASLMS_DAEMON_USER" -g "root"
done

# Load additional libraries
# shellcheck disable=SC1090,SC1091
. /opt/bitnami/scripts/libservice.sh
. /opt/bitnami/scripts/libwebserver.sh

# Load web server environment for web_server_* functions
. "/opt/bitnami/scripts/$(web_server_type)-env.sh"

# Enable extra service management configuration
# Disable Canvas RCE API by default, users can enable it following our documentation
info "Configuring extra services"
if [[ "$BITNAMI_SERVICE_MANAGER" = "monit" ]]; then
    generate_monit_conf "canvaslms-delayed-jobs" "$CANVASLMS_DELAYED_JOBS_PID_FILE" /opt/bitnami/scripts/canvaslms-delayed-jobs/start.sh /opt/bitnami/scripts/canvaslms-delayed-jobs/stop.sh
    generate_monit_conf "canvaslms-rce-api" "$CANVASLMS_RCE_API_PID_FILE" /opt/bitnami/scripts/canvaslms-rce-api/start.sh /opt/bitnami/scripts/canvaslms-rce-api/stop.sh --disable
elif [[ "$BITNAMI_SERVICE_MANAGER" = "systemd" ]]; then
    generate_systemd_conf "canvaslms-delayed-jobs" \
        --name "CanvasLMS delayed_job Worker" \
        --user "$CANVASLMS_DAEMON_USER" \
        --group "$CANVASLMS_DAEMON_GROUP" \
        --environment "RAILS_ENV=production" \
        --working-directory "$CANVASLMS_BASE_DIR" \
        --exec-start "${BITNAMI_ROOT_DIR}/ruby/bin/bundle exec script/delayed_job start" \
        --pid-file "$CANVASLMS_DELAYED_JOBS_PID_FILE"
    # Use 'simple' type to start service in foreground and consider started while it is running
    generate_systemd_conf "canvaslms-rce-api" \
        --name "Canvas RCE API Server" \
        --type "simple" \
        --user "$CANVASLMS_DAEMON_USER" \
        --group "$CANVASLMS_DAEMON_GROUP" \
        --working-directory "$CANVASLMS_RCE_API_DIR" \
        --exec-start "${BITNAMI_ROOT_DIR}/node/bin/node app.js"
else
    error "Unsupported service manager ${BITNAMI_SERVICE_MANAGER}"
    exit 1
fi
# 'su' option used to avoid: "error: skipping (...) because parent directory has insecure permissions (It's world writable or writable by group which is not "root")"
generate_logrotate_conf "canvaslms" "${CANVASLMS_BASE_DIR}/log/*log" --extra "su ${CANVASLMS_DAEMON_USER} ${CANVASLMS_DAEMON_GROUP}"
generate_logrotate_conf "canvaslms-rce-api" "${CANVASLMS_RCE_API_DIR}/log/*log"

# Enable default web server configuration for Canvas LMS
info "Creating default web server configuration for Canvas LMS"
web_server_validate
ensure_web_server_app_configuration_exists "canvaslms" \
    --type ruby-passenger \
    --document-root "${CANVASLMS_BASE_DIR}/public" \
    --apache-additional-configuration "RailsEnv ${CANVASLMS_ENV}
# Fixes errors caused by Passenger not loading gems from Bundler, e.g.:
# 'You have already activated strscan 3.0.1, but your Gemfile requires strscan 3.0.6. (...)'
SetEnv RUBYOPT \"-r bundler/setup\"" \
    --apache-before-vhost-configuration "PassengerStartTimeout 240" # Avoid "A timeout occurred while starting a preloader process." errors
# Support Canvas RCE API via a custom vhost/server block (supposing it is running in the same server)
# Unfortunately it doesn't yet support hosting in a sub-path, see: https://github.com/instructure/canvas-rce-api/pull/5
ensure_web_server_app_configuration_exists "canvas-rce-api" \
    --type proxy \
    --server-name "$CANVASLMS_RCE_API_HOST" \
    --server-aliases "www.${CANVASLMS_RCE_API_HOST}" \
    --apache-proxy-address "http://127.0.0.1:${CANVASLMS_RCE_API_PORT_NUMBER}/" \
    --disable

# Grant ownership to the default "bitnami" SSH user to edit files, and restrict permissions for the web server
info "Granting Canvas LMS files ownership to the 'bitnami' user"
configure_permissions_ownership "$CANVASLMS_BASE_DIR" -u "bitnami" -g "$CANVASLMS_DAEMON_GROUP"
