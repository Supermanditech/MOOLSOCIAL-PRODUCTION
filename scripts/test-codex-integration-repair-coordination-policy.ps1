[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireQualifiedGraph,
  [switch]$RequireOctoberSourceAdmission,
  [switch]$RequireOctoberBootstrapProbes,
  [switch]$RequireCompatibilityStageProbes,
  [switch]$RequireCompatibilityLiveAdmissionProbes,
  [ValidateSet('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')]
  [string]$CaptureCompatibilityReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$policyPath = Join-Path $root 'config\codex-subagent-coordination-policy.json'
$checkerPath = Join-Path $root 'scripts\check-codex-subagent-coordination-policy.ps1'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$checker = Get-Content -Raw -LiteralPath $checkerPath

function Assert-RepairContract([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Integration repair fixture rejected: $Message" }
}

if ($RequireCompatibilityStageProbes -or $RequireCompatibilityLiveAdmissionProbes -or $CaptureCompatibilityReport) {
  $tokens=$null; $errors=$null
  $ast=[System.Management.Automation.Language.Parser]::ParseFile(
    $checkerPath,[ref]$tokens,[ref]$errors)
  Assert-RepairContract ($errors.Count -eq 0) 'checker has parse errors.'
  foreach ($name in @('Get-OctoberCompatibilityBinding',
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityAmendmentOwners','Get-OctoberCompatibilityLayoutOwners','Test-OctoberCompatibilityBindingInventory',
      'Test-OctoberCompatibilityStageFacts','Test-OctoberCompatibilityIntegrationIdentity','Assert-Coordination',
      'Get-OctoberCompatibilityGitLines','Get-OctoberCompatibilityHistoryStage',
      'Test-OctoberCompatibilityQualification','Read-OctoberCompatibilityReportEvents',
      'Get-OctoberCompatibilityReportPlan','Test-OctoberCompatibilityCapture')) {
    $nodes=@($ast.FindAll({param($node)
      $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq $name
    },$true))
    Assert-RepairContract ($nodes.Count -eq 1) "missing/duplicate operative predicate $name."
    . ([scriptblock]::Create($nodes[0].Extent.Text))
  }
  $binding=Get-OctoberCompatibilityBinding
  if($CaptureCompatibilityReport) {
    Assert-RepairContract (-not $RequireCompatibilityStageProbes -and -not $RequireCompatibilityLiveAdmissionProbes) 'capture cannot be combined with probe modes.'
    $branch=@(& git -C $root branch --show-current)
    Assert-RepairContract ($LASTEXITCODE -eq 0 -and $branch.Count -eq 1 -and
      $branch[0] -ceq $binding.branch -and $root.Replace('\','/').TrimEnd('/') -ceq $binding.worktreePath) 'capture requires exact successor worktree/branch.'
    $source=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))
    Assert-RepairContract ($source.Count -eq 1) 'capture source unavailable.'
    $history=Get-OctoberCompatibilityHistoryStage $source[0]
    Assert-RepairContract ($history.Stage -eq 4) 'capture requires committed L, not E/G/C/A or documentary Q.'
    $before=@(Get-OctoberCompatibilityGitLines @('status','--porcelain=v1','-z'))
    Assert-RepairContract ($before.Count -eq 0) 'capture requires clean L source.'
    $admission=@{
      AgentRole='primary'; AgentTask='/root'; ClaimedOwners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
      ExpectedRegistryEntryCount=[int]$policy.registryBinding.entryCount
      ExpectedRegistrySha256=[string]$policy.registryBinding.sha256
      ProductionLane='integration_repair'; ProductionPhase='implementation'
      ProductionWorkId=$binding.workId; ProductionTicketId=$binding.ticketId; RepositoryRoot=$root
    }
    & $checkerPath @admission
    & (Join-Path $PSScriptRoot 'check-cross-agent-incremental-ticket-gate.ps1') `
      -Phase implementation -Lane integration_repair -TicketId $binding.ticketId `
      -UiScope store.buy_publication_compatibility -PackageId com.moolsocial.app.runtime `
      -CandidateVersionName 1.0.0-r66.42 -CandidateVersionCode 2026100801 -RepositoryRoot $root
    & (Join-Path $PSScriptRoot 'check-codex-development-regression-memory.ps1') -Phase general `
      -RepositoryRoot $root -EvidenceArchiveRoot 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904'
    $plan=Get-OctoberCompatibilityReportPlan $CaptureCompatibilityReport
    $flutterArguments=@($plan.Arguments)
    $tree=@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($source[0])^{tree}"))
    $producer=@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($source[0]):scripts/test-codex-integration-repair-coordination-policy.ps1"))
    Assert-RepairContract ($tree.Count -eq 1 -and $producer.Count -eq 1) 'capture tree/producer identity unavailable.'
    $relative='apps/mobile/build/compat-'+$CaptureCompatibilityReport+'-'+[Guid]::NewGuid().ToString('N')+'.jsonl'
    $log=Join-Path $root $relative; $stderr=$log+'.stderr.txt'; $capturePath=$log+'.capture.json'
    foreach($path in @($log,$stderr,$capturePath)) {
      Assert-RepairContract (-not (Test-Path -LiteralPath $path)) 'capture refuses existing evidence paths.'
    }
    $flutter='C:/Users/jisal/develop/flutter/bin/flutter.bat'
    Assert-RepairContract (Test-Path -LiteralPath $flutter -PathType Leaf) 'configured Flutter executable unavailable.'
    foreach($suite in $plan.Suites) {
      Assert-RepairContract (Test-Path -LiteralPath (Join-Path $root ('apps/mobile/test/'+$suite)) -PathType Leaf) 'capture suite unavailable.'
    }
    $started=[DateTimeOffset]::UtcNow.ToString('o')
    [IO.File]::WriteAllText($stderr,'',[Text.UTF8Encoding]::new($false))
    $writer=[IO.StreamWriter]::new($log,$false,[Text.UTF8Encoding]::new($false))
    $script:compatNativeExit=-1; $guardCompleted=$false; $failure=$null
    $marker=@{type='moolsocialSource'; sourceCommit=$source[0]; sourceTree=$tree[0]
      registrySha256=[string]$policy.registryBinding.sha256; reportId=$CaptureCompatibilityReport
      runtimeDefines=@($plan.RuntimeDefines)}
    $writer.WriteLine((ConvertTo-Json -InputObject $marker -Compress -Depth 10)); $writer.Flush()
    . (Join-Path $PSScriptRoot 'invoke-flutter-with-clean-support.ps1')
    try {
      $guardExit=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $root -Invocation {
        Push-Location (Join-Path $root 'apps/mobile')
        try {
          & $flutter @flutterArguments 2> $stderr | ForEach-Object {$writer.WriteLine([string]$_); $writer.Flush()}
          $script:compatNativeExit=[int]$LASTEXITCODE
          if($script:compatNativeExit -ne 0){throw "Flutter report exited $script:compatNativeExit; original output retained."}
        } finally { Pop-Location }
      }
      $guardCompleted=$true
      Assert-RepairContract ([int]$guardExit -eq $script:compatNativeExit) 'guard/native exit mismatch.'
    } catch { $failure=$_ } finally { $writer.Dispose() }
    $afterHead=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))
    $afterTree=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD^{tree}'))
    $afterDirt=@(Get-OctoberCompatibilityGitLines @('status','--porcelain=v1','-z'))
    $capture=@{
      schemaVersion=1; producer='test-codex-integration-repair-coordination-policy.ps1'
      producerGitBlob=$producer[0]; reportId=$CaptureCompatibilityReport
      sourceCommit=$source[0]; sourceTree=$tree[0]; registrySha256=[string]$policy.registryBinding.sha256
      sourceCommitAfter=$afterHead[0]; sourceTreeAfter=$afterTree[0]
      executable=$flutter; workingDirectory=$binding.worktreePath+'/apps/mobile'
      cleanBefore=$true; cleanAfter=($afterDirt.Count -eq 0); guardCompleted=$guardCompleted
      exitCode=$script:compatNativeExit; arguments=@($plan.Arguments); runtimeDefines=@($plan.RuntimeDefines)
      startedAtUtc=$started; finishedAtUtc=[DateTimeOffset]::UtcNow.ToString('o')
      stdoutSha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash
      stderrPath=$relative+'.stderr.txt'; stderrSha256=(Get-FileHash -LiteralPath $stderr -Algorithm SHA256).Hash
    }
    [IO.File]::WriteAllText($capturePath,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
    $record=@{id=$CaptureCompatibilityReport; path=$relative; sha256=$capture.stdoutSha256
      capturePath=$relative+'.capture.json'; captureSha256=(Get-FileHash -LiteralPath $capturePath -Algorithm SHA256).Hash
      runtimeDefines=@($plan.RuntimeDefines)}
    Write-Output (ConvertTo-Json -InputObject $record -Compress -Depth 10)
    if($null -ne $failure){throw $failure}
    Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $capture -ReportId $CaptureCompatibilityReport `
      -Source $source[0] -Tree $tree[0] -RegistrySha ([string]$policy.registryBinding.sha256) `
      -ProducerBlob $producer[0] -LogSha $capture.stdoutSha256) 'host capture failed; retained files are not passing evidence.'
    return
  }
  $facts=@{
    Role=$binding.role; Task=$binding.task; Lane=$binding.lane
    WorkId=$binding.workId; TicketId=$binding.ticketId
    Root=$binding.worktreePath; Branch=$binding.branch; Base=$binding.baselineHead
    BaseGraphValid=$true; SourceRemotesExact=$true; NativeUnchanged=$true
    GenerationExact=$true; BindingsExact=$true; HistoryValid=$true
    Stage=0; Phase='coordination_bootstrap'; Owners=@($binding.bootstrapOwners)
    Clean=$true; HostQualificationPassed=$true
  }
  $cases=0
  Assert-RepairContract (Test-OctoberCompatibilityStageFacts $facts) 'exact pre-G bootstrap rejected.'
  $cases++
  foreach ($key in @('Role','Task','Lane','WorkId','TicketId','Root','Branch','Base',
      'BaseGraphValid','SourceRemotesExact','NativeUnchanged','GenerationExact',
      'BindingsExact','HistoryValid','Stage','Phase','Owners')) {
    $changed=$facts.Clone(); $changed[$key]='altered'
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) "changed$key accepted."
    $missing=$facts.Clone(); $missing.Remove($key)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $missing)) "missing$key accepted."
    $cases+=2
  }
  foreach ($key in @('BaseGraphValid','SourceRemotesExact','NativeUnchanged',
      'GenerationExact','BindingsExact','HistoryValid')) {
    foreach ($value in @($false,'true')) {
      $changed=$facts.Clone(); $changed[$key]=$value
      Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) "invalid boolean$key accepted."
      $cases++
    }
  }
  $ownerProbes=@(
    @{ Owners=@($binding.bootstrapOwners)+@('apps/mobile/lib/features/work/work_publication.dart') },
    @{ Owners=@($binding.bootstrapOwners[0..6]) },
    @{ Owners=@($binding.bootstrapOwners[0..6])+@($binding.bootstrapOwners[0]) }
  )
  Assert-RepairContract ($ownerProbes.Count -eq 3) 'owner probe construction changed.'
  foreach ($probe in $ownerProbes) {
    $changed=$facts.Clone(); $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'bad bootstrap owner inventory accepted.'
    $cases++
  }
  foreach ($pair in @(@('pre_commit',0),@('pre_commit',1),@('pre_commit',2),@('pre_commit',3),@('pre_commit',4),
      @('task_start',1),@('implementation',1),@('implementation',2),@('implementation',3),@('implementation',4),@('handoff',5),@('integration_admission_authorize',5))) {
    $stageFacts=$facts.Clone(); $stageFacts.Phase=$pair[0]; $stageFacts.Stage=[int]$pair[1]
    $stageFacts.Owners=if($stageFacts.Stage -eq 0){@($binding.bootstrapOwners)}
      elseif($stageFacts.Stage -eq 1){@(Get-OctoberCompatibilityApplicationOwners)}
      elseif($stageFacts.Stage -eq 2){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 3){@(Get-OctoberCompatibilityLayoutOwners)}
      else{@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
    Assert-RepairContract (Test-OctoberCompatibilityStageFacts $stageFacts) "exact stage$($pair -join '/') rejected."
    $cases++
  }
  foreach ($stage in @(0,1,2,3,4)) {
    $changed=$facts.Clone(); $changed.Phase='handoff'; $changed.Stage=[int]$stage
    $changed.Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'unqualified E/G/C/A/L accepted for handoff.'
    $cases++
  }
  foreach($probe in @(
      @{Stage=1; Owners=@(Get-OctoberCompatibilityLayoutOwners)},
      @{Stage=2; Owners=@(Get-OctoberCompatibilityApplicationOwners)},
      @{Stage=3; Owners=@(Get-OctoberCompatibilityAmendmentOwners)},
      @{Stage=4; Owners=@(Get-OctoberCompatibilityLayoutOwners)})) {
    $changed=$facts.Clone(); $changed.Phase='pre_commit'; $changed.Stage=[int]$probe.Stage
    $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'owners from another successor stage accepted.'
    $cases++
  }
  $handoff=$facts.Clone(); $handoff.Phase='handoff'; $handoff.Stage=5
  $handoff.Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
  foreach($key in @('Clean','HostQualificationPassed')) {
    foreach($value in @($false,'true')) {
      $changed=$handoff.Clone(); $changed[$key]=$value
      Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) "unverified$key accepted."
      $cases++
    }
  }
  foreach($probe in @(
      @{Stage=2; Owners=@(Get-OctoberCompatibilityAmendmentOwners)+@('apps/mobile/test/work_public_handoff_test.dart')},
      @{Stage=2; Owners=@(Get-OctoberCompatibilityLayoutOwners)},
      @{Stage=3; Owners=@(Get-OctoberCompatibilityLayoutOwners | Where-Object {$_ -cne 'apps/mobile/test/work_public_handoff_test.dart'})},
      @{Stage=3; Owners=@(Get-OctoberCompatibilityLayoutOwners)+@('apps/mobile/lib/features/work/work_publication.dart')},
      @{Stage=4; Owners=@(Get-OctoberCompatibilityAmendmentOwners)})) {
    $changed=$facts.Clone(); $changed.Phase='pre_commit'; $changed.Stage=[int]$probe.Stage
    $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'widened or incomplete amendment/layout/Q claim accepted.'
    $cases++
  }
  Assert-RepairContract ($cases -eq 80) 'stage probe inventory changed.'
  Write-Output "Compatibility stage predicates: $cases cases passed; live graph/admission and APK qualification remain separate."
  $finalFacts=@{
    Role='primary'; Task='/root'; Lane='integration'
    Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-store-buy-combined-baseline-20261008'
    Branch='integration/moolsocial/store-buy-combined-baseline-20261008'
    WorkId='store-buy-combined-baseline-20261008'
    TicketId='UAW-INTEGRATION-STORE-BUY-COMBINED-BASELINE-20261008'
    Phase='integration_verify'
  }
  $finalCases=0
  foreach($phase in @('integration_verify','integration_close','candidate_preflight')) {
    $probe=$finalFacts.Clone(); $probe.Phase=$phase
    Assert-RepairContract (Test-OctoberCompatibilityIntegrationIdentity $probe) 'exact final integration identity rejected.'
    $finalCases++
  }
  foreach($key in @('Role','Task','Lane','Root','Branch','WorkId','TicketId')) {
    $probe=$finalFacts.Clone(); $probe[$key]='altered'
    Assert-RepairContract (-not (Test-OctoberCompatibilityIntegrationIdentity $probe)) "changed final identity$key accepted."
    $probe=$finalFacts.Clone(); $probe.Remove($key)
    Assert-RepairContract (-not (Test-OctoberCompatibilityIntegrationIdentity $probe)) "missing final identity$key accepted."
    $finalCases+=2
  }
  foreach($phase in @('integration_start','implementation','pre_commit','handoff')) {
    $probe=$finalFacts.Clone(); $probe.Phase=$phase
    Assert-RepairContract (-not (Test-OctoberCompatibilityIntegrationIdentity $probe)) 'unsupported final integration phase accepted.'
    $finalCases++
  }
  Assert-RepairContract ($finalCases -eq 21) 'final integration identity probe inventory changed.'
  Write-Output "Compatibility final integration identity: $finalCases cases passed; no integration worktree or APK created."
  # Synthetic protocol fixtures only: never runtime, host journey or APK evidence.
  $fixtureRoot='C:/labelled-automated-report-fixture'
  $fixturePath=$fixtureRoot+'/apps/mobile/test/fixture_test.dart'
  $validEvents=@(
    @{type='start'},
    @{type='suite'; suite=@{id=0; path=$fixturePath}},
    @{type='allSuites'; count=1},
    @{type='testStart'; test=@{id=1; suiteID=0; name='Retained bill'}},
    @{type='testDone'; testID=1; result='success'; skipped=$false},
    @{type='done'; success=$true}
  )
  $result=Read-OctoberCompatibilityReportEvents -Events $validEvents `
    -RequiredSuites @('fixture_test.dart') -SourceRoot $fixtureRoot
  Assert-RepairContract ($null -ne $result -and $result.Completed -eq 1 -and $result.Successes.Count -eq 1) 'complete labelled protocol fixture rejected.'
  $protocolCases=1
  $caseVariant=@($validEvents[0..4])+@(
    @{type='testStart'; test=@{id=2; suiteID=0; name='retained bill'}},
    @{type='testDone'; testID=2; result='success'; skipped=$false},$validEvents[5])
  $result=Read-OctoberCompatibilityReportEvents -Events $caseVariant `
    -RequiredSuites @('fixture_test.dart') -SourceRoot $fixtureRoot
  Assert-RepairContract ($null -ne $result -and $result.Successes.Count -eq 2) 'ordinal test identity collapsed distinct names.'
  $protocolCases++
  $badSkip=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($badSkip.Count -eq $validEvents.Count) 'decoded skip fixture event inventory changed.'
  $badSkip[4].skipped='false'
  $badResult=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($badResult.Count -eq $validEvents.Count) 'decoded result fixture event inventory changed.'
  $badResult[4].result='failure'
  $badDone=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($badDone.Count -eq $validEvents.Count) 'decoded completion fixture event inventory changed.'
  $badDone[5].success='true'
  $failedDone=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($failedDone.Count -eq $validEvents.Count) 'decoded failure fixture event inventory changed.'
  $failedDone[5].success=$false
  $outside=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($outside.Count -eq $validEvents.Count) 'decoded source-path fixture event inventory changed.'
  $outside[1].suite.path='C:/another-source/apps/mobile/test/fixture_test.dart'
  $loadingOnly=(ConvertTo-Json -InputObject $validEvents -Depth 20 -Compress)|ConvertFrom-Json
  Assert-RepairContract ($loadingOnly.Count -eq $validEvents.Count) 'decoded loading fixture event inventory changed.'
  $loadingOnly[3].test.name='loading '+$fixturePath
  $duplicateBehavior=@($validEvents[0..4])+@(
    @{type='testStart'; test=@{id=2; suiteID=0; name='Retained bill'}},
    @{type='testDone'; testID=2; result='success'; skipped=$false},$validEvents[5])
  $protocolRejects=@(
    @{Events=$badSkip},@{Events=$badResult},@{Events=$badDone},@{Events=$failedDone},
    @{Events=$outside},@{Events=$loadingOnly},@{Events=$duplicateBehavior},
    @{Events=@($validEvents[0..4])},
    @{Events=@($validEvents)+@(@{type='print'; message='after completion'})},
    @{Events=@($validEvents[0..4])+@($validEvents[4],$validEvents[5])},
    @{Events=@($validEvents[0..4])+@($validEvents[1],$validEvents[5])},
    @{Events=@($validEvents[0..4])+@(@{type='error'; message='failed'},$validEvents[5])},
    @{Events=@($validEvents[0],$validEvents[1],$validEvents[3],$validEvents[4],$validEvents[5])},
    @{Events=@($validEvents[0],$validEvents[2],$validEvents[3],$validEvents[4],$validEvents[5])},
    @{Events=@($validEvents[0..2])+@($validEvents[5])}
  )
  foreach($probe in $protocolRejects) {
    $result=Read-OctoberCompatibilityReportEvents -Events @($probe.Events) `
      -RequiredSuites @('fixture_test.dart') -SourceRoot $fixtureRoot
    Assert-RepairContract ($null -eq $result) 'incomplete/failed/ambiguous protocol fixture accepted.'
    $protocolCases++
  }
  Assert-RepairContract ($protocolCases -eq 17) 'protocol fixture inventory changed.'
  Write-Output "Compatibility report protocol: $protocolCases labelled automated fixtures passed; no real host/source/APK acceptance."
  $captureFixture=@{
    schemaVersion=1; producer='test-codex-integration-repair-coordination-policy.ps1'
    producerGitBlob=('a'*40); reportId='publication_contracts'
    sourceCommit=('b'*40); sourceTree=('c'*40); registrySha256=('D'*64)
    sourceCommitAfter=('b'*40); sourceTreeAfter=('c'*40); stdoutSha256=('E'*64)
    executable='C:/Users/jisal/develop/flutter/bin/flutter.bat'
    workingDirectory=$binding.worktreePath+'/apps/mobile'
    exitCode=0; guardCompleted=$true; cleanBefore=$true; cleanAfter=$true
    arguments=@((Get-OctoberCompatibilityReportPlan 'publication_contracts').Arguments); runtimeDefines=@()
    startedAtUtc='2026-10-08T01:00:00+00:00'; finishedAtUtc='2026-10-08T01:01:00+00:00'
  }
  $captureFacts=@{ReportId='publication_contracts'; Source=('b'*40); Tree=('c'*40)
    RegistrySha=('D'*64); ProducerBlob=('a'*40); LogSha=('E'*64)}
  Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $captureFixture @captureFacts) 'complete labelled capture fixture rejected.'
  $captureCases=1
  foreach($key in @('producer','producerGitBlob','reportId','sourceCommit','sourceTree','registrySha256',
      'sourceCommitAfter','sourceTreeAfter','stdoutSha256','executable','workingDirectory','arguments','runtimeDefines')) {
    $probe=$captureFixture.Clone(); $probe[$key]='altered'
    Assert-RepairContract (-not (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) "changed capture$key accepted."
    $captureCases++
  }
  foreach($key in @('guardCompleted','cleanBefore','cleanAfter')) {
    foreach($value in @($false,'true')) {
      $probe=$captureFixture.Clone(); $probe[$key]=$value
      Assert-RepairContract (-not (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) "invalid capture$key accepted."
      $captureCases++
    }
  }
  foreach($value in @(1,'0')) {
    $probe=$captureFixture.Clone(); $probe.exitCode=$value
    Assert-RepairContract (-not (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) 'failed/coerced process exit accepted.'
    $captureCases++
  }
  $probe=$captureFixture.Clone(); $probe.finishedAtUtc='2026-10-08T00:00:00+00:00'
  Assert-RepairContract (-not (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) 'reversed capture timestamps accepted.'
  $captureCases++
  foreach($value in @('2026-10-08T06:30:00+05:30','08/10/2026 01:00:00',
      [DateTime]::SpecifyKind([DateTime]::new(2026,10,8,1,0,0),[DateTimeKind]::Utc))) {
    $probe=$captureFixture.Clone(); $probe.startedAtUtc=$value
    Assert-RepairContract (-not (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) 'non-UTC, malformed or coerced timestamp accepted.'
    $captureCases++
  }
  $probe=$captureFixture.Clone(); $probe.startedAtUtc='2026-10-08T01:00:00.0000000Z'
  $probe.finishedAtUtc='2026-10-08T01:01:00.0000000Z'
  Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts) 'producer ISO round-trip UTC format rejected.'
  $captureCases++
  Assert-RepairContract ($captureCases -eq 27) 'capture fixture inventory changed.'
  Write-Output "Compatibility capture provenance: $captureCases labelled automated fixtures passed; producer execution remains separately gated."
  $capturePrematureRejected=$false
  try { $null=& $PSCommandPath -RepositoryRoot $root -CaptureCompatibilityReport publication_contracts }
  catch {
    Assert-RepairContract ($_.Exception.Message.IndexOf('capture requires committed L, not E/G/C/A or documentary Q.',[StringComparison]::Ordinal) -ge 0) 'premature capture failed for an unrelated reason.'
    $capturePrematureRejected=$true
  }
  Assert-RepairContract $capturePrematureRejected 'premature host capture admitted before L.'
  Write-Output 'Compatibility capture producer: unqualified source rejected before Flutter or evidence-file creation.'
  # Complete aggregate fixture in an isolated ignored build directory. Fake Git
  # reads are scoped to this scriptblock; no real source/ledger/device is changed.
  & {
    $fixtureRoot=Join-Path $root ('apps/mobile/build/labelled-proof-fixture-'+[Guid]::NewGuid().ToString('N'))
    $root=[IO.Path]::GetFullPath($fixtureRoot).Replace('\','/').TrimEnd('/')
    $null=[IO.Directory]::CreateDirectory((Join-Path $root 'apps/mobile/build'))
    $null=[IO.Directory]::CreateDirectory((Join-Path $root 'docs/quality'))
    $fakeSource='b'*40; $fakeTree='c'*40; $fakeRegistry='D'*64; $fakeProducer='a'*40; $fakeQ='e'*40
    $fixtureDoc=Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
    function Get-OctoberCompatibilityBinding { return @{worktreePath=$root} }
    function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
      $key=$Arguments -join '|'
      if($key -ceq "rev-parse|${fakeSource}^{tree}"){return $fakeTree}
      if($key -ceq "rev-parse|${fakeSource}:scripts/test-codex-integration-repair-coordination-policy.ps1"){return $fakeProducer}
      if($key -ceq "show|${fakeSource}:config/codex-subagent-coordination-policy.json"){
        return (ConvertTo-Json -InputObject @{registryBinding=@{sha256=$fakeRegistry}} -Compress)
      }
      if($key -ceq "show|${fakeQ}:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md"){
        return [IO.File]::ReadAllText($fixtureDoc)
      }
      throw 'Unexpected synthetic fixture Git read.'
    }
    function Write-FixtureProof([object]$Proof) {
      $text="<!-- COMPATIBILITY_QUALIFICATION_JSON_BEGIN -->`n"+
        (ConvertTo-Json -InputObject $Proof -Depth 30 -Compress)+
        "`n<!-- COMPATIBILITY_QUALIFICATION_JSON_END -->"
      [IO.File]::WriteAllText($fixtureDoc,$text,[Text.UTF8Encoding]::new($false))
    }
    $reports=[Collections.Generic.List[object]]::new()
    $minimum=@{publication_contracts=92; impacted_store_buy=984; store_layout_and_recovery=40; enabled_review_fixture=14}
    foreach($id in @('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')) {
      $plan=Get-OctoberCompatibilityReportPlan $id
      $relative='apps/mobile/build/fixture-'+$id+'.jsonl'; $log=Join-Path $root $relative
      $events=[Collections.Generic.List[object]]::new()
      $events.Add(@{type='moolsocialSource'; sourceCommit=$fakeSource; sourceTree=$fakeTree
        registrySha256=$fakeRegistry; reportId=$id; runtimeDefines=@($plan.RuntimeDefines)})
      $events.Add(@{type='start'}); $events.Add(@{type='allSuites'; count=$plan.Suites.Count})
      $testId=1
      for($suiteId=0;$suiteId -lt $plan.Suites.Count;$suiteId++) {
        $suite=$plan.Suites[$suiteId]
        $events.Add(@{type='suite'; suite=@{id=$suiteId; path=$root+'/apps/mobile/test/'+$suite}})
        $count=[int][Math]::Floor($minimum[$id]/$plan.Suites.Count)
        if($suiteId -lt ($minimum[$id]%$plan.Suites.Count)){$count++}
        for($n=0;$n -lt $count;$n++) {
          $events.Add(@{type='testStart'; test=@{id=$testId; suiteID=$suiteId; name='Labelled fixture behavior '+$n}})
          $events.Add(@{type='testDone'; testID=$testId; result='success'; skipped=$false}); $testId++
        }
      }
      $events.Add(@{type='done'; success=$true})
      $writer=[IO.StreamWriter]::new($log,$false,[Text.UTF8Encoding]::new($false))
      try {foreach($event in $events){$writer.WriteLine((ConvertTo-Json -InputObject $event -Depth 12 -Compress))}}finally{$writer.Dispose()}
      $stderr=$log+'.stderr.txt'; [IO.File]::WriteAllText($stderr,'',[Text.UTF8Encoding]::new($false))
      $capture=@{schemaVersion=1; producer='test-codex-integration-repair-coordination-policy.ps1'
        producerGitBlob=$fakeProducer; reportId=$id; sourceCommit=$fakeSource; sourceTree=$fakeTree
        registrySha256=$fakeRegistry; sourceCommitAfter=$fakeSource; sourceTreeAfter=$fakeTree
        stdoutSha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash
        stderrPath=$relative+'.stderr.txt'; stderrSha256=(Get-FileHash -LiteralPath $stderr -Algorithm SHA256).Hash
        executable='C:/Users/jisal/develop/flutter/bin/flutter.bat'; workingDirectory=$root+'/apps/mobile'
        exitCode=0; guardCompleted=$true; cleanBefore=$true; cleanAfter=$true
        arguments=@($plan.Arguments); runtimeDefines=@($plan.RuntimeDefines)
        startedAtUtc='2026-10-08T01:00:00+00:00'; finishedAtUtc='2026-10-08T01:01:00+00:00'}
      [IO.File]::WriteAllText(($log+'.capture.json'),(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
      $reports.Add(@{id=$id; path=$relative; sha256=$capture.stdoutSha256; capturePath=$relative+'.capture.json'
        captureSha256=(Get-FileHash -LiteralPath ($log+'.capture.json') -Algorithm SHA256).Hash
        runtimeDefines=@($plan.RuntimeDefines)})
    }
    $proof=@{schemaVersion=1; state='verified'; sourceCommit=$fakeSource; sourceTree=$fakeTree
      registrySha256=$fakeRegistry; reports=$reports.ToArray()}
    Write-FixtureProof $proof
    $working=@{Stage=4; Commits=@(('f'*40),('d'*40),('a'*40),$fakeSource); Head=$fakeSource}
    $committed=@{Stage=5; Commits=@(('f'*40),('d'*40),('a'*40),$fakeSource,$fakeQ); Head=$fakeQ}
    Assert-RepairContract (Test-OctoberCompatibilityQualification $working -FromWorkingTree) 'complete labelled working-Q aggregate rejected.'
    Assert-RepairContract (Test-OctoberCompatibilityQualification $committed) 'complete labelled committed-Q aggregate rejected.'
    $aggregateCases=2
    foreach($kind in @('missing-report','duplicate-report','stale-source','stale-registry','swapped-sidecars')) {
      $changed=(ConvertTo-Json -InputObject $proof -Depth 30 -Compress)|ConvertFrom-Json
      switch($kind) {
        'missing-report' {$changed.reports=@($changed.reports[0..2])}
        'duplicate-report' {$changed.reports=@($changed.reports[0..2])+@($changed.reports[0])}
        'stale-source' {$changed.sourceCommit='0'*40}
        'stale-registry' {$changed.registrySha256='0'*64}
        'swapped-sidecars' {
          $changed.reports[0].capturePath=$changed.reports[1].capturePath
          $changed.reports[0].captureSha256=$changed.reports[1].captureSha256
        }
      }
      Write-FixtureProof $changed
      Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $working -FromWorkingTree)) "aggregate $kind accepted."
      $aggregateCases++
    }
    $firstLog=Join-Path $root ([string]$proof.reports[0].path)
    $firstCapture=Join-Path $root ([string]$proof.reports[0].capturePath)
    $originalLog=[IO.File]::ReadAllBytes($firstLog)
    $originalCapture=[IO.File]::ReadAllBytes($firstCapture)
    $captureJsonParameters=@{}
    if((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
      $captureJsonParameters.DateKind='String'
    }
    foreach($kind in @('wrong-producer','wrong-plan','uncovered-skip','non-utc-timestamp')) {
      try {
        $changed=(ConvertTo-Json -InputObject $proof -Depth 30 -Compress)|ConvertFrom-Json
        $capture=[IO.File]::ReadAllText($firstCapture)|ConvertFrom-Json @captureJsonParameters
        Assert-RepairContract ($capture.startedAtUtc -is [string] -and
          $capture.startedAtUtc -ceq '2026-10-08T01:00:00+00:00') 'capture ISO timestamp was coerced before mutation.'
        switch($kind) {
          'wrong-producer' {$capture.producerGitBlob='0'*40}
          'wrong-plan' {$capture.arguments=@($capture.arguments)+@('--name=incorrect-filter')}
          'non-utc-timestamp' {$capture.startedAtUtc='2026-10-08T06:30:00+05:30'}
          'uncovered-skip' {
            $events=@([IO.File]::ReadAllLines($firstLog)|ForEach-Object {$_|ConvertFrom-Json})
            $done=@($events|Where-Object {$_.type -ceq 'testDone' -and $_.testID -eq 1})
            Assert-RepairContract ($done.Count -eq 1) 'skip fixture target not unique.'
            $done[0].skipped=$true
            $writer=[IO.StreamWriter]::new($firstLog,$false,[Text.UTF8Encoding]::new($false))
            try {foreach($event in $events){$writer.WriteLine((ConvertTo-Json -InputObject $event -Depth 12 -Compress))}}finally{$writer.Dispose()}
            $capture.stdoutSha256=(Get-FileHash -LiteralPath $firstLog -Algorithm SHA256).Hash
            $changed.reports[0].sha256=$capture.stdoutSha256
          }
        }
        [IO.File]::WriteAllText($firstCapture,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
        $changed.reports[0].captureSha256=(Get-FileHash -LiteralPath $firstCapture -Algorithm SHA256).Hash
        Write-FixtureProof $changed
        Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $working -FromWorkingTree)) "aggregate $kind accepted."
        $aggregateCases++
      } finally {
        [IO.File]::WriteAllBytes($firstLog,$originalLog)
        [IO.File]::WriteAllBytes($firstCapture,$originalCapture)
      }
    }
    Write-FixtureProof $proof
    Assert-RepairContract ($aggregateCases -eq 11) 'aggregate fixture inventory changed.'
    Write-Output "Compatibility aggregate qualification: $aggregateCases labelled fixtures passed; isolated fake Git only, no actual source qualification."
  }
  $baseLines=@(& git -C $root show "$($binding.baselineHead):config/codex-subagent-coordination-policy.json")
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'sealed E policy unavailable.'
  $basePolicy=($baseLines -join "`n") | ConvertFrom-Json
  $baseBindings=@($basePolicy.productionGitDiscipline.continuationBindings)
  $bindings=@($policy.productionGitDiscipline.continuationBindings)
  Assert-RepairContract (Test-OctoberCompatibilityBindingInventory $bindings $baseBindings) 'exact82-plus-one inventory rejected.'
  $inventoryCases=1
  Assert-RepairContract (Test-OctoberCompatibilityBindingInventory @($bindings | Sort-Object id) $baseBindings) 'outer binding order affects identity.'
  $inventoryCases++
  foreach($probe in @(
      @{ Bindings=@($bindings[0..81]); Base=$baseBindings },
      @{ Bindings=@($bindings)+@($bindings[0]); Base=$baseBindings },
      @{ Bindings=@($bindings[0..81])+@($bindings[0]); Base=$baseBindings },
      @{ Bindings=$bindings; Base=@($baseBindings[0..80]) },
      @{ Bindings=$bindings; Base=@($baseBindings[0..80])+@($baseBindings[0]) })) {
    Assert-RepairContract (-not (Test-OctoberCompatibilityBindingInventory @($probe.Bindings) @($probe.Base))) 'bad binding count/identity accepted.'
    $inventoryCases++
  }
  foreach($target in @([string]$baseBindings[0].id,[string]$binding.id)) {
    $altered=@((ConvertTo-Json -InputObject $bindings -Depth 100 -Compress) | ConvertFrom-Json)
    $row=@($altered | Where-Object { $_.id -ceq $target })
    Assert-RepairContract ($row.Count -eq 1) 'mutation target not unique.'
    $row[0] | Add-Member -MemberType NoteProperty -Name state -Value 'altered' -Force
    Assert-RepairContract (-not (Test-OctoberCompatibilityBindingInventory $altered $baseBindings)) 'changed historical/successor body accepted.'
    $inventoryCases++
  }
  Assert-RepairContract ($inventoryCases -eq 9) 'binding probe inventory changed.'
  Write-Output "Compatibility binding inventory: $inventoryCases cases passed; sealed82 bodies and exact successor retained."
  $uiLockPath=Join-Path $root 'scripts/check-approved-ui-locks.ps1'
  $uiTokens=$null; $uiErrors=$null
  $uiAst=[System.Management.Automation.Language.Parser]::ParseFile($uiLockPath,[ref]$uiTokens,[ref]$uiErrors)
  Assert-RepairContract ($uiErrors.Count -eq 0) 'UI-lock checker has parse errors.'
  foreach($name in @('Get-LockSha256','Get-CursorAccessibilityNativeProjection')) {
    $nodes=@($uiAst.FindAll({param($node)
      $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    },$true))
    Assert-RepairContract ($nodes.Count -eq 1) "missing/duplicate native predicate$name."
    . ([scriptblock]::Create($nodes[0].Extent.Text))
  }
  $nativePath=Join-Path $root 'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
  $nativeSource=[IO.File]::ReadAllText($nativePath).Replace("`r`n","`n")
  $projection=Get-CursorAccessibilityNativeProjection -Path $nativePath -Source $nativeSource
  Assert-RepairContract ((Get-LockSha256 ([Text.UTF8Encoding]::new($false).GetBytes($projection))) -ceq
    'f28c19b40a0bcd8f660cc33bbb4683ec03057327b69695a3abf7cb09d0b0e4a4') 'sealed native projection changed.'
  $nativeCases=1
  foreach($probe in @(
      @{ Path=$nativePath; Source=$nativeSource+"`n// altered fixture"; Error='Store download projection rejects changed native source.' },
      @{ Path=(Join-Path $root 'apps/mobile/android/unassigned.kt'); Source=$nativeSource; Error='Approved UI Accessibility projection requires its exact isolated native owner.' })) {
    $rejected=$false
    try { $null=Get-CursorAccessibilityNativeProjection -Path $probe.Path -Source $probe.Source }
    catch { Assert-RepairContract ($_.Exception.Message -ceq $probe.Error) 'native probe failed for an unrelated reason.'; $rejected=$true }
    Assert-RepairContract $rejected 'altered/unassigned native source accepted.'
    $nativeCases++
  }
  Write-Output "Compatibility native projection: $nativeCases cases passed; no native files modified."
  $history=Get-OctoberCompatibilityHistoryStage $binding.baselineHead
  Assert-RepairContract ($history.Stage -eq 0 -and $history.Commits.Count -eq 0 -and
    $history.Head -ceq $binding.baselineHead) 'exact live E graph rejected.'
  $historyCases=1
  foreach($checkpoint in @(
      @{Head='f376a80b9c4abb6bed42ebb40136de2dd884d346'; Stage=1},
      @{Head='62e0a37d900f11c0c2d405e6559e54ef70ab9b43'; Stage=2})) {
    $sealed=Get-OctoberCompatibilityHistoryStage $checkpoint.Head
    Assert-RepairContract ($sealed.Stage -eq $checkpoint.Stage -and
      $sealed.Head -ceq $checkpoint.Head) 'sealed G/C identity, owner or parentage rejected.'
    $historyCases++
  }
  foreach($probe in @(
      @{ Head='f27e25fdfa64453d119d81dcef51956a56120c19'; Error='Codex subagent coordination gate rejected: Compatibility HEAD must descend from exact E.' },
      @{ Head='altered'; Error='Codex subagent coordination gate rejected: Compatibility HEAD identity invalid.' })) {
    $rejected=$false
    try { $null=Get-OctoberCompatibilityHistoryStage $probe.Head }
    catch { Assert-RepairContract ($_.Exception.Message -ceq $probe.Error) 'history probe failed for an unrelated reason.'; $rejected=$true }
    Assert-RepairContract $rejected 'unqualified/wrong history accepted.'
    $historyCases++
  }
  Write-Output "Compatibility live sealed history: $historyCases cases passed; E/G/C retained, not qualified."
  Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $history)) 'unqualified E evidence accepted.'
  $missingProof=@{ Stage=4; Commits=@($binding.baselineHead,$binding.baselineHead,$binding.baselineHead,$binding.baselineHead); Head=$binding.baselineHead }
  Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $missingProof -FromWorkingTree)) 'missing Q evidence accepted.'
  Write-Output 'Compatibility qualification: E and missing proof rejected; no host pass manufactured.'
  if($RequireCompatibilityLiveAdmissionProbes) {
    $live=@{
      RepositoryRoot=$root; AgentRole='primary'; AgentTask='/root'
      ClaimedOwners=@($binding.bootstrapOwners)
      ExpectedRegistryEntryCount=[int]$policy.registryBinding.entryCount
      ExpectedRegistrySha256=[string]$policy.registryBinding.sha256
      ProductionLane='integration_repair'; ProductionPhase='coordination_bootstrap'
      ProductionWorkId=$binding.workId; ProductionTicketId=$binding.ticketId
    }
    $probes=@(
      @{ Key='AgentTask'; Value='/root/altered'; Error='Compatibility83 inventory is outside its exact successor or final integration identity/phase.' },
      @{ Key='ProductionTicketId'; Value='UAW-ALTERED-COMPATIBILITY-20261008'; Error='Compatibility83 inventory is outside its exact successor or final integration identity/phase.' },
      @{ Key='ProductionWorkId'; Value='store-buy-altered-20261008'; Error='Compatibility83 inventory is outside its exact successor or final integration identity/phase.' },
      @{ Key='ProductionPhase'; Value='implementation'; Error='production continuation bootstrap commit is missing.' },
      @{ Key='ExpectedRegistryEntryCount'; Value=4622; Error='current registry entry count differs from the agent preflight generation.' },
      @{ Key='ExpectedRegistrySha256'; Value=('0'*64); Error='current registry SHA-256 differs from the agent preflight generation.' },
      @{ Key='ClaimedOwners'; Value=(@($binding.bootstrapOwners)+@(Get-OctoberCompatibilityApplicationOwners)); Error='Compatibility live stage/claim/qualification rejected.' }
    )
    $liveCases=0
    foreach($probe in $probes) {
      $altered=$live.Clone(); $altered[$probe.Key]=$probe.Value; $rejected=$false
      try { $null=& $checkerPath @altered }
      catch {
        Assert-RepairContract ($_.Exception.Message.IndexOf($probe.Error,[StringComparison]::Ordinal) -ge 0) "live probe$($probe.Key) failed for an unrelated reason: $($_.Exception.Message)"
        $rejected=$true
      }
      Assert-RepairContract $rejected "live probe$($probe.Key) admitted."
      $liveCases++
    }
    Assert-RepairContract ($liveCases -eq 7) 'live admission probe inventory changed.'
    Write-Output "Compatibility live admission: $liveCases negative cases rejected by operative checker; no fixture files changed."
  }
  return
}

$repair = $policy.productionGitDiscipline.integration.repair
$repairBinding = @(
  $policy.productionGitDiscipline.continuationBindings | Where-Object {
    [string]$_.id -ceq 'integration_repair_store_buy_conflict_v3_20260904'
  }
)
$repairClaim = @($policy.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/repair_store_buy_conflict_v3_20260904'
})
$expectedConflicts = @(
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'scripts/check-codex-subagent-coordination-policy.ps1'
)
$expectedBootstrapOwners = @(
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'docs/quality/STORE-BUY-V3-PRE-INTEGRATION-RECONCILIATION-20260904.md',
  'docs/quality/UAW-INTEGRATION-REPAIR-STORE-BUY-V3-20260904.md',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-codex-subagent-coordination-policy.ps1',
  'scripts/test-codex-integration-repair-coordination-policy.ps1'
)

Assert-RepairContract ($repairBinding.Count -eq 1) 'repair binding is missing or ambiguous.'
Assert-RepairContract ($repairClaim.Count -eq 1) 'repair owner claim is missing or ambiguous.'
Assert-RepairContract (
  [string]$repair.requiredCodexCommit -ceq
    'f208fbef80303ad3c6b1bf41a385616adcc969b5' -and
  [string]$repair.requiredCursorCommit -ceq
    'fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d' -and
  [string]$repairBinding[0].baselineHead -ceq
    [string]$repair.requiredCodexCommit -and
  [int]$repair.maximumMergeCommits -eq 1 -and
  [int]$repair.maximumPreMergeCoordinationCommits -eq 1 -and
  [int]$repair.maximumPostMergeClosureCommits -eq 3 -and
  -not [bool]$repair.directSourceCommitsAllowed -and
  [bool]$repair.conflictResolutionAllowed
) 'sealed parents or one-merge boundary changed.'
Assert-RepairContract (
  (@($repair.exactConflictOwners | Sort-Object) -join '|') -ceq
    (@($expectedConflicts | Sort-Object) -join '|')
) 'exact conflict owner set changed.'
Assert-RepairContract (
  (@($repairBinding[0].bootstrapOwners | Sort-Object) -join '|') -ceq
    (@($expectedBootstrapOwners | Sort-Object) -join '|')
) 'bootstrap owner set changed.'
if (-not $RequireOctoberSourceAdmission) {
  Assert-RepairContract (
    @($expectedConflicts | Where-Object {
      @($repairClaim[0].owners) -cnotcontains $_
    }).Count -eq 0
  ) 'repair claim does not own every conflict owner.'
} else {
  $octoberClaim=@($policy.activeClaims | Where-Object { $_.task -ceq '/root' -and $_.role -ceq 'primary' })
  $octoberBinding=@($policy.productionGitDiscipline.continuationBindings | Where-Object { $_.id -ceq 'integration_repair_store_buy_combined_20261008' })
  Assert-RepairContract ($octoberClaim.Count -eq 1 -and $octoberBinding.Count -eq 1) 'October claim or binding missing or ambiguous.'
  $octoberOwners=@(
    '.gitattributes','apps/mobile/.flutter-plugins-dependencies',
    'apps/mobile/lib/features/journey01/journey_router.dart',
    'apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart',
    'config/codex-development-regression-registry.json',
    'config/codex-subagent-coordination-policy.json','scripts/check-approved-ui-locks.ps1',
    'scripts/check-codex-subagent-coordination-policy.ps1','scripts/test-artifact-evidence-retention.ps1'
  ) + @($octoberBinding[0].bootstrapOwners)
  Assert-RepairContract (@($octoberOwners | Where-Object {
    @($octoberClaim[0].owners) -cnotcontains $_
  }).Count -eq 0) 'October primary claim does not own every admitted owner.'
}
foreach ($token in @(
  "'integration_repair'",
  "'integration_admission_authorize'",
  'function Assert-IntegrationRepairMerge',
  'function Assert-QualifiedIntegrationRepairTip',
  'integration repair conflict inventory changed',
  'integration repair resolved delta does not equal every exact conflict owner',
  'integration repair resolved blob retains conflict markers',
  'integration repair merge second parent changed',
  'fresh integration target is not clean at the governance tag'
)) {
  Assert-RepairContract ($checker.Contains($token)) "checker token is missing: $token"
}

if ($RequireQualifiedGraph) {
  $graphRepair=$repair.PSObject.Copy()
  $graphSubject='^repair\(store-buy-conflict-repair-v3-20260904\): .+'
  if ($RequireOctoberSourceAdmission) {
    $graphRepair.requiredCodexCommit='8002e8cd740aaf613b75dc749212fb12ae4fddb7'
    $graphRepair.requiredCursorCommit='f32c17e1a3a41807564fe18f83c0520a66e0bfe6'
    $graphSubject='^repair\(store-buy-combined-20261008\): .+'
  }
  $head = (& git -C $root rev-parse HEAD).Trim()
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'repair HEAD read failed.'
  $qualifiedMerges = @(& git -C $root rev-list --first-parent --merges `
      "$($graphRepair.requiredCodexCommit)..$head")
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and $qualifiedMerges.Count -eq 1
  ) 'qualified repair does not contain one exact merge.'
  $qualifiedMerge = [string]$qualifiedMerges[0]
  $parentOutput = @(& git -C $root show -s --format='%P' $qualifiedMerge)
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and $parentOutput.Count -eq 1
  ) 'qualified repair parent read failed.'
  $parents = @([string]$parentOutput[0] -split ' ')
  Assert-RepairContract (
    $parents.Count -eq 2 -and
    $parents[1] -ceq [string]$graphRepair.requiredCursorCommit
  ) 'qualified repair parents changed.'
  $subject = (& git -C $root show -s --format='%s' $qualifiedMerge).Trim()
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and
    $subject -cmatch $graphSubject
  ) 'qualified repair subject changed.'
  foreach ($requiredTip in @(
      [string]$graphRepair.requiredCodexCommit,
      [string]$graphRepair.requiredCursorCommit
    )) {
    & git -C $root merge-base --is-ancestor $requiredTip $head
    Assert-RepairContract ($LASTEXITCODE -eq 0) "qualified repair omits $requiredTip."
  }
}

if ($RequireOctoberSourceAdmission) {
  $parseTokens=$null; $parseErrors=$null
  $checkerAst=[System.Management.Automation.Language.Parser]::ParseFile($checkerPath,[ref]$parseTokens,[ref]$parseErrors)
  Assert-RepairContract (@($parseErrors).Count -eq 0) 'checker parse errors.'
  $functionNodes=@($checkerAst.FindAll({param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -cin @('Test-OctoberInheritedCursorDisposition','Test-OctoberIntegrationSelection','Test-OctoberIntegrationMergeSubject')
  },$true))
  Assert-RepairContract ($functionNodes.Count -eq 3) 'exact operative October predicates missing or duplicated.'
  foreach ($functionNode in $functionNodes) { . ([scriptblock]::Create($functionNode.Extent.Text)) }
  Assert-RepairContract (Test-OctoberIntegrationMergeSubject 'merge(store-buy-combined-baseline-20261008): integrate qualified Store and public Buy') 'exact merge subject rejected.'
  Assert-RepairContract (-not (Test-OctoberIntegrationMergeSubject 'merge(store-buy-combined-baseline-20261008): different outcome')) 'same prefix with different outcome accepted.'
  Assert-RepairContract (-not (Test-OctoberIntegrationMergeSubject 'merge(other-work): integrate qualified Store and public Buy')) 'wrong subject work ID accepted.'
  Write-Output 'October operative exact-merge-subject predicate: 3 cases passed.'
  $selectionCommit='8002e8cd740aaf613b75dc749212fb12ae4fddb7'
  $selectionBranch='work/integration-repair/store-buy-combined-20261008'
  Assert-RepairContract (Test-OctoberIntegrationSelection @($selectionCommit) @($selectionBranch)) 'exact selection predicate failed; graph qualification is separate.'
  foreach ($selection in @(
    @{commits=@();branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@()},
    @{commits=@($selectionCommit,$selectionCommit);branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@($selectionBranch,'work/cursor-ui/buy-ready-20260921')},
    @{commits=@($selectionCommit);branches=@('work/cursor-ui/buy-ready-20260921')},
    @{commits=@('invalid');branches=@($selectionBranch)},
    @{commits=@($selectionCommit.ToUpperInvariant());branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@($selectionBranch.ToUpperInvariant())}
  )) {
    Assert-RepairContract (-not (Test-OctoberIntegrationSelection $selection.commits $selection.branches)) 'invalid October selection accepted.'
  }
  Write-Output 'October operative integration-selection predicate: 9 cases passed; qualified-tip graph remains separate.'
  $octoberCommit='0e90a6ca74b81e212f118995f7c4fab0d3b78620'
  $octoberIdentity=@{Commit=$octoberCommit; CursorTip='f32c17e1a3a41807564fe18f83c0520a66e0bfe6'}
  foreach ($field in @(@('Parent','%P'),@('Tree','%T'),@('Subject','%s'))) {
    $value=@(& git -C $root show -s "--format=$($field[1])" $octoberCommit)
    Assert-RepairContract ($LASTEXITCODE -eq 0 -and $value.Count -eq 1) 'inherited identity read failed.'
    $octoberIdentity[$field[0]]=[string]$value[0]
  }
  $octoberIdentity.Paths=@(& git -C $root diff-tree --no-commit-id --name-only -r $octoberCommit)
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'inherited owner read failed.'
  & git -C $root merge-base --is-ancestor $octoberCommit $octoberIdentity.CursorTip
  $octoberIdentity.IsAncestor=$LASTEXITCODE -eq 0
  Assert-RepairContract (Test-OctoberInheritedCursorDisposition $octoberIdentity) 'actual inherited disposition rejected.'
  $octoberCases=1
  foreach ($key in @('Commit','Parent','Tree','Subject','CursorTip','IsAncestor','Paths')) {
    $changed=$octoberIdentity.Clone(); $changed[$key]='altered'
    Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $changed)) "altered inherited $key accepted."
    $missing=$octoberIdentity.Clone(); $missing.Remove($key)
    Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $missing)) "missing inherited $key accepted."
    $octoberCases+=2
  }
  $sameSubject=$octoberIdentity.Clone(); $sameSubject.Commit=$octoberIdentity.Parent
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $sameSubject)) 'same-subject different commit accepted.'
  $sibling=$octoberIdentity.Clone(); $sibling.Paths=@($octoberIdentity.Paths[0..14])+'apps/mobile/lib/features/journey01/forbidden_sibling.dart'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $sibling)) 'forbidden sibling accepted.'
  $duplicate=$octoberIdentity.Clone(); $duplicate.Paths=@($octoberIdentity.Paths[0..14])+$octoberIdentity.Paths[0]
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $duplicate)) 'duplicate owner accepted.'
  $notAncestor=$octoberIdentity.Clone(); $notAncestor.IsAncestor=$false
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $notAncestor)) 'non-ancestor accepted.'
  $textAncestor=$octoberIdentity.Clone(); $textAncestor.IsAncestor='true'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $textAncestor)) 'string ancestry accepted.'
  $extra=$octoberIdentity.Clone(); $extra.Unknown='extra'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $extra)) 'extra field accepted.'
  $octoberCases+=6
  Write-Output "October operative inherited-disposition predicate: $octoberCases cases passed. Full graph replay remains separate."
}
if ($RequireOctoberBootstrapProbes) {
  Assert-RepairContract ([bool]$RequireOctoberSourceAdmission) 'October bootstrap probes require October fixture mode.'
  $bootstrapParameters=@{
    AgentRole='primary';AgentTask='/root'
    ClaimedOwners=@($octoberBinding[0].bootstrapOwners)
    ExpectedRegistryEntryCount=[int]$policy.registryBinding.entryCount
    ExpectedRegistrySha256=[string]$policy.registryBinding.sha256
    ProductionLane='integration_repair';ProductionPhase='coordination_bootstrap'
    ProductionWorkId='store-buy-combined-20261008'
    ProductionTicketId='UAW-INTEGRATION-REPAIR-STORE-BUY-COMBINED-20261008'
    RepositoryRoot=$root
  }
  foreach ($probeName in @('wrong-ticket','extra-app-owner','missing-owner','stale-generation')) {
    $probe=$bootstrapParameters.Clone()
    switch ($probeName) {
      'wrong-ticket' { $probe.ProductionTicketId='UAW-INTEGRATION-REPAIR-STORE-BUY-COMBINED-WRONG' }
      'extra-app-owner' { $probe.ClaimedOwners=@($probe.ClaimedOwners)+'apps/mobile/lib/features/journey01/journey_router.dart' }
      'missing-owner' { $probe.ClaimedOwners=@($probe.ClaimedOwners[0..3]) }
      'stale-generation' { $probe.ExpectedRegistrySha256=('0' * 64) }
    }
    $rejected=$false
    try { & $checkerPath @probe | Out-Null } catch { $rejected=$true; Write-Output "$probeName rejected: $($_.Exception.Message)" }
    Assert-RepairContract $rejected "operative bootstrap accepted $probeName."
  }
  Write-Output 'October operative bootstrap: 4 rejection probes passed; files were not mutated.'
}
Write-Output 'Codex Store-Buy integration repair coordination fixture passed.'
