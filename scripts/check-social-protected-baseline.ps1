$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$baselinePath = Join-Path $root (
  "artifacts\quality\social-protected-baseline-20260729-02\BASELINE.json"
)

if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
  throw "Protected Social baseline is missing: $baselinePath"
}

$baseline = Get-Content -Raw -LiteralPath $baselinePath | ConvertFrom-Json
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
  "apps\mobile\lib\ui_v2\social",
  "apps\mobile\lib\core\youtube",
  "apps\mobile\packages\youtube_embedded_player_private_dev",
  "backend\functions\src"
)

foreach ($relativeRoot in $productionRoots) {
  $absoluteRoot = Join-Path $root $relativeRoot
  if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
    throw "Protected Social source root is missing: $absoluteRoot"
  }
  $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File |
    Where-Object {
      $_.FullName -notmatch '[\\/]\.dart_tool[\\/]' -and
      $_.FullName -notmatch '[\\/]build[\\/]' -and
      $_.Name -notmatch '\.test\.(ts|js)$'
    }
}

$explicitFiles = @(
  "apps\mobile\lib\core\navigation\youtube_connect_return_route.dart",
  "apps\mobile\android\app\src\main\kotlin\com\moolsocial\app\YouTubeConnectReturnActivity.kt",
  "apps\mobile\assets\prototype\social-market-grocery.png",
  "backend\functions\package.json",
  "backend\functions\package-lock.json",
  "backend\functions\tsconfig.json"
)

foreach ($relative in $explicitFiles) {
  $absolute = Join-Path $root $relative
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    throw "Protected Social file is missing: $absolute"
  }
  $files += Get-Item -LiteralPath $absolute
}

$testRoots = @(
  "apps\mobile\test",
  "apps\mobile\integration_test",
  "apps\mobile\test_driver"
)

foreach ($relativeRoot in $testRoots) {
  $absoluteRoot = Join-Path $root $relativeRoot
  $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File |
    Where-Object {
      $relative = Get-RelativePath -Path $_.FullName
      $relative -match '(?i)(social|youtube|screen04)' -and
      $_.FullName -notmatch '[\\/]candidate_captures[\\/]' -and
      $_.FullName -notmatch '[\\/]failures[\\/]'
    }
}

$relativeFiles = @(
  $files |
    ForEach-Object { Get-RelativePath -Path $_.FullName } |
    Sort-Object -Unique
)

function Test-SocialOverlayFacts {
  param(
    [bool]$BranchAllowed,
    [bool]$InventoryEqual,
    [bool]$OwnerBytesEqual
  )
  return $BranchAllowed -and $InventoryEqual -and $OwnerBytesEqual
}

if (
  -not (Test-SocialOverlayFacts $true $true $true) -or
  (Test-SocialOverlayFacts $false $true $true) -or
  (Test-SocialOverlayFacts $true $false $true) -or
  (Test-SocialOverlayFacts $true $true $false)
) {
  throw 'Social protected sealed-overlay fixture failed.'
}

function Get-SealedSocialOverlayInventory {
  param([Parameter(Mandatory = $true)][string]$Commit)
  $allOwners = @(& git -C $root ls-tree -r --name-only $Commit)
  if ($LASTEXITCODE -ne 0) { return @() }
  $productionPrefixes = @(
    'apps/mobile/lib/ui_v2/social/',
    'apps/mobile/lib/core/youtube/',
    'apps/mobile/packages/youtube_embedded_player_private_dev/',
    'backend/functions/src/'
  )
  $explicitOwners = @($explicitFiles | ForEach-Object { $_.Replace('\', '/') })
  $testPrefixes = @(
    'apps/mobile/test/',
    'apps/mobile/integration_test/',
    'apps/mobile/test_driver/'
  )
  $selected = foreach ($owner in $allOwners) {
    $isProduction = @($productionPrefixes | Where-Object {
      $owner.StartsWith($_, [StringComparison]::Ordinal)
    }).Count -gt 0
    if (
      $isProduction -and
      $owner -notmatch '(?i)[/](?:\.dart_tool|build)/' -and
      $owner -notmatch '(?i)\.test\.(?:ts|js)$'
    ) {
      $owner
      continue
    }
    if ($explicitOwners -ccontains $owner) {
      $owner
      continue
    }
    $isTest = @($testPrefixes | Where-Object {
      $owner.StartsWith($_, [StringComparison]::Ordinal)
    }).Count -gt 0
    if (
      $isTest -and $owner -match '(?i)(social|youtube|screen04)' -and
      $owner -notmatch '(?i)/(?:candidate_captures|failures)/'
    ) {
      $owner
    }
  }
  return @($selected | Sort-Object -Unique)
}

function Test-SealedSocialOverlay {
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
  $overlayOwners = @(Get-SealedSocialOverlayInventory $overlayCommit)
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
  return Test-SocialOverlayFacts `
    $branchAllowed $inventoryEqual $ownerBytesEqual
}

$sealedOverlayAccepted = Test-SealedSocialOverlay $relativeFiles

$expectedCount = [int]$baseline.protectedSource.fileCount
if ($relativeFiles.Count -ne $expectedCount -and -not $sealedOverlayAccepted) {
  throw (
    "Protected Social inventory changed. Expected $expectedCount files but " +
    "found $($relativeFiles.Count). A founder-approved baseline replacement " +
    "is required."
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

$expectedTree = [string]$baseline.protectedSource.portableTreeSha256
if (
  $actualTree -ne $expectedTree.ToLowerInvariant() -and
  -not $sealedOverlayAccepted
) {
  throw (
    "Protected Social tree changed. Expected $expectedTree but found " +
    "$actualTree. Buy work must not rebaseline Social."
  )
}

$apkRelative = [string]$baseline.flutter.retainedApk
$apkPath = Join-Path $root $apkRelative
if (Test-Path -LiteralPath $apkPath -PathType Leaf) {
  $actualApk = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $apkPath
  ).Hash.ToLowerInvariant()
  $expectedApk = (
    [string]$baseline.flutter.retainedApkSha256
  ).ToLowerInvariant()
  if ($actualApk -ne $expectedApk) {
    throw (
      "Retained Social APK changed. Expected $expectedApk but found " +
      "$actualApk."
    )
  }
}

Write-Output (
  "Protected Social baseline passed: $($relativeFiles.Count) files, tree " +
  "$actualTree."
)
