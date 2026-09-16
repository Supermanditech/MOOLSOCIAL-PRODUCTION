$ErrorActionPreference = 'Stop'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$pin = '3c30ba11521db6bb1a1ec6995b181a81df1a6b34'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $root 'scripts/check-buy-protected-baseline.ps1'),
  [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Admission checker parse failed.' }
$functions = @($ast.FindAll({ param($node)
  $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
  $node.Name -ceq 'Test-IntegratedStoreBuyReviewSource'
}, $true))
if ($functions.Count -ne 1) { throw 'Exact admission function unavailable.' }
. ([scriptblock]::Create($functions[0].Extent.Text))
if (-not (Test-IntegratedStoreBuyReviewSource $pin)) { throw 'Actual source rejected.' }
Write-Output 'PASS actual source with real Git, branch, ancestry and boundaries'
if (Test-IntegratedStoreBuyReviewSource '11b6562e7bf382afeb11e1801a0a390477fcae8f') {
  throw 'Old source pin incorrectly admitted changed source.'
}
Write-Output 'PASS real changed source rejects predecessor pin'

# Only Git discovery is substituted below. Execute the actual parsed function
# and prove each intended negative boundary was reached. No checkout is changed.
$script:scenario = ''
function git {
  $arguments = @($args)
  $global:LASTEXITCODE = 0
  if ($script:scenario -ceq 'wrong-branch' -and $arguments -contains '--show-current') {
    $script:triggered = $true; return 'work/unapproved'
  }
  if ($script:scenario -ceq 'missing-ancestor' -and $arguments -contains 'merge-base') {
    $script:triggered = $true; $global:LASTEXITCODE = 1; return
  }
  if ($script:scenario -ceq 'committed-drift' -and $arguments -contains 'diff' -and $arguments -contains 'HEAD') {
    $script:triggered = $true; $global:LASTEXITCODE = 1; return
  }
  if ($script:scenario -ceq 'working-drift' -and $arguments -contains 'diff' -and -not ($arguments -contains 'HEAD')) {
    $script:triggered = $true; $global:LASTEXITCODE = 1; return
  }
  if ($script:scenario -ceq 'untracked-source' -and $arguments -contains 'ls-files') {
    $script:triggered = $true; return 'apps/mobile/lib/unapproved.dart'
  }
  if ($script:scenario -ceq 'git-failure') {
    $script:triggered = $true; $global:LASTEXITCODE = 128; return
  }
  if ($arguments -contains '--show-current') { return 'work/cursor-ui/redmi-v6-audit-20260913' }
  if ($arguments -contains 'merge-base' -or $arguments -contains 'diff' -or $arguments -contains 'ls-files') { return }
  throw 'Unexpected fixture Git command.'
}
foreach ($case in @('wrong-branch','missing-ancestor','committed-drift','working-drift','untracked-source','git-failure')) {
  $script:scenario = $case
  $script:triggered = $false
  if (Test-IntegratedStoreBuyReviewSource $pin) { throw "Fail-open: $case" }
  if (-not $script:triggered) { throw "Wrong rejection boundary: $case" }
  Write-Output "PASS rejected $case at intended boundary"
}
$script:scenario = ''
if (Test-IntegratedStoreBuyReviewSource ('0' * 40)) { throw 'Unknown pin admitted.' }
Write-Output 'PASS rejected unknown source pin'
$root = 'C:/GUARANTEED OUTCOME/unapproved-review-root'
if (Test-IntegratedStoreBuyReviewSource $pin) { throw 'Wrong root admitted.' }
Write-Output 'PASS rejected wrong root'
Write-Output '10 source admission checks passed; no real source or Git mutation.'
