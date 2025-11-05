# Compile the BYOND project and summarize errors/warnings
param(
    [string]$DME = "Interpost-Hague.dme",
    [string]$DmPath = "C:\\Program Files (x86)\\BYOND\\bin\\dm.exe"
)

if (-not (Test-Path $DmPath)) {
    Write-Error "dm.exe not found at: $DmPath"
    exit 1
}

& $DmPath $DME 2>&1 | Tee-Object -Variable buildOut | Out-Host
$errs = ($buildOut | Select-String -Pattern '(?i)\berror\b').Count
$warns = ($buildOut | Select-String -Pattern '(?i)\bwarning\b').Count
Write-Output ("DM summary: Errors={0} Warnings={1}" -f $errs,$warns)

if ($errs -gt 0) { exit 1 }
