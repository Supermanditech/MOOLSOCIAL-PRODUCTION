[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
Push-Location $repo
try {
  $expectedCandidate = 'BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7'
  $expectedVersionName = '1.0.0-r58.23'
  $expectedVersionCode = '2026080419'
  $expectedManifestSha =
    'A05B47F0893778064E255574DF3678BF198DAE72A18DA7C81710693557AE1BEE'
  $expectedApkSha =
    'F0C1061D1D7897130528533F254B41BDC48FE7958E7DD9B50624FEF6EE3B5DC9'
  $evidence = Join-Path $repo (
    'artifacts/quality/' +
    'buy-category-sheet-ime-result-visibility-r58-8-8-fix7-20260805-175'
  )
  $manifest = Join-Path $evidence '140-source-manifest-post-device.txt'
  $apk = Join-Path $evidence (
    'buy-r58-category-sheet-ime-result-visibility-fix7-' +
    'device-review-profile.apk'
  )

  $branch = (& git branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0 -or $branch -notin @(
      'remediation/prototype-conformance-2026-07-20',
      'checkpoint/moolsocial-20260805-0055-ist-sealed'
    )) {
    throw "Unexpected recovery branch: $branch"
  }

  & git lfs fsck
  if ($LASTEXITCODE -ne 0) {
    throw 'Git LFS integrity check failed. Run git lfs pull and retry.'
  }

  $state = Get-Content -Raw -LiteralPath (
    Join-Path $repo 'config/apk-regression-gate-state.json'
  ) | ConvertFrom-Json
  if ($state.machineState -cne 'founder_approved_protected' -or
      $state.buildAuthorization -cne 'consumed' -or
      $state.candidate.id -cne $expectedCandidate -or
      $state.candidate.versionName -cne $expectedVersionName -or
      [string]$state.candidate.versionCode -cne $expectedVersionCode -or
      $state.source.manifestSha256 -cne $expectedManifestSha -or
      $state.buildResult.apkSha256 -cne $expectedApkSha -or
      $state.installResult.installedSha256 -cne $expectedApkSha) {
    throw 'Checkpoint machine-state identity mismatch.'
  }

  if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw "Source manifest is missing: $manifest"
  }
  if ((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -cne
      $expectedManifestSha) {
    throw 'Source-manifest checksum mismatch.'
  }

  $entries = Get-Content -LiteralPath $manifest
  foreach ($entry in $entries) {
    if ($entry -notmatch '^([A-F0-9]{64})  (.+)$') {
      throw "Malformed source-manifest entry: $entry"
    }
    $expected = $Matches[1]
    $path = Join-Path $repo $Matches[2]
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "Checkpoint source file is missing: $path"
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actual -cne $expected) {
      throw "Checkpoint source drift: $path"
    }
  }

  if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) {
    throw 'Approved APK is missing. Run git lfs pull and retry.'
  }
  if ((Get-Item -LiteralPath $apk).Length -ne 134214109 -or
      (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash -cne
      $expectedApkSha) {
    throw 'Approved APK bytes/checksum mismatch. Run git lfs pull and retry.'
  }

  Write-Output (
    "MoolSocial resume checkpoint passed: branch=$branch; " +
    "candidate=$expectedCandidate; source=$expectedManifestSha; " +
    "apk=$expectedApkSha; files=$($entries.Count)."
  )
} finally {
  Pop-Location
}
