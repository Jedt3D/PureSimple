# 09 — Static Files and Caddy

## Why Caddy serves static files

PureSimple (via PureSimpleHTTPServer) can serve files, but for a production
blog with CSS, JS, and dozens of webfonts, a dedicated server is better:

- **Cache-Control headers** set automatically by Caddy
- **If-None-Match / ETag** support for conditional requests
- **Range requests** for large assets
- **Gzip compression** handled before bytes leave the machine
- **No PureBasic thread blocked** waiting for disk I/O

The rule is: **Caddy owns `/static/*`, PureSimple owns everything else.**

## Caddyfile structure

```caddyfile
yourdomain.com {
    # Static assets served directly — never hit PureSimple
    handle /static/* {
        root * /opt/massively
        file_server
    }

    # Dynamic routes proxy to PureSimple on :8080
    handle {
        reverse_proxy localhost:8080
    }

    encode gzip

    log {
        output file /var/log/caddy/massively-access.log
        format json
    }
}
```

`root * /opt/massively` means Caddy looks for `/static/css/main.css` at
`/opt/massively/static/css/main.css` on disk.

## Production directory layout

```
/opt/massively/
  app               Compiled PureBasic binary
  .env              Production config (real ADMIN_PASS, etc.)
  db/
    blog.db         SQLite database
  static/           Caddy serves this subtree
    css/
    js/
    webfonts/
    images/
  templates/        Jinja2 templates (read by PureSimple at runtime)
```

## Template path in production

In `main.pb`, `_tplDir` is set to `"examples/massively/templates/"` for
local development. When deploying to `/opt/massively/`, change this to
`"templates/"` (or set it via `.env` and `Config::Get`).

## TLS (HTTPS)

Caddy provisions Let's Encrypt certificates automatically when you set a real
domain name. For local testing, use `:80` or `:443` with a self-signed cert.

## Systemd + Caddy reload

After updating `Caddyfile`:
```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```
