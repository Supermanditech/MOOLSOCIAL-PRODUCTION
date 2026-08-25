Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-MoolSocialExactBytes {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Left,
    [Parameter(Mandatory = $true)][byte[]]$Right
  )
  return (
    $Left.Length -eq $Right.Length -and
    [Convert]::ToBase64String($Left) -ceq [Convert]::ToBase64String($Right)
  )
}

function Get-MoolSocialFlutterSupportMutexName {
  param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

  $canonicalRoot = [IO.Path]::GetFullPath($RepositoryRoot).
    TrimEnd([char[]]@('\', '/')).ToLowerInvariant()
  $bytes = [Text.Encoding]::UTF8.GetBytes($canonicalRoot)
  $hash = [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($bytes)
  )
  return "Local\MoolSocialFlutterSupport_$hash"
}

function Invoke-MoolSocialFlutterWithCleanSupport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,

    [Parameter(Mandatory = $true)]
    [scriptblock]$Invocation
  )

  $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
    [char[]]@('\', '/')
  )
  $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
  $relativeOwners = @(
    'apps/mobile/.dart_tool/package_config.json',
    'apps/mobile/.dart_tool/package_graph.json',
    'apps/mobile/.flutter-plugins-dependencies',
    'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
  )
  $snapshots = [ordered]@{}
  $resolvedKeys = @()

  foreach ($relativeOwner in $relativeOwners) {
    $resolved = [IO.Path]::GetFullPath((Join-Path $root $relativeOwner))
    if (-not $resolved.StartsWith(
        $rootPrefix,
        [StringComparison]::OrdinalIgnoreCase
      )) {
      throw "Flutter support owner escaped the repository: $relativeOwner"
    }
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
      throw "Flutter support owner is missing: $relativeOwner"
    }
    $item = Get-Item -LiteralPath $resolved -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Flutter support owner is a reparse point: $relativeOwner"
    }
    $key = $resolved.ToLowerInvariant()
    if ($resolvedKeys -contains $key) {
      throw "Flutter support owner resolves twice: $relativeOwner"
    }
    $resolvedKeys += $key
    $tracked = @(& git -C $root ls-files --error-unmatch -- $relativeOwner `
        2>$null)
    if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {
      throw "Flutter support owner is not exactly tracked: $relativeOwner"
    }
    $snapshots[$resolved] = [IO.File]::ReadAllBytes($resolved)
  }

  $mutexName = Get-MoolSocialFlutterSupportMutexName -RepositoryRoot $root
  $mutex = [Threading.Mutex]::new($false, $mutexName)
  $mutexHeld = $false
  $childExit = 0
  $primaryFailure = $null
  $restoreFailures = @()
  try {
    $mutexHeld = $mutex.WaitOne(0)
    if (-not $mutexHeld) {
      throw 'Another guarded Flutter operation owns this worktree.'
    }
    try {
      & $Invocation | Out-Host
      $childExit = [int]$LASTEXITCODE
    } catch {
      $primaryFailure = $_
    }
  } finally {
    if ($mutexHeld) {
      foreach ($resolved in $snapshots.Keys) {
        try {
          $expected = [byte[]]$snapshots[$resolved]
          $currentMatches = $false
          if (Test-Path -LiteralPath $resolved -PathType Leaf) {
            $current = [IO.File]::ReadAllBytes($resolved)
            $currentMatches = Test-MoolSocialExactBytes `
              -Left $current `
              -Right $expected
          }
          if (-not $currentMatches) {
            [IO.File]::WriteAllBytes($resolved, $expected)
          }
          $restored = [IO.File]::ReadAllBytes($resolved)
          if (-not (Test-MoolSocialExactBytes `
              -Left $restored `
              -Right $expected
            )) {
            throw 'restored bytes differ from the snapshot'
          }
        } catch {
          $restoreFailures += "$resolved :: $($_.Exception.Message)"
        }
      }
      $mutex.ReleaseMutex()
    }
    $mutex.Dispose()
  }

  if ($restoreFailures.Count -gt 0) {
    throw (
      'Flutter support restoration failed: ' +
      ($restoreFailures -join '; ')
    )
  }
  if ($null -ne $primaryFailure) {
    throw $primaryFailure
  }
  return $childExit
}
