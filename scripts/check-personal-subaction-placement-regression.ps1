[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireImplemented,
  [switch]$RequireOppoQualified
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-subaction-reachability-promotion-zone-regression.json'
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
  throw 'Sub-action reachability and promotion-zone regression contract is missing.'
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ([int]$contract.schemaVersion -ne 1 -or
    [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-SUBACTION-REACHABILITY-PROMOTION-ZONE-REGRESSION-V1' -or
    [string]$contract.regressionId -cne 'REG-20260807-240-C10E-SUBACTIONS-MOVED-INTO-TOP-PROMOTION-ZONE') {
  throw 'Sub-action reachability and promotion-zone regression identity is invalid.'
}

$isC23Successor = [string]$contract.state -like 'c23*'
if ($isC23Successor) {
  $homeHub = $contract.c23HomeHub
  if ([int]$homeHub.destinationPersistentGlobalRails -ne 0 -or
      [int]$homeHub.destinationPersistentSubactionRails -ne 0 -or
      [int]$homeHub.destinationMoolHomeLauncherCount -ne 1 -or
      [int]$homeHub.destinationLauncherMinimumTapTarget -ne 56 -or
      [int]$homeHub.homeFamilyCount -ne 6 -or
      [int]$homeHub.homeSubactionCount -ne 17 -or
      [int]$homeHub.homeMinimumTapTarget -ne 44 -or
      [int]$homeHub.mainAndSubactionTapBudgetFromHome -ne 1 -or
      [int]$homeHub.maximumTapBudgetFromDestination -ne 2 -or
      [bool]$homeHub.familyExpansionTapAllowed -or
      [bool]$homeHub.horizontalActionScrollAllowed -or
      [bool]$homeHub.persistentBottomChatAllowed -or
      [string]$homeHub.sharedOwner -cne 'MoolHomeHubFamilyRow' -or
      [string]$homeHub.tokenOwner -cne 'MoolHomeHubTokens' -or
      (@($homeHub.familyIds) -join ',') -cne 'social,buy,eat,ride,book,work' -or
      [string]$homeHub.successorGate -cne 'scripts/check-personal-mool-home-action-hub-c23g.ps1') {
    throw 'C23 zero-rail Home-hub placement and tap-budget contract has drifted.'
  }
  if ($RequireOppoQualified) { $RequireImplemented = $true }
  if ($RequireImplemented) {
    $shared = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart')
    $moolHomeSource = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\personal_mool_root_v2.dart')
    $design = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart')
    if ($shared -notmatch "activeId == 'mool'.*onOpenMool == null" -or
        -not $shared.Contains("key: const Key('mool-home-launcher')") -or
        -not $shared.Contains('child: _MoolHomeLauncher(onPressed: onOpenMool!)') -or
        -not $moolHomeSource.Contains('for (var index = 0; index < _moolHomeFamilies.length; index++)' ) -or
        -not $moolHomeSource.Contains("key: const Key('mool-home-chat')") -or
        -not $design.Contains('class MoolHomeHubFamilyRow extends StatelessWidget') -or
        -not $design.Contains('static const double subactionHeight = MoolMetrics.minimumTapTarget')) {
      throw 'C23 implemented zero-rail Home-hub source owners are incomplete.'
    }
  }
  if ($RequireOppoQualified -and
      [string]$contract.resolution.oppoQualification -cne 'passed') {
    throw 'C23 checksum-matched OPPO Home-hub qualification is not passed.'
  }
  Write-Output "Sub-action placement regression contract passed: successor=C23; implementedRequired=$RequireImplemented; oppoRequired=$RequireOppoQualified; destinationRails=0; launcher=1; families=6; subactions=17; tapBudgetHome=1; tapBudgetDestination=2."
  return
}

if (-not [bool]$contract.rules.topPromotionMediaZoneReserved -or
    [bool]$contract.rules.subactionsMayOccupyTopPromotionMediaZone -or
    -not [bool]$contract.rules.oneHandedThumbReachRequired -or
    [int]$contract.rules.routineSubactionTapBudget -ne 1 -or
    -not [bool]$contract.rules.subactionsRemainDestinationLocal -or
    [bool]$contract.rules.globalBottomRailGeometryMayChange -or
    [bool]$contract.rules.defaultMoreMenuAllowed -or
    [bool]$contract.rules.defaultModalOrPaletteAllowed -or
    -not [bool]$contract.rules.compactAndLargeTextRequired -or
    -not [bool]$contract.rules.reducedMotionRequired -or
    -not [bool]$contract.rules.realOppoOneHandedTapEvidenceRequired) {
  throw 'Sub-action reachability and promotion-zone founder rules have been weakened.'
}

$isC22Successor = [string]$contract.state -like 'c22*'
if ($isC22Successor) {
  $professional = $contract.professionalDesignSystem
  if ([int]$contract.rules.maximumFamilyRailHeight -ne 52 -or
      [int]$contract.rules.minimumTapTarget -ne 48 -or
      [bool]$contract.rules.translucentLowShadowSurfaceRequired -or
      -not [bool]$contract.rules.fullyTransparentFamilySurfaceRequired -or
      [double]$contract.rules.maximumSurfaceOpacity -ne 0 -or
      -not [bool]$contract.rules.raisedCardShadowAllowed -or
      [bool]$contract.rules.separateFamilyTileAllowed -or
      -not [bool]$contract.rules.perActionBoxBorderAllowed -or
      [bool]$contract.rules.filledSelectedPillAllowed -or
      -not [bool]$contract.rules.thinFamilyConnectorRequired -or
      [bool]$contract.rules.destinationFamilyAccentRequired -or
      -not [bool]$contract.rules.internalCapsuleFamilyChromaRequired -or
      [bool]$contract.rules.animatedGradientWaveConnectionRequired -or
      [bool]$contract.rules.waveLinksSelectedMainToSelectedSubaction -or
      -not [bool]$contract.rules.reverseUFirstToLastCapsuleCentersRequired -or
      -not [bool]$contract.rules.reverseUSelectedMainStemRequired -or
      [bool]$contract.rules.wavePerpetualMotionAllowed -or
      -not [bool]$contract.rules.waveReducedMotionSettlesImmediately -or
      [bool]$contract.rules.waveMayOwnHitTestingOrSemantics -or
      [bool]$contract.rules.sideToSideFamilyPanelAllowed -or
      -not [bool]$contract.rules.destinationContentMustRemainVisibleBehindLayer -or
      -not [bool]$contract.rules.singleNativeShellContinuityRequired -or
      -not [bool]$contract.rules.globalRailMustRemainVisuallyAnchoredAcrossDestinationSwitches -or
      [bool]$contract.rules.mainOrSubactionSwitchMayFeelLikeUnrelatedPageNavigation) {
    throw 'C22 capsule placement, zero-strap, reverse-U, ownership or continuity rules have been weakened.'
  }
  if ([string]$professional.nativeFlutterSharedOwner -cne 'MoolLocalNavigationRail' -or
      [string]$professional.tokenOwner -cne 'MoolLocalNavigationTokens' -or
      (@($professional.familyIds) -join ',') -cne 'social,buy,eat,ride,book,work' -or
      [double]$professional.commonIconSize -ne 18 -or
      [double]$professional.commonLabelFontSize -ne 12 -or
      [int]$professional.commonLabelFontWeight -ne 800 -or
      [double]$professional.commonGap -ne 8 -or
      [double]$professional.selectedIndicatorWidth -ne 0 -or
      [double]$professional.selectedIndicatorHeight -ne 0 -or
      [double]$professional.compactClusterWidthsAt320.twoActions -ne 152 -or
      [double]$professional.compactClusterWidthsAt320.threeActions -ne 232 -or
      [double]$professional.compactClusterWidthsAt320.fourActions -ne 312 -or
      [bool]$professional.horizontalScrollOrPanelAllowed -or
      [bool]$professional.distributedSparseCellsAllowed -or
      [double]$professional.minimumTapTarget -ne 48 -or
      [double]$professional.capsuleWidth -ne 72 -or
      [double]$professional.railHeight -ne 52 -or
      [double]$professional.controlRadius -ne 24 -or
      [double]$professional.backdropBlurSigma -ne 20 -or
      [string]$professional.neutralGlassTopArgb -cne 'B30D1326' -or
      [string]$professional.neutralGlassBottomArgb -cne 'AB050816' -or
      [double]$professional.minimumNeutralDestinationTransmission -ne .29 -or
      [double]$professional.minimumForegroundContrastRatio -ne 4.5 -or
      [double]$professional.maximumNavigationTextScale -ne 1.3 -or
      -not [bool]$professional.selectedTintMayIncreaseAlpha -or
      -not [bool]$professional.individualControlBorderRequired -or
      -not [bool]$professional.controlledNeutralGradientRequired -or
      -not [bool]$professional.specularInnerEdgeRequired -or
      -not [bool]$professional.perActionShadowRequired -or
      -not [bool]$professional.selectedElevationRequired -or
      [bool]$professional.heavySelectedOutlineAllowed -or
      [double]$professional.pressedScale -ne .975 -or
      [int]$professional.pressMotionMilliseconds -ne 100 -or
      [int]$professional.stateMotionMilliseconds -ne 180 -or
      [double]$professional.maximumInternalEmissionAlpha -ne .28 -or
      [double]$professional.internalEmissionCenterAlpha -ne .27 -or
      [double]$professional.internalEmissionMiddleAlpha -ne .135 -or
      [double]$professional.disclosureBadgeSize -ne 18 -or
      [double]$professional.disclosureBadgeIconSize -ne 14 -or
      [double]$professional.selectedMainActionTapTargetHeight -ne 48 -or
      -not [bool]$professional.selectedMainActionOwnsDisclosureTap -or
      -not [bool]$professional.defaultExpanded -or
      -not [bool]$professional.selectedMainRetapHidesAndRestoresOwnFamily -or
      -not [bool]$professional.disclosureStateIsSessionOnly -or
      -not [bool]$professional.truthfulHideShowSemanticsRequired -or
      [double]$professional.connectionLineStrokeWidth -ne 1.25 -or
      [double]$professional.connectionLineMaximumOpacity -ne .24 -or
      [double]$professional.connectionDotRadius -ne 1.5 -or
      [bool]$professional.connectionOwnsHitTestingOrSemantics -or
      [int]$professional.connectionMotionMilliseconds -ne 180 -or
      -not [bool]$professional.reducedMotionImmediate -or
      -not [bool]$professional.selectedActionIsInert -or
      -not [bool]$professional.availableActionSemanticTapRequired -or
      -not [bool]$professional.providerAssetSupportRequired -or
      [double]$professional.providerGlyphSize -ne 18) {
    throw 'C22 professional capsule shared-owner contract has been weakened.'
  }
  $expectedSourceOwners = @(
    'buyHeaderTabs',
    'socialTopContextTabs',
    'eatFirstContentRail',
    'rideFirstContentRail',
    'bookFirstContentRail',
    'workFirstContentRail'
  )
  $actualSourceOwners = @($contract.currentSourceDisposition.PSObject.Properties.Name)
  if (($actualSourceOwners -join ',') -cne ($expectedSourceOwners -join ',')) {
    throw 'C22 sub-action source-owner inventory is incomplete.'
  }
  foreach ($owner in $expectedSourceOwners) {
    if ([string]$contract.currentSourceDisposition.$owner -cne
        'implemented_c22_shared_fixed_capsule_zero_strap_owner') {
      throw "C22 source owner is not fixed-capsule qualified: $owner"
    }
  }
  if ($RequireOppoQualified) { $RequireImplemented = $true }
  if ($RequireImplemented) {
    if ([string]$contract.founderDecision.state -cne 'approved') {
      throw 'C22 founder capsule placement decision is not approved.'
    }
    $scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
    $scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
    $current = [string]$scope.ticket.id
    $implementedGate = if ($current -ceq
        'UAW-PERSONAL-MVP-COMPOSITE-GLASS-LEGIBILITY-FIX5-C22F1') {
      Join-Path $root 'scripts\check-personal-composite-glass-legibility-c22f1.ps1'
    } elseif ($current -cin @(
        'UAW-PERSONAL-MVP-CAPSULE-SYSTEM-HOST-QUALIFICATION-FIX5-C22G',
        'UAW-PERSONAL-MVP-CAPSULE-SYSTEM-OPPO-QUALIFICATION-FIX5-C22H'
      )) {
      Join-Path $root 'scripts\check-personal-capsule-system-c22g.ps1'
    } else {
      throw "C22 placement replay does not recognize active ticket: $current"
    }
    & $implementedGate -RepositoryRoot $root
  }
  if ($RequireOppoQualified -and
      ([string]$contract.resolution.state -cne 'implemented_host_and_oppo_qualified' -or
       [string]$contract.resolution.oppoQualification -cne 'passed')) {
    throw 'C22 checksum-matched OPPO one-handed qualification is not passed.'
  }
  Write-Output "Sub-action placement regression contract passed: successor=C22; implementedRequired=$RequireImplemented; oppoRequired=$RequireOppoQualified; rail=52px; capsule=72x48-r24; zeroStrap=true; reverseU=true; compositeContrast=4.5; founderDecision=$($contract.founderDecision.state)."
  return
}

$isC21Successor = [string]$contract.state -like 'c21*'
if ($isC21Successor) {
  $professional = $contract.professionalDesignSystem
  if ([int]$contract.rules.maximumFamilyRailHeight -ne 52 -or
      [int]$contract.rules.minimumTapTarget -ne 48 -or
      [bool]$contract.rules.translucentLowShadowSurfaceRequired -or
      -not [bool]$contract.rules.fullyTransparentFamilySurfaceRequired -or
      [double]$contract.rules.maximumSurfaceOpacity -ne 0 -or
      -not [bool]$contract.rules.raisedCardShadowAllowed -or
      [bool]$contract.rules.separateFamilyTileAllowed -or
      -not [bool]$contract.rules.perActionBoxBorderAllowed -or
      [bool]$contract.rules.filledSelectedPillAllowed -or
      -not [bool]$contract.rules.thinFamilyConnectorRequired -or
      [bool]$contract.rules.destinationFamilyAccentRequired -or
      [bool]$contract.rules.wavePerpetualMotionAllowed -or
      -not [bool]$contract.rules.waveReducedMotionSettlesImmediately -or
      [bool]$contract.rules.waveMayOwnHitTestingOrSemantics -or
      [bool]$contract.rules.sideToSideFamilyPanelAllowed -or
      -not [bool]$contract.rules.destinationContentMustRemainVisibleBehindLayer -or
      -not [bool]$contract.rules.singleNativeShellContinuityRequired -or
      -not [bool]$contract.rules.globalRailMustRemainVisuallyAnchoredAcrossDestinationSwitches -or
      [bool]$contract.rules.mainOrSubactionSwitchMayFeelLikeUnrelatedPageNavigation) {
    throw 'C21 optical-glass placement, transparency, ownership or continuity rules have been weakened.'
  }
  if ([string]$professional.nativeFlutterSharedOwner -cne 'MoolLocalNavigationRail' -or
      [string]$professional.tokenOwner -cne 'MoolLocalNavigationTokens' -or
      (@($professional.familyIds) -join ',') -cne 'social,buy,eat,ride,book,work' -or
      [double]$professional.commonIconSize -ne 20 -or
      [double]$professional.commonLabelFontSize -ne 13 -or
      [double]$professional.commonGap -ne 8 -or
      [double]$professional.selectedIndicatorWidth -ne 12 -or
      [double]$professional.selectedIndicatorHeight -ne 2 -or
      [double]$professional.compactClusterWidthsAt320.twoActions -ne 200 -or
      [double]$professional.compactClusterWidthsAt320.threeActions -ne 268 -or
      [double]$professional.compactClusterWidthsAt320.fourActions -ne 304 -or
      [bool]$professional.horizontalScrollOrPanelAllowed -or
      [bool]$professional.distributedSparseCellsAllowed -or
      [double]$professional.minimumTapTarget -ne 48 -or
      [double]$professional.railHeight -ne 52 -or
      [double]$professional.controlRadius -ne 15 -or
      [double]$professional.backdropBlurSigma -ne 20 -or
      [string]$professional.lightGlassTopArgb -cne 'D6FFFFFF' -or
      [string]$professional.lightGlassBottomArgb -cne 'B8FFFFFF' -or
      [string]$professional.mediaGlassTopArgb -cne 'C4141C2D' -or
      [string]$professional.mediaGlassBottomArgb -cne 'B00A1120' -or
      [double]$professional.minimumForegroundContrastRatio -ne 4.5 -or
      [double]$professional.maximumNavigationTextScale -ne 1.3 -or
      -not [bool]$professional.selectedTintMayIncreaseAlpha -or
      -not [bool]$professional.individualControlBorderRequired -or
      -not [bool]$professional.controlledNeutralGradientRequired -or
      -not [bool]$professional.specularInnerEdgeRequired -or
      -not [bool]$professional.perActionShadowRequired -or
      -not [bool]$professional.selectedElevationRequired -or
      [bool]$professional.heavySelectedOutlineAllowed -or
      [double]$professional.pressedScale -ne .975 -or
      [int]$professional.pressMotionMilliseconds -ne 100 -or
      [int]$professional.stateMotionMilliseconds -ne 160 -or
      [double]$professional.disclosureBadgeSize -ne 18 -or
      [double]$professional.disclosureBadgeIconSize -ne 14 -or
      [double]$professional.selectedMainActionTapTargetHeight -ne 48 -or
      -not [bool]$professional.selectedMainActionOwnsDisclosureTap -or
      -not [bool]$professional.defaultExpanded -or
      -not [bool]$professional.selectedMainRetapHidesAndRestoresOwnFamily -or
      -not [bool]$professional.disclosureStateIsSessionOnly -or
      -not [bool]$professional.truthfulHideShowSemanticsRequired -or
      [double]$professional.connectionLineStrokeWidth -ne 1.25 -or
      [double]$professional.connectionLineMaximumOpacity -ne .24 -or
      [double]$professional.connectionDotRadius -ne 1.5 -or
      [bool]$professional.connectionOwnsHitTestingOrSemantics -or
      [int]$professional.connectionMotionMilliseconds -ne 200 -or
      -not [bool]$professional.reducedMotionImmediate -or
      -not [bool]$professional.selectedActionIsInert -or
      -not [bool]$professional.availableActionSemanticTapRequired -or
      -not [bool]$professional.providerAssetSupportRequired -or
      [double]$professional.providerGlyphSize -ne 18) {
    throw 'C21 professional optical-glass shared-owner contract has been weakened.'
  }
  $expectedSourceOwners = @(
    'buyHeaderTabs',
    'socialTopContextTabs',
    'eatFirstContentRail',
    'rideFirstContentRail',
    'bookFirstContentRail',
    'workFirstContentRail'
  )
  $actualSourceOwners = @($contract.currentSourceDisposition.PSObject.Properties.Name)
  if (($actualSourceOwners -join ',') -cne ($expectedSourceOwners -join ',')) {
    throw 'C21 sub-action source-owner inventory is incomplete.'
  }
  $expectedDisposition = @{
    buyHeaderTabs = if ([string]$contract.state -like 'c21b*' -or
        [string]$contract.state -like 'c21c*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21d_buy_light_compositing_and_content_dominance_qualified'
    }
    socialTopContextTabs = if ([string]$contract.state -like 'c21b*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21c_social_media_and_provider_optical_normalization_qualified'
    }
    eatFirstContentRail = if ([string]$contract.state -like 'c21[b-d]*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21e_two_action_adaptive_and_content_reachability_qualified'
    }
    rideFirstContentRail = if ([string]$contract.state -like 'c21[b-d]*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21e_three_action_adaptive_and_content_reachability_qualified'
    }
    bookFirstContentRail = if ([string]$contract.state -like 'c21[b-d]*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21e_two_action_adaptive_and_content_reachability_qualified'
    }
    workFirstContentRail = if ([string]$contract.state -like 'c21[b-d]*') {
      'implemented_c21b_shared_optical_owner_family_qualification_pending'
    } else {
      'implemented_c21e_two_action_adaptive_and_content_reachability_qualified'
    }
  }
  foreach ($owner in $expectedSourceOwners) {
    if ([string]$contract.currentSourceDisposition.$owner -cne [string]$expectedDisposition.$owner) {
      throw "C21 source owner disposition is not sequentially qualified: $owner"
    }
  }
  if ($RequireOppoQualified) { $RequireImplemented = $true }
  if ($RequireImplemented) {
    if ([string]$contract.founderDecision.state -cne 'approved') {
      throw 'C21 founder optical placement decision is not approved.'
    }
    $implementedGate = if ([string]$contract.state -like 'c21b*') {
      Join-Path $root 'scripts\check-personal-shared-optical-liquid-glass-control-c21b.ps1'
    } elseif ([string]$contract.state -like 'c21c*') {
      Join-Path $root 'scripts\check-personal-social-media-glass-conformance-c21c.ps1'
    } elseif ([string]$contract.state -like 'c21d*') {
      Join-Path $root 'scripts\check-personal-buy-commerce-glass-conformance-c21d.ps1'
    } elseif ([string]$contract.state -like 'c21e*') {
      Join-Path $root 'scripts\check-personal-eat-ride-book-work-adaptive-glass-conformance-c21e.ps1'
    } else {
      Join-Path $root 'scripts\check-personal-subaction-disclosure-selection-motion-refinement-c21f.ps1'
    }
    if (-not (Test-Path -LiteralPath $implementedGate -PathType Leaf)) {
      throw 'C21 sequential optical-glass implementation gate is missing.'
    }
    & $implementedGate -RepositoryRoot $root
  }
  if ($RequireOppoQualified -and
      ([string]$contract.resolution.state -cne 'implemented_host_and_oppo_qualified' -or
       [string]$contract.resolution.oppoQualification -cne 'passed')) {
    throw 'C21 checksum-matched OPPO one-handed qualification is not passed.'
  }
  Write-Output "Sub-action placement regression contract passed: successor=C21; implementedRequired=$RequireImplemented; oppoRequired=$RequireOppoQualified; rail=52px; target=48px; transparent=true; independentOpticalGlass=true; founderDecision=$($contract.founderDecision.state)."
  return
}

$isC17Successor = [string]$contract.state -like 'c17*'
if ($isC17Successor) {
  $professional = $contract.professionalDesignSystem
  if ([int]$contract.rules.maximumFamilyRailHeight -ne 52 -or
      [int]$contract.rules.minimumTapTarget -ne 48 -or
      [bool]$contract.rules.translucentLowShadowSurfaceRequired -or
      -not [bool]$contract.rules.fullyTransparentFamilySurfaceRequired -or
      [double]$contract.rules.maximumSurfaceOpacity -ne 0 -or
      [bool]$contract.rules.raisedCardShadowAllowed -or
      [bool]$contract.rules.separateFamilyTileAllowed -or
      -not [bool]$contract.rules.perActionBoxBorderAllowed -or
      [bool]$contract.rules.filledSelectedPillAllowed -or
      -not [bool]$contract.rules.thinFamilyConnectorRequired -or
      [bool]$contract.rules.wavePerpetualMotionAllowed -or
      -not [bool]$contract.rules.waveReducedMotionSettlesImmediately -or
      [bool]$contract.rules.waveMayOwnHitTestingOrSemantics -or
      [bool]$contract.rules.sideToSideFamilyPanelAllowed -or
      -not [bool]$contract.rules.destinationContentMustRemainVisibleBehindLayer -or
      -not [bool]$contract.rules.singleNativeShellContinuityRequired -or
      -not [bool]$contract.rules.globalRailMustRemainVisuallyAnchoredAcrossDestinationSwitches -or
      [bool]$contract.rules.mainOrSubactionSwitchMayFeelLikeUnrelatedPageNavigation) {
    throw 'C17 clear-glass placement, transparency, ownership or continuity rules have been weakened.'
  }
  if ([string]$professional.nativeFlutterSharedOwner -cne 'MoolLocalNavigationRail' -or
      [string]$professional.tokenOwner -cne 'MoolLocalNavigationTokens' -or
      (@($professional.familyIds) -join ',') -cne 'social,buy,eat,ride,book,work' -or
      [double]$professional.commonIconSize -ne 20 -or
      [double]$professional.commonLabelFontSize -ne 12 -or
      [double]$professional.commonGap -ne 4 -or
      [double]$professional.selectedIndicatorWidth -ne 18 -or
      [double]$professional.selectedIndicatorHeight -ne 2 -or
      [double]$professional.compactClusterWidthsAt320.twoActions -ne 212 -or
      [double]$professional.compactClusterWidthsAt320.threeActions -ne 272 -or
      [double]$professional.compactClusterWidthsAt320.fourActions -ne 312 -or
      [bool]$professional.horizontalScrollOrPanelAllowed -or
      [bool]$professional.distributedSparseCellsAllowed -or
      [double]$professional.minimumTapTarget -ne 48 -or
      [double]$professional.railHeight -ne 52 -or
      [double]$professional.controlRadius -ne 14 -or
      [double]$professional.backdropBlurSigma -ne 16 -or
      [double]$professional.lightGlassAlpha -ne .52 -or
      [double]$professional.mediaGlassAlpha -ne .58 -or
      [double]$professional.minimumForegroundContrastRatio -ne 4.5 -or
      [double]$professional.maximumNavigationTextScale -ne 1.3 -or
      [bool]$professional.selectedTintMayIncreaseAlpha -or
      -not [bool]$professional.individualControlBorderRequired -or
      -not [bool]$professional.selectedActionIsInert -or
      -not [bool]$professional.availableActionSemanticTapRequired -or
      -not [bool]$professional.providerAssetSupportRequired) {
    throw 'C17 professional clear-glass shared-owner contract has been weakened.'
  }
  $expectedSourceOwners = @(
    'buyHeaderTabs',
    'socialTopContextTabs',
    'eatFirstContentRail',
    'rideFirstContentRail',
    'bookFirstContentRail',
    'workFirstContentRail'
  )
  $actualSourceOwners = @($contract.currentSourceDisposition.PSObject.Properties.Name)
  if (($actualSourceOwners -join ',') -cne ($expectedSourceOwners -join ',')) {
    throw 'C17 sub-action source-owner inventory is incomplete.'
  }
  foreach ($owner in $expectedSourceOwners) {
    if ([string]$contract.currentSourceDisposition.$owner -cne
        'implemented_c17_clear_glass_shared_owner_family_qualified') {
      throw "C17 source owner is not family-qualified: $owner"
    }
  }
  if ($RequireOppoQualified) { $RequireImplemented = $true }
  if ($RequireImplemented) {
    if ([string]$contract.founderDecision.state -cne 'approved') {
      throw 'C17 founder placement decision is not approved.'
    }
    $familyGate = Join-Path $root 'scripts\check-personal-eat-ride-book-work-clear-glass-conformance-c17d.ps1'
    if (-not (Test-Path -LiteralPath $familyGate -PathType Leaf)) {
      throw 'C17 family conformance gate is missing.'
    }
    & $familyGate -RepositoryRoot $root
  }
  if ($RequireOppoQualified -and
      ([string]$contract.resolution.state -cne 'implemented_host_and_oppo_qualified' -or
       [string]$contract.resolution.oppoQualification -cne 'passed')) {
    throw 'C17 checksum-matched OPPO one-handed qualification is not passed.'
  }
  Write-Output "Sub-action placement regression contract passed: successor=C17; implementedRequired=$RequireImplemented; oppoRequired=$RequireOppoQualified; rail=52px; target=48px; transparent=true; founderDecision=$($contract.founderDecision.state)."
  return
}

if ([int]$contract.rules.maximumFamilyRailHeight -ne 44 -or
    [int]$contract.rules.minimumTapTarget -ne 44 -or
    [bool]$contract.rules.translucentLowShadowSurfaceRequired -or
    -not [bool]$contract.rules.fullyTransparentFamilySurfaceRequired -or
    [double]$contract.rules.maximumSurfaceOpacity -ne 0 -or
    [bool]$contract.rules.raisedCardShadowAllowed -or
    [bool]$contract.rules.separateFamilyTileAllowed -or
    [bool]$contract.rules.perActionBoxBorderAllowed -or
    [bool]$contract.rules.filledSelectedPillAllowed -or
    -not [bool]$contract.rules.thinFamilyConnectorRequired -or
    [bool]$contract.rules.destinationFamilyMarkerRequired -or
    -not [bool]$contract.rules.destinationFamilyAccentRequired -or
    -not [bool]$contract.rules.animatedGradientWaveConnectionRequired -or
    -not [bool]$contract.rules.waveLinksSelectedMainToSelectedSubaction -or
    [int]$contract.rules.waveSelectionMotionMillisecondsMinimum -ne 180 -or
    [int]$contract.rules.waveSelectionMotionMillisecondsMaximum -ne 220 -or
    [bool]$contract.rules.wavePerpetualMotionAllowed -or
    -not [bool]$contract.rules.waveReducedMotionSettlesImmediately -or
    [bool]$contract.rules.waveMayOwnHitTestingOrSemantics -or
    [bool]$contract.rules.sideToSideFamilyPanelAllowed -or
    -not [bool]$contract.rules.destinationContentMustRemainVisibleBehindLayer -or
    -not [bool]$contract.rules.directDefaultLandingRequired -or
    [bool]$contract.rules.legacyProductionChooserAllowed) {
  throw 'C15 transparent gradient-wave family geometry, motion, direct-landing or ownership rules have been weakened.'
}
$professional = $contract.professionalDesignSystem
if ([string]$professional.nativeFlutterSharedOwner -cne 'MoolLocalNavigationRail' -or
    [string]$professional.tokenOwner -cne 'MoolLocalNavigationTokens' -or
    (@($professional.familyIds) -join ',') -cne 'social,buy,eat,ride,book,work' -or
    [double]$professional.commonIconSize -ne 16 -or
    [double]$professional.commonLabelFontSize -ne 10.5 -or
    [double]$professional.commonGap -ne 4 -or
    [double]$professional.selectedIndicatorWidth -ne 20 -or
    [double]$professional.selectedIndicatorHeight -ne 2 -or
    [double]$professional.compactClusterWidthsAt320.twoActions -ne 180 -or
    [double]$professional.compactClusterWidthsAt320.threeActions -ne 248 -or
    [double]$professional.compactClusterWidthsAt320.fourActions -ne 304 -or
    [bool]$professional.horizontalScrollOrPanelAllowed -or
    [bool]$professional.distributedSparseCellsAllowed -or
    [double]$professional.minimumTapTarget -ne 44 -or
    -not [bool]$professional.selectedActionIsInert -or
    -not [bool]$professional.availableActionSemanticTapRequired -or
    -not [bool]$professional.providerAssetSupportRequired) {
  throw 'C16 professional adaptive shared-owner contract has been weakened.'
}
$expectedSourceOwners = @(
  'buyHeaderTabs',
  'socialTopContextTabs',
  'eatFirstContentRail',
  'rideFirstContentRail',
  'bookFirstContentRail',
  'workFirstContentRail'
)
$actualSourceOwners = @($contract.currentSourceDisposition.PSObject.Properties.Name)
if ($actualSourceOwners.Count -ne $expectedSourceOwners.Count -or
    ($actualSourceOwners -join ',') -cne ($expectedSourceOwners -join ',')) {
  throw 'Sub-action top-placement source-owner inventory is incomplete.'
}

if ($RequireOppoQualified) { $RequireImplemented = $true }

if ($RequireImplemented) {
  $blockers = [Collections.Generic.List[string]]::new()
  if ([string]$contract.founderDecision.state -cne 'approved') {
    $blockers.Add('founder placement decision is pending')
  }
  if ([string]$contract.resolution.state -cnotin @(
      'c16a_through_c16g_host_qualified_two_complete_cycles_pending',
      'c16_host_qualified_build_pending',
      'implemented_host_and_oppo_qualified'
    )) {
    $blockers.Add('reachable sub-action placement is not implemented')
  }
  foreach ($owner in $expectedSourceOwners) {
    if ([string]$contract.currentSourceDisposition.$owner -cne
        'implemented_c16_shared_adaptive_professional_owner') {
      $blockers.Add("$owner is not registered in the C16 shared adaptive professional owner")
    }
  }

  $buy = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart')
  $social = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\social\social_v2_consumer.dart')
  $shared = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart')
  $designSystem = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart')
  $socialComponents = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart')
  $router = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart')
  if (-not $shared.Contains('class MoolDestinationNavigationV2') -or
      -not $shared.Contains('moolDestinationFamilyRailHeight = 44') -or
      -not $shared.Contains('moolDestinationFamilyRailSurfaceOpacity = 0') -or
      -not $shared.Contains('moolDestinationFamilyWaveDuration = Duration(milliseconds: 200)') -or
      -not $shared.Contains('class MoolDestinationFamilyWavePainter') -or
      -not $shared.Contains('moolsocial-${widget.activeId}-family-wave-link') -or
      -not $shared.Contains('selectedLocalIndex') -or
      -not $shared.Contains('localActionCount') -or
      -not $shared.Contains('MoolLocalNavigationTokens.selectedCenterX(') -or
      -not $shared.Contains('selectedMainActionAnchorKey') -or
      -not $shared.Contains('IgnorePointer(') -or
      -not $shared.Contains('ExcludeSemantics(') -or
      -not $shared.Contains('CustomPaint(') -or
      -not $shared.Contains('AlwaysStoppedAnimation<double>(1)') -or
      -not $shared.Contains('strokeWidth = 10') -or
      -not $shared.Contains('strokeWidth = 1.5') -or
      $shared.Contains('moolsocial-$activeId-subaction-family-marker') -or
      $shared.Contains('moolDestinationFamilyRailSurfaceOpacity = .36') -or
      $shared.Contains('width: 38') -or
      $shared -notmatch 'MoolDestinationNavigationV2[\s\S]{0,8000}MoolGlobalNavigationV2\(') {
    $blockers.Add('shared transparent family layer does not preserve its exact 44px envelope, measured finite gradient connection and final global owner')
  }
  foreach ($token in @(
    'abstract final class MoolLocalNavigationTokens',
    'static const double iconSize = 16',
    'static const double labelFontSize = 10.5',
    'static const double itemGap = MoolSpacing.xxs',
    'static const double selectedIndicatorWidth = 20',
    'static const double selectedIndicatorHeight = 2',
    'static Color familyAccent(String familyId)',
    "'social' => const Color",
    "'buy' => const Color",
    "'eat' => const Color",
    "'ride' => const Color",
    "'book' => const Color",
    "'work' => const Color",
    'static double clusterWidth(double maxWidth, int actionCount)',
    'static double selectedCenterX({',
    "key: const Key('moolsocial-local-navigation-adaptive-layout')",
    "key: const Key('moolsocial-local-navigation-compact-cluster')",
    'final accent = MoolLocalNavigationTokens.familyAccent(familyId)',
    'onTap: action.onPressed',
    'minWidth: MoolMetrics.minimumTapTarget',
    'minHeight: MoolMetrics.minimumTapTarget',
    'MoolLocalNavigationTokens.selectedIndicatorWidth',
    'MoolLocalNavigationTokens.selectedIndicatorHeight',
    'MoolMotion.accessible(context, MoolMotion.quick)',
    'GlobalKey? anchorKey'
  )) {
    if (-not $designSystem.Contains($token)) {
      $blockers.Add("shared C16 adaptive design-system token is missing: $token")
    }
  }
  $railStart = $designSystem.IndexOf('class MoolLocalNavigationRail extends StatelessWidget')
  $railEnd = $designSystem.IndexOf('class _MoolLocalNavigationCell extends StatelessWidget', $railStart)
  if ($railStart -lt 0 -or $railEnd -le $railStart) {
    $blockers.Add('shared C16 local-navigation owner bounds are invalid')
  } else {
    $railBlock = $designSystem.Substring($railStart, $railEnd - $railStart)
    foreach ($forbidden in @('SingleChildScrollView(', 'ScrollController(', 'Expanded(', 'distributeEvenly')) {
      if ($railBlock.Contains($forbidden)) {
        $blockers.Add("shared C16 local-navigation owner retains forbidden lane/distribution state: $forbidden")
      }
    }
    foreach ($required in @('LayoutBuilder(', 'return Center(', 'width: clusterWidth', 'width: cellWidth')) {
      if (-not $railBlock.Contains($required)) {
        $blockers.Add("shared C16 local-navigation owner is not compact/adaptive: $required")
      }
    }
  }
  if ($socialComponents -notmatch 'class Screen04ContextTabs[\s\S]{0,1800}MoolLocalNavigationRail\([\s\S]{0,300}familyId:\s*''social''[\s\S]{0,1000}for \(final item in world\.choices\)' -or
      $socialComponents -notmatch 'class Screen04ContextTabs[\s\S]{0,1800}iconAsset:\s*item\.attributionAsset' -or
      $socialComponents -match 'class _RailAction' -or
      $socialComponents -match 'class _TrackingRailRibbon') {
    $blockers.Add('Social actions are not mapped to the shared C16 adaptive owner with provider assets preserved')
  }
  if ($buy.Contains('Expanded(child: _BuyDestinationTabs(session: session))')) {
    $blockers.Add('Buy sub-actions remain inside the top header')
  }
  if ($buy -notmatch "Scaffold\([\s\S]{0,200}key:\s*const ValueKey\('buy-v2-screen'\),[\s\S]{0,100}extendBody:\s*true" -or
      $buy -notmatch 'body:\s*DecoratedBox\([\s\S]{0,300}LinearGradient\([\s\S]{0,300}surfaceTheme\.canvasGradient\.colors[\s\S]{0,300}child:\s*SafeArea\([\s\S]{0,80}bottom:\s*true' -or
      $buy -notmatch "bottomNavigationBar:\s*MoolDestinationNavigationV2\([\s\S]{0,500}localNavigation:\s*_buildBuyLocalNavigation\(session\)" -or
      $buy -notmatch "bottomNavigationBar:\s*MoolDestinationNavigationV2\([\s\S]{0,500}selectedLocalIndex:[\s\S]{0,500}localActionCount:\s*4" -or
      $buy -match "id:\s*'help',[\s\S]{0,180}label:\s*'Help'" -or
      $buy -notmatch "Widget _buildBuyLocalNavigation\(BuyV2Session session\)[\s\S]{0,300}MoolLocalNavigationRail\([\s\S]{0,200}familyId:\s*'buy'" -or
      $buy -notmatch "Widget _buildBuyLocalNavigation\(BuyV2Session session\)[\s\S]{0,2500}buy-local-tab-shop[\s\S]{0,2500}buy-local-tab-wholesale[\s\S]{0,2500}buy-local-tab-medicine[\s\S]{0,2500}buy-local-tab-orders" -or
      $buy -match 'class _BuyDestinationTabs' -or
      $buy -match 'class _BuyLocalRailCue' -or
      $buy.Contains('buy-local-destination-tabs-scroll') -or
      $buy.Contains('buy-local-destination-tabs-overflow-cue')) {
    $blockers.Add('Buy does not expose exactly four primary destinations through the shared C16 adaptive owner')
  }
  if ($social -match 'Screen04Header\([\s\S]{0,1800}Screen04ContextTabs\(') {
    $blockers.Add('Social sub-actions remain directly below the top header')
  }
  if ($social -notmatch "Scaffold\([\s\S]{0,200}key:\s*const Key\('screen04-universal-v2'\),[\s\S]{0,100}extendBody:\s*true" -or
      $social -notmatch 'body:\s*SafeArea\([\s\S]{0,80}bottom:\s*true' -or
      $social -notmatch 'bottomNavigationBar:\s*MoolDestinationNavigationV2\([\s\S]{0,500}selectedLocalIndex:[\s\S]{0,500}localActionCount:\s*world\.choices\.length[\s\S]{0,500}localNavigation:\s*Screen04ContextTabs\(') {
    $blockers.Add('Social context tabs are not indexed in the transparent family layer')
  }
  $defaultMainActionRoutes = [ordered]@{
    eat = '/app/eat/home'
    ride = '/app/ride/book?type=bike'
    book = '/app/book/doctor'
    work = '/app/work/earn'
  }
  foreach ($entry in $defaultMainActionRoutes.GetEnumerator()) {
    $actionPattern = "id:\s*'$([regex]::Escape([string]$entry.Key))',[\s\S]{0,100}route:\s*'$([regex]::Escape([string]$entry.Value))'"
    if ($shared -notmatch $actionPattern) {
      $blockers.Add("$($entry.Key) global action does not land on its default sub-action route")
    }
  }
  if ($shared -match "route:\s*'/app/(eat|ride|book|work)'," -or
      $router -notmatch "redirect:[\s\S]{0,500}personalMvpActionChoiceRoots\[section\][\s\S]{0,300}actions\.first\.route" -or
      $router -notmatch 'if \(legacyPresentationForTestsOnly && actionChoiceRoot != null\)' -or
      $router -match 'if \(!legacyPresentationForTestsOnly && actionChoiceRoot != null\)') {
    $blockers.Add('retired Eat, Ride, Book or Work choice roots remain reachable in the production main-action path')
  }
  foreach ($owner in @(
    @{ Name = 'Eat'; Path = 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'; Banner = 'EatMessageBanner' },
    @{ Name = 'Ride'; Path = 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'; Banner = 'RideMessageBanner' },
    @{ Name = 'Book'; Path = 'apps\mobile\lib\features\book\widgets\book_widgets.dart'; Banner = 'BookMessageBanner' },
    @{ Name = 'Work'; Path = 'apps\mobile\lib\features\work\widgets\work_widgets.dart'; Banner = 'WorkMessageBanner' }
  )) {
    $source = Get-Content -Raw -LiteralPath (Join-Path $root $owner.Path)
    $pattern = [regex]::Escape([string]$owner.Banner) + '\(session: session\),\s*MoolLocalNavigationRail\('
    if ($source -match $pattern) {
      $blockers.Add("$($owner.Name) sub-actions remain in the first top content row")
    }
    $familyId = $owner.Name.ToLowerInvariant()
    if ($source -notmatch 'Scaffold\([\s\S]{0,100}extendBody:\s*true' -or
        $source -notmatch 'body:\s*SafeArea\([\s\S]{0,80}top:\s*false,[\s\S]{0,80}bottom:\s*true' -or
        $source -notmatch "bottomNavigationBar:\s*MoolDestinationNavigationV2\([\s\S]{0,800}selectedLocalIndex:[\s\S]{0,500}localActionCount:[\s\S]{0,500}localNavigation:\s*MoolLocalNavigationRail\([\s\S]{0,300}familyId:\s*'$familyId'" -or
        $source.Contains('distributeEvenly:') -or
        $source.Contains('SingleChildScrollView(')) {
      $blockers.Add("$($owner.Name) sub-actions are not indexed in the shared compact adaptive family layer")
    }
  }
  if ($RequireOppoQualified -and
      ([string]$contract.resolution.state -cne 'implemented_host_and_oppo_qualified' -or
       [string]$contract.resolution.oppoQualification -cne 'passed')) {
    $blockers.Add('checksum-matched OPPO one-handed qualification is not passed')
  }
  if ($blockers.Count -gt 0) {
    throw ('Sub-action placement regression remains open: ' + ($blockers -join '; ') + '.')
  }
}

Write-Output "Sub-action placement regression contract passed: implementedRequired=$RequireImplemented; oppoRequired=$RequireOppoQualified; topPromotionZone=reserved; tapBudget=1; founderDecision=$($contract.founderDecision.state)."
