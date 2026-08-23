[CmdletBinding()]
param(
  [ValidateSet('source', 'preprompt', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'source',

  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c34i.json',

  [string]$ScopePath = 'config/mvp-scope-gate-state.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34I {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34I r60.73 privacy-safe release gate rejected: $Message"
  }
}

function Resolve-C34IFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34I -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is blank."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C34I -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the production repository."
  return $resolved
}

function Assert-C34IPowerShellOwner {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C34I -Condition (@($errors).Count -eq 0) `
    -Message "$Label PowerShell parser rejected the owner."
}

function Assert-C34IManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  $rows = @(Get-Content -LiteralPath $ManifestPath)
  Assert-C34I -Condition ($rows.Count -gt 0) -Message 'source manifest is empty.'
  foreach ($row in $rows) {
    $match = [regex]::Match($row, '^([0-9A-F]{64})  (.+)$')
    Assert-C34I -Condition $match.Success -Message 'source-manifest row is malformed.'
    $owner = Resolve-C34IFile -Path $match.Groups[2].Value -Label 'sealed source owner'
    Assert-C34I -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
        $match.Groups[1].Value
    ) -Message "source changed after seal: $($match.Groups[2].Value)"
  }
}

$ticketId = 'UAW-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-PLAY-OPPO-ACCEPTANCE'
$ticketPath = Resolve-C34IFile `
  -Path 'config/uaw-c34i-r60-73-authentication-privacy-safe-play-oppo-acceptance-ticket.json' `
  -Label 'C34I ticket'
$ticketHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C34I -Condition (
  $ticketHash -ceq '279EF1EF0D91B7152190B50EA0D6F0F01E93D8FC651E96D7E51C77601287AD9E' -and
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.candidate.versionName -ceq '1.0.0-r60.73' -and
  [string]$ticket.candidate.versionCode -ceq '2026081373' -and
  [string]$ticket.candidate.playTrack -ceq 'internal' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.within60To75DayLock -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [bool]$ticket.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$ticket.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$ticket.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  [bool]$ticket.authority.founderHiddenInputEntryAuthorized -and
  [bool]$ticket.authority.founderOnlyAuthenticationDialogHandlingRequired -and
  -not [bool]$ticket.authority.agentSecretPrivateIdentifierOrPrivateLinkAccessAuthorized -and
  -not [bool]$ticket.authority.otherTrackAuthorized -and
  -not [bool]$ticket.authority.adbInstallUninstallDataClearDowngradeOrSideloadAuthorized -and
  -not [bool]$ticket.authority.backendHostingProviderOrProductionDeploymentAuthorized
) -Message 'ticket identity, privacy boundary, reuse assessment or authority changed.'

$scopePathResolved = Resolve-C34IFile -Path $ScopePath -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePathResolved | ConvertFrom-Json
Assert-C34I -Condition (
  [string]$scope.ticket.id -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketHash -and
  [string]$scope.authorization.evidence -ceq
    'docs/quality/UAW-C34I-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md'
) -Message 'selected MVP ticket, assessment hash or founder authority changed.'

$statePathResolved = Resolve-C34IFile -Path $StatePath -Label 'C34I state'
$state = Get-Content -Raw -LiteralPath $statePathResolved | ConvertFrom-Json
$aggregatePath = Resolve-C34IFile `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C34I aggregate'
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
Assert-C34I -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001' -and
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.73' -and
  [string]$state.candidate.versionCode -ceq '2026081373' -and
  [string]$state.candidate.playTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71' -and
  [string]$state.candidate.deviceModel -ceq 'CPH2375'
) -Message 'state repository, candidate, package, track or OPPO identity changed.'
Assert-C34I -Condition (
  [string]$aggregate.contractId -ceq
    'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-AGGREGATE-001' -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq '1.0.0-r60.73' -and
  [string]$aggregate.candidate.versionCode -ceq '2026081373'
) -Message 'aggregate identity or candidate changed.'

$registryPath = Resolve-C34IFile `
  -Path 'config/codex-development-regression-registry.json' `
  -Label 'regression registry'
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
$registryCount = @($registry.entries).Count
$registryHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $registryPath).Hash
Assert-C34I -Condition (
  [int]$state.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [string]$state.regressionMemory.sealedRegistrySha256 -ceq $registryHash -and
  [int]$aggregate.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [string]$aggregate.regressionMemory.sealedRegistrySha256 -ceq $registryHash -and
  [bool]$state.regressionMemory.allEntriesAppliedBeforeSeal -and
  [bool]$state.regressionMemory.postSealRegistryChangeRejectsBuildOrPromotion -and
  [bool]$state.regressionMemory.anyHistoricalOrNewRegressionRejectsCandidate -and
  -not [bool]$state.regressionMemory.waiversAllowed
) -Message 'regression-memory count, hash or fail-closed rule changed.'

$policyPath = Resolve-C34IFile `
  -Path ([string]$state.releaseBinding.deviceActorPolicy) `
  -Label 'C34I device-actor policy'
$policyHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $policyPath).Hash
Assert-C34I -Condition (
  $policyHash -ceq [string]$state.releaseBinding.deviceActorPolicySha256 -and
  $policyHash -ceq [string]$state.sourcePrerequisites.deviceActorPolicySha256 -and
  $policyHash -ceq [string]$aggregate.deviceActorPolicy.sha256 -and
  [bool]$aggregate.deviceActorPolicy.founderOnlyAuthenticationDialogHandlingRequired
) -Message 'device-actor policy hash or founder-only binding changed.'
$actorPolicyGate = Resolve-C34IFile `
  -Path ([string]$state.sourcePrerequisites.deviceActorPolicyGatePath) `
  -Label 'C34I device-actor policy gate'
& $actorPolicyGate -RepositoryRoot $root -SelfTest | Out-Null

$c34hStatePath = Resolve-C34IFile `
  -Path 'config/successor-aab-regression-hard-gate-state-c34h.json' `
  -Label 'rejected C34H state'
$c34hState = Get-Content -Raw -LiteralPath $c34hStatePath | ConvertFrom-Json
$lastHistorical = @($state.historicalCandidates)[-1]
$lastAggregateHistorical = @($aggregate.historicalCandidates)[-1]
Assert-C34I -Condition (
  [string]$c34hState.machineState -ceq
    'postinstall_rejected_account_chooser_private_identifier_exposure_successor_required' -and
  [int]$c34hState.actionCounts.build -eq 1 -and
  [int]$c34hState.actionCounts.upload -eq 1 -and
  [int]$c34hState.actionCounts.install -eq 1 -and
  [int]$c34hState.actionCounts.deviceAcceptance -eq 0 -and
  [bool]$c34hState.privacyBoundary.privateAccountIdentifiersObserved -and
  -not [bool]$c34hState.rejection.artifactReusable -and
  [string]$lastHistorical.versionName -ceq '1.0.0-r60.72' -and
  [string]$lastHistorical.machineState -ceq [string]$c34hState.machineState -and
  [int]$lastHistorical.buildCount -eq 1 -and
  [int]$lastHistorical.uploadCount -eq 1 -and
  [int]$lastHistorical.installCount -eq 1 -and
  [int]$lastHistorical.deviceAcceptanceCount -eq 0 -and
  -not [bool]$lastHistorical.artifactReusable -and
  [string]$lastAggregateHistorical.versionName -ceq '1.0.0-r60.72' -and
  [int]$lastAggregateHistorical.buildCount -eq 1 -and
  [int]$lastAggregateHistorical.uploadCount -eq 1 -and
  [int]$lastAggregateHistorical.installCount -eq 1 -and
  [int]$lastAggregateHistorical.deviceAcceptanceCount -eq 0 -and
  -not [bool]$lastAggregateHistorical.artifactReusable
) -Message 'C34H privacy rejection, 1/1/1/0 history or nonreuse changed.'

Assert-C34I -Condition (
  [int]$state.actionCounts.build -eq [int]$aggregate.actionCounts.build -and
  [int]$state.actionCounts.upload -eq [int]$aggregate.actionCounts.upload -and
  [int]$state.actionCounts.install -eq [int]$aggregate.actionCounts.install -and
  [int]$state.actionCounts.deviceAcceptance -eq [int]$aggregate.actionCounts.deviceAcceptance -and
  [string]$state.releaseAuthorities.build -ceq [string]$aggregate.releaseAuthorities.build -and
  [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
    [string]$aggregate.releaseAuthorities.uploadAndInternalActivation -and
  [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
    [string]$aggregate.releaseAuthorities.inPlaceOppoPlayUpdate -and
  [string]$state.releaseAuthorities.postinstallAcceptance -ceq
    [string]$aggregate.releaseAuthorities.postinstallAcceptance
) -Message 'detailed/aggregate counts or release-authority parity changed.'
Assert-C34I -Condition (
  -not [bool]$state.privacyBoundary.secretValuesObserved -and
  -not [bool]$state.privacyBoundary.privateAccountIdentifiersObserved -and
  -not [bool]$state.privacyBoundary.privateLinksObserved -and
  -not [bool]$state.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$state.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$state.privacyBoundary.privateEmailLinkObserved -and
  -not [bool]$aggregate.privacyBoundary.secretValuesObserved -and
  -not [bool]$aggregate.privacyBoundary.privateAccountIdentifiersObserved -and
  -not [bool]$aggregate.privacyBoundary.privateLinksObserved
) -Message 'a secret, private identifier, private link or token boundary was crossed.'

Assert-C34I -Condition (
  [string]$state.releaseBinding.founderLauncher -ceq 'tmp/run-c34i-r60-73-single-aab-founder.ps1' -and
  [string]$state.releaseBinding.authoritativeAabWrapper -ceq 'scripts/invoke-play-internal-aab-build-c30t.ps1' -and
  [string]$state.releaseBinding.candidateGate -ceq
    'scripts/check-uaw-c34i-r60-73-authentication-privacy-safe-release-readiness.ps1' -and
  [string]$state.releaseBinding.postbuildRecoveryOwner -ceq
    'scripts/recover-uaw-c34i-r60-73-postbuild-lifecycle.ps1' -and
  [string]$state.releaseBinding.sourceCycleOwner -ceq
    'scripts/run-uaw-c34i-r60-73-source-cycle.ps1' -and
  [string]$state.releaseBinding.selectedTicketSha256 -ceq $ticketHash
) -Message 'release owner or selected-ticket binding changed.'

$ownerPaths = @(
  [string]$state.releaseBinding.founderLauncher,
  [string]$state.releaseBinding.authoritativeAabWrapper,
  [string]$state.releaseBinding.candidateGate,
  [string]$state.releaseBinding.postbuildRecoveryOwner,
  [string]$state.releaseBinding.sourceCycleOwner,
  [string]$state.sourcePrerequisites.deviceActorPolicyGatePath
)
foreach ($ownerRelative in $ownerPaths) {
  $ownerPath = Resolve-C34IFile -Path $ownerRelative -Label 'C34I release owner'
  Assert-C34IPowerShellOwner -Path $ownerPath -Label $ownerRelative
}

$launcher = Get-Content -Raw -LiteralPath (
  Resolve-C34IFile -Path ([string]$state.releaseBinding.founderLauncher) `
    -Label 'C34I founder launcher'
)
$wrapper = Get-Content -Raw -LiteralPath (
  Resolve-C34IFile -Path ([string]$state.releaseBinding.authoritativeAabWrapper) `
    -Label 'generic AAB wrapper'
)
$cycleOwner = Get-Content -Raw -LiteralPath (
  Resolve-C34IFile -Path ([string]$state.releaseBinding.sourceCycleOwner) `
    -Label 'C34I cycle owner'
)
$recoveryOwner = Get-Content -Raw -LiteralPath (
  Resolve-C34IFile -Path ([string]$state.releaseBinding.postbuildRecoveryOwner) `
    -Label 'C34I postbuild recovery owner'
)
Assert-C34I -Condition (
  $launcher.IndexOf('-Phase preprompt', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('-Phase preprompt', [StringComparison]::Ordinal) -lt
    $launcher.IndexOf("Read-Host 'Enter the moolsocial-upload-2026 password'", [StringComparison]::Ordinal) -and
  $launcher.IndexOf("founder_inputs_validated_single_aab_build_required", [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf("founder_inputs_validated_single_aab_build_required", [StringComparison]::Ordinal) -lt
    $launcher.IndexOf('& $wrapperPath -StatePath $statePath', [StringComparison]::Ordinal) -and
  $wrapper.IndexOf(
    "'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001' { 'check-uaw-c34i-r60-73-authentication-privacy-safe-release-readiness.ps1' }",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal) -ge 0 -and
  $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal) -lt
    $wrapper.IndexOf("`$state.buildAuthorization = 'consumed'", [StringComparison]::Ordinal) -and
  $cycleOwner.IndexOf('source-manifest-c34i-registry-2685.txt', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('registryEntryCount = 2685', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('82C4FCFB2B64951BD562481641BDAE59F0BD5340BED2B278A34F64E876F5FC72', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('scripts/check-release-device-acceptance-actor-policy-c34i.ps1', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('-SelfTest', [StringComparison]::Ordinal) -ge 0 -and
  $recoveryOwner.IndexOf(
    'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $recoveryOwner.IndexOf(
    'scripts/check-uaw-c34i-r60-73-authentication-privacy-safe-release-readiness.ps1',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'launcher, wrapper, cycle or recovery semantic binding changed.'

$runbookPath = Resolve-C34IFile `
  -Path ([string]$state.presealUploadWorkflow.runbookPath) `
  -Label 'C34I Internal Testing runbook'
$browserEvidencePath = Resolve-C34IFile `
  -Path ([string]$state.presealUploadWorkflow.evidencePath) `
  -Label 'C34I browser qualification'
$runbook = Get-Content -Raw -LiteralPath $runbookPath
$browserEvidence = Get-Content -Raw -LiteralPath $browserEvidencePath
Assert-C34I -Condition (
  [bool]$state.presealUploadWorkflow.liveBrowserRouteQualified -and
  [bool]$state.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
  [bool]$state.presealUploadWorkflow.internalTestingRouteProved -and
  [bool]$state.presealUploadWorkflow.noPlayWritePerformed -and
  [bool]$aggregate.presealUploadWorkflow.liveBrowserRouteQualified -and
  [bool]$aggregate.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.internalTestingRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.noPlayWritePerformed -and
  $runbook.Contains('The founder alone enters hidden build inputs') -and
  $runbook.Contains('stops before every provider tap') -and
  $runbook.Contains('After the source seal, repository discovery commands are prohibited.') -and
  $browserEvidence.Contains('No new browser action or Play write was performed') -and
  $browserEvidence.Contains('query-free allowlisted Play host/path')
) -Message 'presealed Internal Testing or founder-only device workflow changed.'

$mvpGate = Resolve-C34IFile `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $mvpGate -StatePath $scopePathResolved -CandidateId $ticketId `
  -RequireExecutionAuthorized -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C34IFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
$memoryPhase = if ($Phase -cin @('source', 'preprompt', 'build')) { 'build' } else { 'release' }
& $memoryGate -Phase $memoryPhase -BuildMode release -RepositoryRoot $root | Out-Null

$blockerGate = Resolve-C34IFile `
  -Path 'scripts/check-uaw-c33g-fix4-unresolved-acceptance-blocker-pre-aab-ledger.ps1' `
  -Label 'C33G acceptance-blocker gate'
$blockerPhase = if ($Phase -cin @('postinstall', 'journey')) { 'postinstall' } else { 'prebuild' }
& $blockerGate -CandidateId $ticketId -CandidateVersionCode '2026081373' `
  -Phase $blockerPhase -RepositoryRoot $root | Out-Null

$cycles = [int]$state.sourceQualification.completedIdenticalCycles
Assert-C34I -Condition (
  [int]$state.sourceQualification.requiredIdenticalCycles -eq 2 -and
  $cycles -eq [int]$aggregate.sourceQualification.completedIdenticalCycles
) -Message 'required or completed source-cycle parity changed.'

if ($Phase -ceq 'source') {
  if ($cycles -eq 0) {
    Assert-C34I -Condition (
      [int]$state.actionCounts.build -eq 0 -and
      [int]$state.actionCounts.upload -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0 -and
      [string]$state.buildAuthorization -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      [string]$state.releaseAuthorities.build -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
      -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
      -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
      -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
    ) -Message 'cycles-zero counts, held authority or false founder flags changed.'
    if ([string]$state.machineState -ceq 'prebuild_composition_registered_two_fresh_cycles_required') {
      Assert-C34I -Condition (
        [string]$aggregate.machineState -ceq $state.machineState -and
        $null -eq $state.sourceQualification.manifestSha256 -and
        $null -eq $aggregate.sourceQualification.manifestSha256 -and
        [int]$state.sourceQualification.fileCount -eq 0 -and
        [int]$aggregate.sourceQualification.fileCount -eq 0
      ) -Message 'pre-seal composition or empty manifest binding changed.'
    } elseif ([string]$state.machineState -ceq 'prebuild_manifest_bound_two_fresh_cycles_required') {
      Assert-C34I -Condition (
        [string]$aggregate.machineState -ceq $state.machineState -and
        -not [string]::IsNullOrWhiteSpace([string]$state.sourceQualification.manifestSha256) -and
        [string]$aggregate.sourceQualification.manifestSha256 -ceq
          [string]$state.sourceQualification.manifestSha256 -and
        [int]$state.sourceQualification.fileCount -gt 0 -and
        [int]$aggregate.sourceQualification.fileCount -eq
          [int]$state.sourceQualification.fileCount -and
        -not [string]::IsNullOrWhiteSpace([string]$state.sourceQualification.focusedManifestSha256) -and
        [string]$aggregate.sourceQualification.focusedManifestSha256 -ceq
          [string]$state.sourceQualification.focusedManifestSha256
      ) -Message 'manifest-bound cycles-zero state changed.'
      $manifestPath = Resolve-C34IFile `
        -Path ([string]$state.sourceQualification.manifestPath) `
        -Label 'C34I source manifest'
      Assert-C34I -Condition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash -ceq
          [string]$state.sourceQualification.manifestSha256
      ) -Message 'source-manifest bytes changed.'
      Assert-C34IManifestCurrent -ManifestPath $manifestPath
      $focusedPath = Resolve-C34IFile `
        -Path ([string]$state.sourceQualification.focusedManifestPath) `
        -Label 'C34I focused manifest'
      Assert-C34I -Condition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $focusedPath).Hash -ceq
          [string]$state.sourceQualification.focusedManifestSha256
      ) -Message 'focused-manifest bytes changed.'
    } else {
      throw 'C34I r60.73 privacy-safe release gate rejected: unsupported cycles-zero machine state.'
    }
  } elseif ($cycles -eq 2) {
    Assert-C34I -Condition (
      [bool]$state.sourceQualification.wholeMobileAnalyzerPassed -and
      [bool]$state.sourceQualification.flutterTestsPassed -and
      [bool]$state.sourceQualification.backendTestsPassed -and
      [bool]$state.sourceQualification.hostingTestsPassed -and
      [bool]$state.sourceQualification.dualPowerShellHostsPassed -and
      [bool]$state.sourceQualification.zeroFailures -and
      @($state.sourceQualification.cycleEvidence).Count -eq 2 -and
      [string]$state.machineState -cin @(
        'source_regression_memory_two_identical_cycles_qualified_build_authority_held',
        'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required'
      )
    ) -Message 'two-cycle qualification or declared transition changed.'
    $manifestPath = Resolve-C34IFile `
      -Path ([string]$state.sourceQualification.manifestPath) `
      -Label 'C34I sealed source manifest'
    Assert-C34IManifestCurrent -ManifestPath $manifestPath
  } else {
    throw 'C34I r60.73 privacy-safe release gate rejected: intermediate cycle persistence is forbidden.'
  }
}

if ($Phase -ceq 'preprompt') {
  Assert-C34I -Condition (
    $cycles -eq 2 -and
    [string]$state.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
    [string]$aggregate.machineState -ceq $state.machineState -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.build -ceq 'available_once' -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
  ) -Message 'preprompt authority or false founder flags changed.'
}

if ($Phase -ceq 'build') {
  Assert-C34I -Condition (
    $cycles -eq 2 -and
    [string]$state.machineState -ceq 'founder_inputs_validated_single_aab_build_required' -and
    [string]$aggregate.machineState -ceq $state.machineState -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.build -ceq 'available_once' -and
    [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent
  ) -Message 'postinput build authority or founder qualification flags changed.'
}

if ($Phase -ceq 'postbuild') {
  Assert-C34I -Condition (
    [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.actionCounts.install -eq 0 -and
    [int]$state.actionCounts.deviceAcceptance -eq 0 -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactPath) -and
    [string]$state.buildResult.artifactSha256 -match '^[0-9A-F]{64}$' -and
    [long]$state.buildResult.artifactBytes -gt 0 -and
    [string]$aggregate.candidate.aabSha256 -ceq [string]$state.buildResult.artifactSha256
  ) -Message 'postbuild artifact, authority or 1/0/0/0 state changed.'
}

if ($Phase -ceq 'preupload') {
  Assert-C34I -Condition (
    [string]$state.uploadAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'available_once' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0
  ) -Message 'preupload authority or counts changed.'
}

if ($Phase -ceq 'postupload') {
  Assert-C34I -Condition (
    [string]$state.uploadAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'consumed' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0 -and
    [int]$state.playResult.uploadCount -eq 1 -and
    [int]$state.playResult.internalActivationCount -eq 1 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.playResult.evidencePath)
  ) -Message 'postupload evidence, authority or 1/1/0/0 state changed.'
}

if ($Phase -ceq 'preinstall') {
  Assert-C34I -Condition (
    [string]$state.installAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'available_once' -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'preinstall authority or counts changed.'
}

if ($Phase -ceq 'postinstall') {
  Assert-C34I -Condition (
    [string]$state.installAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'consumed' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 1 -and
    [int]$state.actionCounts.deviceAcceptance -eq 0 -and
    [int]$state.installResult.installCount -eq 1 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.coldStartEvidencePath) -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.retainedDataEvidencePath) -and
    -not [bool]$state.installResult.acceptanceSucceeded
  ) -Message 'postinstall evidence, authority or 1/1/1/0 state changed.'
}

if ($Phase -ceq 'journey') {
  Assert-C34I -Condition (
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 1 -and
    [int]$state.actionCounts.deviceAcceptance -eq 1 -and
    [string]$state.releaseAuthorities.postinstallAcceptance -ceq 'consumed' -and
    [bool]$state.installResult.acceptanceSucceeded -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.journeyEvidencePath)
  ) -Message 'final journey evidence or 1/1/1/1 acceptance state changed.'
}

Write-Output (
  'C34I r60.73 privacy-safe release gate passed: ' +
  "phase=$Phase; registryEntries=$registryCount; sourceCycles=$cycles/2; " +
  "buildCount=$($state.actionCounts.build); uploadCount=$($state.actionCounts.upload); " +
  "installCount=$($state.actionCounts.install); " +
  "deviceAcceptanceCount=$($state.actionCounts.deviceAcceptance); " +
  'founderOnlyAuthSurfaces=true; waivers=false; secretOrPrivateValuesObserved=false.'
)
