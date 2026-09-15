#!/usr/bin/env bash
set -e

# A fixed session-bus address lets independent GUI processes started by
# PyCharm discover one another, as CCS expects.
bus_socket="/tmp/ccs-session-bus"
if [ ! -S "${bus_socket}" ]; then
    rm -f "${bus_socket}"
    dbus-daemon --session --fork --nopidfile --address="unix:path=${bus_socket}"
fi

exec "$@"
