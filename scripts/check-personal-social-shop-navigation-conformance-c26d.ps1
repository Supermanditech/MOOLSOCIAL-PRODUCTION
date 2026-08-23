[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C26D([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C26D gate rejected: $Message" }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C26D ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C26D (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

$social = Read-Owner 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$socialTabs = Read-Owner 'apps/mobile/lib/ui_v2/social/screen04_universal_components.dart'
$buy = Read-Owner 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
$shared = Read-Owner 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$design = Read-Owner 'apps/mobile/lib/core/design/mool_design_system.dart'
$test = Read-Owner 'apps/mobile/test/ui_v2/universal/mool_family_pair_navigation_conformance_c26d_test.dart'

foreach ($literal in @(
  "key: const Key('screen04-context-tabs')",
  "activeId: _world",
  'localNavigation: Screen04ContextTabs('
)) {
  Assert-C26D ($social.Contains($literal)) "Social projection missing: $literal"
}
foreach ($literal in @("'shorts'", "'videos'", "'feed'", "'create'", "familyId: 'social'", "key: const Key('social-global-chat')")) {
  Assert-C26D ($socialTabs.Contains($literal)) "Social direct action missing: $literal"
}
foreach ($literal in @(
  'bottomNavigationBar: MoolDestinationNavigationV2(',
  "activeId: careNavigation ? 'book' : 'buy'",
  "label: 'Wholesale'",
  "label: 'Orders'",
  "keyName: 'buy-global-chat'"
)) {
  Assert-C26D ($buy.Contains($literal)) "Shop projection missing: $literal"
}
Assert-C26D (-not $buy.Contains("keyName: 'buy-local-tab-medicine',")) 'Medicine returned to the Shop rail'
Assert-C26D (-not $buy.Contains("keyName: 'buy-local-tab-shop'")) 'FSC06 local Shop tab returned'
Assert-C26D (-not $buy.Contains("label: 'Products'")) 'FSC06 Products label returned'

foreach ($forbidden in @('showGeneralDialog', 'barrierColor')) {
  Assert-C26D (-not $shared.Contains($forbidden)) "old Mool popup owner remains: $forbidden"
}
$railStart = $design.IndexOf('class MoolLocalNavigationRail extends StatelessWidget', [StringComparison]::Ordinal)
$railEnd = $design.IndexOf('/// One persistent navigation language', $railStart, [StringComparison]::Ordinal)
Assert-C26D ($railStart -ge 0 -and $railEnd -gt $railStart) 'shared rail owner markers missing'
$rail = $design.Substring($railStart, $railEnd - $railStart)
foreach ($forbidden in @('SingleChildScrollView', 'BackdropFilter', 'glassGradient(', 'controlShadows(', 'ClipRRect(')) {
  Assert-C26D (-not $rail.Contains($forbidden)) "old rendered rail treatment remains: $forbidden"
}
foreach ($literal in @('moolsocial-compact-destination-rail', 'mool-navigator-family-buy', 'buy-local-tab-wholesale', 'screen04-context-tabs')) {
  Assert-C26D ($test.Contains($literal)) "focused proof missing: $literal"
}

Write-Output 'C26D Social and Shop navigation conformance passed: Social=specialized C29N dock; SocialActions=4; Shop=2 actions; Products=false; shared fixed transparent rail=true.'
