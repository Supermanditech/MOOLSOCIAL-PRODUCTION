# Exact founder-authorized historical loss record. No release/build authority.
function Test-ArtifactRetentionMaintenanceOwner {
  param([hashtable]$Facts)
  $identity = @{
    Role='primary'; Task='/root'; ClaimTask='/root'; ClaimRole='primary'
    Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921'
    Branch='work/cursor-ui/buy-ready-20260921'; Lane='cursor_ui'
    WorkId='buy-ready-20260921'; TicketId='UAW-CURSOR-BUY-READY-20260921'
    AuthoritySha256='70F6FE4BAB84B29D9A0C323B6B48CC2CFC2515E25761431AEF2F69E186138370'
  }
  foreach ($key in $identity.Keys) {
    if (-not $Facts.ContainsKey($key) -or [string]$Facts[$key] -cne $identity[$key]) { return $false }
  }
  return $Facts.GenerationVerified -eq $true -and
    $Facts.Phase -cin @('implementation','pre_commit','handoff') -and
    $Facts.Owner -cin @(
      'docs/quality/CURSOR-BUY-ARTIFACT-RETENTION-20261002.json',
      'scripts/check-codex-development-regression-memory.ps1',
      'scripts/artifact-evidence-retention.ps1',
      'scripts/check-cleanup-artifact-retention.ps1',
      'scripts/test-artifact-evidence-retention.ps1'
    )
}

function Get-RetiredRegressionArtifacts {
  param([string]$RepositoryRoot, $Registry, [string[]]$EvidenceRoots)
  $record = Join-Path $RepositoryRoot 'docs/quality/CURSOR-BUY-ARTIFACT-RETENTION-20261002.json'
  $expectedRecordSha = '70F6FE4BAB84B29D9A0C323B6B48CC2CFC2515E25761431AEF2F69E186138370'
  if (-not (Test-Path -LiteralPath $record -PathType Leaf) -or
      (Get-FileHash -LiteralPath $record -Algorithm SHA256).Hash -cne $expectedRecordSha) {
    throw 'Historical artifact retirement authority/evidence is missing or changed.'
  }
  $contract = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
  if ($contract.schemaVersion -ne 1 -or $contract.artifactCount -ne 3 -or
      @($contract.artifacts).Count -ne 3) { throw 'Unexpected retirement inventory.' }
  # Current build/install/candidate owners cannot consume this historical waiver.
  $candidateOwners = @((Join-Path $RepositoryRoot 'config/apk-regression-gate-state.json')) +
    @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'docs/quality') -File -Filter 'CURSOR-BUY-*APK.json' | ForEach-Object { $_.FullName })
  $candidatePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($candidateOwner in $candidateOwners) {
    if (-not (Test-Path -LiteralPath $candidateOwner -PathType Leaf)) { throw 'Current candidate state is unavailable.' }
    $candidateState = Get-Content -Raw -LiteralPath $candidateOwner | ConvertFrom-Json
    $stack = [Collections.Generic.Stack[object]]::new()
    foreach ($field in @('candidate','artifact','buildResult','installResult','promotion')) {
      if ($null -ne $candidateState.$field) { $stack.Push($candidateState.$field) }
    }
    while ($stack.Count -gt 0) {
      $value = $stack.Pop()
      if ($value -is [string]) {
        if ($value -match '(?i)\.(apk|aab)$') {
          $path = if ([IO.Path]::IsPathRooted($value)) { [IO.Path]::GetFullPath($value) }
                  else { [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $value)) }
          [void]$candidatePaths.Add($path)
        }
      } elseif ($value -is [Collections.IEnumerable] -and $value -isnot [pscustomobject]) {
        foreach ($child in $value) { if ($null -ne $child) { $stack.Push($child) } }
      } elseif ($value -is [pscustomobject]) {
        foreach ($property in $value.PSObject.Properties) { if ($null -ne $property.Value) { $stack.Push($property.Value) } }
      }
    }
  }
  $admitted = [Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::Ordinal)
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($artifact in $contract.artifacts) {
    $relative = [string]$artifact.path
    foreach ($retiredRoot in @($RepositoryRoot) + @($EvidenceRoots)) {
      if ($candidatePaths.Contains([IO.Path]::GetFullPath((Join-Path $retiredRoot $relative)))) {
        throw 'A current candidate references a retired historical binary.'
      }
    }
    if (-not $seen.Add($relative) -or $artifact.releaseAuthority -ne $false -or
        $artifact.state -cne 'deleted_historical_rejected_non_reusable') {
      throw 'Duplicate or releasable retirement artifact.'
    }
    $consumers = @($Registry.entries | Where-Object {
      @($_.evidence | Where-Object { [string]$_ -ceq $relative }).Count -gt 0
    } | ForEach-Object { [string]$_.id } | Sort-Object)
    if (($consumers -join '|') -cne (@($artifact.registryEntryIds | Sort-Object) -join '|')) {
      throw "Retirement consumers changed or are unused: $relative"
    }
    foreach ($source in $artifact.provenance) {
      $sourcePath = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $source.path))
      $boundary = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
      if (-not $sourcePath.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase) -or
          -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw 'Retirement provenance escapes the repository or is unavailable.'
      }
      $text = [IO.File]::ReadAllText($sourcePath).Replace("`r`n", "`n")
      $hasher = [Security.Cryptography.SHA256]::Create()
      try { $digest = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-','') }
      finally { $hasher.Dispose() }
      if ($digest -cne [string]$source.normalizedSha256) { throw "Retirement provenance changed: $($source.path)" }
      $document = $text | ConvertFrom-Json
      foreach ($assertion in $source.assertions.PSObject.Properties) {
        $value = $document
        foreach ($segment in $assertion.Name.TrimStart('/').Split('/')) {
          $property = @($value.PSObject.Properties | Where-Object { $_.Name -ceq $segment })
          if ($property.Count -ne 1) { throw "Missing original provenance field: $($assertion.Name)" }
          $value = $property[0].Value
        }
        if (($value | ConvertTo-Json -Compress) -cne ($assertion.Value | ConvertTo-Json -Compress)) {
          throw "Original artifact identity/disposition changed: $($assertion.Name)"
        }
      }
    }
    foreach ($candidateRoot in $EvidenceRoots) {
      $candidate = Join-Path $candidateRoot $relative
      if (Test-Path -LiteralPath $candidate) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf) -or
            (Get-Item -LiteralPath $candidate).Length -ne $artifact.bytes -or
            (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -cne $artifact.artifactSha256) {
          throw "Restored historical binary has wrong identity: $relative"
        }
      }
    }
    foreach ($id in $consumers) { $admitted.Add($id + '|' + $relative, $true) }
  }
  return ,$admitted
}
