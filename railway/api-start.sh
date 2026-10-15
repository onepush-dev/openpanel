#!/bin/sh
set -e
echo "Running migrations..."
CI=true pnpm -r run migrate:deploy
exec pnpm start
