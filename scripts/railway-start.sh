#!/bin/sh
set -e

generate_client_env() {
  ENV_FILE=/app/client/build/env.js
  echo "Generating runtime env file at $ENV_FILE..."
  echo "window.RUNTIME_ENV = {" > "$ENV_FILE"

  for key in REACT_APP_SERVERURL; do
    value=$(printenv "$key" | sed 's/"/\\"/g')
    echo "  $key: \"$value\"," >> "$ENV_FILE"
  done

  echo "};" >> "$ENV_FILE"
}

generate_client_env

echo "Starting OpenSign server..."
cd /app/server
node index.js &
SERVER_PID=$!

echo "Starting OpenSign client..."
cd /app/client
node server.cjs &
CLIENT_PID=$!

# Give backends a moment to bind their ports before Caddy proxies traffic.
sleep 2

trap 'kill $SERVER_PID $CLIENT_PID 2>/dev/null' TERM INT

echo "Starting Caddy on port ${PORT:-3001}..."
exec caddy run --config /app/Caddyfile --adapter caddyfile
