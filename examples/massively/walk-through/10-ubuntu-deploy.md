# 10 — Ubuntu Deployment Guide

## Prerequisites

- Ubuntu 22.04+ server (this guide uses 24.04)
- SSH access as root or a sudo user
- A domain name pointing at the server's IP (for TLS)

## 1. Install PureBasic

```bash
# Download PureBasic 6.x for Linux from https://www.purebasic.com/
# (requires a valid license or evaluation copy)
wget https://your-download-link/purebasic-6.x.x-linux.tar.gz
tar -xzf purebasic-6.x.x-linux.tar.gz -C /opt/purebasic
export PUREBASIC_HOME="/opt/purebasic"
echo 'export PUREBASIC_HOME="/opt/purebasic"' >> ~/.bashrc
```

## 2. Install Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

## 3. Clone the repos

```bash
mkdir -p /opt/src && cd /opt/src
git clone https://github.com/Jedt3D/PureSimple
git clone https://github.com/Jedt3D/PureSimpleHTTPServer
git clone https://github.com/Jedt3D/pure_jinja
```

## 4. Extract static assets

```bash
cd /opt/src/PureSimple
unzip examples/html5up-massively.zip "assets/*" "images/bg.jpg" "images/overlay.png" -d /tmp/massively
mkdir -p /opt/massively/static/{css,js,webfonts,images}
cp /tmp/massively/assets/css/*      /opt/massively/static/css/
cp /tmp/massively/assets/js/*       /opt/massively/static/js/
cp /tmp/massively/assets/webfonts/* /opt/massively/static/webfonts/
cp /tmp/massively/images/bg.jpg     /opt/massively/static/images/
cp /tmp/massively/images/overlay.png /opt/massively/static/images/
```

## 5. Configure `.env`

```bash
cat > /opt/massively/.env <<EOF
PORT=8080
MODE=release
ADMIN_USER=admin
ADMIN_PASS=$(openssl rand -base64 16)
EOF
```

## 6. Compile

```bash
cd /opt/src/PureSimple
$PUREBASIC_HOME/compilers/pbcompiler examples/massively/main.pb -o /opt/massively/app
```

## 7. Copy templates

```bash
cp -r examples/massively/templates /opt/massively/templates
```

Update `_tplDir` in `main.pb` to `"templates/"` before compiling for production,
or adjust the path to be relative to where the binary runs.

## 8. Systemd service

Create `/etc/systemd/system/massively.service`:

```ini
[Unit]
Description=Wild & Still — PureSimple blog
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/massively
EnvironmentFile=/opt/massively/.env
ExecStart=/opt/massively/app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable massively
sudo systemctl start massively
sudo systemctl status massively
```

## 9. Caddy config

```bash
sudo cp /opt/src/PureSimple/examples/massively/Caddyfile /etc/caddy/Caddyfile
# Edit: replace "yourdomain.com" with your actual domain
sudo nano /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## 10. Health check

```bash
curl http://localhost:8080/health
# Expected: {"status":"ok"}

curl https://yourdomain.com/health
# Expected: {"status":"ok"} (via Caddy + TLS)
```

## Rollback

```bash
# If a new build breaks things:
sudo systemctl stop massively
cp /opt/massively/app.bak /opt/massively/app
sudo systemctl start massively
```

Always keep a `app.bak` before deploying:
```bash
cp /opt/massively/app /opt/massively/app.bak
```
