[CmdletBinding()]
param(
  [string]$LockPath,

  [string]$CheckpointPath,

  [string]$StatePath,

  [switch]$RequireTicketSelectionAssessment,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
if (-not $LockPath) {
  $LockPath = Join-Path `
    $repositoryRootFull `
    'config/mvp-robust-60-75-day-delivery-lock.json'
}
if (-not $CheckpointPath) {
  $CheckpointPath = Join-Path `
    $repositoryRootFull `
    'config/mvp-pre-ticket-selection-robustness-checkpoint.json'
}
if (-not $StatePath) {
  $StatePath = Join-Path `
    $repositoryRootFull `
    'config/mvp-scope-gate-state.json'
}

function Assert-DeliveryLock {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "MVP delivery discipline lock rejected: $Message"
  }
}

function Resolve-RepositoryFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-DeliveryLock `
    -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is missing."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRootFull $Path))
  }
  Assert-DeliveryLock -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "$Label escaped the production repository."
  Assert-DeliveryLock `
    -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) `
    -Message "$Label is missing: $resolved"
  return $resolved
}

function Assert-TrueRules {
  param(
    [Parameter(Mandatory)]
    [object]$Rules,

    [Parameter(Mandatory)]
    [string[]]$Names,

    [Parameter(Mandatory)]
    [string]$Label
  )

  foreach ($name in $Names) {
    $property = $Rules.PSObject.Properties[$name]
    Assert-DeliveryLock -Condition (
      $null -ne $property -and [bool]$property.Value
    ) -Message "$Label rule '$name' is not enabled."
  }
}

$resolvedLockPath = Resolve-RepositoryFile `
  -Path $LockPath `
  -Label 'delivery lock'
$resolvedCheckpointPath = Resolve-RepositoryFile `
  -Path $CheckpointPath `
  -Label 'pre-ticket checkpoint'
$resolvedStatePath = Resolve-RepositoryFile `
  -Path $StatePath `
  -Label 'MVP scope machine state'

$lock = Get-Content -Raw -LiteralPath $resolvedLockPath | ConvertFrom-Json
Assert-DeliveryLock -Condition ([int]$lock.schemaVersion -eq 1) `
  -Message 'unsupported delivery-lock schema.'
Assert-DeliveryLock -Condition (
  [string]$lock.lockId -ceq
  'MOOLSOCIAL-MVP-ROBUST-60-75-DAY-NO-DUPLICATION-DELIVERY-LOCK-20260805'
) -Message 'unexpected delivery-lock id.'
Assert-DeliveryLock -Condition (
  [string]$lock.state -ceq 'founder_locked_active'
) -Message 'delivery lock is not active.'
Assert-DeliveryLock -Condition (
  [int]$lock.targetWindow.minimumCalendarDays -eq 60 -and
  [int]$lock.targetWindow.maximumCalendarDays -eq 75 -and
  [string]$lock.targetWindow.earliestTargetDate -ceq '2026-10-04' -and
  [string]$lock.targetWindow.latestTargetDate -ceq '2026-10-19'
) -Message '60-75-day target window changed.'
Assert-DeliveryLock -Condition (
  [bool]$lock.targetWindow.nonstopExecutionStartRequiresSeparateFounderActivation -and
  [bool]$lock.targetWindow.externalProviderAndStoreDatesAreNotEngineeringControlled -and
  [bool]$lock.targetWindow.externalDelayMustBeReportedAndMustNotBeHiddenByQualityReduction
) -Message 'timeline authority or external-dependency truth boundary changed.'
Assert-DeliveryLock -Condition (
  [int]$lock.implementationTopologyTargets.canonicalRouteTargetMinimum -eq 35 -and
  [int]$lock.implementationTopologyTargets.canonicalRouteTargetMaximum -eq 48 -and
  [int]$lock.implementationTopologyTargets.routeLevelV2ScreenTargetMinimum -eq 32 -and
  [int]$lock.implementationTopologyTargets.routeLevelV2ScreenTargetMaximum -eq 40
) -Message 'anti-duplication topology targets changed.'

$requiredLockRules = @(
  'robustFounderDefinedMvpRequired',
  'maximizeUsefulFeaturesInsideApprovedMvpThroughReuse',
  'blockUnnecessaryDuplicateCode',
  'blockDuplicateScreensPerUserType',
  'blockDuplicateRoutesPerUserType',
  'blockDuplicateBackendOwners',
  'oneSharedBuySurfaceForAllEligibleBuyers',
  'sharedScreensUseExactDataCapabilityAndPolicyVariants',
  'sharedBackendOwnersUseThinExactPolicyAdapters',
  'acceptanceTicketsRemainExactByActorAndOutcome',
  'ticketCountDoesNotImplyScreenRouteServiceOrBuildCount',
  'newScreenRequiresRecordedNecessityProof',
  'newRouteRequiresRecordedNecessityProof',
  'newBackendOwnerRequiresRecordedNecessityProof',
  'reuseExistingNonUiOwnersBeforeCreatingAnotherOwner',
  'legacyPresentationRemainsReadOnly',
  'beyondMvpRequiresSeparateExactFounderAuthorization',
  'securityPrivacyAccessibilityRecoveryAndReleaseGatesCannotBeWaived',
  'dependencyHeldWorkCannotBeFabricatedAsComplete',
  'criticalTimelineThreatMustBeReportedImmediatelyWithSmallestLawfulMitigation'
)
Assert-TrueRules `
  -Rules $lock.rules `
  -Names $requiredLockRules `
  -Label 'delivery lock'
Assert-DeliveryLock -Condition (
  -not [bool]$lock.authorityBoundary.executionActivationAtRegistration -and
  [bool]$lock.authorityBoundary.changesImplementationTopologyWithoutChangingApprovedCustomerOutcomes -and
  [bool]$lock.authorityBoundary.doesNotActivateAnyTicket -and
  [bool]$lock.authorityBoundary.doesNotAuthorizeRuntimeBackendBuildDeviceExternalCommitPushDeployOrPromotion -and
  [bool]$lock.authorityBoundary.materialManifestOrOutcomeChangeRequiresVersionedFounderAmendment
) -Message 'delivery-lock authority boundary changed.'

[void](Resolve-RepositoryFile `
  -Path ([string]$lock.humanAuthority) `
  -Label 'delivery-lock human authority')

$nativeDirectivePath = Resolve-RepositoryFile `
  -Path ([string]$lock.nativeFlutterNavigationAuthority.path) `
  -Label 'native Flutter navigation directive'
$nativeDirectiveHash = (
  Get-FileHash -Algorithm SHA256 -LiteralPath $nativeDirectivePath
).Hash
Assert-DeliveryLock -Condition (
  $nativeDirectiveHash -ceq
    ([string]$lock.nativeFlutterNavigationAuthority.sha256).ToUpperInvariant()
) -Message 'native Flutter navigation directive hash changed.'
$nativeDirective = Get-Content -Raw -LiteralPath $nativeDirectivePath |
  ConvertFrom-Json
Assert-DeliveryLock -Condition (
  [int]$nativeDirective.schemaVersion -eq 1 -and
  [string]$nativeDirective.directiveId -ceq
    'MOOLSOCIAL-MVP-NATIVE-FLUTTER-WHIRLPOOL-NAVIGATION-MOTION-20260805' -and
  [string]$nativeDirective.state -ceq 'founder_directed_active'
) -Message 'native Flutter navigation directive identity changed.'
Assert-DeliveryLock -Condition (
  [bool]$nativeDirective.nativeFlutterBoundary.directNativeFlutterV2Authorized -and
  -not [bool]$nativeDirective.nativeFlutterBoundary.htmlFirstVisualParityRequired -and
  [bool]$nativeDirective.nativeFlutterBoundary.versionedInteractionAndNavigationContractRequired -and
  [bool]$nativeDirective.nativeFlutterBoundary.reuseExistingNonUiOwnersRequired -and
  [bool]$nativeDirective.nativeFlutterBoundary.duplicateScreensRoutesAndStateOwnersBlocked -and
  [bool]$nativeDirective.navigationModel.moolReachableInOneTapFromEveryPrimarySurface -and
  [bool]$nativeDirective.navigationModel.chatReachableInOneTapFromEveryPrimarySurface -and
  -not [bool]$nativeDirective.navigationModel.literalSpinningOrDisorientingNavigationAllowed -and
  [bool]$nativeDirective.motionModel.reducedMotionRequired -and
  -not [bool]$nativeDirective.motionModel.perpetualDecorativeLoopsAllowed -and
  -not [bool]$nativeDirective.motionModel.fabricatedLoadingOrLivenessAllowed
) -Message 'native Flutter navigation, motion or anti-duplication rule changed.'

$protectedManifests = @($lock.protectedPreauthorizedManifests)
Assert-DeliveryLock -Condition ($protectedManifests.Count -eq 3) `
  -Message 'protected preauthorized manifest inventory changed.'
foreach ($manifest in $protectedManifests) {
  $manifestPath = Resolve-RepositoryFile `
    -Path ([string]$manifest.path) `
    -Label "protected manifest '$($manifest.id)'"
  $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash
  Assert-DeliveryLock -Condition (
    $actualHash -ceq ([string]$manifest.sha256).ToUpperInvariant()
  ) -Message "protected manifest '$($manifest.id)' hash changed."
}

$checkpoint = Get-Content -Raw -LiteralPath $resolvedCheckpointPath |
  ConvertFrom-Json
Assert-DeliveryLock -Condition ([int]$checkpoint.schemaVersion -eq 1) `
  -Message 'unsupported selection-checkpoint schema.'
Assert-DeliveryLock -Condition (
  [string]$checkpoint.checkpointId -ceq
  'MOOLSOCIAL-MVP-PRE-TICKET-SELECTION-ROBUSTNESS-REUSE-CHECKPOINT-20260805'
) -Message 'unexpected selection-checkpoint id.'
Assert-DeliveryLock -Condition (
  [string]$checkpoint.state -ceq
  'founder_required_fail_closed_for_every_successor_selection'
) -Message 'selection checkpoint is not active.'
Assert-TrueRules `
  -Rules $checkpoint.rules `
  -Names @(
    'checkpointRequiredBeforeEverySuccessorSelection',
    'failureOrMissingEvidenceBlocksSelection',
    'adjustmentCannotCreateAuthority',
    'exactAcceptanceTicketsRemainTraceable',
    'robustnessCannotBeReducedForTimeline',
    'duplicateImplementationCannotBeJustifiedByTicketCount'
  ) `
  -Label 'selection checkpoint'
[void](Resolve-RepositoryFile `
  -Path ([string]$checkpoint.humanAuthority) `
  -Label 'selection-checkpoint human authority')

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
$lockHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedLockPath).Hash
$checkpointHash = (
  Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedCheckpointPath
).Hash
Assert-DeliveryLock -Condition (
  [string]$state.deliveryDisciplineLock.lockId -ceq [string]$lock.lockId -and
  [string]$state.deliveryDisciplineLock.path -ceq
    'config/mvp-robust-60-75-day-delivery-lock.json' -and
  ([string]$state.deliveryDisciplineLock.sha256).ToUpperInvariant() -ceq
    $lockHash -and
  [string]$state.deliveryDisciplineLock.state -ceq [string]$lock.state
) -Message 'MVP scope state does not pin the current delivery lock.'
Assert-DeliveryLock -Condition (
  [string]$state.preTicketSelectionCheckpoint.checkpointId -ceq
    [string]$checkpoint.checkpointId -and
  [string]$state.preTicketSelectionCheckpoint.path -ceq
    'config/mvp-pre-ticket-selection-robustness-checkpoint.json' -and
  ([string]$state.preTicketSelectionCheckpoint.sha256).ToUpperInvariant() -ceq
    $checkpointHash
) -Message 'MVP scope state does not pin the current selection checkpoint.'

if ($RequireTicketSelectionAssessment) {
  $ticketId = [string]$state.ticket.id
  $transition = $checkpoint.currentTicketTransition
  $isPreCheckpointTicket = (
    [bool]$transition.selectedBeforeCheckpoint -and
    [string]$transition.ticketId -ceq $ticketId -and
    [string]$state.preTicketSelectionCheckpoint.state -ceq
      'current_pre_checkpoint_ticket_future_successor_selection_closed'
  )
  if (-not $isPreCheckpointTicket) {
    $assessment = $state.preTicketSelectionCheckpoint.selectedTicketAssessment
    Assert-DeliveryLock -Condition ($null -ne $assessment) `
      -Message 'selected successor ticket has no robustness/reuse assessment.'
    Assert-DeliveryLock -Condition (
      [string]$assessment.ticketId -ceq $ticketId
    ) -Message 'selection assessment ticket id does not match active ticket.'
    foreach ($field in @('customerOutcome', 'necessityProof')) {
      Assert-DeliveryLock -Condition (
        -not [string]::IsNullOrWhiteSpace([string]$assessment.$field)
      ) -Message "selection assessment field '$field' is missing."
    }
    foreach ($field in @(
        'implementationDisposition',
        'sharedImplementationOwners',
        'newScreens',
        'newRoutes',
        'newBackendOwners',
        'robustnessCoverage',
        'adjustments',
        'explicitExclusions',
        'dependenciesAndApprovals'
      )) {
      $property = $assessment.PSObject.Properties[$field]
      Assert-DeliveryLock -Condition ($null -ne $property) `
        -Message "selection assessment field '$field' is absent."
    }
    $dispositions = @($assessment.implementationDisposition)
    $allowedDispositions = @(
      'reuse',
      'configuration',
      'thin_policy_adapter',
      'test_only_acceptance',
      'new_necessary_work'
    )
    Assert-DeliveryLock -Condition ($dispositions.Count -gt 0) `
      -Message 'selection assessment has no implementation disposition.'
    foreach ($disposition in $dispositions) {
      Assert-DeliveryLock -Condition (
        $allowedDispositions -ccontains [string]$disposition
      ) -Message "unsupported implementation disposition '$disposition'."
    }
    Assert-DeliveryLock -Condition (
      @($assessment.robustnessCoverage).Count -gt 0 -and
      @($assessment.explicitExclusions).Count -gt 0 -and
      @($assessment.dependenciesAndApprovals).Count -gt 0
    ) -Message 'selection assessment lacks robustness, exclusions or dependency evidence.'
    $manifestPath = Resolve-RepositoryFile `
      -Path ([string]$assessment.manifestPath) `
      -Label 'selected-ticket manifest'
    $manifestHash = (
      Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath
    ).Hash
    Assert-DeliveryLock -Condition (
      $manifestHash -ceq
        ([string]$assessment.manifestSha256).ToUpperInvariant()
    ) -Message 'selected-ticket manifest hash does not match the assessment.'
    Assert-DeliveryLock -Condition ([int]$assessment.timelineImpactDays -ge 0) `
      -Message 'selection assessment timeline impact is invalid.'
    Assert-DeliveryLock -Condition (
      [bool]$assessment.reuseInventoryComplete -and
      [bool]$assessment.duplicateSearchComplete -and
      [bool]$assessment.within60To75DayLock
    ) -Message 'selection assessment did not pass reuse, duplication and timeline checks.'
    [void](Resolve-RepositoryFile `
      -Path ([string]$assessment.evidencePath) `
      -Label 'selected-ticket robustness/reuse evidence')
  }
}

Write-Output (
  'MVP delivery discipline lock passed: window=60-75 days; ' +
  'routes=35-48; screens=32-40; protectedManifests=3; ' +
  "ticket=$([string]$state.ticket.id)."
)
