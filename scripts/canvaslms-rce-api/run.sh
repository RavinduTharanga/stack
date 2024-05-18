#!/bin/bash

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Canvas LMS environment
. /opt/bitnami/scripts/canvaslms-env.sh

# Load libraries
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libcanvaslms.sh

info "** Starting canvas-rce-api **"
cd "$CANVASLMS_RCE_API_DIR"
if am_i_root; then
    exec_as_user "$CANVASLMS_DAEMON_USER" node app.js "$@"
else
    exec node app.js "$@"
fi
