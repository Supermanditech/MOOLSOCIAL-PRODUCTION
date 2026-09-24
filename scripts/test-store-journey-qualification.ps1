$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('store-gate-' + [guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $root
$null = New-Item -ItemType Directory -Path (Join-Path $root 'config')
$registryPath=Join-Path $root 'config/codex-development-regression-registry.json'
$registry=@{entries=@(@{id='REG-20260906-4499-STORE-REVIEW-TEST-CONTRACT-AND-OUTPUT-RECOVERY';storeJourneyLocalBlockers=@();storeJourneyDeviceDependencies=@()})}
$registry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath
$log = Join-Path $root 'test-events.jsonl'
$events = @(
  @{type='testStart';test=@{id=1;name='STORE-PARITY landscape whole screen'}},
  @{type='testDone';testID=1;result='success';skipped=$false},
  @{type='testStart';test=@{id=2;name='STORE-PARITY single Sales action'}},
  @{type='testDone';testID=2;result='success';skipped=$false},
  @{type='testStart';test=@{id=3;name='Store View v2 - compact large text, signals and keyboard'}},
  @{type='testDone';testID=3;result='success';skipped=$false},
  @{type='testStart';test=@{id=4;name='counter isolation refused save retains bill and recovers 1.0'}},
  @{type='testDone';testID=4;result='success';skipped=$false},
  @{type='testStart';test=@{id=5;name='counter isolation refused save retains bill and recovers 2.0'}},
  @{type='testDone';testID=5;result='success';skipped=$false},
  @{type='done';success=$true}
)
$events | ForEach-Object { $_ | ConvertTo-Json -Depth 5 -Compress } | Set-Content -LiteralPath $log
$proof = @{path='test-events.jsonl';sha256=(Get-FileHash $log).Hash}
$hash = 'A' * 64
$cases = @('store-home-landscape','sales-single-action','catalogue-save-stock','manual-save-stock',
  'csv-save-stock','stock-pos-photo-identity','invoice-create-relaunch','receipt-and-document') |
  ForEach-Object { @{id=$_;state='passed';dataOrigin='retailer-saved';storeId='test-gate-only';
    evidence=@($proof);productId='gate-test';originalPhotoSha256=$hash;savedPhotoSha256=$hash;posPhotoSha256=$hash} }
$state = @{oppoQualification=@{apkSha256=$hash};storeJourneyQualification=@{
  schemaVersion=1;sourceFingerprint='source';runtimeDefines=@('REVIEW=true');openLocalDefects=@();
  host=@{exitCode=0;machineLog=$proof};device=@{apkSha256=$hash;serial='2b3e0f71';openDefects=@();cases=@($cases)} }}
$script:checks=0
function Check([string]$name, [scriptblock]$mutate, [bool]$reject, [string]$phase='DeviceQualification') {
  $copy=$state | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  & $mutate $copy
  $failed=$false
  try { & "$PSScriptRoot/check-store-journey-qualification.ps1" -State $copy -RepositoryRoot $root -SourceFingerprint source -RuntimeDefine 'REVIEW=true' -Phase $phase | Out-Null }
  catch { $failed=$true }
  if ($failed -ne $reject) { throw "Unexpected gate outcome: $name" }
  $script:checks++
}
Check missing {param($s) $s.storeJourneyQualification=$null} $true
Check local-defect {param($s) $s.storeJourneyQualification.openLocalDefects=@('invoice-ledger')} $true PreBuild
Check undeclared {param($s) $s.storeJourneyQualification.openLocalDefects=$null} $true PreBuild
Check stale {param($s) $s.storeJourneyQualification.sourceFingerprint='old'} $true
Check runtime {param($s) $s.storeJourneyQualification.runtimeDefines=@('REVIEW=false')} $true
Check exit {param($s) $s.storeJourneyQualification.host.exitCode=1} $true
Check hash {param($s) $s.storeJourneyQualification.host.machineLog.sha256='bad'} $true
Check escape {param($s) $s.storeJourneyQualification.host.machineLog.path='../other'} $true
Check apk {param($s) $s.storeJourneyQualification.device.apkSha256='B'*64} $true
Check device {param($s) $s.storeJourneyQualification.device.serial='redmi'} $true
Check open {param($s) $s.storeJourneyQualification.device.openDefects=@('AP-S1-001')} $true
Check absent {param($s) $s.storeJourneyQualification.device.cases=@()} $true
Check pending {param($s) $s.storeJourneyQualification.device.cases[0].state='pending'} $true
Check synthetic {param($s) $s.storeJourneyQualification.device.cases[0].dataOrigin='fixture'} $true
Check photo {param($s) $s.storeJourneyQualification.device.cases[5].posPhotoSha256='B'*64} $true
Check host-only {param($s) $s.storeJourneyQualification.device=$null} $false PreBuild
Check valid {} $false
# Required skipped cases must fail even when the runner reports overall success.
$events[1].skipped=$true
$events | ForEach-Object { $_ | ConvertTo-Json -Depth 5 -Compress } | Set-Content -LiteralPath $log
$state.storeJourneyQualification.host.machineLog.sha256=(Get-FileHash $log).Hash
Check skipped {} $true PreBuild
$events[1].skipped=$false
$events | ForEach-Object { $_ | ConvertTo-Json -Depth 5 -Compress } | Set-Content -LiteralPath $log
$state.storeJourneyQualification.host.machineLog.sha256=(Get-FileHash $log).Hash
$registry.entries[0].storeJourneyLocalBlockers=@('invoice-ledger-recovery')
$registry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath
Check canonical-local {} $true PreBuild
$registry.entries[0].storeJourneyLocalBlockers=@()
$registry.entries[0].storeJourneyDeviceDependencies=@('photo-continuity')
$registry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath
Check canonical-device {} $true
Write-Output "$script:checks gate contract checks passed. Generated contract fixtures retained at $root; not application/device evidence."
