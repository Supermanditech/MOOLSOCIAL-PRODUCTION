param([Parameter(Mandatory)][ValidatePattern('^[a-z0-9-]+$')][string]$Label)
$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$log=Join-Path $PSScriptRoot ($Label+'.log')
if(Test-Path -LiteralPath $log){throw 'Evidence already exists'}
. (Join-Path $repo 'scripts/invoke-flutter-with-clean-support.ps1')
Push-Location (Join-Path $repo 'apps/mobile')
try {
  $result=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $repo -Invocation {
    & flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --plain-name 'RV6 D014 warm order link s-dog-food repeat-store' --reporter expanded *> $log
  }
} finally {Pop-Location}
Write-Output "Focused exit=$result; log=$log"
exit ([int]$result)
