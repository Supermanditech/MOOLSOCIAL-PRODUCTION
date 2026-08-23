[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$c20ParentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$navigationPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_adaptive_local_navigation_c16a_test.dart'
$auditPath = Join-Path $root 'docs\quality\UAW-C16-R60-15-OPPO-PREDECESSOR-AUDIT-20260808.md'
$familyOwners = @{
  eat = Join-Path $root 'apps\mobile\lib\features\eat\widgets\eat_widgets.dart'
  ride = Join-Path $root 'apps\mobile\lib\features\ride\widgets\ride_widgets.dart'
  book = Join-Path $root 'apps\mobile\lib\features\book\widgets\book_widgets.dart'
  work = Join-Path $root 'apps\mobile\lib\features\work\widgets\work_widgets.dart'
}

foreach ($path in @($ticketPath, $scopePath, $designPath, $navigationPath, $testPath, $auditPath) + $familyOwners.Values) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16A required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$current = [string]$scope.ticket.id
if (Test-Path -LiteralPath $c20ParentPath -PathType Leaf) {
  $c20Parent = Get-Content -Raw -LiteralPath $c20ParentPath | ConvertFrom-Json
  $c20Sequence = @($c20Parent.implementationSequence)
  $c20Start = [Array]::IndexOf($c20Sequence, 'UAW-PERSONAL-MVP-SHARED-NEUTRAL-BRAND-GLASS-CONTROL-FIX3-C20C')
  $c20Current = [Array]::IndexOf($c20Sequence, $current)
  if ([string]$c20Parent.ticketId -ceq 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-FOUNDER-GALLERY-PROFESSIONAL-RECOVERY-FIX3-C20' -and
      $c20Start -ge 0 -and $c20Current -ge $c20Start) {
    $c20cGate = Join-Path $root 'scripts\check-personal-shared-neutral-brand-glass-control-c20c.ps1'
    if (-not (Test-Path -LiteralPath $c20cGate -PathType Leaf)) { throw 'C16A C20C successor gate is missing.' }
    & $c20cGate -RepositoryRoot $root
    Write-Output 'C16A historical professional-owner gate passed through the exact C20C neutral brand-glass successor; buildInstall=closed.'
    return
  }
}
if ($current -like '*C17*') {
  $successorGate = Join-Path $root 'scripts\check-personal-eat-ride-book-work-clear-glass-conformance-c17d.ps1'
  if (-not (Test-Path -LiteralPath $successorGate -PathType Leaf)) {
    throw 'C16A successor compatibility requires the C17D family gate.'
  }
  & $successorGate -RepositoryRoot $root
  Write-Output 'C16A historical professional-owner gate passed through the founder-approved C17 clear-glass successor: target=48px; label=12px; icon=20px; families=6; buildInstall=closed.'
  return
}
$expected = 'UAW-PERSONAL-MVP-SUBACTION-DESIGN-TOKEN-AND-ADAPTIVE-LAYOUT-FIX1-C16A'
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-GLOBAL-SUBACTION-PROFESSIONAL-DESIGN-SYSTEM-FIX1-C16' -or
    -not @($ticket.implementationSequence).Contains($expected)) {
  throw 'C16A parent ticket identity or implementation sequence is invalid.'
}
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16A MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16A host gate refuses build, install, backend, reference or external write authority.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$navigation = Get-Content -Raw -LiteralPath $navigationPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'abstract final class MoolLocalNavigationTokens',
  'static const double iconSize = 16',
  'static const double labelFontSize = 10.5',
  'static const double itemGap = MoolSpacing.xxs',
  'static const double selectedIndicatorWidth = 20',
  'static Color familyAccent(String familyId)',
  "'social' => const Color(0xFF5555D6)",
  "'buy' => const Color(0xFFFF8A00)",
  "'eat' => const Color(0xFF168A2E)",
  "'ride' => const Color(0xFF1677C8)",
  "'book' => const Color(0xFF8B3DC4)",
  "'work' => const Color(0xFFB66A00)",
  'static double clusterWidth(double maxWidth, int actionCount)',
  'static double selectedCenterX(',
  'class MoolLocalNavigationRail extends StatelessWidget',
  "key: const Key('moolsocial-local-navigation-adaptive-layout')",
  "key: const Key('moolsocial-local-navigation-compact-cluster')",
  'height: MoolMetrics.minimumTapTarget',
  'onTap: action.onPressed',
  'MoolMotion.accessible(context, MoolMotion.quick)'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared design owner is missing: $token") }
}

$railStart = $design.IndexOf('class MoolLocalNavigationRail extends StatelessWidget')
$railEnd = $design.IndexOf('class MoolOutcomeDock extends StatelessWidget', $railStart)
if ($railStart -lt 0 -or $railEnd -le $railStart) {
  $blockers.Add('shared local-navigation owner bounds are invalid')
} else {
  $rail = $design.Substring($railStart, $railEnd - $railStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'Expanded(', 'distributeEvenly', 'moolsocial-local-navigation-scroll', 'moolsocial-local-navigation-distributed')) {
    if ($rail.Contains($forbidden)) { $blockers.Add("shared local-navigation owner retains forbidden strip/distribution token: $forbidden") }
  }
}

foreach ($token in @(
  'MoolLocalNavigationTokens.familyAccent(widget.activeId)',
  'value.selectedLocalIndex.toDouble()',
  'localActionCount: widget.localActionCount',
  'MoolLocalNavigationTokens.selectedCenterX('
)) {
  if (-not $navigation.Contains($token)) { $blockers.Add("family wave owner is missing adaptive-center token: $token") }
}

foreach ($entry in $familyOwners.GetEnumerator()) {
  $source = Get-Content -Raw -LiteralPath $entry.Value
  if (-not $source.Contains('MoolLocalNavigationRail(') -or
      -not $source.Contains("familyId: '$($entry.Key)'")) {
    $blockers.Add("$($entry.Key) does not consume the shared C16A family owner")
  }
  if ($source.Contains('distributeEvenly: true')) {
    $blockers.Add("$($entry.Key) retains the rejected even-distribution request")
  }
}

foreach ($token in @(
  'for (final actionCount in const [2, 3, 4])',
  '$actionCount actions use one centered compact cluster with 44px targets',
  'compact large text preserves one row, all labels and hit targets',
  'selected state is inert, one tap opens once and motion is finite',
  'reduced motion settles every shared selected token immediately',
  'six families share one accent token owner and fallback',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16A focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16A professional subaction design owner is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16A professional subaction design owner passed: sharedOwner=1; compactCounts=2,3,4; scrollStrip=absent; sparseExpansion=absent; target=44px; familyAccents=6; waveCenter=adaptive; reducedMotion=immediate; buildInstall=closed.'
