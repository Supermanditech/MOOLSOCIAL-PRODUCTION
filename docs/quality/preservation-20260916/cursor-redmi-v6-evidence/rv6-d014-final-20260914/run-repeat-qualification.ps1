$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
. (Join-Path $repo 'scripts/invoke-flutter-with-clean-support.ps1')
$visual=Join-Path $PSScriptRoot 'repeat-flutter-visuals'
if(Test-Path -LiteralPath $visual){throw 'Preserve existing visual qualification'}
Push-Location (Join-Path $repo 'apps/mobile')
try {
  foreach($step in @('matrix','screen','analysis')) {
    $log=Join-Path $PSScriptRoot ('repeat-qualified-'+$step+'.log')
    if(Test-Path -LiteralPath $log){throw 'Preserve existing qualification log'}
    $result=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $repo -Invocation {
      if($step -eq 'matrix') {
        & flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --plain-name 'RV6 D014 warm order link' --dart-define=BUY_R663_VISUAL_CAPTURE=true "--dart-define=BUY_R663_VISUAL_DIRECTORY=$visual" --reporter expanded *> $log
      } elseif($step -eq 'screen') {
        & flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded *> $log
      } else {
        & flutter analyze --no-pub *> $log
      }
    }
    Write-Output "$step exit=$result; log=$log"
    if([int]$result -ne 0){exit ([int]$result)}
  }
} finally {Pop-Location}
