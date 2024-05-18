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

error_code=0

if canvaslms_is_rce_api_not_running; then
    BITNAMI_QUIET=1 nohup /opt/bitnami/scripts/canvaslms-rce-api/run.sh >>"$CANVASLMS_RCE_API_LOG_FILE" 2>&1 &
    echo "$!" > "$CANVASLMS_RCE_API_PID_FILE"
    if ! retry_while "canvaslms_is_rce_api_running"; then
        error "canvas-rce-api did not start"
        error_code=1
    else
        info "canvas-rce-api started"
    fi
else
    info "canvas-rce-api is already running"
fi

exit "$error_code"
