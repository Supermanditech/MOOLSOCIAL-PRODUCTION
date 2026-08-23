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
$expectedConfirmation = "DEPLOY_C30T_DEV_FIREBASE_HOSTING_ONLY"

Assert-C30T ($ProjectId -ceq $script:C30TProject) `
  "only the exact Dev project is authorized"
$context = Get-C30TAuthorization `
  -RepositoryRoot $root `
  -RequireDeploymentReady:($Mode -eq "Deploy")
$authorization = $context.Authorization
Assert-C30TManifestSection `
  -RepositoryRoot $root `
  -Section $context.Manifest.hosting `
  -ExpectedFingerprint `
    ([string]$authorization.predeploymentEvidence.sourceManifest.hostingFingerprint) `
  -Label "hosting"

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
Invoke-C30TChecked {
  node --test (Join-Path $root "apps/web/tests/firebase-public-site.test.mjs")
} "Firebase public-site tests failed"

$siteOutput = & firebase hosting:sites:get $script:C30THostingSite `
  --project $ProjectId 2>$null
Assert-C30T ($LASTEXITCODE -eq 0) "exact Firebase Hosting site is unavailable"
Assert-C30T (
  ($siteOutput | Out-String).Contains($script:C30THostingSite)
) "Firebase Hosting site identity changed"

if ($Mode -eq "Validate") {
  Write-Host "C30T Dev Firebase Hosting deployment control passed locally."
  Write-Host "No Hosting release or external resource was changed."
  return
}
Assert-C30T ($Confirmation -ceq $expectedConfirmation) `
  "deployment requires -Confirmation $expectedConfirmation"

$beforeOutput = & firebase hosting:channel:list `
  --site $script:C30THostingSite `
  --project $ProjectId `
  --json 2>$null
Assert-C30T ($LASTEXITCODE -eq 0) "unable to inspect live Hosting channel"
$before = ($beforeOutput | Out-String) | ConvertFrom-Json
$beforeLive = @($before.result.channels | Where-Object {
  $_.name -ceq (
    "projects/$ProjectId/sites/$($script:C30THostingSite)/channels/live"
  )
})
Assert-C30T ($beforeLive.Count -eq 1) "live Hosting channel identity changed"
$beforeRelease = [string]$beforeLive[0].release.name
Assert-C30T (-not [string]::IsNullOrWhiteSpace($beforeRelease)) `
  "live Hosting predecessor release is missing"

Invoke-C30TChecked {
  firebase deploy `
    --only hosting `
    --project $ProjectId `
    --message "C30T Dev reviewer compliance Hosting dry run" `
    --dry-run
} "exact Firebase Hosting dry run failed"
Invoke-C30TChecked {
  firebase deploy `
    --only hosting `
    --project $ProjectId `
    --message "C30T Dev reviewer compliance Hosting"
} "exact Firebase Hosting deployment failed"

$afterOutput = & firebase hosting:channel:list `
  --site $script:C30THostingSite `
  --project $ProjectId `
  --json 2>$null
Assert-C30T ($LASTEXITCODE -eq 0) "unable to read back live Hosting channel"
$after = ($afterOutput | Out-String) | ConvertFrom-Json
$afterLive = @($after.result.channels | Where-Object {
  $_.name -ceq (
    "projects/$ProjectId/sites/$($script:C30THostingSite)/channels/live"
  )
})
Assert-C30T ($afterLive.Count -eq 1) "live Hosting channel disappeared"
$afterRelease = [string]$afterLive[0].release.name
Assert-C30T (
  -not [string]::IsNullOrWhiteSpace($afterRelease) -and
  $afterRelease -cne $beforeRelease -and
  $afterLive[0].release.type -ceq "DEPLOY" -and
  $afterLive[0].release.version.status -ceq "FINALIZED" -and
  $afterLive[0].release.releaseUser.email -ceq $script:C30TAccount
) "Hosting did not advance to one finalized founder release"

$routes = [ordered]@{
  "/" = "India Ka Social Commerce App"
  "/privacy" = "uses YouTube API Services"
  "/terms" = "External providers remain separate services"
  "/support" = "hello@moolsocial.com"
  "/youtube-api" = "Google Play Internal Testing (private)"
  "/disconnect" = "Manage connected accounts and services"
  "/delete-account" = "cannot delete data held independently by another provider"
}
foreach ($origin in @(
  "https://moolsocial-dev-503018.web.app",
  "https://moolsocial.com"
)) {
  foreach ($route in $routes.GetEnumerator()) {
    $response = Invoke-WebRequest -Uri ($origin + $route.Key) `
      -MaximumRedirection 5 -TimeoutSec 30
    Assert-C30T ($response.StatusCode -eq 200) `
      "Hosting readback failed: $origin$($route.Key)"
    Assert-C30T ($response.Content.Contains($route.Value)) `
      "Hosting marker missing: $origin$($route.Key)"
    Assert-C30T (
      [string]$response.Headers."X-Content-Type-Options" -eq "nosniff"
    ) "Hosting security header missing: $origin$($route.Key)"
  }
}

$assetLinksResponse = Invoke-WebRequest `
  -Uri "https://moolsocial-dev-503018.web.app/.well-known/assetlinks.json" `
  -TimeoutSec 30
$assetLinks = $assetLinksResponse.Content | ConvertFrom-Json
Assert-C30T (
  @($assetLinks).Count -eq 1 -and
  $assetLinks[0].target.package_name -ceq "com.moolsocial.app" -and
  @($assetLinks[0].target.sha256_cert_fingerprints).Count -eq 1 -and
  $assetLinks[0].target.sha256_cert_fingerprints[0] -ceq
    "47:B2:8C:7D:DE:2B:61:CA:B6:A7:74:8C:90:19:A3:B5:73:76:B3:BE:1D:C1:63:D4:82:53:BB:A3:5B:63:CD:D9"
) "Hosting App Links identity changed"

Write-Host "C30T Dev Firebase Hosting deployed and verified: $afterRelease"
