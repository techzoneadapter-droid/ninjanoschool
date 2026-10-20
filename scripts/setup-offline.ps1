param(
    [switch]$ValidateOnly,
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Require-Tool([string]$name, [string]$help) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing $name. $help"
    }
}
function Check-Exit([string]$task) {
    if ($LASTEXITCODE -ne 0) { throw "$task failed (exit code $LASTEXITCODE)" }
}
function New-HexSecret([int]$size) {
    $bytes = New-Object byte[] $size
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) }
    finally { $rng.Dispose() }
    return [BitConverter]::ToString($bytes).Replace('-', '')
}

$required = @(
    'compose.yaml', '.env.example', 'database-sql/nsohuyda_data (1).sql',
    'database-sql/nsohuyda_account (1).sql', 'scripts/prepare_offline_sql.py',
    'scripts/init-local-db.sh', 'build.xml'
)
foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $name))) {
        throw "Missing project file: $name"
    }
}
if ($ValidateOnly) {
    Write-Host "Windows offline setup files: OK" -ForegroundColor Green
    exit 0
}
Write-Host "[1/6] Checking prerequisites (all run locally)" -ForegroundColor Cyan
Require-Tool 'docker' 'Install Docker Desktop, enable WSL2 and start Docker Desktop: https://www.docker.com/products/docker-desktop/'
Require-Tool 'java' 'Install JDK 8: https://adoptium.net/temurin/releases/?version=8'
if (-not $SkipBuild) {
    Require-Tool 'ant' 'Install Apache Ant and add it to PATH: https://ant.apache.org/bindownload.cgi'
}
$py = $null
if (Get-Command 'py' -ErrorAction SilentlyContinue) {
    & py -3 --version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $py = @('py', '-3') }
}
if (-not $py -and (Get-Command 'python' -ErrorAction SilentlyContinue)) {
    & python --version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $py = @('python') }
}
if (-not $py) { throw 'Install Python 3: https://www.python.org/downloads/windows/ (tick Add Python to PATH)' }
$javaVersion = (& cmd.exe /c "java -version 2>&1" | Out-String)
if ($javaVersion -notmatch 'version "1[.]8[.]|version "8[.]') {
    throw "This legacy backend must be built/tested with Java 8. Found: $javaVersion"
}
& docker compose version | Out-Null
Check-Exit 'Docker Compose'
& docker info --format '{{.ServerVersion}}' | Out-Null
Check-Exit 'Docker Desktop (start it and wait for Engine to be ready)'

Write-Host "[2/6] Preparing private local secrets" -ForegroundColor Cyan
$offlineDir = Join-Path $root '.offline'
$generatedDir = Join-Path $offlineDir 'generated'
New-Item -Force -ItemType Directory $generatedDir | Out-Null
$envFile = Join-Path $root '.env'
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path -LiteralPath $envFile)) {
    $template = [System.IO.File]::ReadAllText((Join-Path $root '.env.example'))
    $template = [regex]::Replace($template, '(?m)^NSO_DB_ROOT_PASSWORD=.*$', "NSO_DB_ROOT_PASSWORD=$(New-HexSecret 24)")
    $template = [regex]::Replace($template, '(?m)^NSO_MYSQL_PASSWORD=.*$', "NSO_MYSQL_PASSWORD=$(New-HexSecret 24)")
    [System.IO.File]::WriteAllText($envFile, $template, $utf8)
    Write-Host "Created local .env (ignored by Git)."
}
$envLines = [System.IO.File]::ReadAllLines($envFile)
foreach ($key in @('NSO_DB_ROOT_PASSWORD', 'NSO_MYSQL_PASSWORD')) {
    if (-not ($envLines | Where-Object { $_ -match ('^' + $key + '=[A-Za-z0-9]{20,}$') })) {
        throw "Missing/weak $key in private .env. Use 20+ alphanumeric characters."
    }
}
$credsFile = Join-Path $offlineDir 'test-account.txt'
$user = 'testninja'
if (Test-Path -LiteralPath $credsFile) {
    $accountPass = ((Get-Content -LiteralPath $credsFile | Where-Object { $_ -like 'password=*' } | Select-Object -First 1) -split '=', 2)[1]
    if ($accountPass -notmatch '^[A-F0-9]{24,}$') {
        throw "Invalid existing offline test account file; refusing to overwrite credentials."
    }
} else {
    $accountPass = New-HexSecret 12
    $lines = "username=$user" + [Environment]::NewLine + "password=$accountPass" + [Environment]::NewLine
    [System.IO.File]::WriteAllText($credsFile, $lines, $utf8)
}
$demoSqlPath = Join-Path $generatedDir 'demo-account.sql'
$demoSql = "INSERT INTO player (id,username,password,ninja,status,ban) VALUES (1,'$user','$accountPass','[]',0,0);"
[System.IO.File]::WriteAllText($demoSqlPath, $demoSql, $utf8)

$driverDir = Join-Path $offlineDir 'drivers'
New-Item -Force -ItemType Directory $driverDir | Out-Null
$driverJar = Join-Path $driverDir 'mariadb-java-client-2.7.13.jar'
if (-not (Test-Path -LiteralPath $driverJar)) {
    Write-Host "Fetching MariaDB Connector/J 2.7.13 once from Maven Central ..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri 'https://repo.maven.apache.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.7.13/mariadb-java-client-2.7.13.jar' -OutFile $driverJar -UseBasicParsing
}
if ((Get-Item -LiteralPath $driverJar).Length -lt 300000) {
    throw "MariaDB Connector/J download incomplete. Delete the incomplete local JAR and retry."
}

Write-Host "[3/6] Generating safe game data + EMPTY account schema" -ForegroundColor Cyan
if ($py.Count -eq 2) {
    & py -3 scripts/prepare_offline_sql.py
} else {
    & python scripts/prepare_offline_sql.py
}
Check-Exit 'SQL sanitizer'

Write-Host "[4/6] Starting private MariaDB on 127.0.0.1" -ForegroundColor Cyan
& docker compose config --quiet
Check-Exit 'Docker Compose configuration'
& docker compose up -d db
Check-Exit 'MariaDB launch'
$container = ((& docker compose ps -q db | Select-Object -First 1) | Out-String).Trim()
if (-not $container) { throw 'Cannot find database container' }
$healthy = $false
for ($i = 0; $i -lt 60; $i++) {
    $health = ((& docker inspect --format '{{.State.Health.Status}}' $container) | Out-String).Trim()
    if ($health -eq 'healthy') { $healthy = $true; break }
    if ($health -eq 'unhealthy') { throw 'MariaDB healthcheck failed. Run: docker compose logs db' }
    Start-Sleep -Seconds 2
}
if (-not $healthy) { throw 'MariaDB healthcheck timed out. Run: docker compose logs db' }

Write-Host "[5/6] Importing reference tables without old accounts" -ForegroundColor Cyan
$uploads = @(
    @((Join-Path $generatedDir 'game_data.sql'), '/tmp/nso-game-data.sql'),
    @((Join-Path $generatedDir 'account_schema.sql'), '/tmp/nso-account-schema.sql'),
    @($demoSqlPath, '/tmp/nso-demo-account.sql'),
    @((Join-Path $root 'scripts/init-local-db.sh'), '/tmp/nso-init-local-db.sh')
)
foreach ($item in $uploads) {
    $destination = ('{0}:{1}' -f $container, $item[1])
    & docker cp $item[0] $destination
    Check-Exit 'Copy SQL to local DB'
}
& docker exec $container sh /tmp/nso-init-local-db.sh
Check-Exit 'Initialize empty offline databases'

if (-not $SkipBuild) {
    Write-Host "[6/6] Building CURRENT Java source with Ant" -ForegroundColor Cyan
    & ant -noinput clean jar
    Check-Exit 'Compile server'
    if (-not (Test-Path 'dist/NSO-HUYDAT.jar')) { throw 'Missing compiled JAR' }
} else {
    Write-Host "[6/6] Build skipped by explicit -SkipBuild flag" -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'LOCAL OFFLINE SETUP COMPLETE' -ForegroundColor Green
Write-Host '  Game listener: 127.0.0.1:14444'
Write-Host '  Local account: see .offline/test-account.txt (never upload this file)'
Write-Host '  Client: NOT included in this backend-only repo; needs a separately verified compatible client.'
Write-Host '  Next: run.bat or TEST-NINJA-SCHOOL.cmd to start game server.'
