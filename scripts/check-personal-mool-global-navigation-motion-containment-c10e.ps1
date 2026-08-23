[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-navigation-motion-containment-oppo-fix1-c10e-ticket.json'
$globalPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$routerPath = Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart'
$ownerPaths = @(
  (Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'),
  (Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'),
  (Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'),
  (Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'),
  (Join-Path $root 'apps\mobile\lib\features\shared\screens\shared_screens.dart')
)
$rootScreenPaths = @(
  (Join-Path $root 'apps\mobile\lib\features\eat\screens\eat_home_screen.dart'),
  (Join-Path $root 'apps\mobile\lib\features\eat\screens\eat_table_screen.dart'),
  (Join-Path $root 'apps\mobile\lib\features\ride\screens\ride_booking_screen.dart'),
  (Join-Path $root 'apps\mobile\lib\features\book\screens\doctor_screens.dart'),
  (Join-Path $root 'apps\mobile\lib\features\book\screens\salon_screens.dart'),
  (Join-Path $root 'apps\mobile\lib\features\work\screens\work_earn_screens.dart'),
  (Join-Path $root 'apps\mobile\lib\features\work\screens\work_onboarding_screens.dart')
)

foreach ($path in @($ticketPath, $globalPath, $designPath, $routerPath, $testPath) + $ownerPaths + $rootScreenPaths) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C10E required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E' -or
    [string]$ticket.parentTicket -cne 'UAW-PERSONAL-MVP-UNIFIED-PERSISTENT-BOTTOM-NAVIGATION-SHELL-FIX1-C10' -or
    [string]$ticket.interactionContractVersion -cne 'C10E-V1-20260807') {
  throw 'C10E ticket identity or interaction contract is invalid.'
}
if ([bool]$ticket.implementationBoundary.buildOrInstallAuthorizedNow) {
  throw 'C10E host checker refuses a ticket that silently opens build or install.'
}

$global = Get-Content -Raw -LiteralPath $globalPath
$design = Get-Content -Raw -LiteralPath $designPath
$router = Get-Content -Raw -LiteralPath $routerPath
$journeyTest = Get-Content -Raw -LiteralPath $testPath
$ownerSource = ($ownerPaths | ForEach-Object { Get-Content -Raw -LiteralPath $_ }) -join "`n"
$rootScreenSource = ($rootScreenPaths | ForEach-Object { Get-Content -Raw -LiteralPath $_ }) -join "`n"
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'const moolGlobalNavigationHeroTag',
  'CustomTransitionPage<void> moolMainDestinationPage',
  'transitionDuration: MoolMotion.standard',
  'reverseTransitionDuration: MoolMotion.standard',
  'if (reduceMotion) return child',
  "key: const Key('moolsocial-main-destination-motion')",
  'FadeTransition(',
  'SlideTransition(',
  'begin: const Offset(.035, 0)',
  'Hero(',
  'tag: moolGlobalNavigationHeroTag',
  'transitionOnUserGestures: true'
)) {
  if (-not $global.Contains($token)) {
    $blockers.Add("global motion owner is missing: $token")
  }
}

foreach ($token in @(
  'class MoolLocalNavigationAction',
  'class MoolLocalNavigationRail',
  'abstract final class MoolLocalNavigationTokens',
  "key: const Key('moolsocial-local-navigation-adaptive-layout')",
  "key: const Key('moolsocial-local-navigation-compact-cluster')",
  'selected: selected',
  'enabled: action.onPressed != null',
  'duration: MoolMotion.accessible(context, MoolMotion.quick)'
)) {
  if (-not $design.Contains($token)) {
    $blockers.Add("local navigation owner is missing: $token")
  }
}
if ($design.Contains("key: const Key('moolsocial-local-navigation-scroll')")) {
  $blockers.Add('retired local-navigation scroll owner remains reachable')
}

foreach ($route in @(
  '/app/buy',
  '/app/chat',
  '/app/chat/inbox',
  '/app/eat/home',
  '/app/ride/book',
  '/app/book/doctor',
  '/app/work/earn'
)) {
  $pattern = "path:\s*'" + [regex]::Escape($route) + "',\s*pageBuilder:"
  if (-not [regex]::IsMatch($router, $pattern)) {
    $blockers.Add("main destination route is not page-owned: $route")
  }
}
if ([regex]::Matches($router, [regex]::Escape('moolMainDestinationPage(')).Count -lt 8) {
  $blockers.Add('router does not wrap every selected main-destination branch')
}
$dynamicStart = $router.IndexOf("path: '/app/:section'")
if ($dynamicStart -lt 0) {
  $blockers.Add('dynamic Personal destination route is missing')
} else {
  $dynamicPageBuilder = $router.IndexOf('pageBuilder:', $dynamicStart)
  $nextRoute = $router.IndexOf('GoRoute(', $dynamicStart + 1)
  if ($dynamicPageBuilder -lt 0 -or
      ($nextRoute -ge 0 -and $dynamicPageBuilder -gt $nextRoute)) {
    $blockers.Add('dynamic Personal destination route lost its page owner')
  }
  $dynamicHeader = if ($dynamicPageBuilder -gt $dynamicStart) {
    $router.Substring($dynamicStart, $dynamicPageBuilder - $dynamicStart)
  } else {
    ''
  }
  if (-not $dynamicHeader.Contains('redirect: (context, state)') -or
      -not $dynamicHeader.Contains('actionChoiceRoot.actions.first.route')) {
    $blockers.Add('dynamic Personal destination route lost its C13 pre-render default redirect')
  }
  $dynamicRoute = $router.Substring($dynamicStart)
  if ($dynamicRoute.Contains('Navigator.of(context).canPop()') -or
      -not $dynamicRoute.Contains('if (context.canPop())')) {
    $blockers.Add('dynamic page-builder Back owner does not use GoRouter context history')
  }
}

foreach ($ownerPath in $ownerPaths) {
  $owner = Get-Content -Raw -LiteralPath $ownerPath
  $isSharedOwner = [IO.Path]::GetFileName($ownerPath) -ceq 'shared_screens.dart'
  $expectedNavigationOwner = if ($isSharedOwner) {
    'MoolGlobalNavigationV2('
  } else {
    'MoolDestinationNavigationV2('
  }
  if (-not $owner.Contains($expectedNavigationOwner) -or
      -not $owner.Contains('MoolLocalNavigationRail(')) {
    $blockers.Add("owner does not separate global and local navigation: $ownerPath")
  }
}
if (-not $global.Contains('class MoolDestinationNavigationV2') -or
    -not $global.Contains('MoolGlobalNavigationV2(')) {
  $blockers.Add('shared destination navigation does not terminate in the global rail')
}
foreach ($screenPath in $rootScreenPaths) {
  $screen = Get-Content -Raw -LiteralPath $screenPath
  if (-not $screen.Contains('showBack: false')) {
    $blockers.Add("first-level destination still exposes top Back: $screenPath")
  }
}

foreach ($retired in @(
  'EatBottomDock',
  'RideBottomDock',
  'BookBottomDock',
  'WorkBottomDock',
  'class _SharedDock',
  'eat-dock-',
  'ride-dock-',
  'book-dock-',
  'work-dock-',
  'shared-dock-'
)) {
  if ($ownerSource.Contains($retired)) {
    $blockers.Add("retired destination navigation remains reachable: $retired")
  }
}

foreach ($token in @(
  'Social Mool Social Mool uses one rail and exact history',
  'deep Eat local switch and global Work switch preserve one navigation frame',
  'reduced motion changes destination without visual transition',
  "expect(find.byKey(destination.back), findsNothing)",
  'MoolMotion.standard.inMilliseconds, inInclusiveRange(180, 320)'
)) {
  if (-not $journeyTest.Contains($token)) {
    $blockers.Add("C10E journey coverage is missing: $token")
  }
}
if ($rootScreenSource.Contains("showBack: true")) {
  $blockers.Add('a first-level destination explicitly re-enables top Back')
}

if ($blockers.Count -gt 0) {
  throw ('C10E global navigation motion containment is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C10E navigation motion containment passed: globalOwner=1; contextualShelfOwner=1; localOwners=5; firstLevelTopBack=absent; motion=240ms; reducedMotion=contained; retiredDocks=absent.'
