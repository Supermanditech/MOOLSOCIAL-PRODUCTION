[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C27B([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C27B gate rejected: $Message" }
}

function Read-C27BOwner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C27B ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C27B (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-C27BSlice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C27B ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C27B ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$design = Read-C27BOwner 'apps/mobile/lib/core/design/mool_design_system.dart'
$navigation = Read-C27BOwner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$test = Read-C27BOwner 'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart'
$ticket = Read-C27BOwner 'config/uaw-personal-mvp-uniform-navigation-shared-dock-fix10-c27b-ticket.json' | ConvertFrom-Json
$scope = Read-C27BOwner 'config/mvp-scope-gate-state.json' | ConvertFrom-Json

Assert-C27B ([string]$ticket.ticketId -ceq 'UAW-PERSONAL-MVP-UNIFORM-NAVIGATION-SHARED-DOCK-FIX10-C27B') 'ticket id changed'
$ticketState = [string]$ticket.state
Assert-C27B ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C27B ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C27B ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime authorization is not open'
}

$tokens = Get-C27BSlice $design 'abstract final class MoolLocalNavigationTokens' 'class MoolHomeHubAction'
foreach ($literal in @(
  'static const double destinationRailHeight = 58;',
  'static const double railHeight = destinationRailHeight;',
  'static const double destinationFixedCellWidth = 54;',
  'static const double destinationPreferredLocalCellWidth = 72;',
  'static const double destinationIconSize = 22;',
  'static const double destinationLabelSize = 10.5;',
  "static const String destinationFontFamily = 'Inter';",
  'static const Color destinationCanvas = Color(0xF7F8F9FC);'
)) {
  Assert-C27B ($tokens.Contains($literal)) "uniform token missing: $literal"
}

$rail = Get-C27BSlice $design 'class MoolDestinationIconLabel extends StatelessWidget' '/// One persistent navigation language'
foreach ($literal in @(
  'alignment: Alignment.centerLeft',
  'MoolDestinationIconLabel(',
  'maxLines: 2',
  'destinationFontFamily',
  'container: true'
)) {
  Assert-C27B ($rail.Contains($literal)) "uniform rail contract missing: $literal"
}
foreach ($forbidden in @(
  'FittedBox(',
  'SingleChildScrollView',
  'BackdropFilter',
  'glassGradient(',
  '_MoolInnerChromaEmission'
)) {
  Assert-C27B (-not $rail.Contains($forbidden)) "rejected rail treatment remains: $forbidden"
}

$destination = Get-C27BSlice $navigation 'class MoolDestinationNavigationV2 extends StatefulWidget' 'class MoolDestinationFamilyWavePainter'
foreach ($literal in @(
  "key: const Key('moolsocial-uniform-destination-canvas')",
  'color: MoolLocalNavigationTokens.destinationCanvas',
  'maintainBottomViewPadding: true',
  'MoolDestinationIconLabel(',
  'Expanded(child: widget.localNavigation)'
)) {
  Assert-C27B ($destination.Contains($literal)) "destination shell contract missing: $literal"
}
foreach ($forbidden in @(
  '_sessionDisclosureByFamily',
  '_localOverlayController',
  '_globalRailTargetKey',
  '_selectedMainActionAnchorKey',
  '_disclosureController',
  '_requestMainAnchorMeasure',
  '_anchorMeasureFramesRemaining',
  'FittedBox('
)) {
  Assert-C27B (-not $destination.Contains($forbidden)) "removed predecessor owner remains: $forbidden"
}

$launcherStart = $navigation.IndexOf('class _MoolHomeLauncherState extends State<_MoolHomeLauncher>', [StringComparison]::Ordinal)
Assert-C27B ($launcherStart -ge 0) 'Mool launcher owner missing'
$launcher = $navigation.Substring($launcherStart)
foreach ($literal in @(
  "Key('mool-compact-launcher-icon-label')",
  "label: 'Mool'",
  'icon: Icons.grid_view_rounded',
  'MoolLocalNavigationTokens.destinationFixedCellWidth'
)) {
  Assert-C27B ($launcher.Contains($literal)) "deterministic Mool paint contract missing: $literal"
}

foreach ($literal in @(
  'C27B all six families use one fixed visual token system',
  'C27B sparse actions stay compact and leading',
  'C27B keeps semantic controls above persistent bottom inset',
  "find.byIcon(Icons.grid_view_rounded)",
  "find.text('Mool')",
  "const Size(54, 58)"
)) {
  Assert-C27B ($test.Contains($literal)) "focused acceptance missing: $literal"
}

Write-Output 'C27B uniform navigation design-system gate passed: six families; 58px rail; fixed Inter labels; leading sparse actions; neutral canvas; dead disclosure removed.'
