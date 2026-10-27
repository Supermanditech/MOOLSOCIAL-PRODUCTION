[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'thin-b07-b04-admission.ps1')
. (Join-Path $PSScriptRoot 'thin-b07-b04-source-seal.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message) {if(!$Condition) {throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name) {if(!$Condition) {throw "AI seal test: $Name"};$script:cases++}
$root=Split-Path -Parent $PSScriptRoot
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b07-b04-20261027';Branch='work/codex-backend/thin-b07-b04-20261027';Lane='codex_backend';Role='primary';Task='/root/codex_backend_thin_b07_b04';WorkId='thin-b07-b04-20261027';Ticket='THIN-B07-B04-PROFILE';Phase='implementation'}
Check (Test-ThinB07B04Identity $facts) 'exact implementation'
foreach($key in $facts.Keys) {$bad=$facts.Clone();$bad[$key]='foreign';Check (!(Test-ThinB07B04Identity $bad)) "foreign $key"}
foreach($phase in @('build','deployment','ticket_close','ticket_acceptance','handoff')) {$bad=$facts.Clone();$bad.Phase=$phase;Check (!(Test-ThinB07B04Identity $bad)) "blocked $phase"}
Check ((Get-ThinSealStage 0) -ceq 'metadata') 'metadata'
Check ((Get-ThinSealStage 1) -ceq 'source') 'source'
Check ((Get-ThinSealStage 2) -ceq 'evidence') 'evidence'
Check ((Get-ThinSealStage 3) -ceq 'sealed') 'sealed'
foreach($count in @(-1,4,5)) {$rejected=$false;try {Get-ThinSealStage $count|Out-Null}catch {$rejected=$true};Check $rejected "reject $count"}
$record=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B07-B04-SOURCE-SEAL-20261028.json')|ConvertFrom-Json
Check ((Get-ThinSealDigest (Join-Path $root 'docs/quality/THIN-B07-B04-SOURCE-SEAL-20261028.json')) -ceq '5AFB5762E80C44E201240BC765538BEE94328509515ED15CA2F8305E8AC003EA') 'bound record'
Check ($record.sourceOwners.Count -eq 25 -and $record.metadataOwners.Count -eq 5 -and $record.evidenceOwners.Count -eq 3) 'exact counts'
Check (Test-ThinSealSet $record.sourceOwners $record.files.path) 'manifest set'
Check (!(Test-ThinSealSet @($record.sourceOwners[0]) $record.sourceOwners)) 'missing source rejected'
Check (!(Test-ThinSealSet @($record.sourceOwners+'main.dart') $record.sourceOwners)) 'extra source rejected'
Check (!$record.productionAcceptance -and !$record.formalTicketClose) 'no live acceptance'
Check ($record.remoteRef -ceq 'refs/heads/work/codex-backend/thin-b07-b04-20261027') 'only named branch'
foreach($file in $record.files) {Check ((Get-ThinSealDigest (Join-Path $root $file.path)) -ceq $file.normalizedSha256.ToUpperInvariant()) "exact source $($file.path)"}
$original=@(& git -C $root show '379fd7e07a042bd000f2f6260ace249bc6bf17f8:scripts/check-codex-subagent-coordination-policy.ps1')
if($LASTEXITCODE -ne 0) {throw 'Missing original checker'}
# Literal comparison permits only the single dispatch; all historical bodies stay byte-equivalent after line-ending normalization.
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1')).Replace("`r`n","`n")
$lines=@($current -split "`n"|Where-Object {$_ -notmatch '^  if\(Test-Path -LiteralPath .*THIN-B07-B04-SOURCE-SEAL-20261028.json'})
Check (($lines -join "`n").TrimEnd() -ceq ($original -join "`n").TrimEnd()) 'historical bodies preserved'
Write-Output "THIN-B07/B04 source-seal checks passed: $cases."
