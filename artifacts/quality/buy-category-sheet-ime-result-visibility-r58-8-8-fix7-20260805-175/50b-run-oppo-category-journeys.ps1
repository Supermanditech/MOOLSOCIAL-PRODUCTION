[CmdletBinding()]
param([string]$Serial = '2b3e0f71')

$ErrorActionPreference = 'Stop'
$candidate = $PSScriptRoot
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$audit15 = Join-Path $repo 'artifacts/quality/buy-cross-family-terminal-audit-r58-8-audit15-20260804-168'
$preserved = Join-Path $audit15 '10-run-oppo-audit15.ps1'
$template = Join-Path $repo 'artifacts/quality/buy-cross-family-terminal-audit-r58-8-audit14-20260804-167/10-run-oppo-audit14.ps1'
$corrections = Join-Path $candidate '52b-inner-source-corrections-candidate.txt'
$helpers = Join-Path $candidate '55-category-helpers-candidate.txt'
$body = Join-Path $candidate '53-oppo-category-body.txt'
$root = Join-Path $candidate 'oppo-category-journeys-normal-harness3'
if (Test-Path -LiteralPath $root) {
  throw "Refusing to overwrite R58.8.8 OPPO journey evidence: $root"
}

$source = Get-Content -Raw -LiteralPath $preserved
$source = $source.Replace(
  "`$repo = (Resolve-Path -LiteralPath (Join-Path `$PSScriptRoot '../../..')).Path",
  "`$repo = '$($repo.Replace("'", "''"))'"
)
$source = $source.Replace(
  "`$template = Join-Path `$repo 'artifacts/quality/buy-cross-family-terminal-audit-r58-8-audit14-20260804-167/10-run-oppo-audit14.ps1'",
  "`$template = '$($template.Replace("'", "''"))'"
)
$source = $source.Replace(
  "`$corrections = Join-Path `$PSScriptRoot '03-inner-source-corrections.txt'",
  "`$corrections = '$($corrections.Replace("'", "''"))'"
)
$source = $source.Replace(
  "`$helpers = Join-Path `$PSScriptRoot '05-audit-helpers.txt'",
  "`$helpers = '$($helpers.Replace("'", "''"))'"
)
$source = $source.Replace(
  "`$body = Join-Path `$PSScriptRoot '06-audit-body.txt'",
  "`$body = '$($body.Replace("'", "''"))'"
)
$source = $source.Replace(
  "`$root = Join-Path `$PSScriptRoot 'oppo-audit'",
  "`$root = '$($root.Replace("'", "''"))'"
)

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput(
  $source,
  [ref]$tokens,
  [ref]$parseErrors
) | Out-Null
if ($parseErrors.Count -ne 0) {
  throw "Generated R58.8.8 journey harness did not parse: $($parseErrors -join '; ')"
}
& ([scriptblock]::Create($source)) -Serial $Serial
