[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C26B([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C26B gate rejected: $Message" }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C26B ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C26B (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

function Get-Slice([string]$Text, [string]$Start, [string]$End) {
  $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
  Assert-C26B ($startIndex -ge 0) "start marker missing: $Start"
  $endIndex = $Text.IndexOf($End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
  Assert-C26B ($endIndex -gt $startIndex) "end marker missing: $End"
  return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$design = Read-Owner 'apps/mobile/lib/core/design/mool_design_system.dart'
$navigation = Read-Owner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$contract = Read-Owner 'approved-references/navigation/moolsocial-embedded-family-navigation/v1/interaction-contract.json'

$rail = Get-Slice $design 'class MoolLocalNavigationRail extends StatelessWidget' '/// One persistent navigation language'
$destination = Get-Slice $navigation 'class MoolDestinationNavigationV2 extends StatefulWidget' 'class MoolDestinationFamilyWavePainter'
$compactStart = $navigation.IndexOf('class _MoolHomeLauncherState extends State<_MoolHomeLauncher>', [StringComparison]::Ordinal)
Assert-C26B ($compactStart -ge 0) 'compact launcher owner missing'
$compactLauncher = $navigation.Substring($compactStart)

foreach ($literal in @(
  'MoolLocalNavigationTokens.destinationRailHeight',
  'moolsocial-local-navigation-compact-cluster',
  'moolsocial-local-${action.id}-selected-indicator',
  'MoolColors.navy',
  'MoolColors.muted'
)) {
  Assert-C26B ($rail.Contains($literal)) "rail contract missing: $literal"
}
foreach ($forbidden in @(
  'SingleChildScrollView',
  'BackdropFilter',
  'glassGradient(',
  'specularGradient(',
  'controlShadows(',
  '_MoolInnerChromaEmission',
  'ClipRRect('
)) {
  Assert-C26B (-not $rail.Contains($forbidden)) "old rendered rail treatment remains: $forbidden"
}
foreach ($literal in @(
  'MoolGlobalNavigationV2(',
  '_MoolFamilyRootButton(',
  'Expanded(child: widget.localNavigation)',
  "label: 'Open `${family.label} home'"
)) {
  Assert-C26B ($destination.Contains($literal)) "destination composition missing: $literal"
}
foreach ($forbidden in @('moolsocial-local-previous', 'moolsocial-local-next', '_MoolRailStepButton(')) {
  Assert-C26B (-not $destination.Contains($forbidden)) "removed step control remains rendered: $forbidden"
}
foreach ($literal in @('Icons.grid_view_rounded', "'Mool'", 'Colors.transparent')) {
  Assert-C26B ($compactLauncher.Contains($literal)) "compact Mool control missing: $literal"
}

$expectedAccents = @(
  "'social' => const Color(0xFF3155C6)",
  "'buy' => const Color(0xFF7B3FB5)",
  "'eat' => const Color(0xFFC64E2B)",
  "'ride' => const Color(0xFF087E9A)",
  "'book' => const Color(0xFF16825D)",
  "'work' => const Color(0xFF9A6400)"
)
foreach ($literal in $expectedAccents) {
  Assert-C26B ($design.Contains($literal)) "approved family accent missing: $literal"
}

$parsedContract = $contract | ConvertFrom-Json
Assert-C26B (-not [bool]$parsedContract.bottomNavigation.horizontalScrollAllowed) 'contract permits horizontal scroll'
Assert-C26B (-not [bool]$parsedContract.bottomNavigation.capsuleOrPillAllowed) 'contract permits capsules'
Assert-C26B ([int]$parsedContract.bottomNavigation.minimumTapTarget -eq 44) 'contract minimum tap target changed'
Assert-C26B (@($parsedContract.families).Count -eq 6) 'contract family count changed'

Write-Output 'C26B transparent unboxed destination rail passed: families=6; horizontalScroll=false; capsules=false; minimumTapTarget=44.'
