[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ManifestPath = 'config/approved-integration-commit-coverage-20260901.json',
  [string]$CandidateHead = 'HEAD'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$manifestFile = if ([IO.Path]::IsPathRooted($ManifestPath)) {
  [IO.Path]::GetFullPath($ManifestPath)
} else {
  [IO.Path]::GetFullPath((Join-Path $root $ManifestPath))
}

function Assert-Coverage([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Approved integration commit coverage rejected: $Message"
  }
}

Assert-Coverage (
  $manifestFile.StartsWith(
    $root + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and (Test-Path -LiteralPath $manifestFile -PathType Leaf)
) 'coverage manifest is missing or outside the repository.'

$manifest = Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json
Assert-Coverage ([int]$manifest.schemaVersion -eq 1) `
  'coverage manifest schema changed.'
Assert-Coverage (
  [string]$manifest.gateId -ceq
    'MOOLSOCIAL-APPROVED-INTEGRATION-COMMIT-COVERAGE-20260901'
) 'coverage manifest identity changed.'

$candidate = (& git -C $root rev-parse "$CandidateHead^{commit}").Trim()
Assert-Coverage ($LASTEXITCODE -eq 0 -and $candidate -cmatch '^[0-9a-f]{40}$') `
  'candidate commit is invalid.'
$baseline = [string]$manifest.baseline.commit
Assert-Coverage ($baseline -cmatch '^[0-9a-f]{40}$') `
  'baseline commit is invalid.'

& git -C $root merge-base --is-ancestor $baseline $candidate
$baselineExit = $LASTEXITCODE
Assert-Coverage ($baselineExit -eq 0) `
  'candidate does not descend from the approved shared baseline.'

$approved = @($manifest.approvedTips)
$rejected = @($manifest.rejectedTips)
Assert-Coverage ($approved.Count -gt 0 -and $rejected.Count -gt 0) `
  'approved or rejected tip inventory is empty.'

$allIds = @($approved + $rejected | ForEach-Object { [string]$_.id })
$allBranches = @($approved + $rejected | ForEach-Object { [string]$_.branch })
$allCommits = @($approved + $rejected | ForEach-Object { [string]$_.commit })
Assert-Coverage (
  @($allIds | Select-Object -Unique).Count -eq $allIds.Count -and
  @($allBranches | Select-Object -Unique).Count -eq $allBranches.Count -and
  @($allCommits | Select-Object -Unique).Count -eq $allCommits.Count
) 'coverage inventory contains a duplicate id, branch or commit.'

foreach ($tip in $approved + $rejected) {
  Assert-Coverage (
    [string]$tip.id -cmatch '^[a-z0-9][a-z0-9-]+$' -and
    [string]$tip.agent -cin @('codex', 'cursor') -and
    [string]$tip.branch -cmatch '^work/[a-z0-9-]+/[a-z0-9][a-z0-9-]+$' -and
    [string]$tip.commit -cmatch '^[0-9a-f]{40}$'
  ) "tip contract is invalid: $([string]$tip.id)"
  & git -C $root cat-file -e "$([string]$tip.commit)^{commit}"
  Assert-Coverage ($LASTEXITCODE -eq 0) `
    "tip commit is unavailable locally: $([string]$tip.id)"
}

foreach ($tip in $rejected) {
  & git -C $root merge-base --is-ancestor ([string]$tip.commit) $candidate
  $rejectedExit = $LASTEXITCODE
  Assert-Coverage ($rejectedExit -in @(0, 1)) `
    "rejected-tip ancestry check failed: $([string]$tip.id)"
  Assert-Coverage ($rejectedExit -eq 1) `
    "rejected tip is present in candidate: $([string]$tip.id)"
}

foreach ($tip in $approved) {
  & git -C $root merge-base --is-ancestor ([string]$tip.commit) $candidate
  $approvedExit = $LASTEXITCODE
  Assert-Coverage ($approvedExit -in @(0, 1)) `
    "approved-tip ancestry check failed: $([string]$tip.id)"
  Assert-Coverage ($approvedExit -eq 0) `
    "approved tip is omitted from candidate: $([string]$tip.id)"
}

$remoteArguments = @('ls-remote', '--exit-code', '--heads', 'origin')
$remoteArguments += @($approved + $rejected | ForEach-Object {
  'refs/heads/' + [string]$_.branch
})
$remoteRows = @(& git -C $root @remoteArguments)
Assert-Coverage ($LASTEXITCODE -eq 0) `
  'approved/rejected remote branch readback failed.'
$remoteByRef = @{}
foreach ($row in $remoteRows) {
  if ($row -notmatch '^([0-9a-f]{40})\s+(refs/heads/.+)$') {
    throw 'Approved integration commit coverage rejected: remote row is invalid.'
  }
  $remoteByRef[$Matches[2]] = $Matches[1]
}
foreach ($tip in $approved + $rejected) {
  $remoteRef = 'refs/heads/' + [string]$tip.branch
  Assert-Coverage (
    $remoteByRef.ContainsKey($remoteRef) -and
    [string]$remoteByRef[$remoteRef] -ceq [string]$tip.commit
  ) "remote tip drifted: $([string]$tip.id)"
}

Write-Output (
  'Approved integration commit coverage passed: ' +
  "candidate=$candidate; approved=$($approved.Count); rejected=$($rejected.Count)."
)
