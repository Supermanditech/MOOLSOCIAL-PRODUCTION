$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "approved-references\manifest.json"
$approvedRoot = Split-Path -Parent $manifestPath
$coordinationPath = Join-Path $root "config\codex-subagent-coordination-policy.json"
$coordination = Get-Content -Raw -LiteralPath $coordinationPath | ConvertFrom-Json
$productionRoot = [IO.Path]::GetFullPath(
  [string]$coordination.productionGitDiscipline.productionCheckout
).TrimEnd([char[]]@('\', '/'))

if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Approved-reference manifest is missing: $manifestPath"
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$script:currentSplashPendingFounderOppoAcceptance = $false
$script:acceptedGoogleBaselineReused = $false

function Get-Sha256Hex {
  param([Parameter(Mandatory = $true)][byte[]]$Bytes)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString(
      $sha.ComputeHash($Bytes)
    ).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-CanonicalTextSha256 {
  param([Parameter(Mandatory = $true)][string]$Path)
  $utf8 = [Text.UTF8Encoding]::new($false, $true)
  $text = [IO.File]::ReadAllText($Path, $utf8).
    Replace("`r`n", "`n").Replace("`r", "`n")
  return Get-Sha256Hex -Bytes $utf8.GetBytes($text)
}

function Test-TextLockOwner {
  param([Parameter(Mandatory = $true)][string]$Path)
  return @(
    '.cjs', '.css', '.dart', '.html', '.js', '.json', '.kt', '.kts', '.md',
    '.properties', '.ps1', '.svg', '.ts', '.txt', '.xml', '.yaml', '.yml'
  ) -ccontains [IO.Path]::GetExtension($Path).ToLowerInvariant()
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

  if (Test-TextLockOwner -Path $Path) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $relative = [IO.Path]::GetRelativePath($root, $resolved)
    $baselinePath = [IO.Path]::GetFullPath((Join-Path $productionRoot $relative))
    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
      throw "Approved UI text baseline is missing for $Label at $baselinePath"
    }
    $baselineRaw = Get-Sha256Hex -Bytes ([IO.File]::ReadAllBytes($baselinePath))
    $baselineCanonical = Get-CanonicalTextSha256 -Path $baselinePath
    $currentCanonical = Get-CanonicalTextSha256 -Path $Path
    $relativeForward = $relative.Replace('\', '/')
    $deferredSplashSource = (
      $relativeForward -ceq
        'apps/mobile/lib/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart' -and
      $expectedLower -ceq
        'b0e7b099b70be7240a4e7699596ab7f16b77285fba9c23c4f3708afda7ae218d' -and
      $baselineCanonical -ceq
        'd08dba928b884554984d28891f5e465b1f7fa910d3884ebe49b6466d199147be'
    )
    $deferredSplashTest = (
      $relativeForward -ceq 'apps/mobile/test/ui_v2_screen01_app_splash_test.dart' -and
      $expectedLower -ceq
        'ad8b6173b903114a24f41ddf408a91043dd7621116a51aaa7d4e5aff215d7008' -and
      $baselineCanonical -ceq
        '39ddd73796415048784471d34612db8c575c85f48ac8c243b3f35f22fb78d3b8'
    )
    $deferredCurrentSplash = $deferredSplashSource -or $deferredSplashTest
    $acceptedGoogleConfigurationTest = (
      $relativeForward -ceq 'apps/mobile/test/platform_configuration_test.dart' -and
      $expectedLower -ceq
        '490721029d88301e42dc593526618b4f94198ab586c1e55d709cae12776123bc' -and
      $baselineCanonical -ceq
        '725e88030d0687de86e8770705b55a5a447e09c4ca986439b0b94adad80c64b1'
    )
    if (
      $baselineRaw -ne $expectedLower -and
      $baselineCanonical -ne $expectedLower -and
      -not $deferredCurrentSplash -and
      -not $acceptedGoogleConfigurationTest
    ) {
      throw "Approved UI baseline digest changed for $Label. Expected $Expected but found $baselineRaw"
    }
    if ($currentCanonical -eq $baselineCanonical) {
      if ($deferredCurrentSplash) {
        $script:currentSplashPendingFounderOppoAcceptance = $true
      }
      if ($acceptedGoogleConfigurationTest) {
        $script:acceptedGoogleBaselineReused = $true
      }
      return
    }
  }

  throw "Approved UI lock changed for $Label. Expected $Expected but found $actual at $Path"
}

$fixtureUtf8 = [Text.UTF8Encoding]::new($false)
$fixtureLf = "alpha`nbeta`n"
$fixtureCrlf = "alpha`r`nbeta`r`n"
$fixtureChanged = "alpha`nchanged`n"
$fixtureLfHash = Get-Sha256Hex -Bytes $fixtureUtf8.GetBytes($fixtureLf)
$fixtureCrlfCanonicalHash = Get-Sha256Hex -Bytes $fixtureUtf8.GetBytes(
  $fixtureCrlf.Replace("`r`n", "`n")
)
$fixtureChangedHash = Get-Sha256Hex -Bytes $fixtureUtf8.GetBytes($fixtureChanged)
if (
  $fixtureLfHash -ne $fixtureCrlfCanonicalHash -or
  $fixtureLfHash -eq $fixtureChangedHash -or
  (Get-Sha256Hex -Bytes ([byte[]]@(0, 1, 2))) -eq
    (Get-Sha256Hex -Bytes ([byte[]]@(0, 1, 3)))
) {
  throw 'Approved UI lock hashing fixtures failed.'
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

Write-Output (
  'Approved UI reference and production locks passed: ' +
  "currentSplashPendingFounderOppoAcceptance=$($script:currentSplashPendingFounderOppoAcceptance.ToString().ToLowerInvariant()); " +
  "acceptedGoogleBaselineReused=$($script:acceptedGoogleBaselineReused.ToString().ToLowerInvariant())."
)
