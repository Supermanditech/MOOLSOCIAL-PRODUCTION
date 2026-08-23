[CmdletBinding()]
param(
  [ValidateSet(
    'source', 'preprompt', 'build', 'postbuild', 'preupload', 'postupload',
    'preinstall', 'postinstall', 'journey'
  )]
  [string]$Phase = 'source',
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34k.json',
  [string]$BlockerLedgerPath,
  [switch]$FixtureMode,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'

if ($FixtureMode) {
  if (
    -not $StatePath.StartsWith(
      'tmp/c34k-candidate-gate-fixtures-',
      [StringComparison]::OrdinalIgnoreCase
    ) -or
    [string]::IsNullOrWhiteSpace($BlockerLedgerPath) -or
    -not $BlockerLedgerPath.StartsWith(
      'tmp/c34k-candidate-gate-fixtures-',
      [StringComparison]::OrdinalIgnoreCase
    )
  ) { throw 'C34K r60.75 fixture paths escaped the exact candidate-gate fixture prefix.' }
} elseif (-not [string]::IsNullOrWhiteSpace($BlockerLedgerPath)) {
  throw 'C34K r60.75 alternate blocker ledger is fixture-only.'
}

function Assert-C34K {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34K r60.75 lifecycle-atomic release gate rejected: $Message"
  }
}

function Resolve-C34KFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34K -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34K -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or outside the production repository."
  return $resolved
}

function Assert-C34KManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  $rows = @(Get-Content -LiteralPath $ManifestPath)
  foreach ($row in $rows) {
    $match = [regex]::Match($row, '^([0-9A-F]{64})  (.+)$')
    Assert-C34K -Condition $match.Success -Message 'source manifest row is malformed.'
    $owner = Resolve-C34KFile -Path $match.Groups[2].Value -Label 'source owner'
    Assert-C34K -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
        $match.Groups[1].Value
    ) -Message "source owner changed: $($match.Groups[2].Value)"
  }
}

$stateFile = Resolve-C34KFile -Path $StatePath -Label 'detailed state'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateFile = Resolve-C34KFile `
  -Path ([string]$state.aggregateStatePath) -Label 'aggregate state'
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
$ticketFile = Resolve-C34KFile `
  -Path 'config/uaw-c34k-r60-75-release-lifecycle-atomic-parity-play-oppo-acceptance-ticket.json' `
  -Label 'selected ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketFile | ConvertFrom-Json
$scopeFile = Resolve-C34KFile -Path 'config/mvp-scope-gate-state.json' -Label 'MVP state'
$scope = Get-Content -Raw -LiteralPath $scopeFile | ConvertFrom-Json
$registryFile = Resolve-C34KFile `
  -Path 'config/codex-development-regression-registry.json' -Label 'regression registry'
$registry = Get-Content -Raw -LiteralPath $registryFile | ConvertFrom-Json
$registryCount = @($registry.entries).Count
$registryHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $registryFile).Hash
$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment

Assert-C34K -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.candidate.versionName -ceq '1.0.0-r60.75' -and
  [string]$ticket.candidate.versionCode -ceq '2026081375' -and
  [string]$ticket.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$ticket.candidate.playTrack -ceq 'internal' -and
  [string]$ticket.candidate.deviceSerial -ceq '2b3e0f71' -and
  @($ticket.productionReadinessParameterInventory).Count -eq 10 -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0
) -Message 'ticket identity, MVP scope or complete parameter inventory changed.'
Assert-C34K -Condition (
  [string]$selected.ticketId -ceq $ticketId -and
  [string]$selected.manifestPath -ceq
    'config/uaw-c34k-r60-75-release-lifecycle-atomic-parity-play-oppo-acceptance-ticket.json' -and
  [string]$selected.manifestSha256 -ceq
    (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketFile).Hash -and
  [string]$scope.ticket.id -ceq $ticketId -and
  [string]$scope.providerGate.nextTicket -ceq $ticketId -and
  [string]$scope.authorization.evidence -ceq
    'docs/quality/UAW-C34K-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md' -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.secretValueAccessAuthorized
) -Message 'selected MVP assessment or closed execution authorities changed.'

$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C34K -Condition (
  $branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  $head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.repositoryIdentity.branch -ceq $branch -and
  [string]$state.repositoryIdentity.head -ceq $head
) -Message 'branch or immutable HEAD changed.'

Assert-C34K -Condition (
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001' -and
  [string]$aggregate.contractId -ceq
    'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-AGGREGATE-001' -and
  [string]$state.ticketId -ceq $ticketId -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.75' -and
  [string]$state.candidate.versionCode -ceq '2026081375' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.playTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71'
) -Message 'candidate state identity changed.'

Assert-C34K -Condition (
  [string]$state.machineState -ceq [string]$aggregate.machineState -and
  [string]$state.candidate.disposition -ceq
    [string]$aggregate.candidate.disposition -and
  [bool]$state.candidate.artifactReusable -eq
    [bool]$aggregate.candidate.artifactReusable -and
  [int]$state.actionCounts.build -eq [int]$aggregate.actionCounts.build -and
  [int]$state.actionCounts.upload -eq [int]$aggregate.actionCounts.upload -and
  [int]$state.actionCounts.install -eq [int]$aggregate.actionCounts.install -and
  [int]$state.actionCounts.deviceAcceptance -eq
    [int]$aggregate.actionCounts.deviceAcceptance -and
  [int]$aggregate.candidate.buildCount -eq [int]$state.actionCounts.build -and
  [int]$aggregate.candidate.uploadCount -eq [int]$state.actionCounts.upload -and
  [int]$aggregate.candidate.installCount -eq [int]$state.actionCounts.install -and
  [int]$aggregate.candidate.deviceAcceptanceCount -eq
    [int]$state.actionCounts.deviceAcceptance -and
  [string]$state.releaseAuthorities.build -ceq
    [string]$aggregate.releaseAuthorities.build -and
  [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
    [string]$aggregate.releaseAuthorities.uploadAndInternalActivation -and
  [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
    [string]$aggregate.releaseAuthorities.inPlaceOppoPlayUpdate -and
  [string]$state.releaseAuthorities.postinstallAcceptance -ceq
    [string]$aggregate.releaseAuthorities.postinstallAcceptance
) -Message 'detailed/aggregate lifecycle mirror parity changed.'

$priorStateFile = Resolve-C34KFile `
  -Path 'config/successor-aab-regression-hard-gate-state-c34j.json' `
  -Label 'C34J rejected detailed state'
$priorAggregateFile = Resolve-C34KFile `
  -Path 'config/successor-aab-regression-hard-gate-aggregate-c34j.json' `
  -Label 'C34J rejected aggregate state'
$priorState = Get-Content -Raw -LiteralPath $priorStateFile | ConvertFrom-Json
$priorAggregate = Get-Content -Raw -LiteralPath $priorAggregateFile | ConvertFrom-Json
$lastStateHistory = @($state.historicalCandidates)[-1]
$lastAggregateHistory = @($aggregate.historicalCandidates)[-1]
Assert-C34K -Condition (
  [string]$priorState.machineState -ceq
    'prebuild_rejected_postseal_postinstall_blocker_ledger_circular_dependency_successor_required' -and
  [string]$priorAggregate.machineState -ceq [string]$priorState.machineState -and
  [int]$priorState.actionCounts.build -eq 0 -and
  [int]$priorState.actionCounts.upload -eq 0 -and
  [int]$priorState.actionCounts.install -eq 0 -and
  [int]$priorState.actionCounts.deviceAcceptance -eq 0 -and
  $null -eq $priorState.buildResult.artifactSha256 -and
  -not [bool]$priorAggregate.candidate.artifactReusable -and
  [string]$lastStateHistory.machineState -ceq [string]$priorState.machineState -and
  [string]$lastAggregateHistory.machineState -ceq [string]$priorState.machineState -and
  [int]$lastStateHistory.buildCount -eq 0 -and
  [int]$lastStateHistory.uploadCount -eq 0 -and
  [int]$lastStateHistory.installCount -eq 0 -and
  [int]$lastStateHistory.deviceAcceptanceCount -eq 0 -and
  -not [bool]$lastStateHistory.artifactReusable
) -Message 'C34J rejection or successor historical binding changed.'

Assert-C34K -Condition (
  [int]$state.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [int]$aggregate.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [string]$state.regressionMemory.sealedRegistrySha256 -ceq $registryHash -and
  [string]$aggregate.regressionMemory.sealedRegistrySha256 -ceq $registryHash -and
  [bool]$state.regressionMemory.allEntriesAppliedBeforeSeal
) -Message 'current regression registry seal changed.'

foreach ($name in @(
  'secretValuesObserved', 'privateAccountIdentifiersObserved',
  'privateLinksObserved', 'oauthClientIdentifierValuesObserved',
  'tokenOrAttestationPayloadObserved', 'privateEmailLinkObserved'
)) {
  Assert-C34K -Condition (
    -not [bool]$state.privacyBoundary.$name -and
    -not [bool]$aggregate.privacyBoundary.$name
  ) -Message "privacy flag changed: $name"
}

$policyFile = Resolve-C34KFile `
  -Path ([string]$state.sourcePrerequisites.deviceActorPolicyPath) `
  -Label 'device actor policy'
$policyGate = Resolve-C34KFile `
  -Path ([string]$state.sourcePrerequisites.deviceActorPolicyGatePath) `
  -Label 'device actor policy gate'
Assert-C34K -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $policyFile).Hash -ceq
    [string]$state.sourcePrerequisites.deviceActorPolicySha256 -and
  [string]$aggregate.deviceActorPolicy.sha256 -ceq
    [string]$state.sourcePrerequisites.deviceActorPolicySha256
) -Message 'privacy-safe device actor policy binding changed.'
& $policyGate -RepositoryRoot $root -SelfTest | Out-Null

$transitionFile = Resolve-C34KFile `
  -Path ([string]$state.sourcePrerequisites.lifecycleTransitionPath) `
  -Label 'lifecycle transition owner'
$transitionGate = Resolve-C34KFile `
  -Path ([string]$state.sourcePrerequisites.lifecycleTransitionGatePath) `
  -Label 'lifecycle transition fixture gate'
Assert-C34K -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $transitionFile).Hash -ceq
    [string]$state.sourcePrerequisites.lifecycleTransitionSha256 -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $transitionGate).Hash -ceq
    [string]$state.sourcePrerequisites.lifecycleTransitionGateSha256 -and
  [int]$aggregate.lifecycleTransition.declaredTransitions -eq 11 -and
  [int]$aggregate.lifecycleTransition.negativeFixtures -eq 6 -and
  [bool]$aggregate.lifecycleTransition.rollbackProved -and
  [bool]$aggregate.lifecycleTransition.dualPowerShellHostsRequired
) -Message 'lifecycle transition owner, fixture hash or declared coverage changed.'
& $transitionGate -RepositoryRoot $root | Out-Null

$wrapperFile = Resolve-C34KFile `
  -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' `
  -Label 'generic AAB wrapper'
$wrapper = Get-Content -Raw -LiteralPath $wrapperFile
foreach ($token in @(
  'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001',
  'check-uaw-c34k-r60-75-release-lifecycle-atomic-parity-readiness.ps1',
  'invoke-release-lifecycle-transition-c34k.ps1',
  '-Transition build-start', '-Transition build-failed',
  '-Transition build-succeeded', '-UploadSignerSha256 $uploadSigner'
)) {
  Assert-C34K -Condition (
    $wrapper.IndexOf($token, [StringComparison]::Ordinal) -ge 0
  ) -Message "generic wrapper C34K binding changed: $token"
}

$requiredOwners = @(
  [string]$state.releaseBinding.founderLauncher,
  [string]$state.releaseBinding.candidateGate,
  [string]$state.releaseBinding.postbuildRecoveryOwner,
  [string]$state.releaseBinding.sourceCycleOwner,
  [string]$state.presealUploadWorkflow.runbookPath,
  [string]$state.presealUploadWorkflow.founderAuthorizationPath,
  [string]$state.presealUploadWorkflow.evidencePath
)
foreach ($owner in $requiredOwners) {
  [void](Resolve-C34KFile -Path $owner -Label 'required C34K owner')
}

$mvpGate = Resolve-C34KFile `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' -Label 'MVP scope gate'
& $mvpGate -CandidateId $ticketId -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C34KFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
$memoryPhase = if ($Phase -cin @('postinstall', 'journey')) {
  'device'
} else { 'build' }
& $memoryGate -Phase $memoryPhase -BuildMode release -RepositoryRoot $root | Out-Null
$blockerGate = Resolve-C34KFile `
  -Path 'scripts/check-uaw-c33g-fix4-unresolved-acceptance-blocker-pre-aab-ledger.ps1' `
  -Label 'C33G blocker gate'
$blockerPhase = if ($Phase -ceq 'journey') {
  'postinstall'
} else { 'prebuild' }
$blockerParameters = @{
  CandidateId = $ticketId
  CandidateVersionCode = '2026081375'
  Phase = $blockerPhase
  RepositoryRoot = $root
}
if ($FixtureMode) { $blockerParameters.LedgerPath = $BlockerLedgerPath }
& $blockerGate @blockerParameters | Out-Null

$cycles = [int]$state.sourceQualification.completedIdenticalCycles
Assert-C34K -Condition (
  [int]$state.sourceQualification.requiredIdenticalCycles -eq 2 -and
  $cycles -eq [int]$aggregate.sourceQualification.completedIdenticalCycles
) -Message 'source-cycle requirement or parity changed.'

if ($Phase -ceq 'source') {
  if ($cycles -eq 0) {
    Assert-C34K -Condition (
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
      -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
      -not [bool]$state.candidate.artifactReusable
    ) -Message 'cycles-zero counts, authority or founder flags changed.'
    if ([string]$state.machineState -ceq
      'prebuild_composition_registered_two_fresh_cycles_required') {
      Assert-C34K -Condition (
        $null -eq $state.sourceQualification.manifestSha256 -and
        [int]$state.sourceQualification.fileCount -eq 0
      ) -Message 'pre-seal composition gained a manifest binding.'
    } elseif ([string]$state.machineState -ceq
      'prebuild_manifest_bound_two_fresh_cycles_required') {
      $manifest = Resolve-C34KFile `
        -Path ([string]$state.sourceQualification.manifestPath) `
        -Label 'sealed source manifest'
      Assert-C34K -Condition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash -ceq
          [string]$state.sourceQualification.manifestSha256 -and
        [int]$state.sourceQualification.fileCount -gt 0
      ) -Message 'manifest-bound cycles-zero identity changed.'
      Assert-C34KManifestCurrent -ManifestPath $manifest
      $focused = Resolve-C34KFile `
        -Path ([string]$state.sourceQualification.focusedManifestPath) `
        -Label 'focused manifest'
      Assert-C34K -Condition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $focused).Hash -ceq
          [string]$state.sourceQualification.focusedManifestSha256 -and
        [int]$state.sourceQualification.focusedManifestFileCount -gt 0
      ) -Message 'focused manifest identity changed.'
    } else {
      throw 'C34K r60.75 lifecycle-atomic release gate rejected: unsupported cycles-zero machine state.'
    }
  } elseif ($cycles -eq 2) {
    Assert-C34K -Condition (
      [bool]$state.sourceQualification.releasePreflightPassed -and
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
    ) -Message 'two-cycle qualification or lifecycle state changed.'
    $manifest = Resolve-C34KFile `
      -Path ([string]$state.sourceQualification.manifestPath) `
      -Label 'qualified source manifest'
    Assert-C34KManifestCurrent -ManifestPath $manifest
  } else {
    throw 'C34K r60.75 lifecycle-atomic release gate rejected: intermediate cycle persistence is forbidden.'
  }
}

if ($Phase -ceq 'preprompt') {
  Assert-C34K -Condition (
    $cycles -eq 2 -and
    [string]$state.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.build -ceq 'available_once' -and
    [bool]$state.authority.founderHiddenInputEntryAuthorized -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered
  ) -Message 'founder-prompt state or one build authority changed.'
}
if ($Phase -ceq 'build') {
  Assert-C34K -Condition (
    $cycles -eq 2 -and
    [string]$state.machineState -ceq
      'founder_inputs_validated_single_aab_build_required' -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.build -ceq 'available_once' -and
    [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    -not [bool]$state.authority.founderHiddenInputEntryAuthorized -and
    [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent
  ) -Message 'postinput build state, authority or founder flags changed.'
}
if ($Phase -ceq 'postbuild') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'single_release_AAB_succeeded_authority_consumed' -and
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.build -ceq 'consumed' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
    [long]$state.buildResult.artifactBytes -gt 0 -and
    [string]$aggregate.candidate.aabSha256 -ceq
      [string]$state.buildResult.artifactSha256 -and
    [bool]$state.candidate.artifactReusable -and
    [bool]$aggregate.candidate.artifactReusable
  ) -Message 'postbuild artifact, consumed authority, counts or reuse parity changed.'
}
if ($Phase -ceq 'preupload') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'postbuild_qualified_internal_testing_upload_authority_available_once' -and
    [string]$state.uploadAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
      'available_once' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0
  ) -Message 'preupload state, authority or counts changed.'
}
if ($Phase -ceq 'postupload') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'internal_testing_upload_activation_succeeded_authority_consumed' -and
    [string]$state.uploadAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
      'consumed' -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.playResult.uploadCount -eq 1 -and
    [int]$state.playResult.internalActivationCount -eq 1 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.playResult.evidencePath)
  ) -Message 'postupload activation, authority or evidence changed.'
}
if ($Phase -ceq 'preinstall') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'postupload_qualified_in_place_oppo_play_update_authority_available_once' -and
    [string]$state.installAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'available_once' -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'preinstall state, authority or counts changed.'
}
if ($Phase -ceq 'postinstall') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'oppo_play_in_place_update_succeeded_postinstall_acceptance_held' -and
    [string]$state.installAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'consumed' -and
    [int]$state.actionCounts.install -eq 1 -and
    [int]$state.installResult.installCount -eq 1 -and
    -not [string]::IsNullOrWhiteSpace(
      [string]$state.installResult.coldStartEvidencePath
    )
  ) -Message 'postinstall update, authority or evidence changed.'
}
if ($Phase -ceq 'journey') {
  Assert-C34K -Condition (
    [string]$state.machineState -ceq
      'internal_testing_oppo_device_acceptance_succeeded' -and
    [string]$state.deviceAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.postinstallAcceptance -ceq 'consumed' -and
    [int]$state.actionCounts.deviceAcceptance -eq 1 -and
    [bool]$state.installResult.acceptanceSucceeded -and
    -not [string]::IsNullOrWhiteSpace(
      [string]$state.installResult.journeyEvidencePath
    ) -and
    -not [bool]$state.candidate.artifactReusable
  ) -Message 'device acceptance, authority or evidence changed.'
}

Write-Output (
  'C34K r60.75 lifecycle-atomic release gate passed: ' +
  "phase=$Phase; registryEntries=$registryCount; sourceCycles=$cycles/2; " +
  "counts=$($state.actionCounts.build)/$($state.actionCounts.upload)/" +
  "$($state.actionCounts.install)/$($state.actionCounts.deviceAcceptance); " +
  'lifecycleFixtures=11/6/rollback; founderOnlyAuthSurfaces=true; ' +
  'waivers=false; secretOrPrivateValuesObserved=false.'
)
