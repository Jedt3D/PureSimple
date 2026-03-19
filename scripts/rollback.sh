#!/usr/bin/env bash
# rollback.sh — Emergency rollback: restore app.bak and restart
# Usage: ./scripts/rollback.sh  (run locally to trigger remote rollback)
#        Can also be called directly on the server as bash scripts/rollback.sh

set -euo pipefail

REMOTE_HOST="root@129.212.236.80"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"
DEPLOY_DIR="/opt/puresimple"
SERVICE="puresimple.service"
HEALTH_URL="http://localhost:8080/health"

log() {
  echo "[rollback] $*"
}

# Detect whether we're already on the server (no SSH needed)
if [[ "${1:-}" == "--local" ]] || [[ "$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -c '129.212.236.80' || true)" -gt 0 ]]; then
  # Running on the server itself
  log "Running in local mode on server"
  cd "$DEPLOY_DIR"

  log "Stopping service…"
  systemctl stop "$SERVICE" || true

  if [[ -f app.bak ]]; then
    log "Restoring app.bak → app"
    mv -f app.bak app
  else
    log "ERROR: app.bak not found — cannot rollback"
    exit 1
  fi

  log "Starting service…"
  systemctl start "$SERVICE"

  sleep 3

  if curl -sf "$HEALTH_URL"; then
    log "ROLLBACK OK — service is healthy"
  else
    log "ROLLBACK FAILED — service is not responding"
    exit 1
  fi
else
  # Running locally — SSH to the server and re-run this script
  log "Triggering rollback on $REMOTE_HOST…"
  ssh $SSH_OPTS "$REMOTE_HOST" "bash $DEPLOY_DIR/scripts/rollback.sh --local"
fi
