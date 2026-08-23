[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-mool-home-action-hub-regression-c23.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-home-hub-host-qualification-fix6-c23g-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$homePath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\personal_mool_root_v2.dart'
$routerPath = Join-Path $root 'apps\mobile\lib\features\journey01\journey_router.dart'
foreach ($path in @($contractPath, $ticketPath, $scopePath, $apkPath, $designPath, $navigationPath, $homePath, $routerPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C23G required owner is missing: $path" }
}

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-HOME-HUB-HOST-QUALIFICATION-FIX6-C23G'
if ([string]$ticket.ticketId -cne $expectedTicket -or
    [string]$scope.ticket.id -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expectedTicket -or
    [bool]$scope.execution.runtimeWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$contract.authority.runtimeMutationAuthorized -or
    [bool]$contract.authority.buildAuthorized -or
    [bool]$contract.authority.installAuthorized) {
  throw 'C23G selected ticket or closed runtime/build/install authority is invalid.'
}
if ([string]$contract.contractId -cne 'UAW-PERSONAL-MVP-MOOL-HOME-ACTION-HUB-REGRESSION-C23' -or
    [bool]$contract.destinationShell.persistentGlobalRailAllowed -or
    [bool]$contract.destinationShell.persistentSubactionRailAllowed -or
    [bool]$contract.destinationShell.fullWidthBottomSurfaceAllowed -or
    [bool]$contract.destinationShell.horizontalActionScrollingAllowed -or
    -not [bool]$contract.destinationShell.singleMoolHomeLauncherRequired -or
    [int]$contract.destinationShell.launcherMinimumTapSize -ne 56 -or
    [bool]$contract.destinationShell.chatPersistentBottomControlAllowed -or
    [bool]$contract.homeHub.familyExpansionTapAllowed -or
    [int]$contract.homeHub.mainDefaultTapCountFromHome -ne 1 -or
    [int]$contract.homeHub.subactionTapCountFromHome -ne 1 -or
    [int]$contract.homeHub.maximumTapCountFromDestination -ne 2 -or
    [int]$contract.homeHub.minimumTapSize -ne 44 -or
    -not [bool]$contract.homeHub.professionalNeutralSurfaceRequired -or
    -not [bool]$contract.homeHub.restrainedFamilyAccentRequired -or
    [bool]$contract.homeHub.largeBlockFamilyColourAllowed -or
    [bool]$contract.homeHub.fillerActionAllowed -or
    [int]$contract.motion.launcherPressMilliseconds -ne 100 -or
    [int]$contract.motion.hubArrivalMaximumMilliseconds -ne 220 -or
    -not [bool]$contract.motion.finiteOnly -or
    -not [bool]$contract.motion.reducedMotionImmediate) {
  throw 'C23G zero-rail, tap-budget, professional hierarchy or motion contract has drifted.'
}
$families = @($contract.families)
$actions = @($families | ForEach-Object { @($_.actions) })
if ($families.Count -ne 6 -or $actions.Count -ne 17 -or
    (@($families.id) -join ',') -cne 'social,buy,eat,ride,book,work') {
  throw 'C23G family or truthful action inventory has drifted.'
}
if (@($contract.requiredTests).Count -ne 13 -or [int]$contract.requiredGateCount -ne 10 -or
    [int]$contract.hostQualification.requiredConsecutiveCycles -ne 2 -or
    -not [bool]$contract.hostQualification.unchangedSourceFingerprintRequired -or
    -not [bool]$contract.hostQualification.completeAnalysisRequired -or
    -not [bool]$contract.hostQualification.completeRequiredSuiteRequired) {
  throw 'C23G host qualification inventory has drifted.'
}
foreach ($relative in @($contract.requiredTests)) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)) -PathType Leaf)) {
    throw "C23G required test is missing: $relative"
  }
}
if ([string]$apk.machineState -cne 'r60_21_founder_rejected_installed_checksum_identity_preserved_successor_build_install_closed' -or
    [string]$apk.buildAuthorization -cne 'consumed_no_second_build' -or
    [string]$apk.installResult.installedVersionName -cne '1.0.0-r60.21' -or
    [string]$apk.installResult.installedVersionCode -cne '2026080921' -or
    [string]$apk.installResult.installedBaseSha256 -cne '17AF5DC2353E7195A597555C88AA42B345AFFDA0EC160900B55B0D3E822691BE' -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C23G refuses changed r60.21 identity or open successor build/install authority.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$moolHomeSource = Get-Content -Raw -LiteralPath $homePath
$router = Get-Content -Raw -LiteralPath $routerPath
$globalStart = $navigation.IndexOf('class MoolGlobalNavigationV2 extends StatelessWidget')
if ($globalStart -lt 0) { throw 'C23G global navigation source boundary is missing.' }
$globalBlock = $navigation.Substring($globalStart)
foreach ($required in @(
  "if (activeId == 'mool' || onOpenMool == null)",
  "key: const Key('mool-home-launcher')",
  'child: _MoolHomeLauncher(onPressed: onOpenMool!)',
  "key: const Key('mool-home-launcher-press-motion')"
)) {
  if (-not $globalBlock.Contains($required)) { throw "C23G launcher owner is missing: $required" }
}
if (-not $navigation.Contains('key: ValueKey<String>(''moolsocial-main:${state.uri}'')')) {
  throw 'C23G shared main-destination page identity is not bound to the complete URI.'
}
foreach ($forbidden in @('MoolOutcomeDock(', 'MoolLocalNavigationRail(', 'SingleChildScrollView(')) {
  if ($globalBlock.Contains($forbidden)) { throw "C23G destination launcher retains a forbidden rail owner: $forbidden" }
}
if (-not $moolHomeSource.Contains("key: const Key('mool-home-chat')") -or
    -not $moolHomeSource.Contains('onOpenRoute: widget.onOpenRoute') -or
    -not $moolHomeSource.Contains('MoolHomeHubFamilyRow(') -or
    ([regex]::Matches($moolHomeSource, '(?m)^  _MoolHomeFamilySpec\(')).Count -ne 6 -or
    ([regex]::Matches($moolHomeSource, '(?m)^      _MoolHomeRouteAction\(')).Count -ne 17 -or
    -not $router.Contains('onOpenRoute: (route) {') -or
    -not $router.Contains('if (moolOrigin == null)') -or
    -not $router.Contains('context.push(route);') -or
    -not $router.Contains('context.pushReplacement(route);') -or
    -not $design.Contains('static const double mainActionHeight = 56') -or
    -not $design.Contains('static const double subactionHeight = MoolMetrics.minimumTapTarget') -or
    -not $design.Contains('static const Duration arrivalDuration = Duration(milliseconds: 220)') -or
    -not $design.Contains('static const Duration pressDuration = Duration(milliseconds: 100)')) {
  throw 'C23G Home hub, route matrix, accessibility or motion source owner is incomplete.'
}

Write-Output 'C23G aggregate gate passed: destinationRails=0; launcher=1x56; families=6; subactions=17; HomeTapBudget=1; destinationTapBudget=2; Chat=HomeHeader44; arrivalMs=220; pressMs=100; requiredTests=13; requiredGates=10; r60.21Preserved=true; runtimeBuildInstall=closed.'
