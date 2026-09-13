param(
  [switch]$SkipFlutter,
  [switch]$AllowReviewedExistingRuntime,
  [switch]$ProviderOnlyC30M
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

foreach ($deploymentScript in @(
  "activate-youtube-private-dev-proof.ps1",
  "check-youtube-private-dev-content.ps1",
  "check-youtube-private-dev-package.ps1",
  "check-youtube-private-dev-preflight.ps1",
  "check-youtube-private-dev-security-prerequisites.ps1",
  "contain-youtube-private-dev.ps1",
  "deploy-youtube-provider-c30m.ps1",
  "deploy-youtube-private-dev.ps1",
  "prepare-youtube-private-dev-runtime.ps1",
  "test-youtube-private-dev-deployment-controls.ps1",
  "test-youtube-provider-c30m-deployment-controls.ps1",
  "youtube-private-dev-control-common.ps1",
  "verify-youtube-private-dev-deployment.ps1"
)) {
  $tokens = $null
  $parseErrors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot $deploymentScript),
    [ref]$tokens,
    [ref]$parseErrors
  )
  if (@($parseErrors).Count -ne 0) {
    throw (
      "PowerShell syntax verification failed for {0}: {1}" -f
        $deploymentScript,
        (($parseErrors | ForEach-Object { $_.Message }) -join "; ")
    )
  }
}

$ignoredRuntimeExists = Test-Path -LiteralPath (
  Join-Path $repoRoot `
    "backend/functions/.env.moolsocial-dev-503018"
) -PathType Leaf
if (-not $AllowReviewedExistingRuntime -and $ignoredRuntimeExists) {
  throw (
    "The ignored Firebase runtime environment exists before packaging. " +
    "Review its ownership and remove it before any deployment workflow."
  )
}

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command,
    [Parameter(Mandatory = $true)]
    [string]$FailureMessage
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw $FailureMessage
  }
}

if (-not $ProviderOnlyC30M) {
  Invoke-Checked {
    powershell -NoProfile -ExecutionPolicy Bypass `
      -File (Join-Path $PSScriptRoot `
        "test-youtube-private-dev-deployment-controls.ps1")
  } "Private Dev deployment-control tests failed."

  Invoke-Checked {
    powershell -NoProfile -ExecutionPolicy Bypass `
      -File (Join-Path $PSScriptRoot `
        "check-youtube-private-dev-preflight.ps1")
  } "Private Dev repository preflight failed."
}

Invoke-Checked {
  powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot `
      "prepare-youtube-private-dev-runtime.ps1")
} "Private Dev runtime package verification failed."

Push-Location (Join-Path $repoRoot "backend/functions")
try {
  Invoke-Checked { npm run verify } `
    "The privileged provider backend verification failed."
  Invoke-Checked {
    node (Join-Path $PSScriptRoot `
      "check-youtube-private-dev-exports.mjs")
  } "The built provider export inventory changed."
} finally {
  Pop-Location
}

if (-not $SkipFlutter) {
  Push-Location (Join-Path $repoRoot "apps/mobile")
  try {
    Invoke-Checked {
      flutter analyze `
        --no-pub `
        lib/core/youtube `
        test/youtube_embedded_player_runtime_test.dart `
        test/youtube_private_dev_client_test.dart
    } "The private Dev Flutter client analysis failed."
    Invoke-Checked {
      flutter test `
        --no-pub `
        test/platform_configuration_test.dart `
        test/youtube_embedded_player_runtime_test.dart `
        test/youtube_private_dev_client_test.dart
    } "The private Dev Flutter client tests failed."
  } finally {
    Pop-Location
  }
}

Invoke-Checked {
  & (Join-Path $PSScriptRoot `
    "check-youtube-private-dev-content.ps1") `
    -AllowReviewedExistingRuntime:$AllowReviewedExistingRuntime `
    -ProviderOnlyC30M:$ProviderOnlyC30M
} "Tracked and untracked package-content verification failed."

Invoke-Checked {
  git -C $repoRoot diff --check -- `
    backend/functions `
    backend/firestore `
    dataconnect/provider `
    dataconnect/schema/provider_integrations.gql `
    deployment/youtube-private-dev `
    firebase.json `
    apps/mobile/lib/core/youtube `
    apps/mobile/test/youtube_embedded_player_runtime_test.dart `
    apps/mobile/test/youtube_private_dev_client_test.dart `
    scripts/check-youtube-private-dev-package.ps1 `
    scripts/check-youtube-private-dev-content.ps1 `
    scripts/check-youtube-private-dev-exports.mjs `
    scripts/check-youtube-private-dev-preflight.ps1 `
    scripts/check-youtube-private-dev-security-prerequisites.ps1 `
    scripts/activate-youtube-private-dev-proof.ps1 `
    scripts/contain-youtube-private-dev.ps1 `
    scripts/deploy-youtube-provider-c30m.ps1 `
    scripts/deploy-youtube-private-dev.ps1 `
    scripts/prepare-youtube-private-dev-runtime.ps1 `
    scripts/test-youtube-private-dev-deployment-controls.ps1 `
    scripts/test-youtube-provider-c30m-deployment-controls.ps1 `
    scripts/youtube-private-dev-control-common.ps1 `
    scripts/verify-youtube-private-dev-deployment.ps1
} "Whitespace or patch-integrity verification failed."

Write-Host "YouTube private Dev deployment package passed locally."
