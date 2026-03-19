#!/usr/bin/env bash
# setup-server.sh — One-time provisioning for the PureSimple production server
# Run once on a fresh Ubuntu 24 server as root:
#   bash deploy/setup-server.sh
#
# Expects:
#   - PureBasic installer archive at /tmp/purebasic_linux.tar.gz
#     (download manually from https://www.purebasic.com/download.shtml)
#   - SSH public key already in /root/.ssh/authorized_keys

set -euo pipefail

DEPLOY_DIR="/opt/puresimple"
PUREBASIC_HOME="/opt/purebasic"
PUREBASIC_ARCHIVE="${PUREBASIC_ARCHIVE:-/tmp/purebasic_linux.tar.gz}"

# Repos — update URLs to your actual org/forks
REPO_PURESIMPLE="https://github.com/your-org/PureSimple.git"
REPO_HTTP_SERVER="https://github.com/your-org/PureSimpleHTTPServer.git"
REPO_PUREJINJA="https://github.com/your-org/PureJinja.git"

log() { echo "[setup] $*"; }

# ------------------------------------------------------------------
# 1. System packages
# ------------------------------------------------------------------
log "Updating apt and installing dependencies…"
apt-get update -qq
apt-get install -y -qq git curl unzip debian-keyring debian-archive-keyring apt-transport-https

# ------------------------------------------------------------------
# 2. Caddy
# ------------------------------------------------------------------
if ! command -v caddy &>/dev/null; then
  log "Installing Caddy…"
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | tee /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -qq && apt-get install -y -qq caddy
fi

# ------------------------------------------------------------------
# 3. PureBasic
# ------------------------------------------------------------------
if [[ ! -f "$PUREBASIC_HOME/compilers/pbcompiler" ]]; then
  log "Installing PureBasic to $PUREBASIC_HOME…"
  mkdir -p "$PUREBASIC_HOME"
  tar -xzf "$PUREBASIC_ARCHIVE" -C "$PUREBASIC_HOME" --strip-components=1
  ln -sf "$PUREBASIC_HOME/compilers/pbcompiler" /usr/local/bin/pbcompiler
fi

# ------------------------------------------------------------------
# 4. Clone repos
# ------------------------------------------------------------------
log "Creating deploy directory $DEPLOY_DIR…"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

clone_or_pull() {
  local dir="$1" url="$2"
  if [[ -d "$dir/.git" ]]; then
    log "Pulling $dir…"
    git -C "$dir" pull origin main
  else
    log "Cloning $url → $dir…"
    git clone "$url" "$dir"
  fi
}

clone_or_pull "$DEPLOY_DIR"                    "$REPO_PURESIMPLE"
clone_or_pull "$DEPLOY_DIR/../PureSimpleHTTPServer" "$REPO_HTTP_SERVER"
clone_or_pull "$DEPLOY_DIR/../PureJinja"       "$REPO_PUREJINJA"

# ------------------------------------------------------------------
# 5. Caddy config
# ------------------------------------------------------------------
log "Installing Caddyfile…"
mkdir -p /etc/caddy /var/log/caddy
cp "$DEPLOY_DIR/deploy/Caddyfile" /etc/caddy/Caddyfile

# ------------------------------------------------------------------
# 6. systemd unit
# ------------------------------------------------------------------
log "Installing systemd unit…"
cp "$DEPLOY_DIR/deploy/puresimple.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable puresimple
systemctl enable caddy

# ------------------------------------------------------------------
# 7. www-data ownership
# ------------------------------------------------------------------
chown -R www-data:www-data "$DEPLOY_DIR"

log ""
log "Server provisioning complete."
log "Next steps:"
log "  1. Edit /etc/caddy/Caddyfile — replace 'yourdomain.com' with your real domain"
log "  2. Run ./scripts/deploy.sh from your local machine to build and start the app"
