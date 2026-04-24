#!/usr/bin/env bash
# Run OpenCode in Docker, connected to local Ollama.
# Usage: ./run.sh [path/to/project]   (defaults to current directory)

PROJECT="${1:-$(pwd)}"

# Resolve the script's directory portably (Linux and macOS).
# macOS's BSD readlink lacks -f, so follow symlinks manually.
SOURCE="${BASH_SOURCE[0]:-$0}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

URL_FILE="${SCRIPT_DIR}/provider-url.txt"
if [ -f "$URL_FILE" ]; then
  OLLAMA_HOST=$(cat "$URL_FILE")
else
  echo "Error: provider-url.txt not found. Create it with your Ollama endpoint."
  exit 1
fi

# Extract hostname from URL and resolve to IP dynamically.
HOSTNAME=$(echo "$OLLAMA_HOST" | sed -E 's|^https?://||' | cut -d':' -f1)

resolve_host() {
  local host="$1" ip=""

  # Linux: getent uses nsswitch, which honours Tailscale's resolver.
  if command -v getent >/dev/null 2>&1; then
    ip=$(getent hosts "$host" 2>/dev/null | awk '{print $1; exit}')
    [ -n "$ip" ] && { echo "$ip"; return 0; }
  fi

  # macOS: dscacheutil uses the system resolver, which picks up Tailscale
  # MagicDNS.
  if command -v dscacheutil >/dev/null 2>&1; then
    ip=$(dscacheutil -q host -a name "$host" 2>/dev/null \
      | awk '/^ip_address:/ {print $2; exit}')
    [ -n "$ip" ] && { echo "$ip"; return 0; }
  fi

  # Fallbacks available on most systems.
  if command -v dig >/dev/null 2>&1; then
    ip=$(dig +short "$host" 2>/dev/null | awk '/^[0-9.]+$/ {print; exit}')
    [ -n "$ip" ] && { echo "$ip"; return 0; }
  fi

  if command -v host >/dev/null 2>&1; then
    ip=$(host "$host" 2>/dev/null \
      | awk '/has address/ {print $NF; exit}')
    [ -n "$ip" ] && { echo "$ip"; return 0; }
  fi

  return 1
}

RESOLVED_IP=$(resolve_host "$HOSTNAME")

if [ -z "$RESOLVED_IP" ]; then
  echo "Error: Could not resolve $HOSTNAME - check DNS/Tailscale connection"
  exit 1
fi

echo "Resolved $HOSTNAME to $RESOLVED_IP"

# Keep the active model loaded in Ollama while the container is running.
# Re-reads OpenCode's state each cycle so it tracks model switches.
# Pings every 4 minutes with a 5-minute keep_alive window.
OLLAMA_BASE=$(echo "$OLLAMA_HOST" | sed 's|/v1$||')

_keepalive() {
  while true; do
    model=$(docker run --rm -v opencode-state:/state alpine \
      sh -c 'cat /state/model.json 2>/dev/null' \
      | jq -r '.recent[0].modelID // empty')
    if [ -n "$model" ]; then
      curl -s -o /dev/null -X POST "${OLLAMA_BASE}/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"${model}\", \"keep_alive\": \"5m\"}"
    fi
    sleep 240
  done
}

_keepalive &
KEEPALIVE_PID=$!

docker run -it --rm \
  --add-host "${HOSTNAME}:${RESOLVED_IP}" \
  -e GLAMOUR_STYLE=dark \
  -e OLLAMA_HOST="$OLLAMA_HOST" \
  -v "${PROJECT}:/workspace" \
  -w /workspace \
  -v "${SCRIPT_DIR}/opencode.json:/home/coder/.config/opencode/opencode.json:ro" \
  -v "${SCRIPT_DIR}/tui.json:/home/coder/.config/opencode/tui.json:ro" \
  -v "${SCRIPT_DIR}/skills:/home/coder/.config/opencode/skills:ro" \
  -v "opencode-share:/home/coder/.local/share/opencode" \
  -v "opencode-state:/home/coder/.local/state/opencode" \
  -v "${HOME}/.gitconfig:/home/coder/.gitconfig:ro" \
  sancho

kill "$KEEPALIVE_PID" 2>/dev/null
wait "$KEEPALIVE_PID" 2>/dev/null
