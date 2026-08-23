[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C26C([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C26C gate rejected: $Message" }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C26C ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C26C (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-Slice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C26C ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C26C ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$navigation = Read-Owner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$design = Read-Owner 'apps/mobile/lib/core/design/mool_design_system.dart'
$contractText = Read-Owner 'approved-references/navigation/moolsocial-embedded-family-navigation/v1/interaction-contract.json'
$menu = Get-Slice $navigation 'class MoolMainDomainMenu extends StatelessWidget' 'class MoolActionChooser extends StatefulWidget'
$navigator = Get-Slice $navigation 'class MoolConnectedActionNavigator extends StatefulWidget' 'class MoolGlobalNavigationV2 extends StatefulWidget'
$global = Get-Slice $navigation 'class MoolGlobalNavigationV2 extends StatefulWidget' 'class _MoolHomeLauncher extends StatefulWidget'

foreach ($literal in @(
  'for (final family in moolActionFamilies)',
  'height: MoolLocalNavigationTokens.switcherRowHeight',
  "'`${widget.keyPrefix}-family-`${family.id}-indicator'",
  'shape: BoxShape.circle'
)) {
  Assert-C26C ($menu.Contains($literal)) "vertical family-row contract missing: $literal"
}
foreach ($forbidden in @('for (var row = 0; row < 2', 'for (var column = 0; column < 3', 'boxShadow: widget.selected')) {
  Assert-C26C (-not $menu.Contains($forbidden)) "predecessor 2x3/card treatment remains: $forbidden"
}

foreach ($literal in @(
  "Key('mool-connected-action-navigator')",
  'MoolLocalNavigationTokens.switcherBlurSigma',
  'color: MoolLocalNavigationTokens.switcherCanvas',
  'onVerticalDragEnd',
  '_dragDy > 24',
  'MoolMainDomainMenu('
)) {
  Assert-C26C ($navigator.Contains($literal)) "connected dock contract missing: $literal"
}
foreach ($forbidden in @("'MoolSocial'", 'Icons.close_rounded', 'mool-connected-navigator-close', 'SafeArea(', 'Alignment.center')) {
  Assert-C26C (-not $navigator.Contains($forbidden)) "separate modal chrome remains: $forbidden"
}

foreach ($literal in @(
  'duration: MoolLocalNavigationTokens.selectionDuration',
  'OverlayPortal(',
  'OverlayPortalController()',
  'CompositedTransformTarget(',
  'CompositedTransformFollower(',
  'targetAnchor: widget.compact && widget.compactOverlayAlignEnd',
  '? Alignment.topRight',
  ': Alignment.topLeft',
  'followerAnchor: widget.compact && widget.compactOverlayAlignEnd',
  '? Alignment.bottomRight',
  ': Alignment.bottomLeft',
  'width: MoolLocalNavigationTokens.switcherWidth',
  "Key('mool-switcher-outside-dismiss')",
  'LocalHistoryEntry(onRemove: _handleLocalHistoryRemoved)',
  'route.addLocalHistoryEntry(entry)',
  '_closeConnectedNavigator(removeHistoryEntry: false)',
  'BackButtonListener(',
  'onBackButtonPressed: _handleBackButton',
  '_closeConnectedNavigator();',
  'return Future<bool>.value(true)',
  'details.primaryVelocity! < -80',
  '_launcherDragDy < -24',
  '_reduceMotion'
)) {
  Assert-C26C ($global.Contains($literal)) "embedded switcher contract missing: $literal"
}
foreach ($forbidden in @('showGeneralDialog', 'barrierColor', 'ModalBarrier', 'pageBuilder:', 'Navigator.of(dialogContext')) {
  Assert-C26C (-not $global.Contains($forbidden)) "modal navigation remains: $forbidden"
}

$contract = $contractText | ConvertFrom-Json
Assert-C26C ($design.Contains('static const double switcherRowHeight = 56;')) 'shared row-height token changed'
Assert-C26C ($design.Contains('static const Duration selectionDuration = Duration(milliseconds: 180);')) 'shared motion token changed'
Assert-C26C ($contract.moolSwitcher.orientation -ceq 'vertical') 'approved switcher orientation changed'
Assert-C26C ([int]$contract.moolSwitcher.rowMinimumHeight -eq 56) 'approved row height changed'
Assert-C26C ([int]$contract.moolSwitcher.motionMilliseconds -eq 180) 'approved motion changed'
Assert-C26C (-not [bool]$contract.moolSwitcher.backdropDimming) 'approved contract permits dimming'
Assert-C26C (-not [bool]$contract.moolSwitcher.separatePageOrModalAppearance) 'approved contract permits modal appearance'
Assert-C26C (@($contract.moolSwitcher.families).Count -eq 6) 'approved family count changed'

Write-Output 'C26C embedded vertical Mool switcher passed: families=6; rows=56px; motion=180ms; conditionalAlignment=true; defaultLeft=true; modal=false; dimming=false.'
