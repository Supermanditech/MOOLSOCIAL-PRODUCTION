[CmdletBinding()]
param(
  [ValidateSet(
    'source', 'preprompt', 'prebuild', 'build', 'postbuild', 'preupload',
    'postupload', 'preinstall', 'postinstall', 'journey', 'rejection'
  )]
  [string]$Phase = 'source',
  [ValidateSet(
    'founder-inputs-validated', 'prebuild-failed', 'build-start',
    'build-failed', 'build-succeeded', 'upload-authorized',
    'upload-succeeded', 'install-authorized', 'install-succeeded',
    'device-accepted', 'reject'
  )]
  [string]$Transition,
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [string]$ProofOutputPath,
  [string]$SourceManifestPath,
  [string]$SourceManifestSha256,
  [long]$SourceManifestBytes,
  [string]$BlockerLedgerPath,
  [string]$BlockerLedgerSha256,
  [long]$BlockerLedgerBytes,
  [string]$BrowserProofPath,
  [string]$BrowserProofSha256,
  [long]$BrowserProofBytes,
  [switch]$FixtureMode,
  [switch]$SelfTest,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$stateContract =
  'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-001'
$aggregateContract =
  'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-AGGREGATE-001'
$selectionState = 'prebuild_composition_registered_two_fresh_cycles_required'
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$browserEvidenceNames = @(
  'browserEvidencePath', 'browserEvidenceSha256', 'browserEvidenceBytes',
  'browserEvidenceAttempt', 'browserEvidenceTransition',
  'browserEvidencePhase', 'browserEvidencePreStateSha256',
  'browserEvidencePreAggregateSha256', 'browserSessionId',
  'browserSessionNonceSha256', 'browserEvidenceProducerId',
  'browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc',
  'sourceManifestPath', 'sourceManifestSha256', 'sourceManifestBytes',
  'blockerLedgerPath', 'blockerLedgerSha256', 'blockerLedgerBytes',
  'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
  'internalTestingRouteProved', 'noPlayWritePerformed'
)

function Assert-C34LReadiness {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw "C34L consolidated readiness rejected: $Message"
  }
}

function Resolve-C34LReadinessPath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label,
    [switch]$AllowMissing
  )
  Assert-C34LReadiness (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LReadiness (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the production repository."
  if (-not $AllowMissing) {
    Assert-C34LReadiness (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
  }
  return $resolved
}

function ConvertTo-C34LReadinessRelative {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = [IO.Path]::GetFullPath($Path)
  Assert-C34LReadiness (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'path escaped the production repository.'
  return $resolved.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-C34LReadinessHash {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}

function Assert-C34LReadinessProperties {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string[]]$Names,
    [Parameter(Mandatory)][string]$Label
  )
  foreach ($name in $Names) {
    Assert-C34LReadiness ($null -ne $Value.PSObject.Properties[$name]) `
      "$Label is missing $name."
  }
}

function Assert-C34LReadinessParity {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  Assert-C34LReadiness (
    [string]$State.contractId -ceq $stateContract -and
    [string]$Aggregate.contractId -ceq $aggregateContract -and
    [string]$State.ticketId -ceq $ticketId -and
    [string]$Aggregate.ticketId -ceq $ticketId -and
    [string]$State.candidate.id -ceq $ticketId -and
    [string]$Aggregate.candidate.id -ceq $ticketId -and
    [string]$State.candidate.versionName -ceq $versionName -and
    [string]$Aggregate.candidate.versionName -ceq $versionName -and
    [string]$State.candidate.versionCode -ceq $versionCode -and
    [string]$Aggregate.candidate.versionCode -ceq $versionCode -and
    [string]$State.machineState -ceq [string]$Aggregate.machineState -and
    [string]$State.candidate.disposition -ceq
      [string]$Aggregate.candidate.disposition -and
    [bool]$State.candidate.artifactReusable -eq
      [bool]$Aggregate.candidate.artifactReusable
  ) 'candidate identity or detailed/aggregate common parity changed.'
  foreach ($name in $countNames) {
    Assert-C34LReadiness (
      $null -ne $State.actionCounts.PSObject.Properties[$name] -and
      $null -ne $Aggregate.actionCounts.PSObject.Properties[$name] -and
      [int]$State.actionCounts.$name -eq [int]$Aggregate.actionCounts.$name
    ) "action-count parity changed at $name."
  }
  foreach ($name in $authorityNames) {
    Assert-C34LReadiness (
      $null -ne $State.releaseAuthorities.PSObject.Properties[$name] -and
      $null -ne $Aggregate.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$State.releaseAuthorities.$name -ceq
        [string]$Aggregate.releaseAuthorities.$name
    ) "release-authority parity changed at $name."
  }
  Assert-C34LReadinessProperties `
    $State.presealUploadWorkflow $browserEvidenceNames `
    'detailed browser evidence mirror'
  Assert-C34LReadinessProperties `
    $Aggregate.presealUploadWorkflow $browserEvidenceNames `
    'aggregate browser evidence mirror'
  Assert-C34LReadiness (
    (@($State.presealUploadWorkflow.PSObject.Properties.Name | Sort-Object) -join ',') `
      -ceq (@($browserEvidenceNames | Sort-Object) -join ',') -and
    (@($Aggregate.presealUploadWorkflow.PSObject.Properties.Name | Sort-Object) -join ',') `
      -ceq (@($browserEvidenceNames | Sort-Object) -join ',')
  ) 'detailed or aggregate browser mirror exact 23-field schema changed.'
  foreach ($name in $browserEvidenceNames) {
    Assert-C34LReadiness (
      $State.presealUploadWorkflow.$name -ceq
        $Aggregate.presealUploadWorkflow.$name
    ) "browser-evidence parity changed at $name."
  }
  Assert-C34LReadiness (
    [int]$Aggregate.candidate.buildCount -eq [int]$State.actionCounts.build -and
    [int]$Aggregate.candidate.uploadCount -eq [int]$State.actionCounts.upload -and
    [int]$Aggregate.candidate.installCount -eq [int]$State.actionCounts.install -and
    [int]$Aggregate.candidate.deviceAcceptanceCount -eq
      [int]$State.actionCounts.deviceAcceptance
  ) 'aggregate candidate counts changed.'
}

function Assert-C34LReadinessVector {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][int[]]$Counts,
    [Parameter(Mandatory)][string[]]$Authorities,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34LReadiness ($Counts.Count -eq 8 -and $Authorities.Count -eq 4) `
    "$Label expected vector is incomplete."
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    Assert-C34LReadiness (
      [int]$State.actionCounts.($countNames[$index]) -eq $Counts[$index]
    ) "$Label count changed at $($countNames[$index])."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    Assert-C34LReadiness (
      [string]$State.releaseAuthorities.($authorityNames[$index]) -ceq
        $Authorities[$index]
    ) "$Label authority changed at $($authorityNames[$index])."
  }
}

function Assert-C34LSelectionOnly {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  Assert-C34LReadiness (
    [string]$State.machineState -ceq $selectionState -and
    [int]$State.sourceQualification.completedIdenticalCycles -eq 0 -and
    [int]$Aggregate.sourceQualification.completedIdenticalCycles -eq 0 -and
    $null -eq $State.sourceQualification.manifestSha256 -and
    $null -eq $Aggregate.sourceQualification.manifestSha256 -and
    [long]$State.sourceQualification.manifestBytes -eq 0 -and
    [long]$Aggregate.sourceQualification.manifestBytes -eq 0 -and
    [int]$State.sourceQualification.fileCount -eq 0 -and
    [int]$Aggregate.sourceQualification.fileCount -eq 0 -and
    $null -eq $State.sourceQualification.focusedManifestSha256 -and
    [long]$State.sourceQualification.focusedManifestBytes -eq 0 -and
    [int]$State.sourceQualification.focusedManifestFileCount -eq 0 -and
    @($State.sourceQualification.cycleEvidence).Count -eq 0 -and
    @($Aggregate.sourceQualification.cycleEvidence).Count -eq 0
  ) 'selection-only state gained a seal or source cycle.'
}

function Assert-C34LSourcePrecycleInvariant {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  $held = @(
    'held_founder_aab_authorization_and_source_qualification',
    'held_postbuild_qualification', 'held_postupload_qualification',
    'held_postinstall_journey_qualification'
  )
  Assert-C34LReadinessVector `
    $State @(0,0,0,0,0,0,0,0) $held 'source precycle'
  Assert-C34LReadiness (
    [string]$State.buildAuthorization -ceq $held[0] -and
    [string]$State.uploadAuthorization -ceq $held[1] -and
    [string]$State.installAuthorization -ceq $held[2] -and
    [string]$State.deviceAuthorization -ceq $held[3] -and
    [int]$Aggregate.candidate.buildCount -eq 0 -and
    [int]$Aggregate.candidate.uploadCount -eq 0 -and
    [int]$Aggregate.candidate.installCount -eq 0 -and
    [int]$Aggregate.candidate.deviceAcceptanceCount -eq 0
  ) 'source precycle action or authority vector changed.'
  Assert-C34LReadiness (
    [string]$State.buildResult.state -ceq 'not_started' -and
    [int]$State.buildResult.buildCount -eq 0 -and
    [int]$State.buildResult.wrapperInvocationCount -eq 0 -and
    [int]$State.buildResult.configOnlyCount -eq 0 -and
    $null -eq $State.buildResult.artifactPath -and
    $null -eq $State.buildResult.artifactSha256 -and
    [long]$State.buildResult.artifactBytes -eq 0 -and
    $null -eq $State.buildResult.uploadSignerSha256 -and
    $null -eq $State.buildResult.provenance -and
    $null -eq $Aggregate.candidate.aabSha256 -and
    [int]$State.playResult.uploadCount -eq 0 -and
    [int]$State.playResult.internalActivationCount -eq 0 -and
    $null -eq $State.playResult.evidencePath -and
    $null -eq $State.playResult.evidenceSha256 -and
    [long]$State.playResult.evidenceBytes -eq 0 -and
    [int]$State.installResult.installCount -eq 0 -and
    $null -eq $State.installResult.coldStartEvidencePath -and
    $null -eq $State.installResult.retainedDataEvidencePath -and
    $null -eq $State.installResult.journeyEvidencePath -and
    -not [bool]$State.installResult.acceptanceSucceeded -and
    $null -eq $State.installResult.failureEvidencePath -and
    @($State.lifecycleTransactionProofs).Count -eq 0 -and
    @($Aggregate.lifecycleTransactionProofs).Count -eq 0
  ) 'source precycle gained artifact, provenance, result, evidence or proof.'
  Assert-C34LReadiness (
    $null -eq $State.presealUploadWorkflow.browserEvidencePath -and
    $null -eq $State.presealUploadWorkflow.browserEvidenceSha256 -and
    [long]$State.presealUploadWorkflow.browserEvidenceBytes -eq 0 -and
    [int]$State.presealUploadWorkflow.browserEvidenceAttempt -eq 0 -and
    $null -eq $State.presealUploadWorkflow.browserEvidenceTransition -and
    $null -eq $State.presealUploadWorkflow.browserEvidencePhase -and
    $null -eq $State.presealUploadWorkflow.browserEvidencePreStateSha256 -and
    $null -eq $State.presealUploadWorkflow.browserEvidencePreAggregateSha256 -and
    $null -eq $State.presealUploadWorkflow.browserSessionId -and
    $null -eq $State.presealUploadWorkflow.browserSessionNonceSha256 -and
    $null -eq $State.presealUploadWorkflow.browserEvidenceProducerId -and
    $null -eq $State.presealUploadWorkflow.browserEvidenceProducedUtc -and
    $null -eq $State.presealUploadWorkflow.browserEvidenceExpiresUtc -and
    $null -eq $State.presealUploadWorkflow.sourceManifestPath -and
    $null -eq $State.presealUploadWorkflow.sourceManifestSha256 -and
    [long]$State.presealUploadWorkflow.sourceManifestBytes -eq 0 -and
    $null -eq $State.presealUploadWorkflow.blockerLedgerPath -and
    $null -eq $State.presealUploadWorkflow.blockerLedgerSha256 -and
    [long]$State.presealUploadWorkflow.blockerLedgerBytes -eq 0 -and
    -not [bool]$State.presealUploadWorkflow.liveBrowserRouteQualified -and
    -not [bool]$State.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
    -not [bool]$State.presealUploadWorkflow.internalTestingRouteProved -and
    [bool]$State.presealUploadWorkflow.noPlayWritePerformed -and
    -not [bool]$State.authority.founderHiddenInputEntryAuthorized -and
    -not [bool]$State.founderAuthorization.hiddenFounderInputsEntered
  ) 'source precycle gained browser binding or founder input authority.'
}

function Assert-C34LTransitionPhase {
  $phaseByTransition = @{
    'founder-inputs-validated'='preprompt'; 'prebuild-failed'='prebuild'
    'build-start'='build'; 'build-failed'='build'; 'build-succeeded'='build'
    'upload-authorized'='preupload'; 'upload-succeeded'='postupload'
    'install-authorized'='postupload'; 'install-succeeded'='postinstall'
    'device-accepted'='journey'; 'reject'='rejection'
  }
  if (-not [string]::IsNullOrWhiteSpace($Transition)) {
    Assert-C34LReadiness (
      [string]$phaseByTransition[$Transition] -ceq $Phase
    ) 'transition and prerequisite phase changed.'
  }
}

if (-not $SelfTest) {
  $stateFile = Resolve-C34LReadinessPath $StatePath 'detailed state'
  $stateRelative = ConvertTo-C34LReadinessRelative $stateFile
  if ($FixtureMode) {
    Assert-C34LReadiness (
      $stateRelative -cmatch
        '^tmp/c34l-blocker-browser-fixtures-readiness-[0-9A-Za-z_-]+/state[.]json$'
    ) 'fixture state escaped the exact C34L candidate-gate fixture root.'
    $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
    $fixturePrefix = $fixtureRoot + '/'
  } else {
    Assert-C34LReadiness (
      $stateRelative -ceq
        'config/successor-aab-regression-hard-gate-state-c34l.json'
    ) 'production validation requires the exact C34L detailed state.'
  }

  $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  Assert-C34LReadinessProperties $state @(
    'contractId', 'ticketId', 'aggregateStatePath', 'machineState',
    'repositoryIdentity', 'candidate', 'predecessorRejection',
    'presealUploadWorkflow', 'regressionMemory', 'sourceQualification',
    'releaseAuthorities', 'actionCounts', 'buildResult', 'playResult',
    'installResult', 'lifecycleTransactionProofs', 'privacyBoundary'
  ) 'detailed state'
  $aggregateFile = Resolve-C34LReadinessPath `
    ([string]$state.aggregateStatePath) 'aggregate state'
  $aggregateRelative = ConvertTo-C34LReadinessRelative $aggregateFile
  if ($FixtureMode) {
    Assert-C34LReadiness (
      $aggregateRelative -ceq ($fixturePrefix + 'aggregate.json')
    ) 'fixture aggregate escaped the exact fixture root.'
  } else {
    Assert-C34LReadiness (
      $aggregateRelative -ceq
        'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
    ) 'production validation requires the exact C34L aggregate state.'
  }
  $aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
  Assert-C34LReadinessProperties $aggregate @(
    'contractId', 'ticketId', 'machineState', 'candidate',
    'predecessorRejection', 'presealUploadWorkflow', 'regressionMemory',
    'sourceQualification', 'releaseAuthorities', 'actionCounts',
    'lifecycleTransactionProofs', 'privacyBoundary'
  ) 'aggregate state'
  Assert-C34LReadinessParity $state $aggregate
  Assert-C34LTransitionPhase
  $isBrowserTuple = $Phase -ceq 'preupload' -and
    $Transition -ceq 'upload-authorized'
  if (-not $isBrowserTuple) {
    Assert-C34LReadiness (
      [string]::IsNullOrWhiteSpace($BrowserProofPath) -and
      [string]::IsNullOrWhiteSpace($BrowserProofSha256) -and
      $BrowserProofBytes -eq 0
    ) 'browser evidence metadata is allowed only for upload-authorized/preupload.'
  }

  $branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
  Assert-C34LReadiness ($LASTEXITCODE -eq 0) 'branch identity command failed.'
  $head = (& git -C $root rev-parse HEAD).Trim()
  Assert-C34LReadiness ($LASTEXITCODE -eq 0) 'HEAD identity command failed.'
  Assert-C34LReadiness (
    $branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
    $head -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
    [string]$state.repositoryIdentity.branch -ceq $branch -and
    [string]$state.repositoryIdentity.head -ceq $head -and
    [string]$state.candidate.branch -ceq $branch -and
    [string]$state.candidate.head -ceq $head -and
    [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
    [string]$state.candidate.playTrack -ceq 'internal' -and
    [string]$state.candidate.deviceBindingSha256 -ceq '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF' -and
    [string]$state.candidate.deviceModel -ceq 'CPH2375'
  ) 'branch, HEAD, package, track or device identity changed.'

  $ticketFile = Resolve-C34LReadinessPath `
    'config/uaw-c34l-r60-76-consolidated-release-transaction-evidence-play-oppo-acceptance-ticket.json' `
    'C34L ticket'
  $ticket = Get-Content -Raw -LiteralPath $ticketFile | ConvertFrom-Json
  Assert-C34LReadiness (
    [string]$ticket.ticketId -ceq $ticketId -and
    [string]$ticket.classification -ceq 'mvp_required' -and
    [string]$ticket.candidate.versionName -ceq $versionName -and
    [string]$ticket.candidate.versionCode -ceq $versionCode -and
    (Get-C34LReadinessHash $ticketFile) -ceq
      [string]$state.releaseBinding.selectedTicketSha256
  ) 'ticket identity, classification, version or hash changed.'

  $interfaceBindings = @(
    @(
      'blockerBrowserIntegrationGatePath',
      'blockerBrowserIntegrationGateSha256',
      'blockerBrowserIntegrationGateBytes'
    ),
    @(
      'lifecycleTransitionPath', 'lifecycleTransitionSha256',
      'lifecycleTransitionBytes'
    ),
    @(
      'lifecycleTransitionGatePath', 'lifecycleTransitionGateSha256',
      'lifecycleTransitionGateBytes'
    ),
    @(
      'transactionJournalGatePath', 'transactionJournalGateSha256',
      'transactionJournalGateBytes'
    ),
    @(
      'retainedEvidenceGatePath', 'retainedEvidenceGateSha256',
      'retainedEvidenceGateBytes'
    ),
    @(
      'retainedEvidenceFixtureGatePath',
      'retainedEvidenceFixtureGateSha256',
      'retainedEvidenceFixtureGateBytes'
    ),
    @(
      'postbuildRecoveryPath', 'postbuildRecoverySha256',
      'postbuildRecoveryBytes'
    ),
    @(
      'buildWrapperTerminalGatePath', 'buildWrapperTerminalGateSha256',
      'buildWrapperTerminalGateBytes'
    )
  )
  foreach ($binding in $interfaceBindings) {
    $pathName = [string]$binding[0]
    $hashName = [string]$binding[1]
    $bytesName = [string]$binding[2]
    Assert-C34LReadiness (
      $null -ne $state.sourcePrerequisites.PSObject.Properties[$pathName] -and
      $null -ne $state.sourcePrerequisites.PSObject.Properties[$hashName] -and
      $null -ne $state.sourcePrerequisites.PSObject.Properties[$bytesName]
    ) "qualified interface binding is missing $pathName, $hashName or $bytesName."
    $interfaceFile = Resolve-C34LReadinessPath `
      ([string]$state.sourcePrerequisites.$pathName) $pathName
    Assert-C34LReadiness (
      [string]$state.sourcePrerequisites.$hashName -cmatch '^[0-9A-F]{64}$' -and
      [long]$state.sourcePrerequisites.$bytesName -gt 0 -and
      (Get-C34LReadinessHash $interfaceFile) -ceq
        [string]$state.sourcePrerequisites.$hashName -and
      (Get-Item -LiteralPath $interfaceFile).Length -eq
        [long]$state.sourcePrerequisites.$bytesName
    ) "qualified interface changed at $pathName."
  }

  $priorStateFile = Resolve-C34LReadinessPath `
    ([string]$state.predecessorRejection.statePath) 'C34K detailed rejection'
  $priorAggregateFile = Resolve-C34LReadinessPath `
    ([string]$state.predecessorRejection.aggregatePath) 'C34K aggregate rejection'
  $priorState = Get-Content -Raw -LiteralPath $priorStateFile | ConvertFrom-Json
  $priorAggregate = Get-Content -Raw -LiteralPath $priorAggregateFile |
    ConvertFrom-Json
  Assert-C34LReadiness (
    (Get-C34LReadinessHash $priorStateFile) -ceq
      [string]$state.predecessorRejection.stateSha256 -and
    (Get-C34LReadinessHash $priorAggregateFile) -ceq
      [string]$state.predecessorRejection.aggregateSha256 -and
    [string]$priorState.machineState -ceq
      'prebuild_rejected_consolidated_lifecycle_audit_gaps_successor_required' -and
    [string]$priorAggregate.machineState -ceq [string]$priorState.machineState -and
    [int]$priorState.actionCounts.build -eq 0 -and
    [int]$priorState.actionCounts.upload -eq 0 -and
    [int]$priorState.actionCounts.install -eq 0 -and
    [int]$priorState.actionCounts.deviceAcceptance -eq 0 -and
    -not [bool]$priorState.candidate.artifactReusable -and
    [string]$aggregate.predecessorRejection.stateSha256 -ceq
      [string]$state.predecessorRejection.stateSha256 -and
    [string]$aggregate.predecessorRejection.aggregateSha256 -ceq
      [string]$state.predecessorRejection.aggregateSha256
  ) 'C34K permanent zero-action rejection binding changed.'

  $registryFile = Resolve-C34LReadinessPath `
    ([string]$state.regressionMemory.registryPath) 'regression registry'
  $registry = Get-Content -Raw -LiteralPath $registryFile | ConvertFrom-Json
  $registryCount = @($registry.entries).Count
  $registryHash = Get-C34LReadinessHash $registryFile
  Assert-C34LReadiness (
    $registryCount -eq [int]$state.regressionMemory.sealedRegistryEntryCount -and
    $registryCount -eq [int]$aggregate.regressionMemory.sealedRegistryEntryCount -and
    $registryHash -ceq [string]$state.regressionMemory.sealedRegistrySha256 -and
    $registryHash -ceq [string]$aggregate.regressionMemory.sealedRegistrySha256
  ) 'current regression registry count or SHA-256 binding changed.'

  foreach ($name in @(
    'secretValuesObserved', 'privateAccountIdentifiersObserved',
    'privateLinksObserved', 'oauthClientIdentifierValuesObserved',
    'tokenOrAttestationPayloadObserved', 'privateEmailLinkObserved'
  )) {
    Assert-C34LReadiness (
      -not [bool]$state.privacyBoundary.$name -and
      -not [bool]$aggregate.privacyBoundary.$name
    ) "privacy boundary changed at $name."
  }

  if ($Phase -ceq 'source') {
    Assert-C34LSourcePrecycleInvariant $state $aggregate
    if ([string]$state.machineState -ceq $selectionState) {
      Assert-C34LSelectionOnly $state $aggregate
    }
  }

  $browserEvidenceProjection = $null
  if ($Phase -in @('source', 'preupload')) {
    $integrationGate = Resolve-C34LReadinessPath `
      'scripts/check-release-blocker-browser-proof-integration-c34l.ps1' `
      'C34L blocker/browser integration gate'
    $integration = @{
      Phase=$Phase; StatePath=$StatePath; Attempt=$Attempt
      SourceManifestPath=$SourceManifestPath
      SourceManifestSha256=$SourceManifestSha256
      SourceManifestBytes=$SourceManifestBytes
      BlockerLedgerPath=$BlockerLedgerPath
      BlockerLedgerSha256=$BlockerLedgerSha256
      BlockerLedgerBytes=$BlockerLedgerBytes
      BrowserProofPath=$BrowserProofPath
      BrowserProofSha256=$BrowserProofSha256
      BrowserProofBytes=$BrowserProofBytes
      RepositoryRoot=$root
    }
    if ($Phase -ceq 'source') {
      [void]$integration.Remove('BrowserProofPath')
      [void]$integration.Remove('BrowserProofSha256')
      [void]$integration.Remove('BrowserProofBytes')
    } else {
      Assert-C34LReadiness ($Transition -ceq 'upload-authorized') `
        'preupload requires the canonical upload-authorized transition.'
    }
    if ($FixtureMode) { $integration.FixtureMode = $true }
    & $integrationGate @integration | Out-Null

    if ($Phase -ceq 'preupload') {
      $browserProofFile = Resolve-C34LReadinessPath `
        $BrowserProofPath 'current-session browser proof'
      $browserProofText = Get-Content -Raw -LiteralPath $browserProofFile
      $browserProof = $browserProofText | ConvertFrom-Json
      Assert-C34LReadinessProperties $browserProof @(
        'attempt', 'transition', 'phase', 'sessionId',
        'sessionNonceSha256', 'producerId', 'producedUtc', 'expiresUtc',
        'sourceManifest', 'blockerLedger', 'routes', 'noPlayWritePerformed'
      ) 'current-session browser proof'
      Assert-C34LReadinessProperties $browserProof.routes @(
        'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
        'internalTestingRouteProved'
      ) 'current-session browser proof routes'
      $browserUtcText = @{}
      foreach ($timestampName in @('producedUtc', 'expiresUtc')) {
        $timestampMatches = [regex]::Matches(
          $browserProofText,
          '"' + $timestampName + '"\s*:\s*"([^"]+)"'
        )
        Assert-C34LReadiness ($timestampMatches.Count -eq 1) `
          "browser proof must contain one exact $timestampName string."
        $browserUtcText[$timestampName] =
          [string]$timestampMatches[0].Groups[1].Value
      }
      $browserEvidenceProjection = [ordered]@{
        browserEvidencePath=$BrowserProofPath
        browserEvidenceSha256=$BrowserProofSha256
        browserEvidenceBytes=$BrowserProofBytes
        browserEvidenceAttempt=$Attempt
        browserEvidenceTransition='upload-authorized'
        browserEvidencePhase='preupload'
        browserEvidencePreStateSha256=Get-C34LReadinessHash $stateFile
        browserEvidencePreAggregateSha256=Get-C34LReadinessHash $aggregateFile
        browserSessionId=[string]$browserProof.sessionId
        browserSessionNonceSha256=[string]$browserProof.sessionNonceSha256
        browserEvidenceProducerId=[string]$browserProof.producerId
        browserEvidenceProducedUtc=[string]$browserUtcText.producedUtc
        browserEvidenceExpiresUtc=[string]$browserUtcText.expiresUtc
        sourceManifestPath=[string]$browserProof.sourceManifest.path
        sourceManifestSha256=[string]$browserProof.sourceManifest.sha256
        sourceManifestBytes=[long]$browserProof.sourceManifest.bytes
        blockerLedgerPath=[string]$browserProof.blockerLedger.path
        blockerLedgerSha256=[string]$browserProof.blockerLedger.sha256
        blockerLedgerBytes=[long]$browserProof.blockerLedger.bytes
        liveBrowserRouteQualified=[bool]$browserProof.routes.liveBrowserRouteQualified
        signedInMoolSocialAppRouteProved=
          [bool]$browserProof.routes.signedInMoolSocialAppRouteProved
        internalTestingRouteProved=
          [bool]$browserProof.routes.internalTestingRouteProved
        noPlayWritePerformed=[bool]$browserProof.noPlayWritePerformed
      }
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($ProofOutputPath)) {
    Assert-C34LReadiness (
      -not [string]::IsNullOrWhiteSpace($Transition)
    ) 'proof output requires one exact transition.'
    $proofFile = Resolve-C34LReadinessPath `
      $ProofOutputPath 'prerequisite proof output' -AllowMissing
    $proofRelative = ConvertTo-C34LReadinessRelative $proofFile
    if ($FixtureMode) {
      Assert-C34LReadiness (
        $proofRelative.StartsWith($fixturePrefix, [StringComparison]::Ordinal)
      ) 'fixture proof output escaped the exact fixture root.'
    } else {
      $evidencePrefix = [string]$state.evidenceRoot + '/'
      Assert-C34LReadiness (
        $proofRelative.StartsWith($evidencePrefix, [StringComparison]::Ordinal)
      ) 'production proof output escaped the exact retained evidence root.'
    }
    Assert-C34LReadiness (-not (Test-Path -LiteralPath $proofFile)) `
      'prerequisite proof output already exists.'
    $proof = [ordered]@{
      ticketId=$ticketId; attempt=$Attempt; versionName=$versionName
      versionCode=$versionCode; transition=$Transition; phase=$Phase
      passed=$true; stateSha256=Get-C34LReadinessHash $stateFile
      aggregateSha256=Get-C34LReadinessHash $aggregateFile
      actionCounts=$state.actionCounts
      releaseAuthorities=$state.releaseAuthorities
    }
    if ($Transition -ceq 'upload-authorized' -and $Phase -ceq 'preupload') {
      Assert-C34LReadiness ($null -ne $browserEvidenceProjection) `
        'canonical upload-authorized proof is missing browser evidence.'
      $proof['browserEvidence'] = $browserEvidenceProjection
    } else {
      Assert-C34LReadiness (
        [string]::IsNullOrWhiteSpace($BrowserProofPath) -and
        [string]::IsNullOrWhiteSpace($BrowserProofSha256) -and
        $BrowserProofBytes -eq 0
      ) 'noncanonical transition received browser evidence metadata.'
    }
    [IO.File]::WriteAllText(
      $proofFile,
      (($proof | ConvertTo-Json -Depth 20) + [Environment]::NewLine),
      [Text.UTF8Encoding]::new($false)
    )
  }

  Write-Output (
    'C34L consolidated readiness passed: ' +
    "phase=$Phase; transition=$Transition; attempt=$Attempt; " +
    "registryEntries=$registryCount; counts=$($state.actionCounts.build)/" +
    "$($state.actionCounts.upload)/$($state.actionCounts.install)/" +
    "$($state.actionCounts.deviceAcceptance); selectionOnly=" +
    ($Phase -ceq 'source').ToString().ToLowerInvariant() +
    '; externalWrites=0; secretOrPrivateValuesObserved=false.'
  )
}

if ($SelfTest) {
  $selfPath = $MyInvocation.MyCommand.Path
  $runRoot = Join-Path $root (
    'tmp/c34l-blocker-browser-fixtures-readiness-' + $PID + '-' +
    [Guid]::NewGuid().ToString('N')
  )
  $stateFixture = Join-Path $runRoot 'state.json'
  $aggregateFixture = Join-Path $runRoot 'aggregate.json'
  $sourceOwnerFixture = Join-Path $runRoot 'source-owner.txt'
  $manifestFixture = Join-Path $runRoot 'source-manifest.txt'
  $ledgerFixture = Join-Path $runRoot 'blocker-ledger.json'
  $browserProofFixture = Join-Path $runRoot 'browser-proof.json'
  $prerequisiteProofFixture = Join-Path $runRoot 'prerequisite-proof.json'
  $stateFixtureRelative = ConvertTo-C34LReadinessRelative $stateFixture
  $aggregateFixtureRelative = ConvertTo-C34LReadinessRelative $aggregateFixture
  $sourceOwnerFixtureRelative = ConvertTo-C34LReadinessRelative $sourceOwnerFixture
  $manifestFixtureRelative = ConvertTo-C34LReadinessRelative $manifestFixture
  $ledgerFixtureRelative = ConvertTo-C34LReadinessRelative $ledgerFixture
  $browserProofFixtureRelative = ConvertTo-C34LReadinessRelative $browserProofFixture
  $prerequisiteProofFixtureRelative =
    ConvertTo-C34LReadinessRelative $prerequisiteProofFixture
  $realStateFile = Resolve-C34LReadinessPath `
    'config/successor-aab-regression-hard-gate-state-c34l.json' `
    'real detailed selection state'
  $realAggregateFile = Resolve-C34LReadinessPath `
    'config/successor-aab-regression-hard-gate-aggregate-c34l.json' `
    'real aggregate selection state'
  $baseState = Get-Content -Raw -LiteralPath $realStateFile | ConvertFrom-Json
  $baseAggregate = Get-Content -Raw -LiteralPath $realAggregateFile |
    ConvertFrom-Json

  function Write-C34LSelfTestJson {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
    [IO.File]::WriteAllText(
      $Path,
      (($Value | ConvertTo-Json -Depth 60) + [Environment]::NewLine),
      [Text.UTF8Encoding]::new($false)
    )
  }
  function Reset-C34LSelfTestFixture {
    $stateValue = ($baseState | ConvertTo-Json -Depth 60) | ConvertFrom-Json
    $aggregateValue = ($baseAggregate | ConvertTo-Json -Depth 60) |
      ConvertFrom-Json
    $stateValue.aggregateStatePath = $aggregateFixtureRelative
    $stateValue.evidenceRoot = (ConvertTo-C34LReadinessRelative $runRoot)
    $aggregateValue.evidenceRoot = (ConvertTo-C34LReadinessRelative $runRoot)
    $stateValue.machineState = 'prebuild_manifest_bound_two_fresh_cycles_required'
    $aggregateValue.machineState = $stateValue.machineState
    $stateValue.candidate.disposition = $stateValue.machineState
    $aggregateValue.candidate.disposition = $stateValue.machineState
    foreach ($value in @($stateValue, $aggregateValue)) {
      $value.sourceQualification.manifestPath = $manifestFixtureRelative
      $value.sourceQualification.manifestSha256 = $manifestFixtureSha256
      $value.sourceQualification.manifestBytes = $manifestFixtureBytes
      $value.sourceQualification.fileCount = 1
    }
    $stateValue.sourcePrerequisites.blockerLedgerPath = $ledgerFixtureRelative
    $stateValue.sourcePrerequisites.blockerLedgerPrebuildSha256 =
      $ledgerFixtureSha256
    Write-C34LSelfTestJson $stateFixture $stateValue
    Write-C34LSelfTestJson $aggregateFixture $aggregateValue
  }
  function Invoke-C34LSelfTestGate {
    & $selfPath -Phase source -StatePath $stateFixtureRelative -FixtureMode `
      -SourceManifestPath $manifestFixtureRelative `
      -SourceManifestSha256 $manifestFixtureSha256 `
      -SourceManifestBytes $manifestFixtureBytes `
      -BlockerLedgerPath $ledgerFixtureRelative `
      -BlockerLedgerSha256 $ledgerFixtureSha256 `
      -BlockerLedgerBytes $ledgerFixtureBytes `
      -RepositoryRoot $root | Out-Null
  }
  function Set-C34LSelfTestPreuploadFixture {
    Reset-C34LSelfTestFixture
    $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
    $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
      ConvertFrom-Json
    $preuploadState = 'single_release_AAB_succeeded_authority_consumed'
    foreach ($value in @($stateValue, $aggregateValue)) {
      $value.machineState = $preuploadState
      $value.candidate.disposition = $preuploadState
      $value.actionCounts.build = 1
      $value.releaseAuthorities.build = 'consumed'
      $value.releaseAuthorities.uploadAndInternalActivation =
        'held_postbuild_qualification'
      $value.sourceQualification.completedIdenticalCycles = 2
    }
    $stateValue.uploadAuthorization = 'held_postbuild_qualification'
    $aggregateValue.candidate.buildCount = 1
    Write-C34LSelfTestJson $stateFixture $stateValue
    Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    $stateFixtureSha256 = Get-C34LReadinessHash $stateFixture
    $aggregateFixtureSha256 = Get-C34LReadinessHash $aggregateFixture
    $nonceSha256 = 'C' * 64
    $utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $producedUtc = [DateTime]::UtcNow.AddMinutes(-1).ToString(
      $utcFormat, $culture
    )
    $expiresUtc = [DateTime]::UtcNow.AddMinutes(9).ToString(
      $utcFormat, $culture
    )
    $browserProofValue = [ordered]@{
      schemaVersion=1
      contractId='MOOLSOCIAL-C34L-R60-76-PREUPLOAD-BROWSER-ROUTE-PROOF-001'
      ticketId=$ticketId; attempt=1; versionName=$versionName
      versionCode=$versionCode; transition='upload-authorized'; phase='preupload'
      stateSha256=$stateFixtureSha256
      aggregateSha256=$aggregateFixtureSha256
      sourceManifest=[ordered]@{
        path=$manifestFixtureRelative; sha256=$manifestFixtureSha256
        bytes=$manifestFixtureBytes
      }
      blockerLedger=[ordered]@{
        path=$ledgerFixtureRelative; sha256=$ledgerFixtureSha256
        bytes=$ledgerFixtureBytes; mutableOutsideSourceSeal=$true
      }
      sessionId='c34l-browser-session-' + $nonceSha256.Substring(0,16)
      sessionNonceSha256=$nonceSha256
      producerId='MOOLSOCIAL-C34L-BROWSER-QUALIFICATION-PRODUCER-001'
      producedUtc=$producedUtc; expiresUtc=$expiresUtc
    }
    $browserProofValue['routes'] = [ordered]@{
      liveBrowserRouteQualified=$true
      signedInMoolSocialAppRouteProved=$true
      internalTestingRouteProved=$true
      sanitizedHost='play.google.com'
      sanitizedPath='/console/app/internal-testing'
      queryPresent=$false; fragmentPresent=$false
    }
    $browserProofValue['actionCounts'] = $stateValue.actionCounts
    $browserProofValue['releaseAuthorities'] = $stateValue.releaseAuthorities
    $browserProofValue['copiedFromPriorCandidate'] = $false
    $browserProofValue['noPlayWritePerformed'] = $true
    $browserProofValue['uploadActionCount'] = 0
    $browserProofValue['activationActionCount'] = 0
    $browserProofValue['otherTrackActionCount'] = 0
    $browserProofValue['privateValuesObserved'] = $false
    Write-C34LSelfTestJson $browserProofFixture $browserProofValue
    if (Test-Path -LiteralPath $prerequisiteProofFixture -PathType Leaf) {
      Remove-Item -LiteralPath $prerequisiteProofFixture -Force
    }
  }
  function Invoke-C34LSelfTestPreuploadGate {
    param([switch]$WritePrerequisiteProof)
    $parameters = @{
      Phase='preupload'; Transition='upload-authorized'; Attempt=1
      StatePath=$stateFixtureRelative; FixtureMode=$true
      SourceManifestPath=$manifestFixtureRelative
      SourceManifestSha256=$manifestFixtureSha256
      SourceManifestBytes=$manifestFixtureBytes
      BlockerLedgerPath=$ledgerFixtureRelative
      BlockerLedgerSha256=$ledgerFixtureSha256
      BlockerLedgerBytes=$ledgerFixtureBytes
      BrowserProofPath=$browserProofFixtureRelative
      BrowserProofSha256=Get-C34LReadinessHash $browserProofFixture
      BrowserProofBytes=(Get-Item -LiteralPath $browserProofFixture).Length
      RepositoryRoot=$root
    }
    if ($WritePrerequisiteProof) {
      $parameters.ProofOutputPath = $prerequisiteProofFixtureRelative
    }
    & $selfPath @parameters | Out-Null
  }
  function Assert-C34LSelfTestFailure {
    param(
      [Parameter(Mandatory)][scriptblock]$Mutation,
      [Parameter(Mandatory)][string]$Label
    )
    Reset-C34LSelfTestFixture
    & $Mutation
    $rejected = $false
    try { Invoke-C34LSelfTestGate } catch { $rejected = $true }
    Assert-C34LReadiness $rejected "$Label fixture did not fail closed."
  }
  function Assert-C34LSelfTestPreuploadFailure {
    param(
      [Parameter(Mandatory)][scriptblock]$Mutation,
      [Parameter(Mandatory)][string]$Label
    )
    Set-C34LSelfTestPreuploadFixture
    & $Mutation
    $rejected = $false
    try { Invoke-C34LSelfTestPreuploadGate } catch { $rejected = $true }
    Assert-C34LReadiness $rejected "$Label fixture did not fail closed."
  }

  [void](New-Item -ItemType Directory -Path $runRoot)
  [IO.File]::WriteAllText(
    $sourceOwnerFixture, "readiness fixture source owner`n",
    [Text.UTF8Encoding]::new($false)
  )
  $realLedgerFile = Resolve-C34LReadinessPath `
    'config/release-acceptance-blocker-ledger-c33g.json' `
    'real mutable C33G blocker ledger'
  $realLedger = Get-Content -Raw -LiteralPath $realLedgerFile | ConvertFrom-Json
  Write-C34LSelfTestJson $ledgerFixture $realLedger
  $sourceOwnerFixtureSha256 = Get-C34LReadinessHash $sourceOwnerFixture
  [IO.File]::WriteAllText(
    $manifestFixture,
    "$sourceOwnerFixtureSha256  $sourceOwnerFixtureRelative`n",
    [Text.UTF8Encoding]::new($false)
  )
  $manifestFixtureSha256 = Get-C34LReadinessHash $manifestFixture
  $manifestFixtureBytes = (Get-Item -LiteralPath $manifestFixture).Length
  $ledgerFixtureSha256 = Get-C34LReadinessHash $ledgerFixture
  $ledgerFixtureBytes = (Get-Item -LiteralPath $ledgerFixture).Length
  try {
    Reset-C34LSelfTestFixture
    Invoke-C34LSelfTestGate

    $unwiredSourceRejected = $false
    try {
      & $selfPath -Phase source -StatePath $stateFixtureRelative `
        -FixtureMode -RepositoryRoot $root | Out-Null
    } catch { $unwiredSourceRejected = $true }
    Assert-C34LReadiness $unwiredSourceRejected `
      'unwired source integration fixture did not fail closed.'

    Reset-C34LSelfTestFixture
    $nonBrowserTupleError = $null
    try {
      & $selfPath -Phase build -Transition build-start `
        -StatePath $stateFixtureRelative -FixtureMode `
        -BrowserProofPath $browserProofFixtureRelative `
        -BrowserProofSha256 ('A' * 64) -BrowserProofBytes 1 `
        -RepositoryRoot $root | Out-Null
    } catch { $nonBrowserTupleError = $_.Exception.Message }
    Assert-C34LReadiness (
      [string]$nonBrowserTupleError -clike
        '*browser evidence metadata is allowed only for upload-authorized/preupload*'
    ) 'non-browser tuple did not reject browser evidence at the exact boundary.'

    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $value.ticketId = 'WRONG-TICKET'
      Write-C34LSelfTestJson $stateFixture $value
    } 'wrong ticket'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $stateValue.candidate.versionName = '1.0.0-r60.75'
      $aggregateValue.candidate.versionName = '1.0.0-r60.75'
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'wrong version'
    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $value.repositoryIdentity.head = ('0' * 40)
      $value.candidate.head = ('0' * 40)
      Write-C34LSelfTestJson $stateFixture $value
    } 'wrong HEAD'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $stateValue.regressionMemory.sealedRegistryEntryCount--
      $aggregateValue.regressionMemory.sealedRegistryEntryCount--
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'wrong registry count'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $stateValue.releaseAuthorities.build = 'available_once'
      $aggregateValue.releaseAuthorities.build = 'available_once'
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'premature build authority'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $stateValue.actionCounts.upload = 1
      $aggregateValue.actionCounts.upload = 1
      $aggregateValue.candidate.uploadCount = 1
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'manifest-bound wrong action count'
    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $aggregateFixture | ConvertFrom-Json
      $value.actionCounts.install = 1
      Write-C34LSelfTestJson $aggregateFixture $value
    } 'aggregate mirror'
    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $value.presealUploadWorkflow.liveBrowserRouteQualified = $true
      Write-C34LSelfTestJson $stateFixture $value
    } 'premature browser proof'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $stateValue.presealUploadWorkflow | Add-Member `
        -NotePropertyName freshSessionProof -NotePropertyValue $true
      $aggregateValue.presealUploadWorkflow | Add-Member `
        -NotePropertyName freshSessionProof -NotePropertyValue $true
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'browser workflow extra field'
    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $value.buildResult.artifactSha256 = ('A' * 64)
      $value.buildResult.artifactBytes = 1
      Write-C34LSelfTestJson $stateFixture $value
    } 'premature artifact'
    Assert-C34LSelfTestFailure {
      $value = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $value.playResult.evidencePath =
        ((ConvertTo-C34LReadinessRelative $runRoot) + '/premature-play.json')
      $value.playResult.evidenceSha256 = 'A' * 64
      $value.playResult.evidenceBytes = 1
      Write-C34LSelfTestJson $stateFixture $value
    } 'premature release evidence'
    Assert-C34LSelfTestFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture | ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $record = [pscustomobject][ordered]@{
        ticketId=$ticketId; attempt=1; transition='build-start'; phase='build'
      }
      $stateValue.lifecycleTransactionProofs = @($record)
      $aggregateValue.lifecycleTransactionProofs = @($record)
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'premature lifecycle proof'

    Set-C34LSelfTestPreuploadFixture
    Invoke-C34LSelfTestPreuploadGate -WritePrerequisiteProof
    $prerequisiteProof = Get-Content -Raw `
      -LiteralPath $prerequisiteProofFixture | ConvertFrom-Json
    Assert-C34LReadinessProperties $prerequisiteProof @(
      'ticketId', 'attempt', 'versionName', 'versionCode', 'transition',
      'phase', 'passed', 'stateSha256', 'aggregateSha256', 'actionCounts',
      'releaseAuthorities', 'browserEvidence'
    ) 'preupload prerequisite proof'
    Assert-C34LReadinessProperties `
      $prerequisiteProof.browserEvidence $browserEvidenceNames `
      'preupload prerequisite browser evidence'
    Assert-C34LReadiness (
      @($prerequisiteProof.browserEvidence.PSObject.Properties).Count -eq
        $browserEvidenceNames.Count -and
      [string]$prerequisiteProof.transition -ceq 'upload-authorized' -and
      [string]$prerequisiteProof.phase -ceq 'preupload' -and
      [string]$prerequisiteProof.releaseAuthorities.uploadAndInternalActivation `
        -ceq 'held_postbuild_qualification' -and
      [string]$prerequisiteProof.browserEvidence.browserEvidencePath -ceq
        $browserProofFixtureRelative -and
      [int]$prerequisiteProof.browserEvidence.browserEvidenceAttempt -eq 1 -and
      [string]$prerequisiteProof.browserEvidence.sourceManifestPath -ceq
        $manifestFixtureRelative -and
      [string]$prerequisiteProof.browserEvidence.sourceManifestSha256 -ceq
        $manifestFixtureSha256 -and
      [long]$prerequisiteProof.browserEvidence.sourceManifestBytes -eq
        $manifestFixtureBytes -and
      [string]$prerequisiteProof.browserEvidence.blockerLedgerPath -ceq
        $ledgerFixtureRelative -and
      [string]$prerequisiteProof.browserEvidence.blockerLedgerSha256 -ceq
        $ledgerFixtureSha256 -and
      [long]$prerequisiteProof.browserEvidence.blockerLedgerBytes -eq
        $ledgerFixtureBytes -and
      [bool]$prerequisiteProof.browserEvidence.liveBrowserRouteQualified -and
      [bool]$prerequisiteProof.browserEvidence.signedInMoolSocialAppRouteProved -and
      [bool]$prerequisiteProof.browserEvidence.internalTestingRouteProved -and
      [bool]$prerequisiteProof.browserEvidence.noPlayWritePerformed -and
      $null -eq $prerequisiteProof.browserEvidence.PSObject.Properties['sessionNonce']
    ) 'canonical preupload browser-evidence proof projection changed.'

    Assert-C34LSelfTestPreuploadFailure {
      $value = Get-Content -Raw -LiteralPath $browserProofFixture |
        ConvertFrom-Json
      $value.routes.internalTestingRouteProved = $false
      Write-C34LSelfTestJson $browserProofFixture $value
    } 'false browser route'
    Assert-C34LSelfTestPreuploadFailure {
      $value = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      $value.presealUploadWorkflow.browserEvidenceSha256 = 'A' * 64
      Write-C34LSelfTestJson $aggregateFixture $value
    } 'mismatched browser mirror'
    Assert-C34LSelfTestPreuploadFailure {
      $value = Get-Content -Raw -LiteralPath $browserProofFixture |
        ConvertFrom-Json
      $format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
      $culture = [Globalization.CultureInfo]::InvariantCulture
      $value.producedUtc = [DateTime]::UtcNow.AddMinutes(-31).ToString(
        $format, $culture
      )
      $value.expiresUtc = [DateTime]::UtcNow.AddMinutes(-16).ToString(
        $format, $culture
      )
      Write-C34LSelfTestJson $browserProofFixture $value
    } 'stale browser session'
    Assert-C34LSelfTestPreuploadFailure {
      $stateValue = Get-Content -Raw -LiteralPath $stateFixture |
        ConvertFrom-Json
      $aggregateValue = Get-Content -Raw -LiteralPath $aggregateFixture |
        ConvertFrom-Json
      foreach ($value in @($stateValue, $aggregateValue)) {
        $value.presealUploadWorkflow.browserSessionId =
          'c34l-browser-session-CCCCCCCCCCCCCCCC'
      }
      Write-C34LSelfTestJson $stateFixture $stateValue
      Write-C34LSelfTestJson $aggregateFixture $aggregateValue
    } 'replayed browser session'
    Assert-C34LSelfTestPreuploadFailure {
      $value = Get-Content -Raw -LiteralPath $browserProofFixture |
        ConvertFrom-Json
      $value.transition = 'upload-succeeded'
      Write-C34LSelfTestJson $browserProofFixture $value
    } 'wrong browser tuple'
    Assert-C34LSelfTestPreuploadFailure {
      $value = Get-Content -Raw -LiteralPath $browserProofFixture |
        ConvertFrom-Json
      $value.releaseAuthorities.uploadAndInternalActivation = 'available_once'
      Write-C34LSelfTestJson $browserProofFixture $value
    } 'post-state authority substituted into preproof'

    Write-Output (
      'C34L consolidated readiness self-test passed: positive=2; negatives=20; ' +
      'wrongTicketVersionHeadRegistryAuthorityMirrorBrowserArtifact=failClosed; ' +
      'manifestBoundWrongCount=prematureArtifactEvidenceProof=failClosed; ' +
      'unwiredSource=nonBrowserTuple=workflowSchemaExtra=falseRoute=' +
      'mismatchedMirror=staleSession=' +
      'replayedSession=wrongTuple=postStateAuthorityInPreproof=failClosed; ' +
      "hostPowerShellMajor=$($PSVersionTable.PSVersion.Major); " +
      'realStateWrites=0; externalWrites=0; secretOrPrivateValuesObserved=false.'
    )
  } finally {
    $resolvedRunRoot = [IO.Path]::GetFullPath($runRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34l-blocker-browser-fixtures-readiness-')
    )
    Assert-C34LReadiness (
      $resolvedRunRoot.StartsWith(
        $expectedPrefix, [StringComparison]::OrdinalIgnoreCase
      )
    ) 'self-test cleanup target escaped the unique fixture prefix.'
    if (Test-Path -LiteralPath $resolvedRunRoot -PathType Container) {
      Remove-Item -LiteralPath $resolvedRunRoot -Recurse -Force
    }
  }
}
