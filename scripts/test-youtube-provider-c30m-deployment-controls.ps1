Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$deploymentPath = Join-Path $PSScriptRoot `
  "deploy-youtube-provider-c30m.ps1"
$packagePath = Join-Path $PSScriptRoot `
  "check-youtube-private-dev-package.ps1"
$contentGatePath = Join-Path $PSScriptRoot `
  "check-youtube-private-dev-content.ps1"

foreach ($requiredPath in @(
  $deploymentPath,
  $packagePath,
  $contentGatePath
)) {
  if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
    throw "Required C30M deployment-control owner is missing: $requiredPath"
  }
}

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
  $deploymentPath,
  [ref]$tokens,
  [ref]$parseErrors
)
if (@($parseErrors).Count -ne 0) {
  throw (
    "C30M provider-only deployment script has syntax errors: " +
    (($parseErrors | ForEach-Object { $_.Message }) -join "; ")
  )
}

$deployment = Get-Content -Raw -LiteralPath $deploymentPath
$package = Get-Content -Raw -LiteralPath $packagePath
$contentGate = Get-Content -Raw -LiteralPath $contentGatePath

foreach ($requiredLiteral in @(
  '$exactDeployTarget = "functions:provider:youtubeProvider"',
  '--only $exactDeployTarget',
  'DEPLOY_C30M_DEV_YOUTUBE_PROVIDER_ONLY',
  'ExpectedProviderRevision',
  'ExpectedOAuthCallbackRevision',
  'ExpectedSocialContentRevision',
  'youtubeoauthcallback',
  'moolsocialcontent',
  '--dry-run',
  '--no-invoker-iam-check',
  '$expectedProviderEnvironment = "dev"',
  '$expectedProviderRuntimeEnabled = "true"',
  '$expectedProviderRuntimeMode = "accepted"',
  '"youtubeOAuthCallback"',
  'MOOLSOCIAL_PROVIDER_ENV=$expectedProviderEnvironment',
  'YOUTUBE_OAUTH_REDIRECT_URI=$expectedProviderOAuthCallback',
  'YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED=$expectedProviderRuntimeEnabled',
  'YOUTUBE_SOCIAL_RUNTIME_MODE=$expectedProviderRuntimeMode',
  '--update-env-vars=$permanentProviderRuntimeValues',
  'Assert-C30MPermanentProviderRuntime',
  'spec.template.spec.containers',
  'update-traffic',
  'functions:artifacts:setpolicy',
  'check-codex-development-regression-memory.ps1',
  'check-mvp-scope-gate-state.ps1',
  'check-mvp-delivery-discipline-lock.ps1',
  'check-youtube-private-dev-package.ps1'
  'AllowReviewedExistingRuntime'
  'ProviderOnlyC30M'
)) {
  if (-not $deployment.Contains($requiredLiteral)) {
    throw "C30M provider-only deployment control is missing: $requiredLiteral"
  }
}

foreach ($forbiddenLiteral in @(
  'functions:provider:youtubeOAuthCallback',
  'functions:provider:moolSocialContent',
  'firestore:rules',
  'storage',
  'hosting',
  'print-access-token',
  'secrets versions access',
  'functions:secrets:get',
  'contain-youtube-private-dev.ps1',
  'YOUTUBE_PROOF_EXPIRES_AT',
  'YOUTUBE_PROOF_PROFILE'
)) {
  if ($deployment.Contains($forbiddenLiteral)) {
    throw "C30M provider-only deployment contains forbidden scope: $forbiddenLiteral"
  }
}

foreach ($owner in @(
  'deploy-youtube-provider-c30m.ps1',
  'test-youtube-provider-c30m-deployment-controls.ps1'
)) {
  if (-not $package.Contains($owner)) {
    throw "The package gate does not own $owner"
  }
  if (-not $contentGate.Contains("scripts/$owner")) {
    throw "The package-content gate does not scan scripts/$owner"
  }
}

if (
  -not $package.Contains('AllowReviewedExistingRuntime') -or
  -not $contentGate.Contains('AllowReviewedExistingRuntime') -or
  -not $package.Contains('if (-not $ProviderOnlyC30M)') -or
  -not $package.Contains('npm run verify') -or
  -not $package.Contains('check-youtube-private-dev-exports.mjs')
) {
  throw "The reviewed runtime or provider-only package gate is incomplete."
}

if (
  $deployment -notmatch
    '(?s)firebaseExecutable\s+deploy.*?--only\s+\$exactDeployTarget' -or
  $deployment -match
    '(?s)firebaseExecutable\s+deploy.*?--only\s+\([^\)]*,[^\)]*\)'
) {
  throw "Firebase deployment is not pinned to one exact provider target."
}

if (
  $deployment -notmatch (
    '(?s)firebaseExecutable\s+deploy.*?' +
    'gcloudExecutable\s+run services update.*?' +
    '--update-env-vars=\$permanentProviderRuntimeValues.*?' +
    'providerAfter\s*=\s*Read-C30MRunServiceState'
  ) -or
  $deployment -notmatch (
    '(?s)Assert-C30MPermanentProviderRuntime\s+`?\s*' +
    '-State\s+\$providerBefore.*?' +
    'Assert-C30MPermanentProviderRuntime\s+`?\s*' +
    '-State\s+\$providerAfter'
  )
) {
  throw (
    'The permanent YouTube provider runtime tuple is not restored and ' +
    'verified around the isolated deployment.'
  )
}

$wrongProjectRejected = $false
try {
  & (Join-Path $PSScriptRoot `
    "deploy-youtube-provider-c30m.ps1") `
    -Mode Validate `
    -ProjectId "not-authorized"
} catch {
  $wrongProjectRejected = $true
}
if (-not $wrongProjectRejected) {
  throw "C30M validation accepted a non-Dev project."
}

git -C $repoRoot diff --check -- `
  scripts/deploy-youtube-provider-c30m.ps1 `
  scripts/test-youtube-provider-c30m-deployment-controls.ps1 `
  scripts/check-youtube-private-dev-package.ps1 `
  scripts/check-youtube-private-dev-content.ps1
if ($LASTEXITCODE -ne 0) {
  throw "C30M provider-only deployment-control patch integrity failed."
}

Write-Host "C30M provider-only deployment controls passed."
