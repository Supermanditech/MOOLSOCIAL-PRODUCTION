# Exact founder-approved source checkpoint. No runtime or release authority.
function Get-ThinSealDigest([string]$Path) {
  $data=[Text.Encoding]::UTF8.GetBytes([IO.File]::ReadAllText($Path).Replace("`r`n","`n"))
  [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data))
}
function Test-ThinSealSet([object[]]$Actual,[object[]]$Expected) {
  (@($Actual|Sort-Object)-join '|') -ceq (@($Expected|Sort-Object)-join '|')
}
function Get-ThinSealStage([int]$Count) {
  switch($Count) {0 {'metadata'};1 {'source'};2 {'evidence'};3 {'sealed'};default {throw 'THIN-B03 seal requires exactly the admitted checkpoint sequence.'}}
}
function Invoke-ThinB03SourceSeal {
  $start='bec1dcead5400f70e88158efd223c661945b6da9'
  $recordPath='docs/quality/THIN-B03-SOURCE-SEAL-20261027.json'
  Assert-Coordination ((Get-ThinSealDigest (Join-Path $root $recordPath)) -ceq '357C4294364C0A0821B384FF5C75FFFBF18C59B322A03DF4AAF6DA8A9B887A8A') 'AI source-seal manifest changed.'
  $seal=Get-Content -Raw (Join-Path $root $recordPath)|ConvertFrom-Json
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-ThinB03Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'AI source-seal identity differs.'
  Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit') -and $seal.startHead -ceq $start -and $seal.approval -ceq 'Founder approved THIN-B03 tested source checkpoint and branch push' -and !$seal.productionAcceptance -and !$seal.formalTicketClose) 'AI source-seal authority differs.'
  $meta=@($seal.metadataOwners);$source=@($seal.sourceOwners);$evidence=@($seal.evidenceOwners)
  Assert-Coordination ($meta.Count -eq 5 -and $source.Count -eq 22 -and $evidence.Count -eq 3 -and (Test-ThinSealSet $source @($seal.files.path))) 'AI source-seal owners differ.'
  $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $prior=(@(Get-OctoberCompatibilityGitLines @('show',"${start}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  foreach($claim in $prior.activeClaims) {if($claim.task -ceq '/root/codex_backend_thin_b03') {foreach($owner in @($meta+$evidence)) {if($owner -cnotin $claim.owners) {$claim.owners=@($claim.owners)+@($owner)}}}}
  Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($prior|ConvertTo-Json -Depth 100 -Compress)) 'AI unrelated owner policy changed.'
  foreach($file in $seal.files) {Assert-Coordination ((Get-ThinSealDigest (Join-Path $root $file.path)) -ceq $file.normalizedSha256.ToUpperInvariant()) "AI tested source changed: $($file.path)"}
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'AI registry pin changed.'
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$start,$head)|Out-Null
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$start..$head"));$stage=Get-ThinSealStage $commits.Count
  Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$start..$head")).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'AI history/index override.'
  $sets=@($meta,$source,$evidence);$parent=$start
  for($i=0;$i -lt $commits.Count;$i++) {
    $commit=$commits[$i]
    Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$commit))[0]) -ceq $parent -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$commit))[0]) -ceq $seal.commitSubjects[$i]) 'AI seal parent/subject differs.'
    Assert-Coordination (Test-ThinSealSet @(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$commit)) $sets[$i]) 'AI seal committed owner set differs.'
    $parent=$commit
  }
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$start))+@(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-ThinB03Owners $changed @($meta+$source+$evidence)
  if($commits.Count -ge 1) {foreach($owner in $meta) {Get-OctoberCompatibilityGitLines @('diff','--exit-code',$commits[0],'--',$owner)|Out-Null}}
  if($commits.Count -ge 2) {foreach($owner in $source) {Get-OctoberCompatibilityGitLines @('diff','--exit-code',$commits[1],'--',$owner)|Out-Null}}
  if($ProductionPhase -ceq 'pre_commit') {
    Assert-Coordination ($commits.Count -lt 3 -and (Test-ThinSealSet @(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')) $sets[$commits.Count])) 'AI seal staged owner set differs.'
  }
  if($commits.Count -ge 3) {
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'AI seal is not clean.'
    $result=Get-Content -Raw (Join-Path $root $evidence[0])|ConvertFrom-Json
    Assert-Coordination ($result.sourceCommit -ceq $commits[1] -and !$result.productionAcceptance -and !$result.formalTicketClose) 'AI evidence source/limits differ.'
  }
  Assert-ProductionSecretSafe -BaseCommit $start -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $start -HeadCommit $head -IndexOnly
  Write-Output "THIN-B03 exact source-seal admission passed: stage=$stage; no runtime edits, release or formal acceptance authority."
}
