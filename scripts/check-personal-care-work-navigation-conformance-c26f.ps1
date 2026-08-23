[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C26F([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C26F gate rejected: $Message" }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C26F ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C26F (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

$book = Read-Owner 'apps/mobile/lib/features/book/widgets/book_widgets.dart'
$buy = Read-Owner 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
$work = Read-Owner 'apps/mobile/lib/features/work/widgets/work_widgets.dart'
$design = Read-Owner 'apps/mobile/lib/core/design/mool_design_system.dart'
$test = Read-Owner 'apps/mobile/test/ui_v2/universal/mool_care_work_navigation_conformance_c26f_test.dart'

foreach ($literal in @(
  "key: const Key('care-book-local-navigation')",
  "keyName: 'care-local-doctor'",
  "keyName: 'care-local-medicine'",
  "switchGlobalDestination('/app/buy?sub=medicine')",
  "keyName: 'care-local-salon'",
  "onOpenChat: openChat"
)) {
  Assert-C26F ($book.Contains($literal)) "Care projection missing: $literal"
}
foreach ($literal in @(
  "activeId: careNavigation ? 'book' : 'buy'",
  "key: const ValueKey('care-local-destination-tabs')",
  "keyName: 'care-local-tab-doctor'",
  "keyName: 'care-local-tab-medicine'",
  "keyName: 'care-local-tab-salon'",
  'backgroundColor: Colors.white'
)) {
  Assert-C26F ($buy.Contains($literal)) "Medicine Care-shell projection missing: $literal"
}
foreach ($literal in @(
  "activeId: 'work'",
  "keyName: 'work-local-earn'",
  "label: 'Earn Today'",
  "keyName: 'work-local-workspace'",
  "label: 'Workspace'",
  "keyName: 'work-global-chat'"
)) {
  Assert-C26F ($work.Contains($literal)) "Work projection missing: $literal"
}

$cellStart = $design.IndexOf('class _MoolLocalNavigationCellState', [StringComparison]::Ordinal)
$cellEnd = $design.IndexOf('/// One persistent navigation language', $cellStart, [StringComparison]::Ordinal)
Assert-C26F ($cellStart -ge 0 -and $cellEnd -gt $cellStart) 'shared cell owner markers missing'
$cell = $design.Substring($cellStart, $cellEnd - $cellStart)
foreach ($literal in @('MoolColors.navy', 'MoolColors.muted', 'color: Colors.transparent')) {
  Assert-C26F ($cell.Contains($literal)) "neutral background-independent cell token missing: $literal"
}
foreach ($forbidden in @('surfaceTone ==', 'navigationAccentForFamily', 'BackdropFilter', 'glassGradient(', 'LinearGradient(')) {
  Assert-C26F (-not $cell.Contains($forbidden)) "destination theme leaks into local cell: $forbidden"
}
foreach ($literal in @('care-local-medicine', 'care-local-tab-medicine', 'work-local-workspace', 'moolsocial-local-workspace-selected-indicator')) {
  Assert-C26F ($test.Contains($literal)) "focused proof missing: $literal"
}

Write-Output 'C26F Care and Work navigation conformance passed: Care=3 actions; Work=2 actions; MedicineBuyReuse=true; themedCell=false.'
