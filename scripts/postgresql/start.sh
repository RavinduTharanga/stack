#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libpostgresql.sh

# Load PostgreSQL environment variables
. /opt/bitnami/scripts/postgresql-env.sh

error_code=0

if is_postgresql_not_running; then
    nohup /opt/bitnami/scripts/postgresql/run.sh >/dev/null 2>&1 &
    if ! retry_while "is_postgresql_running"; then
        error "postgresql did not start"
        error_code=1
    else
        info "postgresql started"
    fi
else
    info "postgresql is already running"
fi

exit "$error_code"
