# Read-only, Windows PowerShell5.1-compatible guard for cleanup candidates.
# This is copied verbatim into the founder's cleanup script, without dependencies.
function Get-CleanupEvidenceProtection {
  param([string[]]$RepositoryRoots)
  $protected = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($repository in $RepositoryRoots) {
    $repository = [IO.Path]::GetFullPath($repository)
    if (-not $repository.StartsWith('C:\GUARANTEED OUTCOME\', [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Cleanup repository inventory is outside the authorized workspace.'
    }
    $registry = Join-Path $repository 'config/codex-development-regression-registry.json'
    if (-not (Test-Path -LiteralPath $registry -PathType Leaf)) {
      throw "Cleanup evidence inventory missing: $registry"
    }
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($auditRoot in @('artifacts/quality','approved-references','apps/mobile/build/review-candidates')) {
      [void]$protected.Add([IO.Path]::GetFullPath((Join-Path $repository $auditRoot)))
    }
    $registryData = Get-Content -Raw -LiteralPath $registry | ConvertFrom-Json
    foreach ($entry in $registryData.entries) {
      foreach ($relative in $entry.evidence) {
        if ([string]$relative -match '(?i)\.(apk|aab)$') { $paths.Add([string]$relative) }
      }
    }
    # Config includes candidate/release manifests. Read values without logging them.
    $stack = [Collections.Generic.Stack[object]]::new()
    foreach ($manifest in Get-ChildItem -LiteralPath (Join-Path $repository 'config') -File -Filter '*.json') {
      $stack.Push((Get-Content -Raw -LiteralPath $manifest.FullName | ConvertFrom-Json))
    }
    while ($stack.Count -gt 0) {
      $value = $stack.Pop()
      if ($value -is [string]) {
        if ($value -match '(?i)\.(apk|aab)$') { $paths.Add($value) }
      } elseif ($value -is [Collections.IEnumerable] -and $value -isnot [pscustomobject]) {
        foreach ($child in $value) { if ($null -ne $child) { $stack.Push($child) } }
      } elseif ($value -is [pscustomobject]) {
        foreach ($property in $value.PSObject.Properties) {
          if ($null -ne $property.Value) { $stack.Push($property.Value) }
        }
      }
    }
    foreach ($path in $paths) {
      $resolved = if ([IO.Path]::IsPathRooted($path)) { [IO.Path]::GetFullPath($path) }
                  else { [IO.Path]::GetFullPath((Join-Path $repository $path)) }
      [void]$protected.Add($resolved)
    }
  }
  return ,$protected
}

function Test-CleanupEvidenceProtected {
  param([string]$Path, $ProtectedEvidence)
  $resolved = [IO.Path]::GetFullPath($Path)
  # Audit directories remain authoritative even when a manifest omitted a file.
  if ($ProtectedEvidence.Contains($resolved) -or
      $resolved.Replace('\','/') -match '(?i)/(artifacts/quality|approved-references|apps/mobile/build/review-candidates)/') { return $true }
  $boundary = $resolved.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
  foreach ($reference in $ProtectedEvidence) {
    if ($reference.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

function Get-CleanupActiveRepositoryRoots {
  param([string]$ProductionRoot, [string[]]$InactiveRemovalRoots, [scriptblock]$ReadGit)
  $inactive = @($InactiveRemovalRoots | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\','/') })
  $registered = @((& $ReadGit $ProductionRoot @('worktree','list','--porcelain')).Split("`n") |
    Where-Object { $_.StartsWith('worktree ') } | ForEach-Object { [IO.Path]::GetFullPath($_.Substring(9).Trim()).TrimEnd('\','/') })
  if ($registered.Count -eq 0) { throw 'Registered cleanup repository inventory is unavailable.' }
  foreach ($root in $registered) {
    if (-not $root.StartsWith('C:\GUARANTEED OUTCOME\', [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Registered cleanup repository is outside the authorized workspace.'
    }
  }
  return @($registered | Where-Object { $_ -notin $inactive })
}

function Assert-CleanupActiveSnapshots {
  param($Heads, $Statuses, [string[]]$ExpectedRoots, [scriptblock]$ReadGit)
  if ($Heads.Count -eq 0 -or $ExpectedRoots.Count -eq 0 -or
      (($Heads.Keys | Sort-Object) -join '|') -cne (($ExpectedRoots | Sort-Object) -join '|') -or
      (($Heads.Keys | Sort-Object) -join '|') -cne (($Statuses.Keys | Sort-Object) -join '|')) {
    throw 'Active cleanup snapshot inventory is missing or inconsistent.'
  }
  foreach ($repository in $Heads.Keys) {
    if ((& $ReadGit $repository @('rev-parse','HEAD')).Trim() -cne $Heads[$repository] -or
        (& $ReadGit $repository @('status','--porcelain=v1','-z','--untracked-files=all')) -cne $Statuses[$repository]) {
      throw 'Active agent work changed during cleanup; destructive operation refused.'
    }
  }
}
