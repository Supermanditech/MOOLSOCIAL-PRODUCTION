[CmdletBinding()]
param(
  [string]$StatePath,
  [string]$CandidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T',
  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'reconcile',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30t.json' }

function Assert-C30T {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30T Play Internal AAB gate rejected: $Message" }
}
function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30T -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label path is missing."
  Assert-C30T -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30T -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30T -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}

$stateFile = [IO.Path]::GetFullPath($StatePath)
Assert-C30T -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'state escaped the repository.'
Assert-C30T -Condition (Test-Path -LiteralPath $stateFile -PathType Leaf) -Message 'state is missing.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30T -Condition ([int]$state.schemaVersion -eq 1 -and [string]$state.contractId -ceq 'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30T-001') -Message 'state contract changed.'
Assert-C30T -Condition ([string]$state.candidate.id -ceq $CandidateId) -Message 'candidate changed.'
Assert-C30T -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.45' -and
  [string]$state.candidate.versionCode -ceq '2026081345' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate is not exact r60.45.'

$branch = (& git -C $root branch --show-current).Trim()
Assert-C30T -Condition ($LASTEXITCODE -eq 0 -and $branch -ceq [string]$state.candidate.branch) -Message 'branch changed.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30T -Condition ($LASTEXITCODE -eq 0 -and $head -ceq [string]$state.candidate.head) -Message 'HEAD changed.'

$ticketPath = Resolve-RepoFile -Path 'config/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-ticket.json' -Label 'ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C30T -Condition ((Get-FileHash -LiteralPath $ticketPath -Algorithm SHA256).Hash -ceq 'F9D499078CB1E80D63B4E7C1AAC053189A01717EEBC73896EB160F0D8CC39CD5') -Message 'sealed ticket hash changed.'
Assert-C30T -Condition ([string]$ticket.ticketId -ceq $CandidateId -and [string]$ticket.classification -ceq 'mvp_required') -Message 'ticket identity or classification changed.'
Assert-C30T -Condition ([bool]$ticket.authority.buildAuthorized -and [bool]$ticket.authority.uploadAuthorized -and [bool]$ticket.authority.deviceInstallAuthorized -and [bool]$ticket.authority.backendWriteAuthorized) -Message 'founder authority is missing.'
Assert-C30T -Condition (-not [bool]$ticket.authority.productionWriteAuthorized -and -not [bool]$ticket.authority.emailOrQuotaSubmissionAuthorized -and -not [bool]$ticket.authority.secretValueAccessAuthorized) -Message 'forbidden authority expanded.'

$aggregate = Get-Content -Raw -LiteralPath (Resolve-RepoFile -Path ([string]$state.aggregateStatePath) -Label 'aggregate state') | ConvertFrom-Json
Assert-C30T -Condition ([string]$aggregate.contractId -ceq 'PLAY-INTERNAL-LIVE-READ-RECOVERY-GATES-C30T-001') -Message 'aggregate state contract changed.'
Assert-C30T -Condition ([string]$aggregate.candidate.successorVersionName -ceq '1.0.0-r60.45' -and [string]$aggregate.candidate.successorVersionCode -ceq '2026081345') -Message 'aggregate candidate changed.'
Assert-C30T -Condition ([int]$aggregate.candidate.buildLimit -eq 1 -and [int]$aggregate.candidate.uploadLimit -eq 1 -and [int]$aggregate.candidate.installLimit -eq 1) -Message 'aggregate single-action limits changed.'

$predecessor = Get-Content -Raw -LiteralPath (Resolve-RepoFile -Path ([string]$state.predecessor.statePath) -Label 'C30S predecessor') | ConvertFrom-Json
Assert-C30T -Condition ([int]$predecessor.installResult.candidateInstallCount -eq 1 -and [string]$predecessor.installResult.installerPackageName -ceq 'com.android.vending' -and [string]$predecessor.installResult.installedVersionCode -ceq '2026081244') -Message 'C30S Play predecessor identity changed.'
Assert-C30T -Condition ([int]$predecessor.journeyResult.createWritesAttempted -eq 0) -Message 'C30S predecessor write count changed.'

Assert-C30T -Condition ([string]$state.distribution.authorizedTrack -ceq 'internal' -and -not [bool]$state.distribution.productionTrackAuthorized -and -not [bool]$state.distribution.openTestingAuthorized -and -not [bool]$state.distribution.publicListingAuthorized) -Message 'distribution boundary changed.'
Assert-C30T -Condition ([string]$state.firebase.projectId -ceq 'moolsocial-dev-503018' -and [string]$state.firebase.androidAppId -ceq '1:760290687711:android:4202409fd3ab38f6ce076a' -and [string]$state.firebase.androidApiKeyRestrictionState -ceq 'qualified_exact_two_package_certificate_pairs_27_api_targets') -Message 'Firebase identity or API-key restriction qualification changed.'
Assert-C30T -Condition (-not [bool]$state.firebase.apiKeyPersistedOrReadByAgent -and -not [bool]$state.firebase.privateVerdictReadAuthorized) -Message 'Firebase secret boundary changed.'
Assert-C30T -Condition (
  [string]$state.providerRevisions.moolsocialcontent -ceq 'moolsocialcontent-00004-gig' -and
  [string]$state.providerRevisions.moolsocialchat -ceq 'moolsocialchat-00001-yaf' -and
  [string]$state.providerRevisions.youtubeprovider -ceq 'youtubeprovider-00038-cic' -and
  [string]$state.providerRevisions.youtubeoauthcallback -ceq 'youtubeoauthcallback-00035-cir' -and
  [bool]$state.providerRevisions.backendDeploymentCompleted -and
  -not [bool]$state.providerRevisions.additionalBackendDeploymentAuthorized
) -Message 'qualified provider revisions or deployment boundary changed.'
Assert-C30T -Condition (-not [bool]$state.installResult.uninstallPerformed -and -not [bool]$state.installResult.dataClearPerformed -and -not [bool]$state.installResult.downgradePerformed -and -not [bool]$state.installResult.adbInstallPerformed -and -not [bool]$state.installResult.secondInstallPerformed) -Message 'forbidden device mutation recorded.'
Assert-C30T -Condition ([int]$state.journeyResult.createWritesAttempted -le 6 -and [int]$state.journeyResult.chatMessagesSent -eq 0 -and -not [bool]$state.journeyResult.chatMessagesAuthorized) -Message 'runtime write boundary changed.'
Assert-C30T -Condition (-not [bool]$state.communicationHold.emailSent -and -not [bool]$state.communicationHold.quotaSubmitted) -Message 'communication hold changed.'

$memoryPhase = if ($Phase -in @('preinstall', 'postinstall', 'journey')) { 'device' } else { 'implementation' }
& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase $memoryPhase -BuildMode none -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $CandidateId -RequireExecutionAuthorized -RepositoryRoot $root

switch ($Phase) {
  'build' {
    Assert-C30T -Condition (
      [string]$state.machineState -ceq 'source_qualified_founder_secret_prompt_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [bool]$state.sourceQualification.comprehensiveReleaseAuditPassed -and
      [bool]$state.sourceQualification.backendVerifyPassed -and
      [bool]$state.sourceQualification.focusedSocialSuitePassed -and
      [bool]$state.sourceQualification.releaseFirebaseStaticGatePassed -and
      [bool]$state.sourceQualification.completeRegressionGatePassed -and
      [int]$state.sourceQualification.identicalQualifyingCycles -eq 2 -and
      [bool]$aggregate.candidate.prebuildQualificationPassed -and
      [string]$aggregate.candidate.sourceFingerprint -ceq [string]$state.sourceQualification.manifestSha256
    ) -Message 'single build is not ready or source fingerprints differ.'
  }
  'postbuild' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and [string]$state.buildAuthorization -ceq 'consumed' -and [int]$state.buildResult.buildCount -eq 1 -and [int]$aggregate.candidate.buildCount -eq 1 -and [bool]$state.buildResult.crashlyticsBuildIdResourceProved -and [bool]$state.buildResult.googleAppIdResourceProved) -Message 'postbuild artifact proof is incomplete.'
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.artifactPath) -Label 'sealed AAB')
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.provenance) -Label 'AAB provenance')
  }
  'preupload' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and [int]$state.buildResult.buildCount -eq 1 -and [int]$state.playReleaseResult.uploadCount -eq 0) -Message 'upload is not ready.'
  }
  'postupload' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and [int]$state.playReleaseResult.uploadCount -eq 1 -and [int]$aggregate.candidate.uploadCount -eq 1 -and [string]$state.playReleaseResult.track -ceq 'internal' -and [string]$state.playReleaseResult.versionCode -ceq '2026081345') -Message 'Internal release proof is incomplete.'
  }
  'preinstall' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and [int]$state.installResult.candidateInstallCount -eq 0) -Message 'in-place Play update is not ready.'
  }
  'postinstall' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and [int]$state.installResult.candidateInstallCount -eq 1 -and [int]$aggregate.candidate.installCount -eq 1 -and [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and [string]$state.installResult.installedVersionCode -ceq '2026081345') -Message 'Play update identity proof is incomplete.'
  }
  'journey' {
    Assert-C30T -Condition ([string]$state.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and [string]$state.installResult.installedVersionCode -ceq '2026081345') -Message 'runtime is not authorized for journeys.'
  }
  default {
    Assert-C30T -Condition ([int]$state.buildResult.buildCount -in @(0, 1) -and [int]$state.playReleaseResult.uploadCount -in @(0, 1) -and [int]$state.installResult.candidateInstallCount -in @(0, 1)) -Message 'single-action counts are invalid.'
  }
}

Write-Output "C30T Play Internal AAB gate passed: phase=$Phase; buildCount=$($state.buildResult.buildCount); uploadCount=$($state.playReleaseResult.uploadCount); installCount=$($state.installResult.candidateInstallCount)."
