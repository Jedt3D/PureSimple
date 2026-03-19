#!/usr/bin/env bash
# new-project.sh — Scaffold a new PureSimple application
#
# Usage:
#   ./scripts/new-project.sh myapp
#   ./scripts/new-project.sh myapp /path/to/parent/dir
#
# Creates:
#   <name>/
#     main.pb            — entry point with routes, config, and logging
#     .env               — local environment variables (not committed)
#     .env.example       — documented example environment variables
#     .gitignore         — excludes compiled output and .env
#     templates/
#       index.html       — starter Jinja HTML template
#     static/            — placeholder for static assets

set -euo pipefail

# ----------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------
APP_NAME="${1:-}"
PARENT_DIR="${2:-.}"

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <app-name> [parent-dir]"
  echo "Example: $0 myblog"
  exit 1
fi

TARGET="$PARENT_DIR/$APP_NAME"

if [[ -e "$TARGET" ]]; then
  echo "Error: '$TARGET' already exists."
  exit 1
fi

# ----------------------------------------------------------------
# Resolve path to PureSimple (relative to the new project)
# ----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURESIMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Compute relative path from TARGET to PURESIMPLE_DIR using Python (portable)
REL_PATH="$(python3 -c "import os.path; print(os.path.relpath('$PURESIMPLE_DIR', '$PARENT_DIR/$APP_NAME'))")"

# ----------------------------------------------------------------
# Create directory structure
# ----------------------------------------------------------------
mkdir -p "$TARGET/templates"
mkdir -p "$TARGET/static"

echo "Scaffolding '$APP_NAME' in $TARGET ..."

# ----------------------------------------------------------------
# main.pb
# ----------------------------------------------------------------
cat > "$TARGET/main.pb" << PBEOF
; $APP_NAME — PureSimple application
; Compile: \$PUREBASIC_HOME/compilers/pbcompiler main.pb -o $APP_NAME
; Run:     ./$APP_NAME

EnableExplicit

XIncludeFile "${REL_PATH}/src/PureSimple.pb"

; Load .env configuration
If Config::Load(".env")
  Log::Info(".env loaded")
Else
  Log::Warn("No .env file found — using built-in defaults")
EndIf

Protected port.i = Config::GetInt("PORT", 8080)
Protected mode.s = Config::Get("MODE", "debug")
Engine::SetMode(mode)

; ---- Global middleware ----
Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

; ---- Routes ----
Engine::GET("/", @IndexHandler())
Engine::GET("/health", @HealthHandler())

Log::Info("Starting $APP_NAME on :" + Str(port) + " [" + Engine::Mode() + "]")
Engine::Run(port)

; ---- Handlers ----

Procedure IndexHandler(*C.RequestContext)
  Ctx::Set(*C, "title", "$APP_NAME")
  Rendering::Render(*C, "index.html")
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::Text(*C, "OK")
EndProcedure
PBEOF

# ----------------------------------------------------------------
# .env (local, not committed)
# ----------------------------------------------------------------
cat > "$TARGET/.env" << ENVEOF
PORT=8080
MODE=debug
APP_NAME=$APP_NAME
ENVEOF

# ----------------------------------------------------------------
# .env.example (committed, documents available variables)
# ----------------------------------------------------------------
cat > "$TARGET/.env.example" << ENVEOF
# Copy this file to .env and fill in values
PORT=8080
MODE=debug          # debug | release | test
APP_NAME=$APP_NAME
# DB_PATH=data/app.db
# SECRET_KEY=change-me
ENVEOF

# ----------------------------------------------------------------
# .gitignore
# ----------------------------------------------------------------
cat > "$TARGET/.gitignore" << GIEOF
# PureBasic compiled output
$APP_NAME
$APP_NAME.exe
*.o
*.purebasic_tmp

# Environment
.env

# macOS
.DS_Store

# Logs
*.log
GIEOF

# ----------------------------------------------------------------
# templates/index.html
# ----------------------------------------------------------------
cat > "$TARGET/templates/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ title }}</title>
</head>
<body>
  <h1>Welcome to {{ title }}</h1>
  <p>Edit <code>main.pb</code> and <code>templates/index.html</code> to get started.</p>
</body>
</html>
HTMLEOF

# ----------------------------------------------------------------
# Done
# ----------------------------------------------------------------
echo ""
echo "Done! Your new PureSimple app is ready:"
echo ""
echo "  cd $TARGET"
echo "  \$PUREBASIC_HOME/compilers/pbcompiler main.pb -o $APP_NAME"
echo "  ./$APP_NAME"
echo ""
