#!/bin/sh
set -eu

# Railway supplies PORT dynamically. Hermes' dashboard service has its own
# port variable, so bridge the two before s6-overlay starts its services.
: "${PORT:=9119}"
export HERMES_DASHBOARD_PORT="${HERMES_DASHBOARD_PORT:-$PORT}"

# The official image uses s6-overlay as PID 1. Pass the original command
# through unchanged so gateway/dashboard supervision remains upstream-owned.
exec /init /opt/hermes/docker/main-wrapper.sh "$@"
