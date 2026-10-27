$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'profile-b02-admission.ps1')
. (Join-Path $PSScriptRoot 'profile-b02-source-seal.ps1')
$n=0
function Check([bool]$ok){if(!$ok){throw 'B02 source seal regression rejected'};$script:n++}
Check (Test-B02SealSet @('a','b') @('b','a'))
Check (!(Test-B02SealSet @('a','b') @('a','c')))
Check (!(Test-B02SealSet @('a','a') @('a')))
foreach($i in 0..3){Check ((Get-B02SealStage $i) -ceq @('metadata','runtime','evidence','sealed')[$i])}
foreach($i in @(-1,4,9)){$rejected=$false;try{Get-B02SealStage $i|Out-Null}catch{$rejected=$true};Check $rejected}
$root=Split-Path -Parent $PSScriptRoot
$r=Get-Content -Raw (Join-Path $root 'docs/quality/PROFILE-B02-SOURCE-SEAL-20261027.json')|ConvertFrom-Json
Check ($r.runtimeOwners.Count -eq 22 -and $r.metadataOwners.Count -eq 7 -and $r.evidenceOwners.Count -eq 2)
Check (!$r.limits.productionAcceptance -and !$r.limits.formalTicketClose -and !$r.limits.cloud -and !$r.limits.billing -and !$r.limits.apk -and !$r.limits.main -and !$r.limits.forcePush)
foreach($f in $r.files){Check ((Get-B02SealDigest (Join-Path $root $f.path)) -ceq $f.sha256Lf)}
$original=(@(& git -C $root show 'f46d6a1300ec26f021248499e86e1ad9d9e74c8c:scripts/profile-b02-admission.ps1') -join "`n").TrimEnd()
if($LASTEXITCODE -ne 0){throw 'Missing original B02 admission'}
$current=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'profile-b02-admission.ps1')).Replace("`r`n","`n")
$dispatch="  if(Test-Path (Join-Path `$root 'docs/quality/PROFILE-B02-SOURCE-SEAL-20261027.json')){`n    . (Join-Path `$root 'scripts/profile-b02-source-seal.ps1')`n    Invoke-ProfileB02SourceSeal`n    return`n  }`n"
Check ($current.Contains($dispatch))
Check ($current.Replace($dispatch,'').TrimEnd() -ceq $original)
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
foreach($foreign in @('apps/mobile/lib/main.dart','backend/functions/package.json','.env','apps/mobile/.flutter-plugins-dependencies')){
  $rejected=$false;try{Assert-ProfileB02Owners @($foreign) @($r.runtimeOwners+$r.metadataOwners+$r.evidenceOwners)}catch{$rejected=$true};Check $rejected
}
Write-Output "B02 source-sealing regression checks passed: $n."
