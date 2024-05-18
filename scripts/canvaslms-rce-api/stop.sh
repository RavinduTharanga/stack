#!/bin/bash

# shellcheck disable=SC1091

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

if canvaslms_is_rce_api_running; then
    canvaslms_rce_api_stop
    if ! retry_while "canvaslms_is_rce_api_not_running"; then
        error "canvas-rce-api could not be stopped"
        error_code=1
    else
        info "canvas-rce-api stopped"
    fi
else
    info "canvas-rce-api is not running"
fi

exit "$error_code"
