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

if canvaslms_is_delayed_jobs_not_running; then
    cd "$CANVASLMS_BASE_DIR"
    export RAILS_ENV="$CANVASLMS_ENV"
    if am_i_root; then
        run_as_user "$CANVASLMS_DAEMON_USER" script/delayed_job start
    else
        script/delayed_job start
    fi
    if ! retry_while "canvaslms_is_delayed_jobs_running"; then
        error "canvaslms-delayed-jobs did not start"
        error_code=1
    else
        info "canvaslms-delayed-jobs started"
    fi
else
    info "canvaslms-delayed-jobs is already running"
fi

exit "$error_code"
