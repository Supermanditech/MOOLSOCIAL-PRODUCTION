[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

$ticketPath = Join-Path $root 'config\uaw-personal-mvp-chat-global-dock-exact-return-fix1-c10d-ticket.json'
$widgetsPath = Join-Path $root 'apps\mobile\lib\features\chat\widgets\chat_widgets.dart'
$inboxPath = Join-Path $root 'apps\mobile\lib\features\chat\screens\chat_inbox_screen.dart'
$threadPath = Join-Path $root 'apps\mobile\lib\features\chat\screens\chat_thread_screen.dart'
$journeyTestPath = Join-Path $root 'apps\mobile\test\ui_v2\universal\uaw_personal_mvp_chat_global_dock_exact_return_c10d_test.dart'
foreach ($path in @($ticketPath, $widgetsPath, $inboxPath, $threadPath, $journeyTestPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C10D required owner is missing: $path"
  }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
if ([string]$ticket.ticketId -cne 'UAW-PERSONAL-MVP-CHAT-GLOBAL-DOCK-EXACT-RETURN-FIX1-C10D' -or
    [string]$ticket.parentTicket -cne 'UAW-PERSONAL-MVP-UNIFIED-PERSISTENT-BOTTOM-NAVIGATION-SHELL-FIX1-C10') {
  throw 'C10D ticket identity is invalid.'
}

$widgets = Get-Content -Raw -LiteralPath $widgetsPath
$inbox = Get-Content -Raw -LiteralPath $inboxPath
$thread = Get-Content -Raw -LiteralPath $threadPath
$journeyTest = Get-Content -Raw -LiteralPath $journeyTestPath
$reachable = $widgets + "`n" + $inbox + "`n" + $thread
$blockers = [Collections.Generic.List[string]]::new()

foreach ($token in @(
  'PopScope<Object?>(',
  'Navigator.of(context).canPop()',
  'MoolGlobalNavigationV2(',
  "activeId: 'chat'",
  'context.push(action.route)',
  "context.push('/app/mool?from=chat')",
  "key: const Key('chat-bottom-navigation-stack')"
)) {
  if (-not $widgets.Contains($token)) {
    $blockers.Add("Chat shared navigation contract is missing: $token")
  }
}

foreach ($token in @(
  "key: const PageStorageKey('chat-inbox-scroll')",
  "key: const Key('chat-new')"
)) {
  if (-not $inbox.Contains($token)) {
    $blockers.Add("Chat inbox exact-state contract is missing: $token")
  }
}
if (-not [regex]::IsMatch($inbox, 'context\.push\(\s*chatRoute\(')) {
  $blockers.Add('Chat inbox exact-state contract is missing: context.push(chatRoute(...))')
}

foreach ($token in @(
  'showContentBack: true',
  "key: const Key('chat-back')",
  'bottom: false'
)) {
  if (-not $reachable.Contains($token)) {
    $blockers.Add("Chat thread content-depth contract is missing: $token")
  }
}

foreach ($retired in @(
  "Key('chat-open-mool')",
  "Key('chat-thread-mool')",
  'context.go(chatRoute('
)) {
  if ($reachable.Contains($retired)) {
    $blockers.Add("retired Chat navigation remains reachable: $retired")
  }
}

foreach ($token in @(
  'Chat inbox is one selected global root without top Back',
  'thread Back restores the exact live inbox query and filter',
  'thread draft focus and IME survive a global Buy round trip'
)) {
  if (-not $journeyTest.Contains($token)) {
    $blockers.Add("C10D journey coverage is missing: $token")
  }
}

if ($blockers.Count -gt 0) {
  throw ('C10D Chat global navigation is not implemented: ' + ($blockers -join '; ') + '.')
}

Write-Output 'C10D Chat navigation passed: shared global dock selected; inbox top Back absent; thread depth exact; duplicate Mool launchers contained; draft/IME journeys gated.'
