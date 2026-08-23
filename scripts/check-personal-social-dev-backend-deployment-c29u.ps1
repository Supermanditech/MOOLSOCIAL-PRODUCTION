[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C29U([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29U deployment gate rejected: $Message" }
}

function Resolve-C29UFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29U ($path.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29U (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29UContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29UFile $RelativePath)
}

function Assert-C29UContains([string]$RelativePath, [string]$Text) {
  Assert-C29U ((Get-C29UContent $RelativePath).Contains($Text, [StringComparison]::Ordinal)) "required seal missing from $RelativePath`: $Text"
}

function Assert-C29UHash([string]$RelativePath, [string]$Expected) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C29UFile $RelativePath)).Hash
  Assert-C29U ($actual -ceq $Expected) "SHA-256 changed for $RelativePath; expected $Expected, got $actual"
}

function Get-C29UTreeSeal([string]$RelativeDirectory, [string]$Filter) {
  $directory = [IO.Path]::GetFullPath((Join-Path $root $RelativeDirectory))
  Assert-C29U ($directory.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) "tree escaped repository: $RelativeDirectory"
  Assert-C29U (Test-Path -LiteralPath $directory -PathType Container) "tree missing: $RelativeDirectory"
  $files = @(Get-ChildItem -LiteralPath $directory -Recurse -File -Filter $Filter | Sort-Object FullName)
  $lines = @($files | ForEach-Object {
    $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    "$hash $relative"
  })
  $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $aggregate = [Convert]::ToHexString($sha.ComputeHash($bytes)) } finally { $sha.Dispose() }
  return [pscustomobject]@{ Count = $files.Count; Hash = $aggregate }
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U'
$expectedProject = 'moolsocial-dev-503018'
$ticketPath = Resolve-C29UFile 'config/uaw-personal-mvp-social-dev-backend-deployment-c29u-ticket.json'
$scopePath = Resolve-C29UFile 'config/mvp-scope-gate-state.json'
$protectedPath = Resolve-C29UFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$protected = Get-Content -Raw -LiteralPath $protectedPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29U ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29U ([string]$ticket.state -ceq 'selected_founder_authorized_predeployment_qualification') 'ticket is not at the predeployment gate'
Assert-C29U ([string]$ticket.classification -ceq 'mvp_required') 'classification changed'
Assert-C29U ([string]$ticket.actor -ceq 'founder_supervised_Dev_release_operator') 'exact actor changed'
Assert-C29U ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29U ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29U ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29U ([string]$scope.authorization.state -ceq 'founder_acknowledged_mvp_scope') 'MVP authority vocabulary changed'
Assert-C29U ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/gate authority is closed'
Assert-C29U ([bool]$scope.execution.externalServiceWriteAuthorized) 'Dev external-service authority is closed'
Assert-C29U (-not [bool]$scope.execution.secretValueAccessAuthorized) 'secret-value access was opened'
foreach ($closed in @(
  [bool]$scope.execution.referenceWriteAuthorized,
  [bool]$scope.execution.runtimeWriteAuthorized,
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$ticket.authority.secretValueAccessAuthorized,
  [bool]$ticket.authority.productionWriteAuthorized,
  [bool]$ticket.authority.buildAuthorized,
  [bool]$ticket.authority.deviceInstallAuthorized
)) { Assert-C29U (-not $closed) 'source/reference/build/device/Production/secret authority opened' }
foreach ($open in @(
  [bool]$ticket.authority.externalReadAuthorized,
  [bool]$ticket.authority.devRulesDeployAuthorized,
  [bool]$ticket.authority.devFunctionsDeployAuthorized,
  [bool]$ticket.authority.requiredDevApiEnablementAuthorized,
  [bool]$ticket.authority.leastPrivilegeIamMutationAuthorized,
  [bool]$ticket.authority.secretMetadataAndBindingAuthorized
)) { Assert-C29U $open 'required Dev deployment authority is closed' }

Assert-C29U ([string]$protected.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29U ([string]$protected.installResult.versionName -ceq '1.0.0-r60.34') 'protected OPPO version changed'
Assert-C29U ([string]$protected.installResult.versionCode -ceq '2026081134') 'protected OPPO version code changed'
Assert-C29U ([string]$protected.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected OPPO APK checksum changed'
Assert-C29U (-not [bool]$protected.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29U (-not [bool]$protected.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29U (-not [bool]$protected.installResult.downgradePerformed) 'protected app was downgraded'

Assert-C29UHash 'backend/firestore/youtube-private-dev.rules' 'CD5089E4E5116DBB994013DC5FD5E7E411EC348935B8D06D13ACD00173CCA15B'
Assert-C29UHash 'backend/storage/moolsocial-private-dev.rules' '709A97B54435900F36EA789C0A7F83E69D62E37FA1430102353F8E2ABE0068CD'
Assert-C29UHash 'firebase.json' '0FF2AA55F6D88688D7F4495A3194806C85189A0967B303E1E69BD4B8B01F7BD3'
Assert-C29UHash 'backend/functions/package.json' 'C940929A2F44F2B9C6E2DB83259D18D952423E3BD27C9EC0C373803A9965FEEE'
Assert-C29UHash 'backend/functions/package-lock.json' 'EDDA3DEF898EFD61E8F822D62DD2BED0D01630F813ECAFF4AAD84D08187E93CC'
$tree = Get-C29UTreeSeal 'backend/functions/src' '*.ts'
Assert-C29U ([int]$tree.Count -eq 107) 'function source file count changed'
Assert-C29U ([string]$tree.Hash -ceq 'AB8D68286ADC79BB1B40BB742525239C8BE4687AAAF3C2CEC86206324F8A6C6E') 'function source aggregate changed'

$firebase = Get-C29UContent 'firebase.json' | ConvertFrom-Json
Assert-C29U ([string]$firebase.functions[0].source -ceq 'backend/functions') 'Functions source changed'
Assert-C29U ([string]$firebase.functions[0].codebase -ceq 'provider') 'Functions codebase changed'
Assert-C29U ([string]$firebase.functions[0].runtime -ceq 'nodejs22') 'Functions runtime changed'
Assert-C29U ([string]$firebase.firestore.rules -ceq 'backend/firestore/youtube-private-dev.rules') 'Firestore rules owner changed'
Assert-C29U ([string]$firebase.storage.rules -ceq 'backend/storage/moolsocial-private-dev.rules') 'Storage rules owner changed'
Assert-C29UContains 'backend/firestore/youtube-private-dev.rules' 'allow read, write: if false;'
Assert-C29UContains 'backend/storage/moolsocial-private-dev.rules' 'allow read, write: if false;'
foreach ($export in @('export const youtubeProvider = onRequest(', 'export const moolSocialContent = onRequest(', 'export const youtubeOAuthCallback = onRequest(')) {
  Assert-C29UContains 'backend/functions/src/index.ts' $export
}
Assert-C29UContains 'backend/functions/src/index.ts' 'youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
Assert-C29UContains 'backend/functions/src/index.ts' 'social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
Assert-C29UContains 'backend/functions/src/youtube/config.ts' 'export const PRIVATE_DEV_YOUTUBE_PROJECT_ID = "moolsocial-dev-503018";'
Assert-C29UContains 'backend/functions/src/youtube/config.ts' 'export const PRIVATE_DEV_YOUTUBE_MAX_PROOF_MILLISECONDS = 30 * 60 * 1000;'
Assert-C29UContains 'backend/functions/src/youtube/config.ts' 'publicOrUnlistedUpload: false,'

Write-Output "C29U deployment gate passed: project=$expectedProject; functions=youtubeProvider,youtubeOAuthCallback,moolSocialContent; sourceFiles=$($tree.Count); sourceAggregate=$($tree.Hash); directClientRules=deny-all; protectedOPPO=r60.34."
