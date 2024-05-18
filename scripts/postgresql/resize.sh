#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libpostgresql.sh
. /opt/bitnami/scripts/libos.sh

# Load PostgreSQL environment
. /opt/bitnami/scripts/postgresql-env.sh

machine_size="$(get_machine_size "$@")"
ln -sf "bitnami/memory-${machine_size}.conf" "${POSTGRESQL_CONF_DIR}/memory.conf"
