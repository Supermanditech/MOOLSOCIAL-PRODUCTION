$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$source='4221158fead95a89047e3408aaeb11c9a12dd135'
. (Join-Path $repo 'scripts/invoke-flutter-with-clean-support.ps1')
function Assert-Source {
  & git -C $repo diff --quiet $source -- apps backend contracts packages package.json package-lock.json pubspec.yaml pubspec.lock
  if($LASTEXITCODE -ne 0){throw 'Combined source differs from qualified D014 checkpoint'}
}
foreach($cycle in @(1,2)) {
  Assert-Source
  $log=Join-Path $PSScriptRoot ('d014-combined-cycle'+$cycle+'.log')
  $receipt=Join-Path $PSScriptRoot ('d014-combined-cycle'+$cycle+'.result.json')
  if((Test-Path -LiteralPath $log) -or (Test-Path -LiteralPath $receipt)){throw 'Preserve existing cycle evidence'}
  $started=[DateTimeOffset]::Now.ToString('o')
  Push-Location (Join-Path $repo 'apps/mobile')
  try {
    $result=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $repo -Invocation {
      & flutter test --no-pub test/ui_v2/buy test/ui_v2/profile/global_privacy_preferences_v2_test.dart test/ui_v2/profile/global_personal_profile_v2_test.dart test/ui_v2/profile/global_security_v2_test.dart test/chat_settings_hub_test.dart test/app/ui_review_language_store_test.dart --reporter expanded *> $log
    }
  } finally { Pop-Location }
  Assert-Source
  $record=[ordered]@{source=$source;cycle=$cycle;startedAt=$started;finishedAt=[DateTimeOffset]::Now.ToString('o');exitCode=[int]$result;logSha256=(Get-FileHash -LiteralPath $log).Hash;supportRestoration='completed';sourceAfter='equal'}
  [IO.File]::WriteAllText($receipt,($record|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
  $record|ConvertTo-Json -Compress|Write-Output
  if([int]$result -ne 0){exit ([int]$result)}
}
