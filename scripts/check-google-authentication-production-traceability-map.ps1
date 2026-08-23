[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$mapPath = Join-Path $root `
  'config/google-authentication-production-traceability-map.json'

function Assert-GoogleTraceability([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Google authentication traceability rejected: $Message"
  }
}

Assert-GoogleTraceability `
  (Test-Path -LiteralPath $mapPath -PathType Leaf) `
  'the permanent mapper is missing.'

$raw = Get-Content -LiteralPath $mapPath -Raw
try {
  $map = $raw | ConvertFrom-Json
} catch {
  throw 'Google authentication traceability rejected: the mapper is not valid JSON.'
}

Assert-GoogleTraceability ([int]$map.schemaVersion -eq 1) `
  'the schema version changed.'
Assert-GoogleTraceability `
  ([string]$map.scope -ceq 'google_sign_in_only') `
  'the mapper escaped Google-only scope.'

$requirements = @($map.requirements)
$expectedIds = 1..40 | ForEach-Object { 'G{0:d2}' -f $_ }
$actualIds = @($requirements | ForEach-Object { [string]$_.requirementId })
Assert-GoogleTraceability ($requirements.Count -eq 40) `
  'the mapper must contain exactly G01 through G40.'
Assert-GoogleTraceability `
  (@($actualIds | Sort-Object -Unique).Count -eq 40) `
  'requirement IDs are duplicated.'
Assert-GoogleTraceability `
  (-not (Compare-Object $expectedIds $actualIds)) `
  'the requirement ID set is incomplete or unexpected.'

$allowedStatuses = @('PASS', 'FAIL', 'NOT_VERIFIED', 'NOT_APPLICABLE')
$requiredTraceLayers = @(
  'externalConfiguration',
  'source',
  'plugin',
  'android',
  'generatedResources',
  'signing',
  'releaseApk',
  'runtimeTelemetry',
  'firebaseResult',
  'sessionUiResult'
)
$knownTickets = @{
  'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR' =
    'config/uaw-c34p-fix11-google-sign-in-oppo-forensic-repair-ticket.json'
  'UAW-C34P-FIX12-GOOGLE-FIREBASE-EXACT-CODE-PRESERVATION' =
    'config/uaw-c34p-fix12-google-firebase-exact-code-preservation-ticket.json'
  'UAW-C34P-FIX13-GOOGLE-FIREBASE-AUTH-APP-CHECK-ALIGNMENT' =
    'config/uaw-c34p-fix13-google-firebase-auth-app-check-alignment-ticket.json'
  'UAW-C34P-FIX14-GOOGLE-FIREBASE-IDENTITY-TOOLKIT-AVAILABILITY' =
    'config/uaw-c34p-fix14-google-firebase-identity-toolkit-availability-ticket.json'
  'UAW-C34P-FIX15-GOOGLE-IDENTITY-PLATFORM-REJECTION-CONTROLS' =
    'config/uaw-c34p-fix15-google-identity-platform-rejection-controls-ticket.json'
}

foreach ($requirement in $requirements) {
  $id = [string]$requirement.requirementId
  foreach ($property in @(
    'productionRequirement',
    'authoritativeSource',
    'requirementLevel',
    'evidenceLocation',
    'automatedCheck',
    'externalConsoleCheck',
    'runtimeCheck',
    'status',
    'blockingSeverity',
    'gatePhase',
    'fixTicketId',
    'reverifyWhen'
  )) {
    Assert-GoogleTraceability `
      ($null -ne $requirement.PSObject.Properties[$property]) `
      "$id is missing $property."
  }

  Assert-GoogleTraceability `
    ($allowedStatuses -ccontains [string]$requirement.status) `
    "$id has an invalid status."
  Assert-GoogleTraceability `
    (@($requirement.authoritativeSource).Count -gt 0) `
    "$id has no authoritative source."
  Assert-GoogleTraceability `
    (@($requirement.reverifyWhen).Count -gt 0) `
    "$id has no reverify trigger."

  foreach ($layer in $requiredTraceLayers) {
    $layerProperty = $requirement.trace.PSObject.Properties[$layer]
    Assert-GoogleTraceability `
      ($null -ne $layerProperty -and -not [string]::IsNullOrWhiteSpace(
        [string]$layerProperty.Value
      )) `
      "$id is missing the $layer trace."
  }

  $isP0Open = [string]$requirement.blockingSeverity -ceq 'P0' -and
    [string]$requirement.status -in @('FAIL', 'NOT_VERIFIED')
  if ($isP0Open) {
    Assert-GoogleTraceability `
      (-not [string]::IsNullOrWhiteSpace([string]$requirement.fixTicketId)) `
      "$id is an open P0 requirement without a fix ticket."
  }

  if (-not [string]::IsNullOrWhiteSpace([string]$requirement.fixTicketId)) {
    $ticketId = [string]$requirement.fixTicketId
    Assert-GoogleTraceability ($knownTickets.ContainsKey($ticketId)) `
      "$id references an unknown ticket."
    Assert-GoogleTraceability `
      (Test-Path -LiteralPath (Join-Path $root $knownTickets[$ticketId]) `
        -PathType Leaf) `
      "$id references a missing ticket owner."
  }
}

$preBuildBlockers = @(
  $requirements | Where-Object {
    [string]$_.gatePhase -ceq 'pre_build' -and
    [string]$_.blockingSeverity -ceq 'P0' -and
    [string]$_.status -notin @('PASS', 'NOT_APPLICABLE')
  }
)
$preBuildBlockerIds = @(
  $preBuildBlockers | ForEach-Object { [string]$_.requirementId }
)
Assert-GoogleTraceability ($preBuildBlockers.Count -eq 0) `
  ('P0 pre-build blockers remain: ' +
    (($preBuildBlockerIds | Sort-Object) -join ', '))

$acceptancePending = @(
  $requirements | Where-Object {
    [string]$_.gatePhase -ceq 'post_install_acceptance' -and
    [string]$_.status -eq 'NOT_VERIFIED'
  }
)
Assert-GoogleTraceability ($acceptancePending.Count -eq 4) `
  'the four real-device acceptance requirements are not isolated correctly.'
$acceptancePendingIds = @(
  $acceptancePending | ForEach-Object { [string]$_.requirementId }
)
Assert-GoogleTraceability `
  (-not (Compare-Object @('G10', 'G29', 'G31', 'G40') `
    $acceptancePendingIds)) `
  'the real-device acceptance requirement set changed.'

foreach ($forbiddenPattern in @(
  'AIza[0-9A-Za-z_-]+',
  '[0-9]+-[0-9A-Za-z_-]+\.apps\.googleusercontent\.com',
  '(?i)client[_ -]?secret\s*[:=]\s*[^;\s]+',
  '(?i)id[_ -]?token\s*[:=]\s*[0-9A-Za-z._-]{20,}'
)) {
  Assert-GoogleTraceability (-not [regex]::IsMatch($raw, $forbiddenPattern)) `
    'the mapper contains a prohibited credential-shaped value.'
}

Write-Output (
  'Google authentication production traceability passed: requirements=40; ' +
  'p0PreBuildBlockers=0; deviceAcceptancePending=4; ' +
  'stableEvidenceReuse=true; credentialValuesEmitted=false.'
)
