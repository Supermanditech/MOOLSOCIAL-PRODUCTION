[CmdletBinding()]
param(
  [switch]$RunGradleLink,

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-ResourceIntegrity([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Android release resource-integrity gate rejected: $Message"
  }
}

function Resolve-RepositoryFile([string]$RelativePath) {
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-ResourceIntegrity (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "resource owner escaped repository: $RelativePath"
  Assert-ResourceIntegrity (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) "required resource owner is missing: $RelativePath"
  return $resolved
}

$resourceRootRelative = 'apps/mobile/android/app/src/main/res'
$resourceRoot = [IO.Path]::GetFullPath(
  (Join-Path $root $resourceRootRelative)
)
Assert-ResourceIntegrity (
  Test-Path -LiteralPath $resourceRoot -PathType Container
) 'main Android resource root is missing.'

$criticalRelativePaths = @(
  'apps/mobile/android/app/src/main/res/drawable/launch_background.xml',
  'apps/mobile/android/app/src/main/res/drawable/launch_transparent.xml',
  'apps/mobile/android/app/src/main/res/values/colors.xml',
  'apps/mobile/android/app/src/main/res/values/styles.xml',
  'apps/mobile/android/app/src/main/res/values-night/styles.xml',
  'apps/mobile/android/app/src/main/res/values-v31/styles.xml',
  'apps/mobile/android/app/src/main/res/values-night-v31/styles.xml'
)
$criticalPaths = @($criticalRelativePaths | ForEach-Object {
  Resolve-RepositoryFile $_
})

$xmlFiles = @(Get-ChildItem -LiteralPath $resourceRoot -Recurse -File -Filter '*.xml')
Assert-ResourceIntegrity ($xmlFiles.Count -gt 0) 'no Android XML resources found.'
foreach ($xmlFile in $xmlFiles) {
  try {
    $null = [xml](Get-Content -Raw -LiteralPath $xmlFile.FullName)
  } catch {
    $relative = $xmlFile.FullName.Substring($rootPrefix.Length).Replace('\', '/')
    throw "Android release resource-integrity gate rejected: malformed XML: $relative"
  }
}

$baseLaunch = $criticalPaths[0]
$baseLaunchXml = [xml](Get-Content -Raw -LiteralPath $baseLaunch)
$baseLaunchNormalized = [regex]::Replace($baseLaunchXml.OuterXml, '\s+', '')

$dayStyles = Get-Content -Raw -LiteralPath $criticalPaths[3]
$nightStyles = Get-Content -Raw -LiteralPath $criticalPaths[4]
Assert-ResourceIntegrity (
  $dayStyles.Contains('@drawable/launch_background') -and
  $nightStyles.Contains('@drawable/launch_background')
) 'day/night launch themes do not reference the qualified launch background.'

$dayV31 = Get-Content -Raw -LiteralPath $criticalPaths[5]
$nightV31 = Get-Content -Raw -LiteralPath $criticalPaths[6]
Assert-ResourceIntegrity (
  $dayV31.Contains('@drawable/launch_transparent') -and
  $nightV31.Contains('@drawable/launch_transparent')
) 'Android 12 day/night launch themes lack the transparent animated-icon owner.'

$colors = [xml](Get-Content -Raw -LiteralPath $criticalPaths[2])
$moolNavy = @($colors.resources.color | Where-Object {
  [string]$_.name -ceq 'mool_navy'
})
Assert-ResourceIntegrity (
  $moolNavy.Count -eq 1 -and
  -not [string]::IsNullOrWhiteSpace([string]$moolNavy[0].InnerText)
) 'mool_navy launch color owner is missing or duplicated.'

$statusRows = @(
  git -C $root status --porcelain=v1 --untracked-files=all -- $resourceRootRelative
)
Assert-ResourceIntegrity ($LASTEXITCODE -eq 0) 'resource dirty-state read failed.'
$deletedRows = @($statusRows | Where-Object {
  $_.Length -ge 2 -and $_.Substring(0, 2).Contains('D')
})
$allowedObsoleteDeletion = (
  'apps/mobile/android/app/src/main/res/' +
  'drawable-v21/launch_background.xml'
)
$unexpectedDeletedRows = @($deletedRows | Where-Object {
  $_.Substring(3).Replace('\', '/') -cne $allowedObsoleteDeletion
})
Assert-ResourceIntegrity (
  $unexpectedDeletedRows.Count -eq 0
) 'one or more unapproved tracked Android resource owners are deleted.'

$gradleLinkState = 'not_requested'
if ($RunGradleLink) {
  $androidRoot = Join-Path $root 'apps/mobile/android'
  $gradlew = Resolve-RepositoryFile 'apps/mobile/android/gradlew.bat'
  Push-Location $androidRoot
  try {
    $gradleOutput = @(& $gradlew `
      ':app:processReleaseResources' `
      '--rerun-tasks' `
      '--no-daemon' `
      '--warning-mode=summary' `
      '--console=plain' 2>&1)
    $gradleExit = $LASTEXITCODE
  } finally {
    Pop-Location
  }
  if ($gradleExit -ne 0) {
    $gradleOutput | Select-Object -Last 80 | Write-Output
  }
  Assert-ResourceIntegrity (
    $gradleExit -eq 0
  ) 'forced :app:processReleaseResources task failed.'

  $mergedRoot = Join-Path $root (
    'apps/mobile/build/app/intermediates/merged_res/release/' +
    'mergeReleaseResources'
  )
  Assert-ResourceIntegrity (
    Test-Path -LiteralPath $mergedRoot -PathType Container
  ) 'release merged-resource output is missing.'
  $mergedLaunch = @(Get-ChildItem -LiteralPath $mergedRoot -File |
    Where-Object { $_.Name -cmatch '^drawable.*launch_background.*[.]flat$' })
  Assert-ResourceIntegrity (
    $mergedLaunch.Count -ge 1
  ) 'release merge output lacks the launch-background compiled resource.'

  $packagedRoot = Join-Path $root (
    'apps/mobile/build/app/intermediates/packaged_res/release/' +
    'packageReleaseResources'
  )
  Assert-ResourceIntegrity (
    Test-Path -LiteralPath $packagedRoot -PathType Container
  ) 'release packaged-resource output is missing.'
  $packagedLaunch = @(
    Get-ChildItem -LiteralPath $packagedRoot -Recurse -File `
      -Filter 'launch_background.xml'
  )
  Assert-ResourceIntegrity (
    $packagedLaunch.Count -ge 1
  ) 'release packaged resources lack the launch-background owner.'
  foreach ($packagedOwner in $packagedLaunch) {
    $packagedXml = [xml](Get-Content -Raw -LiteralPath $packagedOwner.FullName)
    $packagedNormalized = [regex]::Replace($packagedXml.OuterXml, '\s+', '')
    Assert-ResourceIntegrity (
      $packagedNormalized -ceq $baseLaunchNormalized
    ) 'packaged launch background differs from checked-in owner semantics.'
  }
  $gradleLinkState = 'passed_forced_processReleaseResources'
}

Write-Output (
  'Android release resource integrity passed: ' +
  "xml=$($xmlFiles.Count); unexpectedDeleted=0; launchOwners=1; " +
  "gradleLink=$gradleLinkState."
)
