[CmdletBinding()]
param(
  [string]$StatePath,
  [string]$CandidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S',
  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')][string]$Phase = 'reconcile',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30s.json' }

function Assert-C30S {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30S Play Internal AAB gate rejected: $Message" }
}
function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30S -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label path is missing."
  Assert-C30S -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30S -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30S -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}

$stateFile = [IO.Path]::GetFullPath($StatePath)
Assert-C30S -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'state escaped the repository.'
Assert-C30S -Condition (Test-Path -LiteralPath $stateFile -PathType Leaf) -Message 'state is missing.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30S -Condition ([int]$state.schemaVersion -eq 1 -and [string]$state.contractId -ceq 'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30S-001') -Message 'state contract changed.'
Assert-C30S -Condition ([string]$state.candidate.id -ceq $CandidateId) -Message 'candidate changed.'
Assert-C30S -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.44' -and
  [string]$state.candidate.versionCode -ceq '2026081244' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate is not exact r60.44.'

$branch = (& git -C $root branch --show-current).Trim()
Assert-C30S -Condition ($LASTEXITCODE -eq 0 -and $branch -ceq [string]$state.candidate.branch) -Message 'branch changed.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30S -Condition ($LASTEXITCODE -eq 0 -and $head -ceq [string]$state.candidate.head) -Message 'HEAD changed.'

$ticket = Get-Content -Raw -LiteralPath (Resolve-RepoFile -Path 'config/uaw-personal-mvp-social-play-internal-firebase-startup-recovery-c30s-ticket.json' -Label 'ticket') | ConvertFrom-Json
Assert-C30S -Condition ([string]$ticket.ticketId -ceq $CandidateId -and [string]$ticket.classification -ceq 'mvp_required') -Message 'ticket identity or classification changed.'
Assert-C30S -Condition ([bool]$ticket.authority.buildAuthorized -and [bool]$ticket.authority.uploadAuthorized -and [bool]$ticket.authority.deviceInstallAuthorized) -Message 'founder build, upload or install authority is missing.'
Assert-C30S -Condition (-not [bool]$ticket.authority.backendWriteAuthorized -and -not [bool]$ticket.authority.productionWriteAuthorized -and -not [bool]$ticket.authority.emailOrQuotaSubmissionAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) -Message 'forbidden authority expanded.'

$predecessor = Get-Content -Raw -LiteralPath (Resolve-RepoFile -Path ([string]$state.predecessor.statePath) -Label 'C30R predecessor') | ConvertFrom-Json
Assert-C30S -Condition ([string]$predecessor.machineState -ceq 'Play_installed_identity_sealed_runtime_rejected_missing_Crashlytics_build_ID') -Message 'C30R rejection changed.'
Assert-C30S -Condition ([int]$predecessor.installResult.candidateInstallCount -eq 1 -and [string]$predecessor.installResult.installerPackageName -ceq 'com.android.vending') -Message 'C30R Play install identity changed.'
Assert-C30S -Condition ([int]$predecessor.journeyResult.createWritesAttempted -eq 0) -Message 'C30R write count changed.'

Assert-C30S -Condition ([string]$state.distribution.authorizedTrack -ceq 'internal' -and -not [bool]$state.distribution.productionTrackAuthorized -and -not [bool]$state.distribution.openTestingAuthorized -and -not [bool]$state.distribution.publicListingAuthorized) -Message 'distribution boundary changed.'
Assert-C30S -Condition ([string]$state.firebase.projectId -ceq 'moolsocial-dev-503018' -and [string]$state.firebase.androidAppId -ceq '1:760290687711:android:4202409fd3ab38f6ce076a' -and [string]$state.firebase.crashlyticsGradlePluginVersion -ceq '3.0.7') -Message 'Firebase identity changed.'
Assert-C30S -Condition (-not [bool]$state.firebase.apiKeyPersistedOrReadByAgent -and -not [bool]$state.firebase.privateVerdictReadAuthorized) -Message 'Firebase secret boundary changed.'
Assert-C30S -Condition ([string]$state.providerRevisions.moolsocialcontent -ceq 'moolsocialcontent-00003-juw' -and [string]$state.providerRevisions.youtubeprovider -ceq 'youtubeprovider-00036-qer' -and [string]$state.providerRevisions.youtubeoauthcallback -ceq 'youtubeoauthcallback-00035-cir' -and -not [bool]$state.providerRevisions.backendDeploymentAuthorized) -Message 'provider revisions or deployment boundary changed.'
Assert-C30S -Condition (-not [bool]$state.installResult.uninstallPerformed -and -not [bool]$state.installResult.dataClearPerformed -and -not [bool]$state.installResult.downgradePerformed -and -not [bool]$state.installResult.adbInstallPerformed -and -not [bool]$state.installResult.secondInstallPerformed) -Message 'forbidden device mutation recorded.'
Assert-C30S -Condition (-not [bool]$state.communicationHold.emailSent -and -not [bool]$state.communicationHold.quotaSubmitted) -Message 'communication hold changed.'

$phaseMemory = if ($Phase -in @('preinstall', 'postinstall', 'journey')) { 'device' } else { 'implementation' }
& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase $phaseMemory -BuildMode none
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $CandidateId -RequireExecutionAuthorized -RepositoryRoot $root

switch ($Phase) {
  'build' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'source_qualified_founder_secret_prompt_required' -and [string]$state.buildAuthorization -ceq 'available_once' -and [int]$state.buildResult.buildCount -eq 0 -and [bool]$state.sourceQualification.comprehensiveReleaseAuditPassed -and [bool]$state.sourceQualification.registeredPluginStartupAuditPassed -and [bool]$state.sourceQualification.manifestPermissionComponentAuditPassed -and [bool]$state.sourceQualification.releaseDependencyAndR8AuditPassed -and [bool]$state.sourceQualification.secretAndEnvironmentAuditPassed -and [bool]$state.sourceQualification.updateRetentionAndRecoveryAuditPassed -and [bool]$state.sourceQualification.releaseFirebaseStaticGatePassed -and [bool]$state.sourceQualification.completeRegressionGatePassed -and [int]$state.sourceQualification.identicalQualifyingCycles -eq 2) -Message 'single build is not ready or the comprehensive release audit is incomplete.'
  }
  'postbuild' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and [string]$state.buildAuthorization -ceq 'consumed' -and [int]$state.buildResult.buildCount -eq 1 -and [bool]$state.buildResult.crashlyticsBuildIdResourceProved -and [bool]$state.buildResult.googleAppIdResourceProved) -Message 'postbuild artifact proof is incomplete.'
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.artifactPath) -Label 'sealed AAB')
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.provenance) -Label 'AAB provenance')
  }
  'preupload' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and [int]$state.buildResult.buildCount -eq 1 -and [int]$state.playReleaseResult.uploadCount -eq 0) -Message 'upload is not ready.'
  }
  'postupload' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and [int]$state.playReleaseResult.uploadCount -eq 1 -and [string]$state.playReleaseResult.track -ceq 'internal' -and [string]$state.playReleaseResult.versionCode -ceq '2026081244') -Message 'Internal release proof is incomplete.'
  }
  'preinstall' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and [int]$state.installResult.candidateInstallCount -eq 0) -Message 'in-place Play update is not ready.'
  }
  'postinstall' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'Play_installed_identity_sealed_first_frame_pending' -and [int]$state.installResult.candidateInstallCount -eq 1 -and [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and [string]$state.installResult.installedVersionCode -ceq '2026081244') -Message 'Play update identity proof is incomplete.'
  }
  'journey' {
    Assert-C30S -Condition ([string]$state.machineState -ceq 'Play_installed_first_frame_and_App_Check_qualified_journeys_authorized' -and [string]$state.journeyResult.firstFlutterFrame -ceq 'passed' -and [string]$state.journeyResult.appCheck -ceq 'passed') -Message 'runtime is not authorized for journeys.'
  }
  default {
    Assert-C30S -Condition ([int]$state.buildResult.buildCount -in @(0, 1) -and [int]$state.playReleaseResult.uploadCount -in @(0, 1) -and [int]$state.installResult.candidateInstallCount -in @(0, 1)) -Message 'single-action counts are invalid.'
  }
}

Write-Output "C30S Play Internal AAB gate passed: phase=$Phase; buildCount=$($state.buildResult.buildCount); uploadCount=$($state.playReleaseResult.uploadCount); installCount=$($state.installResult.candidateInstallCount)."
