#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

########################
# Print Passenger root directory
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
get_passenger_root() {
    passenger-config --root
}

########################
# Print 'ruby' command used to invoke Passenger
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#########################
get_passenger_ruby_command() {
    # The --ruby-command option locates the Ruby command used to configure Passenger (the one we want),
    # but also the one located first with PATH. It is sorted by that order so we obtain the first entry.
    # NOTE: We pipe to 'head -n 1' instead of running 'exit' in AWK to avoid broken pipe issues in CentOS 7
    (passenger-config --ruby-command || true) | awk '/Command:/ { print $2 }' | head -n 1
}

# Load libraries
. /opt/bitnami/scripts/libvalidations.sh
. /opt/bitnami/scripts/libapache.sh

# Load Apache environment
. /opt/bitnami/scripts/apache-env.sh

# Ensure we are using the Bitnami-bundled Ruby installation
export PATH="${BITNAMI_ROOT_DIR}/ruby/bin:${BITNAMI_ROOT_DIR}/jruby/bin:${BITNAMI_ROOT_DIR}/java/bin:${PATH}"

PASSENGER_ROOT="$(get_passenger_root)"
PASSENGER_RUBY_COMMAND="$(get_passenger_ruby_command)"

# Check that the Passenger Ruby command is correct to avoid writing incorrect configuration files
if [[ "$PASSENGER_RUBY_COMMAND" != "${BITNAMI_ROOT_DIR}/ruby/"* && "$PASSENGER_RUBY_COMMAND" != "${BITNAMI_ROOT_DIR}/jruby/"* ]]; then
    error "Failed to run passenger-config --ruby-command"
    exit 1
fi

# Write Passenger configuration file
MOD_PASSENGER_FILE="${PASSENGER_ROOT}/buildout/apache2/mod_passenger.so"
cat >"${APACHE_CONF_DIR}/bitnami/passenger.conf" <<EOF
LoadModule passenger_module ${MOD_PASSENGER_FILE}
PassengerRoot ${PASSENGER_ROOT}
PassengerRuby ${PASSENGER_RUBY_COMMAND}
PassengerEnabled off
PassengerFriendlyErrorPages off
PassengerUser ${APACHE_DAEMON_USER}
PassengerGroup ${APACHE_DAEMON_GROUP}
EOF

# JRuby does not support the default 'smart' Passenger Spawn Method
if [[ "$(basename "$PASSENGER_RUBY_COMMAND")" = "jruby" ]]; then
    cat >>"${APACHE_CONF_DIR}/bitnami/passenger.conf" <<EOF
PassengerSpawnMethod direct
EOF
fi

# Enable Passenger for Apache
cat >>"$APACHE_CONF_FILE" <<EOF
Include ${APACHE_CONF_DIR}/bitnami/passenger.conf
EOF
