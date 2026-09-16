param([Parameter(Mandatory)][ValidateSet('matrix','screen','analysis')][string]$Phase)
$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$log=Join-Path $PSScriptRoot ('d014-qualified-'+$Phase+'.log')
if(Test-Path -LiteralPath $log){throw 'Preserve existing test log'}
. (Join-Path $repo 'scripts/invoke-flutter-with-clean-support.ps1')
Push-Location (Join-Path $repo 'apps/mobile')
try {
  $result=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $repo -Invocation {
    if($Phase -eq 'matrix') {
      & flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --plain-name 'RV6 D014 warm order link' --reporter expanded --dart-define=BUY_R663_VISUAL_CAPTURE=true "--dart-define=BUY_R663_VISUAL_DIRECTORY=$PSScriptRoot/d014-router-guard-visuals" *> $log
    } elseif($Phase -eq 'screen') {
      & flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded *> $log
    } else {
      & flutter analyze --no-pub *> $log
    }
  }
} finally { Pop-Location }
exit ([int]$result)
