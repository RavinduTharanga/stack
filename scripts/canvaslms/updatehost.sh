#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load Canvas LMS environment
. /opt/bitnami/scripts/canvaslms-env.sh

# Load libraries
. /opt/bitnami/scripts/libcanvaslms.sh

CANVASLMS_SERVER_HOST="${1:?missing host}"

info "Updating hostname in Canvas LMS configuration"
canvaslms_conf_set "domain" "production.domain" "$CANVASLMS_SERVER_HOST"
