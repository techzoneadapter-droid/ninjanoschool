$ErrorActionPreference = 'Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
Write-Host "Ninja School - Windows local status" -ForegroundColor Cyan
Write-Host "Repo: $((Get-Location).Path)"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host ''
    & docker compose ps db
} else {
    Write-Host "Docker not installed."
}
$client = New-Object System.Net.Sockets.TcpClient
try {
    $attempt = $client.BeginConnect('127.0.0.1', 14444, $null, $null)
    if ($attempt.AsyncWaitHandle.WaitOne(1200)) {
        $client.EndConnect($attempt)
        Write-Host 'Game TCP port 127.0.0.1:14444: OPEN' -ForegroundColor Green
    } else {
        Write-Host 'Game TCP port 127.0.0.1:14444: CLOSED / NOT READY' -ForegroundColor Yellow
    }
} catch {
    Write-Host 'Game TCP port 127.0.0.1:14444: CLOSED / NOT READY' -ForegroundColor Yellow
} finally {
    $client.Close()
}
if (Test-Path '.offline/test-account.txt') {
    Write-Host "Offline test account exists. Read .offline/test-account.txt locally."
} else {
    Write-Host 'Offline test account not created yet.'
}
