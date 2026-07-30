param(
  [string]$RepositoryRoot = "",
  [string]$BaselinePath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$defaultRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $root = $defaultRoot
} else {
  $root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
}

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
  $BaselinePath = Join-Path $root (
    "artifacts\quality\buy-protected-baseline-r35-1-20260731-28\BASELINE.json"
  )
} else {
  $BaselinePath = (Resolve-Path -LiteralPath $BaselinePath).Path
}

if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
  throw "Protected Buy baseline is missing: $BaselinePath"
}

$baseline = Get-Content -Raw -LiteralPath $BaselinePath | ConvertFrom-Json
if ([int]$baseline.schemaVersion -ne 1) {
  throw "Unsupported protected Buy baseline schema: $($baseline.schemaVersion)"
}
if ([string]::IsNullOrWhiteSpace([string]$baseline.baselineId)) {
  throw "Protected Buy baseline id is missing."
}

$utf8Strict = [Text.UTF8Encoding]::new($false, $true)
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Get-PortableSha256 {
  param([Parameter(Mandatory = $true)][string]$Path)

  $bytes = [IO.File]::ReadAllBytes($Path)
  try {
    $text = $utf8Strict.GetString($bytes)
    $bytes = $utf8NoBom.GetBytes($text.Replace("`r`n", "`n"))
  } catch {
    # Binary files and invalid UTF-8 remain governed by their raw bytes.
  }

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return [Convert]::ToHexString(
      $sha.ComputeHash($bytes)
    ).ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-RelativePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return $Path.Substring($root.Length + 1).Replace("\", "/")
}

$files = @()
$productionRoots = @(
  "apps\mobile\lib\features\buy",
  "apps\mobile\lib\ui_v2\buy"
)

foreach ($relativeRoot in $productionRoots) {
  $absoluteRoot = Join-Path $root $relativeRoot
  if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
    throw "Protected Buy source root is missing: $absoluteRoot"
  }
  $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File
}

$explicitFiles = @(
  "apps\mobile\lib\features\journey01\journey_router.dart",
  "apps\mobile\assets\prototype\moolsocial-category-media-atlas-v3a-2026.png",
  "apps\mobile\assets\prototype\moolsocial-category-media-atlas-v3b-2026.png",
  "apps\mobile\assets\prototype\moolsocial-category-media-atlas-v3c-2026.png",
  "apps\mobile\assets\prototype\moolsocial-medicine-media-atlas-v3d-2026.png",
  "apps\mobile\assets\prototype\moolsocial-product-packshot-atlas-v2-2026.png"
)

foreach ($relative in $explicitFiles) {
  $absolute = Join-Path $root $relative
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    throw "Protected Buy file is missing: $absolute"
  }
  $files += Get-Item -LiteralPath $absolute
}

$relativeFiles = @(
  $files |
    ForEach-Object { Get-RelativePath -Path $_.FullName } |
    Sort-Object -Unique
)

$expectedCount = [int]$baseline.protectedRuntime.fileCount
if ($relativeFiles.Count -ne $expectedCount) {
  throw (
    "Protected Buy inventory changed. Expected $expectedCount files but " +
    "found $($relativeFiles.Count). A founder-approved baseline replacement " +
    "is required for runtime changes."
  )
}

$lines = foreach ($relative in $relativeFiles) {
  $absolute = Join-Path $root $relative
  "$(Get-PortableSha256 -Path $absolute)  $relative"
}
$payload = ($lines -join "`n") + "`n"

$treeSha = [Security.Cryptography.SHA256]::Create()
try {
  $actualTree = [Convert]::ToHexString(
    $treeSha.ComputeHash($utf8NoBom.GetBytes($payload))
  ).ToLowerInvariant()
} finally {
  $treeSha.Dispose()
}

$expectedTree = (
  [string]$baseline.protectedRuntime.portableTreeSha256
).ToLowerInvariant()
if ($actualTree -ne $expectedTree) {
  throw (
    "Protected Buy runtime tree changed. Expected $expectedTree but found " +
    "$actualTree. A founder-approved baseline replacement is required."
  )
}

$apkRelative = [string]$baseline.candidate.retainedApk
if (-not [string]::IsNullOrWhiteSpace($apkRelative)) {
  $apkPath = Join-Path $root $apkRelative
  if (Test-Path -LiteralPath $apkPath -PathType Leaf) {
    $actualApk = (
      Get-FileHash -Algorithm SHA256 -LiteralPath $apkPath
    ).Hash.ToLowerInvariant()
    $expectedApk = (
      [string]$baseline.candidate.retainedApkSha256
    ).ToLowerInvariant()
    if ($actualApk -ne $expectedApk) {
      throw (
        "Retained Buy APK changed. Expected $expectedApk but found " +
        "$actualApk."
      )
    }
  }
}

Write-Output (
  "Protected Buy baseline passed: $($relativeFiles.Count) runtime files, " +
  "tree $actualTree."
)
