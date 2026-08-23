[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$OutputPath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$output = if ([IO.Path]::IsPathRooted($OutputPath)) {
  [IO.Path]::GetFullPath($OutputPath)
} else {
  [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
}
if (Test-Path -LiteralPath $output) {
  throw "C30T source manifest already exists and is immutable: $output"
}

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

function Get-Record {
  param([Parameter(Mandatory = $true)][string]$AbsolutePath)
  $full = [IO.Path]::GetFullPath($AbsolutePath)
  if (-not $full.StartsWith($root + [IO.Path]::DirectorySeparatorChar)) {
    throw "Source path escaped the repository: $full"
  }
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
    throw "Source file is missing: $full"
  }
  $relative = $full.Substring($root.Length + 1).Replace("\", "/")
  $item = Get-Item -LiteralPath $full
  [pscustomobject]@{
    path = $relative
    bytes = [long]$item.Length
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToUpperInvariant()
  }
}

function Get-Fingerprint {
  param([Parameter(Mandatory = $true)][object[]]$Records)
  $payload = (
    @($Records | Sort-Object path | ForEach-Object {
      "$($_.path)|$($_.bytes)|$($_.sha256)"
    }) -join "`n"
  ) + "`n"
  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData(
      [Text.Encoding]::UTF8.GetBytes($payload)
    )
  )
}

$providerPaths = @(
  Get-ChildItem -LiteralPath (Join-Path $root "backend/functions/src") `
    -Recurse -File -Filter "*.ts" | ForEach-Object FullName
  @(
    "backend/functions/env/moolsocial-dev-503018.env",
    "backend/functions/package-lock.json",
    "backend/functions/package.json",
    "backend/functions/tsconfig.json",
    "deployment/youtube-private-dev/deployment-manifest.json",
    "firebase.json",
    "scripts/c30t-provider-hosting-deployment-common.ps1",
    "scripts/check-codex-development-regression-memory.ps1",
    "scripts/check-mvp-delivery-discipline-lock.ps1",
    "scripts/check-mvp-scope-gate-state.ps1",
    "scripts/check-youtube-private-dev-content.ps1",
    "scripts/check-youtube-private-dev-exports.mjs",
    "scripts/check-youtube-private-dev-package.ps1",
    "scripts/check-youtube-private-dev-preflight.ps1",
    "scripts/deploy-c30t-dev-provider-only.ps1",
    "scripts/deploy-youtube-provider-c30m.ps1",
    "scripts/prepare-youtube-private-dev-runtime.ps1",
    "scripts/test-c30t-dev-provider-hosting-deployment-controls.ps1",
    "scripts/test-youtube-provider-c30m-deployment-controls.ps1",
    "scripts/youtube-private-dev-control-common.ps1"
  ) | ForEach-Object { Join-Path $root $_ }
)
$provider = @($providerPaths | Sort-Object -Unique | ForEach-Object {
  Get-Record $_
})

$hostingPaths = @(
  Get-ChildItem -LiteralPath (Join-Path $root "apps/web/public") `
    -Recurse -File | ForEach-Object FullName
  @(
    "apps/web/tests/firebase-public-site.test.mjs",
    "firebase.json",
    "scripts/c30t-provider-hosting-deployment-common.ps1",
    "scripts/check-codex-development-regression-memory.ps1",
    "scripts/check-mvp-delivery-discipline-lock.ps1",
    "scripts/check-mvp-scope-gate-state.ps1",
    "scripts/deploy-c30t-dev-hosting-only.ps1",
    "scripts/test-c30t-dev-provider-hosting-deployment-controls.ps1"
  ) | ForEach-Object { Join-Path $root $_ }
)
$hosting = @($hostingPaths | Sort-Object -Unique | ForEach-Object {
  Get-Record $_
})

$baseline = Get-Content -Raw -LiteralPath (
  Join-Path $root "backend/functions/env/moolsocial-dev-503018.env"
)
$reviewRuntime = Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent `
  -BaselineContent $baseline
$runtimeHash = [Convert]::ToHexString(
  [Security.Cryptography.SHA256]::HashData(
    [Text.Encoding]::ASCII.GetBytes($reviewRuntime)
  )
)
$branch = (& git -C $root rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
$head = (& git -C $root rev-parse HEAD 2>$null | Out-String).Trim()
if (
  $branch -cne "remediation/prototype-conformance-2026-07-20" -or
  $head -cne "f6dfe7587aa02d782e94282d14af8bafff48ded0"
) { throw "C30T source manifest branch or HEAD changed." }

$manifest = [ordered]@{
  schemaVersion = 2
  manifestId = "UAW-C30T-DEV-PROVIDER-HOSTING-SOURCE-MANIFEST-20260813-FINAL"
  ticketId = "UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T"
  branch = $branch
  head = $head
  fingerprintAlgorithm = "sha256-utf8-sorted-path-pipe-bytes-pipe-sha256-lf-v1"
  provider = [ordered]@{
    deployTarget = "functions:provider:youtubeProvider"
    fileCount = $provider.Count
    sourceFingerprint = Get-Fingerprint $provider
    runtimeMaterializationSha256 = $runtimeHash
    files = $provider
  }
  hosting = [ordered]@{
    site = "moolsocial-dev-503018"
    fileCount = $hosting.Count
    sourceFingerprint = Get-Fingerprint $hosting
    files = $hosting
  }
}
$directory = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $directory)
}
[IO.File]::WriteAllText(
  $output,
  ($manifest | ConvertTo-Json -Depth 10) + "`r`n",
  [Text.UTF8Encoding]::new($false)
)
Write-Host "C30T source manifest sealed: $output"
Write-Host "Provider fingerprint: $($manifest.provider.sourceFingerprint)"
Write-Host "Hosting fingerprint: $($manifest.hosting.sourceFingerprint)"
