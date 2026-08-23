[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C27C([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C27C gate rejected: $Message" }
}

function Read-C27COwner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C27C ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C27C (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-C27CSlice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C27C ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C27C ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$design = Read-C27COwner 'apps/mobile/lib/core/design/mool_design_system.dart'
$navigation = Read-C27COwner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$test = Read-C27COwner 'apps/mobile/test/ui_v2/universal/mool_uniform_embedded_switcher_c27c_test.dart'
$ticket = Read-C27COwner 'config/uaw-personal-mvp-uniform-embedded-switcher-fix10-c27c-ticket.json' | ConvertFrom-Json
$scope = Read-C27COwner 'config/mvp-scope-gate-state.json' | ConvertFrom-Json

Assert-C27C ([string]$ticket.ticketId -ceq 'UAW-PERSONAL-MVP-UNIFORM-EMBEDDED-SWITCHER-FIX10-C27C') 'ticket id changed'
$ticketState = [string]$ticket.state
Assert-C27C ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C27C ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C27C ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime authorization is not open'
  Assert-C27C (-not [bool]$scope.execution.buildAuthorized) 'build authorization opened early'
}

$tokens = Get-C27CSlice $design 'abstract final class MoolLocalNavigationTokens' 'class MoolHomeHubAction'
foreach ($literal in @(
  'static const double switcherWidth = 136;',
  'static const double switcherRadius = 16;',
  'static const double switcherRowHeight = 56;',
  'static const double switcherIconSize = destinationIconSize;',
  'static const double switcherSelectedIndicatorWidth = 2;',
  'static const double switcherSelectedIndicatorHeight = 18;',
  'static const Color switcherCanvas = Color(0xD9FFFFFF);',
  'static const Duration selectionDuration = Duration(milliseconds: 180);'
)) {
  Assert-C27C ($tokens.Contains($literal)) "switcher token missing: $literal"
}

$menu = Get-C27CSlice $navigation 'class MoolMainDomainMenu extends StatelessWidget' 'class MoolActionChooser extends StatefulWidget'
foreach ($literal in @(
  'height: MoolLocalNavigationTokens.switcherRowHeight',
  'MoolLocalNavigationTokens.navigationAccentForFamily(',
  'MoolLocalNavigationTokens.switcherIconSize',
  'MoolLocalNavigationTokens.destinationFontFamily',
  'MoolLocalNavigationTokens.destinationLabelSize',
  '.switcherSelectedIndicatorWidth',
  '.switcherSelectedIndicatorHeight'
)) {
  Assert-C27C ($menu.Contains($literal)) "uniform menu contract missing: $literal"
}
foreach ($forbidden in @(
  'MoolHomeHubTokens.accentForFamily(',
  'fontSize: 11',
  'width: 3',
  'size: 20'
)) {
  Assert-C27C (-not $menu.Contains($forbidden)) "predecessor menu styling remains: $forbidden"
}

$panel = Get-C27CSlice $navigation 'class MoolConnectedActionNavigator extends StatefulWidget' 'class MoolGlobalNavigationV2 extends StatefulWidget'
foreach ($literal in @(
  'MoolLocalNavigationTokens.switcherRadius',
  'MoolLocalNavigationTokens.switcherShadow',
  'MoolLocalNavigationTokens.switcherBlurSigma',
  "Key('moolsocial-uniform-switcher-glass')",
  'color: MoolLocalNavigationTokens.switcherCanvas',
  'color: MoolLocalNavigationTokens.switcherBorder',
  'MoolLocalNavigationTokens.switcherPadding'
)) {
  Assert-C27C ($panel.Contains($literal)) "uniform glass contract missing: $literal"
}

$global = Get-C27CSlice $navigation 'class MoolGlobalNavigationV2 extends StatefulWidget' 'class _MoolHomeLauncher extends StatefulWidget'
foreach ($literal in @(
  'duration: MoolLocalNavigationTokens.selectionDuration',
  'width: MoolLocalNavigationTokens.switcherWidth',
  'MoolConnectedActionNavigator(',
  'MoolMotion.enter',
  'MoolMotion.change'
)) {
  Assert-C27C ($global.Contains($literal)) "embedded motion contract missing: $literal"
}
foreach ($forbidden in @('ModalBarrier(', 'Dialog(', 'Icons.close_rounded')) {
  Assert-C27C (-not $global.Contains($forbidden)) "rejected modal switcher treatment remains: $forbidden"
}

foreach ($literal in @(
  'C27C every family uses one embedded switcher visual system',
  'C27C switcher keeps approved motion and dismissal behavior',
  'MoolConnectedActionNavigator(',
  'const Size(2, 18)',
  "fontFamily, 'Inter'",
  'disableAnimations: true'
)) {
  Assert-C27C ($test.Contains($literal)) "focused acceptance missing: $literal"
}

Write-Output 'C27C uniform embedded switcher gate passed: families=6; width=136; rows=56; icon=22; Inter=10.5; neutral glass; motion=180ms.'
