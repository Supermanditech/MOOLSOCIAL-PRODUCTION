[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C31AContract {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "C31A Chat contract rejected: $Message"
  }
}

function Read-RepositoryText {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C31AContract -Condition (
    $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "path escaped the repository: $RelativePath"
  Assert-C31AContract -Condition (
    Test-Path -LiteralPath $path -PathType Leaf
  ) -Message "required owner is missing: $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

$ticketText = Read-RepositoryText `
  'config/uaw-c31a-personal-mvp-chat-reply-reaction-continuity-ticket.json'
$ticket = $ticketText | ConvertFrom-Json
Assert-C31AContract -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C31A-PERSONAL-MVP-CHAT-REPLY-REACTION-CONTINUITY'
) -Message 'ticket identity changed.'
Assert-C31AContract -Condition (
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.backendSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.liveDevDataWriteAuthorized -and
  -not [bool]$ticket.authority.backendOrProviderDeploymentAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket authority boundary changed.'

$state = (
  Read-RepositoryText 'config/mvp-scope-gate-state.json'
) | ConvertFrom-Json
$activeTicketId = [string]$state.ticket.id
$isOriginalTicket = $activeTicketId -ceq [string]$ticket.ticketId
$isRecordedSuccessor = $false
$isRecordedDescendant = $false
if (-not $isOriginalTicket) {
  $qualifiedState = (
    Read-RepositoryText 'config/chat-full-module-gate-state-c31a.json'
  ) | ConvertFrom-Json
  $isRecordedSuccessor = (
    [string]$qualifiedState.ticketId -ceq [string]$ticket.ticketId -and
    [string]$qualifiedState.sourceSuccessor.ticketId -ceq $activeTicketId -and
    [bool]$qualifiedState.sourceSuccessor.sharedOwnerMutationMustPreserveC31ARegressions
  )
  if (-not $isRecordedSuccessor) {
    $successorState = (
      Read-RepositoryText 'config/chat-full-module-gate-state-c31b.json'
    ) | ConvertFrom-Json
    $isRecordedDescendant = (
      [string]$qualifiedState.ticketId -ceq [string]$ticket.ticketId -and
      [string]$qualifiedState.sourceSuccessor.ticketId -ceq
        [string]$successorState.ticketId -and
      [bool]$qualifiedState.sourceSuccessor.sharedOwnerMutationMustPreserveC31ARegressions -and
      [string]$successorState.sourceSuccessor.ticketId -ceq $activeTicketId -and
      [bool]$successorState.sourceSuccessor.sharedOwnerMutationMustPreserveC31BRegressions
    )
  }
}
Assert-C31AContract -Condition (
  ($isOriginalTicket -or $isRecordedSuccessor -or $isRecordedDescendant) -and
  [bool]$state.execution.runtimeWriteAuthorized -and
  [bool]$state.execution.backendWriteAuthorized -and
  [bool]$state.execution.testOrGateWriteAuthorized -and
  -not [bool]$state.execution.buildAuthorized -and
  -not [bool]$state.execution.deviceInstallAuthorized -and
  -not [bool]$state.execution.externalServiceWriteAuthorized -and
  -not [bool]$state.execution.secretValueAccessAuthorized
) -Message 'machine execution boundary changed.'

$contracts = Read-RepositoryText 'backend/functions/src/chat/contracts.ts'
$service = Read-RepositoryText 'backend/functions/src/chat/service.ts'
$store = Read-RepositoryText 'backend/functions/src/chat/firestore_store.ts'
$index = Read-RepositoryText 'backend/functions/src/index.ts'
$models = Read-RepositoryText 'apps/mobile/lib/features/chat/chat_models.dart'
$gateway = Read-RepositoryText 'apps/mobile/lib/features/chat/chat_services.dart'
$session = Read-RepositoryText 'apps/mobile/lib/features/chat/chat_session.dart'
$thread = Read-RepositoryText `
  'apps/mobile/lib/features/chat/screens/chat_thread_screen.dart'
$backendTests = (
  Read-RepositoryText 'backend/functions/src/chat/service.test.ts'
) + (
  Read-RepositoryText 'backend/functions/src/chat/firestore_store.test.ts'
)
$flutterTests = (
  Read-RepositoryText 'apps/mobile/test/chat_flow_test.dart'
) + (
  Read-RepositoryText 'apps/mobile/test/chat_production_gateway_test.dart'
)

foreach ($required in @(
    'replyTo\?: ChatReplyRecord',
    'reactionCount: number',
    'reactedByMe: boolean',
    'setReaction\('
  )) {
  Assert-C31AContract -Condition ($contracts -match $required) `
    -Message "backend contract is missing $required."
}
Assert-C31AContract -Condition (
  $service -match 'requiredIdentifier\(body, "threadId"\)' -and
  $service -match 'optionalIdentifier\(body, "replyToMessageId"\)' -and
  $service -match '\^\[A-Za-z0-9\]\[A-Za-z0-9\._-\]'
) -Message 'path-safe Chat identifiers are not enforced.'
Assert-C31AContract -Condition (
  $store -match 'replyToMessageId' -and
  $store -match 'replyPreview' -and
  $store -match 'reactions\[actor\.userId\] = true' -and
  $store -match 'delete reactions\[actor\.userId\]' -and
  $store -match 'reactionCount: Object\.values\(reactions\)'
) -Message 'Firestore reply or privacy-bounded reaction persistence is missing.'
Assert-C31AContract -Condition (
  $index -match 'operation === "setReaction"' -and
  $index -match 'chatService\(\)\.setReaction\(ownerUserId, body\)'
) -Message 'authenticated Chat operation dispatch is missing.'

foreach ($required in @(
    'class ChatReplyReference',
    'final bool reactedByMe',
    'final ChatReplyReference\? replyTo'
  )) {
  Assert-C31AContract -Condition ($models -match $required) `
    -Message "Flutter Chat model is missing $required."
}
Assert-C31AContract -Condition (
  $gateway -match "await _invoke\(\s*'setReaction'" -and
  $gateway -match "'replyToMessageId': \?replyToMessageId" -and
  $gateway -match 'limitedUseAppCheck: true'
) -Message 'authenticated Flutter reply or reaction gateway is missing.'
Assert-C31AContract -Condition (
  $session -match 'Future<bool> toggleReaction' -and
  $session -match 'bool startReply' -and
  $session -match '_replyTargets\[threadId\]\?\.id == selectedReply\?\.messageId'
) -Message 'thread-isolated Chat session behavior is missing.'
foreach ($controlKey in @(
    'chat-reply-',
    'chat-react-',
    'chat-composer-reply-context',
    'chat-cancel-reply'
  )) {
  Assert-C31AContract -Condition ($thread.Contains($controlKey)) `
    -Message "accessible Chat control is missing: $controlKey"
}
Assert-C31AContract -Condition (
  $backendTests -match 'immutable same-thread reply preview' -and
  $backendTests -match 'idempotent and privacy bounded' -and
  $backendTests -match 'rejects Firestore path syntax'
) -Message 'backend C31A regressions are incomplete.'
Assert-C31AContract -Condition (
  $flutterTests -match 'preserves exact reply context through failed-send retry' -and
  $flutterTests -match 'persists authenticated reaction set and clear' -and
  $flutterTests -match 'supports reply and reaction while excluded actions stay absent'
) -Message 'Flutter C31A regressions are incomplete.'

Write-Output (
  'C31A Chat reply/reaction contract passed: routes=0; screens=0; ' +
  'backendOwners=0; liveWrites=false; deployment=false; build=false; device=false.'
)
