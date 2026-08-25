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

function Resolve-BuyProtectedBaselinePath {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [AllowEmptyString()][string]$RequestedPath = ''
  )
  $candidate = if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
    Join-Path $Root (
      'artifacts\quality\buy-protected-baseline-r40-3-20260801-49\BASELINE.json'
    )
  } else {
    [IO.Path]::GetFullPath($RequestedPath)
  }
  if (Test-Path -LiteralPath $candidate -PathType Leaf) {
    return [IO.Path]::GetFullPath($candidate)
  }
  return $null
}

$resolvedBaselinePath = Resolve-BuyProtectedBaselinePath $root $BaselinePath
$baseline = if ($null -ne $resolvedBaselinePath) {
  Get-Content -Raw -LiteralPath $resolvedBaselinePath | ConvertFrom-Json
} else {
  $null
}
if ($null -ne $baseline) {
  if ([int]$baseline.schemaVersion -ne 1) {
    throw "Unsupported protected Buy baseline schema: $($baseline.schemaVersion)"
  }
  if ([string]::IsNullOrWhiteSpace([string]$baseline.baselineId)) {
    throw "Protected Buy baseline id is missing."
  }
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
    return [BitConverter]::ToString(
      $sha.ComputeHash($bytes)
    ).Replace("-", "").ToLowerInvariant()
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

function Test-BuyOverlayFacts {
  param([bool]$BranchAllowed, [bool]$InventoryEqual, [bool]$OwnerBytesEqual)
  return $BranchAllowed -and $InventoryEqual -and $OwnerBytesEqual
}

if (
  -not (Test-BuyOverlayFacts $true $true $true) -or
  (Test-BuyOverlayFacts $false $true $true) -or
  (Test-BuyOverlayFacts $true $false $true) -or
  (Test-BuyOverlayFacts $true $true $false)
) {
  throw 'Buy protected baseline resolver fixture failed.'
}

function Get-SealedBuyOverlayInventory {
  param([Parameter(Mandatory = $true)][string]$Commit)
  $allOwners = @(& git -C $root ls-tree -r --name-only $Commit)
  if ($LASTEXITCODE -ne 0) { return @() }
  $prefixes = @(
    'apps/mobile/lib/features/buy/',
    'apps/mobile/lib/ui_v2/buy/'
  )
  $explicitOwners = @($explicitFiles | ForEach-Object { $_.Replace('\', '/') })
  $selected = foreach ($owner in $allOwners) {
    if (
      @($prefixes | Where-Object {
        $owner.StartsWith($_, [StringComparison]::Ordinal)
      }).Count -gt 0 -or
      $explicitOwners -ccontains $owner
    ) {
      $owner
    }
  }
  return @($selected | Sort-Object -Unique)
}

function Test-SealedBuyOverlay {
  param([Parameter(Mandatory = $true)][string[]]$CurrentOwners)
  $branch = (& git -C $root branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0) { return $false }
  $branchAllowed = $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  $overlayOwners = @(Get-SealedBuyOverlayInventory $overlayCommit)
  $inventoryEqual = (
    (@($CurrentOwners | Sort-Object) -join '|') -ceq
      (@($overlayOwners | Sort-Object) -join '|')
  )
  $ownerBytesEqual = $true
  if ($inventoryEqual) {
    foreach ($owner in $CurrentOwners) {
      & git -C $root diff --quiet $overlayCommit -- $owner
      if ($LASTEXITCODE -ne 0) {
        $ownerBytesEqual = $false
        break
      }
    }
  } else {
    $ownerBytesEqual = $false
  }
  return Test-BuyOverlayFacts $branchAllowed $inventoryEqual $ownerBytesEqual
}

$sealedOverlayAccepted = Test-SealedBuyOverlay $relativeFiles

if ($null -eq $baseline -and -not $sealedOverlayAccepted) {
  throw 'Protected Buy baseline is missing and no exact sealed overlay applies.'
}

$expectedCount = if ($null -ne $baseline) {
  [int]$baseline.protectedRuntime.fileCount
} else {
  $relativeFiles.Count
}
if ($relativeFiles.Count -ne $expectedCount -and -not $sealedOverlayAccepted) {
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
  $actualTree = [BitConverter]::ToString(
    $treeSha.ComputeHash($utf8NoBom.GetBytes($payload))
  ).Replace("-", "").ToLowerInvariant()
} finally {
  $treeSha.Dispose()
}

$expectedTree = if ($null -ne $baseline) {
  ([string]$baseline.protectedRuntime.portableTreeSha256).ToLowerInvariant()
} else {
  $actualTree
}
if ($actualTree -ne $expectedTree -and -not $sealedOverlayAccepted) {
  throw (
    "Protected Buy runtime tree changed. Expected $expectedTree but found " +
    "$actualTree. A founder-approved baseline replacement is required."
  )
}

$apkRelative = if ($null -ne $baseline) {
  [string]$baseline.candidate.retainedApk
} else {
  ''
}
if ($null -ne $baseline -and -not [string]::IsNullOrWhiteSpace($apkRelative)) {
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
