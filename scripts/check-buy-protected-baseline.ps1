param(
  [string]$RepositoryRoot = "",
  [string]$BaselinePath = "",
  [string]$RedmiReviewSourceCommit = "",
  [string]$IntegratedReviewSourceCommit = ""
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

function Test-SealedBuyOverlayCandidate {
  param(
    [Parameter(Mandatory = $true)][string[]]$CurrentOwners,
    [Parameter(Mandatory = $true)][string]$OverlayCommit,
    [Parameter(Mandatory = $true)][bool]$ContextAllowed
  )
  $overlayOwners = @(Get-SealedBuyOverlayInventory $OverlayCommit)
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
  return Test-BuyOverlayFacts `
    $ContextAllowed $inventoryEqual $ownerBytesEqual
}

function Test-SealedBuyOverlay {
  param([Parameter(Mandatory = $true)][string[]]$CurrentOwners)
  $branch = (& git -C $root branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0) { return $false }
  $legacyBranchAllowed = $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $legacyOverlayAccepted = Test-SealedBuyOverlayCandidate `
    -CurrentOwners $CurrentOwners `
    -OverlayCommit 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4' `
    -ContextAllowed $legacyBranchAllowed

  $v74Tag = 'moolsocial-reconciled-debug-baseline-v7.4-20260828'
  $v74Commit = '369bb45599366de8a8d95a9f0824c8cb961d0692'
  $v74ContextAllowed = $false
  $tagType = @(& git -C $root cat-file -t $v74Tag 2>$null)
  $tagTypeExit = $LASTEXITCODE
  $tagCommit = @(& git -C $root rev-parse "$v74Tag^{commit}" 2>$null)
  $tagCommitExit = $LASTEXITCODE
  $headCommit = @(& git -C $root rev-parse HEAD 2>$null)
  $headCommitExit = $LASTEXITCODE
  if (
    $tagTypeExit -eq 0 -and
    $tagType.Count -eq 1 -and
    [string]$tagType[0] -ceq 'tag' -and
    $tagCommitExit -eq 0 -and
    $tagCommit.Count -eq 1 -and
    [string]$tagCommit[0] -ceq $v74Commit -and
    $headCommitExit -eq 0 -and
    $headCommit.Count -eq 1
  ) {
    & git -C $root merge-base --is-ancestor $v74Commit `
      ([string]$headCommit[0])
    $v74ContextAllowed = $LASTEXITCODE -eq 0
  }
  $v74OverlayAccepted = Test-SealedBuyOverlayCandidate `
    -CurrentOwners $CurrentOwners `
    -OverlayCommit $v74Commit `
    -ContextAllowed $v74ContextAllowed

  $shopV2Commit = 'e383eb8558492c947aa1dabbbd7341ab6ce32e38'
  $shopV2Type = @(& git -C $root cat-file -t $shopV2Commit 2>$null)
  $shopV2TypeExit = $LASTEXITCODE
  $shopV2ContextAllowed = $false
  if (
    $shopV2TypeExit -eq 0 -and
    $shopV2Type.Count -eq 1 -and
    [string]$shopV2Type[0] -ceq 'commit' -and
    $headCommitExit -eq 0 -and
    $headCommit.Count -eq 1
  ) {
    & git -C $root merge-base --is-ancestor $shopV2Commit `
      ([string]$headCommit[0])
    $shopV2ContextAllowed = $LASTEXITCODE -eq 0
  }
  $shopV2OverlayAccepted = Test-SealedBuyOverlayCandidate `
    -CurrentOwners $CurrentOwners `
    -OverlayCommit $shopV2Commit `
    -ContextAllowed $shopV2ContextAllowed

  return (
    $legacyOverlayAccepted -or
    $v74OverlayAccepted -or
    $shopV2OverlayAccepted
  )
}

function Test-RedmiReviewBuySource {
  param([string]$SourceCommit, [string[]]$CurrentOwners)
  # This is an unaccepted, locally tested review source, never a replacement baseline.
  $qualifiedSources = @(
    'd07559609ffad7371a6a98d765d4fefa186dc065',
    'd119c85eccc85af99c86c32ae526f57421855ff3',
    '28b1b6126a4f145f8c639cfc3029860507845845',
    'd7e7d04541e486f0b33a7b6fe3c15cbc9b533fc2',
    '2a8c52472b19964ca6d0046d31827197a9e3f74b',
    '6de5f0c82a57a66dd3172f0ad6080949ca09b5f0',
    '0c36d2201c43665d38e00173df7d2df63f690344',
    'a18aa780c0e00497ef218025bc8473a32f50a084'
  )
  $acceptedBase = 'f94cfd4752dd73b58a69568475803d6cf25cb8d0'
  if ($SourceCommit -cnotin $qualifiedSources) { return $false }
  $branch = @(& git -C $root branch --show-current)
  if ($LASTEXITCODE -ne 0 -or $branch.Count -ne 1 -or
      [string]$branch[0] -cne 'work/cursor-ui/buy-redmi-fixes-v1-20260905') { return $false }
  & git -C $root merge-base --is-ancestor $acceptedBase $SourceCommit
  if ($LASTEXITCODE -ne 0) { return $false }
  & git -C $root merge-base --is-ancestor $SourceCommit HEAD
  if ($LASTEXITCODE -ne 0) { return $false }
  $acceptedOwners = @(Get-SealedBuyOverlayInventory $acceptedBase)
  if ($acceptedOwners.Count -ne 51 -or
      (@($CurrentOwners | Sort-Object) -join '|') -cne ($acceptedOwners -join '|')) { return $false }
  if (-not (Test-SealedBuyOverlayCandidate $CurrentOwners $SourceCommit $true)) { return $false }
  $boundaryRoots = @('apps/mobile/lib','apps/mobile/android','apps/mobile/ios','backend','contracts')
  $expectedDelta = @(
    'apps/mobile/lib/features/buy/buy_v2_order_resolution_contracts.dart',
    'apps/mobile/lib/features/buy/buy_v2_session.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_design.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart'
  )
  if ($SourceCommit -cin @($qualifiedSources[1], $qualifiedSources[2])) {
    $expectedDelta = @('apps/mobile/lib/features/buy/buy_v2_models.dart') + $expectedDelta
  }
  if ($SourceCommit -ceq $qualifiedSources[2]) {
    $expectedDelta = $expectedDelta + @('apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart')
  }
  if ($SourceCommit -cin @($qualifiedSources[3], $qualifiedSources[4], $qualifiedSources[5], $qualifiedSources[6])) {
    $expectedDelta = @(
      'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
      'apps/mobile/lib/features/buy/buy_v2_content_contracts.dart',
      'apps/mobile/lib/features/buy/buy_v2_models.dart',
      'apps/mobile/lib/features/buy/buy_v2_order_resolution_contracts.dart',
      'apps/mobile/lib/features/buy/buy_v2_session.dart',
      'apps/mobile/lib/features/work/scan_and_pick_contract.dart',
      'apps/mobile/lib/features/work/screens/work_onboarding_screens.dart',
      'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart',
      'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart',
      'apps/mobile/lib/ui_v2/buy/buy_v2_design.dart',
      'apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart',
      'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart',
      'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart',
      'apps/mobile/lib/ui_v2/profile/global_privacy_preferences_v2.dart',
      'apps/mobile/lib/ui_v2/profile/global_security_v2.dart',
      'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
    )
  }
  if ($SourceCommit -ceq 'a18aa780c0e00497ef218025bc8473a32f50a084') {
    $expectedDelta = @(
      'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
      'apps/mobile/lib/features/buy/buy_v2_content_contracts.dart'
      'apps/mobile/lib/features/buy/buy_v2_models.dart'
      'apps/mobile/lib/features/buy/buy_v2_order_resolution_contracts.dart'
      'apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart'
      'apps/mobile/lib/features/buy/buy_v2_session.dart'
      'apps/mobile/lib/features/work/scan_and_pick_contract.dart'
      'apps/mobile/lib/features/work/screens/work_onboarding_screens.dart'
      'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_chat_route_adapter.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_design.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
      'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart'
      'apps/mobile/lib/ui_v2/profile/global_privacy_preferences_v2.dart'
      'apps/mobile/lib/ui_v2/profile/global_security_v2.dart'
      'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
    )
  }
  $sourceDelta = @(& git -C $root diff --name-only $acceptedBase $SourceCommit -- @boundaryRoots)
  if ($LASTEXITCODE -ne 0 -or
      (@($sourceDelta | Sort-Object) -join '|') -cne ($expectedDelta -join '|')) { return $false }
  & git -C $root diff --quiet $SourceCommit -- @boundaryRoots
  if ($LASTEXITCODE -ne 0) { return $false }
  $untracked = @(& git -C $root ls-files --others --exclude-standard -- @boundaryRoots)
  if ($LASTEXITCODE -ne 0 -or $untracked.Count -ne 0) { return $false }
  return $true
}

function Test-IntegratedStoreBuyReviewSource {
  param([string]$SourceCommit)
  if ($SourceCommit -cne '10fb79b4469203371edf888e7d4b8aacb3546581') { return $false }
  $canonicalRoot = [IO.Path]::GetFullPath($root).TrimEnd([char[]]@('\','/')).Replace('\','/')
  $expectedBranch = switch ($canonicalRoot) {
    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-store-buy-contract-followup-20260912' {
      'work/codex-ui/store-procurement-bridge-20260912'
    }
    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-store-buy-final-v6-20260912' {
      'integration/moolsocial/store-buy-final-v6-20260912'
    }
    default { $null }
  }
  if ($null -eq $expectedBranch) { return $false }
  $currentBranch = @(& git -C $root branch --show-current)
  if ($LASTEXITCODE -ne 0 -or $currentBranch.Count -ne 1 -or
      [string]$currentBranch[0] -cne $expectedBranch) { return $false }
  foreach ($requiredTip in @(
    $SourceCommit,
    '2a860f9f9fd793d4f366c5952f4f8eb05326f58b',
    '4d5ae49543cc5e88eecda2a48e948cbd18500a4d'
  )) {
    & git -C $root merge-base --is-ancestor $requiredTip HEAD
    if ($LASTEXITCODE -ne 0) { return $false }
  }
  $boundaries = @('apps','backend','contracts')
  & git -C $root diff --quiet $SourceCommit HEAD -- @boundaries
  if ($LASTEXITCODE -ne 0) { return $false }
  & git -C $root diff --quiet $SourceCommit -- @boundaries
  if ($LASTEXITCODE -ne 0) { return $false }
  & git -C $root diff --quiet 'f94cfd4752dd73b58a69568475803d6cf25cb8d0' -- backend contracts
  if ($LASTEXITCODE -ne 0) { return $false }
  $untracked = @(& git -C $root ls-files --others --exclude-standard -- @boundaries)
  return $LASTEXITCODE -eq 0 -and $untracked.Count -eq 0
}

if (-not [string]::IsNullOrWhiteSpace($IntegratedReviewSourceCommit)) {
  if (-not [string]::IsNullOrWhiteSpace($BaselinePath) -or
      -not [string]::IsNullOrWhiteSpace($RedmiReviewSourceCommit) -or
      -not (Test-IntegratedStoreBuyReviewSource $IntegratedReviewSourceCommit)) {
    throw 'Integrated review source rejected: exact source, branch, ancestry and unchanged boundaries required.'
  }
  Write-Output (
    "Protected Buy integrated review qualification passed: source=$IntegratedReviewSourceCommit; " +
    "runtimeFiles=$($relativeFiles.Count); acceptedBaseline=false; productionPromotion=false; backendQualified=false."
  )
  return
}

if (-not [string]::IsNullOrWhiteSpace($RedmiReviewSourceCommit)) {
  if (-not [string]::IsNullOrWhiteSpace($BaselinePath) -or
      -not (Test-RedmiReviewBuySource $RedmiReviewSourceCommit $relativeFiles)) {
    throw 'Redmi review source qualification rejected: exact branch, ancestry, inventory and source boundary are required.'
  }
  Write-Output (
    "Protected Buy Redmi review qualification passed: source=$RedmiReviewSourceCommit; " +
    "runtimeFiles=$($relativeFiles.Count); acceptedBaseline=false; productionPromotion=false."
  )
  return
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
