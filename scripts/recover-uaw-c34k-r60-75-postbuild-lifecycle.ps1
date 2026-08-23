[CmdletBinding()]
param(
  [ValidateSet('audit', 'apply')]
  [string]$Mode = 'audit',
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34k.json',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'C34K postbuild lifecycle recovery requires PowerShell 7 or newer.'
}
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'
$evidenceRoot =
  'artifacts/quality/uaw-c34k-r60-75-release-lifecycle-atomic-parity-preparation-20260817-01'

function Assert-C34KRecovery([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34K existing-AAB recovery rejected: $Message"
  }
}
function Resolve-RecoveryPath([string]$Path, [string]$Label) {
  Assert-C34KRecovery -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34KRecovery -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or outside the repository."
  return $resolved
}

$stateFile = Resolve-RecoveryPath -Path $StatePath -Label 'detailed state'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateFile = Resolve-RecoveryPath `
  -Path ([string]$state.aggregateStatePath) -Label 'aggregate state'
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
$inProgress =
  'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
Assert-C34KRecovery -Condition (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.machineState -ceq $inProgress -and
  [string]$aggregate.machineState -ceq $inProgress -and
  [string]$state.buildAuthorization -ceq 'consumed' -and
  [string]$state.releaseAuthorities.build -ceq 'consumed' -and
  [string]$aggregate.releaseAuthorities.build -ceq 'consumed' -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$aggregate.actionCounts.build -eq 1 -and
  [int]$aggregate.candidate.buildCount -eq 1 -and
  [int]$state.actionCounts.upload -eq 0 -and
  [int]$state.actionCounts.install -eq 0 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0 -and
  [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactSha256)
) -Message 'supported interrupted-postbuild boundary or 1/0/0/0 parity changed.'

$artifactRelative =
  "$evidenceRoot/MoolSocial-1.0.0-r60.75-2026081375-release.aab"
$provenanceRelative = "$evidenceRoot/06-release-aab-provenance.json"
$artifactFile = Resolve-RecoveryPath -Path $artifactRelative -Label 'sealed AAB'
$provenanceFile = Resolve-RecoveryPath `
  -Path $provenanceRelative -Label 'AAB provenance'
$provenance = Get-Content -Raw -LiteralPath $provenanceFile | ConvertFrom-Json
$artifactSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactFile).Hash
$artifactBytes = (Get-Item -LiteralPath $artifactFile).Length
Assert-C34KRecovery -Condition (
  [string]$provenance.candidateId -ceq $ticketId -and
  [string]$provenance.versionName -ceq '1.0.0-r60.75' -and
  [string]$provenance.versionCode -ceq '2026081375' -and
  [string]$provenance.packageName -ceq 'com.moolsocial.app' -and
  [string]$provenance.authorizedTrack -ceq 'internal' -and
  [string]$provenance.artifactPath -ceq $artifactRelative -and
  [string]$provenance.artifactSha256 -ceq $artifactSha -and
  [int64]$provenance.artifactBytes -eq $artifactBytes -and
  [string]$provenance.uploadSignerSha256 -cmatch '^[0-9A-F]{64}$' -and
  [bool]$provenance.packageVersionManifestProved -and
  [bool]$provenance.googleAppIdResourceProved -and
  [bool]$provenance.crashlyticsBuildIdResourceProved -and
  [bool]$provenance.splitAndArm64PayloadProved -and
  -not [bool]$provenance.secretValuesRecorded
) -Message 'sealed artifact or provenance proof changed.'

$buildLog = Resolve-RecoveryPath -Path ([string]$provenance.buildLog) `
  -Label 'release build log'
$credentialHits = @(Select-String -LiteralPath $buildLog `
  -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
Assert-C34KRecovery -Condition (
  $credentialHits.Count -eq 0 -and
  @(Select-String -LiteralPath $buildLog `
    -Pattern 'Built build[\\/]app[\\/]outputs[\\/]bundle[\\/]release[\\/]app-release.aab').Count -eq 1 -and
  @(Select-String -LiteralPath $buildLog `
    -Pattern 'BUILD FAILED|FAILURE:|Exception:').Count -eq 0
) -Message 'build completion, zero-failure or privacy evidence changed.'

if ($Mode -ceq 'apply') {
  $transition = Resolve-RecoveryPath `
    -Path 'scripts/invoke-release-lifecycle-transition-c34k.ps1' `
    -Label 'lifecycle transition owner'
  & $transition -Transition build-succeeded -StatePath $StatePath `
    -ArtifactPath $artifactRelative -ArtifactSha256 $artifactSha `
    -ArtifactBytes $artifactBytes `
    -UploadSignerSha256 ([string]$provenance.uploadSignerSha256) `
    -ArtifactProvenance $provenanceRelative -RepositoryRoot $root | Out-Null
  & (Join-Path $root `
    'scripts/check-uaw-c34k-r60-75-release-lifecycle-atomic-parity-readiness.ps1') `
    -Phase postbuild -StatePath $StatePath -RepositoryRoot $root
}

Write-Output (
  'C34K existing-AAB postbuild lifecycle recovery passed: ' +
  "mode=$Mode; sha256=$artifactSha; bytes=$artifactBytes; " +
  'secondBuild=false; upload=0; install=0; OPPO=untouched.'
)
