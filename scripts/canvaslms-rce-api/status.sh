#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Canvas LMS environment
. /opt/bitnami/scripts/canvaslms-env.sh

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libcanvaslms.sh

if canvaslms_is_rce_api_running; then
    info "canvas-rce-api is already running"
else
    info "canvas-rce-api is not running"
fi
