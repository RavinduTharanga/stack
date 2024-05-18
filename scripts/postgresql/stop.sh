#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libpostgresql.sh
. /opt/bitnami/scripts/libos.sh

# Load environment
. /opt/bitnami/scripts/postgresql-env.sh

error_code=0

if is_postgresql_running; then
    BITNAMI_QUIET=1 postgresql_stop
    if ! retry_while "is_postgresql_not_running"; then
        error "postgresql could not be stopped"
        error_code=1
    else
        info "postgresql stopped"
    fi
else
    info "postgresql is not running"
fi

exit "$error_code"
