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

# Internal ports — only Caddy uses Railway's public PORT.
SERVER_PORT=8081
CLIENT_PORT=3000
CADDY_PORT="${PORT:-8080}"

echo "Starting OpenSign server on port ${SERVER_PORT}..."
cd /app/server
PORT="${SERVER_PORT}" node index.js &
SERVER_PID=$!

echo "Starting OpenSign client on port ${CLIENT_PORT}..."
cd /app/client
PORT="${CLIENT_PORT}" node server.cjs &
CLIENT_PID=$!

# Give backends a moment to bind their ports before Caddy proxies traffic.
sleep 2

trap 'kill $SERVER_PID $CLIENT_PID 2>/dev/null' TERM INT

echo "Starting Caddy on port ${CADDY_PORT}..."
PORT="${CADDY_PORT}" exec caddy run --config /app/Caddyfile --adapter caddyfile
