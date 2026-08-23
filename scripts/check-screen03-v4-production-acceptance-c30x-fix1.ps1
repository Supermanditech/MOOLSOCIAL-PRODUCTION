[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30XFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30X FIX1 Screen03 v4 gate rejected: $Message"
  }
}

function Resolve-C30XFix1File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30XFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Get-C30XFix1Hash {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

$manifestPath = Resolve-C30XFix1File `
  -Path 'approved-references/manifest.json' `
  -Label 'approved-reference manifest'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$screen03 = @($manifest.screens | Where-Object {
  [string]$_.screenId -ceq 'login-account-handoff'
})
$v3 = @($screen03 | Where-Object { [string]$_.version -ceq 'v3' })
$v4 = @($screen03 | Where-Object { [string]$_.version -ceq 'v4' })
Assert-C30XFix1 -Condition (
  $v3.Count -eq 1 -and
  $v4.Count -eq 1 -and
  [string]$v3[0].status -ceq 'superseded-production-accepted' -and
  [string]$v4[0].status -ceq 'production-accepted' -and
  [string]$v4[0].supersedes -ceq 'v3' -and
  [string]$v4[0].root -ceq 'screens/03-login-account-handoff/v4' -and
  [string]$v4[0].approvalSource -ceq
    'docs/quality/UAW-C30X-FIX1-FOUNDER-AUTHORIZATION-20260814.md'
) -Message 'Screen03 v3/v4 lineage or active production status changed.'
Assert-C30XFix1 -Condition (
  @($manifest.screens | Where-Object {
    [string]$_.screenId -ceq 'login-account-handoff' -and
    [string]$_.status -ceq 'production-accepted'
  }).Count -eq 1
) -Message 'Screen03 must have exactly one current production-accepted version.'

$v4Root = 'approved-references/screens/03-login-account-handoff/v4'
$v4Files = [ordered]@{
  'README.md' = 'bd5dc5f978409785f878e0bf47604ccaac53d911052451990870da2163dfc532'
  'interaction-contract.json' = '12ef1959719c942ea3ba82642654f1adbf0416f7bd8f5ce0292fea04a892a35e'
  'production-acceptance.json' = '2ac61354784ad6c328817570a3147e6f3cfe56ec2796abb9c33cb364fb7a47bd'
}
foreach ($entry in $v4Files.GetEnumerator()) {
  $path = Resolve-C30XFix1File `
    -Path "$v4Root/$($entry.Key)" `
    -Label "Screen03 v4 $($entry.Key)"
  Assert-C30XFix1 -Condition (
    (Get-C30XFix1Hash -Path $path) -ceq [string]$entry.Value
  ) -Message "Screen03 v4 file changed: $($entry.Key)"
}
$sumPath = Resolve-C30XFix1File `
  -Path "$v4Root/SHA256SUMS" `
  -Label 'Screen03 v4 checksums'
$sumRows = @(Get-Content -LiteralPath $sumPath)
Assert-C30XFix1 -Condition ($sumRows.Count -eq $v4Files.Count) `
  -Message 'Screen03 v4 checksum row count changed.'
foreach ($entry in $v4Files.GetEnumerator()) {
  Assert-C30XFix1 -Condition (
    $sumRows -ccontains ("{0}  {1}" -f $entry.Value, $entry.Key)
  ) -Message "Screen03 v4 checksum row is missing: $($entry.Key)"
}

$v3AcceptancePath = Resolve-C30XFix1File `
  -Path 'approved-references/screens/03-login-account-handoff/v3/production-acceptance.json' `
  -Label 'Screen03 v3 acceptance'
$v4AcceptancePath = Resolve-C30XFix1File `
  -Path "$v4Root/production-acceptance.json" `
  -Label 'Screen03 v4 acceptance'
$v3Acceptance = Get-Content -Raw -LiteralPath $v3AcceptancePath |
  ConvertFrom-Json
$v4Acceptance = Get-Content -Raw -LiteralPath $v4AcceptancePath |
  ConvertFrom-Json
Assert-C30XFix1 -Condition (
  [string]$v4Acceptance.status -ceq 'Accepted' -and
  [string]$v4Acceptance.approval.reconciliationTicket -ceq
    'UAW-C30X-FIX1-SCREEN03-RELEASE-CONFIGURATION-TEST-LOCK-RECONCILIATION' -and
  [bool]$v4Acceptance.lineage.v1V2AndV3FilesPreserved -and
  [int]$v4Acceptance.lineage.v3LockedOwnerCount -eq 12 -and
  [int]$v4Acceptance.lineage.unchangedOwnerCount -eq 11 -and
  [int]$v4Acceptance.lineage.changedOwnerCount -eq 1 -and
  [string]$v4Acceptance.lineage.changedOwner -ceq
    'apps/mobile/test/platform_configuration_test.dart' -and
  -not [bool]$v4Acceptance.presentationEquivalence.runtimeSourceChanged -and
  -not [bool]$v4Acceptance.presentationEquivalence.providerAssetChanged -and
  -not [bool]$v4Acceptance.presentationEquivalence.behaviorOrCopyTestChanged -and
  -not [bool]$v4Acceptance.presentationEquivalence.fitmentTestChanged -and
  -not [bool]$v4Acceptance.presentationEquivalence.goldenTestChanged -and
  -not [bool]$v4Acceptance.presentationEquivalence.goldenImagesChanged
) -Message 'Screen03 v4 acceptance or presentation-equivalence claim changed.'

$v3Locked = @($v3Acceptance.lockedFiles)
$v4Locked = @($v4Acceptance.lockedFiles)
Assert-C30XFix1 -Condition (
  $v3Locked.Count -eq 12 -and $v4Locked.Count -eq 12
) -Message 'Screen03 locked-owner count changed.'
$changed = [Collections.Generic.List[string]]::new()
foreach ($prior in $v3Locked) {
  $current = @($v4Locked | Where-Object {
    [string]$_.path -ceq [string]$prior.path
  })
  Assert-C30XFix1 -Condition ($current.Count -eq 1) `
    -Message "Screen03 v4 lost or duplicated owner: $($prior.path)"
  if ([string]$current[0].sha256 -cne [string]$prior.sha256) {
    $changed.Add([string]$prior.path)
  }
}
Assert-C30XFix1 -Condition (
  $changed.Count -eq 1 -and
  $changed[0] -ceq 'apps/mobile/test/platform_configuration_test.dart'
) -Message 'Screen03 v4 changed more than the one authorized test-only owner.'
foreach ($locked in $v4Locked) {
  $lockedPath = Resolve-C30XFix1File `
    -Path ([string]$locked.path) `
    -Label 'Screen03 v4 locked production owner'
  Assert-C30XFix1 -Condition (
    (Get-C30XFix1Hash -Path $lockedPath) -ceq
      ([string]$locked.sha256).ToLowerInvariant()
  ) -Message "Screen03 v4 locked owner changed: $($locked.path)"
}

$platformPath = Resolve-C30XFix1File `
  -Path 'apps/mobile/test/platform_configuration_test.dart' `
  -Label 'platform configuration test'
$platformSource = Get-Content -Raw -LiteralPath $platformPath
foreach ($required in @(
  'release builds require live Firebase configuration',
  'profile device-review builds retain candidate provenance markers',
  'runApp(const ReleaseConfigurationFailureApp());',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
  'MOOLSOCIAL_CANDIDATE',
  'MOOLSOCIAL_STARTUP'
)) {
  Assert-C30XFix1 -Condition (
    $platformSource.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "platform regression is missing: $required"
}

$scopePath = Resolve-C30XFix1File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$activeTicketId = [string]$scope.ticket.id
$creationContext =
  $activeTicketId -ceq
    'UAW-C30X-FIX1-SCREEN03-RELEASE-CONFIGURATION-TEST-LOCK-RECONCILIATION' -and
  [bool]$scope.execution.referenceWriteAuthorized
$readOnlyReplayContext =
  $activeTicketId -cin @(
    'UAW-C30X-FIX4-SCREEN03-V4-HISTORICAL-GATE-SUCCESSOR-REPLAY',
    'UAW-C30X-SUCCESSOR-AAB-PREPARATION-REGRESSION-HARD-GATE',
    'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
  ) -and
  -not [bool]$scope.execution.referenceWriteAuthorized
Assert-C30XFix1 -Condition (
  ($creationContext -or $readOnlyReplayContext) -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  -not [bool]$scope.execution.backendWriteAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.secretValueAccessAuthorized
) -Message 'C30X FIX1 creation or exact read-only successor replay scope changed.'

Write-Output (
  'C30X FIX1 Screen03 v4 production acceptance passed: ' +
  'presentationChanged=false; lockedOwners=12; changedOwners=1; ' +
  'changedOwner=platform_configuration_test.dart; build=false; device=false.'
)
