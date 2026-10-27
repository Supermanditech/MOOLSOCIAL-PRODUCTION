[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'thin-b03-admission.ps1')
. (Join-Path $PSScriptRoot 'thin-b03-source-seal.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message) {if(!$Condition) {throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name) {if(!$Condition) {throw "AI seal test: $Name"};$script:cases++}
$root=Split-Path -Parent $PSScriptRoot
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b03-20261027';Branch='work/codex-backend/thin-b03-20261027';Lane='codex_backend';Role='primary';Task='/root/codex_backend_thin_b03';WorkId='thin-b03-20261027';Ticket='THIN-B03';Phase='implementation'}
Check (Test-ThinB03Identity $facts) 'exact implementation'
foreach($key in $facts.Keys) {$bad=$facts.Clone();$bad[$key]='foreign';Check (!(Test-ThinB03Identity $bad)) "foreign $key"}
foreach($phase in @('build','deployment','ticket_close','ticket_acceptance','handoff')) {$bad=$facts.Clone();$bad.Phase=$phase;Check (!(Test-ThinB03Identity $bad)) "blocked $phase"}
Check ((Get-ThinSealStage 0) -ceq 'metadata') 'metadata'
Check ((Get-ThinSealStage 1) -ceq 'source') 'source'
Check ((Get-ThinSealStage 2) -ceq 'evidence') 'evidence'
Check ((Get-ThinSealStage 3) -ceq 'sealed') 'sealed'
foreach($count in @(-1,4,5)) {$rejected=$false;try {Get-ThinSealStage $count|Out-Null}catch {$rejected=$true};Check $rejected "reject $count"}
$record=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B03-SOURCE-SEAL-20261027.json')|ConvertFrom-Json
Check ((Get-ThinSealDigest (Join-Path $root 'docs/quality/THIN-B03-SOURCE-SEAL-20261027.json')) -ceq '357C4294364C0A0821B384FF5C75FFFBF18C59B322A03DF4AAF6DA8A9B887A8A') 'bound record'
Check ($record.sourceOwners.Count -eq 22 -and $record.metadataOwners.Count -eq 5 -and $record.evidenceOwners.Count -eq 3) 'exact counts'
Check (Test-ThinSealSet $record.sourceOwners $record.files.path) 'manifest set'
Check (!(Test-ThinSealSet @($record.sourceOwners[0]) $record.sourceOwners)) 'missing source rejected'
Check (!(Test-ThinSealSet @($record.sourceOwners+'main.dart') $record.sourceOwners)) 'extra source rejected'
Check (!$record.productionAcceptance -and !$record.formalTicketClose) 'no live acceptance'
Check ($record.remoteRef -ceq 'refs/heads/work/codex-backend/thin-b03-20261027') 'only named branch'
foreach($file in $record.files) {Check ((Get-ThinSealDigest (Join-Path $root $file.path)) -ceq $file.normalizedSha256.ToUpperInvariant()) "exact source $($file.path)"}
$original=@(& git -C $root show 'bec1dcead5400f70e88158efd223c661945b6da9:scripts/check-codex-subagent-coordination-policy.ps1')
if($LASTEXITCODE -ne 0) {throw 'Missing original checker'}
# Literal comparison permits only the single dispatch; all historical bodies stay byte-equivalent after line-ending normalization.
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1')).Replace("`r`n","`n")
$lines=@($current -split "`n"|Where-Object {$_ -notmatch '^  if\(Test-Path -LiteralPath .*THIN-B03-SOURCE-SEAL-20261027.json'})
Check (($lines -join "`n").TrimEnd() -ceq ($original -join "`n").TrimEnd()) 'historical bodies preserved'
Write-Output "THIN-B03 source-seal checks passed: $cases."
