#!/usr/bin/env bash
# deploy.sh — Local → production deploy pipeline for PureSimple
# Usage: ./scripts/deploy.sh
# Requires: SSH key at ~/.ssh/id_ed25519, PUREBASIC_HOME set on remote

set -euo pipefail

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
REMOTE_HOST="root@129.212.236.80"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no"
DEPLOY_DIR="/opt/puresimple"
SERVICE="puresimple.service"
HEALTH_URL="http://localhost:8080/health"
PUREBASIC_HOME="${PUREBASIC_HOME:-/opt/purebasic}"

# ------------------------------------------------------------------
# Helper
# ------------------------------------------------------------------
remote() {
  ssh $SSH_OPTS "$REMOTE_HOST" "$@"
}

log() {
  echo "[deploy] $*"
}

# ------------------------------------------------------------------
# 1. Pull latest code
# ------------------------------------------------------------------
log "Pulling latest code on remote…"
remote "cd $DEPLOY_DIR && git pull origin main"

# ------------------------------------------------------------------
# 2. Compile new binary
# ------------------------------------------------------------------
log "Compiling app_new…"
remote "cd $DEPLOY_DIR && $PUREBASIC_HOME/compilers/pbcompiler src/main.pb -o app_new"

# ------------------------------------------------------------------
# 3. Run test suite — abort deploy if any test fails
# ------------------------------------------------------------------
log "Running test suite…"
remote "cd $DEPLOY_DIR && $PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb -cl -o run_all_tmp && ./run_all_tmp; rc=\$?; rm -f run_all_tmp; exit \$rc"

# ------------------------------------------------------------------
# 4. Swap binaries
# ------------------------------------------------------------------
log "Stopping service…"
remote "systemctl stop $SERVICE || true"

log "Swapping binary (app → app.bak, app_new → app)…"
remote "cd $DEPLOY_DIR && cp -f app app.bak 2>/dev/null || true && mv -f app_new app"

# ------------------------------------------------------------------
# 5. Run migrations (no-op until P6)
# ------------------------------------------------------------------
log "Running migrations (no-op until P6)…"
remote "cd $DEPLOY_DIR && ./app --migrate 2>/dev/null || true"

# ------------------------------------------------------------------
# 6. Start service and health-check
# ------------------------------------------------------------------
log "Starting service…"
remote "systemctl start $SERVICE"

log "Waiting for health check…"
sleep 3

if remote "curl -sf $HEALTH_URL"; then
  log "DEPLOY OK — $HEALTH_URL responded 200"
else
  log "Health check FAILED — triggering rollback"
  ssh $SSH_OPTS "$REMOTE_HOST" "bash $DEPLOY_DIR/scripts/rollback.sh"
  exit 1
fi
