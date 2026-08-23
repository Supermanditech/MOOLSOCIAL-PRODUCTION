[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C31CContract {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "C31C Chat contract rejected: $Message"
  }
}

function Read-C31CText {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C31CContract -Condition (
    $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "path escaped the repository: $RelativePath"
  Assert-C31CContract -Condition (
    Test-Path -LiteralPath $path -PathType Leaf
  ) -Message "required owner is missing: $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

$ticket = (
  Read-C31CText `
    'config/uaw-c31c-personal-mvp-chat-forward-recipient-continuity-ticket.json'
) | ConvertFrom-Json
Assert-C31CContract -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C31C-PERSONAL-MVP-CHAT-FORWARD-RECIPIENT-CONTINUITY'
) -Message 'ticket identity changed.'
Assert-C31CContract -Condition (
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.backendSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.liveDevDataWriteAuthorized -and
  -not [bool]$ticket.authority.backendOrProviderDeploymentAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket authority boundary changed.'

$state = (Read-C31CText 'config/mvp-scope-gate-state.json') |
  ConvertFrom-Json
$activeTicketId = [string]$state.ticket.id
if ($activeTicketId -ceq [string]$ticket.ticketId) {
  Assert-C31CContract -Condition (
    [bool]$state.execution.runtimeWriteAuthorized -and
    [bool]$state.execution.backendWriteAuthorized -and
    [bool]$state.execution.testOrGateWriteAuthorized -and
    -not [bool]$state.execution.buildAuthorized -and
    -not [bool]$state.execution.deviceInstallAuthorized -and
    -not [bool]$state.execution.externalServiceWriteAuthorized -and
    -not [bool]$state.execution.secretValueAccessAuthorized
  ) -Message 'active C31C execution boundary changed.'
} else {
  $c30xTicketId =
    'UAW-C30X-SUCCESSOR-AAB-PREPARATION-REGRESSION-HARD-GATE'
  $allowedSuccessorTickets = @(
    $c30xTicketId,
    'UAW-C30X-FIX1-SCREEN03-RELEASE-CONFIGURATION-TEST-LOCK-RECONCILIATION',
    'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
  )
  Assert-C31CContract -Condition (
    $allowedSuccessorTickets -ccontains $activeTicketId -and
    -not [bool]$state.execution.runtimeWriteAuthorized -and
    -not [bool]$state.execution.backendWriteAuthorized -and
    [bool]$state.execution.testOrGateWriteAuthorized -and
    (
      -not [bool]$state.execution.buildAuthorized -or
      $activeTicketId -ceq
        'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
    ) -and
    -not [bool]$state.execution.deviceInstallAuthorized -and
    -not [bool]$state.execution.externalServiceWriteAuthorized -and
    -not [bool]$state.execution.secretValueAccessAuthorized
  ) -Message 'C31C has no exact source/gate-only C30X successor.'

  $successor = (
    Read-C31CText 'config/successor-aab-regression-hard-gate-state-c30x.json'
  ) | ConvertFrom-Json
  $predecessor = $successor.chatPredecessorQualification
  $manifestRelative = [string]$predecessor.manifestPath
  $manifestPath = [IO.Path]::GetFullPath((Join-Path $root $manifestRelative))
  Assert-C31CContract -Condition (
    [string]$successor.ticketId -ceq $c30xTicketId -and
    [string]$predecessor.ticketId -ceq [string]$ticket.ticketId -and
    [bool]$predecessor.historicalC31CGateSupersededByC30XTransition -and
    [bool]$predecessor.chatRuntimeBackendTestAndGoldenOwnersMustRemainExact -and
    $manifestPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $manifestPath -PathType Leaf) -and
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash -ceq
      [string]$predecessor.manifestFileSha256
  ) -Message 'C31C successor preservation manifest is missing or changed.'

  $preservedOwners = 0
  foreach ($manifestLine in Get-Content -LiteralPath $manifestPath) {
    if ($manifestLine.StartsWith('#')) { continue }
    $match = [regex]::Match($manifestLine, '^([^|]+)\|([0-9A-F]{64})$')
    Assert-C31CContract -Condition $match.Success `
      -Message 'C31C preservation manifest row is malformed.'
    $relativePath = $match.Groups[1].Value
    if ($relativePath -ceq
      'scripts/check-uaw-c31c-chat-forward-recipient-contract.ps1') {
      continue
    }
    $ownerPath = [IO.Path]::GetFullPath((Join-Path $root $relativePath))
    Assert-C31CContract -Condition (
      $ownerPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and
      (Test-Path -LiteralPath $ownerPath -PathType Leaf) -and
      (Get-FileHash -Algorithm SHA256 -LiteralPath $ownerPath).Hash -ceq
        $match.Groups[2].Value
    ) -Message "C31C preserved owner changed: $relativePath"
    $preservedOwners++
  }
  Assert-C31CContract -Condition (
    $preservedOwners -eq
      [int]$predecessor.preservedOwnerCountExcludingSupersededC31CGate
  ) -Message 'C31C preserved-owner count changed.'
}

$contracts = Read-C31CText 'backend/functions/src/chat/contracts.ts'
$service = Read-C31CText 'backend/functions/src/chat/service.ts'
$store = Read-C31CText 'backend/functions/src/chat/firestore_store.ts'
$index = Read-C31CText 'backend/functions/src/index.ts'
$models = Read-C31CText 'apps/mobile/lib/features/chat/chat_models.dart'
$gateway = Read-C31CText 'apps/mobile/lib/features/chat/chat_services.dart'
$session = Read-C31CText 'apps/mobile/lib/features/chat/chat_session.dart'
$thread = Read-C31CText `
  'apps/mobile/lib/features/chat/screens/chat_thread_screen.dart'
$backendTests = (
  Read-C31CText 'backend/functions/src/chat/service.test.ts'
) + (
  Read-C31CText 'backend/functions/src/chat/firestore_store.test.ts'
)
$flutterTests = Read-C31CText `
  'apps/mobile/test/chat_production_gateway_test.dart'

$messageContractStart = $contracts.IndexOf('export interface ChatMessageRecord')
$messageContractEnd = $contracts.IndexOf(
  'export interface ChatReplyRecord',
  $messageContractStart
)
Assert-C31CContract -Condition (
  $messageContractStart -ge 0 -and $messageContractEnd -gt $messageContractStart
) -Message 'message contract bounds are missing.'
$messageContract = $contracts.Substring(
  $messageContractStart,
  $messageContractEnd - $messageContractStart
)
Assert-C31CContract -Condition (
  $messageContract -match 'forwarded: boolean' -and
  $messageContract -notmatch 'sourceThreadId|sourceMessageId|originalSender|sourceCreatedAt'
) -Message 'public forward marker is missing or exposes source metadata.'
Assert-C31CContract -Condition (
  $contracts -match 'forwardMessage\(' -and
  $service -match 'async forwardMessage\(' -and
  $service -match 'requiredIdentifier\(body, "sourceThreadId"\)' -and
  $service -match 'requiredIdentifier\(body, "sourceMessageId"\)' -and
  $service -match 'requiredIdentifier\(body, "targetThreadId"\)' -and
  $service -match 'sourceThreadId === targetThreadId' -and
  $service -match 'A valid forward retry key is required'
) -Message 'validated idempotent forward service contract is incomplete.'

$forwardStart = $store.IndexOf('  async forwardMessage(')
$forwardEnd = $store.IndexOf('  async setReaction(', $forwardStart)
Assert-C31CContract -Condition (
  $forwardStart -ge 0 -and $forwardEnd -gt $forwardStart
) -Message 'Firestore forward operation bounds are missing.'
$forwardStore = $store.Substring($forwardStart, $forwardEnd - $forwardStart)
Assert-C31CContract -Condition (
  ([regex]::Matches($forwardStore, 'assertParticipant\(').Count -eq 2) -and
  $forwardStore -match 'existing\.get\("requestDigest"\) !== requestDigest' -and
  $forwardStore -match 'Only text messages can be forwarded right now' -and
  $forwardStore -match 'forwarded: true' -and
  $forwardStore -match 'unreadCounts\[participantId\]' -and
  $forwardStore -match 'transaction\.create\(targetMessageRef, messageData\)'
) -Message 'membership, idempotency, text-only, marker or unread persistence is missing.'
$targetDataStart = $forwardStore.LastIndexOf('      messageData = {')
$targetDataEnd = $forwardStore.IndexOf(
  '      transaction.create(targetMessageRef, messageData)',
  $targetDataStart
)
Assert-C31CContract -Condition (
  $targetDataStart -ge 0 -and $targetDataEnd -gt $targetDataStart
) -Message 'target message payload bounds are missing.'
$targetPayload = $forwardStore.Substring(
  $targetDataStart,
  $targetDataEnd - $targetDataStart
)
Assert-C31CContract -Condition (
  $targetPayload -match 'threadId: targetThreadId' -and
  $targetPayload -match 'text,' -and
  $targetPayload -match 'forwarded: true' -and
  $targetPayload -notmatch 'sourceThreadId|sourceMessageId|originalSender|sourceCreatedAt'
) -Message 'target payload exposes source-conversation metadata.'
Assert-C31CContract -Condition (
  $index -match 'operation === "forwardMessage"' -and
  $index -match 'chatService\(\)\.forwardMessage\(ownerUserId, body\)'
) -Message 'authenticated limited-use forward dispatch is missing.'

Assert-C31CContract -Condition (
  $models -match 'final bool forwarded' -and
  $gateway -match "await _invoke\(\s*'forwardMessage'" -and
  $gateway -match 'limitedUseAppCheck: true' -and
  $gateway -match "forwarded: data\['forwarded'\] == true"
) -Message 'Flutter forward model or authenticated gateway is incomplete.'
Assert-C31CContract -Condition (
  $session -match 'List<ChatThread> availableForwardTargets' -and
  $session -match 'thread\.id != sourceThreadId' -and
  $session -match '_forwardRetryKeys\.putIfAbsent' -and
  $session -match 'source\.attachmentLabel != null' -and
  $session -match 'await gateway\.forwardMessage\(' -and
  $session -match 'Message forwarded to \$\{thread\(targetThreadId\)\.title\}'
) -Message 'existing-thread picker, retry ownership or exact completion binding is missing.'
foreach ($controlKey in @(
    'chat-forward-',
    'chat-forwarded-',
    'chat-forward-picker',
    'chat-forward-target-',
    'chat-forward-confirmation',
    'chat-forward-cancel',
    'chat-forward-confirm'
  )) {
  Assert-C31CContract -Condition ($thread.Contains($controlKey)) `
    -Message "accessible forwarding control is missing: $controlKey"
}
Assert-C31CContract -Condition (
  $thread -match 'showModalBottomSheet<ChatThread>' -and
  $thread -match 'showDialog<bool>' -and
  $thread -match 'if \(confirmed == true\)'
) -Message 'recipient confirmation sequence is missing.'
Assert-C31CContract -Condition (
  $backendTests -match 'forward copies exact server text once without source metadata' -and
  $backendTests -match 'forward requires membership in both threads and a text-only source' -and
  $backendTests -match 'binds one confirmed forward to exact source and target conversations'
) -Message 'backend C31C regressions are incomplete.'
Assert-C31CContract -Condition (
  $flutterTests -match 'reuses one forward key after a recoverable failure' -and
  $flutterTests -match 'forward picker excludes source and requires confirmation' -and
  $flutterTests -match 'read outbound message keeps reply and reaction actions'
) -Message 'Flutter C31C or predecessor regressions are incomplete.'

foreach ($goldenRelativePath in @(
    'apps/mobile/test/goldens/chat-c31c-022-provider-support-forward-action-412x915.png',
    'apps/mobile/test/goldens/chat-c31c-024-provider-business-read-forward-action-412x915.png',
    'apps/mobile/test/goldens/chat-c31c-025-provider-people-forward-action-412x915.png',
    'apps/mobile/test/goldens/chat-c31c-024-provider-business-forwarded-412x915.png'
  )) {
  $goldenPath = Join-Path $root $goldenRelativePath
  Assert-C31CContract -Condition (
    Test-Path -LiteralPath $goldenPath -PathType Leaf
  ) -Message "C31C forward golden is missing: $goldenRelativePath"
}

$validatedBuildAuthorityLabel = (
  [bool]$state.execution.buildAuthorized
).ToString().ToLowerInvariant()
Write-Output (
  'C31C Chat forwarding contract passed: routes=0; screens=0; ' +
  'backendOwners=0; sourceMetadataExposed=false; confirmation=true; ' +
  'liveWrites=false; deployment=false; build=' +
  $validatedBuildAuthorityLabel + '; device=false.'
)
