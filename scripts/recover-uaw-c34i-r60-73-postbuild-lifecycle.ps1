[CmdletBinding()]
param(
  [ValidateSet('audit', 'apply')]
  [string]$Mode = 'audit',

  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34i.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'C34I postbuild lifecycle recovery requires PowerShell 7 or newer.'
}
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34IRecovery {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34I existing-AAB postbuild recovery rejected: $Message"
  }
}

function Resolve-C34IRecoveryPath {
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Label,
    [switch]$AllowMissing
  )
  Assert-C34IRecovery -Condition (
    -not [string]::IsNullOrWhiteSpace($RelativePath) -and
    -not [IO.Path]::IsPathRooted($RelativePath)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C34IRecovery -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  if (-not $AllowMissing) {
    Assert-C34IRecovery -Condition (
      Test-Path -LiteralPath $resolved -PathType Leaf
    ) -Message "$Label is missing."
  }
  return $resolved
}

function Write-C34IRecoveryState {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Suffix
  )
  $temporary = $Path + $Suffix
  Assert-C34IRecovery -Condition (-not (Test-Path -LiteralPath $temporary)) `
    -Message "stale atomic state exists: $Suffix"
  try {
    [IO.File]::WriteAllText(
      $temporary,
      (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine),
      [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  } finally {
    if (Test-Path -LiteralPath $temporary) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
}

$candidateId =
  'UAW-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-PLAY-OPPO-ACCEPTANCE'
$evidenceRoot =
  'artifacts/quality/uaw-c34i-r60-73-authentication-privacy-safe-preparation-20260817-01'
$stateFile = Resolve-C34IRecoveryPath -RelativePath $StatePath -Label 'state'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateFile = Resolve-C34IRecoveryPath `
  -RelativePath ([string]$state.aggregateStatePath) `
  -Label 'aggregate state'
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json

Assert-C34IRecovery -Condition (
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001' -and
  [string]$state.candidate.id -ceq $candidateId -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.73' -and
  [string]$state.candidate.versionCode -ceq '2026081373' -and
  [string]$state.buildAuthorization -ceq 'consumed' -and
  [int]$state.buildResult.buildCount -eq 1 -and
  [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
  [int]$state.buildResult.configOnlyCount -eq 1 -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.upload -eq 0 -and
  [int]$state.actionCounts.install -eq 0 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0 -and
  [int]$aggregate.candidate.buildCount -eq 1 -and
  [int]$aggregate.actionCounts.build -eq 1 -and
  [string]$aggregate.releaseAuthorities.build -ceq 'consumed'
) -Message 'candidate identity, consumed single-build authority or 1/0/0/0 mirrors changed.'
Assert-C34IRecovery -Condition (
  [string]$state.machineState -ceq
    'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed' -and
  [string]$state.buildResult.state -ceq
    'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed' -and
  [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactSha256) -and
  [int64]$state.buildResult.artifactBytes -eq 0
) -Message 'state is not the one supported interrupted-postbuild boundary.'

$transientGoogleServices = Resolve-C34IRecoveryPath `
  -RelativePath ([string]$state.runtimeConfiguration.transientGoogleServicesPath) `
  -Label 'transient Google Services file' `
  -AllowMissing
Assert-C34IRecovery -Condition (-not (Test-Path -LiteralPath $transientGoogleServices)) `
  -Message 'transient Google Services file remains.'

$sealedRelative =
  "$evidenceRoot/MoolSocial-1.0.0-r60.73-2026081373-release.aab"
$sealedPath = Resolve-C34IRecoveryPath -RelativePath $sealedRelative -Label 'sealed AAB'
$provenanceCandidates = @()
foreach ($attempt in 1..5) {
  $relative = "$evidenceRoot/06-release-aab-provenance-attempt-$attempt.json"
  $resolved = Resolve-C34IRecoveryPath `
    -RelativePath $relative `
    -Label "provenance attempt $attempt" `
    -AllowMissing
  if (Test-Path -LiteralPath $resolved -PathType Leaf) {
    $provenanceCandidates += [pscustomobject]@{
      relative = $relative
      path = $resolved
    }
  }
}
Assert-C34IRecovery -Condition ($provenanceCandidates.Count -eq 1) `
  -Message 'exactly one completed provenance owner is required.'
$provenanceOwner = $provenanceCandidates[0]
$provenance = Get-Content -Raw -LiteralPath $provenanceOwner.path | ConvertFrom-Json
$artifactSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $sealedPath).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
Assert-C34IRecovery -Condition (
  [string]$provenance.candidateId -ceq $candidateId -and
  [string]$provenance.versionName -ceq '1.0.0-r60.73' -and
  [string]$provenance.versionCode -ceq '2026081373' -and
  [string]$provenance.packageName -ceq 'com.moolsocial.app' -and
  [string]$provenance.authorizedTrack -ceq 'internal' -and
  [string]$provenance.artifactPath -ceq $sealedRelative -and
  [string]$provenance.artifactSha256 -ceq $artifactSha256 -and
  [int64]$provenance.artifactBytes -eq $artifactBytes -and
  [string]$provenance.sourceManifest -ceq
    [string]$state.sourceQualification.manifestPath -and
  [string]$provenance.sourceManifestSha256 -ceq
    [string]$state.sourceQualification.manifestSha256 -and
  [bool]$provenance.packageVersionManifestProved -and
  [bool]$provenance.googleAppIdResourceProved -and
  [bool]$provenance.crashlyticsBuildIdResourceProved -and
  [bool]$provenance.splitAndArm64PayloadProved -and
  -not [bool]$provenance.secretValuesRecorded
) -Message 'sealed AAB, provenance, source seal or payload proof changed.'

$buildLog = Resolve-C34IRecoveryPath `
  -RelativePath ([string]$provenance.buildLog) `
  -Label 'release build log'
$credentialHits = @(
  Select-String -LiteralPath $buildLog `
    -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----'
)
Assert-C34IRecovery -Condition ($credentialHits.Count -eq 0) `
  -Message 'credential-shaped build output was detected.'
Assert-C34IRecovery -Condition (
  @(Select-String -LiteralPath $buildLog `
    -Pattern 'Built build[\\/]app[\\/]outputs[\\/]bundle[\\/]release[\\/]app-release.aab').Count -eq 1 -and
  @(Select-String -LiteralPath $buildLog `
    -Pattern 'BUILD FAILED|FAILURE:|Exception:').Count -eq 0
) -Message 'build completion or zero-failure evidence changed.'

if ($Mode -ceq 'apply') {
  $state.machineState = 'single_release_AAB_succeeded_authority_consumed'
  $state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
  $state.buildResult.artifactPath = $sealedRelative
  $state.buildResult.artifactSha256 = $artifactSha256
  $state.buildResult.artifactBytes = $artifactBytes
  $state.buildResult.uploadSignerSha256 = [string]$provenance.uploadSignerSha256
  $state.buildResult.packageVersionManifestProved = $true
  $state.buildResult.googleAppIdResourceProved = $true
  $state.buildResult.crashlyticsBuildIdResourceProved = $true
  $state.buildResult.splitAndArm64PayloadProved = $true
  $state.buildResult.mergedReleaseManifestProved = $true
  $state.buildResult.provenance = [string]$provenanceOwner.relative
  $aggregate.machineState = 'single_release_AAB_succeeded_authority_consumed'
  $aggregate.candidate.aabSha256 = $artifactSha256
  Write-C34IRecoveryState `
    -State $state `
    -Path $stateFile `
    -Suffix '.c34i-recovery-state-write'
  Write-C34IRecoveryState `
    -State $aggregate `
    -Path $aggregateFile `
    -Suffix '.c34i-recovery-aggregate-write'
  & (Join-Path $root `
    'scripts/check-uaw-c34i-r60-73-authentication-privacy-safe-release-readiness.ps1') `
    -Phase postbuild `
    -StatePath $StatePath `
    -RepositoryRoot $root
}

Write-Output (
  'C34I existing-AAB postbuild lifecycle recovery passed: ' +
  "mode=$Mode; sha256=$artifactSha256; bytes=$artifactBytes; " +
  'secondBuild=false; upload=0; install=0; OPPO=untouched.'
)
