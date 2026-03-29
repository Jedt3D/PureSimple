# new-project.ps1 -- Scaffold a new PureSimple application
#
# Usage:
#   .\scripts\new-project.ps1 myapp
#   .\scripts\new-project.ps1 myapp C:\path\to\parent\dir
#
# Creates:
#   <name>\
#     main.pb            -- entry point with routes, config, and logging
#     .env               -- local environment variables (not committed)
#     .env.example       -- documented example environment variables
#     .gitignore         -- excludes compiled output and .env
#     templates\
#       index.html       -- starter Jinja HTML template
#     static\            -- placeholder for static assets

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------
param(
    [Parameter(Position = 0)]
    [string]$AppName,

    [Parameter(Position = 1)]
    [string]$ParentDir = "."
)

if (-not $AppName) {
    Write-Host "Usage: .\new-project.ps1 <app-name> [parent-dir]"
    Write-Host "Example: .\new-project.ps1 myblog"
    exit 1
}

$Target = Join-Path $ParentDir $AppName

if (Test-Path $Target) {
    Write-Host "Error: '$Target' already exists."
    exit 1
}

# ----------------------------------------------------------------
# Resolve path to PureSimple (relative to the new project)
# ----------------------------------------------------------------
$PureSimpleDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TargetFull    = (New-Item -ItemType Directory -Path $Target -Force).FullName

# Compute relative path from TARGET to PURESIMPLE_DIR
# Use Push-Location trick for PowerShell 5.1 compatibility
Push-Location $TargetFull
try {
    $RelPath = (Resolve-Path -Relative $PureSimpleDir)
} finally {
    Pop-Location
}

# Normalise to forward slashes for PureBasic compatibility
$RelPath = $RelPath -replace '\\', '/'

# ----------------------------------------------------------------
# Create directory structure
# ----------------------------------------------------------------
New-Item -ItemType Directory -Path (Join-Path $Target "templates") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $Target "static")    -Force | Out-Null

Write-Host "Scaffolding '$AppName' in $Target ..."

# ----------------------------------------------------------------
# main.pb
# ----------------------------------------------------------------
$MainPb = @"
; $AppName -- PureSimple application
; Compile: `$PUREBASIC_HOME/compilers/pbcompiler main.pb -o $AppName
; Run:     ./$AppName

EnableExplicit

XIncludeFile "$RelPath/src/PureSimple.pb"

; Load .env configuration
If Config::Load(".env")
  Log::Info(".env loaded")
Else
  Log::Warn("No .env file found -- using built-in defaults")
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

Log::Info("Starting $AppName on :" + Str(port) + " [" + Engine::Mode() + "]")
Engine::Run(port)

; ---- Handlers ----

Procedure IndexHandler(*C.RequestContext)
  Ctx::Set(*C, "title", "$AppName")
  Rendering::Render(*C, "index.html")
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::Text(*C, "OK")
EndProcedure
"@
Set-Content -Path (Join-Path $Target "main.pb") -Value $MainPb -Encoding UTF8

# ----------------------------------------------------------------
# .env (local, not committed)
# ----------------------------------------------------------------
$EnvFile = @"
PORT=8080
MODE=debug
APP_NAME=$AppName
"@
Set-Content -Path (Join-Path $Target ".env") -Value $EnvFile -Encoding UTF8

# ----------------------------------------------------------------
# .env.example (committed, documents available variables)
# ----------------------------------------------------------------
$EnvExample = @"
# Copy this file to .env and fill in values
PORT=8080
MODE=debug          # debug | release | test
APP_NAME=$AppName
# DB_PATH=data/app.db
# SECRET_KEY=change-me
"@
Set-Content -Path (Join-Path $Target ".env.example") -Value $EnvExample -Encoding UTF8

# ----------------------------------------------------------------
# .gitignore
# ----------------------------------------------------------------
$GitIgnore = @"
# PureBasic compiled output
$AppName
$AppName.exe
*.o
*.purebasic_tmp

# Environment
.env

# macOS
.DS_Store

# Logs
*.log
"@
Set-Content -Path (Join-Path $Target ".gitignore") -Value $GitIgnore -Encoding UTF8

# ----------------------------------------------------------------
# templates/index.html
# ----------------------------------------------------------------
$IndexHtml = @"
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
"@
Set-Content -Path (Join-Path $Target "templates" "index.html") -Value $IndexHtml -Encoding UTF8

# ----------------------------------------------------------------
# Done
# ----------------------------------------------------------------
Write-Host ""
Write-Host "Done! Your new PureSimple app is ready:"
Write-Host ""
Write-Host "  cd $Target"
Write-Host "  `$PUREBASIC_HOME\Compilers\pbcompiler.exe main.pb -o $AppName.exe"
Write-Host "  .\$AppName.exe"
Write-Host ""
