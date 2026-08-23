[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-clear-glass-action-controls-fix2-c17-ticket.json'
$c20ParentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_clear_glass_local_navigation_c17b_test.dart'
$familyOwners = @{
  social = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
  buy = Join-Path $root 'apps\mobile\lib\ui_v2\buy\buy_v2_screen.dart'
  eat = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
  ride = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
  book = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
  work = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
}

foreach ($path in @($ticketPath, $scopePath, $designPath, $navigationPath, $testPath) + $familyOwners.Values) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C17B required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SHARED-CLEAR-GLASS-ACTION-CONTROL-FIX2-C17B'
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-CLEAR-GLASS-ACTION-CONTROLS-FIX2-C17' -or
    [string]$ticket.founderApprovedDirection.id -cne 'CLEAR-GLASS-COMPACT-INDIVIDUAL-ACTION-CONTROLS' -or
    [string]$ticket.founderApprovedDirection.state -cne 'approved_20260808' -or
    -not @($ticket.implementationSequence).Contains($expected)) {
  throw 'C17B parent ticket, founder direction or implementation sequence is invalid.'
}
foreach ($family in @('social', 'buy', 'eat', 'ride', 'book', 'work')) {
  if (-not @($ticket.founderApprovedDirection.scope).Contains($family)) {
    throw "C17B founder-approved scope is missing family: $family"
  }
}

$sequence = @($ticket.implementationSequence)
$current = [string]$scope.ticket.id
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$currentIndex = [Array]::IndexOf($sequence, $current)
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
  $c20CStart = [Array]::IndexOf(
    $c20Sequence,
    'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C'
  )
  $isC20Successor =
    [string]$c20Parent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
    $c20Start -ge 0 -and
    $c20Current -ge $c20Start
  $isC20COrLater = $isC20Successor -and $c20CStart -ge 0 -and $c20Current -ge $c20CStart
}
if (($currentIndex -lt $expectedIndex -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C17B MVP selection and sequential disclosure gate is not active.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    ([bool]$scope.execution.referenceWriteAuthorized -and -not $isC18dRefresh -and -not $isC20Successor) -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C17B host gate refuses build, install, backend or external authority; reference writes are limited to exact authorized successor tickets.'
}
if ($isC20COrLater) {
  $c20cGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
  if (-not (Test-Path -LiteralPath $c20cGate -PathType Leaf)) { throw 'C17B C20C successor gate is missing.' }
  & $c20cGate -RepositoryRoot $root
  Write-Output 'C17B historical clear-glass owner passed through the exact C20C neutral brand-glass successor; buildInstall=closed.'
  return
}

$contract = $ticket.clearGlassDesignContract
$contractChecks = @(
  @([bool]$contract.individualControlRequired, $true, 'individual controls'),
  @([bool]$contract.railSurfaceMustRemainTransparent, $true, 'transparent rail'),
  @([bool]$contract.filledFamilyBandOrTrapezoidAllowed, $false, 'filled band rejection'),
  @([double]$contract.lightGlassFillAlpha, 0.52, 'light glass alpha'),
  @([double]$contract.mediaGlassFillAlpha, 0.58, 'media glass alpha'),
  @([double]$contract.backdropBlurSigma, 16.0, 'blur'),
  @([double]$contract.controlHeight, 48.0, 'control height'),
  @([double]$contract.railHeight, 52.0, 'rail height'),
  @([double]$contract.cornerRadius, 14.0, 'radius'),
  @([double]$contract.iconSize, 20.0, 'icon'),
  @([double]$contract.labelFontSize, 12.0, 'label'),
  @([double]$contract.minimumTapTarget, 48.0, 'target'),
  @([double]$contract.connectionLineMaximumStrokeWidth, 1.5, 'connection stroke'),
  @([double]$contract.connectionLineMaximumOpacity, 0.35, 'connection opacity'),
  @([bool]$contract.reducedMotionSettlesImmediately, $true, 'reduced motion')
)
foreach ($check in $contractChecks) {
  if ($check[0] -ne $check[1]) { throw "C17B founder contract drifted: $($check[2])" }
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'enum MoolLocalNavigationSurfaceTone { light, media }',
  'static const double railHeight = 52',
  'static const double controlHeight = MoolMetrics.compactTapTarget',
  'static const double controlRadius = 14',
  'static const double backdropBlurSigma = 16',
  'static const double iconSize = 20',
  'static const double labelFontSize = 12',
  'static const double maximumTextScale = 1.3',
  'static const Color lightGlassFill = Color(0x85FFFFFF)',
  'static const Color mediaGlassFill = Color(0x94081225)',
  'static Color controlAccent(',
  'class MoolLocalNavigationRail extends StatelessWidget',
  'class _MoolLocalNavigationCell extends StatefulWidget',
  'child: BackdropFilter(',
  "'moolsocial-local-`${action.id}-glass-control'",
  'foregroundDecoration: BoxDecoration(',
  'onHighlightChanged:',
  'scale: _pressed ? .985 : 1',
  'fontWeight: selected',
  '? FontWeight.w800',
  ': FontWeight.w700',
  'MoolMotion.accessible(context, MoolMotion.quick)'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared clear-glass owner is missing: $token") }
}

$railStart = $design.IndexOf('class MoolLocalNavigationRail extends StatelessWidget')
$railEnd = $design.IndexOf('class MoolOutcomeDock extends StatelessWidget', $railStart)
if ($railStart -lt 0 -or $railEnd -le $railStart) {
  $blockers.Add('shared local-navigation owner bounds are invalid')
} else {
  $rail = $design.Substring($railStart, $railEnd - $railStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'Expanded(', 'FittedBox(', 'distributeEvenly', 'ListView(')) {
    if ($rail.Contains($forbidden)) { $blockers.Add("shared owner retains rejected strip, shrink or distribution token: $forbidden") }
  }
  if ([regex]::Matches($rail, 'child:\s*BackdropFilter\(').Count -ne 1) {
    $blockers.Add('shared owner must declare exactly one reusable per-action BackdropFilter')
  }
}

foreach ($token in @(
  'moolDestinationFamilyRailSurfaceOpacity = 0',
  'MoolLocalNavigationTokens.connectionLineMaximumOpacity',
  'MoolLocalNavigationTokens.connectionLineStrokeWidth',
  'IgnorePointer(',
  'ExcludeSemantics(',
  'child: CustomPaint('
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("connection owner is missing: $token") }
}
if ($navigation.Contains('strokeWidth = 10')) {
  $blockers.Add('connection owner retains the rejected broad 10px stroke')
}

foreach ($entry in $familyOwners.GetEnumerator()) {
  $source = Get-Content -Raw -LiteralPath $entry.Value
  if (-not $source.Contains('MoolLocalNavigationRail(') -or
      -not $source.Contains("familyId: '$($entry.Key)'")) {
    $blockers.Add("$($entry.Key) does not consume the one shared native owner")
  }
}
$social = Get-Content -Raw -LiteralPath $familyOwners.social
if (-not $social.Contains('surfaceTone: MoolLocalNavigationSurfaceTone.media')) {
  $blockers.Add('Social media background does not select the legible media glass tone')
}

foreach ($token in @(
  'for (final actionCount in const [2, 3, 4])',
  'actions remain individual 48px glass controls',
  'large system text stays legible without shrinking or clipping',
  'light and media tones keep backgrounds visible and text clear',
  'selected is inert and available press gives one finite response',
  'reduced motion makes glass, selection and press immediate',
  'all six families share distinct accessible accent tokens',
  'find.byType(BackdropFilter)',
  'greaterThanOrEqualTo(48)',
  'greaterThan(4.5)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C17B focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C17B clear-glass shared owner is not qualified: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C17B clear-glass shared owner passed: owner=1; families=6; controls=individual; counts=2,3,4; target=48px; rail=transparent; glassTones=light,media; label=12px/700+; icon=20px; backgroundVisible=true; broadBand=absent; connection=1.5px/.35max; reducedMotion=immediate; buildInstall=closed.'
