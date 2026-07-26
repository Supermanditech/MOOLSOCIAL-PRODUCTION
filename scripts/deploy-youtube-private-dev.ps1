param(
  [ValidateSet("Validate", "Deploy")]
  [string]$Mode = "Validate",
  [ValidateSet("Disabled", "PublicDataReview")]
  [string]$CapabilityProfile = "Disabled",
  [string]$ProjectId = "moolsocial-dev-503018",
  [string]$BillingAccountId = "01F9D3-44031C-B5E225",
  [string]$Confirmation = "",
  [string]$ServerApiKeyUid = "",
  [string]$AndroidAppId = "",
  [string]$ExpectedSha256 = "",
  [switch]$AllowNoServerIpRestriction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedProject = "moolsocial-dev-503018"
$expectedBillingAccount = "01F9D3-44031C-B5E225"
$expectedConfirmation = if ($CapabilityProfile -eq "PublicDataReview") {
  $script:YouTubePrivateDevAcceptedPublicReviewConfirmation
} else {
  "DEPLOY_MOOLSOCIAL_PRIVATE_DEV_ONLY"
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$runtimeFile = Join-Path $repoRoot `
  "backend/functions/.env.moolsocial-dev-503018"
$materializedThisRun = $false
$deploymentAttempted = $false
$deploymentVerified = $false
$primaryFailure = $null
$rollbackFailure = $null
$expectedRunServiceNames = @(
  "youtubeprovider",
  "youtubeoauthcallback"
)

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

function Disable-ExactRunInvokerIamChecksForAppCheck {
  foreach ($serviceName in $expectedRunServiceNames) {
    Invoke-Checked {
      $previousErrorActionPreference = $ErrorActionPreference
      try {
        $ErrorActionPreference = "Continue"
        gcloud run services update $serviceName `
          --region asia-south1 `
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
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable deploy `
        --only (
          "functions:provider:youtubeProvider," +
          "functions:provider:youtubeOAuthCallback"
        ) `
        --project $ProjectId `
        --message $Message
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The exact private Dev Functions deployment failed."
  Disable-ExactRunInvokerIamChecksForAppCheck
}

function Invoke-ProfileVerifier {
  param(
    [ValidateSet("Disabled", "PublicDataReview")]
    [string]$ExpectedProfile,
    [switch]$ExpectContained
  )

  $verificationArguments = @(
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
  if ($AllowNoServerIpRestriction) {
    $verificationArguments += "-AllowNoServerIpRestriction"
  }
  if ($ExpectContained) {
    $verificationArguments += "-ExpectContained"
  }
  Invoke-Checked {
    powershell @verificationArguments
  } "The $ExpectedProfile deployed state was not verified."
}

function Invoke-AllDisabledVerifier {
  param([switch]$ExpectContained)

  Invoke-ProfileVerifier `
    -ExpectedProfile "Disabled" `
    -ExpectContained:$ExpectContained
}

if ($ProjectId -ne $expectedProject) {
  throw "Only $expectedProject is authorized."
}
if ($BillingAccountId -ne $expectedBillingAccount) {
  throw "Only the reviewed private Dev billing account is authorized."
}

Invoke-Checked {
  powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot `
      "check-youtube-private-dev-package.ps1")
} "The local private Dev package is not ready."

if ($Mode -eq "Validate") {
  Write-Host "Validation completed. No cloud action was performed."
  exit 0
}

foreach ($tool in @("gcloud", "firebase")) {
  if ($null -eq (Get-Command $tool -ErrorAction SilentlyContinue)) {
    throw "$tool is required for deployment."
  }
}
$firebaseCommand = Get-Command firebase.cmd -ErrorAction SilentlyContinue
if ($null -eq $firebaseCommand) {
  $firebaseCommand = Get-Command firebase -ErrorAction Stop
}
$firebaseExecutable = $firebaseCommand.Source
if ($Confirmation -ne $expectedConfirmation) {
  throw (
    "Deployment requires -Confirmation " +
    $expectedConfirmation
  )
}
foreach ($requiredVerificationValue in @(
  @{ Name = "ServerApiKeyUid"; Value = $ServerApiKeyUid },
  @{ Name = "AndroidAppId"; Value = $AndroidAppId },
  @{ Name = "ExpectedSha256"; Value = $ExpectedSha256 }
)) {
  if ([string]::IsNullOrWhiteSpace($requiredVerificationValue.Value)) {
    throw (
      "$($requiredVerificationValue.Name) is required before deployment " +
      "so the mandatory post-deployment verifier can run."
    )
  }
}

Invoke-Checked {
  powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot `
      "check-youtube-private-dev-preflight.ps1") `
    -Cloud `
    -RequireBilling `
    -ProjectId $ProjectId `
    -BillingAccountId $BillingAccountId
} "The post-payment cloud preflight failed."

$manifest = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot `
    "deployment/youtube-private-dev/deployment-manifest.json"
) | ConvertFrom-Json

Invoke-Checked {
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $firebaseExecutable apps:list `
      --project $ProjectId `
      --json *> $null
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
} "Firebase CLI authentication is not ready for the exact Dev project."

$previousErrorActionPreference = $ErrorActionPreference
try {
  $ErrorActionPreference = "Continue"
  $extensionOutput = & $firebaseExecutable ext:list `
    --project $ProjectId `
    --json 2>$null
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect the Firebase Extensions inventory."
}
try {
  $extensionState = ($extensionOutput | Out-String) | ConvertFrom-Json
} catch {
  throw "Firebase Extensions inventory was not valid JSON."
}
if (@($extensionState.result).Count -ne 0) {
  throw "No Firebase Extension instance is authorized in private Dev."
}

foreach ($secret in @($manifest.secretNames)) {
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $firebaseExecutable functions:secrets:get "$secret" `
      --project $ProjectId `
      --json *> $null
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Required Secret Manager entry is missing: $secret"
  }
  $enabledSecretVersionOutput = & gcloud secrets versions list "$secret" `
    --project=$ProjectId `
    --filter="state=ENABLED" `
    --format=json 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect enabled versions for $secret."
  }
  try {
    $enabledSecretVersions = @(
      ($enabledSecretVersionOutput | Out-String) | ConvertFrom-Json
    )
  } catch {
    throw "Enabled-version inventory was not valid JSON for $secret."
  }
  if (
    $enabledSecretVersions.Count -ne 1 -or
    $enabledSecretVersions[0].state -ne "ENABLED"
  ) {
    throw "Required secret must have exactly one enabled value version: $secret"
  }
}

$securityArguments = @(
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  (Join-Path $PSScriptRoot `
    "check-youtube-private-dev-security-prerequisites.ps1"),
  "-ProjectId",
  $ProjectId,
  "-ServerApiKeyUid",
  $ServerApiKeyUid,
  "-AndroidAppId",
  $AndroidAppId,
  "-ExpectedSha256",
  $ExpectedSha256
)
if ($AllowNoServerIpRestriction) {
  $securityArguments += "-AllowNoServerIpRestriction"
}
Invoke-Checked {
  powershell @securityArguments
} "The pre-deployment security configuration is unsafe or incomplete."

Invoke-Checked {
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $firebaseExecutable functions:artifacts:setpolicy `
      --days 1 `
      --location asia-south1 `
      --project $ProjectId `
      --force
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
} "The one-day Functions artifact cleanup policy could not be pre-applied."

$prepareArguments = @(
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  (Join-Path $PSScriptRoot "prepare-youtube-private-dev-runtime.ps1"),
  "-ProjectId",
  $ProjectId,
  "-CapabilityProfile",
  $CapabilityProfile,
  "-Materialize"
)
if ($CapabilityProfile -eq "PublicDataReview") {
  $prepareArguments += @(
    "-Confirmation",
    $script:YouTubePrivateDevAcceptedPublicReviewConfirmation
  )
}
Invoke-Checked {
  powershell @prepareArguments
} "The $CapabilityProfile runtime environment could not be materialized."
$materializedThisRun = $true

try {
  $deploymentAttempted = $true
  $deploymentMessage = if ($CapabilityProfile -eq "PublicDataReview") {
    "Founder-accepted Dev PublicData review; App Check guarded"
  } else {
    "YouTube private Dev provider; all capabilities disabled"
  }
  Invoke-Checked {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable deploy `
        --only (
          "functions:provider:youtubeProvider," +
          "functions:provider:youtubeOAuthCallback," +
          "firestore:rules"
        ) `
        --project $ProjectId `
        --message $deploymentMessage
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The private Dev Firebase deployment failed."
  Disable-ExactRunInvokerIamChecksForAppCheck

  Invoke-Checked {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable functions:artifacts:setpolicy `
        --days 1 `
        --location asia-south1 `
        --project $ProjectId `
        --force
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The one-day Functions artifact cleanup policy was not applied."

  Invoke-ProfileVerifier -ExpectedProfile $CapabilityProfile
  $deploymentVerified = $true

  Write-Host "Private Dev resources deployed as $CapabilityProfile."
  if ($CapabilityProfile -eq "PublicDataReview") {
    Write-Host "Public catalogue review remains live in the exact Dev project."
    Write-Host "Every owner, upload, live and analytics capability is disabled."
  } else {
    Write-Host "Every capability is disabled."
  }
  Write-Host "Persistence: existing (default) Standard Firestore database."
  Write-Host "Data Connect and Cloud SQL were not deployed."
  Write-Host "Functions build artifacts: one-day cleanup policy applied."
  Write-Host "Read-only deployed-state verification: passed."
} catch {
  $primaryFailure = $_
} finally {
  if ($deploymentAttempted -and -not $deploymentVerified) {
    try {
      if (Test-Path -LiteralPath $runtimeFile -PathType Leaf) {
        Remove-Item -LiteralPath $runtimeFile -Force
      }
      Invoke-Checked {
        powershell -NoProfile -ExecutionPolicy Bypass `
          -File (Join-Path $PSScriptRoot `
            "prepare-youtube-private-dev-runtime.ps1") `
          -ProjectId $ProjectId `
          -CapabilityProfile "Disabled" `
          -Materialize
      } "The all-disabled rollback runtime could not be materialized."
      Invoke-ExactFunctionsDeploy `
        -Message "Private Dev rollback; every capability disabled"
      Invoke-AllDisabledVerifier
      Write-Host "Deployment failed; the all-disabled rollback was verified."
    } catch {
      $rollbackFailure = $_
    }
  }
  if (
    $materializedThisRun -and
    (Test-Path -LiteralPath $runtimeFile -PathType Leaf)
  ) {
    Remove-Item -LiteralPath $runtimeFile -Force
  }
}

if ($null -ne $rollbackFailure) {
  try {
    powershell -NoProfile -ExecutionPolicy Bypass `
      -File (Join-Path $PSScriptRoot `
        "contain-youtube-private-dev.ps1") `
      -ProjectId $ProjectId `
      -Region "asia-south1" `
      -Confirmation "CONTAIN_YOUTUBE_PRIVATE_DEV_NOW"
    if ($LASTEXITCODE -ne 0) {
      throw "Hard containment did not complete."
    }
    Invoke-AllDisabledVerifier -ExpectContained
  } catch {
    throw (
      "Deployment and disable-all rollback failed, and hard containment " +
      "could not be verified. Treat both exact endpoints as unavailable."
    )
  }
  throw (
    "Deployment and disable-all rollback failed. Public invocation was " +
    "removed from the exact two reviewed private Dev services."
  )
}
if ($null -ne $primaryFailure) {
  throw $primaryFailure
}
