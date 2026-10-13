[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$AabPath,
  [Parameter(Mandatory)]
  [string]$CandidateId,
  [Parameter(Mandatory)]
  [string]$ProguardFolderPath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$pathGuard = Join-Path $PSScriptRoot 'release-artifact-path-guard.ps1'
. $pathGuard

function Assert-AabPluginIntegrity([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "AAB integrity gate rejected: $Message"
  }
}

$aab = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $AabPath `
  -Label 'AAB integrity artifact'
$proguardFolder = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $ProguardFolderPath `
  -Label 'AAB integrity Proguard folder'
Assert-AabPluginIntegrity `
  (Test-Path -LiteralPath $aab -PathType Leaf) `
  'AAB is missing.'
Assert-AabPluginIntegrity `
  (Test-Path -LiteralPath $proguardFolder -PathType Container) `
  'Proguard folder is missing.'
Assert-AabPluginIntegrity `
  (-not [string]::IsNullOrWhiteSpace($CandidateId)) `
  'candidate identity is blank.'

$mappingPath = Join-Path $proguardFolder 'mapping.txt'
$seedsPath = Join-Path $proguardFolder 'seeds.txt'
$usagesPath = Join-Path $proguardFolder 'usage.txt'
foreach ($requiredMappingOwner in @($mappingPath, $seedsPath, $usagesPath)) {
  Assert-AabPluginIntegrity `
    (Test-Path -LiteralPath $requiredMappingOwner -PathType Leaf) `
    'required Proguard owner is missing.'
}
$aabTime = (Get-Item -LiteralPath $aab).LastWriteTimeUtc
$oldestMappingTime = @($mappingPath, $seedsPath, $usagesPath) |
  ForEach-Object { (Get-Item -LiteralPath $_).LastWriteTimeUtc } |
  Sort-Object | Select-Object -First 1
Assert-AabPluginIntegrity (
  ($aabTime - $oldestMappingTime).TotalMinutes -le 10 -and
  $oldestMappingTime -le $aabTime.AddMinutes(1)
) 'Proguard owners are stale for this AAB.'

function Get-MappedClassName([string]$OriginalClass) {
  $pattern = '^' + [regex]::Escape($OriginalClass) + ' -> ([^:]+):$'
  $matches = @(Select-String -LiteralPath $mappingPath -Pattern $pattern)
  Assert-AabPluginIntegrity `
    ($matches.Count -eq 1) `
    "required class mapping is missing or duplicated: $OriginalClass"
  return $matches[0].Matches[0].Groups[1].Value
}

$requiredClasses = @(
  'io.flutter.plugins.GeneratedPluginRegistrant',
  'io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin',
  'dev.fluttercommunity.plus.share.SharePlusPlugin',
  'com.moolsocial.app.MainActivity'
)
$requiredDescriptors = @($requiredClasses | ForEach-Object {
  'L' + (Get-MappedClassName $_).Replace('.', '/') + ';'
})

$forbiddenDescriptors = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal
)
[void]$forbiddenDescriptors.Add(
  'Ldev/flutter/plugins/integration_test/IntegrationTestPlugin;'
)
$forbiddenMappings = @(Select-String -LiteralPath $mappingPath -Pattern (
  '^dev\.flutter\.plugins\.integration_test\.[^ ]+ -> ([^:]+):$'
))
foreach ($forbiddenMapping in $forbiddenMappings) {
  [void]$forbiddenDescriptors.Add(
    'L' + $forbiddenMapping.Matches[0].Groups[1].Value.Replace('.', '/') + ';'
  )
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($aab)
try {
  $dexEntries = @($archive.Entries | Where-Object {
    $_.FullName -cmatch '^base/dex/classes(?:\d+)?\.dex$'
  })
  Assert-AabPluginIntegrity ($dexEntries.Count -ge 1) 'base DEX payload is missing.'
  $foundRequired = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
  )
  $foundForbidden = $false
  foreach ($entry in $dexEntries) {
    $stream = $entry.Open()
    try {
      $memory = [IO.MemoryStream]::new()
      try {
        $stream.CopyTo($memory)
        $dexText = [Text.Encoding]::ASCII.GetString($memory.ToArray())
      } finally {
        $memory.Dispose()
      }
    } finally {
      $stream.Dispose()
    }
    foreach ($descriptor in $requiredDescriptors) {
      if ($dexText.Contains($descriptor, [StringComparison]::Ordinal)) {
        [void]$foundRequired.Add($descriptor)
      }
    }
    foreach ($descriptor in $forbiddenDescriptors) {
      if ($dexText.Contains($descriptor, [StringComparison]::Ordinal)) {
        $foundForbidden = $true
      }
    }
  }
  Assert-AabPluginIntegrity `
    ($foundRequired.Count -eq $requiredDescriptors.Count) `
    'one or more mapped required production plugin classes are missing.'
  Assert-AabPluginIntegrity `
    (-not $foundForbidden) `
    'test-only integration_test class is present.'
} finally {
  $archive.Dispose()
}

Write-Output (
  'AAB production plugin integrity passed: ' +
  "candidate=$CandidateId; mappingAware=true; dexFiles=$($dexEntries.Count); " +
  'registrant=true; firebaseCore=true; sharePlus=true; integrationTest=false.'
)
