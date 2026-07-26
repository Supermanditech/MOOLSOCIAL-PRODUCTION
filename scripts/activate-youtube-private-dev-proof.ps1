[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = "None")]
param(
  [ValidateSet(
    "PublicData",
    "OwnerConnect",
    "OwnerActions",
    "CreatorAssets",
    "Live",
    "PrivateUpload",
    "OwnerAnalytics"
  )]
  [string]$Profile,
  [ValidateRange(1, 30)]
  [int]$ProofWindowMinutes = 30,
  [ValidateSet("moolsocial-dev-503018")]
  [string]$ProjectId = "moolsocial-dev-503018",
  [string]$BillingAccountId = "01F9D3-44031C-B5E225",
  [string]$Confirmation = "",
  [string]$ServerApiKeyUid = "",
  [string]$AndroidAppId = "",
  [string]$ExpectedSha256 = "",
  [switch]$AllowNoServerIpRestriction,
  [switch]$StaticOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedBillingAccount = "01F9D3-44031C-B5E225"
$repoRoot = Split-Path -Parent $PSScriptRoot
$baselineFile = Join-Path $repoRoot `
  "backend/functions/env/moolsocial-dev-503018.env"
$runtimeFile = Join-Path $repoRoot `
  "backend/functions/.env.moolsocial-dev-503018"
$profileContract = Get-YouTubePrivateDevProfile $Profile
$expectedRunServiceNames = @(
  "youtubeprovider",
  "youtubeoauthcallback"
)

function Assert-True {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
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

function Remove-RuntimeFile {
  if (Test-Path -LiteralPath $runtimeFile -PathType Leaf) {
    Remove-Item -LiteralPath $runtimeFile -Force
  }
}

function Disable-ExactRunInvokerIamChecksForAppCheck {
  foreach ($serviceName in $expectedRunServiceNames) {
    Invoke-Checked {
      $previousErrorActionPreference = $ErrorActionPreference
      try {
        $ErrorActionPreference = "Continue"
        gcloud run services update $serviceName `
          --region $script:YouTubePrivateDevRegion `
          --project $ProjectId `
          --no-invoker-iam-check `
          --quiet *> $null
      } finally {
        $ErrorActionPreference = $previousErrorActionPreference
      }
    } (
      "Unable to enable App Check-guarded invocation for the exact " +
      "reviewed service: $serviceName"
    )
  }
}

function Invoke-ExactFunctionsDeploy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  Invoke-Checked {
    firebase deploy `
      --only (
        "functions:provider:youtubeProvider," +
        "functions:provider:youtubeOAuthCallback"
      ) `
      --project $ProjectId `
      --message $Message
  } "The exact private Dev Functions deployment failed."
  Disable-ExactRunInvokerIamChecksForAppCheck
}

function Invoke-DeploymentVerifier {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
      "Disabled",
      "PublicData",
      "OwnerConnect",
      "OwnerActions",
      "CreatorAssets",
      "Live",
      "PrivateUpload",
      "OwnerAnalytics"
    )]
    [string]$ExpectedProfile,
    [string]$ExpectedExpiration = "",
    [switch]$ExpectContained
  )

  $arguments = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    (Join-Path $PSScriptRoot `
      "verify-youtube-private-dev-deployment.ps1"),
    "-ProjectId",
    $ProjectId,
    "-BillingAccountId",
    $BillingAccountId,
    "-ServerApiKeyUid",
    $ServerApiKeyUid,
    "-AndroidAppId",
    $AndroidAppId,
    "-ExpectedSha256",
    $ExpectedSha256,
    "-ExpectedCapabilityProfile",
    $ExpectedProfile
  )
  if (-not [string]::IsNullOrWhiteSpace($ExpectedExpiration)) {
    $arguments += @(
      "-ExpectedProofExpiresAt",
      $ExpectedExpiration
    )
  }
  if ($AllowNoServerIpRestriction) {
    $arguments += "-AllowNoServerIpRestriction"
  }
  if ($ExpectContained) {
    $arguments += "-ExpectContained"
  }
  Invoke-Checked {
    powershell @arguments
  } "The deployed private Dev state did not match $ExpectedProfile."
}

function Write-ProfileRuntime {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Expiration
  )

  Assert-True (
    -not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)
  ) "Refusing to overwrite an existing ignored runtime environment file."
  $content = Get-YouTubePrivateDevProfileEnvironmentContent `
    -BaselineContent (
      Get-Content -Raw -LiteralPath $baselineFile
    ) `
    -Profile $Profile `
    -Expiration $Expiration
  Set-Content -LiteralPath $runtimeFile -Value $content -Encoding Ascii
}

Assert-True ($ProjectId -eq $script:YouTubePrivateDevProject) `
  "Only the exact private Dev project is authorized."
Assert-True ($BillingAccountId -eq $expectedBillingAccount) `
  "Only the reviewed private Dev billing account is authorized."
Assert-True ($Confirmation -eq $profileContract.Confirmation) `
  "This proof profile requires its exact one-purpose confirmation."
Assert-True (
  $ProofWindowMinutes -le $script:YouTubePrivateDevMaximumProofMinutes
) "The server-enforced proof window cannot exceed 30 minutes."

if ($StaticOnly) {
  $expiration = Get-YouTubePrivateDevProofExpiration `
    -ProofWindowMinutes $ProofWindowMinutes
  Assert-True (
    Test-YouTubePrivateDevProofExpiration $expiration
  ) "The proof expiry contract failed local validation."
  Write-Host "Supervised $Profile proof contract passed locally."
  Write-Host "No runtime file or cloud resource was changed."
  exit 0
}

foreach ($requiredValue in @(
  @{ Name = "ServerApiKeyUid"; Value = $ServerApiKeyUid },
  @{ Name = "AndroidAppId"; Value = $AndroidAppId },
  @{ Name = "ExpectedSha256"; Value = $ExpectedSha256 }
)) {
  Assert-True (
    -not [string]::IsNullOrWhiteSpace($requiredValue.Value)
  ) "$($requiredValue.Name) is required for supervised proof."
}
foreach ($tool in @("gcloud", "firebase")) {
  Assert-True ($null -ne (Get-Command $tool -ErrorAction SilentlyContinue)) `
    "$tool is required for supervised proof."
}

Invoke-Checked {
  powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot `
      "check-youtube-private-dev-package.ps1") `
    -SkipFlutter
} "The local private Dev package is not ready."
Invoke-DeploymentVerifier -ExpectedProfile "Disabled"

$activationAttempted = $false
$primaryFailure = $null
$rollbackFailure = $null
$proofExpiration = ""

try {
  $proofExpiration = Get-YouTubePrivateDevProofExpiration `
    -ProofWindowMinutes $ProofWindowMinutes
  Write-ProfileRuntime -Expiration $proofExpiration
  $activationAttempted = $true
  Invoke-ExactFunctionsDeploy `
    -Message "Supervised private Dev $Profile proof; server-expiring"
  Invoke-DeploymentVerifier `
    -ExpectedProfile $Profile `
    -ExpectedExpiration $proofExpiration
  Write-Host "Supervised $Profile proof is active for at most 30 minutes."
  Write-Host "Enter the exact completion phrase when the supervised proof ends."
  $completion = Read-Host
  Assert-True ($completion -eq $profileContract.Completion) `
    "The proof completion phrase did not match this profile."
} catch {
  $primaryFailure = $_
} finally {
  if ($activationAttempted) {
    try {
      Remove-RuntimeFile
      Invoke-Checked {
        powershell -NoProfile -ExecutionPolicy Bypass `
          -File (Join-Path $PSScriptRoot `
            "prepare-youtube-private-dev-runtime.ps1") `
          -ProjectId $ProjectId `
          -Materialize
      } "The all-disabled runtime could not be materialized."
      Invoke-ExactFunctionsDeploy `
        -Message "Private Dev rollback; every capability disabled"
      Invoke-DeploymentVerifier -ExpectedProfile "Disabled"
      Write-Host "Every private Dev YouTube capability is disabled again."
    } catch {
      $rollbackFailure = $_
    }
  }
  Remove-RuntimeFile
}

if ($null -ne $rollbackFailure) {
  try {
    powershell -NoProfile -ExecutionPolicy Bypass `
      -File (Join-Path $PSScriptRoot `
        "contain-youtube-private-dev.ps1") `
      -ProjectId $ProjectId `
      -Region $script:YouTubePrivateDevRegion `
      -Confirmation "CONTAIN_YOUTUBE_PRIVATE_DEV_NOW"
    Assert-True ($LASTEXITCODE -eq 0) `
      "Hard containment did not complete."
    Invoke-DeploymentVerifier `
      -ExpectedProfile "Disabled" `
      -ExpectContained
  } catch {
    throw (
      "Disable-all rollback failed and hard containment also failed. " +
      "Treat both exact private Dev endpoints as unavailable pending review."
    )
  }
  throw (
    "Disable-all rollback failed. Public invocation was removed from the " +
    "exact private Dev services as hard containment."
  )
}
if ($null -ne $primaryFailure) {
  throw $primaryFailure
}

Write-Host "Supervised proof completed and the all-disabled state was verified."
