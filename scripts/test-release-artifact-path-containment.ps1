[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
)
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$guardPath = Join-Path $PSScriptRoot 'release-artifact-path-guard.ps1'
. $guardPath

function Assert-ArtifactPathGate {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) {
    throw "Release artifact path-containment gate rejected: $Message"
  }
}

$originalCurrentDirectory = [Environment]::CurrentDirectory
try {
  [Environment]::CurrentDirectory = Split-Path -Parent $root
  $futureRelative = Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $root `
    -Path 'artifacts/quality/future-release-artifact-not-yet-created' `
    -Label 'future relative artifact directory'
} finally {
  [Environment]::CurrentDirectory = $originalCurrentDirectory
}
Assert-ArtifactPathGate `
  ($futureRelative.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
  'repository-relative resolution depends on the process working directory.'

$existingAbsoluteInput = Join-Path $root 'artifacts/quality'
$existingAbsolute = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $existingAbsoluteInput `
  -Label 'existing absolute artifact directory'
Assert-ArtifactPathGate `
  ($existingAbsolute -ceq [IO.Path]::GetFullPath($existingAbsoluteInput)) `
  'an absolute repository descendant was not preserved.'

$normalizedRelative = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path 'artifacts/quality/../quality/future-normalized-artifact' `
  -Label 'normalized relative artifact directory'
Assert-ArtifactPathGate `
  ($normalizedRelative.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
  'a normalized repository descendant was rejected.'

$negativePaths = @(
  $root,
  (Split-Path -Parent $root),
  ($root + '-prefix-collision'),
  '../outside-repository-artifact',
  (Join-Path ([IO.Path]::GetTempPath()) 'outside-repository-artifact')
)
$rejections = 0
foreach ($negativePath in $negativePaths) {
  try {
    $null = Resolve-ReleaseArtifactRepositoryDescendant `
      -RepositoryRoot $root `
      -Path $negativePath `
      -Label 'negative fixture'
  } catch {
    $rejections++
  }
}
Assert-ArtifactPathGate `
  ($rejections -eq $negativePaths.Count) `
  'one or more traversal, root, outside, or prefix-collision fixtures passed.'

$apkWrapper = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/build-buy-device-review.ps1'
)
$aabWrapper = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/invoke-play-internal-aab-build-c30t.ps1'
)
foreach ($wrapper in @($apkWrapper, $aabWrapper)) {
  Assert-ArtifactPathGate (
    $wrapper.Contains('release-artifact-path-guard.ps1') -and
    $wrapper.Contains('Resolve-ReleaseArtifactRepositoryDescendant') -and
    $wrapper.Contains('test-release-artifact-path-containment.ps1')
  ) 'an APK or current AAB wrapper does not enforce the shared path guard.'
}
Assert-ArtifactPathGate (
  $apkWrapper.Contains('$machineStateFile = Resolve-ReleaseArtifactRepositoryDescendant') -and
  $apkWrapper.Contains('-StatePath $machineStateFile') -and
  $apkWrapper.Contains('"MachineState=$machineStateFile"')
) 'the APK wrapper does not canonicalize its machine-state path through the shared guard.'

Write-Output (
  'Release artifact path-containment gate passed: ' +
  'relativeFuture=true; absoluteDescendant=true; processCwdIndependent=true; ' +
  "negativeRejections=$rejections; apk=true; aab=true."
)
