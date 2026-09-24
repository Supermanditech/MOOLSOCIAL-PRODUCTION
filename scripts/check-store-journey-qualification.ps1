[CmdletBinding()]
param(
  [Parameter(Mandatory)][object]$State,
  [Parameter(Mandatory)][string]$RepositoryRoot,
  [Parameter(Mandatory)][string]$SourceFingerprint,
  [Parameter(Mandatory)][string[]]$RuntimeDefine,
  [ValidateSet('PreBuild','DeviceQualification')][string]$Phase = 'PreBuild'
)
$ErrorActionPreference = 'Stop'
function Require([bool]$ok, [string]$reason) {
  if (!$ok) { throw "Store journey qualification rejected: $reason" }
}
function Evidence([object]$item) {
  Require (![string]::IsNullOrWhiteSpace([string]$item.path)) 'Missing evidence path.'
  $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
  $path = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot ([string]$item.path)))
  Require ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) 'Evidence escaped repository.'
  Require (Test-Path -LiteralPath $path -PathType Leaf) 'Evidence does not exist.'
  Require ((Get-Item -LiteralPath $path).Length -gt 0) 'Evidence is empty.'
  Require ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq [string]$item.sha256) 'Evidence hash changed.'
  return $path
}
$q = $State.storeJourneyQualification
Require ($null -ne $q -and $q.schemaVersion -eq 1) 'Requirement-specific qualification is mandatory; aggregate pass counts are insufficient.'
Require ($null -ne $q.openLocalDefects -and @($q.openLocalDefects).Count -eq 0) 'An explicit empty local-defect list is required before building; unresolved regressions block the build.'
# Read known blockers independently: a new candidate receipt must not omit them.
$registryPath = Join-Path $RepositoryRoot 'config/codex-development-regression-registry.json'
Require (Test-Path -LiteralPath $registryPath -PathType Leaf) 'Canonical defect registry is missing.'
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$owner = @($registry.entries | Where-Object id -CEQ 'REG-20260906-4499-STORE-REVIEW-TEST-CONTRACT-AND-OUTPUT-RECOVERY')
Require ($owner.Count -eq 1) 'Canonical Store defect owner is missing or duplicated.'
Require ($null -ne $owner[0].storeJourneyLocalBlockers -and @($owner[0].storeJourneyLocalBlockers).Count -eq 0) 'Canonical Store local defects remain open; a candidate cannot override them.'
if ($Phase -eq 'DeviceQualification') {
  Require ($null -ne $owner[0].storeJourneyDeviceDependencies -and @($owner[0].storeJourneyDeviceDependencies).Count -eq 0) 'Canonical Store device dependencies remain open.'
}
Require ([string]$q.sourceFingerprint -ceq $SourceFingerprint) 'Qualification is for different source.'
$expected = @($RuntimeDefine | Sort-Object -CaseSensitive)
$actual = @($q.runtimeDefines | Sort-Object -CaseSensitive)
Require (($expected -join "`n") -ceq ($actual -join "`n")) 'Qualification runtime defines differ from APK.'
Require ($q.host.exitCode -eq 0) 'Host suite did not exit successfully.'
$log = Evidence $q.host.machineLog
$events = @(Get-Content -LiteralPath $log | ForEach-Object { $_ | ConvertFrom-Json })
$done = @($events | Where-Object type -eq 'done')
Require ($done.Count -eq 1 -and $done[0].success -eq $true) 'Missing successful machine test completion.'
Require (@($events | Where-Object type -eq 'error').Count -eq 0) 'Host test error recorded.'
# These names are assertions in the real Store screen suite, not screenshot titles.
$requiredHost = @('STORE-PARITY landscape whole screen', 'STORE-PARITY single Sales action',
  'Store View v2 - compact large text, signals and keyboard',
  'counter isolation refused save retains bill and recovers 1.0',
  'counter isolation refused save retains bill and recovers 2.0')
foreach ($name in $requiredHost) {
  $starts = @($events | Where-Object { $_.type -eq 'testStart' -and $_.test.name -ceq $name })
  Require ($starts.Count -eq 1) "Required host case missing or duplicated: $name"
  $results = @($events | Where-Object { $_.type -eq 'testDone' -and $_.testID -eq $starts[0].test.id })
  Require ($results.Count -eq 1 -and $results[0].result -ceq 'success' -and $results[0].skipped -eq $false) "Required host case not passed: $name"
}
if ($Phase -eq 'DeviceQualification') {
  $required = @('store-home-landscape','sales-single-action','catalogue-save-stock',
    'manual-save-stock','csv-save-stock','stock-pos-photo-identity',
    'invoice-create-relaunch','receipt-and-document')
  Require ([string]$q.device.apkSha256 -ceq [string]$State.oppoQualification.apkSha256 -and
    [string]$q.device.apkSha256 -cmatch '^[A-F0-9]{64}$') 'Device evidence belongs to another APK.'
  Require ([string]$q.device.serial -ceq '2b3e0f71') 'Device evidence is not OPPO.'
  Require (@($q.device.openDefects).Count -eq 0) 'Open defects prevent device closure.'
  foreach ($id in $required) {
    $cases = @($q.device.cases | Where-Object id -CEQ $id)
    Require ($cases.Count -eq 1) "Required device case missing or duplicated: $id"
    $case = $cases[0]
    Require ([string]$case.state -ceq 'passed') "Device case not passed: $id"
    Require ([string]$case.dataOrigin -ceq 'retailer-saved') "Synthetic/unknown records cannot qualify: $id"
    Require (![string]::IsNullOrWhiteSpace([string]$case.storeId)) "Missing Store scope: $id"
    Require (@($case.evidence).Count -gt 0) "No physical evidence: $id"
    foreach ($item in $case.evidence) { $null = Evidence $item }
    if ($id -eq 'stock-pos-photo-identity') {
      Require (![string]::IsNullOrWhiteSpace([string]$case.productId)) 'Photo proof lacks product identity.'
      Require ([string]$case.originalPhotoSha256 -cmatch '^[A-F0-9]{64}$' -and
        $case.originalPhotoSha256 -ceq $case.savedPhotoSha256 -and
        $case.originalPhotoSha256 -ceq $case.posPhotoSha256) 'Original/saved/POS media identity is unproven.'
    }
  }
}
Write-Output "Store journey qualification passed: $Phase. Host fixtures are not device or production acceptance."
