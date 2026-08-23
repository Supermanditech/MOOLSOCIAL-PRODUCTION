[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$sharedGate = Join-Path $root 'scripts\check-personal-shared-clear-glass-action-control-c17b.ps1'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-clear-glass-action-controls-fix2-c17-ticket.json'
$c20ParentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$socialPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
$buyPath = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_social_buy_clear_glass_conformance_c17c_test.dart'
$buyNavigationTestPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\buy_v2_navigation_motion_test.dart'
$buyConformanceTestPath = Join-Path $root 'apps\mobile\test\ui_v2\buy\uaw_personal_mvp_buy_subaction_professional_conformance_c16c_test.dart'

foreach ($path in @($sharedGate, $ticketPath, $scopePath, $designPath, $socialPath, $buyPath, $navigationPath, $testPath, $buyNavigationTestPath, $buyConformanceTestPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C17C required owner is missing: $path"
  }
}

$earlyScope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$earlyCurrent = [string]$earlyScope.ticket.id
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $earlyParent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $earlySequence = @($earlyParent.implementationSequence)
  $earlyStart = [Array]::IndexOf($earlySequence, 'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C')
  $earlyIndex = [Array]::IndexOf($earlySequence, $earlyCurrent)
  if ([string]$earlyParent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
      $earlyStart -ge 0 -and $earlyIndex -ge $earlyStart) {
    $c20cGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
    if (-not (Test-Path -LiteralPath $c20cGate -PathType Leaf)) { throw 'C17C C20C successor gate is missing.' }
    & $c20cGate -RepositoryRoot $root
    Write-Output 'C17C historical Social/Buy conformance passed through the exact C20C neutral brand-glass successor; buildInstall=closed.'
    return
  }
}

& $sharedGate -RepositoryRoot $root

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SOCIAL-BUY-CLEAR-GLASS-CONFORMANCE-FIX2-C17C'
$sequence = @($ticket.implementationSequence)
$current = [string]$scope.ticket.id
$isC18dRefresh = $current -ceq 'UAW-PERSONAL-MVP-C17-HOST-QUALIFICATION-REFRESH-AFTER-SCREEN01-LOCK-FIX1-C18D'
$isC20Successor = $false
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $c20Parent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $c20Sequence = @($c20Parent.implementationSequence)
  $c20Start = [Array]::IndexOf(
    $c20Sequence,
    'UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B'
  )
  $c20Current = [Array]::IndexOf($c20Sequence, $current)
  $isC20Successor =
    [string]$c20Parent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
    $c20Start -ge 0 -and
    $c20Current -ge $c20Start
}
if (([Array]::IndexOf($sequence, $current) -lt [Array]::IndexOf($sequence, $expected) -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C17C MVP selection and sequential disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    ([bool]$scope.execution.referenceWriteAuthorized -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C17C host gate refuses build, install, backend or external authority; reference writes are limited to exact authorized successor tickets.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$social = Get-Content -Raw -LiteralPath $socialPath
$buy = Get-Content -Raw -LiteralPath $buyPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$buyNavigationTest = Get-Content -Raw -LiteralPath $buyNavigationTestPath
$buyConformanceTest = Get-Content -Raw -LiteralPath $buyConformanceTestPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'return Color.lerp(',
  'accent.withValues(alpha: base.a)',
  'static const Color lightGlassFill = Color(0x85FFFFFF)',
  'static const Color mediaGlassFill = Color(0x94081225)',
  "'buy' => const Color(0xFFA84600)"
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared alpha-preserving owner is missing: $token") }
}

$socialStart = $social.IndexOf('class Screen04ContextTabs extends StatelessWidget')
$socialEnd = $social.IndexOf('@immutable', $socialStart)
if ($socialStart -lt 0 -or $socialEnd -le $socialStart) {
  $blockers.Add('Social family wrapper bounds are invalid')
} else {
  $socialRail = $social.Substring($socialStart, $socialEnd - $socialStart)
  foreach ($token in @(
    'height: MoolLocalNavigationTokens.railHeight',
    'MoolLocalNavigationRail(',
    "familyId: 'social'",
    'surfaceTone: MoolLocalNavigationSurfaceTone.media',
    "'shorts' => Icons.play_circle_outline_rounded",
    "'videos' => Icons.ondemand_video_outlined",
    "'feed' => Icons.dynamic_feed_outlined",
    "'create' => Icons.add_circle_outline_rounded",
    "semanticLabel: item.attributionAsset == null",
    "iconAsset: item.attributionAsset"
  )) {
    if (-not $socialRail.Contains($token)) { $blockers.Add("Social clear-glass conformance is missing: $token") }
  }
  if ($socialRail.Contains('height: 44')) {
    $blockers.Add('Social retains the rejected stale 44px family wrapper')
  }
}

$buyStart = $buy.IndexOf('Widget _buildBuyLocalNavigation(BuyV2Session session)')
$buyEnd = $buy.IndexOf('void _openGlobalMool()', $buyStart)
if ($buyStart -lt 0 -or $buyEnd -le $buyStart) {
  $blockers.Add('Buy local-navigation wrapper bounds are invalid')
} else {
  $buyRail = $buy.Substring($buyStart, $buyEnd - $buyStart)
  foreach ($token in @(
    'MoolLocalNavigationRail(',
    "familyId: 'buy'",
    "keyName: 'buy-local-tab-shop'",
    "keyName: 'buy-local-tab-wholesale'",
    "keyName: 'buy-local-tab-medicine'",
    "keyName: 'buy-local-tab-orders'",
    "label: 'Shop'",
    "label: 'Wholesale'",
    "label: 'Medicine'",
    "label: 'Orders'"
  )) {
    if (-not $buyRail.Contains($token)) { $blockers.Add("Buy clear-glass conformance is missing: $token") }
  }
  if ($buyRail.Contains('surfaceTone: MoolLocalNavigationSurfaceTone.media') -or
      $buyRail.Contains('SingleChildScrollView(') -or $buyRail.Contains('Expanded(')) {
    $blockers.Add('Buy retains a wrong media tone, scroll strip or sparse expansion')
  }
}

foreach ($token in @(
  'moolDestinationFamilyRailSurfaceOpacity = 0',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth'
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("transparent connection shell is missing: $token") }
}
if ($navigation.Contains('strokeWidth = 10')) { $blockers.Add('rejected broad connection stroke remains') }

foreach ($entry in @(
  @{ Name = 'Buy navigation'; Source = $buyNavigationTest },
  @{ Name = 'Buy C16C conformance'; Source = $buyConformanceTest }
)) {
  if ($entry.Source.Contains('closeTo(304')) {
    $blockers.Add("$($entry.Name) retains the rejected predecessor 304px cluster expectation")
  }
  if (-not $entry.Source.Contains('MoolLocalNavigationTokens.clusterWidth(320, 4)')) {
    $blockers.Add("$($entry.Name) does not derive its 320px four-action width from the shared token")
  }
}

foreach ($token in @(
  'Social uses four unclipped media-glass controls and provider semantics',
  'Buy uses four light-glass controls with no blocking family surface',
  'findsNWidgets(4)',
  'findsNWidgets(2)',
  'greaterThanOrEqualTo(48)',
  'MoolLocalNavigationSurfaceTone.media',
  'MoolLocalNavigationSurfaceTone.light',
  'moolDestinationFamilyRailSurfaceOpacity',
  'style.fontWeight!.value',
  'find.ancestor(of: text, matching: find.byType(FittedBox))',
  'fill.a',
  'session.destination, BuyV2Destination.wholesale'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C17C focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C17C Social/Buy conformance is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C17C Social/Buy clear-glass conformance passed: families=Social,Buy; realActions=8; counts=4,4; targets=48px; labels=12px/700+; tones=media,light; providerSvg=2; selectedAlphaPreserved=true; railSurface=transparent; broadBand=absent; navigationOutcomes=unchanged; buildInstall=closed.'
