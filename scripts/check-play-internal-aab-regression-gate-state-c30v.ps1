[CmdletBinding()]
param(
  [string]$StatePath,
  [string]$CandidateId = 'UAW-C30V-R60-47-SEAL-RECOVERY-PLAY-INTERNAL-ACCEPTANCE',
  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'reconcile',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30v.json'
}

function Assert-C30V {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30V Play Internal AAB gate rejected: $Message" }
}

function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30V -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label path is missing."
  Assert-C30V -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30V -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30V -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}

function Assert-SourceManifestCurrent {
  param([Parameter(Mandatory)][string]$Path)
  foreach ($line in Get-Content -LiteralPath $Path) {
    $row = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C30V -Condition $row.Success -Message 'source manifest row is malformed.'
    $owner = Resolve-RepoFile -Path $row.Groups[2].Value -Label 'source owner'
    Assert-C30V -Condition (
      (Get-FileHash -LiteralPath $owner -Algorithm SHA256).Hash -ceq $row.Groups[1].Value
    ) -Message "source changed after qualification: $($row.Groups[2].Value)"
  }
}

$stateFile = [IO.Path]::GetFullPath($StatePath)
Assert-C30V -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'state escaped the repository.'
Assert-C30V -Condition (Test-Path -LiteralPath $stateFile -PathType Leaf) -Message 'state is missing.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30V -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq 'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30V-001'
) -Message 'state contract changed.'
Assert-C30V -Condition ([string]$state.candidate.id -ceq $CandidateId) -Message 'candidate changed.'
Assert-C30V -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.47' -and
  [string]$state.candidate.versionCode -ceq '2026081347' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate is not exact r60.47.'

$branch = (& git -C $root branch --show-current).Trim()
Assert-C30V -Condition ($LASTEXITCODE -eq 0 -and $branch -ceq [string]$state.candidate.branch) -Message 'branch changed.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30V -Condition ($LASTEXITCODE -eq 0 -and $head -ceq [string]$state.candidate.head) -Message 'HEAD changed.'

$ticketPath = Resolve-RepoFile -Path ([string]$state.ticketPath) -Label 'ticket'
$ticketHash = (Get-FileHash -LiteralPath $ticketPath -Algorithm SHA256).Hash
Assert-C30V -Condition ($ticketHash -ceq [string]$state.ticketSha256) -Message 'sealed ticket hash changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C30V -Condition (
  [string]$ticket.ticketId -ceq $CandidateId -and
  [string]$ticket.classification -ceq 'mvp_required'
) -Message 'ticket identity or classification changed.'

$qualifierPath = Resolve-RepoFile -Path 'scripts/qualify-play-internal-seal-recovery-c30v.ps1' -Label 'C30V qualifier'
$qualifierText = Get-Content -Raw -LiteralPath $qualifierPath
Assert-C30V -Condition (
  -not $qualifierText.Contains('cmd package get-install-source') -and
  $qualifierText.Contains('shell pm list packages -i com.moolsocial.app 2>&1') -and
  $qualifierText.Contains('$installSourceExit = $LASTEXITCODE') -and
  $qualifierText.Contains('$installSourceExit -eq 0 -and $playInstallerRows.Count -eq 1') -and
  -not $qualifierText.Contains('$manifestFileCount -gt 1109') -and
  $qualifierText.Contains('07-source-aggregate-manifest-accepted-v7.txt') -and
  $qualifierText.Contains('08-qualifying-cycle-1-v6.json') -and
  $qualifierText.Contains('09-qualifying-cycle-2-v6.json') -and
  $qualifierText.Contains('10-final-pre-aab-qualification-summary-v6.json') -and
  $qualifierText.Contains('$logStem-source-manifest-provisional.txt') -and
  $qualifierText.Contains('protectedSourceOwners=206; missingProtectedSourceOwners=0')
) -Message 'C30V qualifier does not preserve the OPPO-supported exact Google Play installer gate.'

Assert-C30V -Condition (
  -not [bool]$ticket.authority.DevMoolSocialContentDeploymentAuthorized -and
  [bool]$ticket.authority.buildAuthorized -and
  [bool]$ticket.authority.uploadAuthorized -and
  [bool]$ticket.authority.deviceInstallAuthorized -and
  [int]$ticket.authority.buildLimit -eq 1 -and
  [int]$ticket.authority.uploadLimit -eq 1 -and
  [int]$ticket.authority.installLimit -eq 1 -and
  [string]$ticket.authority.authorizedTrack -ceq 'internal'
) -Message 'founder authority is missing or expanded.'
Assert-C30V -Condition (
  -not [bool]$ticket.authority.HostingDeploymentAuthorized -and
  -not [bool]$ticket.authority.youtubeProviderDeploymentAuthorized -and
  -not [bool]$ticket.authority.youtubeOAuthCallbackDeploymentAuthorized -and
  -not [bool]$ticket.authority.moolSocialChatDeploymentAuthorized -and
  -not [bool]$ticket.authority.rulesOrIamMutationAuthorized -and
  -not [bool]$ticket.authority.productionOpenClosedOrPublicAuthorized -and
  -not [bool]$ticket.authority.emailOrQuotaSubmissionAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'forbidden ticket authority expanded.'

$aggregatePath = Resolve-RepoFile -Path ([string]$state.aggregateStatePath) -Label 'aggregate state'
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
Assert-C30V -Condition (
  [string]$aggregate.contractId -ceq 'PLAY-INTERNAL-SEAL-RECOVERY-ACCEPTANCE-GATES-C30V-001' -and
  [string]$aggregate.candidate.id -ceq $CandidateId -and
  [string]$aggregate.candidate.versionName -ceq '1.0.0-r60.47' -and
  [string]$aggregate.candidate.versionCode -ceq '2026081347' -and
  [string]$aggregate.candidate.authorizedTrack -ceq 'internal' -and
  [int]$aggregate.candidate.buildLimit -eq 1 -and
  [int]$aggregate.candidate.uploadLimit -eq 1 -and
  [int]$aggregate.candidate.installLimit -eq 1
) -Message 'aggregate candidate changed.'
Assert-C30V -Condition (
  -not [bool]$aggregate.authority.DevMoolSocialContentDeploymentAuthorized -and
  [bool]$aggregate.authority.buildAuthorized -and
  [bool]$aggregate.authority.uploadAuthorized -and
  [bool]$aggregate.authority.installAuthorized -and
  -not [bool]$aggregate.authority.HostingDeploymentAuthorized -and
  -not [bool]$aggregate.authority.youtubeProviderDeploymentAuthorized -and
  -not [bool]$aggregate.authority.youtubeOAuthCallbackDeploymentAuthorized -and
  -not [bool]$aggregate.authority.moolSocialChatDeploymentAuthorized -and
  -not [bool]$aggregate.authority.firestoreOrStorageRulesDeploymentAuthorized -and
  -not [bool]$aggregate.authority.iamMutationAuthorized -and
  -not [bool]$aggregate.authority.productionOpenClosedOrPublicAuthorized -and
  -not [bool]$aggregate.authority.uninstallDataClearDowngradeSideloadOrAdbInstallAuthorized -and
  -not [bool]$aggregate.authority.emailOrQuotaSubmissionAuthorized -and
  -not [bool]$aggregate.authority.secretValueAccessAuthorized
) -Message 'aggregate authority boundary changed.'

$predecessorAabPath = Resolve-RepoFile -Path ([string]$aggregate.predecessor.aabStatePath) -Label 'C30U abandoned AAB predecessor'
$predecessorAggregatePath = Resolve-RepoFile -Path ([string]$aggregate.predecessor.aggregateStatePath) -Label 'C30U abandoned aggregate predecessor'
Assert-C30V -Condition (
  (Get-FileHash -LiteralPath $predecessorAabPath -Algorithm SHA256).Hash -ceq [string]$aggregate.predecessor.aabStateSha256 -and
  (Get-FileHash -LiteralPath $predecessorAggregatePath -Algorithm SHA256).Hash -ceq [string]$aggregate.predecessor.aggregateStateSha256
) -Message 'sealed predecessor state changed.'
$predecessor = Get-Content -Raw -LiteralPath $predecessorAabPath | ConvertFrom-Json
Assert-C30V -Condition (
  [string]$predecessor.buildAuthorization -ceq 'consumed' -and
  [int]$predecessor.buildResult.buildCount -eq 1 -and
  [int]$predecessor.playReleaseResult.uploadCount -eq 0 -and
  [int]$predecessor.installResult.candidateInstallCount -eq 0 -and
  [string]$predecessor.candidate.versionCode -ceq '2026081346' -and
  [string]$predecessor.candidate.versionName -ceq '1.0.0-r60.46' -and
  [string]$predecessor.buildResult.artifactSha256 -ceq '105242061939B1557B3BCCCBFD40F8CEBBEDFB59BE3ED30839C3FFA90049D145'
) -Message 'consumed unuploaded r60.46 predecessor identity changed.'
$playPredecessorAabPath = Resolve-RepoFile -Path ([string]$aggregate.playInstalledPredecessor.aabStatePath) -Label 'C30T Play-installed AAB predecessor'
$playPredecessorAggregatePath = Resolve-RepoFile -Path ([string]$aggregate.playInstalledPredecessor.aggregateStatePath) -Label 'C30T Play-installed aggregate predecessor'
Assert-C30V -Condition (
  (Get-FileHash -LiteralPath $playPredecessorAabPath -Algorithm SHA256).Hash -ceq [string]$aggregate.playInstalledPredecessor.aabStateSha256 -and
  (Get-FileHash -LiteralPath $playPredecessorAggregatePath -Algorithm SHA256).Hash -ceq [string]$aggregate.playInstalledPredecessor.aggregateStateSha256
) -Message 'Play-installed predecessor state changed.'
$playPredecessor = Get-Content -Raw -LiteralPath $playPredecessorAabPath | ConvertFrom-Json
Assert-C30V -Condition (
  [int]$playPredecessor.playReleaseResult.uploadCount -eq 1 -and
  [int]$playPredecessor.installResult.candidateInstallCount -eq 1 -and
  [string]$playPredecessor.installResult.installerPackageName -ceq 'com.android.vending' -and
  [string]$playPredecessor.installResult.installedVersionCode -ceq '2026081345' -and
  [string]$playPredecessor.installResult.installedVersionName -ceq '1.0.0-r60.45'
) -Message 'consumed Play-installed r60.45 predecessor identity changed.'

Assert-C30V -Condition (
  [string]$aggregate.environment.firebaseProject -ceq 'moolsocial-dev-503018' -and
  [string]$aggregate.environment.firebaseAndroidAppId -ceq '1:760290687711:android:4202409fd3ab38f6ce076a' -and
  [string]$aggregate.environment.oppoSerial -ceq '2b3e0f71' -and
  [string]$aggregate.environment.oppoModel -ceq 'CPH2375'
) -Message 'environment identity changed.'
Assert-C30V -Condition (
  [string]$aggregate.providerAndHostingBoundary.deployTarget -ceq 'none' -and
  -not [bool]$aggregate.providerAndHostingBoundary.deploymentRequired -and
  [string]$aggregate.providerAndHostingBoundary.deploymentState -ceq 'preserved_no_deployment_authorized' -and
  [int]$aggregate.providerAndHostingBoundary.deploymentAttemptCount -eq 0 -and
  [int]$aggregate.providerAndHostingBoundary.deploymentCount -eq 0 -and
  [string]$aggregate.providerAndHostingBoundary.deployedRevision -ceq 'moolsocialcontent-00005-lep' -and
  -not [bool]$aggregate.providerAndHostingBoundary.hostingDeploymentRequired -and
  [string]$aggregate.providerAndHostingBoundary.currentHostingFingerprint -ceq [string]$aggregate.providerAndHostingBoundary.deployedHostingFingerprint -and
  [string]$aggregate.providerAndHostingBoundary.hostingRelease -ceq '1786609421461000' -and
  [string]$aggregate.providerAndHostingBoundary.hostingVersion -ceq '86a17ea7c0f4a41f'
) -Message 'provider or Hosting boundary changed.'
$deploymentManifest = Resolve-RepoFile -Path ([string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestPath) -Label 'deployment payload manifest'
Assert-C30V -Condition (
  (Get-FileHash -LiteralPath $deploymentManifest -Algorithm SHA256).Hash -ceq [string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestSha256
) -Message 'deployment payload manifest checksum changed.'
$deploymentPayload = Get-Content -Raw -LiteralPath $deploymentManifest | ConvertFrom-Json
Assert-C30V -Condition (
  [string]$deploymentPayload.exactDeployTarget -ceq 'functions:provider:moolSocialContent' -and
  [string]$deploymentPayload.backendPayload.sourceFingerprint -ceq [string]$aggregate.providerAndHostingBoundary.deploymentPayloadFingerprint -and
  [bool]$deploymentPayload.hostingPayload.unchanged -and
  -not [bool]$deploymentPayload.hostingPayload.deploymentAuthorized -and
  [string]$deploymentPayload.restoredIgnoredEnvironmentSha256 -ceq '5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702' -and
  -not [bool]$deploymentPayload.ignoredEnvironmentValuesReadByAgent
) -Message 'deployment payload or secret boundary changed.'
Assert-C30V -Condition (
  [string]$state.firebaseAppCheck.projectId -ceq 'moolsocial-dev-503018' -and
  [string]$state.firebaseAppCheck.androidAppId -ceq '1:760290687711:android:4202409fd3ab38f6ce076a' -and
  [string]$state.firebaseAppCheck.packageName -ceq 'com.moolsocial.app' -and
  [bool]$state.firebaseAppCheck.playProjectLinked -and
  [bool]$state.firebaseAppCheck.playIntegrityApiEnabled -and
  [bool]$state.firebaseAppCheck.playIntegrityProviderConfigured -and
  [bool]$state.firebaseAppCheck.playAppSigningCertificateRegistered -and
  -not [bool]$state.firebaseAppCheck.privateVerdictReadAuthorized
) -Message 'Firebase App Check boundary changed.'
Assert-C30V -Condition (
  -not [bool]$state.signingQualification.secretValuesRecorded -and
  -not [bool]$state.signingQualification.agentSecretValueAccessAuthorized -and
  -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent
) -Message 'secret-value boundary changed.'
Assert-C30V -Condition (
  -not [bool]$state.installResult.uninstallPerformed -and
  -not [bool]$state.installResult.dataClearPerformed -and
  -not [bool]$state.installResult.downgradePerformed -and
  -not [bool]$state.installResult.adbInstallPerformed -and
  -not [bool]$state.installResult.secondInstallPerformed -and
  -not [bool]$state.playReleaseResult.productionRolloutPerformed -and
  -not [bool]$state.playReleaseResult.openTestingRolloutPerformed -and
  -not [bool]$state.playReleaseResult.closedTestingRolloutPerformed -and
  -not [bool]$state.playReleaseResult.publicListingMutationPerformed -and
  -not [bool]$aggregate.communicationHold.emailSent -and
  -not [bool]$aggregate.communicationHold.quotaSubmitted
) -Message 'forbidden mutation recorded.'
Assert-C30V -Condition (
  [int]$state.buildResult.buildCount -in @(0, 1) -and
  [int]$state.playReleaseResult.uploadCount -in @(0, 1) -and
  [int]$state.installResult.candidateInstallCount -in @(0, 1) -and
  [int]$aggregate.candidate.buildCount -eq [int]$state.buildResult.buildCount -and
  [int]$aggregate.candidate.uploadCount -eq [int]$state.playReleaseResult.uploadCount -and
  [int]$aggregate.candidate.installCount -eq [int]$state.installResult.candidateInstallCount
) -Message 'single-action counts are invalid or differ.'

$memoryPhase = if ($Phase -in @('preinstall', 'postinstall', 'journey')) { 'device' } else { 'implementation' }
& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase $memoryPhase -BuildMode none -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RequireTicketSelectionAssessment -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $CandidateId -RequireExecutionAuthorized -RepositoryRoot $root

if ([string]$state.sourceQualification.state -ceq 'passed_two_identical_cycles_with_preserved_Dev_services') {
  $sourceManifest = Resolve-RepoFile -Path ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
  Assert-C30V -Condition (
    (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash -ceq [string]$state.sourceQualification.manifestSha256
  ) -Message 'source manifest checksum changed.'
  Assert-SourceManifestCurrent -Path $sourceManifest
}

switch ($Phase) {
  'build' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'source_qualified_founder_secret_prompt_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [int]$state.sourceQualification.identicalQualifyingCycles -eq 2 -and
      [bool]$state.sourceQualification.completeRegressionGatePassed -and
      [bool]$state.sourceQualification.backendVerifyPassed -and
      [bool]$state.sourceQualification.hostingVerifyPassed -and
      [bool]$state.sourceQualification.focusedSocialSuitePassed -and
      [bool]$state.sourceQualification.analyzerPassed -and
      [bool]$state.sourceQualification.deploymentPassed -and
      [bool]$state.sourceQualification.releasePreflightPassed -and
      -not [bool]$state.providerRevisions.backendDeploymentCompleted -and
      -not [bool]$state.providerRevisions.additionalBackendDeploymentAuthorized -and
      -not [bool]$aggregate.providerAndHostingBoundary.deploymentRequired -and
      [int]$aggregate.providerAndHostingBoundary.deploymentCount -eq 0 -and
      -not [string]::IsNullOrWhiteSpace([string]$aggregate.providerAndHostingBoundary.deployedRevision) -and
      [string]$aggregate.sourceQualification.sourceFingerprintSha256 -ceq [string]$state.sourceQualification.manifestSha256 -and
      [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
      [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder
    ) -Message 'single build is not ready or final source/preserved-service proof differs.'
  }
  'postbuild' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [bool]$state.buildResult.crashlyticsBuildIdResourceProved -and
      [bool]$state.buildResult.googleAppIdResourceProved -and
      [bool]$state.buildResult.packageVersionManifestProved -and
      [bool]$state.buildResult.splitAndArm64PayloadProved -and
      [bool]$state.buildResult.mergedReleaseManifestProved
    ) -Message 'postbuild artifact proof is incomplete.'
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.artifactPath) -Label 'sealed AAB')
    [void](Resolve-RepoFile -Path ([string]$state.buildResult.provenance) -Label 'AAB provenance')
  }
  'preupload' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$state.playReleaseResult.uploadCount -eq 0
    ) -Message 'upload is not ready.'
  }
  'postupload' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [int]$state.playReleaseResult.uploadCount -eq 1 -and
      [string]$state.playReleaseResult.track -ceq 'internal' -and
      [string]$state.playReleaseResult.versionCode -ceq '2026081347' -and
      [string]$state.playReleaseResult.versionName -ceq '1.0.0-r60.47'
    ) -Message 'Internal release proof is incomplete.'
  }
  'preinstall' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [int]$state.installResult.candidateInstallCount -eq 0
    ) -Message 'in-place Play update is not ready.'
  }
  'postinstall' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and
      [int]$state.installResult.candidateInstallCount -eq 1 -and
      [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and
      [string]$state.installResult.installedVersionCode -ceq '2026081347' -and
      [string]$state.installResult.installedVersionName -ceq '1.0.0-r60.47' -and
      [bool]$state.installResult.inPlacePlayUpdateProved
    ) -Message 'Play update identity proof is incomplete.'
  }
  'journey' {
    Assert-C30V -Condition (
      [string]$state.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and
      [string]$state.installResult.installedVersionCode -ceq '2026081347'
    ) -Message 'runtime is not authorized for journeys.'
  }
  default {
    Assert-C30V -Condition (
      [string]$state.machineState -in @(
        'pre_aab_reconciliation_in_progress_authority_available',
        'source_qualified_founder_secret_prompt_required',
        'single_release_AAB_succeeded_authority_consumed',
        'internal_release_active_upload_consumed',
        'Play_installed_identity_sealed_journeys_pending'
      )
    ) -Message 'machine state is not recognized.'
  }
}

Write-Output "C30V Play Internal AAB gate passed: phase=$Phase; buildCount=$($state.buildResult.buildCount); uploadCount=$($state.playReleaseResult.uploadCount); installCount=$($state.installResult.candidateInstallCount)."
