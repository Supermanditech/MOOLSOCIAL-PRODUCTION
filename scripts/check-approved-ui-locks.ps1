$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "approved-references\manifest.json"
$approvedRoot = Split-Path -Parent $manifestPath

if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Approved-reference manifest is missing: $manifestPath"
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

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
