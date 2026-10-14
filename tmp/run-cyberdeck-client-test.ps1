& 'C:/Program Files (x86)/BYOND/bin/dm.exe' cyberdeck_test.dme 2>&1 | Tee-Object -FilePath tmp/cyberdeck-test-build.log
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$testLogOffset = (Get-Item -LiteralPath cyberdeck_test.log).Length
$testServer = Start-Process -FilePath 'C:/Program Files (x86)/BYOND/bin/dd.exe' -ArgumentList 'cyberdeck_test.dmb 13377 -invisible -trusted -close -logself -params cyberdeck_client=1' -WindowStyle Hidden -PassThru
$testSeeker = $null
$testWatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
 while (-not $testServer.HasExited -and $testWatch.Elapsed.TotalSeconds -lt 260) {
  $testLogStream = [System.IO.File]::Open('C:/Users/nukec/Documents/GitHub/Interpost-Hague/cyberdeck_test.log', 'Open', 'Read', 'ReadWrite')
  $null = $testLogStream.Seek($testLogOffset, 'Begin')
  $testLogReader = [System.IO.StreamReader]::new($testLogStream)
  $testText = $testLogReader.ReadToEnd()
  $testLogReader.Dispose()
  if (-not $testSeeker -and $testText.Contains('The start-up is finished')) {
   $testSeeker = Start-Process -FilePath 'C:/Program Files (x86)/BYOND/bin/dreamseeker.exe' -ArgumentList 'byond://127.0.0.1:13377' -WindowStyle Hidden -PassThru
   Write-Output 'Connected test Dream Seeker after server initialization.'
  }
  if ($testText.Contains('Caught ')) {
   Write-Output ($testText -split "`n" | Select-Object -Last 15)
   break
  }
  Start-Sleep -Milliseconds 500
 }
 $testText | Set-Content -LiteralPath tmp/cyberdeck-connected-results.log
} finally {
 if ($testSeeker -and -not $testSeeker.HasExited) { Stop-Process -Id $testSeeker.Id }
 if (-not $testServer.HasExited) { Stop-Process -Id $testServer.Id }
}
