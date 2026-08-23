[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$BaselineManifest = (
    'artifacts/quality/' +
    'uaw-c34p-fix11-google-sign-in-oppo-successor-r60-85-20260823-03/' +
    'source-aggregate-manifest.txt'
  ),
  [string]$OutputManifest = (
    'artifacts/quality/' +
    'uaw-c34p-fix11-google-sign-in-diagnostic-r60-86-20260823-01/' +
    'source-aggregate-manifest.txt'
  )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
)
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$baselinePath = [IO.Path]::GetFullPath((Join-Path $root $BaselineManifest))
$outputPath = [IO.Path]::GetFullPath((Join-Path $root $OutputManifest))
if (-not $baselinePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
    -not $outputPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'FIX11 diagnostic source manifest path escaped the repository.'
}
if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
  throw 'FIX11 diagnostic baseline source manifest is missing.'
}
if (Test-Path -LiteralPath $outputPath) {
  throw 'FIX11 diagnostic source manifest already exists; overwrite is forbidden.'
}

$owners = [Collections.Generic.List[string]]::new()
foreach ($line in Get-Content -LiteralPath $baselinePath) {
  if ($line -cnotmatch '^[0-9A-F]{64}  (.+)$') {
    throw 'FIX11 diagnostic baseline source manifest contains an invalid row.'
  }
  $relative = [string]$Matches[1]
  if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains('..')) {
    throw 'FIX11 diagnostic source owner is not repository-relative.'
  }
  $owners.Add($relative)
}
if ($owners.Count -ne 650 -or
    @($owners | Select-Object -Unique).Count -ne $owners.Count) {
  throw 'FIX11 diagnostic source owner inventory changed or is duplicated.'
}

function Get-DiagnosticManifestLines {
  $result = [Collections.Generic.List[string]]::new()
  foreach ($relative in $owners) {
    $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "FIX11 diagnostic source owner is missing: $relative"
    }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $result.Add("$hash  $relative")
  }
  return $result.ToArray()
}

$first = @(Get-DiagnosticManifestLines)
$second = @(Get-DiagnosticManifestLines)
if (($first -join "`n") -cne ($second -join "`n")) {
  throw 'FIX11 diagnostic source inventory changed during independent replay.'
}
$outputDirectory = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $outputDirectory)
}
[IO.File]::WriteAllLines($outputPath, $first, [Text.UTF8Encoding]::new($false))
[pscustomobject]@{
  fileCount = $first.Count
  sha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
  independentReplayPassed = $true
} | ConvertTo-Json
