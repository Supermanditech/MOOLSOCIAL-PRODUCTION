param([Parameter(Mandatory)][ValidatePattern('^[0-9]{3}-[a-z0-9-]+$')][string]$Label)
$ErrorActionPreference='Stop'
$serial='TG8HCYTGGQT885OF'
$package='com.moolsocial.app.cursorreview'
$proof='C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-language-final-20260914/delivery/installation-receipt.json'
if((Get-FileHash -LiteralPath $proof).Hash -cne '9F0C4CAEBFD1DE0B9DBBFE23FD8EAC4997833B17DE01969A62ACECE0B323E58A'){throw 'Installation proof changed'}
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
if($identity -notmatch 'versionCode=2026091403\b' -or $identity -notmatch 'versionName=1\.0\.0-r66\.22-cursorreview\b'){throw 'Wrong installed candidate'}
Start-Sleep -Milliseconds 2000
Assert-Foreground
$png=Join-Path $PSScriptRoot ($Label+'.png')
$xml=Join-Path $PSScriptRoot ($Label+'.xml')
$record=Join-Path $PSScriptRoot ($Label+'.json')
foreach($path in @($png,$xml,$record)){if(Test-Path -LiteralPath $path){throw 'Capture label already exists'}}
$remote='/sdcard/moolsocial-rv622-'+$Label
[void](Read-Adb @('shell','screencap','-p',($remote+'.png')))
[void](Read-Adb @('pull',($remote+'.png'),$png))
Assert-Foreground
[void](Read-Adb @('shell','uiautomator','dump',($remote+'.xml')) 2> (Join-Path $PSScriptRoot ($Label+'-uiautomator.stderr.log')))
[void](Read-Adb @('pull',($remote+'.xml'),$xml))
Assert-Foreground
$metadata=[ordered]@{label=$Label;device=$serial;package=$package;version='1.0.0-r66.22-cursorreview';versionCode=2026091403;apkSha256='4EC88FAF583797B60220CC2795CB5690D1F8779130B037CCCF75E98AA1699A16';sourceHead='f1500cb2b6a4e27c7c11ef5bca6f3e8ccaf54c9b';capturedAt=[DateTimeOffset]::Now.ToString('o');pngSha256=(Get-FileHash -LiteralPath $png).Hash;xmlSha256=(Get-FileHash -LiteralPath $xml).Hash}
[IO.File]::WriteAllText($record,($metadata|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
[xml]$tree=Get-Content -Raw -LiteralPath $xml
Write-Output "Hierarchy nodes=$($tree.SelectNodes('//node').Count)"
Write-Output "PNG=$png"
