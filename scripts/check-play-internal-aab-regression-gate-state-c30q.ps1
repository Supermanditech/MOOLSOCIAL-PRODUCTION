[CmdletBinding()]
param(
  [string]$StatePath,
  [string]$CandidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30Q',
  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'preinstall', 'journey')][string]$Phase = 'reconcile',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30q.json' }

function Assert-C30Q {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30Q Play Internal AAB gate rejected: $Message" }
}
function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30Q -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label path is missing."
  Assert-C30Q -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30Q -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30Q -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}

$stateFile = [IO.Path]::GetFullPath($StatePath)
Assert-C30Q -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'state escaped the repository.'
Assert-C30Q -Condition (Test-Path -LiteralPath $stateFile -PathType Leaf) -Message 'state is missing.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30Q -Condition ([int]$state.schemaVersion -eq 1 -and [string]$state.contractId -ceq 'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30Q-001') -Message 'state contract changed.'
Assert-C30Q -Condition ([string]$state.candidate.id -ceq $CandidateId) -Message 'candidate changed.'
Assert-C30Q -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.43' -and
  [string]$state.candidate.versionCode -ceq '2026081243' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate is not exact r60.43.'

$branch = (& git -C $root branch --show-current).Trim()
Assert-C30Q -Condition ($LASTEXITCODE -eq 0) -Message 'branch read failed.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30Q -Condition ($LASTEXITCODE -eq 0) -Message 'HEAD read failed.'
Assert-C30Q -Condition ($branch -ceq [string]$state.candidate.branch -and $head -ceq [string]$state.candidate.head) -Message 'branch or HEAD changed.'

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $CandidateId -RequireExecutionAuthorized -RepositoryRoot $root

foreach ($predecessor in @($state.failedBuildPredecessors)) {
  $predecessorPath = Resolve-RepoFile -Path ([string]$predecessor.statePath) -Label 'failed predecessor'
  $failed = Get-Content -Raw -LiteralPath $predecessorPath | ConvertFrom-Json
  Assert-C30Q -Condition (
    [string]$failed.machineState -ceq [string]$predecessor.expectedState -and
    [string]$failed.buildAuthorization -ceq 'consumed' -and
    [int]$failed.buildResult.buildCount -eq [int]$predecessor.expectedBuildCount -and
    [int]$failed.buildResult.wrapperInvocationCount -eq 1 -and
    [string]::IsNullOrWhiteSpace([string]$failed.buildResult.artifactPath) -and
    -not [bool]$failed.buildResult.secondBuildPerformed -and
    [int]$failed.playReleaseResult.uploadCount -eq 0 -and
    [int]$failed.installResult.candidateInstallCount -eq 0
  ) -Message "failed predecessor was reused or changed: $($predecessor.ticketId)"
}
[void](Resolve-RepoFile -Path ([string]$state.protectedPredecessor.statePath) -Label 'protected C30N state')
[void](Resolve-RepoFile -Path ([string]$state.communicationHold.reviewerPackage) -Label 'reviewer package')
[void](Resolve-RepoFile -Path ([string]$state.toolingQualification.officialFindingEvidence) -Label 'official finding')

Assert-C30Q -Condition (
  [string]$state.distribution.authorizedTrack -ceq 'internal' -and
  -not [bool]$state.distribution.productionTrackAuthorized -and
  -not [bool]$state.distribution.openTestingAuthorized -and
  -not [bool]$state.distribution.publicListingAuthorized
) -Message 'distribution boundary changed.'
Assert-C30Q -Condition (
  -not [bool]$state.signingQualification.secretValuesRecorded -and
  -not [bool]$state.signingQualification.agentSecretValueAccessAuthorized -and
  -not [bool]$state.firebaseAppCheck.privateVerdictReadAuthorized -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
  -not [bool]$state.communicationHold.emailSent -and
  -not [bool]$state.communicationHold.quotaSubmitted
) -Message 'secret, verdict or communication hold changed.'
Assert-C30Q -Condition (
  [int]$state.buildResult.buildCount -le 1 -and
  [int]$state.buildResult.wrapperInvocationCount -le 1 -and
  [int]$state.buildResult.configOnlyCount -le 1 -and
  -not [bool]$state.buildResult.secondBuildPerformed -and
  [int]$state.playReleaseResult.uploadCount -le 1 -and
  [int]$state.installResult.candidateInstallCount -le 1 -and
  -not [bool]$state.installResult.uninstallPerformed -and
  -not [bool]$state.installResult.dataClearPerformed -and
  -not [bool]$state.installResult.downgradePerformed -and
  -not [bool]$state.installResult.adbSuccessorInstallPerformed -and
  -not [bool]$state.installResult.secondInstallPerformed
) -Message 'single build/config/upload/install boundary changed.'

if ($Phase -in @('build', 'postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30Q -Condition (
    [string]$state.sourceQualification.state -ceq 'passed_two_identical_complete_C30Q_cycles' -and
    [int]$state.sourceQualification.identicalQualifyingCycles -eq 2 -and
    [bool]$state.sourceQualification.completeSocialCyclesPassed -and
    [bool]$state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt -and
    [bool]$state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation -and
    [bool]$state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringNativeCommands -and
    [bool]$state.toolingQualification.nativeExitCodeAuthoritative -and
    [bool]$state.toolingQualification.preferencesRestoredAfterNativeCommands -and
    [bool]$state.toolingQualification.releaseConfigOnlyCommandQualified -and
    [bool]$state.toolingQualification.releaseConfigOnlyProducesNoApk -and
    [bool]$state.toolingQualification.releaseRegistrantExcludesIntegrationTestPlugin
  ) -Message 'source or release-config qualification is incomplete.'
  $manifest = Resolve-RepoFile -Path ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
  Assert-C30Q -Condition ((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -ceq ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()) -Message 'source manifest changed.'
  Assert-C30Q -Condition ([bool]$state.signingQualification.founderControlledUploadKeyPresent -and [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder) -Message 'founder inputs not qualified.'
}
if ($Phase -ceq 'build') {
  Assert-C30Q -Condition ($PSVersionTable.PSVersion.Major -ge 7) -Message 'PowerShell 7 is required.'
  Assert-C30Q -Condition (
    [string]$state.machineState -ceq 'source_and_founder_inputs_qualified_single_release_AAB_build_authorized' -and
    [string]$state.buildAuthorization -ceq 'available_not_consumed' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 0 -and
    [int]$state.buildResult.configOnlyCount -eq 0 -and
    [string]$state.buildResult.state -ceq 'not_started'
  ) -Message 'build authority is unavailable.'
}
if ($Phase -in @('postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30Q -Condition (
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    [int]$state.buildResult.configOnlyCount -eq 1 -and
    [string]$state.buildResult.state -ceq 'single_release_AAB_succeeded_authority_consumed'
  ) -Message 'AAB result is not sealed.'
  $artifact = Resolve-RepoFile -Path ([string]$state.buildResult.artifactPath) -Label 'release AAB'
  Assert-C30Q -Condition ((Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash -ceq ([string]$state.buildResult.artifactSha256).ToUpperInvariant()) -Message 'AAB hash changed.'
}
if ($Phase -in @('preupload', 'preinstall', 'journey')) {
  Assert-C30Q -Condition ([bool]$state.distribution.appCreated -and [bool]$state.firebaseAppCheck.playProjectLinked -and [bool]$state.firebaseAppCheck.playAppSigningCertificateRegistered) -Message 'Play/Firebase identities not sealed.'
}
if ($Phase -in @('preinstall', 'journey')) {
  Assert-C30Q -Condition ([bool]$state.distribution.releaseUploaded -and [int]$state.playReleaseResult.uploadCount -eq 1 -and [string]$state.playReleaseResult.track -ceq 'internal' -and -not [bool]$state.playReleaseResult.productionRolloutPerformed) -Message 'Internal release not sealed.'
}
if ($Phase -ceq 'journey') {
  Assert-C30Q -Condition ([int]$state.installResult.candidateInstallCount -eq 1 -and [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and [bool]$state.installResult.playArtifactRelationshipProved) -Message 'Play install not sealed.'
}
Write-Output "C30Q Play Internal AAB gate passed: phase=$Phase; candidate=$CandidateId; buildCount=$($state.buildResult.buildCount); uploadCount=$($state.playReleaseResult.uploadCount); installCount=$($state.installResult.candidateInstallCount)."
