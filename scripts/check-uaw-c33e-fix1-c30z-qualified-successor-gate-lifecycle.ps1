[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$tmpRoot = [IO.Path]::GetFullPath((Join-Path $root 'tmp')).TrimEnd(
  [char[]]@('\', '/')
)
$tmpPrefix = $tmpRoot + [IO.Path]::DirectorySeparatorChar
$caseRoot = [IO.Path]::GetFullPath((Join-Path $tmpRoot (
  'c33e-fix1-c30z-lifecycle-' + [Guid]::NewGuid().ToString('N')
)))

function Assert-C33EFix1 {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) {
    throw "C33E FIX1 lifecycle checker rejected: $Message"
  }
}

Assert-C33EFix1 ($caseRoot.StartsWith(
  $tmpPrefix,
  [StringComparison]::OrdinalIgnoreCase
)) 'temporary case root escaped repository tmp'
Assert-C33EFix1 (
  (Split-Path -Leaf $caseRoot).StartsWith(
    'c33e-fix1-c30z-lifecycle-',
    [StringComparison]::Ordinal
  )
) 'temporary case root name is unsafe'

$scopePath = Join-Path $root 'config/mvp-scope-gate-state.json'
$gatePath = Join-Path $root `
  'scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1'
Assert-C33EFix1 (Test-Path -LiteralPath $scopePath -PathType Leaf) `
  'scope state is missing'
Assert-C33EFix1 (Test-Path -LiteralPath $gatePath -PathType Leaf) `
  'C30Z gate is missing'
$base = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json

$c30z = 'UAW-C30Z-R60-48-AUTHENTICATION-METHOD-TRUTH-AND-GUEST-FEED-RECOVERY'
$c33e = 'UAW-C33E-R60-48-PLAY-INSTALLED-AUTH-LOGIN-DEVICE-REPRODUCTION'
$fix1 = 'UAW-C33E-FIX1-C30Z-QUALIFIED-SUCCESSOR-GATE-LIFECYCLE'
$hashes = @{
  $c30z = '5A03AD26DAE2AAA9CD724A1F05AE1D0CE0FB4F0D5DFEEFB05AF3DDE58F7B1AD8'
  $c33e = '64441D2ED89084C33AD57DAF3BA40CF5E355B18B2120C0D541CE079F01D6EAAE'
  $fix1 = 'E828DACE4821ECBFAC43737617B976286258F29BEF4EBC8FA4173691A3A359F0'
}

function New-C33EFixture {
  param(
    [string]$TicketId,
    [bool]$RuntimeWrite,
    [bool]$ExistingClientTap
  )
  $fixture = $base | ConvertTo-Json -Depth 100 | ConvertFrom-Json
  $fixture.state = 'ticket_disclosed_and_authorized'
  $fixture.checkpoint.successorRegistered = $true
  $fixture.ticket.id = $TicketId
  $fixture.preTicketSelectionCheckpoint.currentTicketId = $TicketId
  $fixture.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId =
    $TicketId
  $fixture.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
    $hashes[$TicketId]
  $fixture.execution.referenceWriteAuthorized = $false
  $fixture.execution.runtimeWriteAuthorized = $RuntimeWrite
  $fixture.execution.testOrGateWriteAuthorized = $true
  $fixture.execution.backendWriteAuthorized = $false
  $fixture.execution.buildAuthorized = $false
  $fixture.execution.deviceInstallAuthorized = $false
  $fixture.execution.externalServiceWriteAuthorized = $false
  $fixture.execution.secretValueAccessAuthorized = $false
  $fixture.providerGate.nextTicket = $TicketId
  $fixture.providerGate.existingProtectedClientLaunchAndTapAuthorized =
    $ExistingClientTap
  $fixture.providerGate.externalServiceWriteAuthorized = $false
  $fixture.providerGate.secretValueAccessAuthorized = $false
  $fixture.providerGate.apkBuildOrInstallAuthorized = $false
  $fixture.providerGate.productionOrProviderDeploymentAuthorized = $false
  $fixture.providerGate.DevProviderDeploymentAuthorized = $false
  $fixture.providerGate.emailOrQuotaSubmissionAuthorized = $false
  return $fixture
}

function Invoke-C33EFixture {
  param(
    [string]$Label,
    [object]$Fixture,
    [bool]$ShouldPass
  )
  $path = Join-Path $caseRoot ($Label + '.json')
  $Fixture | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path `
    -Encoding UTF8
  $fullPath = [IO.Path]::GetFullPath($path)
  Assert-C33EFix1 ($fullPath.StartsWith(
    $rootPrefix,
    [StringComparison]::OrdinalIgnoreCase
  )) "$Label fixture escaped the repository"
  $relative = $fullPath.Substring($rootPrefix.Length)
  $threw = $false
  $message = ''
  try {
    [void](& $gatePath -RepositoryRoot $root -ScopePath $relative)
  } catch {
    $threw = $true
    $message = $_.Exception.Message
  }
  if ($ShouldPass) {
    Assert-C33EFix1 (-not $threw) "$Label unexpectedly failed: $message"
  } else {
    Assert-C33EFix1 $threw "$Label unexpectedly passed"
    Assert-C33EFix1 (
      $message.Contains('C30Z authentication truth gate rejected:')
    ) "$Label did not fail through the C30Z gate"
  }
}

New-Item -ItemType Directory -Path $caseRoot | Out-Null
try {
  Invoke-C33EFixture 'active-c30z' (
    New-C33EFixture $c30z $true $false
  ) $true
  Invoke-C33EFixture 'qualified-c33e' (
    New-C33EFixture $c33e $false $true
  ) $true
  Invoke-C33EFixture 'active-fix1' (
    New-C33EFixture $fix1 $false $false
  ) $true

  $unrelated = New-C33EFixture $fix1 $false $false
  $unrelated.ticket.id = 'UAW-UNRELATED-TICKET'
  $unrelated.preTicketSelectionCheckpoint.currentTicketId =
    'UAW-UNRELATED-TICKET'
  $unrelated.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId =
    'UAW-UNRELATED-TICKET'
  Invoke-C33EFixture 'reject-unrelated' $unrelated $false

  $runtimeDrift = New-C33EFixture $c33e $true $true
  Invoke-C33EFixture 'reject-c33e-runtime-write' $runtimeDrift $false

  $buildDrift = New-C33EFixture $c33e $false $true
  $buildDrift.execution.buildAuthorized = $true
  Invoke-C33EFixture 'reject-c33e-build' $buildDrift $false

  $secretDrift = New-C33EFixture $c33e $false $true
  $secretDrift.execution.secretValueAccessAuthorized = $true
  Invoke-C33EFixture 'reject-c33e-secret' $secretDrift $false

  $externalDrift = New-C33EFixture $c33e $false $true
  $externalDrift.providerGate.externalServiceWriteAuthorized = $true
  Invoke-C33EFixture 'reject-c33e-external' $externalDrift $false
} finally {
  if (Test-Path -LiteralPath $caseRoot) {
    $resolved = [IO.Path]::GetFullPath($caseRoot)
    Assert-C33EFix1 ($resolved.StartsWith(
      $tmpPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )) 'cleanup target escaped repository tmp'
    Assert-C33EFix1 (
      (Split-Path -Leaf $resolved).StartsWith(
        'c33e-fix1-c30z-lifecycle-',
        [StringComparison]::Ordinal
      )
    ) 'cleanup target name is unsafe'
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

Write-Output (
  'C33E FIX1 C30Z qualified-successor lifecycle checker passed: ' +
  'activeC30Z=true; exactC33E=true; activeFIX1=true; ' +
  'unrelated/runtime/build/secret/external rejected; ' +
  'runtime=false; build=false; install=false; external=false.'
)
