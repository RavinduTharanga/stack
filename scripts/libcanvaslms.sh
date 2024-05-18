#!/bin/bash
#
# Bitnami Canvas LMS library

# shellcheck disable=SC1091

# Load generic libraries
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libnet.sh
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/libvalidations.sh
. /opt/bitnami/scripts/libpersistence.sh
. /opt/bitnami/scripts/libservice.sh

# Load database library
if [[ -f /opt/bitnami/scripts/libpostgresqlclient.sh ]]; then
    . /opt/bitnami/scripts/libpostgresqlclient.sh
elif [[ -f /opt/bitnami/scripts/libpostgresql.sh ]]; then
    . /opt/bitnami/scripts/libpostgresql.sh
fi

########################
# Validate settings in CANVASLMS_* env vars
# Globals:
#   CANVASLMS_*
# Arguments:
#   None
# Returns:
#   0 if the validation succeeded, 1 otherwise
#########################
canvaslms_validate() {
    debug "Validating settings in CANVASLMS_* environment variables..."
    local error_code=0

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }
    check_empty_value() {
        if is_empty_value "${!1}"; then
            print_validation_error "${1} must be set"
        fi
    }
    check_yes_no_value() {
        if ! is_yes_no_value "${!1}" && ! is_true_false_value "${!1}"; then
            print_validation_error "The allowed values for ${1} are: yes no"
        fi
    }
    check_multi_value() {
        if [[ " ${2} " != *" ${!1} "* ]]; then
            print_validation_error "The allowed values for ${1} are: ${2}"
        fi
    }
    check_resolved_hostname() {
        if ! is_hostname_resolved "$1"; then
            warn "Hostname ${1} could not be resolved, this could lead to connection issues"
        fi
    }
    check_valid_port() {
        local port_var="${1:?missing port variable}"
        local err
        if ! err="$(validate_port "${!port_var}")"; then
            print_validation_error "An invalid port was specified in the environment variable ${port_var}: ${err}."
        fi
    }

    # Validate user inputs
    check_empty_value "CANVASLMS_HOST"
    check_yes_no_value "CANVASLMS_ENABLE_HTTPS"
    check_resolved_hostname "$CANVASLMS_DATABASE_HOST"
    check_valid_port "CANVASLMS_DATABASE_PORT_NUMBER"
    check_resolved_hostname "$CANVASLMS_REDIS_HOST"
    check_valid_port "CANVASLMS_REDIS_PORT_NUMBER"
    check_resolved_hostname "$CANVASLMS_RCE_API_HOST"
    check_valid_port "CANVASLMS_RCE_API_PORT_NUMBER"
    check_empty_value "CANVASLMS_RCE_API_ENCRYPTION_SECRET"
    check_empty_value "CANVASLMS_RCE_API_SIGNING_SECRET"

    # Validate credentials
    if is_boolean_yes "${ALLOW_EMPTY_PASSWORD:-}"; then
        warn "You set the environment variable ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD:-}. For safety reasons, do not use this flag in a production environment."
    else
        for empty_env_var in "CANVASLMS_DATABASE_PASSWORD" "CANVASLMS_PASSWORD"; do
            is_empty_value "${!empty_env_var}" && print_validation_error "The ${empty_env_var} environment variable is empty or not set. Set the environment variable ALLOW_EMPTY_PASSWORD=yes to allow a blank password. This is only recommended for development environments."
        done
    fi

    # Validate SMTP credentials
    if ! is_empty_value "$CANVASLMS_SMTP_HOST"; then
        for empty_env_var in "CANVASLMS_SMTP_USER" "CANVASLMS_SMTP_PASSWORD"; do
            is_empty_value "${!empty_env_var}" && warn "The ${empty_env_var} environment variable is empty or not set."
        done
        is_empty_value "$CANVASLMS_SMTP_PORT_NUMBER" && print_validation_error "The CANVASLMS_SMTP_PORT_NUMBER environment variable is empty or not set."
        ! is_empty_value "$CANVASLMS_SMTP_PORT_NUMBER" && check_valid_port "CANVASLMS_SMTP_PORT_NUMBER"
        ! is_empty_value "$CANVASLMS_SMTP_PROTOCOL" && check_multi_value "CANVASLMS_SMTP_PROTOCOL" "ssl tls"
    fi

    return "$error_code"
}

########################
# Ensure Canvas LMS is initialized
# Globals:
#   CANVASLMS_*
# Arguments:
#   None
# Returns:
#   None
#########################
canvaslms_initialize() {
    # Check that external services are alive
    info "Trying to connect to the database server"
    canvaslms_wait_for_postgresql_connection "$CANVASLMS_DATABASE_HOST" "$CANVASLMS_DATABASE_PORT_NUMBER" "$CANVASLMS_DATABASE_NAME" "$CANVASLMS_DATABASE_USER" "$CANVASLMS_DATABASE_PASSWORD"
    info "Trying to connect to the Redis server"
    canvaslms_wait_for_redis_connection "$CANVASLMS_REDIS_HOST" "$CANVASLMS_REDIS_PORT_NUMBER"

    # Based on https://github.com/instructure/canvas-lms/wiki/Production-Start#canvas-default-configuration
    info "Configuring Canvas LMS with settings provided via environment variables"
    # Dynamic settings configuration: Nothing to configure
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#dynamic-settings-configuration
    # Database configuration
    # https://github.com/instructure/canvas-lms/wiki/${CANVASLMS_ENV}-Start#database-configuration
    canvaslms_conf_set "database" "${CANVASLMS_ENV}.host" "$CANVASLMS_DATABASE_HOST"
    canvaslms_conf_set "database" "${CANVASLMS_ENV}.port" "$CANVASLMS_DATABASE_PORT_NUMBER"
    canvaslms_conf_set "database" "${CANVASLMS_ENV}.database" "$CANVASLMS_DATABASE_NAME"
    canvaslms_conf_set "database" "${CANVASLMS_ENV}.username" "$CANVASLMS_DATABASE_USER"
    canvaslms_conf_set "database" "${CANVASLMS_ENV}.password" "$CANVASLMS_DATABASE_PASSWORD"
    # Outgoing mail configuration (SMTP)
    # https://github.com/instructure/canvas-lms/wiki/${CANVASLMS_ENV}-Start#outgoing-mail-configuration
    if ! is_empty_value "$CANVASLMS_SMTP_HOST"; then
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.address" "$CANVASLMS_SMTP_HOST"
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.port" "$CANVASLMS_SMTP_PORT_NUMBER"
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.user_name" "$CANVASLMS_SMTP_USER"
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.password" "$CANVASLMS_SMTP_PASSWORD"
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.domain" "example.com"
        canvaslms_conf_set "outgoing_mail" "${CANVASLMS_ENV}.outgoing_address" "$CANVASLMS_EMAIL"
    fi
    # URL configuration
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#url-configuration
    canvaslms_conf_set "domain" "${CANVASLMS_ENV}.domain" "$CANVASLMS_HOST"
    # Security configuration
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#security-configuration
    chmod g+w "${CANVASLMS_CONF_DIR}/security.yml"
    canvaslms_rake_execute "db:generate_security_key"
    chmod g-w "${CANVASLMS_CONF_DIR}/security.yml"
    # Cache configuration (via Redis)
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#cache-configuration
    canvaslms_conf_set "cache_store" "${CANVASLMS_ENV}.cache_store" "redis_cache_store"
    canvaslms_conf_set "redis" "${CANVASLMS_ENV}.servers[0]" "redis://${CANVASLMS_REDIS_HOST}:${CANVASLMS_REDIS_PORT_NUMBER}"
    # RCE Editor configuration (optional)
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#rich-content-editor
    # https://github.com/instructure/canvas-rce-api/blob/master/README.md#canvas
    canvaslms_conf_set "dynamic_settings" "${CANVASLMS_ENV}.config.canvas.rich-content-service.app-host" "${CANVASLMS_RCE_API_HOST}:${CANVASLMS_RCE_API_PORT_NUMBER}"
    canvaslms_conf_set "dynamic_settings" "${CANVASLMS_ENV}.config.canvas.canvas.encryption-secret" "$CANVASLMS_RCE_API_ENCRYPTION_SECRET"
    canvaslms_conf_set "dynamic_settings" "${CANVASLMS_ENV}.config.canvas.canvas.signing-secret" "$CANVASLMS_RCE_API_SIGNING_SECRET"
    # Renaming 20210812210129_add_singleton_column.rb to avoid "unknown attribute 'singleton' for Delayed::Backend::ActiveRecord::Job" error. https://groups.google.com/g/canvas-lms-users/c/pk6pzDb0-Gw
    mv /opt/bitnami/canvaslms/db/migrate/*_add_singleton_column.rb /opt/bitnami/canvaslms/db/migrate/20111111214311_add_singleton_column.rb
    # CONTENT-1840: Removing 20210823222355_change_immersive_reader_allowed_on_to_on.rb to avoid undefined method `id' error:
    # https://github.com/instructure/canvas-lms/issues/2035
    mv /opt/bitnami/canvaslms/db/migrate/*_change_immersive_reader_allowed_on_to_on.rb /tmp
    # Populate Canvas LMS database and initialize admin user
    # https://github.com/instructure/canvas-lms/wiki/Production-Start#database-population
    info "Populating database"
    # Note: CANVAS_LMS_ACCOUNT_NAME is used by the application as the organization name, not the user name
    CANVAS_LMS_ADMIN_EMAIL="$CANVASLMS_EMAIL" \
    CANVAS_LMS_ADMIN_PASSWORD="$CANVASLMS_PASSWORD" \
    CANVAS_LMS_ACCOUNT_NAME="$CANVASLMS_SITE_NAME" \
    CANVAS_LMS_STATS_COLLECTION="opt_out" \
        canvaslms_rake_execute "db:initial_setup"

    # CONTENT-1840: Recovering 20210823222355_change_immersive_reader_allowed_on_to_on.rb and migrating the database again
    mv /tmp/*_change_immersive_reader_allowed_on_to_on.rb /opt/bitnami/canvaslms/db/migrate/
    canvaslms_rake_execute "db:migrate"
    # ensure that all canvas lms assets for the currently enabled theme exist, regenerate them if needed
    # needs to happen after the database is populated, since it will update existing themes
    # https://github.com/instructure/canvas-lms/wiki/production-start#generate-assets
    info "ensuring that assets are generated"
    canvaslms_rake_execute "brand_configs:generate_and_upload_all"

    # Avoid exit code of previous commands to affect the result of this function
    true
}

########################
# Add or modify an entry in the Canvas LMS configuration file (config.inc.php)
# Globals:
#   CANVASLMS_*
# Arguments:
#   $1 - Configuration file name (e.g. domain, delayed_job, etc.)
#   $2 - YAML key to set
#   $3 - Value to assign to the YAML key
#   $4 - YAML type (string, int or bool)
#   $5 - Indent (defaults to 4)
# Returns:
#   None
#########################
canvaslms_conf_set() {
    local -r conf_file_name="${1:?Missing config file name}"
    local -r key="${2:?Missing key}"
    local -r value="${3:-}"
    local -r type="${4:-string}"
    local -r indent="${5:-4}"
    local -r tempfile=$(mktemp)
    local -r conf_file="${CANVASLMS_CONF_DIR}/${conf_file_name}.yml"

    case "$type" in
    string)
        yq eval "(.${key}) |= \"${value}\"" --indent "${indent}" "$conf_file" >"$tempfile"
        ;;
    int)
        yq eval "(.${key}) |= ${value}" --indent "${indent}" "$conf_file" >"$tempfile"
        ;;
    bool)
        yq eval "(.${key}) |= (\"${value}\" | test(\"true\"))" --indent "${indent}" "$conf_file" >"$tempfile"
        ;;
    *)
        error "Type unknown: ${type}"
        return 1
        ;;
    esac
    cp "$tempfile" "$conf_file"
}

########################
# Wait until the database is accessible with the currently-known credentials
# Globals:
#   *
# Arguments:
#   $1 - database host
#   $2 - database port
#   $3 - database name
#   $4 - database username
#   $5 - database user password (optional)
# Returns:
#   true if the database connection succeeded, false otherwise
#########################
canvaslms_wait_for_postgresql_connection() {
    local -r db_host="${1:?missing database host}"
    local -r db_port="${2:?missing database port}"
    local -r db_name="${3:?missing database name}"
    local -r db_user="${4:?missing database user}"
    local -r db_pass="${5:-}"
    check_postgresql_connection() {
        echo "SELECT 1" | postgresql_remote_execute "$db_host" "$db_port" "$db_name" "$db_user" "$db_pass"
    }
    if ! retry_while "check_postgresql_connection"; then
        error "Could not connect to the database"
        return 1
    fi
}

########################
# Wait until Redis is accessible
# Globals:
#   *
# Arguments:
#   $1 - Redis host
#   $2 - Redis port
# Returns:
#   true if the Redis connection succeeded, false otherwise
#########################
canvaslms_wait_for_redis_connection() {
    local -r redis_host="${1:?missing Redis host}"
    local -r redis_port="${2:?missing Redis port}"
    if ! retry_while "debug_execute wait-for-port --timeout 5 --host ${redis_host} ${redis_port}"; then
        error "Could not connect to Redis"
        return 1
    fi
}

########################
# Executes Bundler with the proper environment and the specified arguments and print result to stdout
# Globals:
#   CANVASLMS_*
# Arguments:
#   $1..$n - Arguments to pass to the CLI call
# Returns:
#   None
#########################
canvaslms_bundle_execute_print_output() {
    # Avoid creating unnecessary cache files at initialization time
    local -a cmd=("bundle" "exec" "$@")
    # Run as application user to avoid having to change permissions/ownership afterwards
    am_i_root && cmd=("run_as_user" "$CANVASLMS_DAEMON_USER" "${cmd[@]}")
    (
        export RAILS_ENV="$CANVASLMS_ENV"
        cd "$CANVASLMS_BASE_DIR" || false
        "${cmd[@]}"
    )
}

########################
# Executes Bundler with the proper environment and the specified arguments
# Globals:
#   CANVASLMS_*
# Arguments:
#   $1..$n - Arguments to pass to the CLI call
# Returns:
#   None
#########################
canvaslms_bundle_execute() {
    debug_execute canvaslms_bundle_execute_print_output "$@"
}

########################
# Executes the 'rake' CLI with the proper Bundler environment and the specified arguments and print result to stdout
# Globals:
#   CANVASLMS_*
# Arguments:
#   $1..$n - Arguments to pass to the CLI call
# Returns:
#   None
#########################
canvaslms_rake_execute_print_output() {
    canvaslms_bundle_execute_print_output "rake" "$@"
}

########################
# Executes the 'rake' CLI with the proper Bundler environment and the specified arguments
# Globals:
#   CANVASLMS_*
# Arguments:
#   $1..$n - Arguments to pass to the CLI call
# Returns:
#   None
#########################
canvaslms_rake_execute() {
    debug_execute canvaslms_rake_execute_print_output "$@"
}

########################
# Check if canvas-rce-api daemons are running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
canvaslms_is_rce_api_running() {
    pid="$(get_pid_from_file "$CANVASLMS_RCE_API_PID_FILE")"
    if [[ -n "$pid" ]]; then
        is_service_running "$pid"
    else
        false
    fi
}

########################
# Check if canvas-rce-api daemons are not running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
canvaslms_is_rce_api_not_running() {
    ! canvaslms_is_rce_api_running
}

########################
# Stop canvas-rce-api daemons
# Arguments:
#   None
# Returns:
#   None
#########################
canvaslms_rce_api_stop() {
    ! canvaslms_is_rce_api_running && return
    stop_service_using_pid "$CANVASLMS_RCE_API_PID_FILE"
}

########################
# Check if canvaslms-delayed-jobs daemons are running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
canvaslms_is_delayed_jobs_running() {
    pid="$(get_pid_from_file "$CANVASLMS_DELAYED_JOBS_PID_FILE")"
    if [[ -n "$pid" ]]; then
        is_service_running "$pid"
    else
        false
    fi
}

########################
# Check if canvaslms-delayed-jobs daemons are not running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
canvaslms_is_delayed_jobs_not_running() {
    ! canvaslms_is_delayed_jobs_running
}

########################
# Stop canvaslms-delayed-jobs daemons
# Arguments:
#   None
# Returns:
#   None
#########################
canvaslms_delayed_jobs_stop() {
    ! canvaslms_is_delayed_jobs_running && return
    stop_service_using_pid "$CANVASLMS_DELAYED_JOBS_PID_FILE"
}
