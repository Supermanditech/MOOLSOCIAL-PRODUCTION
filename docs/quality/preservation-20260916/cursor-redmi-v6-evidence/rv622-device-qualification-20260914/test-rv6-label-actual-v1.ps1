$ErrorActionPreference = 'Stop'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$AgentRole = 'subagent'
$AgentTask = '/root/cursor_redmi_v6_audit_20260913'
$ProductionLane = 'cursor_ui'
$ProductionWorkId = 'redmi-v6-audit-20260913'
$ProductionTicketId = 'UAW-CURSOR-REDMI-V6-AUDIT-20260913'
$branch = 'work/cursor-ui/redmi-v6-audit-20260913'
$checker = Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($checker,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($name in @('Test-RedmiV6HistoricalEvidenceFacts','Test-RedmiV6HistoricalEvidenceCommit','Test-R66HistoricalCommitSubject')) {
  $nodes = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name },$true))
  if ($nodes.Count -ne 1) { throw "Function identity differs: $name" }
  . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$c = '448d4a2c7c10ee195e711e49aa4cc69a593ff37b'
$parents = @(& git -C $root show -s --format=%P $c); if ($LASTEXITCODE -ne 0 -or $parents.Count -ne 1) { throw 'Parent read failed' }
$subject = [string](& git -C $root show -s --format=%s $c); if ($LASTEXITCODE -ne 0) { throw 'Subject read failed' }
$owners = @(& git -C $root diff-tree --no-commit-id --name-only -r $c); if ($LASTEXITCODE -ne 0) { throw 'Owner read failed' }
$trees = @(& git -C $root rev-parse "${c}:apps" "$($parents[0]):apps"); if ($LASTEXITCODE -ne 0) { throw 'Tree read failed' }
$blobs=@{}; foreach($owner in $owners) { $blobs[$owner]=[string](& git -C $root rev-parse "${c}:$owner"); if($LASTEXITCODE -ne 0){throw 'Blob read failed'} }
$facts=@{Root=$root;Role=$AgentRole;Task=$AgentTask;Lane=$ProductionLane;WorkId=$ProductionWorkId;TicketId=$ProductionTicketId;Branch=$branch;Commit=$c;Parent=[string]$parents[0];Subject=$subject;AppsTree=[string]$trees[0];ParentAppsTree=[string]$trees[1];Blobs=$blobs}
function Copy-Facts { $copy=$facts.Clone();$copy.Blobs=$facts.Blobs.Clone();return $copy }
$passed=New-Object 'Collections.Generic.List[string]'
function Reject([string]$label,[hashtable]$candidate) { if(Test-RedmiV6HistoricalEvidenceFacts $candidate){throw "Accepted invalid: $label"};$passed.Add($label) }
if(-not (Test-RedmiV6HistoricalEvidenceFacts $facts)){throw 'Actual committed facts rejected'}
foreach($key in @('Root','Role','Task','Lane','WorkId','TicketId','Branch','Commit','Parent','Subject','AppsTree','ParentAppsTree')) { $bad=Copy-Facts;$bad[$key]+='-changed';Reject "changed-$key" $bad }
foreach($owner in $owners){$bad=Copy-Facts;$bad.Blobs[$owner]='0'*40;Reject "changed-blob-$owner" $bad}
$bad=Copy-Facts;$bad.Blobs.Remove($owners[0]);Reject 'missing-owner' $bad
$bad=Copy-Facts;$bad.Blobs['apps/mobile/lib/unrelated.dart']='0'*40;Reject 'extra-owner' $bad
$bad=Copy-Facts;$key=[string]$owners[0];$value=$bad.Blobs[$key];$bad.Blobs.Remove($key);$bad.Blobs[$key.ToUpperInvariant()]=$value;Reject 'owner-case-change' $bad
$bad=Copy-Facts;$bad.Remove('Root');Reject 'missing-identity' $bad
$bad=Copy-Facts;$bad['Extra']='unexpected';Reject 'extra-fact' $bad
Reject 'null-facts' $null
if(-not (Test-RedmiV6HistoricalEvidenceCommit $c $subject)){throw 'Actual Git wrapper rejected binding'}
if(-not (Test-R66HistoricalCommitSubject $c $subject)){throw 'Actual history-hook rejected binding'}
if(Test-R66HistoricalCommitSubject ('0'*40) $subject){throw 'Future commit accepted'}
$passed.Add('future-commit-rejected')
if(Test-RedmiV6HistoricalEvidenceCommit $c ($subject+' changed')){throw 'Wrong subject accepted by wrapper'}
$passed.Add('wrapper-subject-rejected')
$AgentTask='/root/other';if(Test-RedmiV6HistoricalEvidenceCommit $c $subject){throw 'Wrong task accepted by wrapper'};$AgentTask='/root/cursor_redmi_v6_audit_20260913'
$passed.Add('wrapper-other-task-rejected')
function git { $global:LASTEXITCODE=1 }
if(Test-RedmiV6HistoricalEvidenceCommit $c $subject){throw 'Git failure accepted'}
Remove-Item Function:git
$passed.Add('wrapper-git-failure-rejected')
$result=[ordered]@{actualPredicatePositive=$true;actualGitWrapperPositive=$true;actualHistoryHookPositive=$true;negativeCases=@($passed);checkerSha256=(Get-FileHash -LiteralPath $checker -Algorithm SHA256).Hash;historyRewritten=$false;apkChanged=$false}
$path=Join-Path $PSScriptRoot 'rv6-label-actual-tests-v1.json'
if(Test-Path -LiteralPath $path){throw 'Immutable receipt exists'}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
Write-Output "Actual label tests passed:3 positives; $($passed.Count) negatives; receipt $path"
