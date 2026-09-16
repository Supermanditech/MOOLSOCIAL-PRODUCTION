param([Parameter(Mandatory)][ValidateSet('reproduction','correction','router-guard')][string]$Phase)
$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$log=Join-Path $PSScriptRoot ('d014-nested-'+$Phase+'.log')
if(Test-Path -LiteralPath $log){throw 'Preserve existing test log'}
. (Join-Path $repo 'scripts/invoke-flutter-with-clean-support.ps1')
Push-Location (Join-Path $repo 'apps/mobile')
try {
  Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $repo -Invocation {
    & flutter test test/ui_v2/buy/buy_v2_screen_test.dart --plain-name 'RV6 D014 warm order link s-dog-food recent-other-return' --reporter expanded *> $log
  }
} finally { Pop-Location }
