[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$predecessorGate = Join-Path $root 'scripts\check-personal-shared-optical-liquid-glass-control-c21b.ps1'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-global-subaction-optical-liquid-glass-recovery-fix4-c21-ticket.json'
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-social-media-glass-conformance-fix4-c21c-ticket.json'
$contractPath = Join-Path $root 'config\mvp-personal-subaction-optical-liquid-glass-regression-c21.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$socialPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
$testPath = Join-Path $root 'apps\mobile\test\ui_v2\social\uaw_personal_mvp_social_subaction_professional_conformance_c16b_test.dart'

foreach ($path in @($predecessorGate, $parentPath, $ticketPath, $contractPath, $scopePath, $designPath, $socialPath, $testPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C21C required owner is missing: $path" }
}
& $predecessorGate -RepositoryRoot $root

$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-SOCIAL-MEDIA-GLASS-CONFORMANCE-FIX4-C21C'

$sequence = @($parent.implementationSequence)
$expectedIndex = [Array]::IndexOf($sequence, $expected)
$current = [string]$scope.ticket.id
$currentIndex = [Array]::IndexOf($sequence, $current)
if ([int]$ticket.schemaVersion -ne 1 -or [string]$ticket.ticketId -cne $expected -or
    [string]$ticket.parentTicket -cne [string]$parent.ticketId -or
    [string]$ticket.classification -cne 'mvp_required' -or
    $expectedIndex -lt 0 -or $currentIndex -lt $expectedIndex -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $current -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized') {
  throw 'C21C ticket identity, sequence or scope disclosure is invalid.'
}
if (-not [bool]$ticket.reuseInventory.complete -or
    -not [bool]$ticket.reuseInventory.duplicateSearchComplete -or
    @($ticket.reuseInventory.newScreens).Count -ne 0 -or
    @($ticket.reuseInventory.newRoutes).Count -ne 0 -or
    @($ticket.reuseInventory.newBackendOwners).Count -ne 0 -or
    @($ticket.reuseInventory.newSubactions).Count -ne 0 -or
    [bool]$scope.execution.buildAuthorized -or [bool]$scope.execution.deviceInstallAuthorized -or
    [bool]$scope.execution.backendWriteAuthorized -or [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C21C reuse or execution boundary has been weakened.'
}

$rules = $contract.visualRules
if ([string]$contract.state -notlike 'c21[c-h]*' -or
    [string]$contract.familyQualification.social -cne 'c21c_media_compositing_and_provider_optical_normalization_passed' -or
    [double]$rules.providerIconOpticalBox -ne 20 -or [double]$rules.providerGlyphSize -ne 18 -or
    [string]$rules.mediaGlassTopArgb -cne 'C4141C2D' -or
    [string]$rules.mediaGlassBottomArgb -cne 'B00A1120' -or
    -not [bool]$rules.controlledNeutralGradientRequired -or
    -not [bool]$rules.specularInnerEdgeRequired -or
    [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C21C Social media-glass regression contract has drifted.'
}

$design = Get-Content -Raw -LiteralPath $designPath
$social = Get-Content -Raw -LiteralPath $socialPath
$test = Get-Content -Raw -LiteralPath $testPath
$blockers = [Collections.Generic.List[string]]::new()
foreach ($token in @(
  'static const double providerIconWidth = 20',
  'static const double providerIconHeight = 20',
  'static const double providerGlyphSize = 18'
)) {
  if (-not $design.Contains($token)) { $blockers.Add("C21C provider optical owner is missing: $token") }
}
foreach ($pattern in @(
  'width:\s*MoolLocalNavigationTokens\s*\.providerGlyphSize',
  'height:\s*MoolLocalNavigationTokens\s*\.providerGlyphSize'
)) {
  if (-not [regex]::IsMatch($design, $pattern)) {
    $blockers.Add("C21C formatter-tolerant provider optical expression is missing: $pattern")
  }
}
foreach ($token in @(
  "Screen04Choice('feed', 'Feed')",
  "Screen04Choice('create', 'Create')",
  "'shorts'",
  "'videos'",
  "attributionAsset: 'assets/prototype/provider-youtube.svg'",
  'surfaceTone: MoolLocalNavigationSurfaceTone.media',
  "familyId: 'social'",
  'MoolLocalNavigationRail('
)) {
  if (-not $social.Contains($token)) { $blockers.Add("C21C actual Social owner is missing: $token") }
}
if ([regex]::Matches($social, "attributionAsset: 'assets/prototype/provider-youtube.svg'").Count -ne 2) {
  $blockers.Add('C21C requires exactly the existing two YouTube-attributed outcomes and no filler provider outcome')
}
foreach ($forbidden in @("Screen04Choice('instagram'", "Screen04Choice('facebook'", 'SingleChildScrollView(')) {
  $contextStart = $social.IndexOf('class Screen04ContextTabs')
  $contextEnd = $social.IndexOf('class Screen04CardSpec', $contextStart)
  if ($contextStart -lt 0 -or $contextEnd -le $contextStart -or
      $social.Substring($contextStart, $contextEnd - $contextStart).Contains($forbidden)) {
    $blockers.Add("C21C Social local owner retains a filler or strip token: $forbidden")
  }
}
foreach ($token in @(
  'Social four-action family uses the shared compact owner without a strip',
  "for (final id in const ['shorts', 'videos', 'feed', 'create'])",
  'find.byType(BackdropFilter)',
  'providerAssets, hasLength(2)',
  'provider.width, 18',
  'const Size(20, 20)',
  'specular-edge',
  'MoolLocalNavigationSurfaceTone.media',
  'Social preserves YouTube semantics, direct selection and reduced motion'
)) {
  if (-not $test.Contains($token)) { $blockers.Add("C21C focused coverage is missing: $token") }
}

if ($blockers.Count -gt 0) { throw ('C21C Social media glass is not qualified: ' + ($blockers -join '; ') + '.') }
Write-Output 'C21C Social media-glass conformance passed: outcomes=Shorts,Videos,Feed,Create; providerAssets=2YouTube; filler=absent; mediaGradient=deepNeutral; controls=4x48px; gap=8px; providerGlyph=18pxIn20pxBox; MaterialGlyph=20px; specular=true; semantics=direct; reducedMotion=immediate; buildInstall=closed.'
