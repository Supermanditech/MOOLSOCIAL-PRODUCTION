[CmdletBinding()]
param(
  [string]$StatePath,
  [string]$CandidateId =
    'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30P',
  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'preinstall', 'journey')]
  [string]$Phase = 'reconcile',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30p.json'
}

function Assert-C30P {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw ('C30P Play Internal AAB gate rejected: {0}' -f $Message)
  }
}

function Resolve-RepositoryFile {
  param([Parameter(Mandatory)][string]$RelativePath, [Parameter(Mandatory)][string]$Label)
  Assert-C30P -Condition (-not [string]::IsNullOrWhiteSpace($RelativePath)) -Message "$Label path is missing."
  Assert-C30P -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30P -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30P -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}

$resolvedState = [IO.Path]::GetFullPath($StatePath)
Assert-C30P -Condition ($resolvedState.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'machine state escaped the repository.'
Assert-C30P -Condition (Test-Path -LiteralPath $resolvedState -PathType Leaf) -Message 'machine state is missing.'
$state = Get-Content -Raw -LiteralPath $resolvedState | ConvertFrom-Json

Assert-C30P -Condition ([int]$state.schemaVersion -eq 1) -Message 'unsupported schema.'
Assert-C30P -Condition ([string]$state.contractId -ceq 'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30P-001') -Message 'contract identity changed.'
Assert-C30P -Condition ([string]$state.candidate.id -ceq $CandidateId) -Message 'candidate identity changed.'
Assert-C30P -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.42' -and
  [string]$state.candidate.versionCode -ceq '2026081242' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate is not the exact r60.42 release AAB.'

$branch = (& git -C $root branch --show-current).Trim()
Assert-C30P -Condition ($LASTEXITCODE -eq 0) -Message 'branch could not be read.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30P -Condition ($LASTEXITCODE -eq 0) -Message 'HEAD could not be read.'
Assert-C30P -Condition ($branch -ceq [string]$state.candidate.branch) -Message 'working branch changed.'
Assert-C30P -Condition ($head -ceq [string]$state.candidate.head) -Message 'working HEAD changed.'

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') `
  -CandidateId $CandidateId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root

$c30oPath = Resolve-RepositoryFile -RelativePath ([string]$state.failedBuildPredecessor.statePath) -Label 'failed C30O state'
$c30o = Get-Content -Raw -LiteralPath $c30oPath | ConvertFrom-Json
Assert-C30P -Condition (
  [string]$c30o.machineState -ceq 'single_release_AAB_failed_authority_consumed' -and
  [string]$c30o.buildAuthorization -ceq 'consumed' -and
  [int]$c30o.buildResult.buildCount -eq 1 -and
  [int]$c30o.buildResult.wrapperInvocationCount -eq 1 -and
  [string]::IsNullOrWhiteSpace([string]$c30o.buildResult.artifactPath) -and
  -not [bool]$c30o.buildResult.secondBuildPerformed -and
  [int]$c30o.playReleaseResult.uploadCount -eq 0 -and
  [int]$c30o.installResult.candidateInstallCount -eq 0
) -Message 'C30O failed-authority disposition changed or was reused.'

[void](Resolve-RepositoryFile -RelativePath ([string]$state.protectedPredecessor.statePath) -Label 'protected C30N state')
[void](Resolve-RepositoryFile -RelativePath ([string]$state.communicationHold.reviewerPackage) -Label 'reviewer package')
[void](Resolve-RepositoryFile -RelativePath ([string]$state.toolingQualification.c30oFailureEvidence) -Label 'C30O recurrence evidence')

Assert-C30P -Condition (
  [string]$state.distribution.authorizedTrack -ceq 'internal' -and
  -not [bool]$state.distribution.productionTrackAuthorized -and
  -not [bool]$state.distribution.openTestingAuthorized -and
  -not [bool]$state.distribution.publicListingAuthorized
) -Message 'distribution escaped Internal Testing.'
Assert-C30P -Condition (
  -not [bool]$state.signingQualification.secretValuesRecorded -and
  -not [bool]$state.signingQualification.agentSecretValueAccessAuthorized -and
  -not [bool]$state.firebaseAppCheck.privateVerdictReadAuthorized -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent
) -Message 'secret or private-verdict boundary changed.'
Assert-C30P -Condition (
  -not [bool]$state.communicationHold.gmailDraftCreated -and
  -not [bool]$state.communicationHold.emailSent -and
  -not [bool]$state.communicationHold.quotaSubmitted
) -Message 'communication hold was violated.'
Assert-C30P -Condition (
  [int]$state.buildResult.buildCount -le 1 -and
  [int]$state.buildResult.wrapperInvocationCount -le 1 -and
  -not [bool]$state.buildResult.secondBuildPerformed -and
  [int]$state.playReleaseResult.uploadCount -le 1 -and
  [int]$state.installResult.candidateInstallCount -le 1 -and
  -not [bool]$state.installResult.uninstallPerformed -and
  -not [bool]$state.installResult.dataClearPerformed -and
  -not [bool]$state.installResult.downgradePerformed -and
  -not [bool]$state.installResult.adbSuccessorInstallPerformed -and
  -not [bool]$state.installResult.secondInstallPerformed
) -Message 'single build/upload/install or protected-device boundary changed.'

if ($Phase -in @('build', 'postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30P -Condition (
    [string]$state.sourceQualification.state -ceq 'passed_two_identical_complete_C30P_cycles' -and
    [int]$state.sourceQualification.identicalQualifyingCycles -eq 2 -and
    [bool]$state.sourceQualification.completeSocialCyclesPassed -and
    [bool]$state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt -and
    [bool]$state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation -and
    [bool]$state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringFlutter -and
    [bool]$state.toolingQualification.nativeExitCodeAuthoritative -and
    [bool]$state.toolingQualification.preferencesRestoredAfterFlutter
  ) -Message 'C30P source or PowerShell tooling qualification is incomplete.'
  $manifest = Resolve-RepositoryFile -RelativePath ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
  Assert-C30P -Condition (
    (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -ceq
      ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()
  ) -Message 'source manifest hash changed.'
  Assert-C30P -Condition (
    [bool]$state.signingQualification.founderControlledUploadKeyPresent -and
    -not [string]::IsNullOrWhiteSpace([string]$state.signingQualification.uploadCertificateSha256) -and
    [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder
  ) -Message 'founder signing or secret-safe define input is not qualified.'
}

if ($Phase -ceq 'build') {
  Assert-C30P -Condition ($PSVersionTable.PSVersion.Major -ge 7) -Message 'PowerShell 7 or newer is required before build authority can be consumed.'
  Assert-C30P -Condition (
    [string]$state.machineState -ceq 'source_and_founder_inputs_qualified_single_release_AAB_build_authorized' -and
    [string]$state.buildAuthorization -ceq 'available_not_consumed' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 0 -and
    [string]$state.buildResult.state -ceq 'not_started'
  ) -Message 'C30P build authority is unavailable or consumed.'
}

if ($Phase -in @('postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30P -Condition (
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    [string]$state.buildResult.state -ceq 'single_release_AAB_succeeded_authority_consumed'
  ) -Message 'C30P AAB result is not sealed.'
  $artifact = Resolve-RepositoryFile -RelativePath ([string]$state.buildResult.artifactPath) -Label 'release AAB'
  Assert-C30P -Condition (
    (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash -ceq
      ([string]$state.buildResult.artifactSha256).ToUpperInvariant()
  ) -Message 'release AAB checksum changed.'
}

if ($Phase -in @('preupload', 'preinstall', 'journey')) {
  Assert-C30P -Condition (
    [bool]$state.distribution.appCreated -and
    [string]$state.distribution.playAppId -ceq '4974778280277295872' -and
    [bool]$state.firebaseAppCheck.playProjectLinked -and
    [bool]$state.firebaseAppCheck.playAppSigningCertificateRegistered -and
    [string]$state.firebaseAppCheck.playAppSigningSha256 -ceq [string]$state.signingQualification.playAppSigningCertificateSha256
  ) -Message 'Play/Firebase identities are not sealed.'
}

if ($Phase -in @('preinstall', 'journey')) {
  Assert-C30P -Condition (
    [bool]$state.distribution.releaseUploaded -and
    [bool]$state.distribution.founderTesterEligible -and
    -not [string]::IsNullOrWhiteSpace([string]$state.distribution.testerOptInLink) -and
    [int]$state.playReleaseResult.uploadCount -eq 1 -and
    [string]$state.playReleaseResult.track -ceq 'internal' -and
    -not [bool]$state.playReleaseResult.productionRolloutPerformed
  ) -Message 'Internal Testing release/tester access is not sealed.'
}

if ($Phase -ceq 'journey') {
  Assert-C30P -Condition (
    [int]$state.installResult.candidateInstallCount -eq 1 -and
    [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and
    [string]$state.installResult.versionName -ceq [string]$state.candidate.versionName -and
    [string]$state.installResult.versionCode -ceq [string]$state.candidate.versionCode -and
    [bool]$state.installResult.playArtifactRelationshipProved
  ) -Message 'Play-installed OPPO identity is not sealed.'
}

Write-Output ('C30P Play Internal AAB gate passed: phase={0}; candidate={1}; buildCount={2}; uploadCount={3}; installCount={4}.' -f $Phase, $CandidateId, [int]$state.buildResult.buildCount, [int]$state.playReleaseResult.uploadCount, [int]$state.installResult.candidateInstallCount)
