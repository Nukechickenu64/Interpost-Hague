# Run Marrow server with DreamDaemon (Windows)
param(
    [int]$Port = 8000,
    [string]$DmPath = "C:\\Program Files (x86)\\BYOND\\bin\\DreamDaemon.exe",
    [switch]$Trusted = $true,
    [switch]$Invisible = $true
)

# DreamDaemon's embedded browser control is IE/Trident-based. Without this
# registry key (in the HKCU hive of the account actually running DreamDaemon,
# e.g. a service/scheduled-task account), it defaults to IE7 quirks mode and
# silently fails to render any HTML/CSS/JS - the exact "blank UI, works fine
# when I test locally" symptom, since local interactive testing usually runs
# under a different user profile that already has this key set.
$featureControlKey = "HKCU:\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION"
if (-not (Test-Path $featureControlKey)) {
    New-Item -Path $featureControlKey -Force | Out-Null
}
foreach ($exeName in @("DreamDaemon.exe", "dreamseeker.exe")) {
    New-ItemProperty -Path $featureControlKey -Name $exeName -Value 11001 -PropertyType DWord -Force | Out-Null
}

$flags = @()
if ($Trusted) { $flags += "-trusted" }
if ($Invisible) { $flags += "-invisible" }
$flags += "-logself"

$dmb = Join-Path $PSScriptRoot "..\Marrow.dmb"
if (-not (Test-Path $dmb)) {
    Write-Error "DMB not found at $dmb. Compile Marrow.dme first."
    exit 1
}

& "$DmPath" $dmb $Port @flags