#!/usr/bin/env bash

set -euo pipefail

cd /home/steam/css-serverfiles

exec ./srcds_run_64 \
    -game cstrike \
    -console \
    -usercon \
    -ip 0.0.0.0 \
    -port "$CSS_PORT" \
    -tickrate "$CSS_TICKRATE" \
    -maxplayers "$CSS_MAXPLAYERS" \
    +map "$CSS_MAP" \
    "$@"
