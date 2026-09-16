[CmdletBinding()]
param([Parameter(Mandatory)][string]$ExpectedHead)
$ErrorActionPreference='Stop'
$root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$branch='work/cursor-ui/redmi-v6-audit-20260913'
$source='f1500cb2b6a4e27c7c11ef5bca6f3e8ccaf54c9b'
$candidateRoot=Join-Path $root 'apps/mobile/build/cursor-review-r66.22'
$delivery=Join-Path $PSScriptRoot 'delivery'
function Git-Lines([string[]]$Arguments) {
  $lines=@(& git -C $root @Arguments)
  if($LASTEXITCODE -ne 0){throw "Git verification failed: $($Arguments[0])"}
  return $lines
}
if(@(Git-Lines @('rev-parse','HEAD'))[0] -cne $ExpectedHead){throw 'Final HEAD mismatch'}
if(@(Git-Lines @('branch','--show-current'))[0] -cne $branch){throw 'Final branch mismatch'}
if(@(Git-Lines @('status','--porcelain=v1')).Count -ne 0){throw 'Final Git status is not clean'}
$remote=@(Git-Lines @('ls-remote','--heads','origin',"refs/heads/$branch"))
if($remote.Count -ne 1 -or $remote[0].Split("`t")[0] -cne $ExpectedHead){throw 'Final live remote differs'}
[void](Git-Lines @('diff','--quiet',$source,'HEAD','--','apps/mobile','apps/backend','contracts','packages','config','scripts','package.json','package-lock.json'))
$manifest=Join-Path $candidateRoot 'source-manifest.txt'
if((Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash -cne '6364AD7D65BD1A6DC85C2E073B143274700125DB8C89067ED5B1B43A068B83D0'){throw 'Manifest checksum differs'}
$lines=@(Get-Content -LiteralPath $manifest)
if($lines.Count -ne 326){throw 'Runtime owner count changed'}
$prefix=[IO.Path]::GetFullPath($root).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
foreach($line in $lines){
  if($line -cnotmatch '^([0-9A-F]{64})  (apps/mobile/[^\r\n]+)$'){throw 'Invalid manifest row'}
  $expectedHash=$Matches[1]
  $owner=[IO.Path]::GetFullPath((Join-Path $root $Matches[2]))
  if(-not $owner.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Runtime owner escaped workspace'}
  if((Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -cne $expectedHash){throw "Runtime bytes changed: $owner"}
}
$installation=Get-Content -Raw -LiteralPath (Join-Path $delivery 'installation-receipt.json') | ConvertFrom-Json
if($installation.apkSha256 -cne $installation.installedApkSha256 -or $installation.sourceHead -cne $source){throw 'Installation receipt does not match source artifact'}
$finalState=Get-Content -Raw -LiteralPath (Join-Path $candidateRoot 'machine-state.json') | ConvertFrom-Json
if($finalState.buildAuthorization -cne 'consumed_one_build'){throw 'One-build authorization not consumed'}
$finalState.machineState='delivered_remaining_device_qualification_pending'
foreach($gate in $finalState.postBuildGates){
  if($gate.id -cin @('child-defects-and-original-disposition','final-evidence-git-handoff')){$gate.state='passed'}
}
$finalState | Add-Member -NotePropertyName finalEvidenceHead -NotePropertyValue $ExpectedHead
$stateReceipt=Join-Path $delivery 'handoff-machine-state.json'
$gitReceipt=Join-Path $delivery 'final-handoff.json'
if((Test-Path -LiteralPath $stateReceipt) -or (Test-Path -LiteralPath $gitReceipt)){throw 'Final receipts already exist'}
[IO.File]::WriteAllText($stateReceipt,($finalState|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $stateReceipt -Destination (Join-Path $candidateRoot 'machine-state.json')
$record=[ordered]@{
  authorizedDeliveryScope='complete'; deviceAcceptance='incomplete_as_explicitly_reported';
  branch=$branch; finalEvidenceHead=$ExpectedHead; liveRemoteHead=$ExpectedHead; gitStatusRecords=0;
  sourceBaseline=$source; applicationSource='3c30ba11521db6bb1a1ec6995b181a81df1a6b34'; runtimeOwnersVerifiedAfterBuild=326;
  candidate=$installation.versionName; apkSha256=$installation.apkSha256; installedApkSha256=$installation.installedApkSha256;
  originalDeviceClosures=18; deviceOpen=@('RV6-D005','RV6-D005-C01','RV6-D009','RV6-D010','RV6-D014');
  noNewApkChildTesting=$true; noIntegration=$true; productionReady=$false;
  report='docs/quality/cursor-redmi-v6-audit-20260913/UAT.md'; timestamp=[DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($gitReceipt,($record|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
if(@(Git-Lines @('status','--porcelain=v1')).Count -ne 0){throw 'Final receipt creation changed Git status'}
Write-Output "Final delivery seal: clean/live remote-equal=$ExpectedHead; source=$source; runtime hashes=326; device acceptance remains explicitly open."
