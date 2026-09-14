Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'invoke-flutter-with-clean-support.ps1')

$fixtureRoot = Join-Path $repoRoot 'tmp/rel-build-clean-fixture'
$fixturePrefix = [IO.Path]::GetFullPath((Join-Path $repoRoot 'tmp')).TrimEnd(
  [char[]]@('\', '/')
) + [IO.Path]::DirectorySeparatorChar
$resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
if (-not $resolvedFixture.StartsWith(
    $fixturePrefix,
    [StringComparison]::OrdinalIgnoreCase
  )) {
  throw 'Fixture root escaped repository tmp.'
}
if (Test-Path -LiteralPath $resolvedFixture) {
  Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
}
New-Item -ItemType Directory -Path $resolvedFixture | Out-Null

$owners = @(
  'apps/mobile/.dart_tool/package_config.json',
  'apps/mobile/.dart_tool/package_graph.json',
  'apps/mobile/.flutter-plugins-dependencies',
  'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
)
$outside = Join-Path $resolvedFixture 'outside.txt'
$outsideBytes = [byte[]](41, 42, 43, 44)
[IO.File]::WriteAllBytes($outside, $outsideBytes)
foreach ($index in 0..($owners.Count - 1)) {
  $path = Join-Path $resolvedFixture $owners[$index]
  $parent = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  [IO.File]::WriteAllBytes($path, [byte[]]($index, 7, 13, 29, 255))
}

try {
  & git -C $resolvedFixture init --quiet
  if ($LASTEXITCODE -ne 0) { throw 'fixture git init failed' }
  & git -C $resolvedFixture add -- @owners
  if ($LASTEXITCODE -ne 0) { throw 'fixture git add failed' }

  $before = [ordered]@{}
  foreach ($owner in $owners) {
    $before[$owner] = [IO.File]::ReadAllBytes((Join-Path $resolvedFixture $owner))
  }

  $successExit = Invoke-MoolSocialFlutterWithCleanSupport `
    -RepositoryRoot $resolvedFixture `
    -Invocation {
      foreach ($owner in $owners) {
        [IO.File]::WriteAllBytes(
          (Join-Path $resolvedFixture $owner),
          [byte[]](99, 98, 97)
        )
      }
      $global:LASTEXITCODE = 0
    }
  if ($successExit -ne 0) { throw 'successful child exit changed' }

  $failureExit = Invoke-MoolSocialFlutterWithCleanSupport `
    -RepositoryRoot $resolvedFixture `
    -Invocation {
      [IO.File]::WriteAllBytes(
        (Join-Path $resolvedFixture $owners[0]),
        [byte[]](1, 1, 1)
      )
      Remove-Item -LiteralPath (Join-Path $resolvedFixture $owners[1]) -Force
      $global:LASTEXITCODE = 37
    }
  if ($failureExit -ne 37) { throw 'failing child exit changed' }

  foreach ($owner in $owners) {
    $actual = [IO.File]::ReadAllBytes((Join-Path $resolvedFixture $owner))
    if (-not (Test-MoolSocialExactBytes `
        -Left $actual `
        -Right ([byte[]]$before[$owner])
      )) {
      throw "support owner was not restored: $owner"
    }
  }
  $outsideAfter = [IO.File]::ReadAllBytes($outside)
  if (-not (Test-MoolSocialExactBytes `
      -Left $outsideAfter `
      -Right $outsideBytes
    )) {
    throw 'outside fixture changed'
  }

  $mutexName = Get-MoolSocialFlutterSupportMutexName `
    -RepositoryRoot $resolvedFixture
  $marker = Join-Path $resolvedFixture 'mutex-ready.txt'
  $job = Start-Job -ArgumentList @($mutexName, $marker) -ScriptBlock {
    param($Name, $Marker)
    $jobMutex = [Threading.Mutex]::new($false, $Name)
    $jobHeld = $jobMutex.WaitOne(0)
    if (-not $jobHeld) { throw 'job mutex acquisition failed' }
    try {
      [IO.File]::WriteAllText($Marker, 'ready')
      Start-Sleep -Seconds 20
    } finally {
      $jobMutex.ReleaseMutex()
      $jobMutex.Dispose()
    }
  }
  try {
    foreach ($attempt in 1..50) {
      if (Test-Path -LiteralPath $marker -PathType Leaf) { break }
      Start-Sleep -Milliseconds 100
    }
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
      throw 'fixture mutex job did not become ready'
    }
    $concurrencyRejected = $false
    try {
      Invoke-MoolSocialFlutterWithCleanSupport `
        -RepositoryRoot $resolvedFixture `
        -Invocation { $global:LASTEXITCODE = 0 } | Out-Null
    } catch {
      $concurrencyRejected = $_.Exception.Message -match
        'Another guarded Flutter operation'
    }
    if (-not $concurrencyRejected) {
      throw 'concurrent guarded invocation was not rejected'
    }
  } finally {
    Stop-Job -Job $job -ErrorAction SilentlyContinue
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $marker -PathType Leaf) {
      Remove-Item -LiteralPath $marker -Force
    }
  }

  Write-Output 'Flutter tracked-support cleanliness guard passed.'
} finally {
  if (Test-Path -LiteralPath $resolvedFixture) {
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
  }
}
