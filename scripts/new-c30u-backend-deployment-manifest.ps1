[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$OutputPath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$output = if ([IO.Path]::IsPathRooted($OutputPath)) {
  [IO.Path]::GetFullPath($OutputPath)
} else {
  [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
}
if (-not $output.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C30U deployment manifest output escaped the repository.'
}
if (Test-Path -LiteralPath $output) {
  throw "C30U deployment manifest is immutable and already exists: $output"
}

function Get-C30URecord {
  param([Parameter(Mandatory)][string]$AbsolutePath)
  $full = [IO.Path]::GetFullPath($AbsolutePath)
  if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "C30U deployment source escaped the repository: $full"
  }
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
    throw "C30U deployment source is missing: $full"
  }
  $relative = $full.Substring($root.Length + 1).Replace('\', '/')
  $item = Get-Item -LiteralPath $full
  [pscustomobject]@{
    path = $relative
    bytes = [long]$item.Length
    sha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()
  }
}

function Get-C30UFingerprint {
  param([Parameter(Mandatory)][object[]]$Records)
  $payload = (@($Records | Sort-Object path | ForEach-Object {
    "$($_.path)|$($_.bytes)|$($_.sha256)"
  }) -join "`n") + "`n"
  [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($payload))
  )
}

$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
if (
  $branch -cne 'remediation/prototype-conformance-2026-07-20' -or
  $head -cne 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) { throw 'C30U deployment source branch or HEAD changed.' }

$runtimePath = Join-Path $root 'backend/functions/.env.moolsocial-dev-503018'
$runtimeHash = (Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash
if ($runtimeHash -cne '5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702') {
  throw 'C30U restored ignored backend environment checksum changed.'
}

$backendPaths = @(
  Get-ChildItem -LiteralPath (Join-Path $root 'backend/functions/src') -Recurse -File -Filter '*.ts' |
    ForEach-Object FullName
  @(
    'backend/functions/package.json',
    'backend/functions/package-lock.json',
    'backend/functions/tsconfig.json',
    'backend/functions/env/moolsocial-dev-503018.env',
    'backend/functions/.env.moolsocial-dev-503018',
    'firebase.json'
  ) | ForEach-Object { Join-Path $root $_ }
)
$backend = @($backendPaths | Sort-Object -Unique | ForEach-Object { Get-C30URecord $_ })

$hostingPaths = @(
  Get-ChildItem -LiteralPath (Join-Path $root 'apps/web/public') -Recurse -File |
    ForEach-Object FullName
  @('apps/web/tests/firebase-public-site.test.mjs', 'firebase.json') |
    ForEach-Object { Join-Path $root $_ }
)
$hosting = @($hostingPaths | Sort-Object -Unique | ForEach-Object { Get-C30URecord $_ })

$predecessorManifestPath = Join-Path $root 'artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/01-provider-hosting-source-manifest.json'
$predecessorManifest = Get-Content -Raw -LiteralPath $predecessorManifestPath | ConvertFrom-Json
$predecessorHostingPayload = @($predecessorManifest.hosting.files | Where-Object {
  [string]$_.path -eq 'firebase.json' -or
  [string]$_.path -eq 'apps/web/tests/firebase-public-site.test.mjs' -or
  [string]$_.path -like 'apps/web/public/*'
})
if ($predecessorHostingPayload.Count -ne $hosting.Count) {
  throw 'C30U Hosting payload file count differs from the deployed-source predecessor.'
}
$predecessorHostingFingerprint = Get-C30UFingerprint $predecessorHostingPayload
$currentHostingFingerprint = Get-C30UFingerprint $hosting
if ($currentHostingFingerprint -cne $predecessorHostingFingerprint) {
  throw 'C30U Hosting payload changed; Hosting deployment remains unauthorized.'
}

$manifest = [ordered]@{
  schemaVersion = 1
  manifestId = 'UAW-C30U-DEV-MOOLSOCIALCONTENT-DEPLOYMENT-PAYLOAD-20260813'
  ticketId = 'UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE'
  branch = $branch
  head = $head
  project = 'moolsocial-dev-503018'
  region = 'asia-south1'
  exactDeployTarget = 'functions:provider:moolSocialContent'
  restoredIgnoredEnvironmentSha256 = $runtimeHash
  ignoredEnvironmentValuesReadByAgent = $false
  fingerprintAlgorithm = 'sha256-utf8-sorted-path-pipe-bytes-pipe-sha256-lf-v1'
  backendPayload = [ordered]@{
    fileCount = $backend.Count
    sourceFingerprint = Get-C30UFingerprint $backend
    files = $backend
  }
  hostingPayload = [ordered]@{
    deploymentAuthorized = $false
    currentFileCount = $hosting.Count
    currentFingerprint = $currentHostingFingerprint
    predecessorFingerprint = $predecessorHostingFingerprint
    unchanged = $true
    files = $hosting
  }
}
$directory = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $directory)
}
[IO.File]::WriteAllText(
  $output,
  ($manifest | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
  [Text.UTF8Encoding]::new($false)
)
Write-Output "C30U backend deployment manifest sealed: $OutputPath"
Write-Output "backendFiles=$($backend.Count); backendFingerprint=$($manifest.backendPayload.sourceFingerprint); HostingUnchanged=$($manifest.hostingPayload.unchanged)"
