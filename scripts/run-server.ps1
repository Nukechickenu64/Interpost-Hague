# Run Marrow server with DreamDaemon (Windows)
param(
    [int]$Port = 8000,
    [string]$DmPath = "C:\\Program Files (x86)\\BYOND\\bin\\DreamDaemon.exe",
    [switch]$Trusted = $true,
    [switch]$Invisible = $true
)

$flags = @()
if ($Trusted) { $flags += "-trusted" }
if ($Invisible) { $flags += "-invisible" }
$flags += "-logself"

$dmb = Join-Path $PSScriptRoot "..\Marrow.dmb"
if (-not (Test-Path $dmb)) {
    Write-Error "DMB not found at $dmb. Compile Marrow.dme first."
    exit 1
}

& "$DmPath" $dmb $Port $($flags -join ' ')