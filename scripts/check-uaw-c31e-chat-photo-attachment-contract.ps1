[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C31EContract {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "C31E Chat photo contract rejected: $Message"
  }
}

function Resolve-C31EPath {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C31EContract -Condition (
    $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "path escaped the repository: $RelativePath"
  Assert-C31EContract -Condition (
    Test-Path -LiteralPath $path -PathType Leaf
  ) -Message "required owner is missing: $RelativePath"
  return $path
}

function Read-C31EText {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  return Get-Content -Raw -LiteralPath (Resolve-C31EPath $RelativePath)
}

$ticketRelative =
  'config/uaw-c31e-personal-mvp-chat-photo-attachment-continuity-ticket.json'
$ticketPath = Resolve-C31EPath $ticketRelative
$ticket = (Get-Content -Raw -LiteralPath $ticketPath) | ConvertFrom-Json
Assert-C31EContract -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '419922E66AEEC63D7A871C534DFE61D0D92FBB875FD258F880D38E5C1848CFA5'
) -Message 'ticket identity, classification or sealed selection hash changed.'
Assert-C31EContract -Condition (
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.backendSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.referenceWriteAuthorized -and
  -not [bool]$ticket.authority.liveDevDataWriteAuthorized -and
  -not [bool]$ticket.authority.backendOrProviderDeploymentAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized -and
  -not [bool]$ticket.authority.externalCommunicationAuthorized
) -Message 'ticket authority boundary changed.'
Assert-C31EContract -Condition (
  @($ticket.reuse.newScreens).Count -eq 0 -and
  @($ticket.reuse.newRoutes).Count -eq 0 -and
  @($ticket.reuse.newBackendOwners).Count -eq 0
) -Message 'ticket silently added a route, screen or backend service owner.'

$state = (
  Read-C31EText 'config/chat-full-module-gate-state-c31e.json'
) | ConvertFrom-Json
Assert-C31EContract -Condition (
  [string]$state.ticketId -ceq [string]$ticket.ticketId -and
  [string]$state.repository.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repository.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [int]$state.scope.newRoutes -eq 0 -and
  [int]$state.scope.newScreens -eq 0 -and
  [int]$state.scope.newFunctionServices -eq 0 -and
  [int]$state.scope.newTopLevelFirestoreCollections -eq 0 -and
  [int]$state.scope.maximumPhotoBytes -eq 4194304 -and
  [int]$state.scope.signedUrlMaximumSeconds -eq 300
) -Message 'machine identity or bounded scope changed.'
Assert-C31EContract -Condition (
  [bool]$state.authority.runtimeSourceWriteAuthorized -and
  [bool]$state.authority.backendSourceWriteAuthorized -and
  [bool]$state.authority.testAndGateWriteAuthorized -and
  -not [bool]$state.authority.referenceWriteAuthorized -and
  -not [bool]$state.authority.liveDevDataWriteAuthorized -and
  -not [bool]$state.authority.backendDeploymentAuthorized -and
  -not [bool]$state.authority.storageRulesCorsLifecycleOrIamMutationAuthorized -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.PlayUploadOrActivationAuthorized -and
  -not [bool]$state.authority.deviceMutationAuthorized -and
  -not [bool]$state.authority.secretValueAccessAuthorized -and
  -not [bool]$state.authority.externalCommunicationAuthorized -and
  [string]$state.protectedReleaseState.r60_48BuildUploadInstallCounts -ceq
    '1/1/1' -and
  [string]$state.protectedReleaseState.r60_48RuntimeState -ceq
    'failed_social_auth_and_action_journey_acceptance' -and
  -not [bool]$state.protectedReleaseState.successorAabAuthorized
) -Message 'machine authority or failed r60.48 release truth changed.'

$mvp = (Read-C31EText 'config/mvp-scope-gate-state.json') |
  ConvertFrom-Json
Assert-C31EContract -Condition (
  [string]$mvp.ticket.id -ceq [string]$ticket.ticketId -and
  [string]$mvp.ticket.classification -ceq 'mvp_required' -and
  [string]$mvp.preTicketSelectionCheckpoint.currentTicketId -ceq
    [string]$ticket.ticketId -and
  [bool]$mvp.execution.runtimeWriteAuthorized -and
  [bool]$mvp.execution.backendWriteAuthorized -and
  [bool]$mvp.execution.testOrGateWriteAuthorized -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized -and
  -not [bool]$mvp.execution.externalServiceWriteAuthorized -and
  -not [bool]$mvp.execution.secretValueAccessAuthorized
) -Message 'MVP selection or execution boundary changed.'

$c31cState = (
  Read-C31EText 'config/chat-full-module-gate-state-c31c.json'
) | ConvertFrom-Json
$c31cManifestRelative = [string]$c31cState.sourceManifest.path
$c31cManifest = Read-C31EText $c31cManifestRelative
Assert-C31EContract -Condition (
  [string]$state.predecessor.ticketId -ceq [string]$c31cState.ticketId -and
  [string]$state.predecessor.historicalManifestSha256 -ceq
    [string]$c31cState.sourceManifest.sha256 -and
  [bool]$state.predecessor.C30TThroughC31CRegressionsMustRemainPreserved -and
  $c31cManifest.Contains(
    '# Manifest fingerprint: 0A8A2142DB52D737185A0D384CA65E1EDF8D2862CDE40DF69458299D10CEE43F'
  )
) -Message 'sealed C31C predecessor identity changed.'

$contracts = Read-C31EText 'backend/functions/src/chat/contracts.ts'
$attachmentStore = Read-C31EText `
  'backend/functions/src/chat/attachment_store.ts'
$service = Read-C31EText 'backend/functions/src/chat/service.ts'
$store = Read-C31EText 'backend/functions/src/chat/firestore_store.ts'
$index = Read-C31EText 'backend/functions/src/index.ts'
$models = Read-C31EText 'apps/mobile/lib/features/chat/chat_models.dart'
$gateway = Read-C31EText 'apps/mobile/lib/features/chat/chat_services.dart'
$session = Read-C31EText 'apps/mobile/lib/features/chat/chat_session.dart'
$thread = Read-C31EText `
  'apps/mobile/lib/features/chat/screens/chat_thread_screen.dart'
$attachmentTests = Read-C31EText `
  'backend/functions/src/chat/attachment_store.test.ts'
$backendTests = (
  Read-C31EText 'backend/functions/src/chat/service.test.ts'
) + (
  Read-C31EText 'backend/functions/src/chat/firestore_store.test.ts'
)
$flutterTests = (
  Read-C31EText 'apps/mobile/test/chat_photo_attachment_test.dart'
) + (
  Read-C31EText 'apps/mobile/test/chat_production_gateway_test.dart'
) + (
  Read-C31EText 'apps/mobile/test/chat_flow_test.dart'
)

foreach ($required in @(
    'replyTo?: ChatReplyRecord',
    'reactionCount: number',
    'readCount: number',
    'forwarded: boolean',
    'photo?: ChatPhotoAttachmentRecord',
    'preparePhotoUpload(',
    'sendPhotoMessage('
  )) {
  Assert-C31EContract -Condition ($contracts.Contains($required)) `
    -Message "backend Chat contract is missing $required."
}
$publicPhotoStart = $contracts.IndexOf(
  'export interface ChatPhotoAttachmentRecord'
)
$publicPhotoEnd = $contracts.IndexOf(
  'export type ChatPhotoContentType',
  $publicPhotoStart
)
Assert-C31EContract -Condition (
  $publicPhotoStart -ge 0 -and $publicPhotoEnd -gt $publicPhotoStart
) -Message 'public photo response contract bounds are missing.'
$publicPhoto = $contracts.Substring(
  $publicPhotoStart,
  $publicPhotoEnd - $publicPhotoStart
)
Assert-C31EContract -Condition (
  $publicPhoto.Contains('readUrl: string') -and
  $publicPhoto.Contains('readUrlExpiresAt: string') -and
  $publicPhoto -notmatch 'objectPath|generation|owner|thread|binding|signature'
) -Message 'public photo response exposes private Storage binding state.'

foreach ($required in @(
    'CHAT_PHOTO_MAX_BYTES = 4 * 1024 * 1024',
    'CHAT_PHOTO_SIGNED_URL_SECONDS = 300',
    'randomUUID()',
    'action: "write"',
    'action: "read"',
    'version: "v4"',
    '"x-goog-if-generation-match": "0"',
    '"x-goog-meta-moolsocial-owner"',
    '"x-goog-meta-moolsocial-thread"',
    '"x-goog-meta-moolsocial-name"',
    'matchesFileSignature',
    'return `chat-private/v1/${uploadId}`'
  )) {
  Assert-C31EContract -Condition ($attachmentStore.Contains($required)) `
    -Message "private Storage adapter is missing $required."
}
Assert-C31EContract -Condition (
  $attachmentStore -notmatch
    'firebaseStorageDownloadTokens|getDownloadURL|makePublic|publicUrl'
) -Message 'private Chat adapter introduced a persistent public URL path.'

Assert-C31EContract -Condition (
  $service -match 'async preparePhotoUpload\(' -and
  $service -match 'async sendPhotoMessage\(' -and
  $service -match 'optionalIdentifier\(body, "replyToMessageId"\)' -and
  $service -match 'createHash\("sha256"\)' -and
  $store -match 'await this\.threadForParticipant\(actor\.userId, threadId\)' -and
  $store -match '\.collection\("attachmentReceipts"\)' -and
  $store -match 'transaction\.create\(receiptRef' -and
  $store -match 'messageReplyPreview\(replyData\)' -and
  $store -match 'const messageType = String\(sourceData\.messageType' -and
  $store -match 'messageType !== "text"' -and
  $store -match 'Only text messages can be forwarded right now' -and
  $store -match 'private async publicMessage' -and
  $store -match 'this\.requirePhotoStore\(\)\.readUrl' -and
  $index -match 'new GoogleCloudStorageChatPhotoStore\(getStorage\(\)\.bucket\(\)\)' -and
  $index -match 'operation === "preparePhotoUpload"' -and
  $index -match 'operation === "sendPhotoMessage"' -and
  $index -match 'const mutation = operation === "createDirectThread"'
) -Message 'membership, one-time finalize, reply, forward exclusion or dispatch is missing.'

Assert-C31EContract -Condition (
  $models.Contains('class ChatPhotoAttachment') -and
  $models.Contains('final ChatPhotoAttachment? photo') -and
  $gateway.Contains('class NativeChatPhotoPicker implements ChatPhotoPicker') -and
  $gateway.Contains('class AuthenticatedChatGateway implements ChatGateway, ChatPhotoGateway') -and
  $gateway.Contains("'preparePhotoUpload'") -and
  $gateway.Contains("'sendPhotoMessage'") -and
  $gateway.Contains("'x-goog-if-generation-match'") -and
  $gateway.Contains('_requirePrivateStorageUrl') -and
  $session.Contains('Future<bool> recoverInterruptedPhotoSelection') -and
  $session.Contains('Future<bool> sendSelectedPhoto') -and
  $session.Contains('List<ChatMessage>.of(loaded)') -and
  $session.Contains('source.photo != null') -and
  $session.Contains('_pendingPhotos[threadId]') -and
  $thread.Contains("key: const Key('chat-attach')") -and
  $thread.Contains("key: const Key('chat-gallery')") -and
  $thread.Contains("key: const Key('chat-camera')") -and
  $thread.Contains("'chat-send-photo'") -and
  $thread.Contains("Key('chat-photo-refresh-") -and
  $thread.Contains('Image.memory(') -and
  $thread.Contains('Image.network(') -and
  $thread.Contains('message.photo == null')
) -Message 'Flutter staging, retry, rendering or forward exclusion is missing.'

foreach ($testName in @(
    'prepares one exact create-only private upload without identity in its path',
    'validates signed metadata size generation and PNG signature',
    'rejects a wrong owner binding and a corrupt file signature',
    'issues a five-minute read URL for only the opaque generation-bound object'
  )) {
  Assert-C31EContract -Condition ($attachmentTests.Contains($testName)) `
    -Message "attachment-store regression is missing: $testName"
}
foreach ($testName in @(
    'photo prepare proves membership before issuing a private upload grant',
    'photo finalize is idempotent private and increments unread once',
    'one uploaded photo cannot be consumed by a second message',
    'prepares only one bounded supported photo upload for a verified actor',
    'finalizes a photo with one request digest and optional caption'
  )) {
  Assert-C31EContract -Condition ($backendTests.Contains($testName)) `
    -Message "backend photo regression is missing: $testName"
}
foreach ($testName in @(
    'authenticated photo send prepares, uploads and finalizes once',
    'finalize retry reuses one staged upload and idempotency key',
    'upload failure retries one grant before finalize',
    'session retains photo, caption, reply and one key through failed send',
    'interrupted selection stages a photo without sending it',
    'cancel is non-mutating and camera stages only after confirmation',
    'photo source stages, confirms, sends and renders in thread',
    'late photo completion stays with its originating thread',
    'preserves exact reply context through failed-send retry',
    'reuses one forward key after a recoverable failure',
    'supports reply and reaction while excluded actions stay absent'
  )) {
  Assert-C31EContract -Condition ($flutterTests.Contains($testName)) `
    -Message "Flutter Chat regression is missing: $testName"
}

Write-Output (
  'C31E Chat photo contract passed: routes=0; screens=0; backendOwners=0; ' +
  'private=true; signedUrlSeconds=300; liveWrites=false; deployment=false; ' +
  'build=false; device=false.'
)
