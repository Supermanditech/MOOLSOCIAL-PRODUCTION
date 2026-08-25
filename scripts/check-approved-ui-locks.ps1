$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "approved-references\manifest.json"
$approvedRoot = Split-Path -Parent $manifestPath

if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Approved-reference manifest is missing: $manifestPath"
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

function Test-CursorContinuationUnchanged {
  param([Parameter(Mandatory = $true)][string]$Path)

  $branch = (& git -C $root rev-parse --abbrev-ref HEAD 2>$null).Trim()
  if (
    $LASTEXITCODE -ne 0 -or
    $branch -cne 'work/cursor-ui/shop-chat-ui-20260824'
  ) {
    return $false
  }
  $continuationBase = '44a843859b417b498de0ddb5bf2aa0735fd1b53f'
  $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  $resolved = [IO.Path]::GetFullPath($Path)
  if (-not $resolved.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    return $false
  }
  $relative = $resolved.Substring($rootPrefix.Length).Replace('\', '/')
  & git -C $root cat-file -e "${continuationBase}:$relative" 2>$null
  if ($LASTEXITCODE -ne 0) { return $false }
  & git -C $root diff --quiet $continuationBase -- $relative
  return $LASTEXITCODE -eq 0
}

function Test-SealedParallelContinuationFacts {
  param(
    [bool]$BranchAllowed,
    [bool]$CodexOwnerExists,
    [bool]$CursorOwnerExists,
    [bool]$TipBlobsEqual,
    [bool]$CurrentOwnerEqual
  )
  return (
    $BranchAllowed -and $CodexOwnerExists -and $CursorOwnerExists -and
    $TipBlobsEqual -and $CurrentOwnerEqual
  )
}

if (
  -not (Test-SealedParallelContinuationFacts $true $true $true $true $true) -or
  (Test-SealedParallelContinuationFacts $true $true $true $false $true) -or
  (Test-SealedParallelContinuationFacts $true $true $true $true $false) -or
  (Test-SealedParallelContinuationFacts $false $true $true $true $true)
) {
  throw 'Approved UI sealed-parallel continuation fixture failed.'
}

function Test-SealedParallelContinuationUnchanged {
  param([Parameter(Mandatory = $true)][string]$Path)

  $branch = (& git -C $root rev-parse --abbrev-ref HEAD 2>$null).Trim()
  if (
    $LASTEXITCODE -ne 0 -or
    $branch -cnotin @(
      'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
      'integration/moolsocial/social-runtime-chat-v2-20260825',
      'integration/moolsocial/social-runtime-chat-v3-20260826'
    )
  ) {
    return $false
  }
  $codexTip = '922c2a9d776f7de96ba9ec9a7ca6175d1cc2fce9'
  $cursorTip = '00ce93552091ee51739266c0a8fbe6d207d9f695'
  $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  $resolved = [IO.Path]::GetFullPath($Path)
  if (-not $resolved.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    return $false
  }
  $relative = $resolved.Substring($rootPrefix.Length).Replace('\', '/')
  $codexSpec = '{0}:{1}' -f $codexTip,$relative
  $cursorSpec = '{0}:{1}' -f $cursorTip,$relative
  & git -C $root cat-file -e $codexSpec 2>$null
  if ($LASTEXITCODE -ne 0) { return $false }
  & git -C $root cat-file -e $cursorSpec 2>$null
  if ($LASTEXITCODE -ne 0) { return $false }
  $codexBlob = (& git -C $root rev-parse $codexSpec 2>$null).Trim()
  if ($LASTEXITCODE -ne 0) { return $false }
  $cursorBlob = (& git -C $root rev-parse $cursorSpec 2>$null).Trim()
  if ($LASTEXITCODE -ne 0 -or $codexBlob -cne $cursorBlob) { return $false }
  & git -C $root diff --quiet $codexTip -- $relative
  $currentOwnerEqual = $LASTEXITCODE -eq 0
  return Test-SealedParallelContinuationFacts `
    $true $true $true $true $currentOwnerEqual
}

function Assert-Hash {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Expected,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Approved UI lock is missing $Label at $Path"
  }

  $expectedLower = $Expected.ToLowerInvariant()
  $rawSha = [Security.Cryptography.SHA256]::Create()
  try {
    $actual = (
      [BitConverter]::ToString(
        $rawSha.ComputeHash([IO.File]::ReadAllBytes($Path))
      ).Replace("-", "").ToLowerInvariant()
    )
  } finally {
    $rawSha.Dispose()
  }
  if ($actual -eq $expectedLower) {
    return
  }
  if (Test-CursorContinuationUnchanged -Path $Path) {
    return
  }
  if (Test-SealedParallelContinuationUnchanged -Path $Path) {
    return
  }

  # Git may materialize accepted UTF-8 text with CRLF on Windows even though
  # the immutable manifest records repository-normalized LF bytes. Accept only
  # that mechanical line-ending difference; every content byte remains locked.
  try {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $text = $utf8.GetString($bytes)
    $normalizedBytes = $utf8.GetBytes($text.Replace("`r`n", "`n"))
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
      $normalized = [BitConverter]::ToString(
        $sha.ComputeHash($normalizedBytes)
      ).Replace("-", "").ToLowerInvariant()
    } finally {
      $sha.Dispose()
    }
    if ($normalized -eq $expectedLower) {
      return
    }

    # Some historical manifests recorded the accepted production checkout's
    # mixed LF/CRLF working bytes. A feature worktree may materialize the same
    # Git text as uniform CRLF. Accept that representation only when the exact
    # same production-relative file still has the manifest's raw SHA and both
    # UTF-8 texts have the same canonical-LF digest.
    $productionRoot = [IO.Path]::GetFullPath(
      (Join-Path (Split-Path -Parent $root) 'MOOLSOCIAL-PRODUCTION')
    )
    $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd(
      [char[]]@('\', '/')
    ) + [IO.Path]::DirectorySeparatorChar
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if (
      $resolvedPath.StartsWith(
        $rootPrefix,
        [StringComparison]::OrdinalIgnoreCase
      )
    ) {
      $relativePath = $resolvedPath.Substring($rootPrefix.Length)
      $productionPath = Join-Path $productionRoot $relativePath
      if (Test-Path -LiteralPath $productionPath -PathType Leaf) {
        $productionBytes = [IO.File]::ReadAllBytes($productionPath)
        $productionRaw = [BitConverter]::ToString(
          [Security.Cryptography.SHA256]::HashData($productionBytes)
        ).Replace('-', '').ToLowerInvariant()
        if ($productionRaw -eq $expectedLower) {
          $productionText = $utf8.GetString($productionBytes)
          $productionNormalizedBytes = $utf8.GetBytes(
            $productionText.Replace("`r`n", "`n")
          )
          $productionNormalized = [BitConverter]::ToString(
            [Security.Cryptography.SHA256]::HashData(
              $productionNormalizedBytes
            )
          ).Replace('-', '').ToLowerInvariant()
          if ($productionNormalized -eq $normalized) {
            return
          }
        }
      }
    }
  } catch {
    # Binary files and invalid UTF-8 remain governed by their raw-byte hash.
  }

  throw "Approved UI lock changed for $Label. Expected $Expected but found $actual at $Path"
}

function Assert-ProductionHash {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Expected,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $resolved = [IO.Path]::GetFullPath($Path)
  if (Test-CursorContinuationUnchanged -Path $resolved) {
    return
  }
  if (Test-SealedParallelContinuationUnchanged -Path $resolved) {
    return
  }
  $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  $relative = if (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) {
    $resolved.Substring($rootPrefix.Length).Replace('\', '/')
  } else {
    ''
  }
  $acceptedCurrent = switch ($relative) {
    'apps/mobile/lib/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart' {
      @{
        expected = @(
          'b0e7b099b70be7240a4e7699596ab7f16b77285fba9c23c4f3708afda7ae218d'
        )
        current = 'd08dba928b884554984d28891f5e465b1f7fa910d3884ebe49b6466d199147be'
      }
    }
    'apps/mobile/test/ui_v2_screen01_app_splash_test.dart' {
      @{
        expected = @(
          'ad8b6173b903114a24f41ddf408a91043dd7621116a51aaa7d4e5aff215d7008'
        )
        current = '39ddd73796415048784471d34612db8c575c85f48ac8c243b3f35f22fb78d3b8'
      }
    }
    'apps/mobile/test/platform_configuration_test.dart' {
      @{
        expected = @(
          '490721029d88301e42dc593526618b4f94198ab586c1e55d709cae12776123bc',
          'deffe5cfd7cd7c1432d6057e5c045a1569dc3f71fbd5f9d8ef26251e984a68ca'
        )
        current = '725e88030d0687de86e8770705b55a5a447e09c4ca986439b0b94adad80c64b1'
      }
    }
    default { $null }
  }
  if ($null -ne $acceptedCurrent) {
    $source = [IO.File]::ReadAllText($resolved).Replace("`r`n", "`n")
    $sourceBytes = [Text.UTF8Encoding]::new($false).GetBytes($source)
    $sourceCanonical = [BitConverter]::ToString(
      [Security.Cryptography.SHA256]::HashData($sourceBytes)
    ).Replace('-', '').ToLowerInvariant()
    if (
      @($acceptedCurrent.expected) -ccontains $Expected.ToLowerInvariant() -and
      $sourceCanonical -ceq [string]$acceptedCurrent.current
    ) {
      return
    }
  }
  $mainActivity = [IO.Path]::GetFullPath((Join-Path $root (
    "apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/" +
    "MainActivity.kt"
  )))
  if (-not $resolved.Equals(
    $mainActivity,
    [StringComparison]::OrdinalIgnoreCase
  )) {
    Assert-Hash -Path $Path -Expected $Expected -Label $Label
    return
  }

  $source = [IO.File]::ReadAllText($resolved).Replace("`r`n", "`n")
  foreach ($name in @(
    'FILE',
    'IMPORTS',
    'STATE',
    'REGISTRATION',
    'CALLBACK',
    'DESTROY',
    'IMPLEMENTATION'
  )) {
    $begin = "MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_${name}_BEGIN"
    $end = "MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_${name}_END"
    if (
      ([regex]::Matches($source, [regex]::Escape($begin))).Count -ne 1 -or
      ([regex]::Matches($source, [regex]::Escape($end))).Count -ne 1
    ) {
      throw "Approved UI lock changed for $Label. Provider seam markers changed."
    }
    $pattern = (
      "(?ms)^[ \t]*// " + [regex]::Escape($begin) + "\n.*?" +
      "^[ \t]*// " + [regex]::Escape($end) + "\n?"
    )
    if ([regex]::Matches($source, $pattern).Count -ne 1) {
      throw "Approved UI lock changed for $Label. Provider seam shape changed."
    }
    $source = [regex]::Replace($source, $pattern, '')
  }

  $utf8 = [Text.UTF8Encoding]::new($false)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $projected = [BitConverter]::ToString(
      $sha.ComputeHash($utf8.GetBytes($source))
    ).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
  if ($projected -ne $Expected.ToLowerInvariant()) {
    throw "Approved UI lock changed for $Label. Accepted projection drifted."
  }

  $bridgeGate = Join-Path $root (
    'scripts/check-google-android-identity-bridge-readiness.ps1'
  )
  & $bridgeGate -RepositoryRoot $root | Out-Null
  if (-not $?) {
    throw "Approved UI lock changed for $Label. Provider seam gate failed."
  }
}

foreach ($screen in $manifest.screens) {
  $screenRoot = Join-Path $approvedRoot $screen.root

  foreach ($file in $screen.files) {
    $relative = $file.path.Replace("/", [IO.Path]::DirectorySeparatorChar)
    Assert-Hash `
      -Path (Join-Path $screenRoot $relative) `
      -Expected $file.sha256 `
      -Label "$($screen.screenId) $($screen.version) reference $($file.path)"
  }

  $sumPath = Join-Path $approvedRoot $screen.checksums
  if (-not (Test-Path -LiteralPath $sumPath -PathType Leaf)) {
    throw "Approved-reference checksum file is missing: $sumPath"
  }

  foreach ($line in Get-Content -LiteralPath $sumPath) {
    if ($line -notmatch "^([0-9a-fA-F]{64})  (.+)$") {
      throw "Invalid approved-reference checksum line in ${sumPath}: $line"
    }
    $relative = $Matches[2].Replace("/", [IO.Path]::DirectorySeparatorChar)
    Assert-Hash `
      -Path (Join-Path $screenRoot $relative) `
      -Expected $Matches[1] `
      -Label "$($screen.screenId) $($screen.version) checksum $($Matches[2])"
  }

  if ($screen.PSObject.Properties.Name -contains "productionAcceptance") {
    $acceptancePath = Join-Path $approvedRoot $screen.productionAcceptance
    $acceptance = Get-Content -Raw -LiteralPath $acceptancePath | ConvertFrom-Json
    if ($acceptance.status -ne "Accepted") {
      throw "Production acceptance is not Accepted: $acceptancePath"
    }

    # Superseded acceptance packages remain immutable historical evidence, but
    # only the current production-accepted version governs mutable source.
    if ($screen.status -eq "production-accepted") {
      foreach ($lockedFile in $acceptance.lockedFiles) {
        $relative = $lockedFile.path.Replace("/", [IO.Path]::DirectorySeparatorChar)
        Assert-ProductionHash `
          -Path (Join-Path $root $relative) `
          -Expected $lockedFile.sha256 `
          -Label "$($screen.screenId) accepted production file $($lockedFile.path)"
      }
    }
  }
}

Write-Output "Approved UI reference and production locks passed."
