[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireQualifiedGraph,
  [switch]$RequireOctoberSourceAdmission,
  [switch]$RequireOctoberBootstrapProbes,
  [switch]$RequireCompatibilityStageProbes,
  [switch]$RequireCompatibilityLiveAdmissionProbes,
  [ValidateSet('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')]
  [string]$CaptureCompatibilityReport,
  [ValidateSet('default','localstock_review','workspace_capture','historical_store_review','historical_store_capture','store_live_capture','founder_capture')]
  [string]$CaptureExecutionId = 'default'
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

function Invoke-OctoberCompatibilityVisualEnvironment {
  param([hashtable]$Values,[scriptblock]$Invocation)
  $keys=@('MOOLSOCIAL_COMPAT_VISUAL_MANIFEST','MOOLSOCIAL_COMPAT_EXECUTION_LOG',
    'MOOLSOCIAL_COMPAT_SOURCE_COMMIT','MOOLSOCIAL_COMPAT_SOURCE_TREE','MOOLSOCIAL_COMPAT_EXECUTION_ID')
  if($null -eq $Values -or $null -eq $Invocation -or $Values.Count -notin @(0,5)){throw 'Recorder environment requires empty or complete literal bindings.'}
  foreach($name in $Values.Keys) {
    if($keys -cnotcontains $name -or $Values[$name] -isnot [string] -or
        [string]::IsNullOrWhiteSpace($Values[$name])){throw 'Recorder environment rejects unknown or invalid bindings.'}
  }
  $previous=@{}
  foreach($name in $keys){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
  try {
    foreach($name in $keys){
      if($Values.ContainsKey($name)){[Environment]::SetEnvironmentVariable($name,$Values[$name],'Process')}
      else{[Environment]::SetEnvironmentVariable($name,[NullString]::Value,'Process')}
    }
    & $Invocation
  } finally {
    foreach($name in $keys){
      if($null -eq $previous[$name]){[Environment]::SetEnvironmentVariable($name,[NullString]::Value,'Process')}
      else{[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}
    }
  }
}

function Invoke-OctoberCompatibilityComparatorBoundCapture {
  param([hashtable]$Receipt,[scriptblock]$Invocation)
  if($null -eq $Receipt -or $Receipt.Count -ne 0 -or $null -eq $Invocation){throw 'Comparator capture requires a fresh receipt and invocation.'}
  $before=Get-OctoberCompatibilityComparatorIdentity
  $Receipt.comparatorImplementationSha256Before=$before
  $Receipt.comparatorSdkCommitBefore=if($null -ne $before){'ee80f08bbf97172ec030b8751ceab557177a34a6'}else{$null}
  $Receipt.comparatorCheckedBeforeAtUtc=[DateTimeOffset]::UtcNow.ToString('o')
  Assert-RepairContract ($before -ceq 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA') 'comparator SDK unavailable before capture.'
  try {& $Invocation} finally {
    $after=Get-OctoberCompatibilityComparatorIdentity
    $Receipt.comparatorImplementationSha256After=$after
    $Receipt.comparatorSdkCommitAfter=if($null -ne $after){'ee80f08bbf97172ec030b8751ceab557177a34a6'}else{$null}
    $Receipt.comparatorCheckedAfterAtUtc=[DateTimeOffset]::UtcNow.ToString('o')
    Assert-RepairContract ($after -ceq 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA') 'comparator SDK changed/unavailable after capture.'
  }
}

Assert-RepairContract ($CaptureCompatibilityReport -or $CaptureExecutionId -ceq 'default') 'execution selection requires capture mode.'

if ($RequireCompatibilityStageProbes -or $RequireCompatibilityLiveAdmissionProbes -or $CaptureCompatibilityReport) {
  $tokens=$null; $errors=$null
  $ast=[System.Management.Automation.Language.Parser]::ParseFile(
    $checkerPath,[ref]$tokens,[ref]$errors)
  Assert-RepairContract ($errors.Count -eq 0) 'checker has parse errors.'
  foreach ($name in @('Get-OctoberCompatibilityBinding',
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityAmendmentOwners','Get-OctoberCompatibilityLayoutOwners','Get-OctoberCompatibilityHandoverOwners','Get-OctoberCompatibilityCoverageCartOwners','Get-OctoberCompatibilityInheritedCartTestOwners','Read-OctoberCompatibilityTestAdmissionContract','Test-OctoberCompatibilityBindingInventory',
      'Test-OctoberCompatibilityStageFacts','Test-OctoberCompatibilityIntegrationIdentity','Assert-Coordination',
      'Get-OctoberCoverageBoundHash','New-OctoberCoverageMutex','Test-OctoberCoveragePreparation','Test-OctoberHandoverPreparation',
      'Get-OctoberCompatibilityGitLines','Get-OctoberCompatibilityHistoryStage',
      'Test-OctoberCompatibilityQualification','Get-OctoberCompatibilityComparatorIdentity','Test-OctoberCompatibilityCaptureComparator','Test-OctoberCompatibilityVisualQualification','Test-OctoberCompatibilityLegacyQualification','Read-OctoberCompatibilityExecutionCoverage','Read-OctoberCompatibilityVisualManifestBinding','Test-OctoberCompatibilityVisualEvidenceShape','Read-OctoberCompatibilityVisualArtifactBytes','Read-OctoberCompatibilityJsonObject','Get-OctoberCompatibilityQualificationExecutions','Read-OctoberCompatibilityExecutionEvents','Read-OctoberCompatibilityExecutionEvidence','Get-OctoberCompatibilityByteHash','Read-OctoberCompatibilityReportEvents',
      'Read-OctoberCompatibilityClaimHandoff','Get-OctoberCompatibilityClaimHandoff','Read-OctoberCompatibilityDerivedClaims',
      'Get-OctoberCompatibilityReportPlan','Get-OctoberCompatibilityExecutionPlan','Test-OctoberCompatibilityCapture',
      'Test-OctoberCompatibilitySourceMarker','Test-OctoberCompatibilityCoverageSpecification',
      'Get-OctoberCompatibilityCoverageSpecification','Read-OctoberCompatibilityResolutionSpecification','Get-OctoberCompatibilityResolutionSpecification','Get-OctoberCompatibilityVisualProtocol','Test-OctoberCompatibilityKResolution','Read-OctoberCompatibilityTrustedVisualDecisions','Read-OctoberCompatibilityPngPixels','Test-OctoberCompatibilityPngEquality','Read-OctoberCompatibilityVisualObservations','Open-OctoberCompatibilityVisualArtifact','Test-OctoberCompatibilityLockedPngPair','Test-OctoberCompatibilityVisualSlot','Test-OctoberCoveragePreCommitInventory')) {
    $nodes=@($ast.FindAll({param($node)
      $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq $name
    },$true))
    Assert-RepairContract ($nodes.Count -eq 1) "missing/duplicate operative predicate $name."
    . ([scriptblock]::Create($nodes[0].Extent.Text))
  }
  $binding=Get-OctoberCompatibilityBinding
  if($RequireCompatibilityStageProbes) {
    $resolutionText=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
    & {
      $claimFixtureBinding=Get-OctoberCompatibilityClaimHandoff
      Assert-RepairContract ($null -ne $claimFixtureBinding -and $claimFixtureBinding.Sha256 -ceq 'B2EE65275AF1A0BD2F176751EDA97C3493A1858CFB0B5588AED52D092D1DA505') 'Exact working handoff contract rejected.'
      $claimFixtureJson=$claimFixtureBinding.SpecificationJson
      $claimFixtureN=Read-OctoberCompatibilityTestAdmissionContract -FromWorkingTree
      Assert-RepairContract ($null -ne $claimFixtureN) 'Exact N fixture contract rejected.'
      $claimFixtureNJson=$claimFixtureN|ConvertTo-Json -Depth 30 -Compress
      $claimFixtureTestOwners=@('apps/mobile/test/ui_v2/buy/buy_v2_cart_safe_clear_test.dart',
        'apps/mobile/test/ui_v2/buy/buy_v2_navigation_motion_test.dart',
        'apps/mobile/test/ui_v2/buy/buy_v2_cart_line_continuity_test.dart',
        'apps/mobile/test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart')
      Assert-RepairContract ((@(Get-OctoberCompatibilityInheritedCartTestOwners) -join '|') -ceq ($claimFixtureTestOwners -join '|')) 'Literal N test owner inventory differs.'
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityClaimHandoff ($claimFixtureJson.Replace("`n","`r`n")))) 'CRLF-normalized handoff rejected.'
      $claimFixtureCases=@('positive','pre-M','unverified-M','coerced-M','writer-active','wrong-root','wrong-branch','wrong-task','wrong-role',
        'wrong-policy','wrong-registry','wrong-cursor','wrong-phase','wrong-M-commit','K-as-M','changed-contract',
        'missing-claim','duplicate-claim','missing-Buy','duplicate-Buy','changed-non-Buy','changed-role',
        'N-positive','T-positive','Q-positive','N-unverified','N-coerced','N-missing-proof','N-empty-contract',
        'N-altered-contract','N-as-L','N-draft-pre-N','N-premature-handoff','Q-implementation','T-unrelated-owner')
      Assert-RepairContract ($claimFixtureCases.Count -eq 35) 'M22 plus N13 fixture inventory differs.'
      $claimFixtureOriginal=$policy.activeClaims|ConvertTo-Json -Depth 30 -Compress
      foreach($claimFixtureMode in $claimFixtureCases){
        $claimFixtureClaims=ConvertFrom-Json -InputObject $claimFixtureOriginal
        $claimFixtureClaims=@($claimFixtureClaims)
        $claimFixtureContext=@{Root=$binding.worktreePath;Branch=$binding.branch;Role='primary';Task='/root';Lane=$binding.lane;
          WorkId=$binding.workId;TicketId=$binding.ticketId;Stage=7;Phase='implementation';ImmutableMVerified=$true;WriterFactsVerified=$true;
          MCommit=('b'*40);PolicySha256='84C191D84F5973126969568CC979B245233972BD5FF185BC599F51B4FCAFC8B3';
          RegistrySha256='8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3';CursorCommit='f32c17e1a3a41807564fe18f83c0520a66e0bfe6'}
        $claimFixtureCandidate=$claimFixtureJson
        $claimFixtureTestCandidate=''
        if($claimFixtureMode -cmatch '^(N|T|Q)-') {
          $claimFixtureContext.Stage=9;$claimFixtureContext.ImmutableNVerified=$true;$claimFixtureContext.NCommit=('a'*40)
          $claimFixtureTestCandidate=$claimFixtureNJson
        }
        switch($claimFixtureMode){
          'pre-M' {$claimFixtureContext.Stage=6}
          'unverified-M' {$claimFixtureContext.ImmutableMVerified=$false}
          'coerced-M' {$claimFixtureContext.ImmutableMVerified='true'}
          'writer-active' {$claimFixtureContext.WriterFactsVerified=$false}
          'wrong-root' {$claimFixtureContext.Root='C:/other'}
          'wrong-branch' {$claimFixtureContext.Branch='other'}
          'wrong-task' {$claimFixtureContext.Task='/root/other'}
          'wrong-role' {$claimFixtureContext.Role='subagent'}
          'wrong-policy' {$claimFixtureContext.PolicySha256='0'*64}
          'wrong-registry' {$claimFixtureContext.RegistrySha256='0'*64}
          'wrong-cursor' {$claimFixtureContext.CursorCommit='a'*40}
          'wrong-phase' {$claimFixtureContext.Phase='candidate_preflight'}
          'wrong-M-commit' {$claimFixtureContext.MCommit='not-a-commit'}
          'K-as-M' {$claimFixtureContext.MCommit='2beaf3775ed20f14fa42101346b35ddb7f8e9283'}
          'changed-contract' {$claimFixtureCandidate=$claimFixtureJson.Replace('exclusive_handoff','unapproved_handoff')}
          'missing-claim' {$claimFixtureClaims=@($claimFixtureClaims[0..1])}
          'duplicate-claim' {$claimFixtureClaims[1]=$claimFixtureClaims[0]}
          'missing-Buy' {$claimFixtureClaims[2].owners=@($claimFixtureClaims[2].owners|Where-Object {$_ -cne 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'})}
          'duplicate-Buy' {$claimFixtureClaims[0].owners+=@('apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart')}
          'changed-non-Buy' {$claimFixtureClaims[1].owners+=@('extra.dart')}
          'changed-role' {$claimFixtureClaims[1].role='subagent'}
          'T-positive' {$claimFixtureContext.Stage=10}
          'Q-positive' {$claimFixtureContext.Stage=11;$claimFixtureContext.Phase='handoff'}
          'N-unverified' {$claimFixtureContext.ImmutableNVerified=$false}
          'N-coerced' {$claimFixtureContext.ImmutableNVerified='true'}
          'N-missing-proof' {$claimFixtureContext.Remove('ImmutableNVerified')}
          'N-empty-contract' {$claimFixtureTestCandidate=''}
          'N-altered-contract' {$claimFixtureTestCandidate=$claimFixtureNJson.Replace('specified_test_addition_not_active_until_committed_N','unapproved_test_addition')}
          'N-as-L' {$claimFixtureContext.NCommit='0da3630d1c857390c173ec83ba5c0210cb1e5ec2'}
          'N-draft-pre-N' {$claimFixtureContext.Stage=8}
          'N-premature-handoff' {$claimFixtureContext.Phase='handoff'}
          'Q-implementation' {$claimFixtureContext.Stage=11}
          'T-unrelated-owner' {$claimFixtureContext.Stage=10;$claimFixtureClaims[1].owners+=@('extra.dart')}
        }
        $claimFixtureBefore=$claimFixtureClaims|ConvertTo-Json -Depth 30 -Compress
        $claimFixtureResult=@(Read-OctoberCompatibilityDerivedClaims -Claims $claimFixtureClaims -ContractJson $claimFixtureCandidate -Context $claimFixtureContext -TestAdmissionJson $claimFixtureTestCandidate)
        $claimFixtureAccepted=$claimFixtureMode -cin @('positive','N-positive','T-positive','Q-positive')
        Assert-RepairContract (($claimFixtureResult.Count -eq 3) -eq $claimFixtureAccepted) ('Derived handoff result incorrect: '+$claimFixtureMode)
        if(-not $claimFixtureAccepted){
          Assert-RepairContract (@($claimFixtureResult|Where-Object {$null -ne $_}).Count -eq 0) ('Rejected handoff returned non-null payload: '+$claimFixtureMode)
        }
        Assert-RepairContract (($claimFixtureClaims|ConvertTo-Json -Depth 30 -Compress) -ceq $claimFixtureBefore) ('Input claims mutated: '+$claimFixtureMode)
        if($claimFixtureAccepted){
          $claimFixtureExpected=ConvertFrom-Json -InputObject $claimFixtureOriginal
          $claimFixtureExpected=@($claimFixtureExpected)
          $claimFixtureExpected[0].owners+=@('apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart')
          $claimFixtureExpected[2].owners=@($claimFixtureExpected[2].owners|Where-Object {$_ -cne 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'})
          $claimFixtureExpectedCount=97
          if($claimFixtureMode -cne 'positive'){$claimFixtureExpected[0].owners+=@($claimFixtureTestOwners);$claimFixtureExpectedCount=101}
          Assert-RepairContract (($claimFixtureResult|ConvertTo-Json -Depth 30 -Compress) -ceq
            ($claimFixtureExpected|ConvertTo-Json -Depth 30 -Compress)) 'Complete derived claim result differs from exclusive one-owner handoff.'
          $claimFixtureTo=@($claimFixtureResult|Where-Object {$_.task -ceq '/root'})
          $claimFixtureFrom=@($claimFixtureResult|Where-Object {$_.task -ceq '/root/cursor_redmi_v6_audit_20260913'})
          Assert-RepairContract (@($claimFixtureTo[0].owners).Count -eq $claimFixtureExpectedCount -and @($claimFixtureFrom[0].owners).Count -eq 68 -and
            @($claimFixtureTo[0].owners|Where-Object {$_ -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'}).Count -eq 1 -and
            @($claimFixtureFrom[0].owners|Where-Object {$_ -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'}).Count -eq 0) 'One-owner transfer differs.'
        }
      }
      foreach($claimFixtureReadMode in @('index','commit','changed','missing','duplicate','throw','mixed','invalid-commit','empty-commit','null-commit','index-empty','index-null')){
        & {
          $claimFixtureReads=@{Count=0;Unexpected=$false}
          function Get-OctoberCompatibilityGitLines {param([string[]]$Arguments)
            $claimFixtureReads.Count++
            $selection=$Arguments -join '|'
            $expectedSelection=if($claimFixtureReadMode -ceq 'commit'){'show|'+('b'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
            if($selection -cne $expectedSelection){$claimFixtureReads.Unexpected=$true;throw 'Unexpected handoff source selection'}
            switch($claimFixtureReadMode){
              'changed' {return $resolutionText.Replace('exclusive_handoff','unapproved_handoff')}
              'missing' {return $resolutionText.Replace('COMPATIBILITY_CLAIM_HANDOFF_JSON_BEGIN','MISSING_HANDOFF')}
              'duplicate' {return $resolutionText+"`n<!-- COMPATIBILITY_CLAIM_HANDOFF_JSON_BEGIN -->{}<!-- COMPATIBILITY_CLAIM_HANDOFF_JSON_END -->"}
              'throw' {throw 'Labelled unavailable handoff source'}
              default {return $resolutionText}
            }
          }
          $claimFixtureReadResult=switch($claimFixtureReadMode){
            'commit' {Get-OctoberCompatibilityClaimHandoff -Commit ('b'*40)}
            'mixed' {Get-OctoberCompatibilityClaimHandoff -FromIndex -Commit ('b'*40)}
            'invalid-commit' {Get-OctoberCompatibilityClaimHandoff -Commit 'invalid'}
            'empty-commit' {Get-OctoberCompatibilityClaimHandoff -Commit ''}
            'null-commit' {Get-OctoberCompatibilityClaimHandoff -Commit $null}
            'index-empty' {Get-OctoberCompatibilityClaimHandoff -FromIndex -Commit ''}
            'index-null' {Get-OctoberCompatibilityClaimHandoff -FromIndex -Commit $null}
            default {Get-OctoberCompatibilityClaimHandoff -FromIndex}
          }
          $expectedCalls=if($claimFixtureReadMode -cin @('mixed','invalid-commit','empty-commit','null-commit','index-empty','index-null')){0}else{1}
          Assert-RepairContract (-not $claimFixtureReads.Unexpected -and $claimFixtureReads.Count -eq $expectedCalls) ('Handoff wrong source/read count: '+$claimFixtureReadMode)
          Assert-RepairContract (($null -ne $claimFixtureReadResult) -eq ($claimFixtureReadMode -cin @('index','commit'))) ('Handoff source result: '+$claimFixtureReadMode)
        }
      }
      Write-Output ('Compatibility handoff composition: '+$claimFixtureCases.Count+' labelled in-memory cases and12 source-selection probes passed; simulated M then additive N, no claim activation or source edit.')
    }
    $resolutionBlocks=[regex]::Matches($resolutionText,'(?s)<!-- COMPATIBILITY_RESOLUTION_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_RESOLUTION_JSON_END -->')
    Assert-RepairContract ($resolutionBlocks.Count -eq 1) 'resolution fixture source missing or ambiguous.'
    $resolutionJson=$resolutionBlocks[0].Groups[1].Value
    $resolution=Read-OctoberCompatibilityResolutionSpecification $resolutionJson
    Assert-RepairContract ($null -ne $resolution -and $resolution.cases.Count -eq 84) 'exact resolution specification rejected.'
    Assert-RepairContract ($null -ne (Read-OctoberCompatibilityResolutionSpecification (" `n"+$resolutionJson+"`n "))) 'normalized exact resolution rejected.'
    $visualProtocol=Get-OctoberCompatibilityVisualProtocol
    Assert-RepairContract ($null -ne $visualProtocol -and $visualProtocol.decisionCount -eq 65) 'exact working visual protocol rejected.'
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityVisualProtocol -Commit 'not-a-commit')) 'invalid protocol commit admitted.'
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityVisualProtocol -FromIndex -Commit ('c'*40))) 'mixed protocol source admitted.'
    & {
      $kResolutionFixtureBlock=[regex]::Match($resolutionText,'(?s)<!-- COMPATIBILITY_QUALIFICATION_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_QUALIFICATION_JSON_END -->')
      # Permanent fixtures must survive actual K staging and later verified Q.
      # Today's unstaged/pending observations belong to read-only diagnostics.
      $kResolutionFixtureBaseline=[pscustomobject]@{schemaVersion=2;state='pending';sourceCommit=$null;sourceTree=$null;resolutionCommit=$null;
        resolutionSpecificationSha256='69FD2DADE14A3A3CF52F1DFC20248E1C15D0F58386BB8F5DE9E8C78EDC4454F8';
        coverageCommit='7ccc0f01372276f6bc0b654544c95fc56c7b7086';
        coverageSpecificationSha256='7BBB55F9CC4A3B12483241A78BC5B754F12CD6F22F3AAF48EB72423616B98569';
        registrySha256='8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3';reports=@();
        visualProtocolSha256='6D71DBB461594FE0DD58B1FEB48AD2F3F47AAFF8EE863AE9CB7917167A87DA19';
        trustedVisualAnchorSha256=$null;comparatorImplementationSha256='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA'}
      $kResolutionFixtureBaselineJson=$kResolutionFixtureBaseline|ConvertTo-Json -Compress -Depth 8
      foreach($kResolutionFixtureMode in @('positive','verified','coerced-schema','foreign-pin','claimed-source','claimed-anchor','nonempty-reports','extra-field','missing-field')) {
        & {
          $kResolutionFixtureContext=@{Reads=0;Unexpected=$false}
          $kResolutionFixturePending=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes($kResolutionFixtureBaselineJson))
          switch -CaseSensitive ($kResolutionFixtureMode) {
            'verified' {$kResolutionFixturePending.state='verified'}
            'coerced-schema' {$kResolutionFixturePending.schemaVersion=@(2)}
            'foreign-pin' {$kResolutionFixturePending.visualProtocolSha256='0'*64}
            'claimed-source' {$kResolutionFixturePending.sourceCommit='a'*40}
            'claimed-anchor' {$kResolutionFixturePending.trustedVisualAnchorSha256='F'*64}
            'nonempty-reports' {$kResolutionFixturePending.reports=@([pscustomobject]@{id='labelled fake'})}
            'extra-field' {$kResolutionFixturePending|Add-Member -NotePropertyName unowned -NotePropertyValue $true}
            'missing-field' {$kResolutionFixturePending.PSObject.Properties.Remove('comparatorImplementationSha256')}
          }
          $kResolutionFixtureDocument=$resolutionText.Replace($kResolutionFixtureBlock.Groups[1].Value,($kResolutionFixturePending|ConvertTo-Json -Depth 8 -Compress))
          function Get-OctoberCompatibilityGitLines {
            param([string[]]$Arguments)
            $kResolutionFixtureContext.Reads++
            if(($Arguments -join '|') -cne 'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'){
              $kResolutionFixtureContext.Unexpected=$true;throw 'Unexpected labelled K index read'
            }
            return $kResolutionFixtureDocument
          }
          $kResolutionFixtureResult=Test-OctoberCompatibilityKResolution -FromIndex
          Assert-RepairContract ($kResolutionFixtureResult -eq ($kResolutionFixtureMode -ceq 'positive')) ('K staged resolution result incorrect: '+$kResolutionFixtureMode)
          Assert-RepairContract (-not $kResolutionFixtureContext.Unexpected -and $kResolutionFixtureContext.Reads -eq 3) ('K used wrong source/selection: '+$kResolutionFixtureMode)
        }
      }
      Write-Output 'Compatibility K resolution: 9 labelled staged-read probes passed independently of real preparation/Q state; no staging or source qualification.'
    }
    & {
      # Execute the actual three live dispatch statements, not copied predicates.
      $liveKBlocks=@{}
      foreach($liveKSelection in @(
          @('facts','$compatibilityFacts.KPreparationVerified=Test-OctoberCoverageCartPreparation'),
          @('owner','$octoberCoveragePreservedOwner=@(Get-OctoberCompatibilityHandoverOwners)'),
          @('inventory','K precommit must stage exact metadata4/resolution'))) {
        $liveKNeedle=$liveKSelection[1]
        $liveKNodes=@($ast.FindAll({param($n)
          $n -is [System.Management.Automation.Language.IfStatementAst] -and
          $n.Extent.Text.Contains($liveKNeedle) -and $n.Extent.Text.Length -lt 1500 -and
          ($liveKSelection[0] -cne 'owner' -or (
            $n.Clauses[0].Item1.Extent.Text.Contains('$compatibilityHistory.Stage -eq 5') -and
            $n.Clauses[0].Item1.Extent.Text.Contains('$compatibilityFacts.KPreparationVerified -eq $true')))
        },$true))
        Assert-RepairContract ($liveKNodes.Count -eq 1) ('missing/ambiguous K live block: '+$liveKSelection[0])
        $liveKBlocks[$liveKSelection[0]]=[scriptblock]::Create($liveKNodes[0].Extent.Text)
      }
      $liveKContext=@{Preparation=$true;Resolution=$true;Calls=@();FromIndex=$false}
      function Test-OctoberCoverageCartPreparation {param([string]$Phase)
        $liveKContext.Calls+=@($Phase);return $liveKContext.Preparation}
      function Test-OctoberCompatibilityKResolution {param([switch]$FromIndex)
        $liveKContext.FromIndex=$FromIndex.IsPresent;return $liveKContext.Resolution}
      function Assert-Coordination {param([bool]$Condition,[string]$Message)
        if(-not $Condition){throw $Message}}
      foreach($liveKPhase in @('implementation','pre_commit')) {
        $compatibilityHistory=[pscustomobject]@{Stage=5};$ProductionPhase=$liveKPhase;$compatibilityFacts=@{}
        $liveKContext.Calls=@();$liveKContext.FromIndex=$false
        . $liveKBlocks.facts
        Assert-RepairContract ($compatibilityFacts.KPreparationVerified -eq $true -and
          $compatibilityFacts.KResolutionVerified -eq $true -and
          ($liveKContext.Calls -join '|') -ceq $liveKPhase -and
          $liveKContext.FromIndex -eq ($liveKPhase -ceq 'pre_commit')) 'K live reader selection differs.'
      }
      $octoberCompatibilityIdentity=$true;$compatibilityHistory=[pscustomobject]@{Stage=5}
      $ProductionPhase='pre_commit';$compatibilityFacts=@{KPreparationVerified=$true;KResolutionVerified=$true}
      $liveKStaged=@(Get-OctoberCompatibilityAmendmentOwners)
      $liveKUnstaged=@(Get-OctoberCompatibilityHandoverOwners)
      foreach($liveKMode in @('positive','missing-staged','extra-staged','staged-source','missing-session',
          'buy-dirt','untracked','false-preservation','false-resolution','foreign-identity','stage6')) {
        $preCommitStagedOwners=@($liveKStaged);$preCommitUnstagedOwners=@($liveKUnstaged);$preCommitUntrackedOwners=@()
        $compatibilityHistory.Stage=5;$octoberCompatibilityIdentity=$true
        $compatibilityFacts=@{KPreparationVerified=$true;KResolutionVerified=$true}
        switch($liveKMode) {
          'missing-staged' {$preCommitStagedOwners=@($liveKStaged[0..2])}
          'extra-staged' {$preCommitStagedOwners+=@('extra.txt')}
          'staged-source' {$preCommitStagedOwners+=@($liveKUnstaged[0])}
          'missing-session' {$preCommitUnstagedOwners=@($liveKUnstaged|Where-Object {$_ -cne 'apps/mobile/lib/features/work/work_session.dart'})}
          'buy-dirt' {$preCommitUnstagedOwners+=@('apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart')}
          'untracked' {$preCommitUntrackedOwners=@('extra.txt')}
          'false-preservation' {$compatibilityFacts.KPreparationVerified=$false}
          'false-resolution' {$compatibilityFacts.KResolutionVerified=$false}
          'foreign-identity' {$octoberCompatibilityIdentity=$false}
          'stage6' {$compatibilityHistory.Stage=6}
        }
        $octoberCoveragePreparationPending=$false;$liveKRejected=$false
        try {. $liveKBlocks.inventory} catch {$liveKRejected=$true}
        Assert-RepairContract ($octoberCoveragePreparationPending -eq ($liveKMode -ceq 'positive')) ('K inventory result: '+$liveKMode)
        Assert-RepairContract ($liveKRejected -eq ($liveKMode -cnotin @('positive','foreign-identity','stage6'))) ('K inventory reach: '+$liveKMode)
      }
      foreach($liveKOwnerMode in @('positive','buy','unknown','false-preservation','stage6','foreign-identity','wrong-phase')) {
        $compatibilityHistory.Stage=5;$octoberCompatibilityIdentity=$true;$ProductionPhase='implementation'
        $compatibilityFacts=@{KPreparationVerified=$true};$changedOwner=$liveKUnstaged[0]
        switch($liveKOwnerMode) {
          'buy' {$changedOwner='apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'}
          'unknown' {$changedOwner='extra.dart'}
          'false-preservation' {$compatibilityFacts.KPreparationVerified=$false}
          'stage6' {$compatibilityHistory.Stage=6}
          'foreign-identity' {$octoberCompatibilityIdentity=$false}
          'wrong-phase' {$ProductionPhase='publication'}
        }
        $octoberCoveragePreservedOwner=$false
        . $liveKBlocks.owner
        Assert-RepairContract ($octoberCoveragePreservedOwner -eq ($liveKOwnerMode -ceq 'positive')) ('K owner result: '+$liveKOwnerMode)
      }
      Write-Output 'Compatibility K live dispatch: 20 labelled statement probes passed; no actual staging/admission or app edit.'
    }
    & {
      Assert-RepairContract ((Get-OctoberCompatibilityComparatorIdentity) -ceq 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA') 'actual configured comparator SDK not verified.'
      foreach($sdkFixtureMode in @('positive','wrong-commit','dirty-library','wrong-hash','git-failed')) {
        & {
          $sdkFixtureContext=@{UnexpectedRead=$false}
          function Get-OctoberCompatibilityGitLines {
            param([string[]]$Arguments)
            $sdkFixtureSelection=$Arguments -join '|'
            if($sdkFixtureSelection -cnotin @('-C|C:/Users/jisal/develop/flutter|rev-parse|HEAD',
              '-C|C:/Users/jisal/develop/flutter|status|--porcelain|--untracked-files=all|--|packages/flutter_test/lib')) {
              $sdkFixtureContext.UnexpectedRead=$true;throw 'Unexpected labelled SDK Git selection'
            }
            if($sdkFixtureMode -ceq 'git-failed'){throw 'Labelled SDK Git failure'}
            if($sdkFixtureSelection -ceq '-C|C:/Users/jisal/develop/flutter|rev-parse|HEAD') {
              if($sdkFixtureMode -ceq 'wrong-commit'){return ('0'*40)};return 'ee80f08bbf97172ec030b8751ceab557177a34a6'
            }
            if($sdkFixtureMode -ceq 'dirty-library'){return ' M packages/flutter_test/lib/src/_goldens_io.dart'}
          }
          function Get-OctoberCoverageBoundHash {
            param([string]$Path)
            if(-not [string]::Equals([IO.Path]::GetFullPath($Path),[IO.Path]::GetFullPath('C:/Users/jisal/develop/flutter/packages/flutter_test/lib/src/_goldens_io.dart'),[StringComparison]::OrdinalIgnoreCase)) {
              $sdkFixtureContext.UnexpectedRead=$true;throw 'Unexpected labelled SDK hash path'
            }
            if($sdkFixtureMode -ceq 'wrong-hash'){return ('0'*64)};return 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA'
          }
          $sdkFixtureResult=Get-OctoberCompatibilityComparatorIdentity
          Assert-RepairContract (($null -ne $sdkFixtureResult) -eq ($sdkFixtureMode -ceq 'positive')) ('SDK identity result incorrect: '+$sdkFixtureMode)
          Assert-RepairContract (-not $sdkFixtureContext.UnexpectedRead) ('SDK probe used an unintended query/path: '+$sdkFixtureMode)
        }
      }
      Write-Output 'Compatibility comparator SDK: actual configured identity and5 labelled rejection/positive probes passed; no visual invocation inferred.'
    }
    & {
      foreach($sdkBoundaryFixtureMode in @('positive','before-failed','after-failed','invocation-threw')) {
        & {
          $sdkBoundaryFixtureContext=@{Reads=0;Invocations=0};$sdkBoundaryFixtureReceipt=@{}
          $sdkBoundaryFixtureStarted=[DateTimeOffset]::UtcNow.ToString('o');$sdkBoundaryFixtureThrown=$false
          function Get-OctoberCompatibilityComparatorIdentity {
            $sdkBoundaryFixtureContext.Reads++
            if($sdkBoundaryFixtureMode -ceq 'before-failed'){return $null}
            if($sdkBoundaryFixtureMode -ceq 'after-failed' -and $sdkBoundaryFixtureContext.Reads -eq 2){return ('0'*64)}
            return 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA'
          }
          try {
            Invoke-OctoberCompatibilityComparatorBoundCapture -Receipt $sdkBoundaryFixtureReceipt -Invocation {
              $sdkBoundaryFixtureContext.Invocations++
              if($sdkBoundaryFixtureMode -ceq 'invocation-threw'){throw 'Labelled capture invocation failure'}
            }
          } catch {$sdkBoundaryFixtureThrown=$true}
          $sdkBoundaryFixtureFinished=[DateTimeOffset]::UtcNow.ToString('o')
          Assert-RepairContract ($sdkBoundaryFixtureThrown -eq ($sdkBoundaryFixtureMode -cne 'positive')) ('capture exception boundary incorrect: '+$sdkBoundaryFixtureMode)
          $sdkBoundaryFixtureExpectedReads=if($sdkBoundaryFixtureMode -ceq 'before-failed'){1}else{2}
          $sdkBoundaryFixtureExpectedInvocations=if($sdkBoundaryFixtureMode -ceq 'before-failed'){0}else{1}
          Assert-RepairContract ($sdkBoundaryFixtureContext.Reads -eq $sdkBoundaryFixtureExpectedReads -and
            $sdkBoundaryFixtureContext.Invocations -eq $sdkBoundaryFixtureExpectedInvocations) ('SDK/capture boundary not reached: '+$sdkBoundaryFixtureMode)
          $sdkBoundaryFixtureReceipt.startedAtUtc=$sdkBoundaryFixtureStarted;$sdkBoundaryFixtureReceipt.finishedAtUtc=$sdkBoundaryFixtureFinished
          Assert-RepairContract ((Test-OctoberCompatibilityCaptureComparator ([pscustomobject]$sdkBoundaryFixtureReceipt)) -eq
            ($sdkBoundaryFixtureMode -cin @('positive','invocation-threw'))) ('SDK receipt binding incorrect: '+$sdkBoundaryFixtureMode)
        }
      }
      $sdkShapeFixtureBase=[pscustomobject]@{startedAtUtc='2026-10-10T00:00:00.0000000+00:00';finishedAtUtc='2026-10-10T00:00:03.0000000+00:00';
        comparatorImplementationSha256Before='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA';
        comparatorImplementationSha256After='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA';
        comparatorSdkCommitBefore='ee80f08bbf97172ec030b8751ceab557177a34a6';comparatorSdkCommitAfter='ee80f08bbf97172ec030b8751ceab557177a34a6';
        comparatorCheckedBeforeAtUtc='2026-10-10T00:00:01.0000000+00:00';comparatorCheckedAfterAtUtc='2026-10-10T00:00:02.0000000+00:00'}
      Assert-RepairContract (Test-OctoberCompatibilityCaptureComparator $sdkShapeFixtureBase) 'labelled SDK capture metadata rejected.'
      foreach($sdkShapeFixtureMutation in @(
        @{name='comparatorImplementationSha256Before';value=('0'*64)},@{name='comparatorSdkCommitAfter';value=('0'*40)},
        @{name='comparatorCheckedBeforeAtUtc';value='2026-10-09T00:00:01.0000000+00:00'},
        @{name='comparatorCheckedAfterAtUtc';value='2026-10-11T00:00:02.0000000+00:00'},
        @{name='comparatorCheckedAfterAtUtc';value='2026-10-10T00:00:00.5000000+00:00'},
        @{name='comparatorCheckedBeforeAtUtc';value=[DateTimeOffset]::UtcNow},
        @{name='comparatorCheckedBeforeAtUtc';value='2026-10-10T00:00:01.0000000+05:30'})) {
        $sdkShapeFixtureChanged=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($sdkShapeFixtureBase|ConvertTo-Json -Compress)))
        $sdkShapeFixtureChanged.($sdkShapeFixtureMutation.name)=$sdkShapeFixtureMutation.value
        Assert-RepairContract (-not(Test-OctoberCompatibilityCaptureComparator $sdkShapeFixtureChanged)) ('invalid SDK capture metadata admitted: '+$sdkShapeFixtureMutation.name)
      }
      $sdkShapeFixtureMissing=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($sdkShapeFixtureBase|ConvertTo-Json -Compress)))
      $sdkShapeFixtureMissing.PSObject.Properties.Remove('comparatorImplementationSha256After')
      Assert-RepairContract (-not(Test-OctoberCompatibilityCaptureComparator $sdkShapeFixtureMissing)) 'missing capture SDK identity admitted.'
      Write-Output 'Compatibility capture SDK boundaries: 4 actual host-wrapper probes and9 labelled metadata cases passed; no Flutter or visual acceptance.'
    }
    & {
      function Invoke-LabelledVisualAggregate([string]$Mode) {
        $visualAggregateFixtureRows=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
        foreach($visualAggregateFixtureRow in $resolution.cases){foreach($visualAggregateFixtureSlot in $visualAggregateFixtureRow.comparisonSlots){
          $visualAggregateFixtureRows.Add($visualAggregateFixtureSlot.slotId,@{Row=$visualAggregateFixtureRow;Slot=$visualAggregateFixtureSlot})
        }}
        $visualAggregateFixtureContext=@{Mode=$Mode;TrustReads=0;ExecutionReads=0;SlotReads=0;ManifestReads=@{};
          Leases=[Collections.Generic.List[object]]::new();CurrentExecution='';FinalLogHashReached=$false}
        $visualAggregateFixtureInventory=[Collections.Generic.List[object]]::new()
        foreach($visualAggregateFixtureCategory in @('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')) {
          $visualAggregateFixtureExecutions=if($visualAggregateFixtureCategory -ceq 'store_layout_and_recovery'){
            @('default','localstock_review','workspace_capture','historical_store_review','historical_store_capture','store_live_capture','founder_capture')
          }else{@('default')}
          foreach($visualAggregateFixtureExecution in $visualAggregateFixtureExecutions){
            $visualAggregateFixtureInventory.Add(@{ReportId=$visualAggregateFixtureCategory;ExecutionId=$visualAggregateFixtureExecution;
              Evidence=[pscustomobject]@{path=('apps/mobile/build/labelled-'+$visualAggregateFixtureCategory+'-'+$visualAggregateFixtureExecution+'.jsonl');sha256=('F'*64);
                capturePath=('apps/mobile/build/labelled-'+$visualAggregateFixtureCategory+'-'+$visualAggregateFixtureExecution+'.jsonl.capture.json');captureSha256=('F'*64)}})
          }
        }
        function Get-OctoberCompatibilityQualificationExecutions {
          if($visualAggregateFixtureContext.Mode -ceq 'missing-execution'){return $visualAggregateFixtureInventory.ToArray()[0..8]}
          return $visualAggregateFixtureInventory.ToArray()
        }
        function Read-OctoberCompatibilityTrustedVisualDecisions {
          $visualAggregateFixtureContext.TrustReads++
          if($visualAggregateFixtureContext.Mode -ceq 'missing-trust' -or
              ($visualAggregateFixtureContext.Mode -ceq 'changed-anchor' -and $visualAggregateFixtureContext.TrustReads -eq 2)){return $null}
          $visualAggregateFixtureDecisions=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
          foreach($visualAggregateFixtureId in $visualAggregateFixtureRows.Keys){$visualAggregateFixtureDecisions.Add($visualAggregateFixtureId,[pscustomobject]@{slotId=$visualAggregateFixtureId})}
          if($visualAggregateFixtureContext.Mode -ceq 'foreign-anchor-slot') {
            $visualAggregateFixtureFirst=@($visualAggregateFixtureDecisions.Keys)[0];[void]$visualAggregateFixtureDecisions.Remove($visualAggregateFixtureFirst)
            $visualAggregateFixtureDecisions.Add('H99-visual-1',[pscustomobject]@{slotId='H99-visual-1'})
          }
          return [pscustomobject]@{Decisions=$visualAggregateFixtureDecisions}
        }
        function Read-OctoberCompatibilityExecutionEvidence {
          param([object]$Evidence,[string]$ReportId,[string]$ExecutionId)
          $visualAggregateFixtureContext.ExecutionReads++;$visualAggregateFixtureContext.CurrentExecution=$ExecutionId
          if($visualAggregateFixtureContext.Mode -ceq 'failed-default' -and $ReportId -ceq 'store_layout_and_recovery' -and $ExecutionId -ceq 'default'){return $null}
          $visualAggregateFixtureSuccess=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
          foreach($visualAggregateFixtureRow in $resolution.cases){[void]$visualAggregateFixtureSuccess.Add($visualAggregateFixtureRow.originalKey)}
          if($visualAggregateFixtureContext.Mode -ceq 'missing-original-success'){$visualAggregateFixtureSuccess.Clear()}
          return @{Successes=$visualAggregateFixtureSuccess}
        }
        function Read-OctoberCompatibilityVisualManifestBinding {
          param([object]$Evidence,[string]$ExecutionId,[string]$RecorderBlob,[string[]]$ExpectedSlotIds)
          if(-not $visualAggregateFixtureContext.ManifestReads.ContainsKey($ExecutionId)){$visualAggregateFixtureContext.ManifestReads[$ExecutionId]=0}
          $visualAggregateFixtureContext.ManifestReads[$ExecutionId]++
          if($visualAggregateFixtureContext.Mode -ceq 'missing-manifest' -or $RecorderBlob -cne ('d'*40) -or
              ($visualAggregateFixtureContext.Mode -ceq 'changed-manifest' -and $visualAggregateFixtureContext.ManifestReads[$ExecutionId] -eq 2)){return $null}
          $visualAggregateFixtureEntries=@($ExpectedSlotIds|ForEach-Object {[pscustomobject]@{slotId=$_}})
          if($visualAggregateFixtureContext.Mode -ceq 'duplicate-manifest' -and $visualAggregateFixtureEntries.Count -gt 1){$visualAggregateFixtureEntries[-1].slotId=$visualAggregateFixtureEntries[0].slotId}
          return [pscustomobject]@{entries=$visualAggregateFixtureEntries}
        }
        function Open-OctoberCompatibilityVisualArtifact {
          param([string]$RelativePath)
          if($visualAggregateFixtureContext.Mode -ceq 'missing-log' -and $RelativePath.EndsWith('.jsonl',[StringComparison]::Ordinal)){return $null}
          $visualAggregateFixtureLease=[IO.MemoryStream]::new();$visualAggregateFixtureContext.Leases.Add($visualAggregateFixtureLease)
          $visualAggregateFixtureBuffer=[byte[]]@(1)
          if($RelativePath.EndsWith('.capture.json',[StringComparison]::Ordinal)) {
            $visualAggregateFixtureCapture=[pscustomobject]@{startedAtUtc='2026-10-10T00:00:00.0000000+00:00';finishedAtUtc='2026-10-10T00:00:03.0000000+00:00';
              comparatorImplementationSha256Before='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA';
              comparatorImplementationSha256After='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA';
              comparatorSdkCommitBefore='ee80f08bbf97172ec030b8751ceab557177a34a6';comparatorSdkCommitAfter='ee80f08bbf97172ec030b8751ceab557177a34a6';
              comparatorCheckedBeforeAtUtc='2026-10-10T00:00:01.0000000+00:00';comparatorCheckedAfterAtUtc='2026-10-10T00:00:02.0000000+00:00'}
            if($visualAggregateFixtureContext.Mode -ceq 'missing-capture-sdk'){$visualAggregateFixtureCapture.PSObject.Properties.Remove('comparatorSdkCommitBefore')}
            $visualAggregateFixtureBuffer=[Text.Encoding]::UTF8.GetBytes(($visualAggregateFixtureCapture|ConvertTo-Json -Compress))
          }
          return [pscustomobject]@{Stream=$visualAggregateFixtureLease;Bytes=$visualAggregateFixtureBuffer;CanonicalPath='C:/labelled-host/log.jsonl'}
        }
        function Read-OctoberCompatibilityVisualObservations {
          param([string]$ExecutionId)
          $visualAggregateFixtureObservations=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
          foreach($visualAggregateFixtureId in $visualAggregateFixtureRows.Keys){
            if($visualAggregateFixtureRows[$visualAggregateFixtureId].Row.executionId -ceq $ExecutionId){
              $visualAggregateFixtureObservations.Add($visualAggregateFixtureId,[pscustomobject]@{slotId=$visualAggregateFixtureId})
            }
          }
          if($visualAggregateFixtureContext.Mode -ceq 'missing-observation') {
            [void]$visualAggregateFixtureObservations.Remove(@($visualAggregateFixtureObservations.Keys)[0])
          }
          if($visualAggregateFixtureContext.Mode -ceq 'foreign-observation') {
            [void]$visualAggregateFixtureObservations.Remove(@($visualAggregateFixtureObservations.Keys)[0])
            $visualAggregateFixtureObservations.Add('H99-visual-1',[pscustomobject]@{slotId='H99-visual-1'})
          }
          return [pscustomobject]@{Observations=$visualAggregateFixtureObservations}
        }
        function Test-OctoberCompatibilityVisualSlot {
          param([object]$Evidence,[object]$Slot,[object]$Decision,[object]$Observation,[string]$TestKey,[string]$ExecutionId)
          $visualAggregateFixtureContext.SlotReads++
          return $visualAggregateFixtureContext.Mode -cne 'failed-slot' -and $Evidence.slotId -ceq $Slot.slotId -and
            $Decision.slotId -ceq $Slot.slotId -and $Observation.slotId -ceq $Slot.slotId -and
            $TestKey -ceq $Slot.requiredProof.originalTestKey -and $ExecutionId -ceq $Slot.requiredProof.executionId
        }
        function Get-OctoberCoverageBoundHash {
          $visualAggregateFixtureContext.FinalLogHashReached=$true
          if($visualAggregateFixtureContext.Mode -ceq 'changed-log'){return ('0'*64)};return ('F'*64)
        }
        $visualAggregateFixtureComparator=if($Mode -ceq 'wrong-comparator'){'0'*64}else{'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA'}
        $visualAggregateFixtureRecorder=if($Mode -ceq 'wrong-recorder'){'e'*40}else{'d'*40}
        $visualAggregateFixtureResult=Test-OctoberCompatibilityVisualQualification -Proof ([pscustomobject]@{}) -Resolution $resolution -Protocol $visualProtocol `
          -Source ('a'*40) -Tree ('b'*40) -RegistrySha ('F'*64) -ProducerBlob ('c'*40) -RecorderBlob $visualAggregateFixtureRecorder `
          -ComparatorImplementationSha256 $visualAggregateFixtureComparator -TrustedAnchorSha256 ('F'*64)
        Assert-RepairContract ($visualAggregateFixtureResult -eq ($Mode -ceq 'positive')) ('visual aggregate result incorrect: '+$Mode)
        foreach($visualAggregateFixtureLease in $visualAggregateFixtureContext.Leases){Assert-RepairContract (-not $visualAggregateFixtureLease.CanRead) ('aggregate log lease not disposed: '+$Mode)}
        if($Mode -cin @('positive','changed-anchor')) {
          Assert-RepairContract ($visualAggregateFixtureContext.ExecutionReads -eq 10 -and $visualAggregateFixtureContext.SlotReads -eq 65 -and
            $visualAggregateFixtureContext.TrustReads -eq 2) ('complete65/10/final-anchor boundary not reached: '+$Mode)
        }
        if($Mode -cin @('positive','changed-log')){Assert-RepairContract $visualAggregateFixtureContext.FinalLogHashReached ('final log hash not reached: '+$Mode)}
      }
      foreach($visualAggregateFixtureMode in @('positive','missing-execution','missing-trust','foreign-anchor-slot','failed-default',
        'missing-original-success','missing-manifest','duplicate-manifest','missing-log','missing-observation','foreign-observation',
        'failed-slot','changed-manifest','changed-log','changed-anchor','wrong-comparator','wrong-recorder','missing-capture-sdk')) {
        Invoke-LabelledVisualAggregate $visualAggregateFixtureMode
      }
      Write-Output 'Compatibility complete visual aggregation: 18 labelled in-memory cases passed; exact65/10 composition only, no actual visual/source approval.'
    }
    & {
      $qualificationFixtureResolution=$resolution;$qualificationFixtureProtocol=$visualProtocol
      $qualificationFixtureCoverage=[regex]::Match($resolutionText,'(?s)<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_END -->').Groups[1].Value
      Assert-RepairContract (Test-OctoberCompatibilityCoverageSpecification $qualificationFixtureCoverage) 'qualification fixture lost immutable H specification.'
      foreach($qualificationFixtureMode in @('positive','wrong-source','wrong-tree','wrong-resolution','wrong-coverage','wrong-registry',
        'wrong-resolution-digest','wrong-protocol-digest','wrong-coverage-digest','missing-anchor','failed-sdk','wrong-sdk-proof',
        'missing-recorder','failed-coverage','failed-visual','old-schema1','old-schema2',
        'wrong-test-admission','wrong-test-admission-digest','missing-committed-N','working-positive','working-missing-proof')) {
        & {
          $qualificationFixtureContext=@{Mode=$qualificationFixtureMode;CoverageReached=$false;VisualReached=$false;UnexpectedRead=$false}
          $qualificationFixtureProof=[pscustomobject]@{schemaVersion=3;state='verified';sourceCommit=('a'*40);sourceTree=('b'*40);
            resolutionCommit=('c'*40);coverageCommit='7ccc0f01372276f6bc0b654544c95fc56c7b7086';
            testAdmissionCommit=('9'*40);testAdmissionSpecificationSha256='A27A195444E4295FA218F549EC4D978AF77605AA344C35B7D3A44CE783EAA889';
            coverageSpecificationSha256='7BBB55F9CC4A3B12483241A78BC5B754F12CD6F22F3AAF48EB72423616B98569';
            resolutionSpecificationSha256='69FD2DADE14A3A3CF52F1DFC20248E1C15D0F58386BB8F5DE9E8C78EDC4454F8';
            visualProtocolSha256='6D71DBB461594FE0DD58B1FEB48AD2F3F47AAFF8EE863AE9CB7917167A87DA19';
            registrySha256='8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3';
            trustedVisualAnchorSha256=('F'*64);comparatorImplementationSha256='A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA';reports=@()}
          switch -CaseSensitive ($qualificationFixtureMode) {
            'wrong-source' {$qualificationFixtureProof.sourceCommit='0'*40}
            'wrong-tree' {$qualificationFixtureProof.sourceTree='0'*40}
            'wrong-resolution' {$qualificationFixtureProof.resolutionCommit='0'*40}
            'wrong-coverage' {$qualificationFixtureProof.coverageCommit='0'*40}
            'wrong-registry' {$qualificationFixtureProof.registrySha256='0'*64}
            'wrong-resolution-digest' {$qualificationFixtureProof.resolutionSpecificationSha256='0'*64}
            'wrong-protocol-digest' {$qualificationFixtureProof.visualProtocolSha256='0'*64}
            'wrong-coverage-digest' {$qualificationFixtureProof.coverageSpecificationSha256='0'*64}
            'missing-anchor' {$qualificationFixtureProof.PSObject.Properties.Remove('trustedVisualAnchorSha256')}
            'wrong-sdk-proof' {$qualificationFixtureProof.comparatorImplementationSha256='0'*64}
            'old-schema1' {$qualificationFixtureProof.schemaVersion=1}
            'old-schema2' {$qualificationFixtureProof.schemaVersion=2}
            'wrong-test-admission' {$qualificationFixtureProof.testAdmissionCommit='0'*40}
            'wrong-test-admission-digest' {$qualificationFixtureProof.testAdmissionSpecificationSha256='0'*64}
          }
          $qualificationFixtureDoc='<!-- COMPATIBILITY_QUALIFICATION_JSON_BEGIN -->'+($qualificationFixtureProof|ConvertTo-Json -Compress -Depth 8)+'<!-- COMPATIBILITY_QUALIFICATION_JSON_END -->'
          $qualificationFixtureWorking=$qualificationFixtureMode.StartsWith('working-')
          if($qualificationFixtureWorking) {
            $qualificationFixtureWorkingPath=Join-Path $root ('apps/mobile/build/qualification-working-'+[Guid]::NewGuid().ToString('N')+'.fixture.md')
            $qualificationFixtureContents=if($qualificationFixtureMode -ceq 'working-missing-proof'){'Missing working qualification block'}else{$qualificationFixtureDoc}
            [IO.File]::WriteAllText($qualificationFixtureWorkingPath,$qualificationFixtureContents,[Text.UTF8Encoding]::new($false))
            $qualificationFixtureContext.WorkingRead=$false
            function Join-Path {
              param([string]$Path,[string]$ChildPath)
              if(@(Get-PSCallStack)[1].FunctionName -ceq 'Test-OctoberCompatibilityQualification' -and
                  $Path -ceq $root -and $ChildPath -ceq 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md') {
                $qualificationFixtureContext.WorkingRead=$true;return $qualificationFixtureWorkingPath
              }
              $qualificationFixtureContext.UnexpectedRead=$true;throw 'Unexpected working qualification path query'
            }
          }
          function Get-OctoberCompatibilityGitLines {
            param([string[]]$Arguments)
            $qualificationFixtureSelection=$Arguments -join '|'
            switch -CaseSensitive ($qualificationFixtureSelection) {
              ('rev-parse|'+('a'*40)+'^{tree}') {return ('b'*40)}
              ('rev-parse|'+('a'*40)+':scripts/test-codex-integration-repair-coordination-policy.ps1') {return ('d'*40)}
              ('rev-parse|'+('a'*40)+':apps/mobile/test/work_workspace_layout_safety_test.dart') {
                if($qualificationFixtureContext.Mode -ceq 'missing-recorder'){return};return ('e'*40)
              }
              ('show|'+('f'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md') {return $qualificationFixtureDoc}
              ('show|'+('9'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md') {
                if($qualificationFixtureContext.Mode -ceq 'missing-committed-N'){return 'Missing committed N contract'}
                return $resolutionText
              }
              'show|7ccc0f01372276f6bc0b654544c95fc56c7b7086:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md' {
                return '<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_BEGIN -->'+$qualificationFixtureCoverage+'<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_END -->'
              }
              default {$qualificationFixtureContext.UnexpectedRead=$true;throw 'Unexpected labelled qualification Git selection'}
            }
          }
          function Get-OctoberCompatibilityResolutionSpecification {
            param([string]$Commit)
            if($Commit -cne ('c'*40)){return $null};return $qualificationFixtureResolution
          }
          function Get-OctoberCompatibilityVisualProtocol {
            param([string]$Commit)
            if($Commit -cne ('c'*40)){return $null};return $qualificationFixtureProtocol
          }
          function Read-OctoberCompatibilityExecutionCoverage {
            param([object]$Proof,[string]$CoverageJson,[string]$Source,[string]$Tree,[string]$RegistrySha,[string]$ProducerBlob)
            $qualificationFixtureContext.CoverageReached=$true
            if($qualificationFixtureContext.Mode -ceq 'failed-coverage' -or -not(Test-OctoberCompatibilityCoverageSpecification $CoverageJson) -or
              $Source -cne ('a'*40) -or $Tree -cne ('b'*40) -or $ProducerBlob -cne ('d'*40) -or
              $RegistrySha -cne '8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3'){return $null}
            return @{VerifiedExecutions=10}
          }
          function Get-OctoberCompatibilityComparatorIdentity {
            if($qualificationFixtureContext.Mode -ceq 'failed-sdk'){return $null};return 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA'
          }
          function Test-OctoberCompatibilityVisualQualification {
            param([object]$Proof,[object]$Resolution,[object]$Protocol,[string]$Source,[string]$Tree,
              [string]$RegistrySha,[string]$ProducerBlob,[string]$RecorderBlob,[string]$ComparatorImplementationSha256,[string]$TrustedAnchorSha256)
            $qualificationFixtureContext.VisualReached=$true
            return $qualificationFixtureContext.Mode -cne 'failed-visual' -and $Resolution.cases.Count -eq 84 -and $Protocol.decisionCount -eq 65 -and
              $Source -ceq ('a'*40) -and $Tree -ceq ('b'*40) -and $ProducerBlob -ceq ('d'*40) -and $RecorderBlob -ceq ('e'*40) -and
              $RegistrySha -ceq '8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3' -and
              $ComparatorImplementationSha256 -ceq 'A17532A2EC45F463BCDD5966FD0FB7EED13573F6550A866A77D16068B32478BA' -and $TrustedAnchorSha256 -ceq ('F'*64)
          }
          $qualificationFixtureHistory=@{Stage=11;Head=('f'*40);Commits=@(('1'*40),('2'*40),('3'*40),
            '7ccc0f01372276f6bc0b654544c95fc56c7b7086','84b889430abb84e67ea1cf3838c63841429f7712',('c'*40),('6'*40),
            '0da3630d1c857390c173ec83ba5c0210cb1e5ec2',('9'*40),('a'*40),('f'*40))}
          if($qualificationFixtureWorking) {
            $qualificationFixtureHistory.Stage=10;$qualificationFixtureHistory.Commits=@($qualificationFixtureHistory.Commits|Select-Object -First 10)
            $qualificationFixtureHistory.Head='a'*40
          }
          $qualificationFixtureResult=Test-OctoberCompatibilityQualification $qualificationFixtureHistory -FromWorkingTree:$qualificationFixtureWorking
          Assert-RepairContract ($qualificationFixtureResult -eq ($qualificationFixtureMode -cin @('positive','working-positive'))) ('concrete Q conjunction result incorrect: '+$qualificationFixtureMode)
          Assert-RepairContract (-not $qualificationFixtureContext.UnexpectedRead) ('Q rejection masked unintended Git read: '+$qualificationFixtureMode)
          if($qualificationFixtureWorking){Assert-RepairContract $qualificationFixtureContext.WorkingRead 'Working Q branch did not read its isolated fixture file.'}
          if($qualificationFixtureMode -ceq 'working-missing-proof') {
            Assert-RepairContract (-not $qualificationFixtureContext.CoverageReached -and
              -not $qualificationFixtureContext.VisualReached) 'Missing working proof reached downstream qualification.'
          }
          if($qualificationFixtureMode -cin @('positive','working-positive','failed-coverage','failed-visual')) {
            Assert-RepairContract $qualificationFixtureContext.CoverageReached ('Q coverage boundary not reached: '+$qualificationFixtureMode)
          }
          if($qualificationFixtureMode -cin @('positive','working-positive','failed-visual')) {
            Assert-RepairContract $qualificationFixtureContext.VisualReached ('Q visual conjunction not reached: '+$qualificationFixtureMode)
          }
        }
      }
      Write-Output 'Compatibility concrete Q conjunction: 22 labelled cases passed; committed N and isolated stage10 working-proof branch included, no real graph, capture, approval or source qualified.'
    }
    & {
      $observationFixtureSource='a'*40;$observationFixtureTree='b'*40
      $observationFixtureComparator='C'*64
      $observationFixtureKey='work_workspace_layout_safety_test.dart:labelled observation fixture'
      $observationFixtureKeys=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
      [void]$observationFixtureKeys.Add($observationFixtureKey)
      $observationFixtureRow=[ordered]@{schemaVersion=1;sourceCommit=$observationFixtureSource;sourceTree=$observationFixtureTree;
        executionId='default';testKey=$observationFixtureKey;slotId='H01-visual-1';captureTarget='labelled root';
        viewportWidth=412;viewportHeight=915;devicePixelRatio=1;textScale=1;bottomViewPadding=34;bottomViewInsets=0;
        captureLogicalBounds=@{left=0;top=0;right=412;bottom=915};renderedPixelWidth=412;renderedPixelHeight=915;
        actualRenderSha256=('D'*64);referenceSha256Before=('E'*64);referenceSha256After=('E'*64);
        comparatorIdentity='flutter_test.LocalFileComparator';comparatorImplementationSha256=$observationFixtureComparator;
        comparatorInvoked=$true;comparisonPassed=$true}
      function Invoke-LabelledObservationRead([object]$Row,[int]$PrintTestId=7,[bool]$Duplicate=$false,[bool]$IncludeStart=$true,[bool]$CompletedBeforePrint=$false) {
        $observationFixtureLines=[Collections.Generic.List[string]]::new()
        $observationFixtureLines.Add((@{type='suite';suite=@{id=3;path=($binding.worktreePath+'/apps/mobile/test/work_workspace_layout_safety_test.dart')}}|ConvertTo-Json -Compress -Depth 8))
        if($IncludeStart){$observationFixtureLines.Add((@{type='testStart';test=@{id=7;suiteID=3;name='labelled observation fixture'}}|ConvertTo-Json -Compress -Depth 8))}
        if($CompletedBeforePrint){$observationFixtureLines.Add((@{type='testDone';testID=7;result='success';skipped=$false;hidden=$false}|ConvertTo-Json -Compress))}
        $observationFixturePrint=@{type='print';testID=$PrintTestId;message=($visualProtocol.observationPrefix+($Row|ConvertTo-Json -Compress -Depth 8))}|ConvertTo-Json -Compress -Depth 10
        $observationFixtureLines.Add($observationFixturePrint)
        if($Duplicate){$observationFixtureLines.Add($observationFixturePrint)}
        return Read-OctoberCompatibilityVisualObservations -LogBytes ([Text.Encoding]::UTF8.GetBytes($observationFixtureLines -join "`n")) -Protocol $visualProtocol -Source $observationFixtureSource -Tree $observationFixtureTree -ExecutionId default -ComparatorImplementationSha256 $observationFixtureComparator -SuccessfulKeys $observationFixtureKeys
      }
      $observationFixtureResult=Invoke-LabelledObservationRead $observationFixtureRow
      Assert-RepairContract ($null -ne $observationFixtureResult -and $observationFixtureResult.Observations.Count -eq 1) 'source/test-bound labelled observation rejected.'
      foreach($observationFixtureMutation in @(
        @{name='sourceCommit';value=('f'*40)},@{name='sourceTree';value=('f'*40)},
        @{name='testKey';value='other test'},@{name='executionId';value='other execution'},
        @{name='comparatorImplementationSha256';value=('F'*64)},
        @{name='comparatorInvoked';value=$false},@{name='comparisonPassed';value=$false},
        @{name='referenceSha256After';value=('F'*64)},@{name='comparatorInvoked';value='true'})) {
        $observationFixtureChanged=[ordered]@{}
        foreach($observationFixtureName in $observationFixtureRow.Keys){$observationFixtureChanged[$observationFixtureName]=$observationFixtureRow[$observationFixtureName]}
        $observationFixtureChanged[$observationFixtureMutation.name]=$observationFixtureMutation.value
        Assert-RepairContract ($null -eq (Invoke-LabelledObservationRead $observationFixtureChanged)) ('observation mutation admitted: '+$observationFixtureMutation.name)
      }
      Assert-RepairContract ($null -eq (Invoke-LabelledObservationRead $observationFixtureRow -PrintTestId 8)) 'unknown running test admitted.'
      Assert-RepairContract ($null -eq (Invoke-LabelledObservationRead $observationFixtureRow -IncludeStart $false)) 'observation without test start admitted.'
      Assert-RepairContract ($null -eq (Invoke-LabelledObservationRead $observationFixtureRow -Duplicate $true)) 'duplicate observation slot admitted.'
      Assert-RepairContract ($null -eq (Invoke-LabelledObservationRead $observationFixtureRow -CompletedBeforePrint $true)) 'observation after successful test completion admitted.'
      Write-Output 'Compatibility visual observations: 14 labelled in-memory checks passed; no real render/comparator or visual acceptance claimed.'
    }
    & {
      Add-Type -AssemblyName System.Drawing
      $pngFixtureBitmap=[Drawing.Bitmap]::new(2,2,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
      $pngFixtureRgb=[Drawing.Bitmap]::new(2,2,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
      function Get-LabelledImageBuffer([Drawing.Bitmap]$Bitmap,[Drawing.Imaging.ImageFormat]$Format) {
        $imageBuffer=[IO.MemoryStream]::new()
        try{$Bitmap.Save($imageBuffer,$Format);return [pscustomobject]@{Bytes=$imageBuffer.ToArray()}}
        finally{$imageBuffer.Dispose()}
      }
      try {
        $pngFixtureBitmap.SetPixel(0,0,[Drawing.Color]::FromArgb(255,255,0,0))
        $pngFixtureBitmap.SetPixel(1,0,[Drawing.Color]::FromArgb(255,0,255,0))
        $pngFixtureBitmap.SetPixel(0,1,[Drawing.Color]::FromArgb(255,0,0,255))
        $pngFixtureBitmap.SetPixel(1,1,[Drawing.Color]::FromArgb(128,10,20,30))
        $pngFixtureReference=(Get-LabelledImageBuffer $pngFixtureBitmap ([Drawing.Imaging.ImageFormat]::Png)).Bytes
        $pngFixtureDecoded=Read-OctoberCompatibilityPngPixels -Bytes $pngFixtureReference -ExpectedWidth 2 -ExpectedHeight 2
        $pngFixtureExpected=@(255,0,0,255,0,255,0,255,0,0,255,255,10,20,30,128)
        Assert-RepairContract ($null -ne $pngFixtureDecoded -and $pngFixtureDecoded.Representation -ceq 'independent_rgba8888_straight' -and
          $pngFixtureDecoded.Pixels.Length -eq 16 -and (@($pngFixtureDecoded.Pixels) -join '|') -ceq ($pngFixtureExpected -join '|')) 'known RGBA/row/channel pixels decoded incorrectly.'
        Assert-RepairContract (Test-OctoberCompatibilityPngEquality $pngFixtureReference $pngFixtureReference 2 2) 'identical decoded PNG rejected.'
        $pngFixtureBitmap.SetPixel(0,0,[Drawing.Color]::FromArgb(255,254,0,0))
        $pngFixtureChanged=(Get-LabelledImageBuffer $pngFixtureBitmap ([Drawing.Imaging.ImageFormat]::Png)).Bytes
        Assert-RepairContract (-not(Test-OctoberCompatibilityPngEquality $pngFixtureReference $pngFixtureChanged 2 2)) 'single colour byte difference ignored.'
        $pngFixtureBitmap.SetPixel(0,0,[Drawing.Color]::FromArgb(255,255,0,0))
        $pngFixtureBitmap.SetPixel(1,1,[Drawing.Color]::FromArgb(127,10,20,30))
        $pngFixtureChanged=(Get-LabelledImageBuffer $pngFixtureBitmap ([Drawing.Imaging.ImageFormat]::Png)).Bytes
        Assert-RepairContract (-not(Test-OctoberCompatibilityPngEquality $pngFixtureReference $pngFixtureChanged 2 2)) 'alpha difference ignored.'
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityPngPixels -Bytes $pngFixtureReference[0..31] -ExpectedWidth 2 -ExpectedHeight 2)) 'truncated header admitted.'
        $pngFixtureBmp=(Get-LabelledImageBuffer $pngFixtureBitmap ([Drawing.Imaging.ImageFormat]::Bmp)).Bytes
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityPngPixels -Bytes $pngFixtureBmp -ExpectedWidth 2 -ExpectedHeight 2)) 'non-PNG image admitted.'
        $pngFixtureUnsupported=[byte[]]$pngFixtureReference.Clone();$pngFixtureUnsupported[24]=16
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityPngPixels -Bytes $pngFixtureUnsupported -ExpectedWidth 2 -ExpectedHeight 2)) 'unsupported bit depth admitted.'
        Assert-RepairContract (-not(Test-OctoberCompatibilityPngEquality $pngFixtureReference $pngFixtureReference 3 2)) 'wrong expected dimensions rescued by resize.'
        & {
          $pngLimitHeader=[byte[]]$pngFixtureReference.Clone()
          $pngLimitHeader[16]=0;$pngLimitHeader[17]=0;$pngLimitHeader[18]=32;$pngLimitHeader[19]=0
          $pngLimitHeader[20]=0;$pngLimitHeader[21]=0;$pngLimitHeader[22]=32;$pngLimitHeader[23]=0
          $pngLimitProbe=@{DecoderSetupReached=$false}
          function Add-Type {$pngLimitProbe.DecoderSetupReached=$true;throw 'Labelled decoder-entry sentinel'}
          $pngLimitResult=Read-OctoberCompatibilityPngPixels -Bytes $pngLimitHeader -ExpectedWidth 8192 -ExpectedHeight 8192
          Assert-RepairContract ($null -eq $pngLimitResult -and -not $pngLimitProbe.DecoderSetupReached) 'pixel resource limit did not reject before decoder setup.'
        }
        Assert-RepairContract (-not(Test-OctoberCompatibilityPngEquality $null $pngFixtureReference 2 2)) 'missing image admitted.'
        $pngFixtureRgb.SetPixel(0,0,[Drawing.Color]::FromArgb(1,2,3))
        $pngFixtureRgbBytes=(Get-LabelledImageBuffer $pngFixtureRgb ([Drawing.Imaging.ImageFormat]::Png)).Bytes
        $pngFixtureRgbDecoded=Read-OctoberCompatibilityPngPixels -Bytes $pngFixtureRgbBytes -ExpectedWidth 2 -ExpectedHeight 2
        Assert-RepairContract ($null -ne $pngFixtureRgbDecoded -and ($pngFixtureRgbDecoded.Pixels[0..3] -join '|') -ceq '1|2|3|255') 'RGB PNG did not decode to exact opaque RGBA.'
        & {
          $leaseFixtureTempBase=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
          $leaseFixtureDirectory=[IO.Path]::Combine($leaseFixtureTempBase,('mool-visual-lease-fixture-'+[guid]::NewGuid().ToString('N')))
          [void][IO.Directory]::CreateDirectory($leaseFixtureDirectory)
          $leaseFixtureHeld=$null
          try {
            $leaseFixtureReference=[IO.Path]::Combine($leaseFixtureDirectory,'reference.png')
            $leaseFixtureActual=[IO.Path]::Combine($leaseFixtureDirectory,'actual.png')
            $leaseFixtureChanged=[IO.Path]::Combine($leaseFixtureDirectory,'changed.png')
            [IO.File]::WriteAllBytes($leaseFixtureReference,$pngFixtureReference)
            [IO.File]::WriteAllBytes($leaseFixtureActual,$pngFixtureReference)
            [IO.File]::WriteAllBytes($leaseFixtureChanged,$pngFixtureChanged)
            $leaseFixtureHash=Get-OctoberCompatibilityByteHash $pngFixtureReference
            $leaseFixtureChangedHash=Get-OctoberCompatibilityByteHash $pngFixtureChanged
            Assert-RepairContract (Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png $leaseFixtureHash $leaseFixtureDirectory actual.png $leaseFixtureHash 2 2) 'distinct identical locked PNG files rejected.'
            Assert-RepairContract (-not(Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png $leaseFixtureHash $leaseFixtureDirectory reference.png $leaseFixtureHash 2 2)) 'same artifact used as reference and render.'
            [void](New-Item -ItemType HardLink -Path ([IO.Path]::Combine($leaseFixtureDirectory,'alias.png')) -Value $leaseFixtureReference)
            $leaseFixtureOriginalIdentity=$null;$leaseFixtureAliasIdentity=$null
            try {
              $leaseFixtureOriginalIdentity=Open-OctoberCompatibilityVisualArtifact $leaseFixtureDirectory reference.png $leaseFixtureHash
              $leaseFixtureAliasIdentity=Open-OctoberCompatibilityVisualArtifact $leaseFixtureDirectory alias.png $leaseFixtureHash
              Assert-RepairContract ($null -ne $leaseFixtureOriginalIdentity -and $null -ne $leaseFixtureAliasIdentity -and
                $leaseFixtureOriginalIdentity.CanonicalPath -cne $leaseFixtureAliasIdentity.CanonicalPath -and
                $leaseFixtureOriginalIdentity.FileIdentity -ceq $leaseFixtureAliasIdentity.FileIdentity) 'hardlink fixture did not reach two distinct-path leases with equal Windows identity.'
            } finally {
              try {if($null -ne $leaseFixtureAliasIdentity){$leaseFixtureAliasIdentity.Stream.Dispose()}}
              finally {if($null -ne $leaseFixtureOriginalIdentity){$leaseFixtureOriginalIdentity.Stream.Dispose()}}
            }
            Assert-RepairContract (-not(Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png $leaseFixtureHash $leaseFixtureDirectory alias.png $leaseFixtureHash 2 2)) 'reference/render hardlink alias admitted.'
            Assert-RepairContract (-not(Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png $leaseFixtureHash $leaseFixtureDirectory missing.png $leaseFixtureHash 2 2)) 'missing actual artifact admitted.'
            Assert-RepairContract (-not(Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png ('F'*64) $leaseFixtureDirectory actual.png $leaseFixtureHash 2 2)) 'incorrect bound reference hash admitted.'
            Assert-RepairContract (-not(Test-OctoberCompatibilityLockedPngPair $leaseFixtureDirectory reference.png $leaseFixtureHash $leaseFixtureDirectory changed.png $leaseFixtureChangedHash 2 2)) 'different pixels admitted by locked pair.'
            $leaseFixtureHeld=Open-OctoberCompatibilityVisualArtifact $leaseFixtureDirectory reference.png $leaseFixtureHash
            Assert-RepairContract ($null -ne $leaseFixtureHeld -and $leaseFixtureHeld.Stream.CanRead) 'read lease unavailable.'
            $leaseFixtureWriterBlocked=$false
            try {$leaseFixtureWriter=[IO.File]::Open($leaseFixtureReference,[IO.FileMode]::Open,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite);$leaseFixtureWriter.Dispose()}
            catch [IO.IOException] {$leaseFixtureWriterBlocked=$true}
            Assert-RepairContract $leaseFixtureWriterBlocked 'reference writer not excluded during held lease.'
            $leaseFixtureDeleteBlocked=$false
            try {[IO.File]::Delete($leaseFixtureReference)}catch [IO.IOException] {$leaseFixtureDeleteBlocked=$true}
            Assert-RepairContract $leaseFixtureDeleteBlocked 'reference deletion not excluded during held lease.'
            $leaseFixtureHeld.Stream.Dispose();$leaseFixtureHeld=$null
            $leaseFixtureExclusive=[IO.File]::Open($leaseFixtureReference,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
            try {Assert-RepairContract $leaseFixtureExclusive.CanWrite 'lease not released after comparison.'}finally{$leaseFixtureExclusive.Dispose()}
            $leaseFixtureOversizedPath=[IO.Path]::Combine($leaseFixtureDirectory,'oversized.bin')
            $leaseFixtureOversizedStream=[IO.File]::Open($leaseFixtureOversizedPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try {$leaseFixtureOversizedStream.SetLength(67108865)}finally{$leaseFixtureOversizedStream.Dispose()}
            & {
              $leaseFixtureLimitProbe=@{HashReached=$false}
              function Get-OctoberCoverageBoundHash {$leaseFixtureLimitProbe.HashReached=$true;throw 'Labelled pre-buffer hash sentinel'}
              $leaseFixtureLimitResult=Open-OctoberCompatibilityVisualArtifact $leaseFixtureDirectory oversized.bin ('F'*64)
              Assert-RepairContract ($null -eq $leaseFixtureLimitResult -and -not $leaseFixtureLimitProbe.HashReached) 'oversized artifact did not reject before hash/buffer allocation.'
            }
          } finally {
            try {if($null -ne $leaseFixtureHeld){$leaseFixtureHeld.Stream.Dispose()}}
            finally {
              $leaseFixtureResolved=[IO.Path]::GetFullPath($leaseFixtureDirectory)
              $leaseFixturePrefix=$leaseFixtureTempBase.TrimEnd([char[]]@('\','/'))+[IO.Path]::DirectorySeparatorChar
              if(-not $leaseFixtureResolved.StartsWith($leaseFixturePrefix,[StringComparison]::OrdinalIgnoreCase) -or
                  [IO.Path]::GetFileName($leaseFixtureResolved) -cnotmatch '\Amool-visual-lease-fixture-[0-9a-f]{32}\z'){throw 'Unsafe fixture cleanup target.'}
              Remove-Item -LiteralPath $leaseFixtureResolved -Recurse -Force
            }
          }
          Write-Output 'Compatibility locked PNG pairs: 12 labelled temporary-file checks passed; fixtures removed, no reference approval or visual acceptance.'
        }
      }finally{$pngFixtureBitmap.Dispose();$pngFixtureRgb.Dispose()}
      Write-Output 'Compatibility independent PNG pixels: 11 labelled in-memory checks passed; not Flutter comparator invocation or visual acceptance.'
    }
    & {
      $approvalFixtureSource='a'*40;$approvalFixtureTree='b'*40
      $approvalFixtureResolution=$resolution;$approvalFixtureProtocol=$visualProtocol
      $approvalFixtureFounderText='labelled-host-founder-message-no-human-approval'
      $approvalFixtureFounderBytes=[Text.Encoding]::UTF8.GetBytes($approvalFixtureFounderText)
      $approvalFixtureFounderHash=Get-OctoberCompatibilityByteHash $approvalFixtureFounderBytes
      $approvalFixtureRows=[Collections.Generic.List[object]]::new()
      foreach($fixtureRow in $approvalFixtureResolution.cases){foreach($fixtureSlot in $fixtureRow.comparisonSlots){
        $approvalFixtureRows.Add([pscustomobject]@{slotId=$fixtureSlot.slotId;testKey=$fixtureRow.originalKey;
          executionId=$fixtureRow.executionId;captureTarget=$fixtureSlot.captureTarget;
          sourceCommit=$approvalFixtureSource;sourceTree=$approvalFixtureTree;
          referencePath=$fixtureSlot.approvedAlternativePath;referenceSha256=('d'*64).ToUpperInvariant();
          actualRenderSha256=('e'*64).ToUpperInvariant();approvalRecordPath=$fixtureSlot.approvalRecordRelativePath;
          approvalRecordSha256=('f'*64).ToUpperInvariant();founderMessageLocator=$approvalFixtureFounderText;
          decision=$approvalFixtureProtocol.decision;geometry=$fixtureSlot.expectedGeometry})
      }}
      $approvalFixtureBase=[pscustomobject]@{schemaVersion=1;state=$approvalFixtureProtocol.anchorState;
        writerRole='primary';writerTask='/root';sourceCommit=$approvalFixtureSource;sourceTree=$approvalFixtureTree;
        authoritySha256='3D9F45EFE4EBC751B72FB62887463973B4DE74973B4A010C9203BFE68918FCC2';
        founderEvidenceSha256=$approvalFixtureFounderHash;decisions=$approvalFixtureRows.ToArray()}
      $approvalFixtureModes=@('positive','missing-anchor','pending','coerced-state','wrong-source','wrong-tree',
        'missing-slot','duplicate-slot','wrong-key','wrong-reference','coerced-geometry','missing-locator',
        'extra-field','rejected-decision','anchor-changes')
      foreach($approvalFixtureMode in $approvalFixtureModes) {
        $approvalFixtureAnchor=(ConvertTo-Json -InputObject $approvalFixtureBase -Depth 18)|ConvertFrom-Json
        switch($approvalFixtureMode){
          'pending' {$approvalFixtureAnchor.state='pending'}
          'coerced-state' {$approvalFixtureAnchor.state=@($approvalFixtureProtocol.anchorState)}
          'wrong-source' {$approvalFixtureAnchor.sourceCommit='0'*40}
          'wrong-tree' {$approvalFixtureAnchor.sourceTree='0'*40}
          'missing-slot' {$approvalFixtureAnchor.decisions=@($approvalFixtureAnchor.decisions[0..63])}
          'duplicate-slot' {$approvalFixtureAnchor.decisions[64]=$approvalFixtureAnchor.decisions[0]}
          'wrong-key' {$approvalFixtureAnchor.decisions[0].testKey='labelled wrong original key'}
          'wrong-reference' {$approvalFixtureAnchor.decisions[0].referencePath='labelled-other.png'}
          'coerced-geometry' {$approvalFixtureAnchor.decisions[0].geometry.viewportWidth='412'}
          'missing-locator' {$approvalFixtureAnchor.decisions[0].founderMessageLocator='labelled-missing-founder-message'}
          'extra-field' {$approvalFixtureAnchor.decisions[0]|Add-Member -NotePropertyName extra -NotePropertyValue 1}
          'rejected-decision' {$approvalFixtureAnchor.decisions[0].decision='rejected'}
        }
        $approvalFixtureAnchorBytes=[Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $approvalFixtureAnchor -Depth 18 -Compress))
        $approvalFixtureAnchorHash=Get-OctoberCompatibilityByteHash $approvalFixtureAnchorBytes
        $script:approvalFixtureReadCount=0;$script:approvalFixtureUnexpected=$false;$script:approvalFixtureChangedReached=$false
        & {
          function Read-OctoberCompatibilityVisualArtifactBytes([string]$Base,[string]$RelativePath,[string]$ExpectedSha256) {
            $script:approvalFixtureReadCount++
            if($Base -cne 'C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store'){
              $script:approvalFixtureUnexpected=$true;throw 'unexpected labelled approval root'
            }
            if($RelativePath -ceq 'work/compatibility-visual-founder-decisions-20261010.json' -and $ExpectedSha256 -ceq $approvalFixtureAnchorHash) {
              if($approvalFixtureMode -ceq 'missing-anchor'){return $null}
              return [pscustomobject]@{Bytes=$approvalFixtureAnchorBytes;CanonicalPath=$approvalFixtureProtocol.trustedAnchorPath}
            }
            if($RelativePath -ceq 'outputs/compatibility-visual-founder-review-20261010.md' -and $ExpectedSha256 -ceq $approvalFixtureFounderHash) {
              return [pscustomobject]@{Bytes=$approvalFixtureFounderBytes;CanonicalPath=$approvalFixtureProtocol.founderEvidencePath}
            }
            $script:approvalFixtureUnexpected=$true;throw 'unexpected labelled approval artifact'
          }
          function Get-OctoberCoverageBoundHash([string]$Path) {
            if($Path -ceq $approvalFixtureProtocol.trustedAnchorPath) {
              if($approvalFixtureMode -ceq 'anchor-changes'){$script:approvalFixtureChangedReached=$true;return ('0'*64)}
              return $approvalFixtureAnchorHash
            }
            if($Path -ceq $approvalFixtureProtocol.founderEvidencePath){return $approvalFixtureFounderHash}
            $script:approvalFixtureUnexpected=$true;throw 'unexpected labelled approval hash'
          }
          $approvalFixtureResult=Read-OctoberCompatibilityTrustedVisualDecisions -Resolution $approvalFixtureResolution `
            -Protocol $approvalFixtureProtocol -Source $approvalFixtureSource -Tree $approvalFixtureTree -ExpectedAnchorSha256 $approvalFixtureAnchorHash
          if($approvalFixtureMode -ceq 'positive') {
            Assert-RepairContract ($null -ne $approvalFixtureResult -and $approvalFixtureResult.Decisions.Count -eq 65) 'labelled complete approval bindings rejected.'
          }else{Assert-RepairContract ($null -eq $approvalFixtureResult) 'invalid labelled approval bindings admitted.'}
          Assert-RepairContract ($script:approvalFixtureReadCount -gt 0 -and -not $script:approvalFixtureUnexpected) 'approval fixture failed before intended source or read unbound input.'
          if($approvalFixtureMode -ceq 'anchor-changes'){Assert-RepairContract $script:approvalFixtureChangedReached 'approval final hash boundary not reached.'}
        }
      }
      Remove-Variable -Name approvalFixtureReadCount,approvalFixtureUnexpected,approvalFixtureChangedReached -Scope Script
      Write-Output 'Compatibility trusted decision bindings: 15 labelled in-memory cases passed; no founder decisions/files or visual approvals created.'
    }
    $resolutionCases=2
    foreach($changed in @($null,$true,'{}',($resolutionJson+' ' + '{}'),
        $resolutionJson.Replace('same_original_key_only_no_aliases','allow_aliases'),
        $resolutionJson.Replace('specification_only_not_execution','verified'),
        $resolutionJson.Replace('H01-visual-1','H02-visual-1'),
        $resolutionJson.Replace('workspace_capture','default'))) {
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityResolutionSpecification $changed)) 'changed resolution specification admitted.'
      $resolutionCases++
    }
    Assert-RepairContract ($resolutionCases -eq 10) 'resolution fixture count changed.'
    Write-Output "Compatibility resolution specification: $resolutionCases exact-payload host checks passed; no staged annex, visual approval or source qualification."
    & {
      $fixtureCommit='c'*40;$expectedRevision='';$fixtureDocument=$resolutionText;$readFailure=''
      $script:resolutionReads=0;$script:wrongResolutionRead=$false
      function Get-OctoberCompatibilityGitLines {
        param([string[]]$Arguments)
        $script:resolutionReads++
        if($Arguments.Count -ne 2 -or $Arguments[0] -cne 'show' -or $Arguments[1] -cne $expectedRevision){
          $script:wrongResolutionRead=$true;throw 'unexpected resolution source'
        }
        if($readFailure -ceq 'throw'){throw 'labelled resolution read failure'}
        if($readFailure -ceq 'missing'){return @()}
        return @($fixtureDocument -split "`n")
      }
      Assert-RepairContract ($null -ne (Get-OctoberCompatibilityResolutionSpecification)) 'exact working resolution rejected.'
      Assert-RepairContract ($script:resolutionReads -eq 0) 'working resolution unexpectedly read Git.'
      $readerCases=1
      foreach($mode in @('index','commit')) {
        $expectedRevision=if($mode -ceq 'index'){':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{$fixtureCommit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
        $parameters=if($mode -ceq 'index'){@{FromIndex=$true}}else{@{Commit=$fixtureCommit}}
        $script:resolutionReads=0
        Assert-RepairContract ($null -ne (Get-OctoberCompatibilityResolutionSpecification @parameters)) 'exact selected resolution rejected.'
        Assert-RepairContract ($script:resolutionReads -eq 1 -and -not $script:wrongResolutionRead) 'resolution read wrong source.'
        $readerCases++
        $fixtureDocument=$resolutionText.Replace($resolutionJson,'{}');$script:resolutionReads=0
        Assert-RepairContract ($null -eq (Get-OctoberCompatibilityResolutionSpecification @parameters)) 'working resolution rescued invalid selected payload.'
        Assert-RepairContract ($script:resolutionReads -eq 1 -and -not $script:wrongResolutionRead) 'invalid resolution read wrong source.'
        $readerCases++;$fixtureDocument=$resolutionText
      }
      $expectedRevision=':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
      $fixtureDocument=$resolutionText+"`n"+$resolutionText;$script:resolutionReads=0
      Assert-RepairContract ($null -eq (Get-OctoberCompatibilityResolutionSpecification -FromIndex)) 'duplicate selected resolution admitted.'
      Assert-RepairContract ($script:resolutionReads -eq 1 -and -not $script:wrongResolutionRead) 'duplicate resolution read wrong source.'
      $readerCases++;$fixtureDocument=$resolutionText
      $script:resolutionReads=0
      Assert-RepairContract ($null -eq (Get-OctoberCompatibilityResolutionSpecification -FromIndex -Commit $fixtureCommit)) 'mixed resolution sources admitted.'
      Assert-RepairContract ($null -eq (Get-OctoberCompatibilityResolutionSpecification -Commit 'not-a-commit')) 'invalid resolution commit admitted.'
      Assert-RepairContract ($script:resolutionReads -eq 0) 'invalid source selection reached Git.'
      $readerCases+=2
      foreach($readFailure in @('missing','throw')) {
        $script:resolutionReads=0
        Assert-RepairContract ($null -eq (Get-OctoberCompatibilityResolutionSpecification -FromIndex)) 'failed resolution read admitted.'
        Assert-RepairContract ($script:resolutionReads -eq 1 -and -not $script:wrongResolutionRead) 'failed resolution read wrong source.'
        $readerCases++
      }
      Assert-RepairContract ($readerCases -eq 10) 'resolution source fixture count changed.'
      Remove-Variable -Name resolutionReads,wrongResolutionRead -Scope Script
      Write-Output 'Compatibility resolution readers: 10 isolated source-selection checks passed; actual index and commits unchanged.'
    }
  }
  if($CaptureCompatibilityReport) {
    Assert-RepairContract (-not $RequireCompatibilityStageProbes -and -not $RequireCompatibilityLiveAdmissionProbes) 'capture cannot be combined with probe modes.'
    $branch=@(& git -C $root branch --show-current)
    Assert-RepairContract ($LASTEXITCODE -eq 0 -and $branch.Count -eq 1 -and
      $branch[0] -ceq $binding.branch -and $root.Replace('\','/').TrimEnd('/') -ceq $binding.worktreePath) 'capture requires exact successor worktree/branch.'
    $source=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))
    Assert-RepairContract ($source.Count -eq 1) 'capture source unavailable.'
    $history=Get-OctoberCompatibilityHistoryStage $source[0]
    Assert-RepairContract ($history.Stage -eq 10) 'capture requires committed T test repair after immutable N, not earlier source or documentary Q.'
    $before=@(Get-OctoberCompatibilityGitLines @('status','--porcelain=v1','-z'))
    Assert-RepairContract ($before.Count -eq 0) 'capture requires clean T source.'
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
    $plan=Get-OctoberCompatibilityExecutionPlan -ReportId $CaptureCompatibilityReport -ExecutionId $CaptureExecutionId
    Assert-RepairContract ($null -ne $plan) 'execution is not a literal plan for this report category.'
    $flutterArguments=@($plan.Arguments)
    $tree=@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($source[0])^{tree}"))
    $producer=@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($source[0]):scripts/test-codex-integration-repair-coordination-policy.ps1"))
    Assert-RepairContract ($tree.Count -eq 1 -and $producer.Count -eq 1) 'capture tree/producer identity unavailable.'
    $relative='apps/mobile/build/compat-'+$CaptureCompatibilityReport+'-'+$CaptureExecutionId+'-'+[Guid]::NewGuid().ToString('N')+'.jsonl'
    $log=Join-Path $root $relative; $stderr=$log+'.stderr.txt'; $capturePath=$log+'.capture.json'
    $visualManifestRelative=$relative+'.visual.json'
    $visualManifestPath=Join-Path $root $visualManifestRelative
    foreach($path in @($log,$stderr,$capturePath,$visualManifestPath)) {
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
    $script:compatNativeExit=-1; $guardCompleted=$false; $failure=$null;$captureSdkEvidence=@{}
    $marker=@{type='moolsocialSource'; sourceCommit=$source[0]; sourceTree=$tree[0]
      registrySha256=[string]$policy.registryBinding.sha256; reportId=$CaptureCompatibilityReport
      executionId=$CaptureExecutionId; runtimeDefines=@($plan.RuntimeDefines)}
    $writer.WriteLine((ConvertTo-Json -InputObject $marker -Compress -Depth 10)); $writer.Flush()
    . (Join-Path $PSScriptRoot 'invoke-flutter-with-clean-support.ps1')
    try {
      $guardExit=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $root -Invocation {
        Push-Location (Join-Path $root 'apps/mobile')
        $visualEnvironment=@{}
        try {
          if($CaptureCompatibilityReport -ceq 'store_layout_and_recovery' -and $CaptureExecutionId -cne 'default') {
            # The committed T source's preserved recorder writes this execution's
            # manifest. The host never invents entries or comparator results.
            $visualEnvironment=@{
              MOOLSOCIAL_COMPAT_VISUAL_MANIFEST=$visualManifestPath
              MOOLSOCIAL_COMPAT_EXECUTION_LOG=$relative
              MOOLSOCIAL_COMPAT_SOURCE_COMMIT=$source[0]
              MOOLSOCIAL_COMPAT_SOURCE_TREE=$tree[0]
              MOOLSOCIAL_COMPAT_EXECUTION_ID=$CaptureExecutionId
            }
          }
          Invoke-OctoberCompatibilityVisualEnvironment -Values $visualEnvironment -Invocation {
            Invoke-OctoberCompatibilityComparatorBoundCapture -Receipt $captureSdkEvidence -Invocation {
              & $flutter @flutterArguments 2> $stderr | ForEach-Object {$writer.WriteLine([string]$_); $writer.Flush()}
              $script:compatNativeExit=[int]$LASTEXITCODE
              if($script:compatNativeExit -ne 0){throw "Flutter report exited $script:compatNativeExit; original output retained."}
            }
          }
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
      producerGitBlob=$producer[0]; reportId=$CaptureCompatibilityReport; executionId=$CaptureExecutionId
      sourceCommit=$source[0]; sourceTree=$tree[0]; registrySha256=[string]$policy.registryBinding.sha256
      sourceCommitAfter=$afterHead[0]; sourceTreeAfter=$afterTree[0]
      executable=$flutter; workingDirectory=$binding.worktreePath+'/apps/mobile'
      cleanBefore=$true; cleanAfter=($afterDirt.Count -eq 0); guardCompleted=$guardCompleted
      exitCode=$script:compatNativeExit; arguments=@($plan.Arguments); runtimeDefines=@($plan.RuntimeDefines)
      startedAtUtc=$started; finishedAtUtc=[DateTimeOffset]::UtcNow.ToString('o')
      stdoutSha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash
      stderrPath=$relative+'.stderr.txt'; stderrSha256=(Get-FileHash -LiteralPath $stderr -Algorithm SHA256).Hash
      visualManifestPath=if(Test-Path -LiteralPath $visualManifestPath -PathType Leaf){$visualManifestRelative}else{$null}
      visualManifestSha256=if(Test-Path -LiteralPath $visualManifestPath -PathType Leaf){Get-OctoberCoverageBoundHash $visualManifestPath}else{$null}
      comparatorImplementationSha256Before=$captureSdkEvidence['comparatorImplementationSha256Before']
      comparatorImplementationSha256After=$captureSdkEvidence['comparatorImplementationSha256After']
      comparatorSdkCommitBefore=$captureSdkEvidence['comparatorSdkCommitBefore'];comparatorSdkCommitAfter=$captureSdkEvidence['comparatorSdkCommitAfter']
      comparatorCheckedBeforeAtUtc=$captureSdkEvidence['comparatorCheckedBeforeAtUtc'];comparatorCheckedAfterAtUtc=$captureSdkEvidence['comparatorCheckedAfterAtUtc']
    }
    [IO.File]::WriteAllText($capturePath,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
    $record=@{id=$CaptureCompatibilityReport; executionId=$CaptureExecutionId; path=$relative; sha256=$capture.stdoutSha256
      capturePath=$relative+'.capture.json'; captureSha256=(Get-FileHash -LiteralPath $capturePath -Algorithm SHA256).Hash
      runtimeDefines=@($plan.RuntimeDefines)}
    Write-Output (ConvertTo-Json -InputObject $record -Compress -Depth 10)
    if($null -ne $failure){throw $failure}
    Assert-RepairContract (Test-OctoberCompatibilityCaptureComparator $capture) 'capture comparator provenance failed; retained capture is not qualified.'
    Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $capture -ReportId $CaptureCompatibilityReport -ExecutionId $CaptureExecutionId `
      -Source $source[0] -Tree $tree[0] -RegistrySha ([string]$policy.registryBinding.sha256) `
      -ProducerBlob $producer[0] -LogSha $capture.stdoutSha256) 'host capture failed; retained files are not passing evidence.'
    return
  }
  # Actual process-environment wrapper probes, with host-only values. Preserve
  # all preexisting user values and never print their contents.
  $fixtureEnvKeys=@('MOOLSOCIAL_COMPAT_VISUAL_MANIFEST','MOOLSOCIAL_COMPAT_EXECUTION_LOG',
    'MOOLSOCIAL_COMPAT_SOURCE_COMMIT','MOOLSOCIAL_COMPAT_SOURCE_TREE','MOOLSOCIAL_COMPAT_EXECUTION_ID')
  $originalFixtureEnv=@{};$fixtureEnvValues=@{};$environmentCases=0
  foreach($name in $fixtureEnvKeys){$originalFixtureEnv[$name]=[Environment]::GetEnvironmentVariable($name,'Process');$fixtureEnvValues[$name]='labelled-current-host-value'}
  try {
    foreach($name in $fixtureEnvKeys){[Environment]::SetEnvironmentVariable($name,'labelled-preexisting-host-value','Process')}
    foreach($kind in @('visual-success','nonvisual-success','visual-throw','nonvisual-throw')) {
      $hostShouldThrow=$kind.EndsWith('-throw',[StringComparison]::Ordinal)
      $hostIsVisual=$kind.StartsWith('visual-',[StringComparison]::Ordinal)
      $values=if($hostIsVisual){$fixtureEnvValues}else{@{}}
      $expectedException=$false;$script:hostEnvironmentInvocations=0
      try {
        Invoke-OctoberCompatibilityVisualEnvironment -Values $values -Invocation {
          $script:hostEnvironmentInvocations++
          foreach($name in $fixtureEnvKeys) {
            $value=[Environment]::GetEnvironmentVariable($name,'Process')
            if($hostIsVisual){Assert-RepairContract ($value -ceq 'labelled-current-host-value') 'visual environment did not use current bindings.'}
            else{Assert-RepairContract ($null -eq $value) 'nonvisual environment inherited recorder settings.'}
          }
          if($hostShouldThrow){throw 'Labelled recorder environment exception.'}
        }
      } catch {
        if(-not $hostShouldThrow -or $_.Exception.Message -cne 'Labelled recorder environment exception.'){throw}
        $expectedException=$true
      }
      Assert-RepairContract ($script:hostEnvironmentInvocations -eq 1 -and $expectedException -eq $hostShouldThrow) 'environment invocation/exception boundary mismatch.'
      foreach($name in $fixtureEnvKeys){Assert-RepairContract ([Environment]::GetEnvironmentVariable($name,'Process') -ceq 'labelled-preexisting-host-value') 'recorder environment not restored.'}
      $environmentCases++
    }
    foreach($kind in @('partial','unknown','coerced','blank')) {
      $values=$fixtureEnvValues.Clone();$script:hostEnvironmentInvocations=0;$rejected=$false
      switch($kind) {
        'partial' {$values.Remove($fixtureEnvKeys[0])}
        'unknown' {$values.Remove($fixtureEnvKeys[0]);$values.UNKNOWN_RECORDER_SETTING='labelled'}
        'coerced' {$values[$fixtureEnvKeys[0]]=$true}
        'blank' {$values[$fixtureEnvKeys[0]]=' '}
      }
      try {Invoke-OctoberCompatibilityVisualEnvironment -Values $values -Invocation {$script:hostEnvironmentInvocations++}}
      catch {$rejected=$_.Exception.Message.StartsWith('Recorder environment',[StringComparison]::Ordinal)}
      Assert-RepairContract ($rejected -and $script:hostEnvironmentInvocations -eq 0) 'invalid recorder bindings reached invocation.'
      foreach($name in $fixtureEnvKeys){Assert-RepairContract ([Environment]::GetEnvironmentVariable($name,'Process') -ceq 'labelled-preexisting-host-value') 'invalid bindings changed environment.'}
      $environmentCases++
    }
    foreach($name in $fixtureEnvKeys){[Environment]::SetEnvironmentVariable($name,[NullString]::Value,'Process')}
    Invoke-OctoberCompatibilityVisualEnvironment -Values $fixtureEnvValues -Invocation {
      foreach($name in $fixtureEnvKeys){Assert-RepairContract ([Environment]::GetEnvironmentVariable($name,'Process') -ceq 'labelled-current-host-value') 'absent-value control bindings rejected.'}
    }
    foreach($name in $fixtureEnvKeys){Assert-RepairContract ($null -eq [Environment]::GetEnvironmentVariable($name,'Process')) 'absent recorder environment restored as an empty variable.'}
    $environmentCases++
    Assert-RepairContract ($environmentCases -eq 9) 'recorder environment fixture inventory changed.'
  } finally {
    foreach($name in $fixtureEnvKeys){
      if($null -eq $originalFixtureEnv[$name]){[Environment]::SetEnvironmentVariable($name,[NullString]::Value,'Process')}
      else{[Environment]::SetEnvironmentVariable($name,$originalFixtureEnv[$name],'Process')}
    }
  }
  Write-Output "Compatibility recorder environment: $environmentCases actual host wrapper probes passed; no Flutter or runtime records invoked."
  $facts=@{
    Role=$binding.role; Task=$binding.task; Lane=$binding.lane
    WorkId=$binding.workId; TicketId=$binding.ticketId
    Root=$binding.worktreePath; Branch=$binding.branch; Base=$binding.baselineHead
    BaseGraphValid=$true; SourceRemotesExact=$true; NativeUnchanged=$true
    GenerationExact=$true; BindingsExact=$true; HistoryValid=$true
    Stage=0; Phase='coordination_bootstrap'; Owners=@($binding.bootstrapOwners)
    Clean=$true; HostQualificationPassed=$true
    HPreparationVerified=$true
    HCoverageVerified=$true
    JPreparationVerified=$true
    KPreparationVerified=$true
    KResolutionVerified=$true
    MPreparationVerified=$true
    MContractVerified=$true
    NPreparationVerified=$true
    NContractVerified=$true
    NTestAdmissionVerified=$true
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
  foreach ($pair in @(@('pre_commit',0),@('pre_commit',1),@('pre_commit',2),@('pre_commit',3),@('pre_commit',4),@('pre_commit',5),@('pre_commit',6),@('pre_commit',7),@('pre_commit',8),@('pre_commit',9),@('pre_commit',10),
      @('task_start',1),@('implementation',1),@('implementation',2),@('implementation',3),@('implementation',4),@('implementation',5),@('implementation',6),@('implementation',7),@('implementation',8),@('implementation',9),@('implementation',10),@('handoff',11),@('integration_admission_authorize',11))) {
    $stageFacts=$facts.Clone(); $stageFacts.Phase=$pair[0]; $stageFacts.Stage=[int]$pair[1]
    $stageFacts.Owners=if($stageFacts.Stage -eq 0){@($binding.bootstrapOwners)}
      elseif($stageFacts.Stage -eq 1){@(Get-OctoberCompatibilityApplicationOwners)}
      elseif($stageFacts.Stage -eq 2){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 3){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 4){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 5){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 6){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 7){@(Get-OctoberCompatibilityCoverageCartOwners)}
      elseif($stageFacts.Stage -eq 8){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 9){@(Get-OctoberCompatibilityInheritedCartTestOwners)}
      else{@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
    Assert-RepairContract (Test-OctoberCompatibilityStageFacts $stageFacts) "exact stage$($pair -join '/') rejected."
    $cases++
  }
  foreach ($stage in @(0,1,2,3,4,5,6,7,8,9,10)) {
    $changed=$facts.Clone(); $changed.Phase='handoff'; $changed.Stage=[int]$stage
    $changed.Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'unqualified E/G/C/A/L accepted for handoff.'
    $cases++
  }
  foreach($probe in @(
      @{Stage=1; Owners=@(Get-OctoberCompatibilityLayoutOwners)},
      @{Stage=2; Owners=@(Get-OctoberCompatibilityApplicationOwners)},
      @{Stage=3; Owners=@(Get-OctoberCompatibilityLayoutOwners)},
      @{Stage=5; Owners=@(Get-OctoberCompatibilityHandoverOwners)},
      @{Stage=6; Owners=@(Get-OctoberCompatibilityHandoverOwners)})) {
    $changed=$facts.Clone(); $changed.Phase='pre_commit'; $changed.Stage=[int]$probe.Stage
    $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'owners from another successor stage accepted.'
    $cases++
  }
  $handoff=$facts.Clone(); $handoff.Phase='handoff'; $handoff.Stage=11
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
      @{Stage=7; Owners=@(Get-OctoberCompatibilityCoverageCartOwners | Where-Object {$_ -cne 'apps/mobile/lib/features/work/work_session.dart'})},
      @{Stage=7; Owners=@(Get-OctoberCompatibilityCoverageCartOwners)+@('apps/mobile/lib/features/work/work_publication.dart')},
      @{Stage=10; Owners=@(Get-OctoberCompatibilityAmendmentOwners)})) {
    $changed=$facts.Clone(); $changed.Phase='pre_commit'; $changed.Stage=[int]$probe.Stage
    $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'widened or incomplete amendment/layout/Q claim accepted.'
    $cases++
  }
  foreach($flagCase in @(@(8,'NPreparationVerified'),@(8,'NContractVerified'),@(9,'NTestAdmissionVerified'))) {
    foreach($value in @($false,'true',$null)) {
      $changed=$facts.Clone();$changed.Phase='pre_commit';$changed.Stage=[int]$flagCase[0]
      $changed.Owners=if($changed.Stage -eq 8){@(Get-OctoberCompatibilityAmendmentOwners)}else{@(Get-OctoberCompatibilityInheritedCartTestOwners)}
      if($null -eq $value){$changed.Remove($flagCase[1])}else{$changed[$flagCase[1]]=$value}
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'N/T admitted without exact typed internal verification.'
      $cases++
    }
  }
  foreach($value in @($false,'true',$null)) {
    $changed=$facts.Clone();$changed.Phase='implementation';$changed.Stage=3
    $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
    if($null -eq $value){$changed.Remove('HPreparationVerified')}else{$changed.HPreparationVerified=$value}
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'H admitted without exact verified preparation.'
    $cases++
  }
  foreach($value in @($false,'true',$null)) {
    $changed=$facts.Clone();$changed.Phase='pre_commit';$changed.Stage=3
    $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
    if($null -eq $value){$changed.Remove('HCoverageVerified')}else{$changed.HCoverageVerified=$value}
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'H commit admitted without verified coverage specification.'
    $cases++
  }
  foreach($phase in @('implementation','pre_commit')) {
    foreach($value in @($false,'true',$null)) {
      $changed=$facts.Clone();$changed.Phase=$phase;$changed.Stage=4
      $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
      if($null -eq $value){$changed.Remove('JPreparationVerified')}else{$changed.JPreparationVerified=$value}
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'J admitted without independently verified preservation.'
      $cases++
    }
  }
  foreach($phase in @('implementation','pre_commit')) {
    foreach($value in @($false,'true',$null)) {
      $changed=$facts.Clone();$changed.Phase=$phase;$changed.Stage=5
      $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
      if($null -eq $value){$changed.Remove('KPreparationVerified')}else{$changed.KPreparationVerified=$value}
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'K admitted without independent current preservation.';$cases++
    }
  }
  foreach($value in @($false,'true',$null)) {
    $changed=$facts.Clone();$changed.Phase='pre_commit';$changed.Stage=5
    $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
    if($null -eq $value){$changed.Remove('KResolutionVerified')}else{$changed.KResolutionVerified=$value}
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'K committed without complete executable resolution contract.';$cases++
  }
  $changed=$handoff.Clone();$changed.Phase='integration_admission_authorize';$changed.Stage=7
  Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'legacy stage7 admitted as qualified integration source.';$cases++
  foreach($phase in @('implementation','pre_commit')) {
    foreach($value in @($false,'true',$null)) {
      $changed=$facts.Clone();$changed.Phase=$phase;$changed.Stage=6
      $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
      if($null -eq $value){$changed.Remove('MPreparationVerified')}else{$changed.MPreparationVerified=$value}
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'M admitted without independent current preparation.';$cases++
    }
  }
  foreach($value in @($false,'true',$null)) {
    $changed=$facts.Clone();$changed.Phase='pre_commit';$changed.Stage=6
    $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
    if($null -eq $value){$changed.Remove('MContractVerified')}else{$changed.MContractVerified=$value}
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'M committed without verified staged handoff contract.';$cases++
  }
  # Preserve124 earlier probes, plus4 stage positives,2 premature-closure
  # refusals and9 typed N-fact refusals. No old case is silently removed.
  Assert-RepairContract ($cases -eq 139) 'stage probe inventory changed.'
  Write-Output "Compatibility stage predicates: $cases cases passed; live graph/admission and APK qualification remain separate."
  # Literal execution planning only: no Flutter or optional golden run is admitted.
  $planCases=0
  foreach($id in @('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')) {
    $expected=Get-OctoberCompatibilityReportPlan $id
    $plan=Get-OctoberCompatibilityExecutionPlan -ReportId $id
    Assert-RepairContract ($null -ne $plan -and $plan.ExecutionId -ceq 'default' -and
      $plan.RequiredNames.Count -eq 0 -and
      (@($plan.Arguments) -join '|') -ceq (@($expected.Arguments) -join '|') -and
      (@($plan.Suites) -join '|') -ceq (@($expected.Suites) -join '|')) 'default execution changed its baseline plan.'
    $planCases++
  }
  $executionPins=@{
    localstock_review=@{Count=6;Hash='E7B0DB6254C1F760D16262A2009F8B804D9665DCEBCB1E54EBB6A381FE9B602E';Defines=@('MOOLSOCIAL_DEVICE_REVIEW=true','MOOLSOCIAL_UI_REVIEW_ONLY=true')}
    workspace_capture=@{Count=11;Hash='5EF22DD5FCB0E25192E5111C65EB66DF245A980F162988872756A8AE31459B83';Defines=@('MOOL_CAPTURE_STORE_VIEW_V2=true')}
    historical_store_review=@{Count=17;Hash='6D022B1BA60353C92D634EC5CB7CAF7B1B374E4869C9271CF224BF1DB58FC9A4';Defines=@()}
    historical_store_capture=@{Count=6;Hash='1DA2E56A0B3A09ECAC26C2FA2E2A00E6906DC5D0317E093D2BD6F74B127D8D3A';Defines=@('MOOL_CAPTURE_WORK_STORE_1_40=true')}
    store_live_capture=@{Count=20;Hash='E214B73B677EBE788E4C6F59306AC81293CDE7C064B5B7C50D4C87257DB7011F';Defines=@('MOOL_CAPTURE_WORK_STORE_LIVE_V1=true')}
    founder_capture=@{Count=24;Hash='7D5C3E747D69FB979740F5C719DEFACC81F47B6E8973BEC4A2DFD37850DF6E53';Defines=@('MOOL_CAPTURE_WORK_STORE_1_40=true')}
  }
  $literalNames=0
  foreach($id in $executionPins.Keys) {
    $pin=$executionPins[$id];$plan=Get-OctoberCompatibilityExecutionPlan -ReportId store_layout_and_recovery -ExecutionId $id
    Assert-RepairContract ($null -ne $plan -and $plan.Id -ceq 'store_layout_and_recovery' -and
      $plan.ExecutionId -ceq $id -and $plan.RequiredNames.Count -eq $pin.Count -and
      (@($plan.RuntimeDefines) -join '|') -ceq (@($pin.Defines) -join '|') -and
      (@($plan.Suites) -join '|') -ceq 'work_workspace_layout_safety_test.dart') 'supplemental execution identity/configuration changed.'
    [string[]]$names=@($plan.RequiredNames);[Array]::Sort($names,[StringComparer]::Ordinal)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {$hash=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($names -join "`n")))).Replace('-','')} finally {$sha.Dispose()}
    Assert-RepairContract ($hash -ceq $pin.Hash) 'literal case set differs from frozen discovery inventory.'
    $selectionArguments=@($plan.Arguments | Where-Object {$_ -clike '--name=*'})
    Assert-RepairContract ($selectionArguments.Count -eq 1) 'supplemental selection is missing or duplicated.'
    $selection=$selectionArguments[0].Substring(7)
    foreach($name in $names) {
      Assert-RepairContract ([regex]::IsMatch($name,$selection) -and
        -not [regex]::IsMatch($name+' unrelated',$selection) -and
        -not [regex]::IsMatch('unrelated '+$name,$selection) -and
        -not [regex]::IsMatch($name+"`n",$selection) -and
        -not [regex]::IsMatch($name+"`r`n",$selection)) 'literal selector is not fully anchored.'
      $literalNames++
    }
    if($id -ceq 'historical_store_review' -or $id -ceq 'historical_store_capture') {
      Assert-RepairContract (@($names | Where-Object {-not $_.StartsWith('local Store 1-40 review evidence ',[StringComparison]::Ordinal)}).Count -eq 0) 'historical plan renames retained original cases.'
      Assert-RepairContract (@($plan.RuntimeDefines | Where-Object {$_ -cne 'MOOL_CAPTURE_WORK_STORE_1_40=true'}).Count -eq 0) 'historical plan introduces a parent-skip bypass define.'
      Assert-RepairContract ([regex]::IsMatch('local Store 1-40 review evidence founder review capture - setup dashboard',$selection) -eq ($id -ceq 'historical_store_capture')) 'historical functional and visual profiles overlap.'
    } else {
      Assert-RepairContract (-not [regex]::IsMatch('local Store 1-40 review evidence founder review capture - setup dashboard',$selection)) 'supplemental flag pretends to enable an always-skipped parent group.'
    }
    $planCases++
  }
  foreach($id in @('unknown','LOCALSTOCK_REVIEW','localstock_review --update-goldens','')) {
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityExecutionPlan -ReportId store_layout_and_recovery -ExecutionId $id)) 'unknown/caller-injected execution admitted.';$planCases++
  }
  foreach($id in @('publication_contracts','impacted_store_buy','enabled_review_fixture','unknown')) {
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityExecutionPlan -ReportId $id -ExecutionId localstock_review)) 'supplemental execution escaped its layout category.';$planCases++
  }
  Assert-RepairContract ($literalNames -eq 84 -and $planCases -eq 18) 'execution fixture inventory changed.'
  Write-Output "Compatibility execution plans: $planCases configurations and $literalNames literal names checked; no supplemental capture or coverage admission."
  # Labelled host-only inventory fixtures: no evidence file or app data is created.
  $executionReports=@()
  foreach($reportId in @('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')) {
    $executionIds=if($reportId -ceq 'store_layout_and_recovery') {
      @('default','localstock_review','workspace_capture','historical_store_review',
        'historical_store_capture','store_live_capture','founder_capture')
    } else {@('default')}
    $executionRows=@()
    foreach($executionId in $executionIds) {
      $executionPlan=Get-OctoberCompatibilityExecutionPlan -ReportId $reportId -ExecutionId $executionId
      $fixturePath='apps/mobile/build/inventory-fixture-'+$reportId+'-'+$executionId+'.jsonl'
      $executionRows+=@{executionId=$executionId;path=$fixturePath;sha256=('A'*64);
        capturePath=($fixturePath+'.capture.json');captureSha256=('B'*64);
        runtimeDefines=@($executionPlan.RuntimeDefines)}
    }
    $executionReports+=@{id=$reportId;executions=@($executionRows)}
  }
  $executionInventoryJson=@{schemaVersion=2;reports=@($executionReports)}|ConvertTo-Json -Depth 20
  $inventoryProof=$executionInventoryJson|ConvertFrom-Json
  $inventoryResult=@(Get-OctoberCompatibilityQualificationExecutions $inventoryProof)
  Assert-RepairContract ($inventoryResult.Count -eq 10 -and
    @($inventoryResult | Where-Object {$_.ExecutionId -ceq 'default'}).Count -eq 4) 'complete nested inventory rejected.'
  $executionInventoryCases=1
  foreach($kind in @('schema-string','legacy-schema','missing-category','duplicate-category',
      'wrong-category-case','unknown-category','scalar-reports','scalar-executions',
      'missing-default','duplicate-execution','wrong-execution-family','unknown-execution',
      'wrong-execution-case','coerced-execution','extra-execution-field','flat-category-path',
      'wrong-defines','coerced-defines','scalar-defines','duplicate-path','traversal-path',
      'wrong-capture-path','bad-log-hash','bad-capture-hash','empty-string-defines',
      'joined-defines','define-count','reordered-defines','path-final-lf',
      'log-hash-final-lf','capture-hash-final-lf','capture-path-final-lf')) {
    $probe=$executionInventoryJson|ConvertFrom-Json
    switch($kind) {
      'schema-string' {$probe.schemaVersion='2'}
      'legacy-schema' {$probe.schemaVersion=1}
      'missing-category' {$probe.reports=@($probe.reports | Select-Object -First 3)}
      'duplicate-category' {$probe.reports[1].id=$probe.reports[0].id}
      'wrong-category-case' {$probe.reports[0].id='PUBLICATION_CONTRACTS'}
      'unknown-category' {$probe.reports[0].id='unknown'}
      'scalar-reports' {$probe.reports=$probe.reports[0]}
      'scalar-executions' {$probe.reports[0].executions=$probe.reports[0].executions[0]}
      'missing-default' {$probe.reports[2].executions=@($probe.reports[2].executions | Select-Object -Skip 1)}
      'duplicate-execution' {$probe.reports[2].executions[1].executionId='default'}
      'wrong-execution-family' {$probe.reports[0].executions[0].executionId='workspace_capture'}
      'unknown-execution' {$probe.reports[2].executions[1].executionId='unknown'}
      'wrong-execution-case' {$probe.reports[2].executions[1].executionId='LOCALSTOCK_REVIEW'}
      'coerced-execution' {$probe.reports[2].executions[1].executionId=$true}
      'extra-execution-field' {$probe.reports[0].executions[0]|Add-Member -NotePropertyName success -NotePropertyValue $true}
      'flat-category-path' {$probe.reports[0]|Add-Member -NotePropertyName path -NotePropertyValue 'apps/mobile/build/flat.jsonl'}
      'wrong-defines' {$probe.reports[0].executions[0].runtimeDefines=@('MOOL_CAPTURE_WORK_STORE_1_40=true')}
      'coerced-defines' {$probe.reports[0].executions[0].runtimeDefines=@($true)}
      'scalar-defines' {$probe.reports[2].executions[4].runtimeDefines='MOOL_CAPTURE_WORK_STORE_1_40=true'}
      'duplicate-path' {$probe.reports[1].executions[0].path=$probe.reports[0].executions[0].path;
        $probe.reports[1].executions[0].capturePath=$probe.reports[0].executions[0].capturePath}
      'traversal-path' {$probe.reports[0].executions[0].path='apps/mobile/build/../outside.jsonl';
        $probe.reports[0].executions[0].capturePath='apps/mobile/build/../outside.jsonl.capture.json'}
      'wrong-capture-path' {$probe.reports[0].executions[0].capturePath='apps/mobile/build/other.jsonl.capture.json'}
      'bad-log-hash' {$probe.reports[0].executions[0].sha256='a'*64}
      'bad-capture-hash' {$probe.reports[0].executions[0].captureSha256=$true}
      'empty-string-defines' {$probe.reports[0].executions[0].runtimeDefines=@('')}
      'joined-defines' {$probe.reports[2].executions[1].runtimeDefines=@('MOOLSOCIAL_DEVICE_REVIEW=true|MOOLSOCIAL_UI_REVIEW_ONLY=true')}
      'define-count' {$probe.reports[2].executions[1].runtimeDefines=@('MOOLSOCIAL_DEVICE_REVIEW=true')}
      'reordered-defines' {$probe.reports[2].executions[1].runtimeDefines=@('MOOLSOCIAL_UI_REVIEW_ONLY=true','MOOLSOCIAL_DEVICE_REVIEW=true')}
      'path-final-lf' {$probe.reports[0].executions[0].path+="`n";
        $probe.reports[0].executions[0].capturePath=$probe.reports[0].executions[0].path+'.capture.json'}
      'log-hash-final-lf' {$probe.reports[0].executions[0].sha256+="`n"}
      'capture-hash-final-lf' {$probe.reports[0].executions[0].captureSha256+="`n"}
      'capture-path-final-lf' {$probe.reports[0].executions[0].capturePath+="`n"}
    }
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityQualificationExecutions $probe)) "nested execution inventory admitted $kind."
    $executionInventoryCases++
  }
  Assert-RepairContract ($executionInventoryCases -eq 33) 'nested execution fixture count changed.'
  Write-Output "Compatibility nested execution inventory: $executionInventoryCases labelled host fixtures passed; no logs, visuals or source qualified."
  $coverageDoc=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $coverageBlocks=[regex]::Matches($coverageDoc,'(?s)<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_COVERAGE_SPECIFICATION_JSON_END -->')
  Assert-RepairContract ($coverageBlocks.Count -eq 1) 'coverage specification missing/duplicated.'
  $coverageJson=$coverageBlocks[0].Groups[1].Value
  $coverage=$coverageJson|ConvertFrom-Json
  Assert-RepairContract (Test-OctoberCompatibilityCoverageSpecification $coverageJson) 'complete prospective coverage accounting rejected.'
  $coverageCases=1
  $normalizedCopy=" `r`n"+$coverageJson.Trim().Replace("`r`n","`n").Replace("`n","`r`n")+"`r`n "
  Assert-RepairContract (Test-OctoberCompatibilityCoverageSpecification $normalizedCopy) 'line-ending normalization changes reviewed payload.';$coverageCases++
  foreach($kind in @('schema-string','spec-claims-verified','wrong-source','wrong-layout',
      'wrong-inventory','wrong-keyset','wrong-boundary','false-history-claim','coerced-history-claim',
      'missing-row','duplicate-row','renamed-key','case-changed-key','duplicate-ordinal',
      'coerced-ordinal','wrong-family','wrong-execution','unapproved-replacement',
      'missing-success','wrong-success','scalar-obligations','empty-obligations',
      'empty-obligation-text','scalar-comparisons','bad-reference','empty-unresolved','empty-skip',
      'cross-family-swap','nonempty-obligation-replacement','empty-capture-comparisons')) {
    $probe=$coverageJson|ConvertFrom-Json
    switch($kind) {
      'schema-string' {$probe.schemaVersion='1'}
      'spec-claims-verified' {$probe.state='verified'}
      'wrong-source' {$probe.sourceCommit='0'*40}
      'wrong-layout' {$probe.frozenLayoutSha256='0'*64}
      'wrong-inventory' {$probe.inventorySha256='0'*64}
      'wrong-keyset' {$probe.caseKeySetSha256='0'*64}
      'wrong-boundary' {$probe.correctionBoundary='replace_anything'}
      'false-history-claim' {$probe.noHistoricalSuccessClaim=$false}
      'coerced-history-claim' {$probe.noHistoricalSuccessClaim='true'}
      'missing-row' {$probe.cases=@($probe.cases[0..82])}
      'duplicate-row' {$probe.cases[83]=$probe.cases[0]}
      'renamed-key' {$probe.cases[0].key+=' unrelated'}
      'case-changed-key' {$probe.cases[0].key=$probe.cases[0].key.ToUpperInvariant()}
      'duplicate-ordinal' {$probe.cases[1].ordinal=$probe.cases[0].ordinal}
      'coerced-ordinal' {$probe.cases[0].ordinal='1'}
      'wrong-family' {$probe.cases[0].family='localstock_review'}
      'wrong-execution' {$probe.cases[0].executionId='default'}
      'unapproved-replacement' {$probe.cases[0].replacementAuthorityState='granted'}
      'missing-success' {$probe.cases[0].requiredSuccessKeys=@()}
      'wrong-success' {$probe.cases[0].requiredSuccessKeys=@($probe.cases[1].key)}
      'scalar-obligations' {$probe.cases[0].retainedObligations='do anything'}
      'empty-obligations' {$probe.cases[0].retainedObligations=@()}
      'empty-obligation-text' {$probe.cases[0].retainedObligations=@(' ')}
      'scalar-comparisons' {$probe.cases[0].expectedComparisons='image.png'}
      'bad-reference' {$probe.cases[0].referenceSha256='invalid'}
      'empty-unresolved' {$probe.cases[0].unresolvedRequirements=''}
      'empty-skip' {$probe.cases[0].skipCondition=''}
      'cross-family-swap' {
        $key=$probe.cases[0].key;$probe.cases[0].key=$probe.cases[11].key;$probe.cases[11].key=$key
        $probe.cases[0].requiredSuccessKeys=@($probe.cases[0].key)
        $probe.cases[11].requiredSuccessKeys=@($probe.cases[11].key)
      }
      'nonempty-obligation-replacement' {$probe.cases[0].retainedObligations=@('Anything is sufficient')}
      'empty-capture-comparisons' {$probe.cases[0].expectedComparisons=@()}
    }
    $probeJson=ConvertTo-Json -InputObject $probe -Compress -Depth 30
    Assert-RepairContract (-not(Test-OctoberCompatibilityCoverageSpecification $probeJson)) "invalid coverage $kind admitted.";$coverageCases++
  }
  Assert-RepairContract ($coverageCases -eq 32) 'prospective coverage fixture inventory changed.'
  Write-Output "Compatibility coverage specification: $coverageCases labelled fixtures passed; accounting only, not source qualification."
  # Aggregate orchestration fixtures use an explicitly isolated evidence reader.
  # Real file parsing has separate tests; these fixtures prove all ten callers
  # and family-bound original coverage, not real source/visual qualification.
  & {
    $aggregateCoverageMode='positive';$failedExecution=''
    $fixtureCoverageInventory=$coverageJson|ConvertFrom-Json
    $coverageReaderCalls=[Collections.Generic.List[string]]::new()
    $coverageFacts=@{Source=('a'*40);Tree=('b'*40);RegistrySha=('C'*64);ProducerBlob=('d'*40)}
    function Read-OctoberCompatibilityExecutionEvidence {
      param([object]$Evidence,[string]$ReportId,[string]$ExecutionId,
        [string]$Source,[string]$Tree,[string]$RegistrySha,[string]$ProducerBlob)
      $identity=$ReportId+':'+$ExecutionId;$coverageReaderCalls.Add($identity)
      if($Source -cne $coverageFacts.Source -or $Tree -cne $coverageFacts.Tree -or
          $RegistrySha -cne $coverageFacts.RegistrySha -or $ProducerBlob -cne $coverageFacts.ProducerBlob){return $null}
      if($identity -ceq $failedExecution){return $null}
      $passed=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
      $ignored=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
      $null=$passed.Add('labelled aggregate host control:'+ $identity)
      if($ReportId -ceq 'store_layout_and_recovery') {
        $plan=Get-OctoberCompatibilityExecutionPlan -ReportId $ReportId -ExecutionId $ExecutionId
        foreach($row in $fixtureCoverageInventory.cases) {
          foreach($key in $row.requiredSuccessKeys) {
            if($plan.RequiredNames -ccontains $key.Substring($key.IndexOf(':')+1)) {
              if($row.ordinal -eq 1 -and $aggregateCoverageMode -cin @('missing-original','wrong-family')){continue}
              $null=$passed.Add($key)
            }
          }
        }
        if($ExecutionId -ceq 'default' -and $aggregateCoverageMode -ceq 'wrong-family') {
          foreach($key in $fixtureCoverageInventory.cases[0].requiredSuccessKeys){$null=$passed.Add($key)}
        }
        if($ExecutionId -ceq 'default' -and $aggregateCoverageMode -ceq 'discharged-skip') {
          foreach($key in $fixtureCoverageInventory.cases[0].requiredSuccessKeys){$null=$ignored.Add($key)}
        }
      }
      if($aggregateCoverageMode -ceq 'undischarged-skip'){$null=$ignored.Add('unfulfilled original skip')}
      if($aggregateCoverageMode -ceq 'invalid-reader-shape'){return @{Successes=@('not validated');Skipped=$ignored}}
      return @{Successes=$passed;Skipped=$ignored}
    }
    $result=Read-OctoberCompatibilityExecutionCoverage -Proof $inventoryProof -CoverageJson $coverageJson @coverageFacts
    Assert-RepairContract ($null -ne $result -and $result.VerifiedExecutions -eq 10 -and
      $coverageReaderCalls.Count -eq 10 -and @($coverageReaderCalls | Select-Object -Unique).Count -eq 10) 'complete ten-execution aggregate rejected or did not read every execution.'
    $aggregateCoverageCases=1
    $aggregateCoverageMode='discharged-skip';$coverageReaderCalls.Clear()
    $result=Read-OctoberCompatibilityExecutionCoverage -Proof $inventoryProof -CoverageJson $coverageJson @coverageFacts
    Assert-RepairContract ($null -ne $result -and $coverageReaderCalls.Count -eq 10) 'same-key supplemental skip discharge rejected.';$aggregateCoverageCases++
    $aggregateCoverageMode='positive'
    foreach($execution in $inventoryResult) {
      $failedExecution=$execution.ReportId+':'+$execution.ExecutionId;$coverageReaderCalls.Clear()
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionCoverage -Proof $inventoryProof -CoverageJson $coverageJson @coverageFacts)) "aggregate rescued failed execution $failedExecution."
      Assert-RepairContract ($coverageReaderCalls.Contains($failedExecution)) 'failed execution boundary was not reached.';$aggregateCoverageCases++
    }
    $failedExecution=''
    foreach($kind in @('missing-original','wrong-family','undischarged-skip','missing-execution','wrong-source','invalid-reader-shape')) {
      $aggregateCoverageMode=$kind;$probe=$executionInventoryJson|ConvertFrom-Json;$facts=$coverageFacts.Clone();$coverageReaderCalls.Clear()
      if($kind -ceq 'missing-execution'){$probe.reports[2].executions=@($probe.reports[2].executions | Select-Object -Skip 1)}
      if($kind -ceq 'wrong-source'){$facts.Source='invalid'}
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionCoverage -Proof $probe -CoverageJson $coverageJson @facts)) "execution aggregate admitted $kind.";$aggregateCoverageCases++
    }
    $aggregateCoverageMode='positive';$coverageReaderCalls.Clear()
    $result=Read-OctoberCompatibilityExecutionCoverage -Proof $inventoryProof -CoverageJson $coverageJson @coverageFacts
    Assert-RepairContract ($null -ne $result -and $coverageReaderCalls.Count -eq 10) 'final aggregate control rejected.';$aggregateCoverageCases++
    Assert-RepairContract ($aggregateCoverageCases -eq 19) 'aggregate coverage fixture count changed.'
    Write-Output "Compatibility execution coverage: $aggregateCoverageCases labelled orchestration fixtures passed; real file, visual and immutable source qualification remain separate."
  }
  # Isolated index observations: a valid working document must never rescue an
  # invalid staged payload. No real index or working document is modified.
  & {
    $indexDocument=$coverageDoc;$readMode='normal'
    $script:coverageReadCalls=0;$script:coverageUnexpectedRead=$false
    function Get-OctoberCompatibilityGitLines {
      param([string[]]$Arguments)
      $script:coverageReadCalls++
      if($Arguments.Count -ne 2 -or $Arguments[0] -cne 'show' -or
          $Arguments[1] -cne ':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md') {
        $script:coverageUnexpectedRead=$true;throw 'unexpected coverage Git read'
      }
      if($readMode -ceq 'missing'){return @()}
      if($readMode -ceq 'throw'){throw 'labelled coverage Git failure'}
      return @($indexDocument -split "`n")
    }
    Assert-RepairContract ($null -ne (Get-OctoberCompatibilityCoverageSpecification -FromIndex)) 'valid staged coverage rejected.'
    Assert-RepairContract ($script:coverageReadCalls -eq 1 -and -not $script:coverageUnexpectedRead) 'index coverage read another source.'
    $indexDocument=$coverageDoc.Replace($coverageJson,'{}')
    $script:coverageReadCalls=0
    Assert-RepairContract ($null -ne (Get-OctoberCompatibilityCoverageSpecification)) 'valid working coverage unavailable in index fixture.'
    Assert-RepairContract ($script:coverageReadCalls -eq 0) 'working coverage unexpectedly read Git.'
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityCoverageSpecification -FromIndex)) 'valid working coverage rescued invalid staged coverage.'
    Assert-RepairContract ($script:coverageReadCalls -eq 1 -and -not $script:coverageUnexpectedRead) 'invalid staged coverage used wrong source.'
    $indexDocument=$coverageDoc+"`n"+$coverageDoc
    $script:coverageReadCalls=0
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityCoverageSpecification -FromIndex)) 'duplicate staged coverage admitted.'
    Assert-RepairContract ($script:coverageReadCalls -eq 1 -and -not $script:coverageUnexpectedRead) 'duplicate staged coverage used wrong source.'
    $indexDocument=$coverageDoc;$script:coverageReadCalls=0
    Assert-RepairContract ($null -eq (Get-OctoberCompatibilityCoverageSpecification -FromIndex -Commit ('a'*40))) 'mixed index/commit source admitted.'
    Assert-RepairContract ($script:coverageReadCalls -eq 0 -and -not $script:coverageUnexpectedRead) 'conflicting source reached Git.'
    foreach($readMode in @('missing','throw')){
      $script:coverageReadCalls=0
      Assert-RepairContract ($null -eq (Get-OctoberCompatibilityCoverageSpecification -FromIndex)) "$readMode staged read admitted."
      Assert-RepairContract ($script:coverageReadCalls -eq 1 -and -not $script:coverageUnexpectedRead) "$readMode staged read used wrong source."
    }
    Remove-Variable -Name coverageReadCalls,coverageUnexpectedRead -Scope Script
  }
  Write-Output 'Compatibility staged coverage source: 7 labelled reader scenarios passed with isolated call assertions; real index unchanged.'
  $hFacts=$facts.Clone();$hFacts.Stage=3;$hFacts.Phase='pre_commit'
  $hFacts.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
  $staged=@(Get-OctoberCompatibilityAmendmentOwners);$unstaged=@(Get-OctoberCompatibilityLayoutOwners)
  Assert-RepairContract (Test-OctoberCoveragePreCommitInventory -Facts $hFacts -Staged $staged -Unstaged $unstaged -Untracked @()) 'exact H staging inventory rejected.'
  $hInventoryCases=1
  foreach($kind in @('extra-staged','missing-staged','extra-unstaged','missing-unstaged','untracked','wrong-stage','wrong-phase','unverified-preservation','unverified-specification')) {
    $probe=$hFacts.Clone();$s=@($staged);$u=@($unstaged);$n=@()
    switch($kind) {
      'extra-staged' {$s+=@($unstaged[0])}
      'missing-staged' {$s=@($staged[0..2])}
      'extra-unstaged' {$u+=@('unrelated.dart')}
      'missing-unstaged' {$u=@($unstaged[0..1])}
      'untracked' {$n=@('untracked.dart')}
      'wrong-stage' {$probe.Stage=4}
      'wrong-phase' {$probe.Phase='implementation'}
      'unverified-preservation' {$probe.HPreparationVerified=$false}
      'unverified-specification' {$probe.HCoverageVerified=$false}
    }
    Assert-RepairContract (-not(Test-OctoberCoveragePreCommitInventory -Facts $probe -Staged $s -Unstaged $u -Untracked $n)) "H inventory $kind admitted.";$hInventoryCases++
  }
  Assert-RepairContract ($hInventoryCases -eq 10) 'H staging inventory fixtures changed.'
  Write-Output "Compatibility H staging inventory: $hInventoryCases labelled fixtures passed; live index/preservation admission remains separate."
  # Actual H collector with labelled Git/filesystem observations. Constants and
  # collector logic are the operative definitions above, not rewritten copies.
  & {
    $root=$binding.worktreePath; $mode='positive';$mutated=$false;$unexpected=$false
    $observations=@{}; $mutexName='Local\MoolSocialHFixture_'+[Guid]::NewGuid().ToString('N')
    $sourcePaths=@(Get-OctoberCompatibilityLayoutOwners)
    $metadataPaths=@(Get-OctoberCompatibilityAmendmentOwners)
    $canonical=[IO.Path]::GetFullPath($root).TrimEnd([char[]]@('\','/')).ToLowerInvariant()
    $fixtureSha=[Security.Cryptography.SHA256]::Create()
    try {$fixtureDigest=$fixtureSha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical))} finally {$fixtureSha.Dispose()}
    $expectedMutexName='Local\MoolSocialFlutterSupport_'+[BitConverter]::ToString($fixtureDigest).Replace('-','')
    $sourceIndex=@(
      "100644 6c666815ed6584d26d47ceccc84841c14642fa07 0`tapps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart",
      "100644 12ab455c553a754e2594050b126433dd9c764467 0`tapps/mobile/test/work_public_handoff_test.dart",
      "100644 c976ec36cc96c6f448962af5b032209e62296d3d 0`tapps/mobile/test/work_workspace_layout_safety_test.dart")
    $hashes=@{
      ($root+'/'+$sourcePaths[0])='7E78F1ED40138033BAF84EC6CDD910D22E6064B3F77ADDCE93D78C0DE2D30A5B'
      ($root+'/'+$sourcePaths[1])='C2263DE880D013DAF3B9A7262CC774D6F3C8B686BD2E34D00C92D7DD8C43FD33'
      ($root+'/'+$sourcePaths[2])='EBA5DF0E18423D1F90E2489F7CA7215B32C9557E1A6C3886674FA3A2C438995F'
      'C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/work/compatibility-coverage-metadata-preparation-decision-20261009.json'='EFEF3850C32A6F56EC1A7DC9BB6D8513E2313618E6FCD3B7C0618F3FFCB53B14'
      'C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/work/compatibility-coverage-preparation-PS7-20261009.json'='7609550C0C8EFE4887A36D44D6E2433CC29101DB123B9C326BFBB466F5A124DE'
      'C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/work/compatibility-coverage-preparation-PS5-20261009.json'='78A9AE38B4068F33B366E26670EA4C02EE38FA53A278610B3C870579D3C0D6C2'
      'C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/founder-combined-compatibility-authority-20261008.md'='7F16E2209129B1F80D3DD8D390006A94CC62C45A7E4BA69DC56516884953F281'
    }
    $blobs=@{
      $metadataPaths[0]='187ed0881e8c421a6a3ef53c28f580b72bf78d75'
      $metadataPaths[1]='9b4c11fbb7c5e75bae4f9499e386cd6cc35e0654'
      $metadataPaths[2]='83d318d31a8a02031ac9aa253f30c918c4c3fe57'
      $metadataPaths[3]='b421f9a0e03ba66c63cf7f753014f608d4d008f5'
    }
    foreach($path in $metadataPaths){$hashes[$root+'/'+$path]='F'*64}
    $metadataIndex=@($metadataPaths | ForEach-Object {"100644 $($blobs[$_]) 0`t$_"})
    $ancestors=@{}
    foreach($path in $hashes.Keys){
      $part=[IO.Path]::GetFullPath($path)
      while($part){$ancestors[$part.Replace('\','/')]=$true;$parent=Split-Path -Parent $part;if($parent -ceq $part){break};$part=$parent}
    }
    function Seen([string]$Key){if(-not $observations.ContainsKey($Key)){$observations[$Key]=0};$observations[$Key]++;return $observations[$Key]}
    function Get-ChildItem([string]$Path){
      if($Path -cne 'Env:'){$script:hUnexpected=$true;throw 'Unknown H fixture environment query.'}
      if($mode -ceq 'environment'){$script:hMutated=$true;return [pscustomobject]@{Name='GIT_DIR'}}
      return [pscustomobject]@{Name='GIT_PAGER'}
    }
    function Get-Item([string]$LiteralPath,[switch]$Force){
      $path=[IO.Path]::GetFullPath($LiteralPath).Replace('\','/')
      if(-not $ancestors.ContainsKey($path)){$script:hUnexpected=$true;throw 'Unknown H fixture item query.'}
      if($mode -ceq 'source-reparse' -and $path -ceq ($root+'/'+$sourcePaths[0])){$script:hMutated=$true;return [pscustomobject]@{Attributes=[IO.FileAttributes]::ReparsePoint}}
      return [pscustomobject]@{Attributes=[IO.FileAttributes]::Normal}
    }
    function Get-FileHash([string]$LiteralPath,[string]$Algorithm){
      $path=$LiteralPath.Replace('\','/');$n=Seen ('hash:'+ $path)
      if($Algorithm -cne 'SHA256' -or -not $hashes.ContainsKey($path)){$script:hUnexpected=$true;throw 'Unknown H fixture hash query.'}
      if(($mode -ceq 'source-hash' -or ($mode -ceq 'source-changes' -and $n -gt 1)) -and $path -ceq ($root+'/'+$sourcePaths[0])){$script:hMutated=$true;return [pscustomobject]@{Hash=('0'*64)}}
      if($mode -ceq 'stale-provision' -and $path.EndsWith('/compatibility-coverage-metadata-preparation-decision-20261009.json')){$script:hMutated=$true;return [pscustomobject]@{Hash=('0'*64)}}
      if($mode -ceq 'metadata-changes' -and $n -gt 2 -and $path -ceq ($root+'/'+$metadataPaths[0])){$script:hMutated=$true;return [pscustomobject]@{Hash=('0'*64)}}
      return [pscustomobject]@{Hash=$hashes[$path]}
    }
    function Test-Path([string]$LiteralPath){
      $path=$LiteralPath.Replace('\','/')
      $allowed=@('MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','index.lock','rebase-merge','rebase-apply','sequencer','info/grafts') | ForEach-Object {'C:/fixture/'+$_}
      if($path -cnotin $allowed){$script:hUnexpected=$true;throw 'Unknown H fixture pending query.'}
      if($mode -ceq 'sequencer' -and $path -ceq 'C:/fixture/sequencer'){$script:hMutated=$true;return $true};return $false
    }
    function New-OctoberCoverageMutex([string]$Name){
      if($Name -cne $expectedMutexName){$script:hUnexpected=$true;throw 'Unexpected H fixture mutex name.'}
      return [Threading.Mutex]::new($false,$mutexName)
    }
    function Get-OctoberCompatibilityGitLines([string[]]$Arguments){
      $query=$Arguments -join '|'
      switch -Exact ($query){
        'rev-parse|HEAD'{if($mode -ceq 'head'){$script:hMutated=$true;return ('0'*40)};return '8e711da618ed9b04b9a9e267b5d4b5c7400b02fe'}
        'branch|--show-current'{if($mode -ceq 'branch-changes' -and (Seen 'branch') -gt 2){$script:hMutated=$true;return 'changed-branch'};return $binding.branch}
        'rev-parse|HEAD^{tree}'{return '24a44c88956aa94537faba4faed57a1c786b7809'}
        'ls-files|--unmerged'{return @()}
        'ls-files|--others|--exclude-standard'{if($mode -ceq 'untracked'){$script:hMutated=$true;return 'unexpected.txt'};return @()}
        'diff|--cached|--name-only|--diff-filter=ACMRTUXBD'{
          if($mode -ceq 'staged-source'){$script:hMutated=$true;return $sourcePaths[0]}
          if($fixturePhase -ceq 'pre_commit'){
            if($mode -ceq 'partial-metadata'){$script:hMutated=$true;return $metadataPaths[0..2]}
            return $metadataPaths
          };return @()
        }
        'diff|--name-only|--diff-filter=ACMRTUXBD'{
          $paths=if($fixturePhase -ceq 'pre_commit'){$sourcePaths}else{@($sourcePaths)+@($metadataPaths)}
          if($mode -ceq 'extra-owner'){$script:hMutated=$true;$paths+=@('unexpected.txt')};return $paths
        }
        'diff|--cached|--quiet|HEAD|--|apps'{return @()}
      }
      if($query -ceq ((@('ls-files','--stage','--')+@($sourcePaths)) -join '|')){
        if($mode -ceq 'source-index'){$script:hMutated=$true;return @($sourceIndex[0].Replace('100644','100755'))+$sourceIndex[1..2]};return $sourceIndex
      }
      if($query -ceq ((@('ls-files','--stage','--')+@($metadataPaths)) -join '|')){
        if($mode -ceq 'metadata-index-changes' -and (Seen 'metadata-index') -gt 2){$script:hMutated=$true;return @($metadataIndex[0].Replace('100644','100755'))+$metadataIndex[1..3]};return $metadataIndex
      }
      foreach($path in $metadataPaths){if($query -ceq ('rev-parse|HEAD:'+$path)){
        if($mode -ceq 'metadata-preimage'){$script:hMutated=$true;return ('0'*40)};return $blobs[$path]
      }}
      foreach($name in @('MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','index.lock','rebase-merge','rebase-apply','sequencer','info/grafts')){
        if($query -ceq ('rev-parse|--path-format=absolute|--git-path|'+$name)){return 'C:/fixture/'+$name}
      }
      $script:hUnexpected=$true;throw ('Unknown H fixture Git query: '+$query)
    }
    $collectorCases=0
    foreach($phase in @('implementation','pre_commit')){
      $fixturePhase=$phase;$mode='positive';$observations.Clear();$script:hUnexpected=$false
      Assert-RepairContract (Test-OctoberCoveragePreparation $phase) 'valid H preservation observations rejected.'
      Assert-RepairContract (-not $script:hUnexpected) 'H positive used unknown observation.';$collectorCases++
    }
    foreach($case in @('head','stale-provision','environment','source-hash','source-changes','source-reparse','source-index','staged-source','extra-owner','untracked','metadata-preimage','sequencer','partial-metadata','branch-changes','metadata-changes','metadata-index-changes')){
      $fixturePhase=if($case -ceq 'partial-metadata'){'pre_commit'}else{'implementation'}
      $mode=$case;$observations.Clear();$script:hUnexpected=$false;$script:hMutated=$false
      Assert-RepairContract (-not(Test-OctoberCoveragePreparation $fixturePhase)) "invalid H $case admitted."
      Assert-RepairContract ($script:hMutated -and -not $script:hUnexpected) "H $case rejected before its intended observation."
      $collectorCases++
      $mode='positive';$observations.Clear();$script:hUnexpected=$false
      Assert-RepairContract (Test-OctoberCoveragePreparation $fixturePhase) "H control after$case rejected.";$collectorCases++
    }
    Assert-RepairContract (-not(Test-OctoberCoveragePreparation 'device')) 'wrong H phase admitted.';$collectorCases++
    # Separate process: same-thread native mutex acquisition is recursive.
    $readyName=$mutexName+'_ready';$releaseName=$mutexName+'_release'
    $ready=[Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$readyName)
    $release=[Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$releaseName)
    $child=$null
    try {
      $code="`$m=[Threading.Mutex]::new(`$false,'$mutexName');`$r=[Threading.EventWaitHandle]::OpenExisting('$readyName');`$d=[Threading.EventWaitHandle]::OpenExisting('$releaseName');try{if(-not `$m.WaitOne(0)){exit 2};`$r.Set()|Out-Null;`$d.WaitOne(30000)|Out-Null;`$m.ReleaseMutex()}finally{`$m.Dispose();`$r.Dispose();`$d.Dispose()}"
      $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
      $child=Start-Process -FilePath powershell.exe -ArgumentList @('-NoProfile','-EncodedCommand',$encoded) -WindowStyle Hidden -PassThru
      Assert-RepairContract ($ready.WaitOne(10000)) 'H mutex child did not become ready.'
      $fixturePhase='implementation';$mode='positive';$observations.Clear();$script:hUnexpected=$false
      Assert-RepairContract (-not(Test-OctoberCoveragePreparation $fixturePhase)) 'held H mutex admitted.'
      Assert-RepairContract (-not $script:hUnexpected) 'held H mutex rejected on unknown observation.';$collectorCases++
      $null=$release.Set()
      Assert-RepairContract ($child.WaitForExit(10000) -and $child.ExitCode -eq 0) 'H mutex child did not release cleanly.'
      $observations.Clear()
      Assert-RepairContract (Test-OctoberCoveragePreparation $fixturePhase) 'H mutex release control rejected.';$collectorCases++
    } finally {$null=$release.Set();$ready.Dispose();$release.Dispose();if($child){$child.Dispose()}}
    Write-Output "Compatibility H preservation collector: $collectorCases labelled fixtures passed; no live admission or source mutation."
  }
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
  $probe=$captureFixture.Clone();$probe.executionId='default'
  Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $probe @captureFacts) 'explicit default execution rejected.';$captureCases++
  foreach($value in @('localstock_review','unknown',$true,0,$null,'')) {
    $probe=$captureFixture.Clone();$probe.executionId=$value
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe @captureFacts)) 'wrong/coerced default execution identity admitted.';$captureCases++
  }
  foreach($id in @('localstock_review','workspace_capture','store_live_capture','founder_capture')) {
    $plan=Get-OctoberCompatibilityExecutionPlan -ReportId store_layout_and_recovery -ExecutionId $id
    $supplement=$captureFixture.Clone();$supplement.reportId='store_layout_and_recovery';$supplement.executionId=$id
    $supplement.arguments=@($plan.Arguments);$supplement.runtimeDefines=@($plan.RuntimeDefines)
    $supplementFacts=$captureFacts.Clone();$supplementFacts.ReportId='store_layout_and_recovery'
    Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture $supplement -ExecutionId $id @supplementFacts) 'matching labelled supplemental capture rejected.';$captureCases++
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $supplement @supplementFacts)) 'supplemental capture reused as default evidence.';$captureCases++
    $probe=$supplement.Clone();$probe.arguments=@($captureFixture.arguments)
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'wrong supplemental filter/suite accepted.';$captureCases++
    $probe=$supplement.Clone();$null=$probe.Remove('executionId')
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'missing supplemental identity accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.runtimeDefines=@()
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'wrong supplemental defines accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.sourceCommit='0'*40
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'foreign supplemental source accepted.';$captureCases++
    Assert-RepairContract (Test-OctoberCompatibilityCapture -Capture ([pscustomobject]$supplement) -ExecutionId $id @supplementFacts) 'deserialized-style supplemental identity rejected.';$captureCases++
    $probe=$supplement.Clone();$probe.arguments=@(($plan.Arguments -join '|').Split([char]'|'))
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'pipe-split selector arguments accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.arguments=@($plan.Arguments -join '|')
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'joined native argument array accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.arguments=@($plan.Arguments);$probe.arguments[0]=@('test')
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'non-string argument element accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.arguments=$plan.Arguments -join '|'
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'scalar arguments accepted.';$captureCases++
    $probe=$supplement.Clone();$probe.runtimeDefines=$plan.RuntimeDefines -join '|'
    Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId $id @supplementFacts)) 'scalar runtime defines accepted.';$captureCases++
  }
  $probe=$captureFixture.Clone();$probe.executionId='unknown'
  Assert-RepairContract (-not(Test-OctoberCompatibilityCapture -Capture $probe -ExecutionId unknown @captureFacts)) 'unknown execution plan admitted.';$captureCases++
  Assert-RepairContract ($captureCases -eq 83) 'capture fixture inventory changed.'
  Write-Output "Compatibility capture provenance: $captureCases labelled automated fixtures passed; producer execution remains separately gated."
  $markerFacts=@{ReportId='store_layout_and_recovery';Source=$captureFacts.Source;
    Tree=$captureFacts.Tree;RegistrySha=$captureFacts.RegistrySha}
  $markerFixture=@{type='moolsocialSource';reportId=$markerFacts.ReportId;
    sourceCommit=$markerFacts.Source;sourceTree=$markerFacts.Tree;
    registrySha256=$markerFacts.RegistrySha;runtimeDefines=@()}
  Assert-RepairContract (Test-OctoberCompatibilitySourceMarker -Marker $markerFixture @markerFacts) 'legacy default source marker rejected.'
  $markerCases=1
  foreach($id in @('default','localstock_review','workspace_capture','store_live_capture','founder_capture')) {
    $plan=Get-OctoberCompatibilityExecutionPlan -ReportId $markerFacts.ReportId -ExecutionId $id
    $marker=$markerFixture.Clone();$marker.executionId=$id;$marker.runtimeDefines=@($plan.RuntimeDefines)
    Assert-RepairContract (Test-OctoberCompatibilitySourceMarker -Marker $marker -ExecutionId $id @markerFacts) 'matching marker identity rejected.';$markerCases++
    $probe=$marker.Clone();$probe.runtimeDefines=$plan.RuntimeDefines -join '|'
    Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $probe -ExecutionId $id @markerFacts)) 'scalar marker defines admitted.';$markerCases++
    foreach($field in @('type','reportId','sourceCommit','sourceTree','registrySha256','executionId')) {
      $probe=$marker.Clone();$probe[$field]='unknown'
      Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $probe -ExecutionId $id @markerFacts)) "wrong marker $field admitted.";$markerCases++
      $probe=$marker.Clone();$probe[$field]=$true
      Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $probe -ExecutionId $id @markerFacts)) "coerced marker $field admitted.";$markerCases++
    }
    if($id -cne 'default') {
      Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $marker @markerFacts)) 'supplemental marker reused as default.';$markerCases++
      $probe=$marker.Clone();$null=$probe.Remove('executionId')
      Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $probe -ExecutionId $id @markerFacts)) 'missing supplemental marker identity admitted.';$markerCases++
      $probe=$marker.Clone();$probe.runtimeDefines=@()
      Assert-RepairContract (-not(Test-OctoberCompatibilitySourceMarker -Marker $probe -ExecutionId $id @markerFacts)) 'wrong marker defines admitted.';$markerCases++
    }
  }
  Assert-RepairContract ($markerCases -eq 83) 'source marker fixture inventory changed.'
  Write-Output "Compatibility source marker identity: $markerCases labelled fixtures passed; no supplemental execution admitted."
  function New-LabelledExecutionEvents([string]$ExecutionId) {
    $executionPlan=Get-OctoberCompatibilityExecutionPlan -ReportId store_layout_and_recovery -ExecutionId $ExecutionId
    $capture=$captureFixture.Clone();$capture.reportId='store_layout_and_recovery';$capture.executionId=$ExecutionId
    $capture.arguments=@($executionPlan.Arguments);$capture.runtimeDefines=@($executionPlan.RuntimeDefines)
    $marker=$markerFixture.Clone();$marker.executionId=$ExecutionId;$marker.runtimeDefines=@($executionPlan.RuntimeDefines)
    $suitePath=$binding.worktreePath+'/apps/mobile/test/work_workspace_layout_safety_test.dart'
    $events=[Collections.Generic.List[object]]::new()
    $events.Add($marker);$events.Add(@{type='start'});$events.Add(@{type='allSuites';count=1})
    $events.Add(@{type='suite';suite=@{id=0;path=$suitePath}})
    $events.Add(@{type='testStart';test=@{id=0;suiteID=0;name=('loading '+$suitePath)}})
    $events.Add(@{type='testDone';testID=0;result='success';skipped=$false;hidden=$true})
    $names=if($ExecutionId -ceq 'default'){@(0..39 | ForEach-Object {'Host labelled execution fixture '+$_})}
      else{@($executionPlan.RequiredNames)}
    $testId=1
    foreach($name in $names) {
      $events.Add(@{type='testStart';test=@{id=$testId;suiteID=0;name=$name}})
      $events.Add(@{type='testDone';testID=$testId;result='success';skipped=$false;hidden=$false});$testId++
    }
    $events.Add(@{type='done';success=$true})
    return @{Capture=$capture;Events=$events.ToArray()}
  }
  $executionEventFacts=@{ReportId='store_layout_and_recovery';Source=$captureFacts.Source;
    Tree=$captureFacts.Tree;RegistrySha=$captureFacts.RegistrySha;ProducerBlob=$captureFacts.ProducerBlob;LogSha=$captureFacts.LogSha}
  $executionEventCases=0
  foreach($id in @('default','localstock_review','workspace_capture','historical_store_review',
      'historical_store_capture','store_live_capture','founder_capture')) {
    $fixture=New-LabelledExecutionEvents $id
    $result=Read-OctoberCompatibilityExecutionEvents -Events $fixture.Events -Capture $fixture.Capture -ExecutionId $id @executionEventFacts
    Assert-RepairContract ($null -ne $result -and $result.Skipped.Count -eq 0) "complete labelled $id execution rejected."
    $executionEventCases++
  }
  foreach($kind in @('capture-execution','marker-execution','missing-marker-execution',
      'capture-source','marker-source','source-after','nonzero-exit','unclean-after',
      'false-done','error-before-success','renamed-case','skipped-case','duplicate-case',
      'extra-case','duplicate-marker','late-marker','coerced-skipped','outside-suite',
      'unfinished-test','timestamp-final-lf','suite-id-string','test-id-string',
      'done-id-string','capture-schema-string','marker-defines','skipped-loader',
      'unhidden-loader','duplicate-loader','hidden-behavior','coerced-hidden',
      'missing-hidden','missing-loader')) {
    $fixture=New-LabelledExecutionEvents historical_store_review
    switch($kind) {
      'capture-execution' {$fixture.Capture.executionId='default'}
      'marker-execution' {$fixture.Events[0].executionId='default'}
      'missing-marker-execution' {$null=$fixture.Events[0].Remove('executionId')}
      'capture-source' {$fixture.Capture.sourceCommit='0'*40}
      'marker-source' {$fixture.Events[0].sourceCommit='0'*40}
      'source-after' {$fixture.Capture.sourceCommitAfter='0'*40}
      'nonzero-exit' {$fixture.Capture.exitCode=1}
      'unclean-after' {$fixture.Capture.cleanAfter=$false}
      'false-done' {$fixture.Events[-1].success=$false}
      'error-before-success' {$fixture.Events=@($fixture.Events[0..($fixture.Events.Count-2)])+@(@{type='error';message='Labelled failure'},$fixture.Events[-1])}
      'renamed-case' {$fixture.Events[6].test.name='Unrelated current test'}
      'skipped-case' {$fixture.Events[7].skipped=$true}
      'duplicate-case' {$fixture.Events[8].test.name=$fixture.Events[6].test.name}
      'extra-case' {$fixture.Events=@($fixture.Events[0..($fixture.Events.Count-2)])+@(
        @{type='testStart';test=@{id=99;suiteID=0;name='Unrelated extra case'}},
        @{type='testDone';testID=99;result='success';skipped=$false;hidden=$false},$fixture.Events[-1])}
      'duplicate-marker' {$fixture.Events=@($fixture.Events[0..1])+@($fixture.Events[0])+@($fixture.Events[2..($fixture.Events.Count-1)])}
      'late-marker' {$fixture.Events=@($fixture.Events[1],$fixture.Events[0])+@($fixture.Events[2..($fixture.Events.Count-1)])}
      'coerced-skipped' {$fixture.Events[7].skipped='false'}
      'outside-suite' {$fixture.Events[3].suite.path='C:/other/apps/mobile/test/work_workspace_layout_safety_test.dart'}
      'unfinished-test' {$fixture.Events=@($fixture.Events[0..6])+@($fixture.Events[8..($fixture.Events.Count-1)])}
      'timestamp-final-lf' {$fixture.Capture.startedAtUtc+="`n"}
      'suite-id-string' {$fixture.Events[3].suite.id='0'}
      'test-id-string' {$fixture.Events[6].test.id='1'}
      'done-id-string' {$fixture.Events[7].testID='1'}
      'capture-schema-string' {$fixture.Capture.schemaVersion='1'}
      'marker-defines' {$fixture.Events[0].runtimeDefines=@('MOOL_CAPTURE_WORK_STORE_1_40=true')}
      'skipped-loader' {$fixture.Events[5].skipped=$true}
      'unhidden-loader' {$fixture.Events[5].hidden=$false}
      'duplicate-loader' {$fixture.Events=@($fixture.Events[0..5])+@(
        @{type='testStart';test=@{id=99;suiteID=0;name=$fixture.Events[4].test.name}},
        @{type='testDone';testID=99;result='success';skipped=$false;hidden=$true})+@($fixture.Events[6..($fixture.Events.Count-1)])}
      'hidden-behavior' {$fixture.Events[7].hidden=$true}
      'coerced-hidden' {$fixture.Events[7].hidden='false'}
      'missing-hidden' {$null=$fixture.Events[7].Remove('hidden')}
      'missing-loader' {$fixture.Events=@($fixture.Events[0..3])+@($fixture.Events[6..($fixture.Events.Count-1)])}
    }
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionEvents -Events $fixture.Events -Capture $fixture.Capture -ExecutionId historical_store_review @executionEventFacts)) "execution event validator admitted $kind."
    $executionEventCases++
  }
  # A later passing supplement cannot make this failed default execution valid.
  $fixture=New-LabelledExecutionEvents default;$fixture.Events[7].result='failure'
  Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionEvents -Events $fixture.Events -Capture $fixture.Capture -ExecutionId default @executionEventFacts)) 'failed default run accepted.'
  $executionEventCases++
  $fixture=New-LabelledExecutionEvents default
  $fixture.Events=@($fixture.Events[0..81])+@($fixture.Events[-1])
  Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionEvents -Events $fixture.Events -Capture $fixture.Capture -ExecutionId default @executionEventFacts)) 'under-covered default run accepted.'
  $executionEventCases++
  Assert-RepairContract ($executionEventCases -eq 41) 'execution event fixture count changed.'
  Write-Output "Compatibility execution events: $executionEventCases labelled host fixtures passed; actual file hashes and visual qualification remain separate."
  & {
    $jsonCases=0
    foreach($json in @('{}','{"a":1}','{"a":"\/\b\f\r"}','{"a":[true,false,null,0,-1,1.5,1e2]}',
        '{"a":{"x":1},"b":{"x":2}}','{"a":[{"x":1},{"x":2}]}',
        '{"a":"x","b":"x"}','{"a\\b":1,"a\"b":2}',
        '{"nested":{"empty":[],"object":{}},"literal":"},:[{\\\""}')){
      $bytes=[Text.UTF8Encoding]::new($false).GetBytes($json)
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityJsonObject $bytes)) 'valid labelled JSON rejected.';$jsonCases++
    }
    $utc='2026-10-09T12:34:56.1234567Z'
    $payload=Read-OctoberCompatibilityJsonObject ([Text.UTF8Encoding]::new($false).GetBytes('{"at":"'+$utc+'"}'))
    Assert-RepairContract ($null -ne $payload -and $payload.at -is [string] -and $payload.at -ceq $utc) 'UTC string changed during JSON parse.';$jsonCases++
    $dateKey='2026-10-09T12:34:56Z'
    $payload=Read-OctoberCompatibilityJsonObject ([Text.UTF8Encoding]::new($false).GetBytes('{"'+$dateKey+'":1}'))
    Assert-RepairContract ($null -ne $payload -and @($payload.PSObject.Properties).Count -eq 1 -and
      @($payload.PSObject.Properties.Name)[0] -ceq $dateKey) 'date-looking JSON property name changed.';$jsonCases++
    $payload=Read-OctoberCompatibilityJsonObject ([Text.UTF8Encoding]::new($false).GetBytes('{"a":"\n\t\u0000"}'))
    Assert-RepairContract ($null -ne $payload -and $payload.a -ceq ("`n`t"+[char]0)) 'escaped control value changed.';$jsonCases++
    foreach($control in @(0,9,10,31)){
      $rawControlCases=@(('{"a":"'+[char]$control+'"}'),('{"a'+[char]$control+'":1}'),
        ('{"a":"'+'\'+[char]$control+'"}'))
      Assert-RepairContract ($rawControlCases.Count -eq 3) 'raw-control fixture expressions collapsed.'
      foreach($json in $rawControlCases){
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityJsonObject ([Text.UTF8Encoding]::new($false).GetBytes($json)))) 'raw control character JSON admitted.';$jsonCases++
      }
    }
    foreach($json in @('{"a":1,"a":2}','{"name":1,"na\u006de":2}',
        '{"a":1,"A":2}','{"2026-10-09T12:34:56Z":1,"\u0032026-10-09T12:34:56Z":2}',
        '{"p":{"a":1,"a":2}}','{"p":[{"a":1,"a":2}]}',
        '{"a\\b":1,"a\\b":2}','{"a\"b":1,"a\"b":2}',
        '{}{}','{} true','[]','[{}]','null','{"a":1,}','{"a":[1,]}',
        '{/*comment*/"a":1}','{"a":1//comment
}', '{"a":01}','{"a":.5}','{"a":+1}','{"a":1e}',
        '{"a":truefalse}','{"a":NaN}','{"a":Infinity}','{"a":undefined}',
        '{a:1}',"{'a':1}",'{"a" 1}','{"a":}','{"a":[1}}','{"a":"unfinished}',
        '{"a":"bad\q"}','{"a":"bad\u000x"}','{"a":1',
        ('{"a":"\'+[char]39+'"}'),('{"a\'+[char]39+'":1}'))){
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityJsonObject ([Text.UTF8Encoding]::new($false).GetBytes($json)))) "invalid labelled JSON admitted: $json";$jsonCases++
    }
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilityJsonObject ([byte[]]@(255)))) 'invalid UTF8 accepted.';$jsonCases++
    Assert-RepairContract ($jsonCases -eq 61) 'JSON fixture count changed.'
    Write-Output "Compatibility strict JSON: $jsonCases labelled host fixtures passed; no approval or source qualification."
    # Labelled shape fixtures only: no approved reference or rendered image.
    $slot=[pscustomobject]@{slotId='H01-visual-1';captureTarget='Key(store-review-root)';
      originalPath='workspace-choose.png';approvedAlternativePath='01/workspace-choose.png';
      actualRenderRelativePath='01/workspace-choose.png';approvalRecordRelativePath='approvals/H01-visual-1.json';
      expectedGeometry=[pscustomobject]@{viewportWidth=412;viewportHeight=915;devicePixelRatio=1;
        textScale=1;bottomViewPadding=34;bottomViewInsets=0}}
    $facts=@{Slot=$slot;TestKey='original-exact-key';ExecutionId='workspace_capture';
      Source=('a'*40);Tree=('b'*40);ComparatorImplementationSha256=('C'*64);
      CaptureBounds=[pscustomobject]@{left=0;top=0;right=412;bottom=915}}
    function New-LabelledVisualShape {
      return [pscustomobject]@{sourceCommit=('a'*40);sourceTree=('b'*40);executionId='workspace_capture';
        testKey='original-exact-key';slotId='H01-visual-1';captureTarget='Key(store-review-root)';textScale=1;
        referencePath='01/workspace-choose.png';referenceSha256Before=('D'*64);referenceSha256After=('D'*64);
        actualRenderPath='01/workspace-choose.png';actualRenderSha256=('E'*64);
        approvalRecordPath='approvals/H01-visual-1.json';approvalRecordSha256=('F'*64);
        approvalDecision='accept_this_exact_source_bound_visual_reference_for_this_retained_case';
        approvedReferenceSha256=('D'*64);comparatorIdentity='flutter_test.LocalFileComparator';
        comparatorImplementationSha256=('C'*64);strictComparisonPassed=$true;differentPixelCount=0;
        viewportWidth=412;viewportHeight=915;devicePixelRatio=1;bottomViewPadding=34;bottomViewInsets=0;
        captureLogicalBounds=[pscustomobject]@{left=0;top=0;right=412;bottom=915};
        renderedPixelWidth=412;renderedPixelHeight=915}
    }
    $visualCases=0
    $evidence=New-LabelledVisualShape
    Assert-RepairContract (Test-OctoberCompatibilityVisualEvidenceShape -Evidence $evidence @facts) 'labelled visual shape rejected.';$visualCases++
    $evidence.referencePath=$slot.originalPath
    Assert-RepairContract (Test-OctoberCompatibilityVisualEvidenceShape -Evidence $evidence @facts) 'original reference shape rejected.';$visualCases++
    $evidence.captureLogicalBounds.right=412.5;$evidence.renderedPixelWidth=413
    $halfPixelFacts=$facts.Clone();$halfPixelFacts.CaptureBounds=[pscustomobject]@{left=0;top=0;right=412.5;bottom=915}
    Assert-RepairContract (Test-OctoberCompatibilityVisualEvidenceShape -Evidence $evidence @halfPixelFacts) 'positive half-pixel Dart rounding rejected.';$visualCases++
    $fields=@((New-LabelledVisualShape).PSObject.Properties.Name)
    Assert-RepairContract ($fields.Count -eq 28) 'visual field inventory changed.'
    foreach($field in $fields){
      foreach($kind in @('missing','null','case-variant')){
        $evidence=New-LabelledVisualShape
        switch($kind){
          'missing' {$evidence.PSObject.Properties.Remove($field)}
          'null' {$evidence.$field=$null}
          'case-variant' {$value=$evidence.$field;$evidence.PSObject.Properties.Remove($field);$evidence|Add-Member -NotePropertyName $field.ToUpperInvariant() -NotePropertyValue $value}
        }
        Assert-RepairContract (-not(Test-OctoberCompatibilityVisualEvidenceShape -Evidence $evidence @facts)) "visual shape admitted $kind $field.";$visualCases++
      }
    }
    $negatives=@(
      @{name='extra';mutate={param($e)$e|Add-Member -NotePropertyName extra -NotePropertyValue 1}},
      @{name='wrong-source';mutate={param($e)$e.sourceCommit='c'*40}},
      @{name='wrong-tree';mutate={param($e)$e.sourceTree='d'*40}},
      @{name='wrong-slot';mutate={param($e)$e.slotId='H02-visual-1'}},
      @{name='wrong-key';mutate={param($e)$e.testKey='other-key'}},
      @{name='wrong-execution';mutate={param($e)$e.executionId='default'}},
      @{name='wrong-target';mutate={param($e)$e.captureTarget='Scaffold.first'}},
      @{name='wrong-comparator';mutate={param($e)$e.comparatorIdentity='other'}},
      @{name='wrong-comparator-hash';mutate={param($e)$e.comparatorImplementationSha256='0'*64}},
      @{name='wrong-reference';mutate={param($e)$e.referencePath='other.png'}},
      @{name='wrong-render';mutate={param($e)$e.actualRenderPath='other.png'}},
      @{name='wrong-approval';mutate={param($e)$e.approvalRecordPath='approvals/other.json'}},
      @{name='unapproved';mutate={param($e)$e.approvalDecision='pending'}},
      @{name='changed-reference';mutate={param($e)$e.referenceSha256After='0'*64}},
      @{name='wrong-approved-hash';mutate={param($e)$e.approvedReferenceSha256='0'*64}},
      @{name='hash-newline';mutate={param($e)$e.actualRenderSha256+="`n"}},
      @{name='false-comparison';mutate={param($e)$e.strictComparisonPassed=$false}},
      @{name='truthy-comparison';mutate={param($e)$e.strictComparisonPassed='true'}},
      @{name='nonzero-difference';mutate={param($e)$e.differentPixelCount=1}},
      @{name='fractional-difference';mutate={param($e)$e.differentPixelCount=0.0}},
      @{name='string-number';mutate={param($e)$e.textScale='1'}},
      @{name='bool-number';mutate={param($e)$e.devicePixelRatio=$true}},
      @{name='wrong-dpr';mutate={param($e)$e.devicePixelRatio=2}},
      @{name='wrong-geometry';mutate={param($e)$e.bottomViewInsets=280}},
      @{name='nonfinite';mutate={param($e)$e.captureLogicalBounds.right=[double]::NaN}},
      @{name='infinite';mutate={param($e)$e.captureLogicalBounds.bottom=[double]::PositiveInfinity}},
      @{name='bounds-string';mutate={param($e)$e.captureLogicalBounds.left='0'}},
      @{name='bounds-extra';mutate={param($e)$e.captureLogicalBounds|Add-Member -NotePropertyName crop -NotePropertyValue 1}},
      @{name='bounds-inverted';mutate={param($e)$e.captureLogicalBounds.right=-1}},
      @{name='shifted-region';mutate={param($e)$e.captureLogicalBounds.left=1;$e.captureLogicalBounds.right=413}},
      @{name='smaller-crop';mutate={param($e)$e.captureLogicalBounds.right=400;$e.renderedPixelWidth=400}},
      @{name='pixel-overflow';mutate={param($e)$e.renderedPixelWidth=[long]::MaxValue}},
      @{name='bounds-overflow';mutate={param($e)$e.captureLogicalBounds.right=[double]::MaxValue}},
      @{name='pixel-fraction';mutate={param($e)$e.renderedPixelHeight=915.5}},
      @{name='pixel-mismatch';mutate={param($e)$e.renderedPixelWidth=411}},
      @{name='pixel-string';mutate={param($e)$e.renderedPixelHeight='915'}}
    )
    foreach($negative in $negatives){
      $evidence=New-LabelledVisualShape;& $negative.mutate $evidence
      Assert-RepairContract (-not(Test-OctoberCompatibilityVisualEvidenceShape -Evidence $evidence @facts)) "visual shape admitted $($negative.name).";$visualCases++
    }
    Assert-RepairContract ($visualCases -eq (3+3*$fields.Count+$negatives.Count)) 'visual shape case count changed.'
    Write-Output "Compatibility visual shapes: $visualCases labelled fixtures passed; no reference, approval, render or comparison qualified."
    & {
      function Invoke-LabelledVisualSlot([string]$Mode) {
        $slotFixtureEvidence=New-LabelledVisualShape
        $slotFixtureSlot=$slot|ConvertTo-Json -Depth 8|ConvertFrom-Json
        $slotFixtureSlot|Add-Member -NotePropertyMembers @{actualRenderPathBase='actualRenderArtifactRoot';
          approvalRecordPathBase='approvalArtifactRoot';approvedAlternativePathBase='approvalArtifactRoot';
          originalPathBase='compatibilitySourceRoot';originalSha256=$null}
        $slotFixtureProtocol=Get-OctoberCompatibilityVisualProtocol
        $slotFixtureResolution=[pscustomobject]@{approvalArtifactRoot='C:/labelled-host/approved';
          actualRenderArtifactRoot='compatibilitySourceRoot/apps/mobile/build/compat-visual-candidates-20261009'}
        $slotFixtureDecision=[pscustomobject]@{sourceCommit=('a'*40);sourceTree=('b'*40);executionId='workspace_capture';
          testKey='original-exact-key';slotId='H01-visual-1';captureTarget='Key(store-review-root)';
          referencePath=$slotFixtureEvidence.referencePath;referenceSha256=('D'*64);actualRenderSha256=('E'*64);
          approvalRecordPath=$slotFixtureEvidence.approvalRecordPath;approvalRecordSha256=('F'*64);
          founderMessageLocator='labelled fixture only, not human approval';decision=$slotFixtureProtocol.decision;
          geometry=$slotFixtureSlot.expectedGeometry}
        $slotFixtureRecord=$slotFixtureDecision|ConvertTo-Json -Depth 8|ConvertFrom-Json
        $slotFixtureRecord.PSObject.Properties.Remove('approvalRecordSha256')
        $slotFixtureObservation=[pscustomobject]@{}
        foreach($slotFixtureName in $slotFixtureProtocol.observationRequiredFields) {
          $slotFixtureValue=switch -CaseSensitive ($slotFixtureName) {
            'schemaVersion' {1}
            'comparatorInvoked' {$true}
            'comparisonPassed' {$true}
            default {$slotFixtureEvidence.$slotFixtureName}
          }
          $slotFixtureObservation|Add-Member -NotePropertyName $slotFixtureName -NotePropertyValue $slotFixtureValue
        }
        $slotFixtureContext=@{Mode=$Mode;Lease=$null;PairReached=$false;FinalHashReached=$false}
        switch -CaseSensitive ($Mode) {
          'missing-decision' {$slotFixtureDecision=$null}
          'wrong-observation' {$slotFixtureObservation.actualRenderSha256='0'*64}
          'wrong-decision' {$slotFixtureDecision.sourceCommit='0'*40}
          'wrong-record' {$slotFixtureRecord.sourceCommit='0'*40}
          'missing-record-field' {$slotFixtureRecord.PSObject.Properties.Remove('founderMessageLocator')}
          'record-geometry-string' {$slotFixtureRecord.geometry.viewportWidth='412'}
          'wrong-root' {$slotFixtureSlot.actualRenderPathBase='caller override'}
          'self-hashed-record' {$slotFixtureRecord|Add-Member -NotePropertyName approvalRecordSha256 -NotePropertyValue ('F'*64)}
        }
        # Serialize the13-field body first, then bind its real hash externally.
        # The record never needs a SHA256 fixed point to satisfy a positive.
        $slotFixtureRecordBytes=[Text.Encoding]::UTF8.GetBytes(($slotFixtureRecord|ConvertTo-Json -Depth 8 -Compress))
        $slotFixtureContext.RecordHash=Get-OctoberCompatibilityByteHash $slotFixtureRecordBytes
        $slotFixtureEvidence.approvalRecordSha256=$slotFixtureContext.RecordHash
        if($null -ne $slotFixtureDecision){$slotFixtureDecision.approvalRecordSha256=$slotFixtureContext.RecordHash}
        function Open-OctoberCompatibilityVisualArtifact {
          param([string]$Base,[string]$RelativePath,[string]$ExpectedSha256)
          if($slotFixtureContext.Mode -ceq 'missing-approval'){return $null}
          if($Base -cne 'C:/labelled-host/approved' -or $RelativePath -cne 'approvals/H01-visual-1.json' -or
              $ExpectedSha256 -cne (Get-OctoberCompatibilityByteHash $slotFixtureRecordBytes)){return $null}
          $slotFixtureContext.Lease=[IO.MemoryStream]::new()
          return [pscustomobject]@{CanonicalPath='C:/labelled-host/approved/approvals/H01-visual-1.json';
            Bytes=$slotFixtureRecordBytes;Stream=$slotFixtureContext.Lease}
        }
        function Test-OctoberCompatibilityLockedPngPair {
          param([string]$ReferenceBase,[string]$ReferencePath,[string]$ReferenceSha256,
            [string]$ActualBase,[string]$ActualPath,[string]$ActualSha256,[int]$Width,[int]$Height)
          $slotFixtureContext.PairReached=$true
          return $slotFixtureContext.Mode -cne 'pair-failed' -and $ReferenceBase -ceq 'C:/labelled-host/approved' -and
            $ReferencePath -ceq '01/workspace-choose.png' -and $ReferenceSha256 -ceq ('D'*64) -and
            ([IO.Path]::GetFullPath($ActualBase)) -ceq ([IO.Path]::GetFullPath((Join-Path (Get-OctoberCompatibilityBinding).worktreePath 'apps/mobile/build/compat-visual-candidates-20261009'))) -and
            $ActualPath -ceq '01/workspace-choose.png' -and $ActualSha256 -ceq ('E'*64) -and $Width -eq 412 -and $Height -eq 915
        }
        function Get-OctoberCoverageBoundHash {
          $slotFixtureContext.FinalHashReached=$true
          if($slotFixtureContext.Mode -ceq 'changed-approval'){return ('0'*64)};return $slotFixtureContext.RecordHash
        }
        $slotFixtureResult=Test-OctoberCompatibilityVisualSlot -Evidence $slotFixtureEvidence -Slot $slotFixtureSlot -Decision $slotFixtureDecision `
          -Observation $slotFixtureObservation -Resolution $slotFixtureResolution -Protocol $slotFixtureProtocol -TestKey original-exact-key `
          -ExecutionId workspace_capture -Source ('a'*40) -Tree ('b'*40) -ComparatorImplementationSha256 ('C'*64)
        Assert-RepairContract ($slotFixtureResult -eq ($Mode -ceq 'positive')) ('visual slot composition result incorrect: '+$Mode)
        if($null -ne $slotFixtureContext.Lease){Assert-RepairContract (-not $slotFixtureContext.Lease.CanRead) ('approval lease not disposed: '+$Mode)}
        if($Mode -cin @('positive','pair-failed','changed-approval')){Assert-RepairContract $slotFixtureContext.PairReached ('pair boundary not reached: '+$Mode)}
        if($Mode -cin @('positive','changed-approval')){Assert-RepairContract $slotFixtureContext.FinalHashReached ('final approval hash not reached: '+$Mode)}
      }
      foreach($slotFixtureMode in @('positive','missing-decision','wrong-observation','wrong-decision','wrong-record',
        'missing-record-field','record-geometry-string','pair-failed','changed-approval','wrong-root','missing-approval','self-hashed-record')) {
        Invoke-LabelledVisualSlot $slotFixtureMode
      }
      Write-Output 'Compatibility visual slot composition: 12 labelled in-memory cases passed; record bytes actually hashed, no actual approval, image or source qualification.'
    }
  }
  & {
    # Temporary host files only; never runtime storage or source/device evidence.
    $fileFixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('moolsocial-labelled-execution-'+[Guid]::NewGuid().ToString('N'))
    Assert-RepairContract (-not(Test-Path -LiteralPath $fileFixtureRoot)) 'temporary fixture root already exists.'
    $fileFixtureBuild=Join-Path $fileFixtureRoot 'apps/mobile/build'
    $null=[IO.Directory]::CreateDirectory($fileFixtureBuild)
    $binding=@{worktreePath=$fileFixtureRoot.Replace('\','/')}
    function Get-OctoberCompatibilityBinding {return $binding}
    $realBoundHash=${function:Get-OctoberCoverageBoundHash}
    $realEventReader=${function:Read-OctoberCompatibilityExecutionEvents}
    $script:fileEventParserCalls=0
    function Read-OctoberCompatibilityExecutionEvents {
      param([object[]]$Events,[object]$Capture,[string]$ReportId,[string]$ExecutionId,
        [string]$Source,[string]$Tree,[string]$RegistrySha,[string]$ProducerBlob,[string]$LogSha)
      $script:fileEventParserCalls++
      return & $realEventReader @PSBoundParameters
    }
    $fileHashCounts=@{};$fileMode='positive';$fileBoundaryObserved=$false
    function Get-OctoberCoverageBoundHash([string]$Path) {
      $fileName=[IO.Path]::GetFileName($Path)
      if(-not $fileHashCounts.ContainsKey($fileName)){$fileHashCounts[$fileName]=0}
      $fileHashCounts[$fileName]++
      if($fileMode -ceq 'reparse-rejection'){$script:fileBoundaryObserved=$true;throw 'Labelled ancestor reparse rejection.'}
      if($fileMode -ceq 'changed-after-read' -and $fileHashCounts[$fileName] -gt 1){$script:fileBoundaryObserved=$true;return ('0'*64)}
      $manifestFinalTargets=@{
        'manifest-final-log'=@('labelled-execution.jsonl',3)
        'manifest-final-stderr'=@('labelled-execution.jsonl.stderr.txt',3)
        'manifest-final-capture'=@('labelled-execution.jsonl.capture.json',5)
        'manifest-final-manifest'=@('labelled-execution.jsonl.visual.json',3)
      }
      if($manifestFinalTargets.ContainsKey($fileMode) -and
          $fileName -ceq $manifestFinalTargets[$fileMode][0] -and
          $fileHashCounts[$fileName] -eq $manifestFinalTargets[$fileMode][1]){
        $script:fileBoundaryObserved=$true;return ('0'*64)
      }
      if($fileMode -ceq 'buffered-byte-change' -and $fileName -ceq 'labelled-execution.jsonl' -and $fileHashCounts[$fileName] -eq 1){
        $hash=& $realBoundHash $Path
        # Leading JSON whitespace changes bytes without invalidating any event.
        # A zero parser-call assertion below distinguishes the buffer boundary
        # from the later path-stability rejection of these changed valid bytes.
        $validJsonLines=[IO.File]::ReadAllText($Path)
        [IO.File]::WriteAllText($Path,(' '+$validJsonLines),[Text.UTF8Encoding]::new($false))
        $script:fileBoundaryObserved=$true;return $hash
      }
      return & $realBoundHash $Path
    }
    $fileRelative='apps/mobile/build/labelled-execution.jsonl'
    $fileLog=Join-Path $fileFixtureRoot $fileRelative
    $fileCapture=$fileLog+'.capture.json';$fileStderr=$fileLog+'.stderr.txt'
    $fileFixturePassed=$false
    function Write-LabelledExecutionFiles {
      $fixture=New-LabelledExecutionEvents historical_store_review
      $fixture.Capture.workingDirectory=$binding.worktreePath+'/apps/mobile'
      $fixture.Capture.stderrPath=$fileRelative+'.stderr.txt'
      $lines=@($fixture.Events | ForEach-Object {ConvertTo-Json -InputObject $_ -Depth 20 -Compress})
      [IO.File]::WriteAllLines($fileLog,[string[]]$lines,[Text.UTF8Encoding]::new($false))
      [IO.File]::WriteAllText($fileStderr,'',[Text.UTF8Encoding]::new($false))
      $fixture.Capture.stdoutSha256=(Get-FileHash -LiteralPath $fileLog -Algorithm SHA256).Hash
      $fixture.Capture.stderrSha256=(Get-FileHash -LiteralPath $fileStderr -Algorithm SHA256).Hash
      [IO.File]::WriteAllText($fileCapture,(ConvertTo-Json -InputObject $fixture.Capture -Depth 20),[Text.UTF8Encoding]::new($false))
      return [pscustomobject]@{executionId='historical_store_review';path=$fileRelative;
        capturePath=($fileRelative+'.capture.json');sha256=$fixture.Capture.stdoutSha256;
        captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash;runtimeDefines=@()}
    }
    function Read-LabelledCapture {
      $jsonParameters=@{}
      if((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')){$jsonParameters.DateKind='String'}
      return Get-Content -Raw -LiteralPath $fileCapture|ConvertFrom-Json @jsonParameters
    }
    function Refresh-LabelledExecutionHashes([object]$Evidence) {
      $capture=Read-LabelledCapture
      $Evidence.sha256=(Get-FileHash -LiteralPath $fileLog -Algorithm SHA256).Hash
      $capture.stdoutSha256=$Evidence.sha256
      [IO.File]::WriteAllText($fileCapture,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
      $Evidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash
    }
    $fileFacts=$executionEventFacts.Clone();$fileFacts.Remove('LogSha');$fileFacts.ExecutionId='historical_store_review'
    $fileCases=0
    try {
      $evidence=Write-LabelledExecutionFiles
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityExecutionEvidence -Evidence $evidence @fileFacts)) 'complete actual host fixture files rejected.'
      Assert-RepairContract ($script:fileEventParserCalls -eq 1) 'positive file reader did not reach the real event parser once.'
      $fileCases++
      Refresh-LabelledExecutionHashes $evidence
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityExecutionEvidence -Evidence $evidence @fileFacts)) 'unchanged UTC-preserving rewrite control rejected.'
      Assert-RepairContract ($script:fileEventParserCalls -eq 2) 'rewrite control did not reach the real event parser once.'
      $fileCases++
      foreach($kind in @('missing-log','missing-capture','missing-stderr','wrong-log-hash',
          'wrong-capture-hash','wrong-stderr-bytes','invalid-capture-json','invalid-log-json',
          'blank-log-line','array-log-line','wrong-stderr-path','wrong-defines',
          'traversal-path','final-lf-path','reparse-rejection','changed-after-read',
          'array-capture-root','buffered-byte-change','invalid-utf8-log',
          'duplicate-capture-key','duplicate-event-key','case-colliding-event-key')) {
        $evidence=Write-LabelledExecutionFiles;$fileHashCounts.Clear();$fileMode='positive';$script:fileBoundaryObserved=$false;$script:fileEventParserCalls=0
        switch($kind) {
          'missing-log' {Remove-Item -LiteralPath $fileLog}
          'missing-capture' {Remove-Item -LiteralPath $fileCapture}
          'missing-stderr' {Remove-Item -LiteralPath $fileStderr}
          'wrong-log-hash' {$evidence.sha256='0'*64}
          'wrong-capture-hash' {$evidence.captureSha256='0'*64}
          'wrong-stderr-bytes' {[IO.File]::WriteAllText($fileStderr,'changed',[Text.UTF8Encoding]::new($false))}
          'invalid-capture-json' {[IO.File]::WriteAllText($fileCapture,'{broken',[Text.UTF8Encoding]::new($false));$evidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash}
          'invalid-log-json' {[IO.File]::WriteAllText($fileLog,'{broken',[Text.UTF8Encoding]::new($false));Refresh-LabelledExecutionHashes $evidence}
          'blank-log-line' {$text=[IO.File]::ReadAllText($fileLog);[IO.File]::WriteAllText($fileLog,("`n"+$text),[Text.UTF8Encoding]::new($false));Refresh-LabelledExecutionHashes $evidence}
          'array-log-line' {$lines=[IO.File]::ReadAllLines($fileLog);$lines[0]='['+$lines[0]+']';[IO.File]::WriteAllLines($fileLog,$lines,[Text.UTF8Encoding]::new($false));Refresh-LabelledExecutionHashes $evidence}
          'wrong-stderr-path' {$capture=Read-LabelledCapture;$capture.stderrPath='apps/mobile/build/other.stderr.txt';[IO.File]::WriteAllText($fileCapture,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false));$evidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash}
          'wrong-defines' {$evidence.runtimeDefines=@('')}
          'traversal-path' {$evidence.path='apps/mobile/build/../outside.jsonl';$evidence.capturePath=$evidence.path+'.capture.json'}
          'final-lf-path' {$evidence.path+="`n";$evidence.capturePath=$evidence.path+'.capture.json'}
          'reparse-rejection' {$fileMode=$kind}
          'changed-after-read' {$fileMode=$kind}
          'array-capture-root' {$text=[IO.File]::ReadAllText($fileCapture);[IO.File]::WriteAllText($fileCapture,('['+$text+']'),[Text.UTF8Encoding]::new($false));$evidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash}
          'buffered-byte-change' {$fileMode=$kind}
          'invalid-utf8-log' {[IO.File]::WriteAllBytes($fileLog,[byte[]]@(255));Refresh-LabelledExecutionHashes $evidence}
          'duplicate-capture-key' {
            $text=[IO.File]::ReadAllText($fileCapture)
            $text=$text.Insert($text.IndexOf('{')+1,'"schemaVersion":1,')
            [IO.File]::WriteAllText($fileCapture,$text,[Text.UTF8Encoding]::new($false))
            $evidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash
          }
          'duplicate-event-key' {
            $lines=[IO.File]::ReadAllLines($fileLog)
            $lines[0]=$lines[0].Insert(1,'"type":"moolsocialSource",')
            [IO.File]::WriteAllLines($fileLog,$lines,[Text.UTF8Encoding]::new($false))
            Refresh-LabelledExecutionHashes $evidence
          }
          'case-colliding-event-key' {
            $lines=[IO.File]::ReadAllLines($fileLog)
            $lines[0]=$lines[0].Insert(1,'"TYPE":"moolsocialSource",')
            [IO.File]::WriteAllLines($fileLog,$lines,[Text.UTF8Encoding]::new($false))
            Refresh-LabelledExecutionHashes $evidence
          }
        }
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityExecutionEvidence -Evidence $evidence @fileFacts)) "actual host fixture reader admitted $kind."
        if($kind -cin @('reparse-rejection','changed-after-read','buffered-byte-change')){Assert-RepairContract $script:fileBoundaryObserved 'file boundary rejection was not reached.'}
        if($kind -ceq 'buffered-byte-change') {
          Assert-RepairContract ($script:fileEventParserCalls -eq 0) 'changed buffered bytes reached event parsing before rejection.'
        }
        $fileCases++
      }
      $fileMode='positive';$fileHashCounts.Clear();$script:fileEventParserCalls=0;$evidence=Write-LabelledExecutionFiles
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityExecutionEvidence -Evidence $evidence @fileFacts)) 'actual file control after negative fixtures rejected.';$fileCases++
      Assert-RepairContract ($script:fileEventParserCalls -eq 1) 'final control did not reach the real event parser once.'
      Assert-RepairContract ($fileCases -eq 25) 'actual file fixture count changed.'
      $artifactCases=0
      $fileHashCounts.Clear()
      $payload=Read-OctoberCompatibilityVisualArtifactBytes -Base $fileFixtureRoot -RelativePath $fileRelative -ExpectedSha256 $evidence.sha256
      Assert-RepairContract ($null -ne $payload -and $payload.Bytes -is [byte[]] -and
        (Get-OctoberCompatibilityByteHash $payload.Bytes) -ceq $evidence.sha256 -and
        $payload.CanonicalPath -ceq [IO.Path]::GetFullPath($fileLog)) 'labelled artifact verified-byte control rejected.';$artifactCases++
      foreach($kind in @('wrong-hash','missing-path','traversal','sibling-prefix','path-newline',
          'rooted-relative','drive-relative-path','drive-relative-base','relative-base','non-directory-base',
          'reparse-rejection','changed-after-read','buffered-byte-change')){
        $evidence=Write-LabelledExecutionFiles;$fileHashCounts.Clear();$fileMode='positive';$script:fileBoundaryObserved=$false
        $artifactArguments=@{Base=$fileFixtureRoot;RelativePath=$fileRelative;ExpectedSha256=$evidence.sha256}
        switch($kind){
          'wrong-hash' {$artifactArguments.ExpectedSha256='0'*64}
          'missing-path' {$artifactArguments.RelativePath='missing.png'}
          'traversal' {$artifactArguments.RelativePath='apps/../outside.png'}
          'sibling-prefix' {$artifactArguments.RelativePath='../sibling/file.png'}
          'path-newline' {$artifactArguments.RelativePath+="`n"}
          'rooted-relative' {$artifactArguments.RelativePath=$fileLog}
          'drive-relative-path' {$artifactArguments.RelativePath='C:relative.png'}
          'drive-relative-base' {$artifactArguments.Base='C:relative'}
          'relative-base' {$artifactArguments.Base='.'}
          'non-directory-base' {$artifactArguments.Base=$fileLog}
          'reparse-rejection' {$fileMode=$kind}
          'changed-after-read' {$fileMode=$kind}
          'buffered-byte-change' {$fileMode=$kind}
        }
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityVisualArtifactBytes @artifactArguments)) "artifact reader admitted $kind.";$artifactCases++
        if($kind -cin @('reparse-rejection','changed-after-read','buffered-byte-change')){
          Assert-RepairContract $script:fileBoundaryObserved 'artifact boundary negative was not reached.'
        }
        if($kind -ceq 'buffered-byte-change'){
          Assert-RepairContract ($fileHashCounts['labelled-execution.jsonl'] -eq 1) 'artifact buffer mismatch reached final path observation.'
        }
        if($kind -ceq 'changed-after-read'){
          Assert-RepairContract ($fileHashCounts['labelled-execution.jsonl'] -eq 2) 'artifact final change rejected before its intended observation.'
        }
      }
      $fileMode='positive';$fileHashCounts.Clear();$evidence=Write-LabelledExecutionFiles
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityVisualArtifactBytes -Base $fileFixtureRoot -RelativePath $fileRelative -ExpectedSha256 $evidence.sha256)) 'artifact final positive control rejected.';$artifactCases++
      Assert-RepairContract ($artifactCases -eq 15) 'artifact fixture count changed.'
      Write-Output "Compatibility artifact bytes: $artifactCases labelled host fixtures passed; no image, approval or comparison qualified."
      $fileManifest=$fileLog+'.visual.json'
      $manifestFacts=$fileFacts.Clone();$manifestFacts.RecorderBlob='e'*40
      $manifestFacts.ExpectedSlotIds=@('labelled-host-slot-1','labelled-host-slot-2')
      function Write-LabelledVisualManifestBinding([string]$Kind='positive') {
        $fixtureEvidence=Write-LabelledExecutionFiles
        $manifest=[pscustomobject]@{schemaVersion=1;sourceCommit=$fileFacts.Source;sourceTree=$fileFacts.Tree;
          executionLogPath=$fileRelative;reportId=$fileFacts.ReportId;executionId=$fileFacts.ExecutionId;
          recorderPath='apps/mobile/test/work_workspace_layout_safety_test.dart';recorderGitBlob=('e'*40);
          entries=@([pscustomobject]@{slotId='labelled-host-slot-1'},[pscustomobject]@{slotId='labelled-host-slot-2'})}
        switch($Kind) {
          'wrong-execution' {$manifest.executionId='workspace_capture'}
          'wrong-source' {$manifest.sourceCommit='f'*40}
          'wrong-tree' {$manifest.sourceTree='f'*40}
          'wrong-log' {$manifest.executionLogPath='apps/mobile/build/another.jsonl'}
          'wrong-recorder' {$manifest.recorderGitBlob='f'*40}
          'schema-string' {$manifest.schemaVersion='1'}
          'extra-field' {$manifest|Add-Member -NotePropertyName accepted -NotePropertyValue $true}
          'missing-slot' {$manifest.entries=@($manifest.entries[0])}
          'unknown-slot' {$manifest.entries[0].slotId='unapproved-slot'}
          'duplicate-slot' {$manifest.entries[1].slotId=$manifest.entries[0].slotId}
          'scalar-entries' {$manifest.entries=$manifest.entries[0]}
        }
        $text=ConvertTo-Json -InputObject $manifest -Depth 20
        if($Kind -ceq 'duplicate-key'){$text=$text.Insert($text.IndexOf('{')+1,'"schemaVersion":1,')}
        [IO.File]::WriteAllText($fileManifest,$text,[Text.UTF8Encoding]::new($false))
        $capture=Read-LabelledCapture
        $capture|Add-Member -NotePropertyName visualManifestPath -NotePropertyValue ($fileRelative+'.visual.json')
        $capture|Add-Member -NotePropertyName visualManifestSha256 -NotePropertyValue ((Get-FileHash -LiteralPath $fileManifest -Algorithm SHA256).Hash)
        if($Kind -ceq 'unbound-manifest'){$capture.visualManifestPath=$null;$capture.visualManifestSha256=$null}
        if($Kind -ceq 'wrong-manifest-hash'){$capture.visualManifestSha256='0'*64}
        if($Kind -ceq 'wrong-manifest-path'){$capture.visualManifestPath='apps/mobile/build/another.visual.json'}
        [IO.File]::WriteAllText($fileCapture,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
        $fixtureEvidence.captureSha256=(Get-FileHash -LiteralPath $fileCapture -Algorithm SHA256).Hash
        if($Kind -ceq 'missing-manifest'){Remove-Item -LiteralPath $fileManifest}
        if($Kind -ceq 'changed-manifest-after-binding'){[IO.File]::WriteAllText($fileManifest,($text+' '),[Text.UTF8Encoding]::new($false))}
        if($Kind -ceq 'failed-execution'){
          $lines=[IO.File]::ReadAllLines($fileLog);$lines[$lines.Count-1]='{"type":"done","success":false}'
          [IO.File]::WriteAllLines($fileLog,$lines,[Text.UTF8Encoding]::new($false));Refresh-LabelledExecutionHashes $fixtureEvidence
        }
        return $fixtureEvidence
      }
      $fileMode='positive';$fileHashCounts.Clear();$evidence=Write-LabelledVisualManifestBinding
      $manifestResult=Read-OctoberCompatibilityVisualManifestBinding -Evidence $evidence @manifestFacts
      Assert-RepairContract ($null -ne $manifestResult -and $manifestResult.entries.Count -eq 2) 'hash-bound labelled visual manifest rejected.'
      $manifestCases=1
      foreach($kind in @('missing-manifest','unbound-manifest','wrong-manifest-hash','wrong-manifest-path',
          'wrong-execution','wrong-source','wrong-tree','wrong-log','wrong-recorder','schema-string',
          'extra-field','duplicate-key','missing-slot','unknown-slot','duplicate-slot','scalar-entries',
          'failed-execution','changed-manifest-after-binding','manifest-final-log','manifest-final-stderr',
          'manifest-final-capture','manifest-final-manifest')) {
        $fileMode='positive';$fileHashCounts.Clear();$evidence=Write-LabelledVisualManifestBinding $kind
        if($kind.StartsWith('manifest-final-',[StringComparison]::Ordinal)){$fileMode=$kind;$script:fileBoundaryObserved=$false}
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityVisualManifestBinding -Evidence $evidence @manifestFacts)) "visual manifest binding admitted $kind.";$manifestCases++
        if($kind.StartsWith('manifest-final-',[StringComparison]::Ordinal)){Assert-RepairContract $script:fileBoundaryObserved 'manifest final preservation boundary not reached.'}
      }
      $fileMode='positive';$fileHashCounts.Clear();$evidence=Write-LabelledVisualManifestBinding
      Assert-RepairContract ($null -ne (Read-OctoberCompatibilityVisualManifestBinding -Evidence $evidence @manifestFacts)) 'final visual manifest binding control rejected.';$manifestCases++
      Assert-RepairContract ($manifestCases -eq 24) 'visual manifest fixture inventory changed.'
      Write-Output "Compatibility visual manifest binding: $manifestCases labelled temporary host fixtures passed; no real render, approval or comparison qualified."
      $fileFixturePassed=$true
      Write-Output "Compatibility execution files: $fileCases labelled temporary host fixtures passed; reparse/change boundaries simulated, no real source or visuals qualified."
    } finally {
      if($fileFixturePassed) {
        # Exact files and empty directories created by this invocation only.
        foreach($path in @($fileLog,$fileCapture,$fileStderr,$fileManifest)){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}}
        foreach($path in @($fileFixtureBuild,(Join-Path $fileFixtureRoot 'apps/mobile'),(Join-Path $fileFixtureRoot 'apps'),$fileFixtureRoot)){
          Assert-RepairContract ([IO.Path]::GetFullPath($path).StartsWith([IO.Path]::GetFullPath($fileFixtureRoot),[StringComparison]::OrdinalIgnoreCase)) 'fixture cleanup escaped its created root.'
          Remove-Item -LiteralPath $path
        }
      } else {Write-Output ('Failed labelled host fixtures retained at '+$fileFixtureRoot)}
    }
  }
  $capturePrematureRejected=$false
  try { $null=& $PSCommandPath -RepositoryRoot $root -CaptureCompatibilityReport publication_contracts }
  catch {
    Assert-RepairContract ($_.Exception.Message -ceq 'Integration repair fixture rejected: capture requires committed T test repair after immutable N, not earlier source or documentary Q.') 'premature capture failed for an unrelated reason.'
    $capturePrematureRejected=$true
  }
  Assert-RepairContract $capturePrematureRejected 'premature host capture admitted before T.'
  Write-Output 'Compatibility capture producer: unqualified source rejected before Flutter or evidence-file creation.'
  $selectionWithoutCaptureRejected=$false
  try { $null=& $PSCommandPath -RepositoryRoot $root -CaptureExecutionId localstock_review }
  catch {
    Assert-RepairContract ($_.Exception.Message.IndexOf('execution selection requires capture mode.',[StringComparison]::Ordinal) -ge 0) 'execution-only call failed for an unrelated reason.'
    $selectionWithoutCaptureRejected=$true
  }
  Assert-RepairContract $selectionWithoutCaptureRejected 'supplemental selection admitted outside capture mode.'
  $unknownSelectionRejected=$false
  try { $null=& $PSCommandPath -RepositoryRoot $root -CaptureExecutionId caller_injected_execution }
  catch {
    Assert-RepairContract ($_.FullyQualifiedErrorId.IndexOf('ParameterArgumentValidationError',[StringComparison]::Ordinal) -ge 0) 'unknown execution failed for an unrelated reason.'
    $unknownSelectionRejected=$true
  }
  Assert-RepairContract $unknownSelectionRejected 'unknown capture execution admitted.'
  Write-Output 'Compatibility capture execution selection: 2 actual producer rejection checks passed; no capture or Flutter invocation.'
  # Complete aggregate fixture in an isolated ignored build directory. Fake Git
  # reads are scoped to this scriptblock; no real source/ledger/device is changed.
  & {
    $fixtureRoot=Join-Path $root ('apps/mobile/build/labelled-proof-fixture-'+[Guid]::NewGuid().ToString('N'))
    $root=[IO.Path]::GetFullPath($fixtureRoot).Replace('\','/').TrimEnd('/')
    $null=[IO.Directory]::CreateDirectory((Join-Path $root 'apps/mobile/build'))
    $null=[IO.Directory]::CreateDirectory((Join-Path $root 'docs/quality'))
    $fakeSource='b'*40; $fakeTree='c'*40; $fakeRegistry='D'*64; $fakeProducer='a'*40; $fakeQ='e'*40
    $fakeH='9'*40;$fixtureCoverageDocument=$coverageDoc
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
      if($key -ceq "show|${fakeH}:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md"){
        return $fixtureCoverageDocument
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
      if($id -ceq 'store_layout_and_recovery') {
        # Labelled fake-Git proof only: these are protocol fixtures, not actual
        # executions of historical tests or real-user commerce records.
        foreach($row in $coverage.cases) {
          $name=$row.key.Substring('work_workspace_layout_safety_test.dart:'.Length)
          $events.Add(@{type='testStart';test=@{id=$testId;suiteID=0;name=$name}})
          $events.Add(@{type='testDone';testID=$testId;result='success';skipped=$false});$testId++
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
      coverageCommit=$fakeH;coverageSpecificationSha256='7BBB55F9CC4A3B12483241A78BC5B754F12CD6F22F3AAF48EB72423616B98569'
      registrySha256=$fakeRegistry; reports=$reports.ToArray()}
    Write-FixtureProof $proof
    $working=@{Stage=6; Commits=@(('f'*40),('d'*40),('a'*40),('9'*40),('8'*40),$fakeSource); Head=$fakeSource}
    $committed=@{Stage=7; Commits=@(('f'*40),('d'*40),('a'*40),('9'*40),('8'*40),$fakeSource,$fakeQ); Head=$fakeQ}
    Assert-RepairContract (Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree) 'complete labelled legacy working-Q aggregate rejected.'
    Assert-RepairContract (Test-OctoberCompatibilityLegacyQualification $committed) 'complete labelled legacy committed-Q aggregate rejected.'
    Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $working -FromWorkingTree)) 'operative qualifier admitted legacy working proof.'
    Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $committed)) 'operative qualifier admitted legacy committed proof.'
    $prospective=@{Stage=9;Commits=@(('f'*40),('d'*40),('a'*40),('9'*40),('8'*40),('7'*40),('6'*40),$fakeSource,$fakeQ);Head=$fakeQ}
    Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $prospective -FromWorkingTree)) 'operative qualifier fell back to schema1 on prospective history.'
    $aggregateCases=2
    # Retain the two legacy positives above, then test the actual new producer
    # shape with explicit default identity at every link and fresh file hashes.
    $identityJsonParameters=@{}
    if((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
      $identityJsonParameters.DateKind='String'
    }
    foreach($report in $proof.reports) {
      $log=Join-Path $root ([string]$report.path)
      $sidecar=Join-Path $root ([string]$report.capturePath)
      $events=@([IO.File]::ReadAllLines($log)|ForEach-Object {$_|ConvertFrom-Json})
      $events[0]|Add-Member -NotePropertyName executionId -NotePropertyValue 'default'
      $writer=[IO.StreamWriter]::new($log,$false,[Text.UTF8Encoding]::new($false))
      try {foreach($event in $events){$writer.WriteLine((ConvertTo-Json -InputObject $event -Depth 12 -Compress))}}finally{$writer.Dispose()}
      $capture=[IO.File]::ReadAllText($sidecar)|ConvertFrom-Json @identityJsonParameters
      $capture|Add-Member -NotePropertyName executionId -NotePropertyValue 'default'
      $capture.stdoutSha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash
      [IO.File]::WriteAllText($sidecar,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
      $report.executionId='default';$report.sha256=$capture.stdoutSha256
      $report.captureSha256=(Get-FileHash -LiteralPath $sidecar -Algorithm SHA256).Hash
    }
    Write-FixtureProof $proof
    Assert-RepairContract (Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree) 'explicit-default legacy working-Q aggregate rejected.';$aggregateCases++
    Assert-RepairContract (Test-OctoberCompatibilityLegacyQualification $committed) 'explicit-default legacy committed-Q aggregate rejected.';$aggregateCases++
    foreach($kind in @('missing-report','duplicate-report','stale-source','stale-registry','swapped-sidecars','supplemental-report-identity','coerced-report-identity',
        'missing-coverage-commit','wrong-coverage-commit','wrong-coverage-hash')) {
      $changed=(ConvertTo-Json -InputObject $proof -Depth 30 -Compress)|ConvertFrom-Json
      switch($kind) {
        'missing-report' {$changed.reports=@($changed.reports[0..2])}
        'duplicate-report' {$changed.reports=@($changed.reports[0..2])+@($changed.reports[0])}
        'stale-source' {$changed.sourceCommit='0'*40}
        'stale-registry' {$changed.registrySha256='0'*64}
        'supplemental-report-identity' {$changed.reports[0].executionId='workspace_capture'}
        'coerced-report-identity' {$changed.reports[0].executionId=$true}
        'missing-coverage-commit' {$changed.PSObject.Properties.Remove('coverageCommit')}
        'wrong-coverage-commit' {$changed.coverageCommit=$fakeSource}
        'wrong-coverage-hash' {$changed.coverageSpecificationSha256='0'*64}
        'swapped-sidecars' {
          $changed.reports[0].capturePath=$changed.reports[1].capturePath
          $changed.reports[0].captureSha256=$changed.reports[1].captureSha256
        }
      }
      Write-FixtureProof $changed
      Assert-RepairContract (-not (Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree)) "aggregate $kind accepted."
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
    foreach($kind in @('wrong-producer','wrong-plan','uncovered-skip','non-utc-timestamp','supplemental-capture-identity','supplemental-header-identity','coerced-header-identity')) {
      try {
        $changed=(ConvertTo-Json -InputObject $proof -Depth 30 -Compress)|ConvertFrom-Json
        $capture=[IO.File]::ReadAllText($firstCapture)|ConvertFrom-Json @captureJsonParameters
        Assert-RepairContract ($capture.startedAtUtc -is [string] -and
          $capture.startedAtUtc -ceq '2026-10-08T01:00:00+00:00') 'capture ISO timestamp was coerced before mutation.'
        switch($kind) {
          'wrong-producer' {$capture.producerGitBlob='0'*40}
          'wrong-plan' {$capture.arguments=@($capture.arguments)+@('--name=incorrect-filter')}
          'non-utc-timestamp' {$capture.startedAtUtc='2026-10-08T06:30:00+05:30'}
          'supplemental-capture-identity' {$capture.executionId='workspace_capture'}
          {$_ -in @('supplemental-header-identity','coerced-header-identity')} {
            $events=@([IO.File]::ReadAllLines($firstLog)|ForEach-Object {$_|ConvertFrom-Json})
            $value=if($kind -ceq 'coerced-header-identity'){$true}else{'workspace_capture'}
            $events[0].executionId=$value
            $writer=[IO.StreamWriter]::new($firstLog,$false,[Text.UTF8Encoding]::new($false))
            try {foreach($event in $events){$writer.WriteLine((ConvertTo-Json -InputObject $event -Depth 12 -Compress))}}finally{$writer.Dispose()}
            $capture.stdoutSha256=(Get-FileHash -LiteralPath $firstLog -Algorithm SHA256).Hash
            $changed.reports[0].sha256=$capture.stdoutSha256
          }
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
        Assert-RepairContract (-not (Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree)) "aggregate $kind accepted."
        $aggregateCases++
      } finally {
        [IO.File]::WriteAllBytes($firstLog,$originalLog)
        [IO.File]::WriteAllBytes($firstCapture,$originalCapture)
      }
    }
    Write-FixtureProof $proof
    $wrongHistory=$working.Clone();$wrongHistory.Commits=@($working.Commits);$wrongHistory.Commits[3]=$fakeSource
    Assert-RepairContract (-not(Test-OctoberCompatibilityLegacyQualification $wrongHistory -FromWorkingTree)) 'wrong H history position admitted.';$aggregateCases++
    foreach($kind in @('altered-contract','duplicate-contract')) {
      try {
        $fixtureCoverageDocument=if($kind -ceq 'altered-contract'){$coverageDoc.Replace('Workspace overnight visual - choose','unapproved different capture')}
          else{$coverageDoc+"`n"+$coverageDoc}
        Assert-RepairContract (-not(Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree)) "immutable H $kind admitted.";$aggregateCases++
      }finally{$fixtureCoverageDocument=$coverageDoc}
    }
    $layoutLog=Join-Path $root ([string]$proof.reports[2].path)
    $layoutCapture=Join-Path $root ([string]$proof.reports[2].capturePath)
    $originalLayoutLog=[IO.File]::ReadAllBytes($layoutLog)
    $originalLayoutCapture=[IO.File]::ReadAllBytes($layoutCapture)
    foreach($kind in @('missing-original-case','skipped-original-case','renamed-original-case')) {
      try {
        $changed=(ConvertTo-Json -InputObject $proof -Depth 30 -Compress)|ConvertFrom-Json
        $events=@([IO.File]::ReadAllLines($layoutLog)|ForEach-Object {$_|ConvertFrom-Json})
        $name=$coverage.cases[-1].key.Substring('work_workspace_layout_safety_test.dart:'.Length)
        $target=@($events|Where-Object {$_.type -ceq 'testStart' -and $_.test.name -ceq $name})
        Assert-RepairContract ($target.Count -eq 1) '84th historical protocol fixture not unique.'
        $targetId=$target[0].test.id
        switch($kind) {
          'missing-original-case' {$events=@($events|Where-Object { -not(($_.type -ceq 'testStart' -and $_.test.id -eq $targetId) -or ($_.type -ceq 'testDone' -and $_.testID -eq $targetId))})}
          'skipped-original-case' {($events|Where-Object {$_.type -ceq 'testDone' -and $_.testID -eq $targetId}).skipped=$true}
          'renamed-original-case' {$target[0].test.name+=' renamed'}
        }
        $writer=[IO.StreamWriter]::new($layoutLog,$false,[Text.UTF8Encoding]::new($false))
        try {foreach($event in $events){$writer.WriteLine((ConvertTo-Json -InputObject $event -Depth 12 -Compress))}}finally{$writer.Dispose()}
        $capture=[IO.File]::ReadAllText($layoutCapture)|ConvertFrom-Json @captureJsonParameters
        $capture.stdoutSha256=(Get-FileHash -LiteralPath $layoutLog -Algorithm SHA256).Hash
        [IO.File]::WriteAllText($layoutCapture,(ConvertTo-Json -InputObject $capture -Depth 20),[Text.UTF8Encoding]::new($false))
        $changed.reports[2].sha256=$capture.stdoutSha256
        $changed.reports[2].captureSha256=(Get-FileHash -LiteralPath $layoutCapture -Algorithm SHA256).Hash
        Write-FixtureProof $changed
        Assert-RepairContract (-not(Test-OctoberCompatibilityLegacyQualification $working -FromWorkingTree)) "contract fulfillment $kind admitted.";$aggregateCases++
      }finally{
        [IO.File]::WriteAllBytes($layoutLog,$originalLayoutLog)
        [IO.File]::WriteAllBytes($layoutCapture,$originalLayoutCapture)
      }
    }
    Write-FixtureProof $proof
    Assert-RepairContract ($aggregateCases -eq 27) 'aggregate fixture inventory changed.'
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
  # Isolated Git-boundary fixtures invoke the real history predicate. Only the
  # prospective M responses are simulated; existing sealed history is read.
  $historyOriginalGitLines=(Get-Command Get-OctoberCompatibilityGitLines).ScriptBlock
  $historyNativeGit=(Get-Command git.exe).Source
  $historyK='2beaf3775ed20f14fa42101346b35ddb7f8e9283'
  $historyKChain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$($binding.baselineHead)..$historyK"))
  $historyAllowedReads=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  [void]$historyAllowedReads.Add('rev-parse|--path-format=absolute|--git-path|MERGE_HEAD')
  foreach($sealed in @('55b87b8a590a991fdec198d9386f964292bea047','f27e25fdfa64453d119d81dcef51956a56120c19',
      '6fc0cb5b5ef0f58897c4576651e3208e69076b4c',$binding.baselineHead)) {
    [void]$historyAllowedReads.Add("show|-s|--format=%P|$sealed")
  }
  [void]$historyAllowedReads.Add('show|-s|--format=%T|6fc0cb5b5ef0f58897c4576651e3208e69076b4c')
  foreach($sealed in @('f27e25fdfa64453d119d81dcef51956a56120c19',$binding.baselineHead)) {
    [void]$historyAllowedReads.Add("diff-tree|--no-commit-id|--name-only|-r|$sealed")
  }
  [void]$historyAllowedReads.Add('rev-parse|55b87b8a590a991fdec198d9386f964292bea047:apps|8002e8cd740aaf613b75dc749212fb12ae4fddb7:apps')
  [void]$historyAllowedReads.Add("rev-parse|$($binding.baselineHead):apps|6fc0cb5b5ef0f58897c4576651e3208e69076b4c:apps")
  $historyPrevious=$binding.baselineHead
  for($historyIndex=0;$historyIndex -lt $historyKChain.Count;$historyIndex++) {
    $sealed=$historyKChain[$historyIndex]
    foreach($format in @('%P','%s')){[void]$historyAllowedReads.Add("show|-s|--format=$format|$sealed")}
    [void]$historyAllowedReads.Add("diff-tree|--no-commit-id|--name-only|-r|$sealed")
    if($historyIndex -in @(0,2,3,4,5)){[void]$historyAllowedReads.Add("rev-parse|${sealed}:apps|${historyPrevious}:apps")}
    $historyPrevious=$sealed
  }
  $historyWorkingDocument=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $historyMCases=0
  foreach($historyMode in @('positive','wrong-M','wrong-K','wrong-parent','wrong-subject','missing-owner','extra-owner',
      'changed-apps','missing-contract','altered-contract','duplicate-contract')) {
    & {
      $fixtureM=if($historyMode -ceq 'wrong-M'){('a'*40)}else{'122d9f12bde7baea38eeb30dada3b1321e3d5289'}
      $historyContext=@{Mode=$historyMode;M=$fixtureM;BadK=('b'*40);ContractRead=$false;Unexpected=$false;AncestryCalls=0}
      function git {
        $historyArgs=@($args)
        # The prospective ancestry is simulated by the exact actual K ancestry.
        if(($historyArgs -join '|') -ceq "-C|$root|merge-base|--is-ancestor|$($binding.baselineHead)|$($historyContext.M)") {
          $historyContext.AncestryCalls++;$historyArgs[-1]=$historyK
        }elseif($historyArgs.Count -ge 6 -and
            (@($historyArgs[0..4]) -join '|') -ceq "--no-pager|--no-optional-locks|--no-replace-objects|-C|$root" -and
            $historyAllowedReads.Contains((@($historyArgs[5..($historyArgs.Count-1)]) -join '|'))) {
          # Exact delegated sealed-history read only.
        }else{
          $historyContext.Unexpected=$true;throw 'Unexpected native M fixture query.'
        }
        & $historyNativeGit @historyArgs
        $global:LASTEXITCODE=$LASTEXITCODE
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|';$m=$historyContext.M
        if($query -ceq "rev-list|--reverse|$($binding.baselineHead)..$m" -or
            $query -ceq "rev-list|--first-parent|--reverse|$($binding.baselineHead)..$m") {
          $chain=@($historyKChain)
          if($historyContext.Mode -ceq 'wrong-K'){$chain[5]=$historyContext.BadK}
          return $chain+@($m)
        }
        if($query -ceq "show|-s|--format=%P|$m") {
          if($historyContext.Mode -ceq 'wrong-parent'){return '84b889430abb84e67ea1cf3838c63841429f7712'}
          if($historyContext.Mode -ceq 'wrong-K'){return $historyContext.BadK};return $historyK
        }
        if($query -ceq "show|-s|--format=%s|$m") {
          if($historyContext.Mode -ceq 'wrong-subject'){return 'altered'}
          return 'coordination(store-buy-compatibility-20261008): admit exclusive embedded Buy handoff'
        }
        if($query -ceq "diff-tree|--no-commit-id|--name-only|-r|$m") {
          $owners=@(Get-OctoberCompatibilityAmendmentOwners)
          if($historyContext.Mode -ceq 'missing-owner'){return $owners[0..2]}
          if($historyContext.Mode -ceq 'extra-owner'){return $owners+@('apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart')}
          return $owners
        }
        $comparison=if($historyContext.Mode -ceq 'wrong-K'){$historyContext.BadK}else{$historyK}
        if($query -ceq "rev-parse|${m}:apps|${comparison}:apps") {
          if($historyContext.Mode -ceq 'changed-apps'){return @(('d'*40),('e'*40))}
          return @('3dcabaa2688da63b25f8ec5233b6a3e07943e0f9','3dcabaa2688da63b25f8ec5233b6a3e07943e0f9')
        }
        if($query -ceq "show|${m}:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md") {
          $historyContext.ContractRead=$true
          switch($historyContext.Mode) {
            'missing-contract' {return 'No committed handoff contract; valid working copy must not substitute.'}
            'altered-contract' {return $historyWorkingDocument.Replace('specified_exclusive_handoff_not_active_until_committed_M','altered')}
            'duplicate-contract' {return $historyWorkingDocument+"`n"+$historyWorkingDocument}
            default {return $historyWorkingDocument}
          }
        }
        if(($Arguments -join '|').Contains($m)){$historyContext.Unexpected=$true;throw 'Unexpected prospective M fixture query.'}
        $forward=@($Arguments|ForEach-Object {if($_ -ceq $historyContext.BadK){$historyK}
          elseif($_ -ceq "$($historyContext.BadK):apps"){"${historyK}:apps"}else{$_}})
        if(-not $historyAllowedReads.Contains(($forward -join '|'))){
          $historyContext.Unexpected=$true;throw 'Unexpected delegated sealed-history fixture query.'
        }
        return & $historyOriginalGitLines $forward
      }
      $accepted=$false;$rejection=''
      try {$result=Get-OctoberCompatibilityHistoryStage $historyContext.M;$accepted=$result.Stage -eq 7}
      catch {$rejection=$_.Exception.Message}
      Assert-RepairContract ($accepted -eq ($historyMode -ceq 'positive')) ('M history result incorrect: '+$historyMode+'; rejection: '+$rejection)
      Assert-RepairContract (-not $historyContext.Unexpected -and $historyContext.AncestryCalls -eq 1) 'M history fixture missed ancestry or made an unexpected read.'
      $expectedError=switch($historyMode) {
        'wrong-M' {'Sealed compatibility M changed.'}
        'wrong-K' {'Sealed compatibility K changed.'}
        'wrong-parent' {'Compatibility successor parent/subject changed.'}
        'wrong-subject' {'Compatibility successor parent/subject changed.'}
        'missing-owner' {'Compatibility successor changed unexpected owners.'}
        'extra-owner' {'Compatibility successor changed unexpected owners.'}
        'changed-apps' {'Compatibility metadata commit changed apps.'}
        default {'Committed compatibility M handoff contract missing or changed.'}
      }
      if(-not $accepted){Assert-RepairContract ($rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedError)) ('M history rejected for an unrelated reason: '+$historyMode)}
      if($historyMode -cin @('positive','missing-contract','altered-contract','duplicate-contract')) {
        Assert-RepairContract $historyContext.ContractRead 'M history did not read its committed contract.'
      }
      if($historyMode -ceq 'wrong-M') {
        Assert-RepairContract (-not $historyContext.ContractRead) 'Changed M identity reached contract reading.'
      }
    }
    $historyMCases++
  }
  Assert-RepairContract ($historyMCases -eq 11) 'Immutable M history case inventory changed.'
  Write-Output "Compatibility immutable M history: $historyMCases labelled sealed-history Git fixtures passed; no commit or claim transfer."
  Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $history)) 'unqualified E evidence accepted.'
  $missingProof=@{ Stage=6; Commits=@($binding.baselineHead,$binding.baselineHead,$binding.baselineHead,$binding.baselineHead,$binding.baselineHead,$binding.baselineHead); Head=$binding.baselineHead }
  Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $missingProof -FromWorkingTree)) 'premature stage6 evidence accepted.'
  & {
    $proofReadContext=@{Read=$false;Unexpected=$false}
    $missingProofNText=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
    function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
      if(($Arguments -join '|') -ceq ('show|'+('9'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')){return $missingProofNText}
      if(($Arguments -join '|') -ceq "show|$($binding.baselineHead):docs/quality/STORE-BUY-COMPATIBILITY-20261008.md") {
        $proofReadContext.Read=$true;return 'Deliberately missing qualification block.'
      }
      $proofReadContext.Unexpected=$true;throw 'Unexpected missing-Q fixture query.'
    }
    $modernMissingProof=@{Stage=11;Head=$binding.baselineHead;Commits=@(('1'*40),('2'*40),('3'*40),('4'*40),('5'*40),('6'*40),('7'*40),
      '0da3630d1c857390c173ec83ba5c0210cb1e5ec2',('9'*40),('a'*40),$binding.baselineHead)}
    Assert-RepairContract (-not(Test-OctoberCompatibilityQualification $modernMissingProof)) 'valid-stage missing Q proof accepted.'
    Assert-RepairContract ($proofReadContext.Read -and -not $proofReadContext.Unexpected) 'missing Q rejection did not reach the intended proof read.'
  }
  Write-Output 'Compatibility qualification: E, premature stage and actual missing-proof read rejected; no host pass manufactured.'
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
