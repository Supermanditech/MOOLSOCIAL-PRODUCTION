[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29P([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29P source gate rejected: $Message" }
}

function Resolve-C29PFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29P ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29P (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29PContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29PFile $RelativePath)
}

function Assert-C29PContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29PContent $RelativePath
  Assert-C29P ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29PNotContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29PContent $RelativePath
  Assert-C29P (-not $content.Contains($Text, [StringComparison]::Ordinal)) "forbidden contract found in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-FEED-CREATE-AUTHENTICATED-PERSISTENCE-C29P'
$ticketPath = Resolve-C29PFile 'config/uaw-personal-mvp-social-feed-create-persistence-c29p-ticket.json'
$scopePath = Resolve-C29PFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29PFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29P ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29P ([string]$ticket.state -cin @('selected_source_implementation_authorized', 'source_qualified_external_dev_deploy_and_oppo_pending')) 'ticket state is not source-only'
Assert-C29P ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29P ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29P ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29P ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29P ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29P ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/evidence authority is closed'
Assert-C29P ([bool]$scope.execution.backendWriteAuthorized) 'backend source authority is closed'
Assert-C29P ([bool]$ticket.execution.runtimeSourceWriteAuthorized) 'ticket runtime source authority is closed'
Assert-C29P ([bool]$ticket.execution.testOrGateWriteAuthorized) 'ticket test authority is closed'
Assert-C29P ([bool]$ticket.execution.backendSourceWriteAuthorized) 'ticket backend source authority is closed'

foreach ($closed in @(
  [bool]$scope.execution.referenceWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.externalDevQualificationAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.deployAuthorized,
  [bool]$ticket.execution.productionWriteAuthorized,
  [bool]$ticket.execution.providerMessageAuthorized,
  [bool]$ticket.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.referenceWriteAuthorized
)) {
  Assert-C29P (-not $closed) 'build/install/deploy/external/secret/reference authority opened'
}

Assert-C29P ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29P ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29P ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29P ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29P ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29P (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29P (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29P (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'

$contracts = 'backend/functions/src/social/contracts.ts'
$service = 'backend/functions/src/social/service.ts'
$security = 'backend/functions/src/social/request_security.ts'
$store = 'backend/functions/src/social/firestore_store.ts'
$index = 'backend/functions/src/index.ts'
$gateway = 'apps/mobile/lib/features/shared/social_content_gateway.dart'
$session = 'apps/mobile/lib/features/shared/shared_session.dart'
$consumer = 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$content = 'apps/mobile/lib/ui_v2/social/social_v2_public_content.dart'

Assert-C29PContains $contracts '"imagePoll",'
Assert-C29PContains $contracts '"quickPoll",'
Assert-C29PNotContains $contracts '"reel"'
Assert-C29PContains $security 'App verification is required.'
Assert-C29PContains $security 'Sign in to continue.'
Assert-C29PContains $security 'if (consumeAppCheck && verified.alreadyConsumed)'
Assert-C29PContains $service 'const maximumTotalMediaBytes = 20 * 1024 * 1024;'
Assert-C29PContains $service 'mediaMatchesContentType(bytes, contentType)'
Assert-C29PContains $service 'throw badRequest("Image bytes do not match the selected image format.");'
Assert-C29PContains $store 'this.firestore.runTransaction'
Assert-C29PContains $store 'socialPublishIdempotency'
Assert-C29PContains $store 'social-media/${userId}/${postId}/'
Assert-C29PContains $store 'await this.removeMedia(media);'
Assert-C29PContains $store 'export function isValidSocialFeedCursor'
Assert-C29PContains $store 'socialPostInteractions'
Assert-C29PContains $index 'export const moolSocialContent = onRequest('
Assert-C29PContains $index 'social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
Assert-C29PContains $index 'request.rawBody.byteLength > 29 * 1024 * 1024'
Assert-C29PContains $index 'verifySocialInvocation('
Assert-C29PContains $index 'errorType: error instanceof Error ? error.name : typeof error'

Assert-C29PContains 'firebase.json' '"rules": "backend/storage/moolsocial-private-dev.rules"'
Assert-C29PContains 'firebase.json' '"host": "127.0.0.1"'
Assert-C29PContains 'firebase.json' '"port": 8080'
Assert-C29PContains 'firebase.json' '"port": 9199'
Assert-C29PContains 'firebase.json' '"src/**/*.emulator.ts"'
Assert-C29PContains 'backend/firestore/youtube-private-dev.rules' 'allow read, write: if false;'
Assert-C29PContains 'backend/storage/moolsocial-private-dev.rules' 'allow read, write: if false;'
Assert-C29PContains 'backend/functions/package.json' '"test:emulator:social": "npm run build && node --test lib/social/firebase_rules.emulator.js"'
Assert-C29PContains 'backend/functions/package.json' '"@firebase/rules-unit-testing": "5.0.1"'
Assert-C29PContains 'backend/functions/package.json' '"brace-expansion": "5.0.9"'

Assert-C29PContains $gateway "'MOOLSOCIAL_SOCIAL_CONTENT_URL'"
Assert-C29PContains $gateway 'return const UnavailableSocialContentGateway();'
Assert-C29PContains $gateway 'class AuthenticatedSocialContentGateway implements SocialContentGateway'
Assert-C29PContains $gateway "const requiredHost = 'asia-south1-moolsocial-dev-503018.cloudfunctions.net';"
Assert-C29PContains $gateway "endpoint.path != '/moolSocialContent'"
Assert-C29PContains $gateway 'SocialAppCheckTokenMode.limitedUse'
Assert-C29PContains $gateway 'await _appCheck.getLimitedUseToken()'
Assert-C29PContains $gateway "'sha256': sha256.convert(bytes).toString(),"
Assert-C29PContains $gateway "'One selected image is no longer available. Choose it again.',"
Assert-C29PNotContains $gateway 'class ReviewSocialContentGateway'
Assert-C29PContains $session 'socialContentGateway ?? buildSocialContentGateway()'
Assert-C29PContains $session 'Future<bool> loadSocialFeed({bool refresh = false}) async'
Assert-C29PContains $session 'final item = await _socialContentGateway.publish('
Assert-C29PContains $session '_upsertSocialItem(item);'
Assert-C29PContains $session 'MoolSocial does not host Shorts or Reels.'
Assert-C29PContains $session "errorMessage = '`$action is not available yet. Nothing changed.';"
Assert-C29PContains $consumer 'session.loadSocialFeed(refresh: true)'
Assert-C29PContains $consumer 'onReply: _explainMoolSocialReplyGate'
Assert-C29PContains $content 'return Image.network('
Assert-C29PContains $content "session.rejectUnsupportedSocialInteraction('Repost')"

$sessionSource = Get-C29PContent $session
$ackIndex = $sessionSource.IndexOf('final item = await _socialContentGateway.publish(', [StringComparison]::Ordinal)
$insertIndex = $sessionSource.IndexOf('_upsertSocialItem(item);', $ackIndex, [StringComparison]::Ordinal)
Assert-C29P ($ackIndex -ge 0 -and $insertIndex -gt $ackIndex) 'local Feed mutation can precede server acknowledgement'

foreach ($requiredTest in @(
  'backend/functions/src/social/service.test.ts',
  'backend/functions/src/social/request_security.test.ts',
  'backend/functions/src/social/firestore_store.test.ts',
  'backend/functions/src/social/firebase_rules.emulator.ts',
  'apps/mobile/test/social_content_authenticated_gateway_test.dart',
  'apps/mobile/test/social_v2_create_publication_test.dart',
  'apps/mobile/test/social_v2_moolsocial_feed_ownership_test.dart',
  'apps/mobile/test/support/review_social_content_gateway.dart'
)) {
  [void](Resolve-C29PFile $requiredTest)
}
Assert-C29PContains 'backend/functions/src/social/firestore_store.test.ts' 'an idempotency race keeps the committed post media'
Assert-C29PContains 'backend/functions/src/social/firestore_store.test.ts' 'a recovered conflicting idempotency commit removes the rejected upload'
Assert-C29PContains 'backend/functions/src/social/firebase_rules.emulator.ts' 'direct signed-in and signed-out Firestore clients cannot access Social content'
Assert-C29PContains 'backend/functions/src/social/firebase_rules.emulator.ts' 'direct signed-in and signed-out Storage clients cannot access Social media'
Assert-C29PContains 'apps/mobile/test/social_content_authenticated_gateway_test.dart' 'SharedSession keeps content local until server acknowledgement'
Assert-C29PContains 'apps/mobile/test/social_content_authenticated_gateway_test.dart' 'SharedSession reuses its idempotency key after a retryable failure'

Write-Output 'C29P source gate passed: authenticated App Check-protected Social persistence, verified media, durable idempotency/cursors/interactions, no production fake gateway, fail-closed unsupported actions, r60.34 protected, build/install/deploy/external/secret authority closed.'
