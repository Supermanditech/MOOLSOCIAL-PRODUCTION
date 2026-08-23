[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$owner = Join-Path $root 'scripts\invoke-personal-c26h-semantic-tap.ps1'
if (-not (Test-Path -LiteralPath $owner -PathType Leaf)) { throw 'C26H semantic-tap owner is missing.' }
$source = Get-Content -Raw -LiteralPath $owner
foreach ($token in @(
  'Refusing to overwrite tap evidence',
  'shell dumpsys input_method',
  'mInputShown=true',
  'Visible input method covers native navigation',
  '//node[@clickable="true"]',
  '-ceq $Semantic',
  'Expected exactly one clickable exact semantic',
  '$right -le $left -or $bottom -le $top',
  '[Math]::Floor',
  'shell input tap $x $y'
)) {
  if (-not $source.Contains($token)) { throw "Semantic-tap invariant is missing: $token" }
}
Write-Output 'C26H exact semantic-tap gate passed.'
