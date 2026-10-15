#!/bin/sh
set -e
printf '%s\n' "$CADDYFILE" > /etc/caddy/Caddyfile
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
