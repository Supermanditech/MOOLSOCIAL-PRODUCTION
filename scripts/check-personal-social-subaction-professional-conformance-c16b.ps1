[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$socialPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\social\uaw_personal_mvp_social_subaction_professional_conformance_c16b_test.dart'
$screen04TestPath = Join-Path $root 'apps\mobile\test\screen04_universal_v2_conformance_test.dart'
$providerAssetPath = Join-Path $root 'apps\mobile\assets\prototype\provider-youtube.svg'
$assessmentPath = Join-Path $root 'docs\quality\UAW-PERSONAL-MVP-SOCIAL-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16B-PRESELECTION-ASSESSMENT-20260808.md'

foreach ($path in @($ticketPath, $scopePath, $socialPath, $designPath, $testPath, $screen04TestPath, $providerAssetPath, $assessmentPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C16B required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SOCIAL-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16B'
$sequence = @($ticket.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ($expectedIndex -lt 0 -or
    $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C16B MVP selection/disclosure gate is not active or has not been passed sequentially.'
}
if ([bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.referenceWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C16B host gate refuses build, install, backend, reference or external write authority.'
}

$social = Get-Content -Raw -LiteralPath $socialPath
$design = Get-Content -Raw -LiteralPath $designPath
$test = Get-Content -Raw -LiteralPath $testPath
$screen04Test = Get-Content -Raw -LiteralPath $screen04TestPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  "import '../../core/design/mool_design_system.dart';",
  'class Screen04ContextTabs extends StatelessWidget',
  'child: MoolLocalNavigationRail(',
  "familyId: 'social'",
  "key: const Key('screen04-choice-ribbon')",
  "keyName: 'screen04-rail-`${item.id}'",
  "'shorts' => Icons.play_circle_outline_rounded",
  "'videos' => Icons.ondemand_video_outlined",
  "'feed' => Icons.dynamic_feed_outlined",
  "'create' => Icons.add_circle_outline_rounded",
  "'YouTube `${item.label}'",
  'iconAsset: item.attributionAsset',
  'onPressed: item.id == choice'
)) {
  if (-not $social.Contains($token)) { $blockers.Add("Social shared owner mapping is missing: $token") }
}

foreach ($choice in @(
  @{ Id = 'shorts'; Label = 'Shorts' },
  @{ Id = 'videos'; Label = 'Videos' },
  @{ Id = 'feed'; Label = 'Feed' },
  @{ Id = 'create'; Label = 'Create' }
)) {
  $pattern = "Screen04Choice\(\s*'" + $choice.Id + "',\s*'" + $choice.Label + "'"
  if (-not [regex]::IsMatch($social, $pattern)) {
    $blockers.Add("Social existing action inventory changed: $($choice.Id)")
  }
}
if ([regex]::Matches($social, [regex]::Escape("attributionAsset: 'assets/prototype/provider-youtube.svg'")).Count -ne 2) {
  $blockers.Add('Social YouTube attribution must remain on exactly Shorts and Videos')
}

foreach ($forbidden in @(
  'class _TrackingRailRibbon',
  'class _TrackingRailRibbonState',
  'class _RailAction',
  'class _RailIdentityLine'
)) {
  if ($social.Contains($forbidden)) { $blockers.Add("duplicate Social rail owner remains: $forbidden") }
}

$contextStart = $social.IndexOf('class Screen04ContextTabs extends StatelessWidget')
$contextEnd = $social.IndexOf('@immutable', $contextStart)
if ($contextStart -lt 0 -or $contextEnd -le $contextStart) {
  $blockers.Add('Social context-tab owner bounds are invalid')
} else {
  $contextOwner = $social.Substring($contextStart, $contextEnd - $contextStart)
  foreach ($forbidden in @('SingleChildScrollView(', 'Expanded(', 'ScrollController(', 'AnimatedScale(', 'boxShadow:')) {
    if ($contextOwner.Contains($forbidden)) { $blockers.Add("Social context owner retains forbidden bespoke strip token: $forbidden") }
  }
}

foreach ($token in @(
  'this.semanticLabel',
  'this.iconAsset',
  'SvgPicture.asset(',
  'static const double providerIconWidth = 16',
  'static const double providerIconHeight = 11',
  'static const double labelFontSize = 10.5',
  'onTap: action.onPressed'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("shared provider/semantic owner is missing: $token") }
}

foreach ($token in @(
  'Social four-action family uses the shared compact owner without a strip',
  'Social preserves YouTube semantics, direct selection and reduced motion',
  "expect(node.label, 'YouTube Shorts, current')",
  "expect(node.label, 'Open YouTube Videos')",
  'find.byType(MoolLocalNavigationRail)',
  'find.byType(Scrollable)',
  'find.byType(Expanded)',
  'greaterThanOrEqualTo(44)',
  'expect(shortsSelection.duration, Duration.zero)'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C16B focused coverage is missing: $token") }
}

foreach ($token in @(
  "'eat': Key('eat-home-screen')",
  "'ride': Key('ride-booking-screen')",
  "'book': Key('book-doctor')",
  "'work': Key('work-earn-screen')"
)) {
  if (-not $screen04Test.Contains($token)) { $blockers.Add("Screen 04 current default-owner coverage is missing: $token") }
}

if ($blockers.Count -gt 0) {
  throw ('C16B Social professional conformance is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C16B Social professional conformance passed: actions=Shorts,Videos,Feed,Create; sharedOwner=1; duplicateRenderers=0; providerAttribution=preserved; compactFour=1; target=44px; reducedMotion=immediate; buildInstall=closed.'
