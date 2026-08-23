[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$SnapshotPath,
  [Parameter(Mandatory)][string]$OwnerPath,
  [Parameter(Mandatory)][string]$ExpectedSha256,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30YFix2Restore {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX2 qualified-owner restore rejected: $Message"
  }
}

function Resolve-C30YFix2RestorePath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C30YFix2Restore -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30YFix2Restore -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  return $resolved
}

Assert-C30YFix2Restore -Condition (
  $ExpectedSha256 -cmatch '^[0-9A-F]{64}$'
) -Message 'expected SHA-256 is malformed.'
$snapshot = Resolve-C30YFix2RestorePath `
  -Path $SnapshotPath `
  -Label 'qualified snapshot'
$owner = Resolve-C30YFix2RestorePath `
  -Path $OwnerPath `
  -Label 'qualified owner'
Assert-C30YFix2Restore -Condition (
  (Test-Path -LiteralPath $snapshot -PathType Leaf) -and
  (Test-Path -LiteralPath $owner -PathType Leaf)
) -Message 'snapshot or owner is missing.'
Assert-C30YFix2Restore -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $snapshot).Hash -ceq
    $ExpectedSha256
) -Message 'qualified snapshot hash changed.'

$temporary = $owner + '.c30y-fix2-qualified-restore'
Assert-C30YFix2Restore -Condition (-not (Test-Path -LiteralPath $temporary)) `
  -Message 'stale restore temporary exists.'
try {
  Copy-Item -LiteralPath $snapshot -Destination $temporary
  Assert-C30YFix2Restore -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $temporary).Hash -ceq
      $ExpectedSha256
  ) -Message 'restore temporary differs from the qualified snapshot.'
  Move-Item -LiteralPath $temporary -Destination $owner -Force
  Assert-C30YFix2Restore -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
      $ExpectedSha256
  ) -Message 'qualified owner restore did not bind exact bytes.'
} finally {
  if (Test-Path -LiteralPath $temporary) {
    Remove-Item -LiteralPath $temporary -Force
  }
}

Write-Output 'C30Y FIX2 qualified generated owner restored: exactBytes=true.'
