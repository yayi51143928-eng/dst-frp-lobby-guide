#!/bin/sh
set -eu

: "${VPS_HOST:?Set VPS_HOST}"
: "${VPS_USER:?Set VPS_USER}"
test -r /run/secrets/vps_ssh_key
test -r /etc/ssh/dst_known_hosts

# 0.0.0.0 is inside this container; do not publish its port on the host.
exec ssh -F /dev/null -NT \
  -p "${VPS_SSH_PORT:-22}" \
  -i /run/secrets/vps_ssh_key \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=/etc/ssh/dst_known_hosts \
  -o ExitOnForwardFailure=yes \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -L 0.0.0.0:8888:127.0.0.1:8888 \
  "${VPS_USER}@${VPS_HOST}"
