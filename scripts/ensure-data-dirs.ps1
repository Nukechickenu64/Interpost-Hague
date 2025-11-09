# Ensure runtime directories exist
$base = Join-Path $PSScriptRoot ".."
$paths = @(
  Join-Path $base "data",
  Join-Path $base "data/logs",
  Join-Path $base "data/player_saves"
)
foreach ($p in $paths) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
Write-Host "Ensured data directories exist."
