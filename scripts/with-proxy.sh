#!/usr/bin/env bash
# Run an existing DST launcher from its original working directory.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  printf 'Usage: bash with-proxy.sh COMMAND [ARG ...]\n' >&2
  exit 64
fi

export https_proxy="${DST_HTTPS_PROXY:-http://127.0.0.1:8888}"
export no_proxy='localhost,127.0.0.1'
export NO_PROXY="$no_proxy"

# A successful HTTP response proves only that the proxy can reach this URL.
curl --fail --show-error --silent --noproxy '' \
  --connect-timeout 5 --max-time 15 \
  --proxy "$https_proxy" https://api.ipify.org
printf '\nProxy reachable. Confirm this IP matches your FRP public entry.\n' >&2
exec "$@"
