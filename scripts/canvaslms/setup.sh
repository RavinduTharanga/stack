#!/bin/bash

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Canvas LMS environment
. /opt/bitnami/scripts/canvaslms-env.sh

# Load PostgreSQL Client environment for 'postgresql_remote_execute' (after 'canvaslms-env.sh' so that MODULE is not set to a wrong value)
if [[ -f /opt/bitnami/scripts/postgresql-client-env.sh ]]; then
    . /opt/bitnami/scripts/postgresql-client-env.sh
elif [[ -f /opt/bitnami/scripts/postgresql-env.sh ]]; then
    . /opt/bitnami/scripts/postgresql-env.sh
fi

# Load libraries
. /opt/bitnami/scripts/libcanvaslms.sh

# Load additional libraries
# shellcheck disable=SC1090,SC1091
. /opt/bitnami/scripts/libwebserver.sh

# Load web server environment for web_server_* functions
. "/opt/bitnami/scripts/$(web_server_type)-env.sh"

# Generate a random set of keys for Canvas RCE API
# Note: They must be 32-bit or the application will throw HTTP 500 errors when accessing places like 'Admin > Settings'
CANVASLMS_RCE_API_ENCRYPTION_SECRET="${CANVASLMS_RCE_API_ENCRYPTION_SECRET:-"$(generate_random_string -t alphanumeric -c 32)"}"
CANVASLMS_RCE_API_SIGNING_SECRET="${CANVASLMS_RCE_API_SIGNING_SECRET:-"$(generate_random_string -t alphanumeric -c 32)"}"

# Ensure Canvas LMS environment variables are valid
canvaslms_validate

# Ensure Canvas LMS is initialized
canvaslms_initialize

# Update web server configuration with runtime environment
web_server_update_app_configuration "canvaslms"
if [[ "$(web_server_type)" = "apache" ]]; then
    for vhost_file in "${APACHE_VHOSTS_DIR}/canvaslms"*; do
        replace_in_file "$vhost_file" "RailsEnv .*" "RailsEnv ${CANVASLMS_ENV}"
    done
fi

# Configure Canvas RCE API
# https://github.com/instructure/canvas-rce-api#configuration
# Note: HTTP_PROTOCOL_OVERRIDE is supported but undocumented - https://github.com/instructure/canvas-rce-api/blob/master/app/api/wrapCanvas.js#L22
info "Configuring Canvas RCE API"
cat >"${CANVASLMS_RCE_API_DIR}/.env" <<EOF
ECOSYSTEM_KEY=${CANVASLMS_RCE_API_ENCRYPTION_SECRET}
ECOSYSTEM_SECRET=${CANVASLMS_RCE_API_SIGNING_SECRET}
FLICKR_API_KEY=
UNSPLASH_APP_ID=
UNSPLASH_SECRET=
UNSPLASH_APP_NAME=
YOUTUBE_API_KEY=
NODE_ENV=${CANVASLMS_ENV}
PORT=${CANVASLMS_RCE_API_PORT_NUMBER}
# The statsd server configuration fields are required even if no server will be used
STATSD_HOST=127.0.0.1
STATSD_PORT=8125
# Fix protocol for RCE API server requests to Canvas LMS /api
HTTP_PROTOCOL_OVERRIDE=$(is_boolean_yes "$CANVASLMS_ENABLE_HTTPS" && echo "https" || echo "http")
EOF
