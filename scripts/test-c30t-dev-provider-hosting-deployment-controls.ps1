Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$commonPath = Join-Path $PSScriptRoot `
  "c30t-provider-hosting-deployment-common.ps1"
$providerPath = Join-Path $PSScriptRoot "deploy-c30t-dev-provider-only.ps1"
$hostingPath = Join-Path $PSScriptRoot "deploy-c30t-dev-hosting-only.ps1"
$manifestPath = Join-Path $PSScriptRoot `
  "new-c30t-provider-hosting-source-manifest.ps1"

foreach ($path in @($commonPath, $providerPath, $hostingPath, $manifestPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C30T deployment-control owner is missing: $path"
  }
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $path, [ref]$tokens, [ref]$errors
  )
  if (@($errors).Count -ne 0) {
    throw "C30T deployment-control syntax failed: $path"
  }
}

$common = Get-Content -Raw -LiteralPath $commonPath
$provider = Get-Content -Raw -LiteralPath $providerPath
$hosting = Get-Content -Raw -LiteralPath $hostingPath
$manifest = Get-Content -Raw -LiteralPath $manifestPath

foreach ($required in @(
  'functions:provider:youtubeProvider',
  'Authorize C30T bounded Dev YouTube provider and Firebase Hosting ',
  'youtubeOAuthCallbackDeploy',
  'moolSocialContentDeploy',
  'moolSocialChatDeploy',
  'aabBuildUploadOrInstall',
  'gmailOrQuotaSubmission'
)) {
  if (-not $common.Contains($required, [StringComparison]::Ordinal)) {
    throw "C30T common control is missing: $required"
  }
}
foreach ($required in @(
  'Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent',
  '[IO.File]::ReadAllBytes',
  '[IO.File]::WriteAllBytes',
  'deploy-youtube-provider-c30m.ps1',
  'pwsh -NoProfile -File',
  'DEPLOY_C30T_DEV_YOUTUBE_PROVIDER_ONLY',
  'moolsocialchat',
  'YOUTUBE_OWNER_CONNECT_ENABLED = "true"',
  'YOUTUBE_PRIVATE_UPLOAD_ENABLED = "false"',
  '$provider.metadata.annotations."run.googleapis.com/invoker-iam-disabled"'
)) {
  if (-not $provider.Contains($required, [StringComparison]::Ordinal)) {
    throw "C30T provider control is missing: $required"
  }
}
if (
  ([regex]::Matches($hosting, '(?m)^\s*--only hosting\s*`?$')).Count -ne 2
) { throw "C30T Hosting control must contain exactly dry-run and live targets." }
foreach ($required in @(
  'DEPLOY_C30T_DEV_FIREBASE_HOSTING_ONLY',
  'hosting:channel:list',
  'India Ka Social Commerce App',
  '/.well-known/assetlinks.json',
  '47:B2:8C:7D:DE:2B:61:CA:B6:A7:74:8C:90:19:A3:B5:73:76:B3:BE:1D:C1:63:D4:82:53:BB:A3:5B:63:CD:D9'
)) {
  if (-not $hosting.Contains($required, [StringComparison]::Ordinal)) {
    throw "C30T Hosting control is missing: $required"
  }
}
foreach ($forbiddenTarget in @(
  '--only functions',
  '--only firestore',
  '--only storage',
  '--except',
  '--force'
)) {
  if (
    $provider.Contains($forbiddenTarget, [StringComparison]::OrdinalIgnoreCase) -or
    $hosting.Contains($forbiddenTarget, [StringComparison]::OrdinalIgnoreCase)
  ) { throw "C30T wrapper contains a forbidden broad target: $forbiddenTarget" }
}
foreach ($required in @(
  'fingerprintAlgorithm',
  'runtimeMaterializationSha256',
  'check-youtube-private-dev-exports.mjs',
  'deploy-c30t-dev-provider-only.ps1',
  'deploy-c30t-dev-hosting-only.ps1',
  'apps/web/tests/firebase-public-site.test.mjs'
)) {
  if (-not $manifest.Contains($required, [StringComparison]::Ordinal)) {
    throw "C30T source-manifest owner is missing: $required"
  }
}

Write-Host "C30T provider and Hosting deployment controls passed locally."
Write-Host "No runtime file or external resource was changed."
