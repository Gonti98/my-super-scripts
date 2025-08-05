#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PID=$(pgrep --euid "$USER" --exact "waybar" || true )

if [[ -z "$PID" ]]; then
  nohup waybar > /dev/null 2>&1 &
  exit 0
else
  kill -TERM "$PID"
  exit 0
fi

