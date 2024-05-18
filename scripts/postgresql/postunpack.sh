#!/bin/bash

# shellcheck disable=SC1091

# Load libraries
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/libpostgresql.sh

# Load PostgreSQL environment variables
. /opt/bitnami/scripts/postgresql-env.sh

for dir in "$POSTGRESQL_INITSCRIPTS_DIR" "$POSTGRESQL_TMP_DIR" "$POSTGRESQL_LOG_DIR" "$POSTGRESQL_CONF_DIR" "${POSTGRESQL_CONF_DIR}/conf.d" "$POSTGRESQL_MOUNTED_CONF_DIR" "${POSTGRESQL_MOUNTED_CONF_DIR}/conf.d" "$POSTGRESQL_VOLUME_DIR"; do
    ensure_dir_exists "$dir"
done

# Create basic pg_hba.conf for local connections
postgresql_allow_local_connection
# Create basic postgresql.conf
postgresql_create_config

chmod -R g+rwX "$POSTGRESQL_INITSCRIPTS_DIR" "$POSTGRESQL_TMP_DIR" "$POSTGRESQL_LOG_DIR" "$POSTGRESQL_CONF_DIR" "${POSTGRESQL_CONF_DIR}/conf.d" "$POSTGRESQL_MOUNTED_CONF_DIR" "${POSTGRESQL_MOUNTED_CONF_DIR}/conf.d" "$POSTGRESQL_VOLUME_DIR"

# Enable logging to the log file instead of stdout
postgresql_set_property "log_destination" "stderr"
postgresql_set_property "logging_collector" "on"
postgresql_set_property "log_directory" "$POSTGRESQL_LOG_DIR"
postgresql_set_property "log_filename" "$(basename "$POSTGRESQL_LOG_FILE")"
postgresql_set_property "log_rotation_age" 0

# Enable extra service management configuration
if [[ "$BITNAMI_SERVICE_MANAGER" = "monit" ]]; then
    generate_monit_conf "postgresql" "$POSTGRESQL_PID_FILE" /opt/bitnami/scripts/postgresql/start.sh /opt/bitnami/scripts/postgresql/stop.sh
elif [[ "$BITNAMI_SERVICE_MANAGER" = "systemd" ]]; then
    # https://www.postgresql.org/docs/current/server-start.html
    generate_systemd_conf "postgresql" \
        --name "PostgreSQL" \
        --type "simple" \
        --user "$POSTGRESQL_DAEMON_USER" \
        --group "$POSTGRESQL_DAEMON_GROUP" \
        --exec-start "${POSTGRESQL_BIN_DIR}/postgres -D ${POSTGRESQL_DATA_DIR} --config-file=${POSTGRESQL_CONF_FILE} --external_pid_file=${POSTGRESQL_PID_FILE} --hba_file=${POSTGRESQL_PGHBA_FILE}" \
        --pid-file "$POSTGRESQL_PID_FILE"
else
    error "Unsupported service manager ${BITNAMI_SERVICE_MANAGER}"
    exit 1
fi
# 'su' option used to avoid: "error: skipping (...) because parent directory has insecure permissions (It's world writable or writable by group which is not "root")"
generate_logrotate_conf "postgresql" "$POSTGRESQL_LOG_FILE" --extra "su ${POSTGRESQL_DAEMON_USER} ${POSTGRESQL_DAEMON_GROUP}"

info "Creating PostgreSQL daemon user"
ensure_user_exists "$POSTGRESQL_DAEMON_USER" --group "$POSTGRESQL_DAEMON_GROUP"

for dir in "$POSTGRESQL_TMP_DIR" "$POSTGRESQL_LOG_DIR" "$POSTGRESQL_DATA_DIR"; do
    ensure_dir_exists "$dir"
    chown "${POSTGRESQL_DAEMON_USER}:${POSTGRESQL_DAEMON_GROUP}" "$dir"
done

ensure_dir_exists "${POSTGRESQL_CONF_DIR}/bitnami"

# Create configuration files for setting PostgreSQL optimization parameters depending on the instance size
# Default to micro configuration until a resize is performed
ln -sf "bitnami/memory-micro.conf" "${POSTGRESQL_CONF_DIR}/memory.conf"
read -r -a supported_machine_sizes <<< "$(get_supported_machine_sizes)"

for machine_size in "${supported_machine_sizes[@]}"; do
    case "$machine_size" in
        micro)
            effective_cache_size="400MB"
            max_connections="100"
            shared_buffers="200MB"
            ;;
        small)
            effective_cache_size="800MB"
            max_connections="200"
            shared_buffers="400MB"
            ;;
        medium)
            effective_cache_size="1600MB"
            max_connections="400"
            shared_buffers="800MB"
            ;;
        large)
            effective_cache_size="3200MB"
            max_connections="800"
            shared_buffers="1600MB"
            ;;
        xlarge)
            effective_cache_size="6400MB"
            max_connections="1600"
            shared_buffers="3200MB"
            ;;
        2xlarge)
            effective_cache_size="12800MB"
            max_connections="3200"
            shared_buffers="6400MB"
            ;;
        *)
            error "Unknown machine size '${machine_size}'"
            exit 1
            ;;
        esac
    cat >"${POSTGRESQL_CONF_DIR}/bitnami/memory-${machine_size}.conf" <<EOF
# Memory settings
#
# Note: This will be modified on server size changes

effective_cache_size = ${effective_cache_size}
max_connections = ${max_connections}
shared_buffers = ${shared_buffers}
EOF
done

cat >> "$POSTGRESQL_CONF_FILE" << EOF
# Memory settings
include = '${POSTGRESQL_CONF_DIR}/memory.conf'
EOF
