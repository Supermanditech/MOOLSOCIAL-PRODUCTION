Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$repoRoot = Split-Path -Parent $PSScriptRoot

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

function Assert-ExactStringSet {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Actual,
    [Parameter(Mandatory = $true)]
    [string[]]$Expected,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $actualValues = @($Actual | ForEach-Object { "$_" } | Sort-Object -Unique)
  $expectedValues = @($Expected | Sort-Object -Unique)
  Assert-True (
    $actualValues.Count -eq $expectedValues.Count -and
    @(Compare-Object $expectedValues $actualValues).Count -eq 0
  ) "$Name does not match its reviewed exact set."
}

$profileNames = @(
  "PublicData",
  "OwnerConnect",
  "OwnerActions",
  "CreatorAssets",
  "Live",
  "PrivateUpload",
  "OwnerAnalytics"
)
$confirmations = @()
$completions = @()
foreach ($profileName in $profileNames) {
  $profile = Get-YouTubePrivateDevProfile $profileName
  $enabledFlags = @(
    $profile.Flags.GetEnumerator() |
      Where-Object { $_.Value -eq "true" }
  )
  Assert-True ($enabledFlags.Count -eq 1) `
    "$profileName must enable exactly one capability."
  Assert-True (-not [string]::IsNullOrWhiteSpace($profile.RuntimeName)) `
    "$profileName must have one server runtime name."
  $confirmations += $profile.Confirmation
  $completions += $profile.Completion
}
Assert-True (
  @($confirmations | Sort-Object -Unique).Count -eq $profileNames.Count
) "Every proof profile must have a unique activation confirmation."
Assert-True (
  @($completions | Sort-Object -Unique).Count -eq $profileNames.Count
) "Every proof profile must have a unique completion confirmation."

$disabled = Get-YouTubePrivateDevProfile "Disabled"
Assert-True (
  @(
    $disabled.Flags.GetEnumerator() |
      Where-Object { $_.Value -eq "true" }
  ).Count -eq 0
) "The immutable baseline profile must enable no capability."

$now = [datetimeoffset]::Parse("2026-07-25T00:00:00Z")
$expiration = Get-YouTubePrivateDevProofExpiration `
  -ProofWindowMinutes 30 `
  -Now $now
Assert-True ($expiration -eq "2026-07-25T00:30:00Z") `
  "Proof expiration must be deterministic and UTC."
Assert-True (
  Test-YouTubePrivateDevProofExpiration `
    -Value $expiration `
    -Now $now
) "A valid 30-minute proof expiry was rejected."
foreach ($invalid in @(
  "not-a-time",
  "2026-07-25T00:00:00Z",
  "2026-07-25T00:30:01Z",
  "2026-07-25T00:30:00+00:00"
)) {
  Assert-True (
    -not (Test-YouTubePrivateDevProofExpiration `
      -Value $invalid `
      -Now $now)
  ) "An invalid proof expiry was accepted."
}

Assert-True (Test-YouTubePrivateDevEffectiveFalse $null) `
  "An absent App Check requireLicensed field must be effectively false."
Assert-True (Test-YouTubePrivateDevEffectiveFalse $false) `
  "Boolean false App Check requireLicensed must be accepted."
Assert-True (-not (Test-YouTubePrivateDevEffectiveFalse $true)) `
  "Boolean true App Check requireLicensed must be rejected."
Assert-True (-not (Test-YouTubePrivateDevEffectiveFalse "false")) `
  "A string App Check requireLicensed value must be rejected."

$manifest = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot `
    "deployment/youtube-private-dev/deployment-manifest.json"
) | ConvertFrom-Json
$reviewedAllowedServices = @(
  @($manifest.deploymentPrerequisiteServices) +
  @($manifest.providerServices) +
  @($manifest.preExistingPlatformServices)
)
Assert-ExactStringSet `
  @($manifest.allowedEnabledServices) `
  $reviewedAllowedServices `
  "Allowed enabled-service inventory"
foreach ($service in @($manifest.preExistingPlatformServices)) {
  Assert-True (
    -not (@($manifest.deferredServices) -contains $service)
  ) "A deferred service cannot be accepted as pre-existing platform state."
}
Assert-True ([int]$manifest.supervisedProof.maximumMinutes -eq 30) `
  "The manifest proof window must remain capped at 30 minutes."
Assert-ExactStringSet `
  @($manifest.supervisedProof.profiles) `
  $profileNames `
  "Manifest proof profile inventory"
Assert-True (
  [decimal]$manifest.budget.approvedMonthlyAmount -eq 1000
) "The Dev monthly budget alert target must remain INR 1,000."
Assert-True ([int]$manifest.runtime.maxInstances -eq 1) `
  "The Dev runtime hard cap must remain maxInstances=1."
Assert-True (
  $manifest.acceptedPublicReview.profile -eq "PublicDataReview" -and
  $manifest.acceptedPublicReview.allowedTarget -eq
  $script:YouTubePrivateDevProject -and
  $manifest.acceptedPublicReview.modeVariable -eq
  "YOUTUBE_PUBLIC_DATA_REVIEW_MODE" -and
  $manifest.acceptedPublicReview.modeValue -eq
  $script:YouTubePrivateDevAcceptedPublicReviewMode -and
  $manifest.acceptedPublicReview.onlyPublicDataEnabled -eq $true -and
  $manifest.acceptedPublicReview.appCheckRequired -eq $true -and
  $manifest.acceptedPublicReview.stagingForbidden -eq $true -and
  $manifest.acceptedPublicReview.productionForbidden -eq $true
) "Accepted public review lost its exact Dev-only containment."

$baseline = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot `
    "backend/functions/env/moolsocial-dev-503018.env"
)
foreach ($flag in $script:YouTubePrivateDevCapabilityKeys) {
  Assert-True ($baseline -match "(?m)^$flag=false$") `
    "The immutable baseline must keep $flag false."
}
Assert-True (
  $baseline -notmatch "(?m)^YOUTUBE_PROOF_(PROFILE|EXPIRES_AT)="
) "The immutable baseline must not contain a supervised proof profile."
Assert-True (
  $baseline -notmatch "(?m)^YOUTUBE_PUBLIC_DATA_REVIEW_MODE="
) "The immutable baseline must not contain an accepted review mode."
foreach ($profileName in $profileNames) {
  $profile = Get-YouTubePrivateDevProfile $profileName
  $materialized = Get-YouTubePrivateDevProfileEnvironmentContent `
    -BaselineContent $baseline `
    -Profile $profileName `
    -Expiration $expiration `
    -Now $now
  Assert-True (
    @(
      $script:YouTubePrivateDevCapabilityKeys |
        Where-Object {
          $materialized -match "(?m)^$($_)=true$"
        }
    ).Count -eq 1
  ) "$profileName materialization must enable exactly one capability."
  Assert-True (
    $materialized -match (
      "(?m)^YOUTUBE_PROOF_PROFILE=" +
      [regex]::Escape($profile.RuntimeName) +
      "`r?$"
    )
  ) "$profileName materialization has the wrong server profile."
  Assert-True (
    $materialized -match (
      "(?m)^YOUTUBE_PROOF_EXPIRES_AT=utc:" +
      [regex]::Escape($expiration) +
      "`r?$"
    )
  ) "$profileName materialization has the wrong server expiry."
}
$acceptedReview =
  Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
    -BaselineContent $baseline
Assert-True (
  $acceptedReview -match (
    "(?m)^YOUTUBE_PUBLIC_DATA_REVIEW_MODE=" +
    [regex]::Escape(
      $script:YouTubePrivateDevAcceptedPublicReviewMode
    ) +
    "`r?$"
  )
) "Accepted public review has the wrong mode."
Assert-True (
  @(
    $script:YouTubePrivateDevCapabilityKeys |
      Where-Object {
        $acceptedReview -match "(?m)^$($_)=true`r?$"
      }
  ).Count -eq 1 -and
  $acceptedReview -match "(?m)^YOUTUBE_PUBLIC_DATA_ENABLED=true`r?$"
) "Accepted public review must enable only PublicData."
Assert-True (
  $acceptedReview -notmatch "(?m)^YOUTUBE_PROOF_(PROFILE|EXPIRES_AT)="
) "Accepted public review must not retain supervised proof controls."
$badBaselines = @()
$badBaselines += (
  $baseline -replace (
    "(?m)^YOUTUBE_PUBLIC_DATA_ENABLED=false$"
  ), "YOUTUBE_PUBLIC_DATA_ENABLED=true"
)
$badBaselines += ($baseline + "`nYOUTUBE_PROOF_PROFILE=publicData")
$badBaselines += (
  $baseline + "`nYOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted"
)
foreach ($badBaseline in $badBaselines) {
  $rejected = $false
  try {
    [void](Get-YouTubePrivateDevProfileEnvironmentContent `
      -BaselineContent $badBaseline `
      -Profile "PublicData" `
      -Expiration $expiration `
      -Now $now)
  } catch {
    $rejected = $true
  }
  Assert-True $rejected `
    "Unsafe baseline input must fail profile materialization."
}

foreach ($badBaseline in $badBaselines) {
  $rejected = $false
  try {
    [void](Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
      -BaselineContent $badBaseline)
  } catch {
    $rejected = $true
  }
  Assert-True $rejected `
    "Unsafe baseline input must fail accepted-review materialization."
}

$activationScript = Get-Content -Raw -LiteralPath (
  Join-Path $PSScriptRoot "activate-youtube-private-dev-proof.ps1"
)
$deploymentScript = Get-Content -Raw -LiteralPath (
  Join-Path $PSScriptRoot "deploy-youtube-private-dev.ps1"
)
$containmentScript = Get-Content -Raw -LiteralPath (
  Join-Path $PSScriptRoot "contain-youtube-private-dev.ps1"
)
$verifierScript = Get-Content -Raw -LiteralPath (
  Join-Path $PSScriptRoot "verify-youtube-private-dev-deployment.ps1"
)
Assert-True ($activationScript -match "(?i)finally\s*\{") `
  "Supervised activation must retain a finally disable-all path."
Assert-True (
  $activationScript -match "ExpectedCapabilityProfile" -and
  $activationScript -match "ExpectedProofExpiresAt"
) "Supervised activation must perform profile-aware verification."
Assert-True (
  $activationScript -notmatch (
    "(?i)param\s*\([^)]*(Enable|CapabilityFlag|EnvironmentFlag)"
  )
) "Generic runtime-flag injection is forbidden."
Assert-True (
  $activationScript -notmatch (
    "(?i)(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_SECRET|" +
    "YOUTUBE_TOKEN_ENCRYPTION_KEY)"
  )
) "Activation controls must not accept or print secret values."
Assert-True (
  $deploymentScript -match (
    '(?s)if \(\$null -ne \$rollbackFailure\).*' +
    'contain-youtube-private-dev\.ps1'
  )
) "Baseline deployment must hard-contain only after rollback failure."
Assert-True (
  $deploymentScript -match "PublicDataReview" -and
  $deploymentScript -match (
    [regex]::Escape(
      "YouTubePrivateDevAcceptedPublicReviewConfirmation"
    )
  ) -and
  $deploymentScript -match "Invoke-ProfileVerifier" -and
  $deploymentScript -match "all-disabled rollback runtime"
) (
  "Accepted public review deployment must require founder confirmation, " +
  "verify the live profile and retain a disable-all rollback."
)
Assert-True (
  $verifierScript -match "PublicDataReview" -and
  $verifierScript -match "YOUTUBE_PUBLIC_DATA_REVIEW_MODE" -and
  $verifierScript -match "mixes accepted public review"
) "Deployment verification must reject ambiguous accepted-review state."
Assert-True (
  $deploymentScript -match (
    "Disable-ExactRunInvokerIamChecksForAppCheck"
  ) -and
  $deploymentScript -match "youtubeprovider" -and
  $deploymentScript -match "youtubeoauthcallback" -and
  $deploymentScript -match "run services update" -and
  $deploymentScript -match "no-invoker-iam-check" -and
  $deploymentScript -notmatch "add-iam-policy-binding"
) (
  "Baseline deployment must disable the invoker IAM check only on the two " +
  "exact App Check-guarded Run services before verification."
)
Assert-True (
  $activationScript -match (
    "Disable-ExactRunInvokerIamChecksForAppCheck"
  ) -and
  $activationScript -match "youtubeprovider" -and
  $activationScript -match "youtubeoauthcallback" -and
  $activationScript -match "run services update" -and
  $activationScript -match "no-invoker-iam-check"
) (
  "Every supervised proof deployment must restore the exact App " +
  "Check-guarded transport boundary."
)
Assert-True (
  $activationScript -match (
    '(?s)if \(\$null -ne \$rollbackFailure\).*' +
    'contain-youtube-private-dev\.ps1'
  )
) "Proof activation must hard-contain only after rollback failure."
Assert-True (
  $containmentScript -match "allUsers" -and
  $containmentScript -match "roles/run.invoker" -and
  $containmentScript -match "allAuthenticatedUsers" -and
  $containmentScript -match "invoker-iam-check" -and
  $containmentScript -match "run.googleapis.com/invoker-iam-disabled"
) (
  "Hard containment must restore the service-level invoker IAM check and " +
  "reject every remaining broad invoker."
)
Assert-True (
  $verifierScript -match "Assert-RunInvocationBoundary" -and
  $verifierScript -match "run.googleapis.com/invoker-iam-disabled" -and
  $verifierScript -match "ExpectContainedBoundary"
) (
  "Deployment verification must distinguish the App Check-guarded transport " +
  "boundary from the hard-contained boundary."
)
Assert-True (
  $deploymentScript -match (
    "(?s)contain-youtube-private-dev\.ps1.*" +
    "Invoke-AllDisabledVerifier -ExpectContained"
  ) -and
  $activationScript -match (
    "(?s)contain-youtube-private-dev\.ps1.*" +
    "Invoke-DeploymentVerifier.*-ExpectContained"
  )
) "Emergency containment must complete the contained-state verifier."
Assert-True (
  $containmentScript -match "CloudRunServiceNotFound" -and
  $containmentScript -match 'run",\s*"services",\s*"describe"' -and
  $containmentScript -match "youtubeprovider" -and
  $containmentScript -match "youtubeoauthcallback"
) (
  "Hard containment must verify an absent exact Run service when a " +
  "failed Function never reached Cloud Run creation."
)

foreach ($profileName in $profileNames) {
  $profile = Get-YouTubePrivateDevProfile $profileName
  & powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot `
      "activate-youtube-private-dev-proof.ps1") `
    -Profile $profileName `
    -ProofWindowMinutes 30 `
    -Confirmation $profile.Confirmation `
    -StaticOnly
  Assert-True ($LASTEXITCODE -eq 0) `
    "$profileName static activation contract failed."
}
& powershell -NoProfile -ExecutionPolicy Bypass `
  -File (Join-Path $PSScriptRoot `
    "contain-youtube-private-dev.ps1") `
  -Confirmation "CONTAIN_YOUTUBE_PRIVATE_DEV_NOW" `
  -StaticOnly
Assert-True ($LASTEXITCODE -eq 0) `
  "Static hard-containment contract failed."

Write-Host "YouTube private Dev deployment-control tests passed locally."
