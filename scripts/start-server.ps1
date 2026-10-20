$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
if (Test-Path ".env") {
    foreach ($line in (Get-Content ".env")) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $value = $Matches[2].Trim()
            if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($Matches[1], $value, "Process")
        }
    }
}
if ([string]::IsNullOrWhiteSpace($env:NSO_MYSQL_PASSWORD)) {
    throw "Set NSO_MYSQL_PASSWORD in a private .env file before starting the server."
}
& java "-Dfile.encoding=UTF-8" "-Xms256m" "-Xmx1024m" "-jar" "dist/NSO-HUYDAT.jar"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
