[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$expectedTicket = 'UAW-PERSONAL-MVP-ADAPTIVE-ACCESSIBILITY-REACHABILITY-GATES-FIX8-C25F'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-adaptive-accessibility-reachability-gates-fix8-c25f-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-domain-navigation-and-destination-rail-recovery-fix8-c25-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$contractPath = Join-Path $root 'config\mvp-personal-domain-navigation-projection-c25.json'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\mool_adaptive_accessibility_reachability_c25f_test.dart'
$socialSealPath = Join-Path $root 'artifacts\quality\social-protected-candidate-c25f-domain-navigation-20260809-01\BASELINE.json'
$buySealPath = Join-Path $root 'artifacts\quality\buy-protected-candidate-c25f-domain-navigation-20260809-01\BASELINE.json'

$requiredOwners = @(
  $ticketPath,
  $parentPath,
  $scopePath,
  $contractPath,
  $apkPath,
  $navigationPath,
  $designPath,
  $testPath,
  $socialSealPath,
  $buySealPath
)
foreach ($path in $requiredOwners) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C25F required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$socialSeal = Get-Content -Raw -LiteralPath $socialSealPath | ConvertFrom-Json
$buySeal = Get-Content -Raw -LiteralPath $buySealPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$expectedSuccessors = @(
  'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-HOST-QUALIFICATION-FIX8-C25G',
  'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-OPPO-QUALIFICATION-FIX8-C25H'
)
$completedChild = @($parent.children | Where-Object {
  [string]$_.ticketId -ceq $expectedTicket
})
$activeState = (
  [string]$ticket.state -ceq 'selected_runtime_test_gate_writes_authorized' -and
  [string]$parent.execution.currentChild -ceq $expectedTicket -and
  [string]$scope.ticket.id -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha -and
  [bool]$scope.execution.runtimeWriteAuthorized
)
$completedState = (
  [string]$ticket.state -ceq 'complete' -and
  $completedChild.Count -eq 1 -and
  [string]$completedChild[0].state -ceq 'complete' -and
  $expectedSuccessors -ccontains [string]$parent.execution.currentChild -and
  [string]$scope.ticket.id -ceq [string]$parent.execution.currentChild -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$parent.execution.currentChild -and
  -not [bool]$scope.execution.runtimeWriteAuthorized
)

if ([string]$ticket.ticketId -cne $expectedTicket -or
    -not ($activeState -or $completedState) -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or
    [bool]$ticket.execution.installAuthorized) {
  throw 'C25F active/completed ticket identity, manifest seal or closed backend/build/install/external authority is invalid.'
}

if ([int]$contract.presentation.minimumTapTarget -ne 44 -or
    [bool]$contract.presentation.horizontalActionScrollAllowed -or
    [bool]$contract.presentation.fullWidthOpaqueBottomStripeAllowed -or
    -not [bool]$contract.presentation.reducedMotionImmediate -or
    [int]$contract.presentation.destinationSubactionTapCount -ne 1 -or
    [int]$contract.presentation.maximumTapTargetOcclusion -ne 0) {
  throw 'C25F adaptive, direct-tap, no-scroll, no-occlusion or reduced-motion contract drifted.'
}

$expectedDomains = @(
  @{ id = 'social'; label = 'Social'; actions = 'Shorts,Videos,Feed,Create' },
  @{ id = 'buy'; label = 'Shop'; actions = 'Products,Wholesale,Orders' },
  @{ id = 'eat'; label = 'Food'; actions = 'Order Food,Book Table' },
  @{ id = 'ride'; label = 'Travel'; actions = 'Bike,Auto,Cab,Bus' },
  @{ id = 'book'; label = 'Care'; actions = 'Doctor,Medicine,Salon' },
  @{ id = 'work'; label = 'Work'; actions = 'Earn Today,Workspace' }
)
foreach ($expected in $expectedDomains) {
  $domain = @($contract.domains | Where-Object { [string]$_.id -ceq $expected.id })
  if ($domain.Count -ne 1 -or
      [string]$domain[0].label -cne $expected.label -or
      (@($domain[0].actions | ForEach-Object { [string]$_.label }) -join ',') -cne $expected.actions) {
    throw "C25F domain/action projection drifted: $($expected.id)"
  }
}

$navigation = Get-Content -Raw -LiteralPath $navigationPath
$design = Get-Content -Raw -LiteralPath $designPath
$test = Get-Content -Raw -LiteralPath $testPath
foreach ($required in @(
  'class MoolMainDomainMenu',
  'class MoolDestinationNavigationV2',
  'class MoolGlobalChatShortcut',
  "key: const Key('moolsocial-compact-destination-rail')",
  "key: const Key('mool-compact-launcher')",
  "label: 'Open Chat'",
  'height: 60',
  'accessibility.disableAnimations || accessibility.accessibleNavigation',
  'reduceRouteMotion ? Duration.zero : MoolMotion.standard'
)) {
  if (-not $navigation.Contains($required)) {
    throw "C25F shared navigation requirement is missing: $required"
  }
}
$motionMatch = [regex]::Match(
  $design,
  'static const Duration standard = Duration\(milliseconds:\s*(\d+)\);'
)
if (-not $motionMatch.Success) {
  throw 'C25F production motion standard literal is missing.'
}
$motionMilliseconds = [int]$motionMatch.Groups[1].Value
$motionMinimum = [int]$contract.presentation.finiteMotionMillisecondsMinimum
$motionMaximum = [int]$contract.presentation.finiteMotionMillisecondsMaximum
if ($motionMinimum -ne 180 -or
    $motionMaximum -ne 320 -or
    $motionMilliseconds -lt $motionMinimum -or
    $motionMilliseconds -gt $motionMaximum) {
  throw (
    "C25F runtime motion $motionMilliseconds ms is outside the declared " +
    "$motionMinimum-$motionMaximum ms production interval."
  )
}
if ($navigation -match 'SingleChildScrollView|ListView\(|PageView\(|scrollDirection:\s*Axis\.horizontal') {
  throw 'C25F shared main/local navigation contains a forbidden scroll owner.'
}
foreach ($required in @(
  'static const double compactItemGap = 2',
  'static const double railHeight = 52',
  'static const Duration selectionDuration = Duration(milliseconds: 180)',
  'static const Color neutralGlassTop = Color(0xE8FFFFFF)'
)) {
  if (-not $design.Contains($required)) {
    throw "C25F shared design token is missing: $required"
  }
}

$familySources = @{
  social = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
  buy = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
  eat = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
  ride = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
  care = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
  work = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
}
foreach ($family in $familySources.Keys) {
  $source = Get-Content -Raw -LiteralPath $familySources[$family]
  if (-not $source.Contains("$family-global-chat")) {
    throw "C25F one-tap Chat owner is missing for family: $family"
  }
}

foreach ($required in @(
  'const [320.0, 390.0, 430.0]',
  'const [1.0, 1.4]',
  'greaterThanOrEqualTo(44)',
  'SemanticsAction.tap',
  "find.byType(Scrollable)",
  "Key('social-global-chat')",
  "Key('buy-global-chat')",
  "Key('eat-global-chat')",
  "Key('ride-global-chat')",
  "Key('care-global-chat')",
  "Key('work-global-chat')",
  "Key('chat-inbox-screen')",
  'handlePopRoute()'
)) {
  if (-not $test.Contains($required)) {
    throw "C25F focused adaptive/reachability assertion is missing: $required"
  }
}

if ([string]$socialSeal.state -cne 'FOUNDER_AUTHORIZED_SUCCESSOR_PENDING_OPPO_ACCEPTANCE' -or
    [int]$socialSeal.protectedRuntime.fileCount -ne 178 -or
    [string]$socialSeal.protectedRuntime.portableTreeSha256 -cne '9d79db1aa83d52d26e5f4a494315a7c213a504da6cba231346772aadac9af4e5' -or
    [string]$buySeal.state -cne 'FOUNDER_AUTHORIZED_SUCCESSOR_PENDING_OPPO_ACCEPTANCE' -or
    [int]$buySeal.protectedRuntime.fileCount -ne 43 -or
    [string]$buySeal.protectedRuntime.portableTreeSha256 -cne '37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7') {
  throw 'C25F protected Social or Buy successor seal is invalid.'
}

if ([string]$apk.machineState -cne 'c24i_r60_23_device_gate_rejected_eat_selected_chat_unreachable_installed_checksum_preserved_authorities_closed' -or
    [string]$apk.installResult.installedVersionName -cne '1.0.0-r60.23' -or
    [string]$apk.installResult.installedVersionCode -cne '2026080923' -or
    [string]$apk.installResult.installedBaseSha256 -cne '178584AB6993D576EAEBCB9BE0494A5CAD83119FE9888C37D969BBD9162BBA8D' -or
    [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C25F refuses changed rejected r60.23 identity or open successor build/install authority.'
}

& (Join-Path $root 'scripts\check-personal-domain-navigation-contract-c25a.ps1') -RepositoryRoot $root | Out-Null
& (Join-Path $root 'scripts\check-social-protected-baseline.ps1') -RepositoryRoot $root | Out-Null
& (Join-Path $root 'scripts\check-buy-protected-baseline.ps1') -RepositoryRoot $root | Out-Null

Write-Output 'C25F adaptive/reachability gate passed: widths=320,390,430; textScale=1.0,1.4; targets>=44; menu=main-only; localCounts=4,3,2,4,3,2; horizontalScroll=0; Chat=oneTapSixFamilies; reducedMotion=immediate; SocialSeal=178; BuySeal=43; r60.23Preserved=true; buildInstall=closed.'
