[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$fixtureParent = Join-Path $root 'artifacts/quality'
$fixtureRoot = Join-Path $fixtureParent (
  '.tmp-release-plugin-integrity-' + [guid]::NewGuid().ToString('N')
)
$fixturePrefix = [IO.Path]::GetFullPath($fixtureParent).TrimEnd('\', '/') +
  [IO.Path]::DirectorySeparatorChar

function Assert-PluginFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Release plugin-integrity fixture rejected: $Message"
  }
}

function New-AabFixture(
  [string]$Path,
  [string[]]$Descriptors
) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::Open(
    $Path,
    [IO.Compression.ZipArchiveMode]::Create
  )
  try {
    $entry = $archive.CreateEntry('base/dex/classes.dex')
    $stream = $entry.Open()
    try {
      $bytes = [Text.Encoding]::ASCII.GetBytes(($Descriptors -join "`n"))
      $stream.Write($bytes, 0, $bytes.Length)
    } finally {
      $stream.Dispose()
    }
  } finally {
    $archive.Dispose()
  }
}

$positiveApkPass = $false
$missingApkRejected = $false
$forbiddenApkRejected = $false
$missingMappingRejected = $false
$positiveAabPass = $false
$missingAabRejected = $false
$forbiddenAabRejected = $false
try {
  [void](New-Item -ItemType Directory -Path $fixtureRoot)
  $mappingFolder = Join-Path $fixtureRoot 'mapping'
  $emptyMappingFolder = Join-Path $fixtureRoot 'empty-mapping'
  [void](New-Item -ItemType Directory -Path $mappingFolder)
  [void](New-Item -ItemType Directory -Path $emptyMappingFolder)
  $mappingText = @'
io.flutter.plugins.GeneratedPluginRegistrant -> a.b:
io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin -> je.d:
com.moolsocial.app.MainActivity -> c.d:
dev.flutter.plugins.integration_test.IntegrationTestPlugin -> x.y:
'@
  [IO.File]::WriteAllText(
    (Join-Path $mappingFolder 'mapping.txt'),
    $mappingText,
    [Text.UTF8Encoding]::new($false)
  )
  foreach ($leaf in @('seeds.txt', 'usage.txt')) {
    [IO.File]::WriteAllText(
      (Join-Path $mappingFolder $leaf),
      "fixture`n",
      [Text.UTF8Encoding]::new($false)
    )
  }

  $analyzer = Join-Path $fixtureRoot 'fake-apkanalyzer.ps1'
  $analyzerSource = @'
$leaf = Split-Path -Leaf $args[-1]
if ($args[0] -ceq 'dex' -and $args[1] -ceq 'packages') {
  'C d io.flutter.plugins.GeneratedPluginRegistrant'
  'C d com.moolsocial.app.MainActivity'
  if ($args -contains '--proguard-mappings' -and $leaf -notlike '*missing*') {
    'C d io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin'
  } else {
    'C d je.d'
  }
  if ($leaf -like '*forbidden*') {
    'C d dev.flutter.plugins.integration_test.IntegrationTestPlugin'
  }
  exit 0
}
if ($args[0] -ceq 'manifest' -and $args[1] -ceq 'application-id') {
  'com.moolsocial.app'
  exit 0
}
exit 9
'@
  [IO.File]::WriteAllText(
    $analyzer,
    $analyzerSource,
    [Text.UTF8Encoding]::new($false)
  )
  $positiveApk = Join-Path $fixtureRoot 'positive.apk'
  $missingApk = Join-Path $fixtureRoot 'missing.apk'
  $forbiddenApk = Join-Path $fixtureRoot 'forbidden.apk'
  foreach ($path in @($positiveApk, $missingApk, $forbiddenApk)) {
    [IO.File]::WriteAllText($path, 'fixture', [Text.UTF8Encoding]::new($false))
  }
  $apkGate = Join-Path $root 'scripts/check-apk-production-plugin-integrity.ps1'
  & $apkGate -ApkPath $positiveApk -CandidateId 'FIXTURE-POSITIVE' `
    -RepositoryRoot $root -ApkAnalyzerPath $analyzer `
    -ProguardFolderPath $mappingFolder -RequireMappingAware | Out-Null
  $positiveApkPass = $true
  try {
    & $apkGate -ApkPath $missingApk -CandidateId 'FIXTURE-MISSING' `
      -RepositoryRoot $root -ApkAnalyzerPath $analyzer `
      -ProguardFolderPath $mappingFolder -RequireMappingAware | Out-Null
  } catch { $missingApkRejected = $true }
  try {
    & $apkGate -ApkPath $forbiddenApk -CandidateId 'FIXTURE-FORBIDDEN' `
      -RepositoryRoot $root -ApkAnalyzerPath $analyzer `
      -ProguardFolderPath $mappingFolder -RequireMappingAware | Out-Null
  } catch { $forbiddenApkRejected = $true }
  try {
    & $apkGate -ApkPath $positiveApk -CandidateId 'FIXTURE-NO-MAPPING' `
      -RepositoryRoot $root -ApkAnalyzerPath $analyzer `
      -ProguardFolderPath $emptyMappingFolder -RequireMappingAware | Out-Null
  } catch { $missingMappingRejected = $true }

  $positiveAab = Join-Path $fixtureRoot 'positive.aab'
  $missingAab = Join-Path $fixtureRoot 'missing.aab'
  $forbiddenAab = Join-Path $fixtureRoot 'forbidden.aab'
  New-AabFixture $positiveAab @('La/b;', 'Lje/d;', 'Lc/d;')
  New-AabFixture $missingAab @('La/b;', 'Lc/d;')
  New-AabFixture $forbiddenAab @('La/b;', 'Lje/d;', 'Lc/d;', 'Lx/y;')
  $aabGate = Join-Path $root 'scripts/check-aab-production-plugin-integrity.ps1'
  & $aabGate -AabPath $positiveAab -CandidateId 'FIXTURE-POSITIVE' `
    -RepositoryRoot $root -ProguardFolderPath $mappingFolder | Out-Null
  $positiveAabPass = $true
  try {
    & $aabGate -AabPath $missingAab -CandidateId 'FIXTURE-MISSING' `
      -RepositoryRoot $root -ProguardFolderPath $mappingFolder | Out-Null
  } catch { $missingAabRejected = $true }
  try {
    & $aabGate -AabPath $forbiddenAab -CandidateId 'FIXTURE-FORBIDDEN' `
      -RepositoryRoot $root -ProguardFolderPath $mappingFolder | Out-Null
  } catch { $forbiddenAabRejected = $true }
} finally {
  $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
  if ($resolvedFixture.StartsWith(
      $fixturePrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and (Test-Path -LiteralPath $resolvedFixture -PathType Container)) {
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
  }
}

Assert-PluginFixture $positiveApkPass 'mapping-aware APK positive fixture failed.'
Assert-PluginFixture $missingApkRejected 'missing Firebase Core APK fixture passed.'
Assert-PluginFixture $forbiddenApkRejected 'integration_test APK fixture passed.'
Assert-PluginFixture $missingMappingRejected 'missing mapping APK fixture passed.'
Assert-PluginFixture $positiveAabPass 'mapping-aware AAB positive fixture failed.'
Assert-PluginFixture $missingAabRejected 'missing Firebase Core AAB fixture passed.'
Assert-PluginFixture $forbiddenAabRejected 'integration_test AAB fixture passed.'

Write-Output (
  'Release production plugin-integrity fixtures passed: ' +
  'apkPositive=1; apkNegative=3; aabPositive=1; aabNegative=2; ' +
  'mappingAware=true; integrationTestForbidden=true.'
)
