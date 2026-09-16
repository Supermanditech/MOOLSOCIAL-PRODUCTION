param([Parameter(Mandatory)][ValidatePattern('^[0-9]{3}-[a-z0-9-]+$')][string]$Label)
$ErrorActionPreference='Stop'
$serial='TG8HCYTGGQT885OF'
$package='com.moolsocial.app.cursorreview'
$proof='C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d014-final-20260914/installation-receipt.json'
if((Get-FileHash -LiteralPath $proof).Hash -cne '6735920C95910C1EB2D0F3A79923BA571F07F8D6FD5E0FC759C0B6A8911C23E5'){throw 'Installation proof changed'}
function Read-Adb([string[]]$Arguments){
  $lines=@(& adb -s $serial @Arguments)
  if($LASTEXITCODE -ne 0){throw "ADB operation failed: $($Arguments[0])"}
  return $lines
}
function Assert-Foreground {
  $top=@(Read-Adb @('shell','dumpsys','activity','activities') | Where-Object {$_ -match '^\s*topResumedActivity='})
  if($top.Count -ne 1 -or $top[0] -notmatch '\bu\d+\s+com\.moolsocial\.app\.cursorreview/'){throw 'Review app is not the exact foreground'}
}
$identity=@(Read-Adb @('shell','dumpsys','package',$package)) -join "`n"
if($identity -notmatch 'versionCode=2026091404\b' -or $identity -notmatch 'versionName=1\.0\.0-r66\.23-cursorreview\b'){throw 'Wrong installed candidate'}
Start-Sleep -Milliseconds 2000
Assert-Foreground
$png=Join-Path $PSScriptRoot ($Label+'.png')
$xml=Join-Path $PSScriptRoot ($Label+'.xml')
$record=Join-Path $PSScriptRoot ($Label+'.json')
foreach($path in @($png,$xml,$record)){if(Test-Path -LiteralPath $path){throw 'Capture label already exists'}}
$remote='/sdcard/moolsocial-rv623-'+$Label
[void](Read-Adb @('shell','screencap','-p',($remote+'.png')))
[void](Read-Adb @('pull',($remote+'.png'),$png))
Assert-Foreground
[void](Read-Adb @('shell','uiautomator','dump',($remote+'.xml')) 2> (Join-Path $PSScriptRoot ($Label+'-uiautomator.stderr.log')))
[void](Read-Adb @('pull',($remote+'.xml'),$xml))
Assert-Foreground
$metadata=[ordered]@{label=$Label;device=$serial;package=$package;version='1.0.0-r66.23-cursorreview';versionCode=2026091404;apkSha256='D59EADBB5A57568F91FED9319602BBC84E3B04831CF756534C3526EC0EDF512F';sourceHead='1d5c4be97dc13874af1f4348156782339ecacf60';capturedAt=[DateTimeOffset]::Now.ToString('o');pngSha256=(Get-FileHash -LiteralPath $png).Hash;xmlSha256=(Get-FileHash -LiteralPath $xml).Hash}
[IO.File]::WriteAllText($record,($metadata|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
[xml]$tree=Get-Content -Raw -LiteralPath $xml
Write-Output "Hierarchy nodes=$($tree.SelectNodes('//node').Count)"
Write-Output "PNG=$png"
