param(
  [ValidateSet("App", "Website", "All")]
  [string]$Surface = "App",
  [string]$ScreenbookRoot = "",
  [switch]$RequireScreenbook
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$contractPath = Join-Path $root "config\brand-integrity.json"

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    throw "Brand integrity gate failed: $Message"
  }
}

function Assert-Contains {
  param(
    [string]$Text,
    [string]$Expected,
    [string]$Message
  )

  Assert-True -Condition $Text.Contains($Expected) -Message $Message
}

Assert-True -Condition (Test-Path -LiteralPath $contractPath) `
  -Message "machine-readable contract is missing: $contractPath"

$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
Assert-True -Condition ($contract.schemaVersion -eq 20) `
  -Message "unsupported brand contract schema"
Assert-True -Condition ($contract.wordmark -ceq "MoolSocial") `
  -Message "wordmark must be exactly MoolSocial"
Assert-True -Condition ($contract.colours.navy -ceq "#000080") `
  -Message "navy must be #000080"
Assert-True -Condition ($contract.colours.saffron -ceq "#FF9933") `
  -Message "saffron must be #FF9933"
Assert-True -Condition ($contract.colours.white -ceq "#FFFFFF") `
  -Message "white must be #FFFFFF"
Assert-True -Condition ($contract.colours.green -ceq "#138808") `
  -Message "green must be #138808"
Assert-True -Condition (
  @($contract.colours.PSObject.Properties.Name).Count -eq 4
) -Message "logo palette must contain only navy plus saffron, white and green"
Assert-True -Condition (($contract.identityLineOrder -join ",") -ceq "saffron,white,green") `
  -Message "identity-line order must be saffron, white, green"
Assert-True -Condition ($contract.moolNavigation.flutterGlyph -ceq "Icons.grid_view_rounded") `
  -Message "Flutter Mool glyph must be Icons.grid_view_rounded"
Assert-True -Condition ($contract.wordmarkMotion.permanentOutcome -ceq "MoolSocial") `
  -Message "permanent brand-motion outcome must be the full MoolSocial wordmark"
Assert-True -Condition (($contract.wordmarkMotion.sequence -join ",") -ceq "MoolSocial,identity-line,settled-wordmark") `
  -Message "brand motion sequence must settle to the full MoolSocial wordmark"
Assert-True -Condition ($contract.wordmarkMotion.reducedMotionResult -ceq "static-MoolSocial") `
  -Message "reduced motion must resolve to the static full MoolSocial wordmark"
Assert-True -Condition ($contract.wordmarkMotion.durationMilliseconds -eq 1200) `
  -Message "shared wordmark motion duration must remain 1200 ms"
Assert-True -Condition (-not $contract.wordmarkMotion.loops) `
  -Message "brand motion must be finite and non-looping"
Assert-True -Condition (($contract.launchBrandReveal.sequence -join ",") -ceq "MoolSocial,India Ka Socio Commerce App,business-promise,unified-lockup") `
  -Message "launch brand reveal must remain progressive"
Assert-True -Condition ($contract.launchBrandReveal.durationMilliseconds -eq 2400) `
  -Message "launch brand reveal duration must remain 2400 ms"
Assert-True -Condition ($contract.launchBrandReveal.presentationGateMilliseconds -eq 3000) `
  -Message "launch reveal must stay inside the existing 3000 ms gate"
Assert-True -Condition ($contract.launchBrandReveal.identityLineCount -eq 1) `
  -Message "launch lockup must contain exactly one identity line"
Assert-True -Condition ($contract.launchBrandReveal.tagline -ceq "India Ka Socio Commerce App") `
  -Message "launch tagline changed"
Assert-True -Condition (($contract.launchBrandReveal.businessCopy -join "|") -ceq "Create. Connect. Work. Grow.|One app for life and business.") `
  -Message "launch business copy changed"
Assert-True -Condition ($contract.launchBrandReveal.taglinePresentation -ceq "plain-text") `
  -Message "launch tagline must remain part of the unified plain-text lockup"
Assert-True -Condition (-not $contract.launchBrandReveal.loops) `
  -Message "launch brand reveal must be finite and non-looping"
Assert-True -Condition ($contract.launchBrandReveal.reducedMotionResult -ceq "static-complete-lockup") `
  -Message "launch reduced motion must show the complete static lockup"
Assert-True -Condition ($contract.sharedMotionPrimitives.owner -ceq "apps/mobile/lib/core/design/mool_motion_primitives.dart") `
  -Message "shared motion primitive owner changed"
Assert-True -Condition (($contract.sharedMotionPrimitives.gradientStops -join ",") -ceq "navy,saffron,white,green") `
  -Message "shared motion gradients must use only the four identity colours"
Assert-True -Condition ($contract.sharedMotionPrimitives.finite) `
  -Message "shared motion primitives must remain finite"
Assert-True -Condition ($contract.sharedMotionPrimitives.reducedMotionResult -ceq "zero-duration-final-state") `
  -Message "shared motion reduced-motion outcome changed"
Assert-True -Condition (@($contract.sharedMotionPrimitives.customerIntegrations).Count -eq 0) `
  -Message "DES-001 must not silently integrate shared motion into a customer surface"
Assert-True -Condition ($contract.buyThemeMotion.owner -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_design.dart") `
  -Message "Buy theme-motion owner changed"
Assert-True -Condition ($contract.buyThemeMotion.integration -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart") `
  -Message "Buy theme-motion integration changed"
Assert-True -Condition (-not $contract.buyThemeMotion.loops) `
  -Message "Buy theme motion must remain finite"
Assert-True -Condition ($contract.buyThemeMotion.reducedMotionResult -ceq "zero-duration-final-theme") `
  -Message "Buy theme reduced-motion result changed"
Assert-True -Condition ($contract.buyThemeMotion.headerDurationMilliseconds -eq 280) `
  -Message "Buy header theme duration changed"
Assert-True -Condition ($contract.buyThemeMotion.canvasDurationMilliseconds -eq 240) `
  -Message "Buy canvas theme duration changed"
Assert-True -Condition ($contract.buyThemeMotion.verticals.shop -ceq "navy-saffron") `
  -Message "Shop theme identity changed"
Assert-True -Condition ($contract.buyThemeMotion.verticals.wholesale -ceq "navy-green") `
  -Message "Wholesale theme identity changed"
Assert-True -Condition ($contract.buyThemeMotion.verticals.medicine -ceq "tricolour-navy") `
  -Message "Medicine theme identity changed"
Assert-True -Condition ($contract.buyThemeMotion.verticals.orders -ceq "navy") `
  -Message "Orders theme identity changed"
Assert-True -Condition ($contract.buyThemeMotion.downstream.cart -ceq "saffron") `
  -Message "Cart theme identity changed"
Assert-True -Condition ($contract.buyThemeMotion.downstream.tracking -ceq "green") `
  -Message "Tracking theme identity changed"
Assert-True -Condition (($contract.buyContextualGlassHeader.owners -join ",") -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart") `
  -Message "Buy contextual glass-header owners changed"
Assert-True -Condition (($contract.buyContextualGlassHeader.sequence -join ",") -ceq "Mool-kinetic-promotional-title-enters-scene,Social-masked-depth-reveal-overtakes-same-stage,five-context-visual-creative-stages-emerge-from-vanishing-room,camera-shifted-context-studio-walls-volumetric-light-reflections-and-near-occlusion,visible-promo-stage-reuses-existing-context-action,icon-only-owned-action-settles,finite-cinematic-context-settle") `
  -Message "Buy cinematic visual-creative sequence changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.permanentOutcome -ceq "scene-embedded-MoolSocial-promotion-with-full-semantics") `
  -Message "Buy scene-embedded identity semantic outcome changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.widthPixels -eq 104 -and $contract.buyContextualGlassHeader.heightPixels -eq 56) `
  -Message "Buy cinematic title-owner geometry changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.durationMilliseconds -eq 3600) `
  -Message "Buy cinematic promotional sequence duration changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.sceneDurationMilliseconds -eq 3600) `
  -Message "Buy contextual scene duration changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.copyDurationMilliseconds -eq 3600) `
  -Message "Buy contextual copy duration changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.identityLineCount -eq 0) `
  -Message "Buy single-slot identity cannot consume space with an identity line"
Assert-True -Condition ($contract.buyContextualGlassHeader.surface -ceq "borderless-scene-embedded-no-logo-tile") `
  -Message "Buy logo box is forbidden"
Assert-True -Condition ($contract.buyContextualGlassHeader.headerTreatment -ceq "camera-shifted-premium-glass-broadcast-studio-with-volumetric-reflective-depth") `
  -Message "Buy contextual glass treatment changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.colourComposition -ceq "four-colour-brand-structure-with-founder-authorized-rich-context-colour-inside-first-party-promo-aperture-only") `
  -Message "Buy promo colour exception escaped its founder-authorized aperture"
Assert-True -Condition (($contract.buyContextualGlassHeader.gradientStops.PSObject.Properties.Value -join ",") -ceq "navy-white-structure-with-retail-cyan-violet-promo-light,navy-white-structure-with-teal-gold-promo-light,navy-white-structure-with-aqua-ultraviolet-promo-light,navy-white-structure-with-electric-blue-magenta-violet-promo-light,source-vertical-over-navy,source-vertical-over-navy") `
  -Message "Buy contextual gradient mapping changed"
Assert-True -Condition (($contract.buyContextualGlassHeader.verticalMotionSignatures.PSObject.Properties.Value -join ",") -ceq "five-visual-shop-studio-creatives,five-visual-wholesale-studio-creatives,five-visual-medicine-studio-creatives,five-visual-orders-studio-creatives-no-progress") `
  -Message "Buy vertical header-motion signatures changed"
Assert-True -Condition (($contract.buyContextualGlassHeader.featureCopy.PSObject.Properties.Value -join ",") -ceq "Everyday shop|Plan the monthly basket,Wholesale supply|Flexible restocking,Everyday care|Prescription centre,Orders & delivery|Purchases") `
  -Message "Buy existing-owned semantic action copy changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.featureCopyPresentation -ceq "no-visible-header-feature-copy-semantic-actions-only" -and -not $contract.buyContextualGlassHeader.visibleFeatureCopy) `
  -Message "Buy visible header feature copy returned"
Assert-True -Condition ($contract.buyContextualGlassHeader.visualCreativeCapacity.total -eq 20 -and $contract.buyContextualGlassHeader.visualCreativeCapacity.perContext -eq 5 -and $contract.buyContextualGlassHeader.visualCreativeCapacity.presentation -ceq "five-finite-code-native-tappable-visual-stages-per-active-context" -and $contract.buyContextualGlassHeader.visualCreativeCapacity.tapResult -ceq "reuse-existing-truthful-context-action" -and -not $contract.buyContextualGlassHeader.visualCreativeCapacity.visiblePromoContainers -and $contract.buyContextualGlassHeader.visualCreativeCapacity.tapSurface -ceq "transparent-central-aperture-with-existing-icon-affordance" -and -not $contract.buyContextualGlassHeader.visualCreativeCapacity.remoteCampaignActivation) `
  -Message "Buy twenty-slot first-party visual creative boundary changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.promoColourException.scope -ceq "first-party-code-native-promo-aperture-and-its-cinematic-light-only" -and -not $contract.buyContextualGlassHeader.promoColourException.globalTokenRegistration -and -not $contract.buyContextualGlassHeader.promoColourException.brandIdentityAffected -and -not $contract.buyContextualGlassHeader.promoColourException.sharedControlsAffected -and -not $contract.buyContextualGlassHeader.promoColourException.semanticColoursAffected) `
  -Message "Buy rich promo colour exceeded the founder-authorized local scope"
Assert-True -Condition ($contract.buyContextualGlassHeader.headerActionPresentation -ceq "tappable-promo-aperture-plus-icon-affordance-with-shared-owned-action-no-visible-label-or-arrow") `
  -Message "Buy header action returned to visible copy or arrow"
Assert-True -Condition ($contract.buyContextualGlassHeader.operationalContextPresentation -ceq "location-standalone-when-search-closed-scanner-inside-empty-resting-search-yields-during-active-query-no-header-rail") `
  -Message "Buy location/scanner ownership changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.searchPresentation.activeControlHeightPixels -eq 70 -and $contract.buyContextualGlassHeader.searchPresentation.longQueryControlHeightPixels -eq 120 -and $contract.buyContextualGlassHeader.searchPresentation.longQueryBandHeightPixels -eq 132 -and $contract.buyContextualGlassHeader.searchPresentation.accessibilityLongQueryControlHeightPixels -eq 150 -and $contract.buyContextualGlassHeader.searchPresentation.accessibilityLongQueryBandHeightPixels -eq 162 -and $contract.buyContextualGlassHeader.searchPresentation.longQueryThresholdCharacters -eq 38 -and $contract.buyContextualGlassHeader.searchPresentation.activeMinimumWidthRatio -eq 0.9 -and $contract.buyContextualGlassHeader.searchPresentation.activeQueryMaxLines -eq 6) `
  -Message "Buy active Search geometry changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.searchPresentation.shell -ceq "borderless-transparent-no-shadow" -and $contract.buyContextualGlassHeader.searchPresentation.inputBorders -ceq "none-all-states") `
  -Message "Buy Search must remain borderless across resting and focused states"
Assert-True -Condition (-not $contract.buyContextualGlassHeader.searchPresentation.scannerDuringActiveQuery -and -not $contract.buyContextualGlassHeader.searchPresentation.scannerWithNonEmptyQuery) `
  -Message "Buy scanner must yield to active or non-empty query copy"
Assert-True -Condition ($contract.buyContextualGlassHeader.contrast.defaultForeground -ceq "white-over-navy-glass-veil") `
  -Message "Buy default header contrast contract changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.contrast.medicineForeground -ceq "white-over-navy-glass-veil") `
  -Message "Buy Medicine header contrast contract changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.contrast.profileOwner -ceq "navy-glass-white-outline") `
  -Message "Buy profile header contrast contract changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.timerInitiatedFiniteTurns -and -not $contract.buyContextualGlassHeader.continuousTicker) `
  -Message "Buy date-wheel must use timer-initiated finite turns without a continuous ticker"
Assert-True -Condition (@($contract.buyContextualGlassHeader.approvedVideoAssets).Count -eq 0) `
  -Message "Buy header media cannot activate without an approved first-party asset"
Assert-True -Condition ($contract.buyContextualGlassHeader.mediaFallback -ceq "native-finite-cinematic-multi-plane-context-world") `
  -Message "Buy header safe media fallback changed"
Assert-True -Condition ($contract.buyContextualGlassHeader.promotionalContent -ceq "twenty-code-native-tappable-visual-context-creatives-no-visible-copy-no-remote-campaign") `
  -Message "Buy header cannot invent remote promotion content or actions"
Assert-True -Condition ($contract.buyContextualGlassHeader.reducedMotionResult -ceq "static-complete-multi-depth-premium-studio-stacked-MoolSocial-tappable-final-promo-icon-affordance-location-control-no-header-rail") `
  -Message "Buy cinematic identity reduced-motion result changed"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.owner -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_design.dart") `
  -Message "Buy Saved/quantity/Cart motion owner changed"
Assert-True -Condition (($contract.buySavedQuantityCartMotion.integrations -join ",") -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart,apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart,apps/mobile/lib/ui_v2/buy/buy_v2_views.dart") `
  -Message "Buy Saved/quantity/Cart integration inventory changed"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.stateOwner -ceq "BuyV2Session") `
  -Message "Buy state motion must remain session-owned"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.valueDurationMilliseconds -eq 180) `
  -Message "Buy value-motion duration changed"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.acknowledgementDurationMilliseconds -eq 240) `
  -Message "Buy Cart acknowledgement duration changed"
Assert-True -Condition (-not $contract.buySavedQuantityCartMotion.loops) `
  -Message "Buy Saved/quantity/Cart motion must remain finite"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.semanticResult -ceq "current-value-only") `
  -Message "Buy value-motion semantic result changed"
Assert-True -Condition ($contract.buySavedQuantityCartMotion.reducedMotionResult -ceq "zero-duration-final-value") `
  -Message "Buy value-motion reduced-motion result changed"
Assert-True -Condition (($contract.buySavedQuantityCartMotion.values -join ",") -ceq "saved,quantity,mini-cart-message,mini-cart-total,cart-line-total,cart-summary,cart-payable-total") `
  -Message "Buy governed value-motion inventory changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.owner -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_views.dart") `
  -Message "Buy coupon/offer motion owner changed"
Assert-True -Condition (($contract.buyCouponOfferMotion.stateOwners -join ",") -ceq "BuyV2CartBenefitsAdapter,BuyV2Session") `
  -Message "Buy coupon/offer state owners changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.selectionDurationMilliseconds -eq 150) `
  -Message "Buy coupon/offer selection duration changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.stateDurationMilliseconds -eq 180) `
  -Message "Buy coupon/offer state duration changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.contentDurationMilliseconds -eq 240) `
  -Message "Buy coupon/offer content duration changed"
Assert-True -Condition (-not $contract.buyCouponOfferMotion.loops) `
  -Message "Buy coupon/offer motion must remain finite"
Assert-True -Condition ($contract.buyCouponOfferMotion.normalProductionResult -ceq "fail-closed") `
  -Message "Buy coupon/offer normal production boundary changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.reviewSeedBoundary -ceq "compile-time-device-review-only") `
  -Message "Buy coupon/offer review-seed boundary changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.semanticResult -ceq "current-state-only") `
  -Message "Buy coupon/offer semantic result changed"
Assert-True -Condition ($contract.buyCouponOfferMotion.reducedMotionResult -ceq "zero-duration-final-state") `
  -Message "Buy coupon/offer reduced-motion result changed"
Assert-True -Condition (($contract.buyCouponOfferMotion.values -join ",") -ceq "entry-summary,destination-selection,kind-selection,unavailable-state,benefit-action,benefit-status") `
  -Message "Buy governed coupon/offer motion inventory changed"
Assert-True -Condition ($contract.buyProductDepthMotion.owner -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_design.dart") `
  -Message "Buy product-depth motion owner changed"
Assert-True -Condition (($contract.buyProductDepthMotion.integrations -join ",") -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart,apps/mobile/lib/ui_v2/buy/buy_v2_views.dart") `
  -Message "Buy product-depth integration inventory changed"
Assert-True -Condition ($contract.buyProductDepthMotion.stateOwner -ceq "BuyV2Session") `
  -Message "Buy product-depth state owner changed"
Assert-True -Condition ($contract.buyProductDepthMotion.pressDurationMilliseconds -eq 110) `
  -Message "Buy product-depth press duration changed"
Assert-True -Condition ($contract.buyProductDepthMotion.contentDurationMilliseconds -eq 240) `
  -Message "Buy product-depth content duration changed"
Assert-True -Condition (-not $contract.buyProductDepthMotion.loops) `
  -Message "Buy product-depth motion must remain finite"
Assert-True -Condition (-not $contract.buyProductDepthMotion.transformHitTests) `
  -Message "Buy product-depth transforms must not move hit testing"
Assert-True -Condition ($contract.buyProductDepthMotion.semanticResult -ceq "current-product-only") `
  -Message "Buy product-depth semantic result changed"
Assert-True -Condition ($contract.buyProductDepthMotion.reducedMotionResult -ceq "zero-duration-static-current-product") `
  -Message "Buy product-depth reduced-motion result changed"
Assert-True -Condition (($contract.buyProductDepthMotion.motionPalette -join ",") -ceq "navy,saffron,white,green") `
  -Message "Buy product-depth motion palette changed"
Assert-True -Condition (($contract.buyProductDepthMotion.values -join ",") -ceq "featured-product-press,dense-product-press,selected-product-media,selected-product-title") `
  -Message "Buy governed product-depth motion inventory changed"
Assert-True -Condition ($contract.buyQueryResultMotion.owner -ceq "apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart") `
  -Message "Buy query-result motion owner changed"
Assert-True -Condition ($contract.buyQueryResultMotion.stateOwner -ceq "BuyV2Session") `
  -Message "Buy query-result state owner changed"
Assert-True -Condition ($contract.buyQueryResultMotion.contentDurationMilliseconds -eq 240) `
  -Message "Buy query-result content duration changed"
Assert-True -Condition (-not $contract.buyQueryResultMotion.loops) `
  -Message "Buy query-result motion must remain finite"
Assert-True -Condition ($contract.buyQueryResultMotion.semanticResult -ceq "current-query-results-only") `
  -Message "Buy query-result semantic outcome changed"
Assert-True -Condition ($contract.buyQueryResultMotion.focusResult -ceq "search-field-and-keyboard-preserved") `
  -Message "Buy query-result focus outcome changed"
Assert-True -Condition ($contract.buyQueryResultMotion.reducedMotionResult -ceq "zero-duration-current-results") `
  -Message "Buy query-result reduced-motion outcome changed"
Assert-True -Condition (($contract.buyQueryResultMotion.motionPalette -join ",") -ceq "navy,saffron,white,green") `
  -Message "Buy query-result motion palette changed"
Assert-True -Condition (($contract.buyQueryResultMotion.values -join ",") -ceq "ready-suggestions,matching-results,empty-results") `
  -Message "Buy governed query-result inventory changed"

$colourPath = Join-Path $root "apps\mobile\lib\core\design\mool_colors.dart"
$designPath = Join-Path $root "apps\mobile\lib\core\design\mool_design_system.dart"
$motionPath = Join-Path $root "apps\mobile\lib\core\design\moolsocial_brand_motion.dart"
$splashPath = Join-Path $root "apps\mobile\lib\ui_v2\screens\screen01_app_splash\app_splash_screen_v2.dart"
$primitivePath = Join-Path $root "apps\mobile\lib\core\design\mool_motion_primitives.dart"
$primitiveReviewPath = Join-Path $root "apps\mobile\lib\review\mool_motion_primitives_review_main.dart"
$buyThemePath = Join-Path $root "apps\mobile\lib\ui_v2\buy\buy_v2_design.dart"
$buyThemeIntegrationPath = Join-Path $root "apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart"
$buyStateCataloguePath = Join-Path $root "apps\mobile\lib\ui_v2\buy\buy_v2_catalogue.dart"
$buyStateViewsPath = Join-Path $root "apps\mobile\lib\ui_v2\buy\buy_v2_views.dart"
$chatPath = Join-Path $root "apps\mobile\lib\features\chat\screens\chat_inbox_screen.dart"
$socialRailPath = Join-Path $root "apps\mobile\lib\ui_v2\social\screen04_universal_components.dart"
$creatorRailPath = Join-Path $root "apps\mobile\lib\ui_v2\social\social_v2_creator.dart"

foreach ($path in @($colourPath, $designPath, $motionPath, $splashPath, $primitivePath, $primitiveReviewPath, $buyThemePath, $buyThemeIntegrationPath, $buyStateCataloguePath, $buyStateViewsPath, $chatPath, $socialRailPath, $creatorRailPath)) {
  Assert-True -Condition (Test-Path -LiteralPath $path) `
    -Message "required Flutter brand source is missing: $path"
}

$colourSource = Get-Content -LiteralPath $colourPath -Raw
Assert-Contains $colourSource "Color(0xFF000080)" "Flutter navy token changed"
Assert-Contains $colourSource "Color(0xFFFF9933)" "Flutter saffron token changed"
Assert-Contains $colourSource "Color(0xFF138808)" "Flutter green token changed"

$designSource = Get-Content -LiteralPath $designPath -Raw
Assert-Contains $designSource "static const String wordmark = 'MoolSocial';" `
  "Flutter canonical wordmark is missing"
Assert-Contains $designSource "static const String staticBrandOutcome = wordmark;" `
  "Flutter static brand outcome must remain the complete wordmark"
Assert-Contains $designSource "static const List<Color> identityPalette = <Color>[" `
  "Flutter four-colour identity palette is missing"
foreach ($token in @("identityNavy", "identitySaffron", "identityWhite", "identityGreen")) {
  Assert-Contains $designSource $token "Flutter identity palette is missing $token"
}
Assert-Contains $designSource "static const IconData moolLauncherIcon = Icons.grid_view_rounded;" `
  "Flutter canonical Mool launcher is missing"
Assert-Contains $designSource "MoolBrand.moolLauncherIcon" `
  "shared outcome dock does not render the canonical Mool launcher"

$motionSource = Get-Content -LiteralPath $motionPath -Raw
Assert-Contains $motionSource "static const duration = Duration(milliseconds: 1200);" `
  "Flutter brand choreography duration changed"
Assert-Contains $motionSource "'MoolSocial'" `
  "Flutter animated identity is missing the complete MoolSocial wordmark"
Assert-True -Condition (-not $motionSource.Contains("MoolSocialCompactMark")) `
  -Message "Flutter identity must not restore a single M or MS compact mark"
Assert-True -Condition (-not $motionSource.Contains("CustomPainter")) `
  -Message "Flutter identity must not restore a custom compact-mark painter"
Assert-Contains $motionSource "label: 'MoolSocial'" `
  "Flutter animated identity semantic label changed"
Assert-Contains $motionSource "media?.disableAnimations" `
  "Flutter brand motion does not honor reduced motion"
Assert-True -Condition (-not $motionSource.Contains(".repeat(")) `
  -Message "Flutter brand motion contains an infinite repeat"
$motionTokenNames = @(
  [regex]::Matches($motionSource, "MoolColors\.([A-Za-z0-9_]+)") |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)
$forbiddenMotionTokens = @(
  $motionTokenNames | Where-Object { $_ -notin @("navy", "orange", "success") }
)
Assert-True -Condition ($forbiddenMotionTokens.Count -eq 0) `
  -Message "Flutter brand motion uses a colour token outside navy/saffron/green: $($forbiddenMotionTokens -join ', ')"
$motionMaterialColours = @(
  [regex]::Matches($motionSource, "(?<!Mool)Colors\.([A-Za-z0-9_]+)") |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)
$forbiddenMaterialColours = @(
  $motionMaterialColours | Where-Object { $_ -ne "white" }
)
Assert-True -Condition ($forbiddenMaterialColours.Count -eq 0) `
  -Message "Flutter brand motion uses a Material colour outside white: $($forbiddenMaterialColours -join ', ')"
Assert-True -Condition (-not [regex]::IsMatch($motionSource, "Color\s*\(\s*0x")) `
  -Message "Flutter brand motion bypasses the approved palette with a direct colour literal"

$splashSource = Get-Content -LiteralPath $splashPath -Raw
foreach ($token in @(
  "class _ProgressiveBrandLockup",
  "'India Ka Socio Commerce App'",
  "'Create. Connect. Work. Grow.'",
  "'One app for life and business.'",
  "Duration(milliseconds: 2400)",
  "progressOverride: wordmarkProgress"
)) {
  Assert-Contains $splashSource $token "progressive launch lockup is missing $token"
}
Assert-True -Condition (-not $splashSource.Contains("class _MotionIdentityLine")) `
  -Message "rejected duplicate travelling identity line remains"
Assert-True -Condition (-not $splashSource.Contains("class _StaticIdentityLine")) `
  -Message "rejected duplicate static identity line remains"
Assert-True -Condition (-not $splashSource.Contains("class _MotionTagline")) `
  -Message "rejected separate tagline pill remains"
Assert-True -Condition (-not $splashSource.Contains("splash-v2-footer-line")) `
  -Message "rejected footer identity line remains"

$primitiveSource = Get-Content -LiteralPath $primitivePath -Raw
foreach ($token in @(
  "MoolBrand.identityNavy",
  "MoolBrand.identitySaffron",
  "MoolBrand.identityWhite",
  "MoolBrand.identityGreen"
)) {
  Assert-Contains $primitiveSource $token "shared motion gradients are missing $token"
}
Assert-Contains $primitiveSource "MoolMotion.accessible(context, duration)" `
  "shared motion primitives do not use the reduced-motion duration owner"
Assert-True -Condition (-not $primitiveSource.Contains(".repeat(")) `
  -Message "shared motion primitives contain an infinite repeat"
Assert-True -Condition (-not [regex]::IsMatch($primitiveSource, "Color\s*\(\s*0x")) `
  -Message "shared motion primitives bypass the approved palette with a direct colour literal"
$primitiveMaterialColours = @(
  [regex]::Matches($primitiveSource, "(?<!Mool)Colors\.([A-Za-z0-9_]+)") |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)
Assert-True -Condition ($primitiveMaterialColours.Count -eq 0) `
  -Message "shared motion primitives use a direct Material colour: $($primitiveMaterialColours -join ', ')"

$primitiveReviewSource = Get-Content -LiteralPath $primitiveReviewPath -Raw
Assert-Contains $primitiveReviewSource "Production continues through" `
  "shared motion review entrypoint lost its evidence-only boundary"
Assert-True -Condition (-not [regex]::IsMatch($primitiveReviewSource, "Color\s*\(\s*0x")) `
  -Message "shared motion review bypasses the approved palette with a direct colour literal"

$buyThemeSource = Get-Content -LiteralPath $buyThemePath -Raw
$themeStart = $buyThemeSource.IndexOf("class BuyV2ThemeSpec")
$themeEnd = $buyThemeSource.IndexOf("class BuyV2ThemeScope")
Assert-True -Condition ($themeStart -ge 0 -and $themeEnd -gt $themeStart) `
  -Message "Buy theme specification boundary is missing"
$buyThemeBlock = $buyThemeSource.Substring($themeStart, $themeEnd - $themeStart)
foreach ($mapping in @(
  "headerGradient: MoolBrandGradient.saffron",
  "headerGradient: MoolBrandGradient.green",
  "headerGradient: MoolBrandGradient.tricolour",
  "headerGradient: MoolBrandGradient.navy",
  "canvasGradient: MoolBrandGradient.saffron",
  "canvasGradient: MoolBrandGradient.green",
  "canvasGradient: MoolBrandGradient.navy",
  "canvasGradient: MoolBrandGradient.tricolour"
)) {
  Assert-Contains $buyThemeBlock $mapping "Buy theme mapping is missing $mapping"
}
$allowedBuyThemeRgb = @("000080", "FF9933", "FFFFFF", "138808")
foreach ($match in [regex]::Matches($buyThemeBlock, "Color\s*\(\s*0x([0-9A-Fa-f]{8})\s*\)")) {
  $rgb = $match.Groups[1].Value.Substring(2).ToUpperInvariant()
  Assert-True -Condition ($rgb -in $allowedBuyThemeRgb) `
    -Message "Buy theme specification uses an off-palette colour 0x$($match.Groups[1].Value)"
}
$buyThemeMaterialColours = @(
  [regex]::Matches($buyThemeBlock, "(?<![A-Za-z0-9_])Colors\.([A-Za-z0-9_]+)") |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)
$forbiddenBuyThemeMaterialColours = @(
  $buyThemeMaterialColours | Where-Object { $_ -ne "white" }
)
Assert-True -Condition ($forbiddenBuyThemeMaterialColours.Count -eq 0) `
  -Message "Buy theme specification uses a Material colour outside white: $($forbiddenBuyThemeMaterialColours -join ', ')"

function Test-BuyThemeIntegrationFacts {
  param([bool]$BranchAllowed, [bool]$OwnerBytesEqual, [bool]$StructureExact)
  return $BranchAllowed -and $OwnerBytesEqual -and $StructureExact
}

if (
  -not (Test-BuyThemeIntegrationFacts $true $true $true) -or
  (Test-BuyThemeIntegrationFacts $false $true $true) -or
  (Test-BuyThemeIntegrationFacts $true $false $true) -or
  (Test-BuyThemeIntegrationFacts $true $true $false)
) {
  throw 'Brand integrity sealed Buy theme fixture failed.'
}

function Test-SealedBuyThemeIntegration {
  param([Parameter(Mandatory = $true)][string]$Source)
  $branch = (& git -C $root branch --show-current).Trim()
  $branchAllowed = $LASTEXITCODE -eq 0 -and $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  $owner = 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
  & git -C $root diff --quiet $overlayCommit -- $owner
  $ownerBytesEqual = $LASTEXITCODE -eq 0
  $structureExact = (
    ([regex]::Matches($Source, 'MoolFiniteGradientTransition')).Count -eq 1 -and
    $Source.Contains("key: const ValueKey('buy-theme-canvas')") -and
    -not $Source.Contains("key: const ValueKey('buy-shared-header')") -and
    $Source.Contains("key: const ValueKey('buy-navigation-surface-owner')") -and
    $Source.Contains('duration: BuyV2Motion.routeChange')
  )
  return Test-BuyThemeIntegrationFacts `
    $branchAllowed $ownerBytesEqual $structureExact
}

$buyThemeIntegrationSource = Get-Content -LiteralPath $buyThemeIntegrationPath -Raw
$sealedBuyThemeIntegration = Test-SealedBuyThemeIntegration `
  $buyThemeIntegrationSource
if ($sealedBuyThemeIntegration) {
  Assert-True -Condition (
    ([regex]::Matches(
      $buyThemeIntegrationSource,
      'MoolFiniteGradientTransition'
    )).Count -eq 1
  ) -Message 'sealed Buy theme must retain one canvas transition'
} else {
  Assert-True -Condition (([regex]::Matches($buyThemeIntegrationSource, "MoolFiniteGradientTransition")).Count -eq 2) `
    -Message "Buy theme motion must have exactly one canvas and one header integration"
  Assert-Contains $buyThemeIntegrationSource "key: const ValueKey('buy-shared-header')" `
    "Buy header theme owner is missing"
  foreach ($token in @(
    "key: const ValueKey('buy-contextual-glass-header')",
    "width: 104",
    "height: 56",
    "label: 'MoolSocial'",
    "const Duration(milliseconds: 3600)",
    "final sceneRecession = _phase(.46, .66)",
    "_paintPromotionalTitle",
    "_paintContextCreativeReel"
  )) {
    Assert-Contains $buyThemeIntegrationSource $token "Buy cinematic glass header is missing $token"
  }
}
Assert-Contains $buyThemeIntegrationSource "key: const ValueKey('buy-theme-canvas')" `
  "Buy canvas theme owner is missing"
Assert-Contains $buyThemeIntegrationSource "duration: BuyV2Motion.contentChange" `
  "Buy canvas theme duration is not contract-owned"
Assert-Contains $buyThemeIntegrationSource "duration: BuyV2Motion.routeChange" `
  "Buy header theme duration is not contract-owned"
Assert-True -Condition (-not $buyThemeIntegrationSource.Contains("surfaceColor: Colors.white")) `
  -Message "rejected boxed Buy logo surface remains"
foreach ($token in @(
  "moolsocial-brand-single-slot-wordmark",
  "moolsocial-brand-single-slot-mool",
  "moolsocial-brand-single-slot-social",
  "moolsocial-brand-single-slot-full",
  "rotateX(phase * math.pi * .58 * direction)",
  "moolsocial-brand-single-slot-edge-light"
)) {
  Assert-Contains $motionSource $token "Buy single-slot identity is missing $token"
}
if (-not $sealedBuyThemeIntegration) {
  foreach ($token in @(
    "buy-header-signature-shop",
    "buy-header-signature-wholesale",
    "buy-header-signature-medicine",
    "buy-header-signature-orders",
    "buy-header-contrast-veil",
    "buy-header-navy-depth-stage",
    "buy-header-surface-copy-suppressed",
    "buy-header-visual-creative-reel",
    "_paintCinematicVolume",
    "_paintBroadcastLighting",
    "_paintPromotionalTitle",
    "_paintContextCreativeReel",
    "buy-header-promo-stage-action-",
    "visual promotion",
    "_paintForegroundOcclusion",
    "buy-change-location",
    "buy-open-scanner"
  )) {
    Assert-Contains $buyThemeIntegrationSource $token "Buy cinematic contextual header is missing $token"
  }
}
Assert-True -Condition (-not $buyThemeIntegrationSource.Contains("buy-header-operational-rail")) `
  -Message "removed Buy header operational rail returned"
if (-not $sealedBuyThemeIntegration) {
foreach ($token in @(
  "final longQueryBandHeight = accessibilityText ? 162.0 : 132.0",
  "final longQueryControlHeight = accessibilityText ? 150.0 : 120.0",
  "height: open ? (longQuery ? longQueryControlHeight : 70) : 44",
  "height: open ? (longQuery ? longQueryBandHeight : 82) : 56",
  "controller.text.trim().length > 38",
  "maxLines: 6",
  "showScanner && !open && controller.text.isEmpty"
)) {
  Assert-Contains $buyThemeIntegrationSource $token "Buy active Search contract is missing $token"
}
Assert-True -Condition (-not $buyThemeIntegrationSource.Contains(".repeat(")) `
  -Message "Buy theme integration contains an infinite repeat"
$sceneStart = $buyThemeIntegrationSource.IndexOf("class _HeaderScenePainter")
$sceneEnd = $buyThemeIntegrationSource.IndexOf("class _BuySearchBand", $sceneStart)
Assert-True -Condition ($sceneStart -ge 0 -and $sceneEnd -gt $sceneStart) `
  -Message "Buy contextual storyboard painter boundary is missing"
$sceneBlock = $buyThemeIntegrationSource.Substring($sceneStart, $sceneEnd - $sceneStart)
Assert-True -Condition (-not [regex]::IsMatch($sceneBlock, "BuyV2Colors\.(orange|green)\.withValues")) `
  -Message "Buy storyboard must not alpha-blend saffron or green over navy"
Assert-True -Condition (-not $buyThemeIntegrationSource.Contains("Text(`r`n                                resolvedAction.label")) `
  -Message "Buy header action returned to visible text"
Assert-True -Condition (-not $buyThemeIntegrationSource.Contains("Icons.arrow_forward_rounded")) `
  -Message "Buy header action arrow returned"
$allowedLocalPromoRgb = @(
  "00BFA5",
  "00D4FF",
  "42A5F5",
  "47D7FF",
  "7C4DFF",
  "9D7CFF",
  "E040FB",
  "FFCA28"
)
$localPromoRgb = @(
  [regex]::Matches($sceneBlock, "Color\s*\(\s*0x([0-9A-Fa-f]{8})\s*\)") |
    ForEach-Object { $_.Groups[1].Value.Substring(2).ToUpperInvariant() } |
    Sort-Object -Unique
)
Assert-True -Condition (($localPromoRgb -join ",") -ceq ($allowedLocalPromoRgb -join ",")) `
  -Message "Buy local promo palette changed or leaked outside its explicit allowlist: $($localPromoRgb -join ', ')"
}

Assert-Contains $buyThemeSource "class BuyV2FiniteValueTransition" `
  "Buy finite value-motion owner is missing"
Assert-Contains $buyThemeSource "class BuyV2FiniteVisualTransition" `
  "Buy finite visual-motion owner is missing"
Assert-Contains $buyThemeSource "class BuyV2FiniteIncomingTransition" `
  "Buy finite incoming-motion owner is missing"
Assert-Contains $buyThemeSource "class BuyV2FiniteDepthReveal" `
  "Buy finite product-depth reveal owner is missing"
Assert-Contains $buyThemeSource "semanticLabel: text" `
  "Buy value motion does not expose only the current value"
Assert-Contains $buyThemeSource "MoolFiniteStateTransition" `
  "Buy state motion no longer consumes the qualified shared primitive"

$buyStateCatalogueSource = Get-Content -LiteralPath $buyStateCataloguePath -Raw
$buyStateViewsSource = Get-Content -LiteralPath $buyStateViewsPath -Raw
foreach ($requiredOwner in @(
  "buy-saved-filter-icon-motion",
  "buy-save-visual-",
  "buy-grid-quantity-value-motion"
)) {
  Assert-Contains $buyStateCatalogueSource $requiredOwner `
    "Buy catalogue state-motion owner is missing $requiredOwner"
}
foreach ($requiredOwner in @(
  "buy-cart-header-value-motion",
  "buy-cart-payable-total-motion",
  "buy-product-quantity-value-motion",
  "buy-cart-scope-value-motion-",
  "buy-cart-line-total-motion-",
  "buy-cart-line-quantity-motion-"
)) {
  Assert-Contains $buyStateViewsSource $requiredOwner `
    "Buy Cart state-motion owner is missing $requiredOwner"
}
foreach ($requiredOwner in @(
  "buy-cart-summary",
  "buy-cart-acknowledgement",
  "buy-mini-cart-total-motion"
)) {
  Assert-Contains $buyThemeIntegrationSource $requiredOwner `
    "Buy mini-Cart state-motion owner is missing $requiredOwner"
}
foreach ($source in @(
  $buyStateCatalogueSource,
  $buyThemeIntegrationSource,
  $buyStateViewsSource
)) {
  Assert-True -Condition (-not $source.Contains(".repeat(")) `
    -Message "Buy Saved/quantity/Cart integration contains an infinite repeat"
}

foreach ($requiredOwner in @(
  "buy-cart-benefit-entry-",
  "buy-cart-benefit-empty-motion",
  "buy-cart-benefit-action-motion-",
  "buy-cart-benefit-status-motion-"
)) {
  Assert-Contains $buyStateViewsSource $requiredOwner `
    "Buy coupon/offer motion owner is missing $requiredOwner"
}
Assert-Contains $buyStateViewsSource "BuyV2FiniteIncomingTransition" `
  "Buy coupon/offer content does not use finite incoming motion"
Assert-Contains $buyStateViewsSource "BuyV2Motion.selection" `
  "Buy coupon/offer selection duration is not contract-owned"
Assert-True -Condition (-not $buyStateViewsSource.Contains(".repeat(")) `
  -Message "Buy coupon/offer integration contains an infinite repeat"

foreach ($requiredOwner in @(
  "buy-featured-depth-",
  "buy-product-depth-"
)) {
  Assert-Contains $buyStateCatalogueSource $requiredOwner `
    "Buy product-card spatial owner is missing $requiredOwner"
}
foreach ($requiredOwner in @(
  "buy-product-media-reveal-",
  "buy-product-title-reveal-"
)) {
  Assert-Contains $buyStateViewsSource $requiredOwner `
    "Buy selected-product reveal owner is missing $requiredOwner"
}
Assert-Contains $buyThemeSource "transformHitTests: false" `
  "Buy product-depth motion moves transformed hit testing"
foreach ($source in @($buyThemeSource, $buyStateCatalogueSource, $buyStateViewsSource)) {
  Assert-True -Condition (-not $source.Contains(".repeat(")) `
    -Message "Buy product-depth integration contains an infinite repeat"
}
Assert-Contains $buyStateCatalogueSource "key: const ValueKey('buy-search-results-surface')" `
  "Buy query-result motion owner is missing"
Assert-Contains $buyStateCatalogueSource "buy-query-results-" `
  "Buy query-result transition is not keyed by current destination/query"
Assert-Contains $buyStateCatalogueSource "BuyV2FiniteIncomingTransition" `
  "Buy query results do not use current-content-only finite motion"
Assert-True -Condition (-not $buyStateCatalogueSource.Contains("AnimatedSwitcher(`n      key: const ValueKey('buy-search-results-surface')")) `
  -Message "Buy query results retain an outgoing switcher copy"

$chatSource = Get-Content -LiteralPath $chatPath -Raw
function Test-SealedChatBrandProjection {
  param([Parameter(Mandatory = $true)][string]$Source)
  $branch = (& git -C $root branch --show-current).Trim()
  $branchAllowed = $LASTEXITCODE -eq 0 -and $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  $owner = 'apps/mobile/lib/features/chat/screens/chat_inbox_screen.dart'
  & git -C $root diff --quiet $overlayCommit -- $owner
  $ownerBytesEqual = $LASTEXITCODE -eq 0
  $structureExact = (
    $Source.Contains('return ChatPageScaffold(') -and
    $Source.Contains("title: 'MoolSocial Chat'") -and
    $Source.Contains('returnRoute: widget.returnRoute') -and
    $Source.Contains("tooltip: 'Add MoolSocial people'")
  )
  return Test-BuyThemeIntegrationFacts `
    $branchAllowed $ownerBytesEqual $structureExact
}

if (Test-SealedChatBrandProjection $chatSource) {
  Assert-Contains $chatSource "title: 'MoolSocial Chat'" `
    'sealed standalone Chat lost its MoolSocial identity'
} else {
  Assert-Contains $chatSource "icon: const Icon(MoolBrand.moolLauncherIcon)" `
    "Chat Mool entry does not use the canonical launcher"
}

function Test-SealedSocialBrandEntries {
  param(
    [Parameter(Mandatory = $true)][string]$SocialSource,
    [Parameter(Mandatory = $true)][string]$CreatorSource
  )
  $branch = (& git -C $root branch --show-current).Trim()
  $branchAllowed = $LASTEXITCODE -eq 0 -and $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  $ownerBytesEqual = $true
  foreach ($owner in @(
      'apps/mobile/lib/ui_v2/social/screen04_universal_components.dart',
      'apps/mobile/lib/ui_v2/social/social_v2_creator.dart'
    )) {
    & git -C $root diff --quiet $overlayCommit -- $owner
    if ($LASTEXITCODE -ne 0) { $ownerBytesEqual = $false; break }
  }
  $structureExact = (
    $SocialSource.Contains('child: MoolLocalNavigationRail(') -and
    $SocialSource.Contains("familyId: 'social'") -and
    $SocialSource.Contains('for (final item in world.choices)') -and
    $CreatorSource -match
      "(?s)label:\s*'Mool'.{0,160}icon:\s*Icons\.grid_view_rounded"
  )
  return Test-BuyThemeIntegrationFacts `
    $branchAllowed $ownerBytesEqual $structureExact
}

$socialRailSource = Get-Content -LiteralPath $socialRailPath -Raw
$creatorRailSource = Get-Content -LiteralPath $creatorRailPath -Raw
if (Test-SealedSocialBrandEntries $socialRailSource $creatorRailSource) {
  Assert-Contains $socialRailSource "familyId: 'social'" `
    'sealed Social local navigation lost its family identity'
} else {
  foreach ($path in @($socialRailPath, $creatorRailPath)) {
    $source = Get-Content -LiteralPath $path -Raw
    Assert-True -Condition (
      $source -match "(?s)label:\s*'Mool'.{0,160}icon:\s*Icons\.grid_view_rounded"
    ) -Message "protected Social Mool entry changed in $path"
  }
}

$flutterRoot = Join-Path $root "apps\mobile\lib"
$forbiddenMoolPattern = "(?s)label:\s*['`"]Mool['`"].{0,240}icon:\s*Icons\.(blur_circular_rounded|circle)\b"
foreach ($file in Get-ChildItem -LiteralPath $flutterRoot -Recurse -File -Filter "*.dart") {
  $source = Get-Content -LiteralPath $file.FullName -Raw
  Assert-True -Condition (-not [regex]::IsMatch($source, $forbiddenMoolPattern)) `
    -Message "placeholder Mool glyph remains in $($file.FullName)"
}

if ([string]::IsNullOrWhiteSpace($ScreenbookRoot)) {
  $ScreenbookRoot = Join-Path (Split-Path -Parent $root) "supermandi-uiux-screenbook"
}

if (Test-Path -LiteralPath $ScreenbookRoot) {
  $buyHtmlPath = Join-Path $ScreenbookRoot "screens\09-buy.html"
  $buyCssPath = Join-Path $ScreenbookRoot "shared\moolsocial-buy-v2.css"
  $foundationPath = Join-Path $ScreenbookRoot "shared\moolsocial-ui-foundation.css"
  $socialBatchPath = Join-Path $ScreenbookRoot "shared\moolsocial-social-batch.js"
  $socialCssPath = Join-Path $ScreenbookRoot "shared\moolsocial-social-batch.css"

  foreach ($path in @(
    $buyHtmlPath,
    $buyCssPath,
    $foundationPath,
    $socialBatchPath,
    $socialCssPath
  )) {
    Assert-True -Condition (Test-Path -LiteralPath $path) `
      -Message "required HTML brand source is missing: $path"
  }

  $foundation = Get-Content -LiteralPath $foundationPath -Raw
  Assert-Contains $foundation "--ms-navy: #000080;" "HTML navy token changed"
  Assert-Contains $foundation "--ms-saffron: #FF9933;" "HTML saffron token changed"
  Assert-Contains $foundation "--ms-white: #FFFFFF;" "HTML white token changed"
  Assert-Contains $foundation "--ms-green: #138808;" "HTML green token changed"

  $buyHtml = Get-Content -LiteralPath $buyHtmlPath -Raw
  Assert-Contains $buyHtml "<strong>MoolSocial</strong>" `
    "Buy wordmark is missing or changed"
  Assert-True -Condition (-not $buyHtml.Contains('class="brand-mark"')) `
    -Message "Buy still contains a module-specific brand mark"
  foreach ($cell in @(
    '<rect x="3" y="3" width="7" height="7" rx="1.5" />',
    '<rect x="14" y="3" width="7" height="7" rx="1.5" />',
    '<rect x="3" y="14" width="7" height="7" rx="1.5" />',
    '<rect x="14" y="14" width="7" height="7" rx="1.5" />'
  )) {
    Assert-Contains $buyHtml $cell "Buy Mool launcher is not the four-cell grid"
  }

  $buyCss = Get-Content -LiteralPath $buyCssPath -Raw
  Assert-True -Condition (-not $buyCss.Contains(".brand-mark")) `
    -Message "Buy CSS still supports the removed module-specific mark"
  Assert-True -Condition ($buyCss -match "(?i)--navy:\s*#000080;") `
    -Message "Buy navy token changed"
  Assert-True -Condition ($buyCss -match "(?i)--saffron:\s*#ff9933;") `
    -Message "Buy saffron token changed"
  Assert-True -Condition ($buyCss -match "(?i)--green:\s*#138808;") `
    -Message "Buy green token changed"

  $socialBatch = Get-Content -LiteralPath $socialBatchPath -Raw
  Assert-Contains $socialBatch "<strong>MoolSocial</strong>" `
    "Social wordmark is missing or changed"
  Assert-Contains $socialBatch '["Mool", "04-universal-focus-shell.html?openMool=1&world=social&rail=capability", "grid"]' `
    "Social navigation no longer uses the grid launcher"

  $socialCss = Get-Content -LiteralPath $socialCssPath -Raw
  Assert-True -Condition ($socialCss -match "(?i)--navy:\s*#000080;") `
    -Message "Social navy token changed"
  Assert-True -Condition ($socialCss -match "(?i)--saffron:\s*#ff9933;") `
    -Message "Social saffron token changed"
  Assert-True -Condition ($socialCss -match "(?i)--white:\s*#fff(?:fff)?;") `
    -Message "Social white token changed"
  Assert-True -Condition ($socialCss -match "(?i)--green:\s*#138808;") `
    -Message "Social green token changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(1) { background: var(--saffron); }" `
    "Social identity-line saffron position changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(2) { background: var(--white); }" `
    "Social identity-line white position changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(3) { background: var(--green); }" `
    "Social identity-line green position changed"

  foreach ($editableRoot in @(
    (Join-Path $ScreenbookRoot "screens"),
    (Join-Path $ScreenbookRoot "shared")
  )) {
    foreach ($file in Get-ChildItem -LiteralPath $editableRoot -Recurse -File |
      Where-Object { $_.Extension -in @(".html", ".css", ".js") }) {
      $source = Get-Content -LiteralPath $file.FullName -Raw
      foreach ($forbiddenMark in $contract.forbiddenAppMarks) {
        Assert-True -Condition (-not $source.Contains([string]$forbiddenMark)) `
          -Message "forbidden one-off M mark remains in $($file.FullName)"
      }
    }
  }
} elseif ($RequireScreenbook) {
  throw "Brand integrity gate failed: screenbook is required but unavailable: $ScreenbookRoot"
} else {
  Write-Output "Screenbook not present; repository-owned Flutter and contract checks completed."
}

if ($Surface -in @("Website", "All")) {
  Assert-True -Condition (
    $contract.surfaces.website.status -ne "pending-alignment" -and
    -not $contract.surfaces.website.blockNextWebsiteReleaseUntilAligned
  ) -Message "website alignment is founder-recorded as pending; the next website release is blocked"
}

Write-Output "Brand integrity gate passed for surface: $Surface"
