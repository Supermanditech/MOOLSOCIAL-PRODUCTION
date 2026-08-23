[CmdletBinding()]
param(
  [ValidateSet("Validate", "Deploy")]
  [string]$Mode = "Validate",
  [string]$ProjectId = "moolsocial-dev-503018",
  [string]$Confirmation = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "c30t-provider-hosting-deployment-common.ps1")
. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedConfirmation = "DEPLOY_C30T_DEV_YOUTUBE_PROVIDER_ONLY"
$runtimePath = Join-Path $root `
  "backend/functions/.env.moolsocial-dev-503018"
$baselinePath = Join-Path $root `
  "backend/functions/env/moolsocial-dev-503018.env"

Assert-C30T ($ProjectId -ceq $script:C30TProject) `
  "only the exact Dev project is authorized"
$context = Get-C30TAuthorization `
  -RepositoryRoot $root `
  -RequireDeploymentReady:($Mode -eq "Deploy")
$authorization = $context.Authorization
Assert-C30TManifestSection `
  -RepositoryRoot $root `
  -Section $context.Manifest.provider `
  -ExpectedFingerprint `
    ([string]$authorization.predeploymentEvidence.sourceManifest.providerFingerprint) `
  -Label "provider"

Invoke-C30TChecked {
  & (Join-Path $PSScriptRoot `
    "check-codex-development-regression-memory.ps1") `
    -RepositoryRoot $root -Phase implementation -BuildMode none
} "regression-memory gate failed"
Invoke-C30TChecked {
  & (Join-Path $PSScriptRoot "check-mvp-scope-gate-state.ps1") `
    -RepositoryRoot $root -RequireExecutionAuthorized
} "MVP execution-authority gate failed"
Invoke-C30TChecked {
  & (Join-Path $PSScriptRoot `
    "check-mvp-delivery-discipline-lock.ps1") `
    -RepositoryRoot $root -RequireTicketSelectionAssessment
} "MVP delivery-discipline lock failed"

Assert-C30T (Test-Path -LiteralPath $runtimePath -PathType Leaf) `
  "pre-existing ignored runtime is missing"
$originalRuntimeHash = Get-C30TSha256 $runtimePath
Assert-C30T (
  $originalRuntimeHash -ceq [string]$authorization.runtimePreservation.sha256
) "pre-existing ignored runtime checksum changed"
$originalRuntimeBytes = [IO.File]::ReadAllBytes($runtimePath)
$originalRuntimeText = [Text.Encoding]::UTF8.GetString($originalRuntimeBytes)
Assert-C30T (
  $originalRuntimeText -notmatch (
    "(?im)^(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_ID|" +
    "YOUTUBE_OAUTH_CLIENT_SECRET|YOUTUBE_TOKEN_ENCRYPTION_KEY_V[0-9]+)="
  )
) "a forbidden secret variable name is present in the ignored runtime"

$baseline = Get-Content -Raw -LiteralPath $baselinePath
$reviewRuntime = Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
  -BaselineContent $baseline
$reviewRuntimeNormalized = $reviewRuntime -replace "`r`n", "`n"
foreach ($expectedLine in @(
  "YOUTUBE_PUBLIC_DATA_ENABLED=true",
  "YOUTUBE_OWNER_CONNECT_ENABLED=true",
  "YOUTUBE_OWNER_ACTIONS_ENABLED=false",
  "YOUTUBE_CREATOR_ASSETS_ENABLED=false",
  "YOUTUBE_LIVE_ENABLED=false",
  "YOUTUBE_PRIVATE_UPLOAD_ENABLED=false",
  "YOUTUBE_OWNER_ANALYTICS_ENABLED=false",
  "YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted"
)) {
  Assert-C30T (
    ([regex]::Matches(
      $reviewRuntimeNormalized,
      "(?m)^" + [regex]::Escape($expectedLine) + "$"
    )).Count -eq 1
  ) "accepted review runtime is missing: $expectedLine"
}
Assert-C30T (
  $reviewRuntime -notmatch (
    "(?im)^(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_ID|" +
    "YOUTUBE_OAUTH_CLIENT_SECRET|YOUTUBE_TOKEN_ENCRYPTION_KEY_V[0-9]+)="
  )
) "accepted review runtime contains a forbidden secret variable name"
$reviewRuntimeHash = (
  [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData(
      [Text.Encoding]::ASCII.GetBytes($reviewRuntime)
    )
  )
)
Assert-C30T (
  $reviewRuntimeHash -ceq
    [string]$context.Manifest.provider.runtimeMaterializationSha256
) "accepted review runtime materialization checksum changed"

$originalRestored = $false
try {
  [IO.File]::WriteAllText(
    $runtimePath,
    $reviewRuntime,
    [Text.ASCIIEncoding]::new()
  )
  Assert-C30T ((Get-C30TSha256 $runtimePath) -ceq $reviewRuntimeHash) `
    "temporary accepted review runtime write changed"

  if ($Mode -eq "Validate") {
    & pwsh -NoProfile -File (
      Join-Path $PSScriptRoot "deploy-youtube-provider-c30m.ps1"
    ) -Mode Validate -ProjectId $ProjectId
    Assert-C30T ($LASTEXITCODE -eq 0) `
      "delegated provider package validation failed"
  } else {
    Assert-C30T ($Confirmation -ceq $expectedConfirmation) `
      "deployment requires -Confirmation $expectedConfirmation"
    & pwsh -NoProfile -File (
      Join-Path $PSScriptRoot "deploy-youtube-provider-c30m.ps1"
    ) -Mode Deploy `
      -ProjectId $ProjectId `
      -Confirmation "DEPLOY_C30M_DEV_YOUTUBE_PROVIDER_ONLY" `
      -ExpectedProviderRevision `
        ([string]$authorization.predecessors.youtubeprovider) `
      -ExpectedOAuthCallbackRevision `
        ([string]$authorization.predecessors.youtubeoauthcallback) `
      -ExpectedSocialContentRevision `
        ([string]$authorization.predecessors.moolsocialcontent)
    Assert-C30T ($LASTEXITCODE -eq 0) "provider-only deployment owner failed"
  }
} finally {
  [IO.File]::WriteAllBytes($runtimePath, $originalRuntimeBytes)
  $originalRestored = (
    (Get-C30TSha256 $runtimePath) -ceq $originalRuntimeHash
  )
}
Assert-C30T $originalRestored `
  "pre-existing ignored runtime was not restored byte-for-byte"

if ($Mode -eq "Validate") {
  Write-Host "C30T Dev youtubeProvider deployment control passed locally."
  Write-Host "Original ignored runtime restored; no external resource changed."
  return
}

$provider = Get-C30TCloudRunState "youtubeprovider" $ProjectId
$callback = Get-C30TCloudRunState "youtubeoauthcallback" $ProjectId
$content = Get-C30TCloudRunState "moolsocialcontent" $ProjectId
$chat = Get-C30TCloudRunState "moolsocialchat" $ProjectId
$newRevision = [string]$provider.status.latestReadyRevisionName
Assert-C30T (
  -not [string]::IsNullOrWhiteSpace($newRevision) -and
  $newRevision -cne [string]$authorization.predecessors.youtubeprovider -and
  $provider.status.latestCreatedRevisionName -ceq $newRevision
) "provider did not advance to one fresh ready revision"
Assert-C30TExactTraffic $provider $newRevision "youtubeProvider"
foreach ($unchanged in @(
  @{ State = $callback; Revision = $authorization.predecessors.youtubeoauthcallback; Label = "youtubeOAuthCallback" },
  @{ State = $content; Revision = $authorization.predecessors.moolsocialcontent; Label = "moolSocialContent" },
  @{ State = $chat; Revision = $authorization.predecessors.moolsocialchat; Label = "moolSocialChat" }
)) {
  Assert-C30T (
    $unchanged.State.status.latestReadyRevisionName -ceq $unchanged.Revision -and
    $unchanged.State.status.latestCreatedRevisionName -ceq $unchanged.Revision
  ) "$($unchanged.Label) revision changed"
  Assert-C30TExactTraffic $unchanged.State $unchanged.Revision $unchanged.Label
}

$environment = @{}
foreach ($entry in @($provider.spec.template.spec.containers[0].env)) {
  if ($entry.PSObject.Properties.Name -contains "value") {
    $environment[[string]$entry.name] = [string]$entry.value
  }
}
foreach ($expected in @{
  YOUTUBE_PUBLIC_DATA_ENABLED = "true"
  YOUTUBE_OWNER_CONNECT_ENABLED = "true"
  YOUTUBE_OWNER_ACTIONS_ENABLED = "false"
  YOUTUBE_CREATOR_ASSETS_ENABLED = "false"
  YOUTUBE_LIVE_ENABLED = "false"
  YOUTUBE_PRIVATE_UPLOAD_ENABLED = "false"
  YOUTUBE_OWNER_ANALYTICS_ENABLED = "false"
  YOUTUBE_PUBLIC_DATA_REVIEW_MODE = "accepted"
}.GetEnumerator()) {
  Assert-C30T (
    $environment.ContainsKey($expected.Key) -and
    $environment[$expected.Key] -ceq $expected.Value
  ) "provider runtime capability readback changed: $($expected.Key)"
}
Assert-C30T (
  $provider.metadata.annotations."run.googleapis.com/invoker-iam-disabled" -ceq "true"
) "provider no-invoker-IAM-check posture changed"

Write-Host "C30T Dev youtubeProvider deployed and contained: $newRevision"
Write-Host "Original ignored runtime restored: $originalRuntimeHash"
