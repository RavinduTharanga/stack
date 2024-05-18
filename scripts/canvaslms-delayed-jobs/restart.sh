#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

/opt/bitnami/scripts/canvaslms-delayed-jobs/stop.sh
/opt/bitnami/scripts/canvaslms-delayed-jobs/start.sh
