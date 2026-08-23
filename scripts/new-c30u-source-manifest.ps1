[CmdletBinding()]
param(
  [string]$OutputPath,
  [string]$ComparePath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if ([string]::IsNullOrWhiteSpace($OutputPath) -eq [string]::IsNullOrWhiteSpace($ComparePath)) {
  throw 'C30U source manifest requires exactly one of -OutputPath or -ComparePath.'
}

function Get-C30URelativeFiles {
  param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][string[]]$Extensions)
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
  @(
    Get-ChildItem -LiteralPath $Directory -Recurse -File | Where-Object {
      $name = $_.Name
      $_.FullName -notmatch '[\\/](build|\.gradle|\.dart_tool|node_modules|\.idea)[\\/]' -and
      @($Extensions | Where-Object { $name.EndsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    } | ForEach-Object {
      $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    }
  )
}

function Resolve-C30UOutput {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'C30U source manifest path escaped the repository.'
  }
  return $resolved
}

function Get-C30UProtectedRelativeFiles {
  $files = @()
  foreach ($relativeRoot in @(
    'apps/mobile/lib/ui_v2/social',
    'apps/mobile/lib/core/youtube',
    'apps/mobile/packages/youtube_embedded_player_private_dev',
    'backend/functions/src'
  )) {
    $absoluteRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
      throw "C30U protected source root is missing: $relativeRoot"
    }
    $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | Where-Object {
      $_.FullName -notmatch '[\\/]\.dart_tool[\\/]' -and
      $_.FullName -notmatch '[\\/]build[\\/]' -and
      $_.Name -notmatch '\.test\.(ts|js)$'
    }
  }

  foreach ($relative in @(
    'apps/mobile/lib/core/navigation/youtube_connect_return_route.dart',
    'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/YouTubeConnectReturnActivity.kt',
    'apps/mobile/assets/prototype/social-market-grocery.png',
    'backend/functions/package.json',
    'backend/functions/package-lock.json',
    'backend/functions/tsconfig.json'
  )) {
    $absolute = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
      throw "C30U protected source owner is missing: $relative"
    }
    $files += Get-Item -LiteralPath $absolute
  }

  foreach ($relativeRoot in @(
    'apps/mobile/test',
    'apps/mobile/integration_test',
    'apps/mobile/test_driver'
  )) {
    $absoluteRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
      throw "C30U protected test root is missing: $relativeRoot"
    }
    $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | Where-Object {
      $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
      $relative -match '(?i)(social|youtube|screen04)' -and
      $_.FullName -notmatch '[\\/]candidate_captures[\\/]' -and
      $_.FullName -notmatch '[\\/]failures[\\/]'
    }
  }

  return @(
    $files |
      ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
      Sort-Object -Unique
  )
}

$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
if (
  $branch -cne 'remediation/prototype-conformance-2026-07-20' -or
  $head -cne 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) { throw 'C30U source manifest branch or HEAD changed.' }

$paths = @()
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/lib') -Extensions @('.dart')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/test') -Extensions @('.dart')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/test/goldens') -Extensions @('.png')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/integration_test') -Extensions @('.dart')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/android') -Extensions @('.kt', '.kts', '.java', '.xml', '.properties', '.gradle')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/mobile/packages/youtube_embedded_player_private_dev') -Extensions @('.dart', '.kt', '.kts', '.java', '.xml', '.yaml')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'backend/functions/src') -Extensions @('.ts')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'apps/web/public') -Extensions @('.html', '.css', '.js', '.json', '.xml', '.txt', '.png', '.svg', '.ico')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'scripts') -Extensions @('.ps1', '.mjs', '.js', '.ts')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'deployment/youtube-private-dev') -Extensions @('.json', '.md', '.ps1', '.mjs')
$paths += Get-C30URelativeFiles -Directory (Join-Path $root 'deployment/youtube-official-api-capability-registry') -Extensions @('.json', '.md', '.mjs')

$paths += @(
  'apps/mobile/pubspec.yaml',
  'apps/mobile/pubspec.lock',
  'backend/functions/package.json',
  'backend/functions/package-lock.json',
  'backend/functions/tsconfig.json',
  'backend/functions/env/moolsocial-dev-503018.env',
  'apps/web/tests/firebase-public-site.test.mjs',
  'firebase.json',
  'approved-references/manifest.json',
  'config/codex-development-regression-registry.json',
  'config/mvp-scope-policy.json',
  'config/mvp-scope-gate-state.json',
  'config/mvp-robust-60-75-day-delivery-lock.json',
  'config/mvp-exact-user-type-scope-matrix.json',
  'config/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-ticket.json',
  'config/uaw-c30t-r60-45-mobile-otp-gate-nonfunctional-ticket.json',
  'config/uaw-c30t-r60-45-email-otp-gate-nonfunctional-ticket.json',
  'config/play-internal-aab-regression-gate-state-c30t.json',
  'config/play-internal-live-read-recovery-gate-state-c30t.json',
  'docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md',
  'docs/quality/RELEASE-GATES.md',
  'docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md',
  'docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md',
  'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1',
  'tmp/run-c30u-single-aab-founder.ps1',
  'tmp/bundletool-all-1.18.3.jar'
)
$paths += @(
  Get-ChildItem -LiteralPath (Join-Path $root 'config') -File -Filter 'uaw-c30t-*-ticket.json' |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }
)
$paths += @(
  Get-ChildItem -LiteralPath (Join-Path $root 'docs/quality') -File -Filter 'UAW-C30U-*.md' |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }
)

$protectedBaselinePath = Join-Path $root 'artifacts/quality/social-protected-candidate-c30u-post-r60-45-social-repairs-20260814-01/BASELINE.json'
if (-not (Test-Path -LiteralPath $protectedBaselinePath -PathType Leaf)) {
  throw 'C30U protected Social successor baseline is missing.'
}
$protectedBaseline = Get-Content -Raw -LiteralPath $protectedBaselinePath | ConvertFrom-Json
$protectedRelativePaths = @(Get-C30UProtectedRelativeFiles)
$expectedProtectedCount = [int]$protectedBaseline.protectedRuntime.fileCount
if ($expectedProtectedCount -ne 206 -or $protectedRelativePaths.Count -ne $expectedProtectedCount) {
  throw "C30U protected source owner inventory is not exact: expected=$expectedProtectedCount actual=$($protectedRelativePaths.Count)"
}
$paths += $protectedRelativePaths

$relativePaths = @($paths | Sort-Object -Unique)
$missingProtectedPaths = @($protectedRelativePaths | Where-Object { $_ -cnotin $relativePaths })
if ($missingProtectedPaths.Count -ne 0) {
  throw "C30U source manifest omitted $($missingProtectedPaths.Count) protected source owner(s)."
}
foreach ($relativePath in $relativePaths) {
  $absolute = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    throw "C30U source manifest owner missing: $relativePath"
  }
}
$rows = @($relativePaths | ForEach-Object {
  '{0}  {1}' -f (Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash, $_
})
$text = ($rows -join [Environment]::NewLine) + [Environment]::NewLine
$bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
$hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
  $path = Resolve-C30UOutput -Path $OutputPath
  if (Test-Path -LiteralPath $path) { throw "C30U source manifest is immutable and already exists: $path" }
  $directory = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $directory)
  }
  [IO.File]::WriteAllBytes($path, $bytes)
  Write-Output "C30U source manifest sealed: $OutputPath"
} else {
  $path = Resolve-C30UOutput -Path $ComparePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'C30U comparison source manifest is missing.' }
  $existing = [IO.File]::ReadAllBytes($path)
  $existingHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($existing))
  if ($existing.Length -ne $bytes.Length -or $existingHash -cne $hash) {
    throw 'C30U source changed between qualification cycles.'
  }
  Write-Output "C30U source manifest unchanged: $ComparePath"
}

Write-Output "sourceFiles=$($relativePaths.Count); sourceFingerprintSha256=$hash; protectedSourceOwners=$($protectedRelativePaths.Count); missingProtectedSourceOwners=$($missingProtectedPaths.Count)"
