$ErrorActionPreference = 'Stop'
$proposalRoot = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-successor-qualification-20260914'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$pin = '9b7e5aa7fddc08517432f9b3932da5a36ef7a92d'
function Load-AdmissionFunction([string]$Path) {
  $tokens = $null; $errors = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
  if ($errors.Count) { throw 'Parse failure' }
  $fn = @($ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Test-IntegratedStoreBuyReviewSource'},$true))
  if ($fn.Count -ne 1) { throw 'Exact function not found' }
  return [scriptblock]::Create($fn[0].Extent.Text)
}
. (Load-AdmissionFunction (Join-Path $root 'scripts/check-buy-protected-baseline.ps1'))
if (Test-IntegratedStoreBuyReviewSource $pin) { throw 'Original checker unexpectedly admitted successor' }
Write-Output 'PASS original checker rejects successor (expected limitation)'
. (Load-AdmissionFunction (Join-Path $proposalRoot 'proposed-check-buy-protected-baseline.ps1'))
if (-not (Test-IntegratedStoreBuyReviewSource $pin)) { throw 'Exact real source rejected' }
Write-Output 'PASS proposed admission accepts exact real source; not complete release qualification'
$realGit = (Get-Command git.exe).Source
$script:scenario = ''
function git {
  $a = @($args)
  $global:LASTEXITCODE = 0
  if ($script:scenario -ceq 'wrong-branch' -and $a -contains '--show-current') { return 'work/unapproved' }
  if ($script:scenario -ceq 'missing-ancestor' -and $a -contains 'merge-base') { $global:LASTEXITCODE=1; return }
  if ($script:scenario -ceq 'committed-source-drift' -and $a -contains 'diff' -and $a -contains 'HEAD') { $global:LASTEXITCODE=1; return }
  if ($script:scenario -ceq 'working-source-drift' -and $a -contains 'diff' -and -not ($a -contains 'HEAD')) { $global:LASTEXITCODE=1; return }
  if ($script:scenario -ceq 'untracked-source' -and $a -contains 'ls-files') { return 'apps/mobile/lib/unapproved.dart' }
  if ($script:scenario -ceq 'git-failure') { $global:LASTEXITCODE=128; return }
  & $realGit @a
  $global:LASTEXITCODE=$LASTEXITCODE
}
foreach ($case in @('wrong-branch','missing-ancestor','committed-source-drift','working-source-drift','untracked-source','git-failure')) {
  $script:scenario=$case
  if (Test-IntegratedStoreBuyReviewSource $pin) { throw "Fail-open: $case" }
  Write-Output "PASS rejected $case"
}
$script:scenario=''
if (Test-IntegratedStoreBuyReviewSource ('0'*40)) { throw 'Unknown pin admitted' }
Write-Output 'PASS rejected unknown source pin'
$root='C:/GUARANTEED OUTCOME/unapproved-review-root'
if (Test-IntegratedStoreBuyReviewSource $pin) { throw 'Wrong root admitted' }
Write-Output 'PASS rejected wrong root'
$root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-store-buy-contract-followup-20260912'
$script:scenario='desktop-branch'
function git {
  $global:LASTEXITCODE=0
  if (@($args) -contains '--show-current') { return 'work/codex-ui/store-procurement-bridge-20260912' }
  throw 'Desktop exclusion must occur before any further Git access'
}
if (Test-IntegratedStoreBuyReviewSource $pin) { throw 'Desktop admitted Redmi successor' }
Write-Output 'PASS rejected Redmi successor in Desktop lane'
Write-Output '11 admission checks passed; no tracked files or real Git state changed.'
