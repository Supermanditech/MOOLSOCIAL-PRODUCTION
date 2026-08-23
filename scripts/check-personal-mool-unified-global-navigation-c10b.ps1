[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-shared-global-dock-main-roots-fix1-c10b-ticket.json'
$globalPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mool_global_navigation_v2.dart'
$personalPath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\personal_mool_root_v2.dart'
$choicePath = Join-Path $root 'apps\mobile\lib\ui_v2\universal\mvp_action_choice_root_v2.dart'
$socialPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\social_v2_consumer.dart'
$socialComponentsPath = Join-Path $root 'apps\mobile\lib\ui_v2\social\screen04_universal_components.dart'
foreach ($path in @($ticketPath, $globalPath, $personalPath, $choicePath, $socialPath, $socialComponentsPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C10B required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-SHARED-GLOBAL-DOCK-MAIN-ROOTS-FIX1-C10B' -or
    [string]$ticket.parentTicket -cne 'UAW-PERSONAL-MVP-UNIFIED-PERSISTENT-BOTTOM-NAVIGATION-SHELL-FIX1-C10') {
  throw 'C10B ticket identity is invalid.'
}

$global = Get-Content -Raw -LiteralPath $globalPath
$personal = Get-Content -Raw -LiteralPath $personalPath
$choice = Get-Content -Raw -LiteralPath $choicePath
$social = Get-Content -Raw -LiteralPath $socialPath
$socialComponents = Get-Content -Raw -LiteralPath $socialComponentsPath
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'class MoolGlobalNavigationV2',
  'MoolOutcomeDock(',
  "activeId: activeId",
  'showOverflowCue: true',
  "keyName: 'mool-root-selected'",
  "keyName: 'mool-action-`$`{action.id`}'",
  "keyName: 'mool-root-chat'",
  "onPressed: activeId == action.id"
)) {
  if (-not $global.Contains($token)) {
    $blockers.Add("shared global owner is missing: $token")
  }
}
foreach ($id in @('social', 'buy', 'eat', 'ride', 'book', 'work')) {
  if (-not $global.Contains("id: '$id'")) {
    $blockers.Add("global destination is missing: $id")
  }
}
if (-not $personal.Contains('bottomNavigationBar: MoolGlobalNavigationV2(')) {
  $blockers.Add('Mool Home does not use the shared global owner')
}
if (-not $choice.Contains('bottomNavigationBar: MoolGlobalNavigationV2(')) {
  $blockers.Add('action-choice root does not use the shared global owner')
}
if ($choice.Contains('_ActionChoiceDock') -or
    $choice.Contains('Icons.arrow_back_ios_new_rounded')) {
  $blockers.Add('action-choice root retains destination-owned bottom navigation or top-level Back')
}
if (-not $social.Contains('bottomNavigationBar: MoolDestinationNavigationV2(') -or
    -not $social.Contains('localNavigation: Screen04ContextTabs(') -or
    -not $global.Contains('class MoolDestinationNavigationV2') -or
    -not $global.Contains('MoolGlobalNavigationV2(')) {
  $blockers.Add('Social does not separate local options from global navigation')
}
if ($social.Contains('Screen04CapabilityRail(') -or
    $socialComponents.Contains('class Screen04CapabilityRail') -or
    -not $socialComponents.Contains('class Screen04ContextTabs')) {
  $blockers.Add('retired Screen04 bottom-navigation owner remains reachable')
}

if ($blockers.Count -gt 0) {
  throw ('C10B unified global navigation is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C10B unified global navigation passed: owner=1; roots=mool,social,eat,ride,book,work; subactions=local; topBack=absent.'
