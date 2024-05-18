#!/bin/bash
#
# Environment configuration for canvaslms

# The values for all environment variables will be set in the below order of precedence
# 1. Custom environment variables defined below after Bitnami defaults
# 2. Constants defined in this file (environment variables with no default), i.e. BITNAMI_ROOT_DIR
# 3. Environment variables overridden via external files using *_FILE variables (see below)
# 4. Environment variables set externally (i.e. current Bash context/Dockerfile/userdata)

# Load logging library
# shellcheck disable=SC1090,SC1091
. /opt/bitnami/scripts/liblog.sh

export BITNAMI_ROOT_DIR="/opt/bitnami"
export BITNAMI_VOLUME_DIR="/bitnami"

# Logging configuration
export MODULE="${MODULE:-canvaslms}"
export BITNAMI_DEBUG="${BITNAMI_DEBUG:-false}"

# By setting an environment variable matching *_FILE to a file path, the prefixed environment
# variable will be overridden with the value specified in that file
canvaslms_env_vars=(
    CANVASLMS_ENABLE_HTTPS
    CANVASLMS_EXTERNAL_HTTP_PORT_NUMBER
    CANVASLMS_EXTERNAL_HTTPS_PORT_NUMBER
    CANVASLMS_HOST
    CANVASLMS_ENV
    CANVASLMS_USERNAME
    CANVASLMS_PASSWORD
    CANVASLMS_EMAIL
    CANVASLMS_SITE_NAME
    CANVASLMS_SMTP_HOST
    CANVASLMS_SMTP_PORT_NUMBER
    CANVASLMS_SMTP_USER
    CANVASLMS_SMTP_PASSWORD
    CANVASLMS_SMTP_PROTOCOL
    CANVASLMS_DATABASE_HOST
    CANVASLMS_DATABASE_PORT_NUMBER
    CANVASLMS_DATABASE_NAME
    CANVASLMS_DATABASE_USER
    CANVASLMS_DATABASE_PASSWORD
    CANVASLMS_REDIS_HOST
    CANVASLMS_REDIS_PORT_NUMBER
    CANVASLMS_RCE_API_HOST
    CANVASLMS_RCE_API_PORT_NUMBER
    CANVASLMS_RCE_API_ENCRYPTION_SECRET
    CANVASLMS_RCE_API_SIGNING_SECRET
    SMTP_HOST
    SMTP_PORT
    CANVASLMS_SMTP_PORT
    SMTP_USER
    SMTP_PASSWORD
    SMTP_PROTOCOL
    POSTGRESQL_HOST
    POSTGRESQL_PORT_NUMBER
    POSTGRESQL_DATABASE_NAME
    POSTGRESQL_DATABASE_USER
    POSTGRESQL_DATABASE_USERNAME
    POSTGRESQL_DATABASE_PASSWORD
    REDIS_HOST
    REDIS_PORT_NUMBER
)
for env_var in "${canvaslms_env_vars[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        if [[ -r "${!file_env_var:-}" ]]; then
            export "${env_var}=$(< "${!file_env_var}")"
            unset "${file_env_var}"
        else
            warn "Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
        fi
    fi
done
unset canvaslms_env_vars

# Load Bitnami installation configuration and user-data
[[ ! -f "${BITNAMI_ROOT_DIR}/scripts/bitnami-env.sh" ]] || . "${BITNAMI_ROOT_DIR}/scripts/bitnami-env.sh"

# Paths
export CANVASLMS_BASE_DIR="${BITNAMI_ROOT_DIR}/canvaslms"
export CANVASLMS_CONF_DIR="${CANVASLMS_BASE_DIR}/config"
export CANVASLMS_RCE_API_DIR="${BITNAMI_ROOT_DIR}/canvas-rce-api"
export PATH="${BITNAMI_ROOT_DIR}/common/bin:${BITNAMI_ROOT_DIR}/node/bin:${BITNAMI_ROOT_DIR}/ruby/bin:${PATH}"

# System users (when running with a privileged user)
export CANVASLMS_DAEMON_USER="daemon"
export CANVASLMS_DAEMON_GROUP="daemon"

# Canvas LMS configuration
export CANVASLMS_ENABLE_HTTPS="${CANVASLMS_ENABLE_HTTPS:-no}" # only used during the first initialization
export CANVASLMS_EXTERNAL_HTTP_PORT_NUMBER="${CANVASLMS_EXTERNAL_HTTP_PORT_NUMBER:-80}" # only used during the first initialization
export CANVASLMS_EXTERNAL_HTTPS_PORT_NUMBER="${CANVASLMS_EXTERNAL_HTTPS_PORT_NUMBER:-443}" # only used during the first initialization
export CANVASLMS_HOST="${CANVASLMS_HOST:-localhost}" # only used during the first initialization
export CANVASLMS_ENV="${CANVASLMS_ENV:-production}"

# Canvas LMS credentials
export CANVASLMS_USERNAME="${CANVASLMS_USERNAME:-user}" # only used during the first initialization
export CANVASLMS_PASSWORD="${CANVASLMS_PASSWORD:-Bitnami12345}" # only used during the first initialization
export CANVASLMS_EMAIL="${CANVASLMS_EMAIL:-user@example.com}" # only used during the first initialization
export CANVASLMS_SITE_NAME="${CANVASLMS_SITE_NAME:-My site}" # only used during the first initialization

# Canvas LMS SMTP credentials
CANVASLMS_SMTP_HOST="${CANVASLMS_SMTP_HOST:-"${SMTP_HOST:-}"}"
export CANVASLMS_SMTP_HOST="${CANVASLMS_SMTP_HOST:-}" # only used during the first initialization
CANVASLMS_SMTP_PORT_NUMBER="${CANVASLMS_SMTP_PORT_NUMBER:-"${SMTP_PORT:-}"}"
CANVASLMS_SMTP_PORT_NUMBER="${CANVASLMS_SMTP_PORT_NUMBER:-"${CANVASLMS_SMTP_PORT:-}"}"
export CANVASLMS_SMTP_PORT_NUMBER="${CANVASLMS_SMTP_PORT_NUMBER:-}" # only used during the first initialization
CANVASLMS_SMTP_USER="${CANVASLMS_SMTP_USER:-"${SMTP_USER:-}"}"
export CANVASLMS_SMTP_USER="${CANVASLMS_SMTP_USER:-}" # only used during the first initialization
CANVASLMS_SMTP_PASSWORD="${CANVASLMS_SMTP_PASSWORD:-"${SMTP_PASSWORD:-}"}"
export CANVASLMS_SMTP_PASSWORD="${CANVASLMS_SMTP_PASSWORD:-}" # only used during the first initialization
CANVASLMS_SMTP_PROTOCOL="${CANVASLMS_SMTP_PROTOCOL:-"${SMTP_PROTOCOL:-}"}"
export CANVASLMS_SMTP_PROTOCOL="${CANVASLMS_SMTP_PROTOCOL:-}" # only used during the first initialization

# Database configuration
export CANVASLMS_DEFAULT_DATABASE_HOST="127.0.0.1" # only used at build time
CANVASLMS_DATABASE_HOST="${CANVASLMS_DATABASE_HOST:-"${POSTGRESQL_HOST:-}"}"
export CANVASLMS_DATABASE_HOST="${CANVASLMS_DATABASE_HOST:-$CANVASLMS_DEFAULT_DATABASE_HOST}" # only used during the first initialization
CANVASLMS_DATABASE_PORT_NUMBER="${CANVASLMS_DATABASE_PORT_NUMBER:-"${POSTGRESQL_PORT_NUMBER:-}"}"
export CANVASLMS_DATABASE_PORT_NUMBER="${CANVASLMS_DATABASE_PORT_NUMBER:-5432}" # only used during the first initialization
CANVASLMS_DATABASE_NAME="${CANVASLMS_DATABASE_NAME:-"${POSTGRESQL_DATABASE_NAME:-}"}"
export CANVASLMS_DATABASE_NAME="${CANVASLMS_DATABASE_NAME:-bitnami_canvaslms}" # only used during the first initialization
CANVASLMS_DATABASE_USER="${CANVASLMS_DATABASE_USER:-"${POSTGRESQL_DATABASE_USER:-}"}"
CANVASLMS_DATABASE_USER="${CANVASLMS_DATABASE_USER:-"${POSTGRESQL_DATABASE_USERNAME:-}"}"
export CANVASLMS_DATABASE_USER="${CANVASLMS_DATABASE_USER:-bn_canvaslms}" # only used during the first initialization
CANVASLMS_DATABASE_PASSWORD="${CANVASLMS_DATABASE_PASSWORD:-"${POSTGRESQL_DATABASE_PASSWORD:-}"}"
export CANVASLMS_DATABASE_PASSWORD="${CANVASLMS_DATABASE_PASSWORD:-}" # only used during the first initialization

# Redis(R) configuration
export CANVASLMS_DEFAULT_REDIS_HOST="127.0.0.1" # only used at build time
CANVASLMS_REDIS_HOST="${CANVASLMS_REDIS_HOST:-"${REDIS_HOST:-}"}"
export CANVASLMS_REDIS_HOST="${CANVASLMS_REDIS_HOST:-$CANVASLMS_DEFAULT_REDIS_HOST}"
CANVASLMS_REDIS_PORT_NUMBER="${CANVASLMS_REDIS_PORT_NUMBER:-"${REDIS_PORT_NUMBER:-}"}"
export CANVASLMS_REDIS_PORT_NUMBER="${CANVASLMS_REDIS_PORT_NUMBER:-6379}"

# canvas-rce-api configuration
export CANVASLMS_RCE_API_HOST="${CANVASLMS_RCE_API_HOST:-rce.example.com}"
export CANVASLMS_RCE_API_PORT_NUMBER="${CANVASLMS_RCE_API_PORT_NUMBER:-3000}"
export CANVASLMS_RCE_API_ENCRYPTION_SECRET="${CANVASLMS_RCE_API_ENCRYPTION_SECRET:-}"
export CANVASLMS_RCE_API_SIGNING_SECRET="${CANVASLMS_RCE_API_SIGNING_SECRET:-}"
export CANVASLMS_RCE_API_PID_FILE="${CANVASLMS_RCE_API_DIR}/tmp/canvas-rce-api.pid"
export CANVASLMS_RCE_API_LOG_FILE="${CANVASLMS_RCE_API_DIR}/log/canvas-rce-api.log"

# canvaslms-delayed-jobs configuration
export CANVASLMS_DELAYED_JOBS_PID_FILE="${CANVASLMS_BASE_DIR}/tmp/pids/delayed_jobs_pool.pid"
export CANVASLMS_DELAYED_JOBS_LOG_FILE="${CANVASLMS_BASE_DIR}/log/delayed_job.log"

# Custom environment variables may be defined below
