[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C31BContract {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "C31B Chat contract rejected: $Message"
  }
}

function Read-C31BText {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C31BContract -Condition (
    $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "path escaped the repository: $RelativePath"
  Assert-C31BContract -Condition (
    Test-Path -LiteralPath $path -PathType Leaf
  ) -Message "required owner is missing: $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

$ticket = (
  Read-C31BText `
    'config/uaw-c31b-personal-mvp-chat-unread-read-receipt-continuity-ticket.json'
) | ConvertFrom-Json
Assert-C31BContract -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C31B-PERSONAL-MVP-CHAT-UNREAD-READ-RECEIPT-CONTINUITY'
) -Message 'ticket identity changed.'
Assert-C31BContract -Condition (
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.backendSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.liveDevDataWriteAuthorized -and
  -not [bool]$ticket.authority.backendOrProviderDeploymentAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket authority boundary changed.'

$state = (Read-C31BText 'config/mvp-scope-gate-state.json') |
  ConvertFrom-Json
$activeTicketId = [string]$state.ticket.id
$isOriginalTicket = $activeTicketId -ceq [string]$ticket.ticketId
$isRecordedSuccessor = $false
if (-not $isOriginalTicket) {
  $qualifiedState = (
    Read-C31BText 'config/chat-full-module-gate-state-c31b.json'
  ) | ConvertFrom-Json
  $isRecordedSuccessor = (
    [string]$qualifiedState.ticketId -ceq [string]$ticket.ticketId -and
    [string]$qualifiedState.sourceSuccessor.ticketId -ceq $activeTicketId -and
    [bool]$qualifiedState.sourceSuccessor.sharedOwnerMutationMustPreserveC31BRegressions
  )
}
Assert-C31BContract -Condition (
  ($isOriginalTicket -or $isRecordedSuccessor) -and
  [bool]$state.execution.runtimeWriteAuthorized -and
  [bool]$state.execution.backendWriteAuthorized -and
  [bool]$state.execution.testOrGateWriteAuthorized -and
  -not [bool]$state.execution.buildAuthorized -and
  -not [bool]$state.execution.deviceInstallAuthorized -and
  -not [bool]$state.execution.externalServiceWriteAuthorized -and
  -not [bool]$state.execution.secretValueAccessAuthorized
) -Message 'machine execution boundary changed.'

$contracts = Read-C31BText 'backend/functions/src/chat/contracts.ts'
$service = Read-C31BText 'backend/functions/src/chat/service.ts'
$store = Read-C31BText 'backend/functions/src/chat/firestore_store.ts'
$index = Read-C31BText 'backend/functions/src/index.ts'
$models = Read-C31BText 'apps/mobile/lib/features/chat/chat_models.dart'
$gateway = Read-C31BText 'apps/mobile/lib/features/chat/chat_services.dart'
$session = Read-C31BText 'apps/mobile/lib/features/chat/chat_session.dart'
$thread = Read-C31BText `
  'apps/mobile/lib/features/chat/screens/chat_thread_screen.dart'
$backendTests = (
  Read-C31BText 'backend/functions/src/chat/service.test.ts'
) + (
  Read-C31BText 'backend/functions/src/chat/firestore_store.test.ts'
)
$flutterTests = Read-C31BText `
  'apps/mobile/test/chat_production_gateway_test.dart'

Assert-C31BContract -Condition (
  $contracts -match 'readCount: number' -and
  $contracts -match 'readByOthers: boolean' -and
  $contracts -match 'markThreadRead\(userId: string, threadId: string\)' -and
  $contracts -match 'interface ChatReadResult'
) -Message 'aggregate backend read contract is incomplete.'
$messageContractStart = $contracts.IndexOf('export interface ChatMessageRecord')
$messageContractEnd = $contracts.IndexOf(
  'export interface ChatReplyRecord',
  $messageContractStart
)
Assert-C31BContract -Condition (
  $messageContractStart -ge 0 -and $messageContractEnd -gt $messageContractStart
) -Message 'message contract bounds are missing.'
$messageContract = $contracts.Substring(
  $messageContractStart,
  $messageContractEnd - $messageContractStart
)
Assert-C31BContract -Condition (
  $messageContract -notmatch 'readerId|readerIds|readAt|lastReadAt'
) -Message 'public message contract exposes private reader identity or timestamps.'
Assert-C31BContract -Condition (
  $service -match 'async markThreadRead' -and
  $service -match 'requiredIdentifier\(body, "threadId"\)'
) -Message 'validated async mark-read service operation is missing.'
Assert-C31BContract -Condition (
  $store -match 'unreadCounts\[participantId\]' -and
  $store -match 'lastReadAtBy\[actor\.userId\] = createdAt' -and
  $store -match 'unreadCounts\[userId\] = 0' -and
  $store -match 'readCount' -and
  $store -match 'readByOthers: readCount > 0'
) -Message 'private unread/read persistence or aggregate derivation is missing.'
Assert-C31BContract -Condition (
  $index -match 'operation === "markThreadRead"' -and
  $index -match 'chatService\(\)\.markThreadRead\(ownerUserId, body\)'
) -Message 'authenticated mark-read dispatch is missing.'

Assert-C31BContract -Condition (
  $models -match 'ChatDeliveryState \{ sending, delivered, read, failed \}' -and
  $models -match 'bool get isSettled' -and
  $models -match 'final int readCount'
) -Message 'Flutter read-state model is incomplete.'
Assert-C31BContract -Condition (
  $gateway -match "await _invoke\(\s*'markThreadRead'" -and
  $gateway -match 'limitedUseAppCheck: true' -and
  $gateway -match 'data\[''readByOthers''\] == true'
) -Message 'authenticated Flutter read gateway is incomplete.'
Assert-C31BContract -Condition (
  $session -match 'Future<bool> markRead' -and
  $session -match 'await gateway\.markThreadRead\(threadId: threadId\)' -and
  $thread -match 'if \(loaded\) await session\.markRead\(threadId\)' -and
  $thread -match 'ChatDeliveryState\.read => Icons\.done_all_rounded'
) -Message 'route-owned read acknowledgement or presentation is missing.'
Assert-C31BContract -Condition (
  $backendTests -match 'unread counts and aggregate read state are idempotent and private' -and
  $backendTests -match 'legacy threads without read maps decode as zero unread and delivered' -and
  $backendTests -match 'marks only one validated authenticated thread as read'
) -Message 'backend C31B regressions are incomplete.'
Assert-C31BContract -Condition (
  $flutterTests -match 'acknowledges one thread read and clears its unread overlay' -and
  $flutterTests -match 'read outbound message keeps reply and reaction actions' -and
  $flutterTests -match 'gateway\.readThreads, \[''thread-new''\]'
) -Message 'Flutter C31B regressions are incomplete.'

$goldenPath = Join-Path $root `
  'apps/mobile/test/goldens/chat-c31b-024-provider-business-read-412x915.png'
Assert-C31BContract -Condition (
  Test-Path -LiteralPath $goldenPath -PathType Leaf
) -Message 'C31B read-state golden is missing.'

Write-Output (
  'C31B Chat unread/read contract passed: routes=0; screens=0; ' +
  'backendOwners=0; readerIdentityExposed=false; liveWrites=false; ' +
  'deployment=false; build=false; device=false.'
)
