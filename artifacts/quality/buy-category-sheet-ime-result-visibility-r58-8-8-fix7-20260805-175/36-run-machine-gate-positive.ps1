$ErrorActionPreference = 'Stop'
$repository = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$gate = Join-Path $repository 'scripts\check-apk-regression-gate-state.ps1'
$state = Join-Path $repository 'config\apk-regression-gate-state.json'
$defines = @(
  'MOOLSOCIAL_DEVICE_REVIEW=true',
  'MOOLSOCIAL_USE_EMULATORS=true',
  'MOOLSOCIAL_CANDIDATE_ID=BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7'
)
& $gate `
  -StatePath $state `
  -CandidateId 'BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7' `
  -BuildName '1.0.0-r58.23' `
  -BuildNumber '2026080419' `
  -BuildMode profile `
  -SourceFingerprint 'A05B47F0893778064E255574DF3678BF198DAE72A18DA7C81710693557AE1BEE' `
  -RuntimeDefine $defines
