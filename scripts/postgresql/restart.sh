#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libpostgresql.sh

# Load environment
. /opt/bitnami/scripts/postgresql-env.sh

/opt/bitnami/scripts/postgresql/stop.sh
/opt/bitnami/scripts/postgresql/start.sh
