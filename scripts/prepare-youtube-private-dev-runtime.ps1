param(
  [string]$ProjectId = "moolsocial-dev-503018",
  [ValidateSet("Disabled", "PublicDataReview")]
  [string]$CapabilityProfile = "Disabled",
  [string]$Confirmation = "",
  [switch]$Materialize
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedProject = "moolsocial-dev-503018"
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot `
  "backend/functions/env/moolsocial-dev-503018.env"
$destination = Join-Path $repoRoot `
  "backend/functions/.env.moolsocial-dev-503018"

if ($ProjectId -ne $expectedProject) {
  throw "Only $expectedProject is authorized for this private Dev package."
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
  throw "The reviewed private Dev runtime environment is missing."
}

$content = Get-Content -Raw -LiteralPath $source
foreach ($required in @(
  "MOOLSOCIAL_PROVIDER_ENV=dev",
  "YOUTUBE_PUBLIC_DATA_ENABLED=false",
  "YOUTUBE_OWNER_CONNECT_ENABLED=false",
  "YOUTUBE_OWNER_ACTIONS_ENABLED=false",
  "YOUTUBE_CREATOR_ASSETS_ENABLED=false",
  "YOUTUBE_LIVE_ENABLED=false",
  "YOUTUBE_PRIVATE_UPLOAD_ENABLED=false",
  "YOUTUBE_OWNER_ANALYTICS_ENABLED=false",
  "YOUTUBE_DEV_SEARCH_DAILY_CAP=20",
  "YOUTUBE_DEV_UPLOAD_DAILY_CAP=10",
  "YOUTUBE_DEV_BATCH_STATS_DAILY_CAP=500",
  "YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100",
  "YOUTUBE_DEV_GENERAL_DAILY_CAP=2000"
)) {
  if (-not $content.Contains($required)) {
    throw "The reviewed environment is missing: $required"
  }
}
if (
  $content -match (
    "(?im)^(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_ID|" +
    "YOUTUBE_OAUTH_CLIENT_SECRET|YOUTUBE_TOKEN_ENCRYPTION_KEY_V[0-9]+)="
  )
) {
  throw "Secret values are forbidden in the runtime environment file."
}

if (-not $Materialize) {
  if ($CapabilityProfile -eq "PublicDataReview") {
    if (
      $Confirmation -ne
      $script:YouTubePrivateDevAcceptedPublicReviewConfirmation
    ) {
      throw "Accepted public review requires its exact founder confirmation."
    }
    [void](Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
      -BaselineContent $content)
  }
  Write-Host "Private Dev runtime package verified."
  Write-Host "No file was written. Use -Materialize only immediately before deployment."
  exit 0
}

if (Test-Path -LiteralPath $destination) {
  throw (
    "Refusing to overwrite the existing ignored runtime environment file. " +
    "Preserve or remove it manually after reviewing its ownership."
  )
}

if ($CapabilityProfile -eq "PublicDataReview") {
  if (
    $Confirmation -ne
    $script:YouTubePrivateDevAcceptedPublicReviewConfirmation
  ) {
    throw "Accepted public review requires its exact founder confirmation."
  }
  $runtimeContent =
    Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
      -BaselineContent $content
  Set-Content -LiteralPath $destination `
    -Value $runtimeContent `
    -Encoding Ascii
} else {
  Copy-Item -LiteralPath $source -Destination $destination
}
Write-Host "Materialized ignored Firebase runtime environment:"
Write-Host $destination
if ($CapabilityProfile -eq "PublicDataReview") {
  Write-Host "Accepted Dev PublicDataReview materialized."
  Write-Host "Every owner, upload, live and analytics capability remains disabled."
} else {
  Write-Host "All YouTube capabilities remain disabled."
}
