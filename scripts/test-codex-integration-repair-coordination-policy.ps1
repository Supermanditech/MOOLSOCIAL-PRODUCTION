[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireQualifiedGraph,
  [switch]$RequireOctoberSourceAdmission,
  [switch]$RequireOctoberBootstrapProbes,
  [switch]$RequireCompatibilityStageProbes,
  [switch]$RequireCompatibilityLiveAdmissionProbes,
  [switch]$RequireCurrentSelectionAggregationProbes,
  [switch]$RequireCurrentPrimaryReviewBindingProbes,
  [switch]$RequireCurrentPrimaryAssertionReviewProbes,
  [switch]$RequireCurrentPrimaryVisualReviewProbes,
  [switch]$RequireSource17ForwardAmendmentProbes,
  [switch]$RequireSource19ForwardAmendmentProbes,
  [switch]$RequireSource21ForwardAmendmentProbes,
  [switch]$RequireSource19FullDependencyProbes,
  [ValidateSet('publication_contracts','impacted_store_buy','store_layout_and_recovery','enabled_review_fixture')]
  [string]$CaptureCompatibilityReport,
  [ValidateSet('default','localstock_review','workspace_capture','historical_store_review','historical_store_capture','store_live_capture','founder_capture')]
  [string]$CaptureExecutionId = 'default',
  [ValidateSet('behavior_only','selected_visual_risks')]
  [string]$CaptureMode = 'behavior_only'
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

function New-OctoberCompatibilityCurrentCaptureEnvelope {
  param([hashtable]$Plan,[hashtable]$SourceIdentityAfter,[string]$StartedAtUtc,[string]$FinishedAtUtc,
    [string]$LogSha256,[string]$StderrRelativePath,[string]$StderrSha256,[int]$NativeExitCode,
    [bool]$CleanBefore,[bool]$CleanAfter,[bool]$GuardCompleted)
  # Serialization only. The caller must derive the plan from sealed source,
  # retain actual process output, restore support and independently validate
  # retained bytes/postflight. Failed runs retain failed receipts, never passes.
  if($null -eq $Plan -or $null -eq $Plan.SourceIdentity){throw 'Current envelope requires a source-bound execution plan.'}
  $identity=$Plan.SourceIdentity.Clone()
  $marker=[ordered]@{type='moolsocialSource';schemaVersion=2;reportId=$Plan.Id;
    executionId=$Plan.ExecutionId;mode=$Plan.Mode;runId=$Plan.RunId;sourceIdentity=$identity.Clone();
    registrySha256='8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3';
    runtimeDefines=@($Plan.RuntimeDefines)}
  $receipt=[ordered]@{schemaVersion=2;producer='test-codex-integration-repair-coordination-policy.ps1';
    producerGitBlob=$identity.producerBlob;reportId=$Plan.Id;executionId=$Plan.ExecutionId;
    mode=$Plan.Mode;runId=$Plan.RunId;sourceIdentity=$identity.Clone();
    sourceIdentityAfter=$(if($null -eq $SourceIdentityAfter){$null}else{$SourceIdentityAfter.Clone()});
    registrySha256=$marker.registrySha256;executable='C:/Users/jisal/develop/flutter/bin/flutter.bat';
    workingDirectory=(Get-OctoberCompatibilityBinding).worktreePath+'/apps/mobile';
    cleanBefore=$CleanBefore;cleanAfter=$CleanAfter;guardCompleted=$GuardCompleted;exitCode=$NativeExitCode;
    arguments=@($Plan.Arguments);runtimeDefines=@($Plan.RuntimeDefines);
    startedAtUtc=$StartedAtUtc;finishedAtUtc=$FinishedAtUtc;stdoutSha256=$LogSha256;
    stderrPath=$StderrRelativePath;stderrSha256=$StderrSha256}
  return [pscustomobject]@{Marker=$marker;Receipt=$receipt;QualificationPassed=$false;ApkAuthority=$false}
}

function Convert-OctoberCompatibilityFlutterBatchArguments {
  param([object[]]$Arguments)
  # Windows .bat transport strips unescaped JSON quotes. This changes transport
  # spelling only; the Dart flag value and receipt's logical argv stay unchanged.
  if($null -eq $Arguments -or $Arguments.Count -eq 0){throw 'Empty Flutter transport arguments.'}
  $prefix='--dart-define=MOOL_CURRENT_QUALIFICATION_SELECTED_VISUAL_SLOTS='
  $selected=$false;$encoded=[Collections.Generic.List[string]]::new()
  foreach($argument in $Arguments) {
    if($argument -isnot [string] -or [string]::IsNullOrEmpty($argument) -or $argument -match '[\x00\r\n]'){throw 'Malformed Flutter transport argument.'}
    if($argument.StartsWith($prefix,[StringComparison]::Ordinal)) {
      if($selected){throw 'Duplicate selected-slot transport argument.'}
      $selected=$true
      $payload=$argument.Substring($prefix.Length)
      if($payload -cnotmatch '\A\["[A-Za-z0-9._-]+"(?:,"[A-Za-z0-9._-]+")*\]\z'){throw 'Malformed selected-slot transport JSON.'}
      $encoded.Add($argument.Replace('"','\"'))
    }else{$encoded.Add($argument)}
  }
  return $encoded.ToArray()
}

function Invoke-OctoberCompatibilityNativeBatchStreams {
  param([string]$BatchPath,[string]$WorkingDirectory,[object[]]$Arguments,
    [IO.Stream]$Stdout,[IO.Stream]$Stderr,[hashtable]$State)
  # Transport only. The production caller supplies fixed Flutter/canonical argv;
  # this helper never determines source, capture or qualification authority.
  if($null -eq $Arguments -or -not $Arguments.Count){throw 'Unsupported native batch arguments.'}
  $selectedPrefix='--dart-define=MOOL_CURRENT_QUALIFICATION_SELECTED_VISUAL_SLOTS='
  $selectedSeen=$false
  foreach($argument in $Arguments) {
    if($argument -isnot [string] -or -not $argument.Length -or $argument -match '[\x00-\x1f%]' -or $argument.EndsWith('\',[StringComparison]::Ordinal)){
      throw 'Unsupported native batch arguments.'
    }
    if($argument.Contains('!') -and -not ($argument.StartsWith('--name=^(?:',[StringComparison]::Ordinal) -and
      $argument.EndsWith(')$(?![\s\S])',[StringComparison]::Ordinal) -and $argument.IndexOf('!') -eq $argument.LastIndexOf('!'))){
      throw 'Unsupported native batch arguments.'
    }
    if($argument.StartsWith($selectedPrefix,[StringComparison]::Ordinal)) {
      if($selectedSeen){throw 'Unsupported native batch arguments.'}
      $selectedSeen=$true
      $payload=$argument.Substring($selectedPrefix.Length)
      # Only the converter's exact compact JSON spelling may contain quotes.
      # Scope/risk authority belongs to the independently reconstructed plan.
      $logicalPayload=$payload.Replace('\"','"')
      if($logicalPayload -cnotmatch '\A\["[A-Za-z0-9._-]+"(?:,"[A-Za-z0-9._-]+")*\]\z' -or
        $logicalPayload.Replace('"','\"') -cne $payload){throw 'Unsupported native batch arguments.'}
      $slotValues=ConvertFrom-Json -InputObject $logicalPayload
      [string[]]$orderedSlots=@($slotValues);[Array]::Sort($orderedSlots,[StringComparer]::Ordinal)
      $uniqueSlots=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
      foreach($slot in $slotValues){if(-not $uniqueSlots.Add($slot)){throw 'Unsupported native batch arguments.'}}
      if((ConvertTo-Json -InputObject @($orderedSlots) -Compress) -cne $logicalPayload){throw 'Unsupported native batch arguments.'}
    }elseif($argument.Contains('"')){throw 'Unsupported native batch arguments.'}
  }
  foreach($path in @($BatchPath,$WorkingDirectory)) {
    if($path -cnotmatch '\A[A-Za-z]:[\\/]' -or $path -match '[\x00-\x1f"%!]'){throw 'Unsupported native batch path.'}
    $ancestor=[IO.Path]::GetFullPath($path)
    while($ancestor) {
      if(((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Native batch path traverses a reparse point.'}
      $parent=Split-Path -Parent $ancestor;if($parent -ceq $ancestor){break};$ancestor=$parent
    }
  }
  if(-not(Test-Path -LiteralPath $BatchPath -PathType Leaf) -or [IO.Path]::GetExtension($BatchPath) -ine '.bat' -or
    -not(Test-Path -LiteralPath $WorkingDirectory -PathType Container)){throw 'Unsupported native batch path.'}
  if($null -eq $Stdout -or $null -eq $Stderr -or -not $Stdout.CanWrite -or -not $Stderr.CanWrite -or
    [object]::ReferenceEquals($Stdout,$Stderr) -or $null -eq $State -or $State.Count){throw 'Native batch requires distinct writable streams and fresh state.'}
  $State.started=$false;$State.exitObserved=$false;$State.exitCode=-1;$State.copiesCompleted=$false
  $process=[Diagnostics.Process]::new();$copies=[Collections.Generic.List[Threading.Tasks.Task]]::new()
  $failures=[Collections.Generic.List[string]]::new()
  $cancel=[Threading.CancellationTokenSource]::new();$settlement=$null
  try {
    $process.StartInfo.FileName=Join-Path ([Environment]::SystemDirectory) 'cmd.exe'
    $quoted=@($Arguments|ForEach-Object {'"'+$_+'"'}) -join ' '
    $process.StartInfo.Arguments='/d /v:off /s /c ""'+[IO.Path]::GetFullPath($BatchPath)+'" '+$quoted+'"'
    $process.StartInfo.WorkingDirectory=[IO.Path]::GetFullPath($WorkingDirectory)
    $process.StartInfo.UseShellExecute=$false;$process.StartInfo.CreateNoWindow=$true
    $process.StartInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $process.StartInfo.RedirectStandardOutput=$true;$process.StartInfo.RedirectStandardError=$true
    if(-not $process.Start()){throw 'Native batch process did not start.'}
    $State.started=$true
    $copies.Add($process.StandardOutput.BaseStream.CopyToAsync($Stdout,81920,$cancel.Token))
    $copies.Add($process.StandardError.BaseStream.CopyToAsync($Stderr,81920,$cancel.Token))
    while($true) {
      $exited=$process.WaitForExit(200)
      if($exited -and -not $State.exitObserved) {
        $State.exitCode=[int]$process.ExitCode;$State.exitObserved=$true;$settlement=[Diagnostics.Stopwatch]::StartNew()
      }
      if($copies[0].IsFaulted -or $copies[1].IsFaulted){throw 'Native stream copy failed while child was active.'}
      if($exited -and $copies[0].IsCompleted -and $copies[1].IsCompleted){break}
      if($exited) {
        if($settlement.ElapsedMilliseconds -ge 15000){throw 'Native streams did not settle after process exit.'}
        [Threading.Thread]::Sleep(20)
      }
    }
  } catch {
    $failures.Add($_.Exception.Message)
    $cancel.Cancel()
    if($State.started) {
      try {
        if(-not $process.HasExited) {
          # Settle only this invocation's owned process tree, never broad names.
          $treeKill=$process.GetType().GetMethod('Kill',[Type[]]@([bool]))
          if($null -ne $treeKill){$null=$treeKill.Invoke($process,@($true))}
          else {
            $killer=[Diagnostics.Process]::new()
            try {
              $killer.StartInfo.FileName=Join-Path ([Environment]::SystemDirectory) 'taskkill.exe'
              $killer.StartInfo.Arguments='/PID '+[int]$process.Id+' /T /F'
              $killer.StartInfo.UseShellExecute=$false;$killer.StartInfo.CreateNoWindow=$true
              $killer.StartInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
              $killer.StartInfo.RedirectStandardOutput=$true;$killer.StartInfo.RedirectStandardError=$true
              if(-not $killer.Start()){throw 'Owned process termination helper did not start.'}
              $killerOut=$killer.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null)
              $killerErr=$killer.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
              if(-not $killer.WaitForExit(10000)) {
                $killer.Kill()
                if(-not $killer.WaitForExit(5000)){throw 'Owned process termination helper did not exit after stop.'}
                throw 'Owned process termination helper timed out.'
              }
              foreach($copy in @($killerOut,$killerErr)) {
                if(-not $copy.Wait(5000)){throw 'Owned process termination output did not settle.'}
                $null=$copy.GetAwaiter().GetResult()
              }
              if($killer.ExitCode -ne 0 -and -not $process.HasExited){throw 'Owned native process tree could not be settled.'}
            } finally {try{$killer.Dispose()}catch{$failures.Add($_.Exception.Message)}}
          }
        }
        if(-not $process.WaitForExit(15000)){throw 'Owned native process did not settle after termination.'}
        $State.exitCode=[int]$process.ExitCode;$State.exitObserved=$true
      } catch {$failures.Add($_.Exception.Message)}
    }
  } finally {
    $copyFailures=0
    if($failures.Count -and $State.started) {
      # Close only process-owned read pipes; output streams remain caller-owned.
      foreach($pipe in @($process.StandardOutput.BaseStream,$process.StandardError.BaseStream)) {
        try{$pipe.Dispose()}catch{$failures.Add($_.Exception.Message)}
      }
    }
    foreach($copy in $copies){
      try {
        if(-not $copy.Wait(15000)){throw 'Native copy did not settle within failure cleanup boundary.'}
        $null=$copy.GetAwaiter().GetResult()
      }catch{$copyFailures++;$failures.Add($_.Exception.Message)}
    }
    $State.copiesCompleted=($copies.Count -eq 2 -and $copyFailures -eq 0)
    try{$process.Dispose()}catch{$failures.Add($_.Exception.Message)}
    try{$cancel.Dispose()}catch{$failures.Add($_.Exception.Message)}
  }
  if($failures.Count){throw ('Native batch transport failed: '+($failures -join '; '))}
}

function Invoke-OctoberCompatibilityCurrentBehaviorCapture {
  param([hashtable]$Plan,[object]$InitialSource,[string]$InventoryPath,[string]$InventorySha256)
  # Execution evidence only: no Q4, visual approval or APK qualification.
  if($null -eq $Plan -or $Plan.Mode -cnotin @('behavior_only','selected_visual_risks') -or $null -eq $InitialSource){throw 'Current launcher requires sealed source.'}
  $selection=$null;$selectionSha=$null;$selectionPath=$null
  if($Plan.Mode -ceq 'selected_visual_risks') {
    $selection=New-OctoberCompatibilityCurrentSelectionContext -InventoryPath $InventoryPath -InventorySha256 $InventorySha256 `
      -ReportId $Plan.Id -ExecutionId $Plan.ExecutionId -RunId $Plan.RunId
    if($null -eq $selection){throw 'Current selected inventory admission failed.'}
  }elseif(-not [string]::IsNullOrEmpty($InventoryPath) -or -not [string]::IsNullOrEmpty($InventorySha256)){
    throw 'Behavior-only capture cannot bind a selection inventory.'
  }
  $before=Read-OctoberCompatibilityCurrentCaptureSource
  if($null -eq $before -or $before.SourceStateIdentity -cne $InitialSource.SourceStateIdentity){throw 'Current source changed before launch.'}
  foreach($role in $before.SourceIdentity.Keys) {
    if($Plan.SourceIdentity[$role] -cne $before.SourceIdentity[$role]){throw 'Current execution plan/source mismatch.'}
  }
  if($null -ne $selection) {
    if($selection.Context.sourceStateIdentity -cne $before.SourceStateIdentity){throw 'Selected source snapshot changed before launch.'}
    foreach($role in $before.SourceIdentity.Keys) {
      if($selection.InventoryProof.SourceIdentity[$role] -cne $before.SourceIdentity[$role]){throw 'Selected source roles changed before launch.'}
    }
    $canonical=$selection.Plan
  }else{
    $canonical=Get-OctoberCompatibilityCurrentExecutionPlan -ReportId $Plan.Id -ExecutionId $Plan.ExecutionId `
      -Mode $Plan.Mode -RunId $Plan.RunId -SourceIdentity $before.SourceIdentity
  }
  if($null -eq $canonical -or (@($Plan.Keys|Sort-Object) -join '|') -cne (@($canonical.Keys|Sort-Object) -join '|')){throw 'Current execution plan is not canonical.'}
  foreach($field in $canonical.Keys) {
    if($field -ceq 'SourceIdentity') {
      if((@($Plan.SourceIdentity.Keys|Sort-Object) -join '|') -cne (@($canonical.SourceIdentity.Keys|Sort-Object) -join '|')){throw 'Current execution source roles changed.'}
    }elseif((ConvertTo-Json -InputObject $Plan[$field] -Depth 10 -Compress) -cne (ConvertTo-Json -InputObject $canonical[$field] -Depth 10 -Compress)){
      throw 'Current execution plan was altered before launch.'
    }
  }
  $Plan=$canonical
  $transport=@(Convert-OctoberCompatibilityFlutterBatchArguments -Arguments $Plan.Arguments)
  $flutter='C:/Users/jisal/develop/flutter/bin/flutter.bat'
  if(-not(Test-Path -LiteralPath $flutter -PathType Leaf)){throw 'Current Flutter executable unavailable.'}
  foreach($suite in $Plan.Suites) {
    if(-not(Test-Path -LiteralPath (Join-Path $root ('apps/mobile/test/'+$suite)) -PathType Leaf)){throw 'Current execution suite unavailable.'}
  }
  $relative='apps/mobile/build/compat-current-'+$Plan.Id+'-'+$Plan.ExecutionId+'-'+$Plan.RunId+'.jsonl'
  $log=Join-Path $root $relative;$paths=@($log,($log+'.stderr.txt'),($log+'.capture.json'))
  if($null -ne $selection){$selectionPath=$relative+'.selection.json';$paths+=@($log+'.selection.json')}
  $streams=[Collections.Generic.List[IO.FileStream]]::new();$writers=[Collections.Generic.List[IO.StreamWriter]]::new()
  $fatal=$null;$failure=$null;$cleanAfter=$false;$guardCompleted=$false
  $cleanupFailures=[Collections.Generic.List[string]]::new()
  try {
    foreach($path in $paths) {
      $ancestor=Split-Path -Parent ([IO.Path]::GetFullPath($path))
      while($ancestor) {
        if(((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Current output traverses a reparse point.'}
        $parent=Split-Path -Parent $ancestor;if($parent -ceq $ancestor){break};$ancestor=$parent
      }
      # Reserve each output exclusively. Collisions retain prior bytes.
      $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
      $streams.Add($stream);$writers.Add([IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false),1024,$true))
    }
    $logWriter=$writers[0];$errorWriter=$writers[1];$started=[DateTimeOffset]::UtcNow.ToString('o')
    if($null -ne $selection) {
      $writers[3].Write((ConvertTo-Json -InputObject $selection.Context -Depth 20 -Compress));$writers[3].Flush()
      $writers[3].Dispose();$writers[3]=$null;$streams[3].Dispose();$streams[3]=$null
      $selectionSha=Get-OctoberCoverageBoundHash $paths[3]
    }
    $envelope=New-OctoberCompatibilityCurrentCaptureEnvelope -Plan $Plan
    $logWriter.WriteLine((ConvertTo-Json -InputObject $envelope.Marker -Depth 10 -Compress));$logWriter.Flush()
    if($null -ne $selection) {
      $frame=@{type='print';message='moolsocialSelectionContext';selectionContext=@{path=$selectionPath;sha256=$selectionSha}}
      $logWriter.WriteLine((ConvertTo-Json -InputObject $frame -Depth 10 -Compress));$logWriter.Flush()
    }
    $script:compatNativeExit=-1;$guardCompleted=$false;$failure=$null
    try {
      $guardExit=Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot $root -Invocation {
        $launchSource=Read-OctoberCompatibilityCurrentCaptureSource
        if($null -eq $launchSource -or $launchSource.SourceStateIdentity -cne $before.SourceStateIdentity){throw 'Current source changed immediately before native launch.'}
        foreach($role in $before.SourceIdentity.Keys){if($launchSource.SourceIdentity[$role] -cne $before.SourceIdentity[$role]){throw 'Current source roles changed immediately before native launch.'}}
        if($null -ne $selection -and ((Get-OctoberCoverageBoundHash $selection.InventoryProof.CanonicalPath) -cne $selection.InventoryProof.Sha256 -or
          (Get-OctoberCoverageBoundHash $paths[3]) -cne $selectionSha)){throw 'Current selected evidence changed before native launch.'}
        Push-Location (Join-Path $root 'apps/mobile')
        try {
          $nativeState=@{}
          try {
            Invoke-OctoberCompatibilityNativeBatchStreams -BatchPath $flutter -WorkingDirectory (Join-Path $root 'apps/mobile') `
              -Arguments $transport -Stdout $streams[0] -Stderr $streams[1] -State $nativeState
          } finally {
            $script:compatNativeExit=if($nativeState.ContainsKey('exitObserved') -and $nativeState.exitObserved){[int]$nativeState.exitCode}else{-1}
            $global:LASTEXITCODE=$script:compatNativeExit
          }
          if($script:compatNativeExit -ne 0){throw ('Current Flutter report exited '+$script:compatNativeExit)}
        } finally {Pop-Location}
      }
      $guardCompleted=([int]$guardExit -eq $script:compatNativeExit)
      if(-not $guardCompleted){throw 'Current guard/native exit mismatch.'}
    } catch {$failure=$_}
    # Independent postflight follows support restoration, including failures.
    $after=Read-OctoberCompatibilityCurrentCaptureSource
    $cleanAfter=($null -ne $after -and $after.SourceStateIdentity -ceq $before.SourceStateIdentity)
    if($cleanAfter){foreach($role in $before.SourceIdentity.Keys){if($after.SourceIdentity[$role] -cne $before.SourceIdentity[$role]){$cleanAfter=$false}}}
    if($null -ne $selection -and ((Get-OctoberCoverageBoundHash $selection.InventoryProof.CanonicalPath) -cne $selection.InventoryProof.Sha256 -or
      (Get-OctoberCoverageBoundHash $paths[3]) -cne $selectionSha)){$cleanAfter=$false}
    $afterIdentity=if($null -ne $after){$after.SourceIdentity}else{$null}
    $logWriter.Flush();$errorWriter.Flush()
    $logWriter.Dispose();$writers[0]=$null;$errorWriter.Dispose();$writers[1]=$null
    $streams[0].Dispose();$streams[0]=$null;$streams[1].Dispose();$streams[1]=$null
    $envelope=New-OctoberCompatibilityCurrentCaptureEnvelope -Plan $Plan -SourceIdentityAfter $afterIdentity `
      -StartedAtUtc $started -FinishedAtUtc ([DateTimeOffset]::UtcNow.ToString('o')) `
      -LogSha256 ((Get-FileHash -LiteralPath $paths[0]).Hash) `
      -StderrRelativePath ($relative+'.stderr.txt') -StderrSha256 ((Get-FileHash -LiteralPath $paths[1]).Hash) `
      -NativeExitCode $script:compatNativeExit -CleanBefore $true -CleanAfter $cleanAfter -GuardCompleted $guardCompleted
    $writers[2].Write((ConvertTo-Json -InputObject $envelope.Receipt -Depth 20));$writers[2].Flush()
  } catch {$fatal=$_} finally {
    foreach($writer in $writers){if($null -ne $writer){try{$writer.Dispose()}catch{$cleanupFailures.Add($_.Exception.Message)}}}
    foreach($stream in $streams){if($null -ne $stream){try{$stream.Dispose()}catch{$cleanupFailures.Add($_.Exception.Message)}}}
  }
  if($null -ne $fatal){
    if($null -ne $failure -or $cleanupFailures.Count) {
      $earlier=if($null -ne $failure){'earlier native/guard failure: '+$failure.Exception.Message+'; '}else{''}
      throw ($earlier+'later failure: '+$fatal.Exception.Message+'; cleanup failures: '+($cleanupFailures -join '; '))
    }
    throw $fatal
  }
  if($cleanupFailures.Count){
    $nativeFailure=if($null -ne $failure){$failure.Exception.Message+'; '}else{''}
    throw ($nativeFailure+'Current cleanup failures: '+($cleanupFailures -join '; '))
  }
  if($null -ne $failure){throw $failure}
  if(-not $cleanAfter -or -not $guardCompleted -or $script:compatNativeExit -ne 0){throw 'Current capture failed postflight; original files retained.'}
  $record=@{executionId=$Plan.ExecutionId;path=$relative;capturePath=$relative+'.capture.json';
    sha256=(Get-FileHash -LiteralPath $paths[0]).Hash;captureSha256=(Get-FileHash -LiteralPath $paths[2]).Hash;runtimeDefines=@($Plan.RuntimeDefines)}
  $typed=ConvertTo-Json -InputObject $record -Depth 10 -Compress | ConvertFrom-Json
  $readArgs=@{Evidence=$typed;ReportId=$Plan.Id;ExecutionId=$Plan.ExecutionId;Mode=$Plan.Mode;RunId=$Plan.RunId;SourceIdentity=$before.SourceIdentity}
  if($null -ne $selection){$readArgs.SelectedSlots=$selection.Context.selectedSlots;$readArgs.SelectedTestKeys=$selection.Context.selectedTestKeys}
  $verified=Read-OctoberCompatibilityCurrentExecutionEvidence @readArgs
  if($null -eq $verified){throw 'Current retained execution rejected; original files retained.'}
  if($null -ne $selection) {
    $retained=$verified.CurrentSelectionBinding
    if($null -eq $retained -or $retained.Sha256 -cne $selectionSha -or
      (ConvertTo-Json -InputObject $retained.Context -Depth 30 -Compress) -cne (ConvertTo-Json -InputObject $selection.Context -Depth 30 -Compress) -or
      (ConvertTo-Json -InputObject $retained.Inventory -Depth 50 -Compress) -cne (ConvertTo-Json -InputObject $selection.InventoryProof.Inventory -Depth 50 -Compress)){
      throw 'Current retained selection does not match original launch snapshot.'
    }
  }
  return $typed
}

function Invoke-OctoberCompatibilityCurrentSelectionAggregationProbes {
  # Labelled host-only controls: actual selectors/aggregation; native/hash mocks.
  function Read-OctoberCompatibilityCurrentSuccessorSpecification {
    param($Commit)
    return [pscustomobject]@{visuals=[pscustomobject]@{
      selectedRiskInventoryFields=@('id','slotIds','representative','currentSurface','target','geometry','state','rationale','equivalenceEvidence')
      representativeFields=@('slotId','reportId','executionId','testKey','profile')
    }}
  }
  function Read-OctoberCompatibilityCurrentQualificationContract {
    param($Commit)
    return [pscustomobject]@{
      visualSlots=@([pscustomobject]@{slot='H01-visual-1';profile='workspace_capture';reference='workspace-choose.png'},
        [pscustomobject]@{slot='H02-visual-1';profile='workspace_capture';reference='workspace-requirements.png'},
        [pscustomobject]@{slot='H02-visual-2';profile='workspace_capture';reference='workspace-requirements-guidance.png'},
        [pscustomobject]@{slot='H35-visual-1';profile='historical_store_capture';reference='historical/setup.png'})
      cases=@([pscustomobject]@{ordinal=1;originalSuccessKeys=@('work_workspace_layout_safety_test.dart:Workspace overnight visual - choose')},
        [pscustomobject]@{ordinal=2;originalSuccessKeys=@('work_workspace_layout_safety_test.dart:Workspace overnight visual - requirements')},
        [pscustomobject]@{ordinal=35;originalSuccessKeys=@('work_workspace_layout_safety_test.dart:local Store 1-40 review evidence founder review capture - setup dashboard')})
    }
  }
  $identity=@{runtimeSourceCommit='3c3f38136db8bb184866635203d04ea4643f1eac';contractCommit=('a'*40);
    captureSourceCommit=('b'*40);captureSourceTree=('c'*40);producerBlob=('d'*40);executionHead=('b'*40)}
  $seed='[{"id":"risk-choose","slotIds":["H01-visual-1"],"representative":{"slotId":"H01-visual-1","reportId":"store_layout_and_recovery","executionId":"workspace_capture","testKey":"work_workspace_layout_safety_test.dart:Workspace overnight visual - choose","profile":"workspace_capture"},"currentSurface":"Workspace choose","target":"Scaffold","geometry":{"logicalViewport":{"width":320,"height":640},"devicePixelRatio":2,"rasterRatio":1,"textScale":2,"padding":{"left":0,"top":20,"right":0,"bottom":10},"viewPadding":{"left":0,"top":20,"right":0,"bottom":10},"viewInsets":{"left":0,"top":0,"right":0,"bottom":0},"boundaryRect":{"left":0,"top":0,"width":320,"height":640},"rasterWidth":320,"rasterHeight":640},"state":"initial","rationale":"Labelled fixture only","equivalenceEvidence":[]}]'

  $fixtureRoot='C:/labelled-current-selection-aggregate'
  function Get-OctoberCompatibilityBinding {return @{worktreePath=$fixtureRoot}}
  function Get-OctoberCoverageBoundHash {
   param($Path)
   if(-not $virtualHashes.ContainsKey($Path)){throw 'Unexpected hash path'}
   if(-not $reads.ContainsKey($Path)){$reads[$Path]=0}
   $reads[$Path]++
   if($caseName -ceq 'final-inventory-drift' -and $Path -ceq $inventoryPath -and $reads[$Path] -gt $profiles.Count){return ('F'*64)}
   if($caseName -ceq 'final-render-drift' -and $Path -ceq $renderDriftPath -and $reads[$Path] -gt 1){return ('F'*64)}
   if($caseName -ceq 'render-late-drift' -and $Path -ceq $metaPath -and $reads[$Path] -gt 1){return ('F'*64)}
   return $virtualHashes[$Path]
  }
  function New-LabelledRetainedExecution {
   param($Profile,$Inventory)
   $selection=Read-OctoberCompatibilityCurrentSelectedRiskBindings -Inventory $Inventory -ExecutionId $Profile -SourceIdentity $identity
   if($null -eq $selection){throw 'Labelled inventory invalid'}
   $run='current-'+[Guid]::NewGuid().ToString('N')
   $relative='apps/mobile/build/compat-current-store_layout_and_recovery-'+$Profile+'-'+$run+'.jsonl'
   $paths=@{};$hashes=@{}
   foreach($role in @('log','capture','stderr')) {
    $suffix=if($role -ceq 'log'){''}elseif($role -ceq 'capture'){'.capture.json'}else{'.stderr.txt'}
    $paths[$role]=[IO.Path]::GetFullPath((Join-Path $fixtureRoot ($relative+$suffix)))
    $hashes[$role]=switch($role){'log' {('A'*64)} 'capture' {('B'*64)} 'stderr' {('C'*64)}}
    $virtualHashes[$paths[$role]]=$hashes[$role]
   }
   $sidecar=[IO.Path]::GetFullPath((Join-Path $fixtureRoot ($relative+'.selection.json')))
   $selectionPins=@{};$selectionPins[$sidecar]=('D'*64);$selectionPins[$inventoryPath]=('E'*64)
   foreach($path in $selectionPins.Keys){$virtualHashes[$path]=$selectionPins[$path]}
   [string[]]$ids=@($selection.SelectedRisks|ForEach-Object {$_.id});[Array]::Sort($ids,[StringComparer]::Ordinal)
   $context=[pscustomobject]@{schemaVersion=1;inventoryPath='apps/mobile/build/compat-current-risk-inventory-00000000000000000000000000000000.json';inventorySha256=('E'*64);
    reportId='store_layout_and_recovery';executionId=$Profile;mode='selected_visual_risks';runId=$run;sourceIdentity=[pscustomobject]$identity.Clone();
    sourceStateIdentity=('A'*64);selectedSlots=@($selection.SelectedSlots);selectedTestKeys=@($selection.SelectedTestKeys);selectedRiskIds=@($ids)}
   $successes=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
   foreach($risk in $selection.SelectedRisks){$null=$successes.Add($risk.representative.testKey)}
   $renderPins=@{};$renderSlots=@{}
   foreach($risk in $selection.SelectedRisks) {
    $slot=$risk.representative.slotId
    $slotPins=@{}
    foreach($suffix in @('.png','.metadata.json')) {
     $path=[IO.Path]::GetFullPath((Join-Path $fixtureRoot ('apps/mobile/build/'+$run+'-'+$slot+$suffix)))
     $renderPins[$path]=('9'*64);$virtualHashes[$path]=('9'*64)
     $slotPins[$path]=('9'*64)
    }
    $renderSlots[$slot]=@{RiskId=$risk.id;TestKey=$risk.representative.testKey;GeometryBinding=@{OriginalFileHashes=$slotPins}}
   }
   return @{Successes=$successes;RetainedFilePaths=$paths;RetainedFileHashes=$hashes;RetainedSelectionFileHashes=$selectionPins;
    CurrentRenderBindings=@{RenderedSlots=$renderSlots;OriginalFileHashes=$renderPins;RecordedRenderBindingsVerified=$true};
    CurrentSelectionBinding=[pscustomobject]@{RelativePath=$relative+'.selection.json';CanonicalPath=$sidecar;Sha256=('D'*64);
     InventoryCanonicalPath=$inventoryPath;InventorySha256=('E'*64);Context=$context;Inventory=$Inventory;Selection=$selection}}
  }
  $cases=0
  foreach($caseName in @('valid-single','valid-multiple','missing-profile','duplicate-profile','different-inventory','wrong-context-slots',
   'wrong-context-risk','wrong-selection','missing-success','wrong-source','wrong-native-path','missing-native-role',
   'extra-selection-pin','conflicting-original-pin','current-inventory-drift','final-inventory-drift','empty-executions',
   'missing-render','render-string-flag','render-missing-pin','render-foreign-slot','render-pin-collision','final-render-drift',
   'valid-same-profile','render-pin-substitution')) {
   $inventory=ConvertFrom-Json -InputObject $seed;$inventory=@($inventory)
   if($caseName -cne 'valid-single') {
    $other=ConvertFrom-Json -InputObject ($inventory[0]|ConvertTo-Json -Depth 30 -Compress)
    $other.id='risk-historical';$other.slotIds=@('H35-visual-1');$other.representative.slotId='H35-visual-1'
    $other.representative.executionId='historical_store_capture';$other.representative.profile='historical_store_capture'
    $other.representative.testKey='work_workspace_layout_safety_test.dart:local Store 1-40 review evidence founder review capture - setup dashboard'
    if($caseName -ceq 'valid-same-profile') {
     $other.id='risk-requirements';$other.slotIds=@('H02-visual-1');$other.representative.slotId='H02-visual-1'
     $other.representative.executionId='workspace_capture';$other.representative.profile='workspace_capture'
     $other.representative.testKey='work_workspace_layout_safety_test.dart:Workspace overnight visual - requirements'
    }
    $inventory+=@($other)
   }
   $profiles=@($inventory|ForEach-Object {$_.representative.executionId}|Sort-Object -Unique)
   $inventoryPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot 'apps/mobile/build/compat-current-risk-inventory-00000000000000000000000000000000.json'))
   $virtualHashes=@{};$reads=@{};$records=@()
   foreach($profile in $profiles){$records+=@(New-LabelledRetainedExecution -Profile $profile -Inventory $inventory)}
   $renderDriftPath=@($records[0].CurrentRenderBindings.OriginalFileHashes.Keys)[0]
   switch($caseName) {
    'missing-profile' {$records=@($records[0])}
    'duplicate-profile' {$records[1]=$records[0]}
    'different-inventory' {$records[0].CurrentSelectionBinding.Inventory=@($inventory[0])}
    'wrong-context-slots' {$records[0].CurrentSelectionBinding.Context.selectedSlots=@('H99-visual-1')}
    'wrong-context-risk' {$records[0].CurrentSelectionBinding.Context.selectedRiskIds=@('wrong')}
    'wrong-selection' {$records[0].CurrentSelectionBinding.Selection=$records[0].CurrentSelectionBinding.Selection.Clone();$records[0].CurrentSelectionBinding.Selection.SelectedTestKeys=@('wrong')}
    'missing-success' {$records[0].Successes.Clear()}
    'wrong-source' {$records[0].CurrentSelectionBinding.Context.sourceIdentity.producerBlob=('f'*40)}
    'wrong-native-path' {$records[0].RetainedFilePaths.capture=$records[0].RetainedFilePaths.log}
    'missing-native-role' {$records[0].RetainedFilePaths.Remove('stderr')}
    'extra-selection-pin' {$records[0].RetainedSelectionFileHashes[(Join-Path $fixtureRoot 'extra.json')]=('F'*64)}
    'conflicting-original-pin' {
     $records[1].CurrentSelectionBinding.InventorySha256=('F'*64);$records[1].CurrentSelectionBinding.Context.inventorySha256=('F'*64)
     $records[1].RetainedSelectionFileHashes[$inventoryPath]=('F'*64)
    }
    'current-inventory-drift' {$virtualHashes[$inventoryPath]=('F'*64)}
    'empty-executions' {$records=@()}
    'missing-render' {$records[0].Remove('CurrentRenderBindings')}
    'render-string-flag' {$records[0].CurrentRenderBindings.RecordedRenderBindingsVerified='true'}
    'render-missing-pin' {$records[0].CurrentRenderBindings.OriginalFileHashes.Remove($renderDriftPath)}
    'render-foreign-slot' {
     $slot=@($records[0].CurrentRenderBindings.RenderedSlots.Keys)[0]
     $row=$records[0].CurrentRenderBindings.RenderedSlots[$slot]
     $records[0].CurrentRenderBindings.RenderedSlots.Remove($slot)
     $records[0].CurrentRenderBindings.RenderedSlots['H99-visual-1']=$row
    }
    'render-pin-collision' {
     $records[0].CurrentRenderBindings.OriginalFileHashes.Remove($renderDriftPath)
     $records[0].CurrentRenderBindings.OriginalFileHashes[$records[0].RetainedFilePaths.log]=('9'*64)
    }
    'render-pin-substitution' {
     $records[0].CurrentRenderBindings.OriginalFileHashes.Remove($renderDriftPath)
     $substitute=[IO.Path]::GetFullPath((Join-Path $fixtureRoot 'apps/mobile/build/unrelated-capture.png'))
     $records[0].CurrentRenderBindings.OriginalFileHashes[$substitute]=('9'*64);$virtualHashes[$substitute]=('9'*64)
    }
   }
   $result=Read-OctoberCompatibilityCurrentRetainedSelectionBindings -Inventory $inventory -Executions $records -SourceIdentity $identity
   $expected=$caseName -in @('valid-single','valid-multiple','valid-same-profile')
   if(($null -ne $result) -ne $expected){throw ('Aggregate result mismatch: '+$caseName)}
   if($expected) {
    if($result.SelectedExecutions.Count -ne $profiles.Count -or $result.OriginalFileHashes.Count -ne (4*$profiles.Count+1+2*$inventory.Count) -or
     -not $result.RetainedSelectionBindingsVerified -or $result.EquivalenceVerified -or $result.GeometryObservationVerified -or $result.QualificationPassed -or $result.ApkAuthority){throw 'Aggregate positive coverage/flags changed'}
    foreach($path in $result.OriginalFileHashes.Keys){if($result.OriginalFileHashes[$path] -cne $virtualHashes[$path] -or $reads[$path] -lt 2){throw 'Original hash lost or final fence missing'}}
   }
   if($caseName -ceq 'conflicting-original-pin' -and $reads[$inventoryPath] -ne 1){throw 'Conflicting pin refreshed or control not reached'}
   if($caseName -ceq 'final-inventory-drift' -and $reads[$inventoryPath] -ne ($profiles.Count+1)){throw 'Final original inventory fence not reached'}
   if($caseName -ceq 'final-render-drift' -and $reads[$renderDriftPath] -ne 2){throw 'Final render original fence not reached'}
   $cases++
  }
  if($cases -ne 25){throw 'Current selection aggregation probe inventory changed.'}
  $pinCases=0;$caseName='combined-original-pins'
  foreach($pinCase in @('disjoint','shared','conflict','missing-behavior','empty-selection','outside','malformed','drift','copy')) {
    $one=[IO.Path]::GetFullPath((Join-Path $fixtureRoot 'one.json'))
    $two=[IO.Path]::GetFullPath((Join-Path $fixtureRoot 'two.json'))
    $behaviorPins=@{};$behaviorPins[$one]=('A'*64)
    $selectionPins=@{};$selectionPins[$two]=('B'*64)
    $virtualHashes=@{};$virtualHashes[$one]=('A'*64);$virtualHashes[$two]=('B'*64);$reads=@{}
    switch($pinCase) {
      'shared' {$selectionPins[$one]=('A'*64)}
      'conflict' {$selectionPins[$one]=('F'*64)}
      'missing-behavior' {$behaviorPins=$null}
      'empty-selection' {$selectionPins=@{}}
      'outside' {$behaviorPins=@{};$behaviorPins[[IO.Path]::GetFullPath('C:/outside-original-pins.json')]=('A'*64)}
      'malformed' {$selectionPins[$two]='invalid'}
      'drift' {$virtualHashes[$one]=('F'*64)}
    }
    $merged=Read-OctoberCompatibilityCurrentCombinedOriginalFilePins -BehaviorPins $behaviorPins -SelectionPins $selectionPins
    $pinExpected=$pinCase -in @('disjoint','shared','copy')
    if(($null -ne $merged) -ne $pinExpected){throw ('Combined original-pin result mismatch: '+$pinCase)}
    if($pinExpected) {
      if($merged.OriginalFileHashes.Count -ne 2 -or $merged.OriginalFileHashes[$one] -cne ('A'*64) -or
        $merged.OriginalFileHashes[$two] -cne ('B'*64) -or -not $merged.FinalFileBindingsVerified -or
        $merged.QualificationPassed -or $merged.ApkAuthority -or $reads.Count -ne 2){throw 'Combined original-pin positive changed'}
      foreach($path in $merged.OriginalFileHashes.Keys){if($reads[$path] -ne 1){throw 'Combined original pin not checked exactly once'}}
      if($pinCase -ceq 'copy') {
        $merged.OriginalFileHashes[$one]=('F'*64)
        if($behaviorPins[$one] -cne ('A'*64) -or $selectionPins[$two] -cne ('B'*64)){throw 'Combined pin return aliases original inputs'}
      }
    }elseif($pinCase -cne 'drift' -and $reads.Count){throw 'Invalid combined inputs reached rehash before validation'}
    if($pinCase -ceq 'drift' -and ($reads.Count -lt 1 -or $behaviorPins[$one] -cne ('A'*64))){throw 'Late drift not reached or original pin refreshed'}
    $pinCases++
  }
  if($pinCases -ne 9){throw 'Combined original-pin probe inventory changed.'}
  $recorderCases=0
  foreach($recorderCase in @('valid','same-test-two-slots','missing','duplicate','unit','lookalike','foreign-slot','wrong-test',
    'post-done','failed','hidden','skipped','wrong-claims','wrong-path','uppercase-hash','source-drift','context-slots',
    'schema-array','classification-array','missing-done','missing-success','ordinary-diagnostic')) {
    # PS5 root JSON arrays are emitted nonenumerated; materialize then flatten.
    $inventory=ConvertFrom-Json -InputObject $seed;$inventory=@($inventory)
    if($recorderCase -ceq 'same-test-two-slots') {
      $inventory[0].id='risk-requirements';$inventory[0].slotIds=@('H02-visual-1')
      $inventory[0].representative.slotId='H02-visual-1'
      $inventory[0].representative.testKey='work_workspace_layout_safety_test.dart:Workspace overnight visual - requirements'
      $second=ConvertFrom-Json -InputObject ($inventory[0]|ConvertTo-Json -Depth 30 -Compress)
      $second.id='risk-guidance';$second.slotIds=@('H02-visual-2');$second.representative.slotId='H02-visual-2';$inventory+=@($second)
    }
    $run='current-'+('0'*32);$profile='workspace_capture'
    $selection=Read-OctoberCompatibilityCurrentSelectedRiskBindings -Inventory $inventory -ExecutionId $profile -SourceIdentity $identity
    if($null -eq $selection){throw ('Recorder probe inventory invalid: '+$recorderCase)}
    $context=[pscustomobject]@{schemaVersion=1;inventoryPath='apps/mobile/build/compat-current-risk-inventory-00000000000000000000000000000000.json';inventorySha256=('E'*64);
      reportId='store_layout_and_recovery';executionId=$profile;mode='selected_visual_risks';runId=$run;sourceIdentity=[pscustomobject]$identity.Clone();
      sourceStateIdentity=('A'*64);selectedSlots=@($selection.SelectedSlots);selectedTestKeys=@($selection.SelectedTestKeys);
      selectedRiskIds=@($selection.SelectedRisks|ForEach-Object {$_.id}|Sort-Object -CaseSensitive)}
    $plan=Get-OctoberCompatibilityCurrentExecutionPlan -ReportId $context.reportId -ExecutionId $profile -Mode selected_visual_risks -RunId $run `
      -SourceIdentity $identity -SelectedSlots $selection.SelectedSlots -SelectedTestKeys $selection.SelectedTestKeys
    $claims=@{}
    foreach($define in $plan.RuntimeDefines) {
      if($define.StartsWith('MOOL_TECHNICAL_CAPTURE_',[StringComparison]::Ordinal)) {
        $pair=$define.Split('=',2)
        $field=switch($pair[0]) {
          'MOOL_TECHNICAL_CAPTURE_RUN_ID' {'runId'} 'MOOL_TECHNICAL_CAPTURE_EXECUTION_ID' {'executionId'}
          'MOOL_TECHNICAL_CAPTURE_PROFILE' {'profile'} 'MOOL_TECHNICAL_CAPTURE_SOURCE_COMMIT' {'sourceCommit'}
          'MOOL_TECHNICAL_CAPTURE_SOURCE_TREE' {'sourceTree'} 'MOOL_TECHNICAL_CAPTURE_EXECUTION_HEAD' {'executionHead'}
          'MOOL_TECHNICAL_CAPTURE_PRODUCER_BLOB' {'producerBlob'} 'MOOL_TECHNICAL_CAPTURE_REGISTRY_SHA256' {'registrySha256'}
        }
        $claims[$field]=$pair[1]
      }
    }
    $events=[Collections.Generic.List[object]]::new()
    $suite=[IO.Path]::GetFullPath((Join-Path $fixtureRoot 'apps/mobile/test/work_workspace_layout_safety_test.dart'))
    $events.Add([pscustomobject]@{type='suite';suite=[pscustomobject]@{id=1;path=$suite}})
    $keys=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$testId=0
    foreach($name in $selection.SelectedTestKeys) {
      $testId++;$key='work_workspace_layout_safety_test.dart:'+$name;$null=$keys.Add($key)
      $events.Add([pscustomobject]@{type='testStart';test=[pscustomobject]@{id=$testId;suiteID=1;name=$name}})
      foreach($risk in @($selection.SelectedRisks|Where-Object {$_.representative.testKey -ceq $key})) {
        $slot=$risk.representative.slotId
        $literal=@((Read-OctoberCompatibilityCurrentQualificationContract).visualSlots|Where-Object {$_.slot -ceq $slot})[0]
        $png=[IO.Path]::GetFullPath((Join-Path $fixtureRoot ('apps/mobile/build/compat-current-technical/'+$run+'/'+$profile+'/'+$slot+'.png')))
        $capture=[pscustomobject]@{schema='moolsocial.current-technical-capture-event.v1';classification='technical-observation';syntheticFixture=$true;
          founderApproved=$false;provenanceClaimsVerified=$false;slotId=$slot;originalReference=$literal.reference;pngPath=$png;
          metadataPath=($png.Substring(0,$png.Length-4)+'.json');pngSha256=('a'*64);metadataSha256=('b'*64);provenanceClaims=[pscustomobject]$claims.Clone()}
        $events.Add([pscustomobject]@{type='print';testID=$testId;message=('MOOL_TECHNICAL_CAPTURE '+($capture|ConvertTo-Json -Depth 10 -Compress))})
      }
      $events.Add([pscustomobject]@{type='testDone';testID=$testId;result='success';hidden=$false;skipped=$false})
    }
    $wire=ConvertFrom-Json -InputObject ($events.ToArray()|ConvertTo-Json -Depth 20 -Compress)
    $capture=ConvertFrom-Json -InputObject $wire[2].message.Substring('MOOL_TECHNICAL_CAPTURE '.Length)
    switch($recorderCase) {
      'missing' {$wire=@($wire[0],$wire[1],$wire[3])}
      'duplicate' {$wire=@($wire[0],$wire[1],$wire[2],$wire[2],$wire[3])}
      'unit' {$wire[2].message=$wire[2].message.Replace('MOOL_TECHNICAL_CAPTURE ','MOOL_TECHNICAL_CAPTURE_UNIT ')}
      'lookalike' {$wire[2].message=$wire[2].message.Replace('MOOL_TECHNICAL_CAPTURE ','MOOL_TECHNICAL_CAPTURE: ')}
      'foreign-slot' {$capture.slotId='H03-visual-1'}
      'wrong-test' {$wire[1].test.name='Workspace overnight visual - contact'}
      'post-done' {$wire=@($wire[0],$wire[1],$wire[3],$wire[2])}
      'failed' {$wire[3].result='error'}
      'hidden' {$wire[3].hidden=$true}
      'skipped' {$wire[3].skipped=$true}
      'wrong-claims' {$capture.provenanceClaims.sourceCommit=('e'*40)}
      'wrong-path' {$capture.pngPath=$capture.pngPath.Replace('H01-visual-1','H02-visual-1')}
      'uppercase-hash' {$capture.pngSha256=('A'*64)}
      'source-drift' {$context.sourceIdentity.captureSourceCommit=('e'*40)}
      'context-slots' {$context.selectedSlots=@('H02-visual-1')}
      'schema-array' {$capture.schema=@('moolsocial.current-technical-capture-event.v1')}
      'classification-array' {$capture.classification=@('technical-observation')}
      'missing-done' {$wire=@($wire[0],$wire[1],$wire[2])}
      'missing-success' {$keys.Clear()}
      'ordinary-diagnostic' {$wire=@($wire[0],$wire[1],[pscustomobject]@{type='print';testID=1;message='Ordinary test diagnostic'},$wire[2],$wire[3])}
    }
    if($recorderCase -in @('foreign-slot','wrong-claims','wrong-path','uppercase-hash','schema-array','classification-array')) {
      $wire[2].message='MOOL_TECHNICAL_CAPTURE '+($capture|ConvertTo-Json -Depth 10 -Compress)
    }
    $joined=Read-OctoberCompatibilityCurrentSelectedRecorderEvents -Events @($wire) -Context $context -Inventory $inventory `
      -SourceIdentity $identity -SuccessfulKeys $keys
    $expected=$recorderCase -in @('valid','same-test-two-slots','ordinary-diagnostic')
    if(($null -ne $joined) -ne $expected){throw ('Selected recorder-event result mismatch: '+$recorderCase)}
    if($expected -and ($joined.Captures.Count -ne $selection.SelectedSlots.Count -or -not $joined.RecorderEventsBound -or
      $joined.ArtifactBytesVerified -or $joined.GeometryObservationVerified -or $joined.InspectionVerified -or $joined.QualificationPassed -or $joined.ApkAuthority)) {
      throw 'Selected recorder-event positive flags/coverage changed'
    }
    if($expected) {
      foreach($risk in $selection.SelectedRisks) {
        $slot=$risk.representative.slotId;$actual=$joined.Captures[$slot]
        $relative='apps/mobile/build/compat-current-technical/'+$run+'/'+$profile+'/'+$slot+'.png'
        if($actual.RiskId -cne $risk.id -or $actual.TestKey -cne $risk.representative.testKey -or $actual.TestId -ne 1 -or
          $actual.PngRelativePath -cne $relative -or $actual.MetadataRelativePath -cne ($relative.Substring(0,$relative.Length-4)+'.json') -or
          $actual.PngSha256 -cne ('A'*64) -or $actual.MetadataSha256 -cne ('B'*64)){throw 'Recorder positive lost exact risk/test/path/hash binding'}
      }
    }
    $recorderCases++
  }
  if($recorderCases -ne 22){throw 'Selected recorder-event probe inventory changed.'}
  # Labelled in-memory byte fixtures: real parser/hash/PNG decoder, mocked leases.
  Add-Type -AssemblyName System.Drawing
  $fixtureBitmap=[Drawing.Bitmap]::new(4,3,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $fixturePngBuffer=[IO.MemoryStream]::new()
  try {
    $fixtureBitmap.SetPixel(0,0,[Drawing.Color]::Teal)
    $fixtureBitmap.Save($fixturePngBuffer,[Drawing.Imaging.ImageFormat]::Png)
    [byte[]]$fixturePng=$fixturePngBuffer.ToArray()
  }finally{try{$fixturePngBuffer.Dispose()}finally{$fixtureBitmap.Dispose()}}
  $baseCapture=ConvertFrom-Json -InputObject ($joined.Captures['H01-visual-1']|ConvertTo-Json -Depth 20 -Compress)
  function Open-OctoberCompatibilityVisualArtifact {
    param($Base,$RelativePath,$ExpectedSha256,$MaxBytes=67108864)
    $role=if($RelativePath -ceq $captureFixture.MetadataRelativePath){'metadata'}elseif($RelativePath -ceq $captureFixture.PngRelativePath){'png'}else{throw 'Unexpected fixture lease path'}
    if($artifactCase -ceq 'absent-lease' -and $role -ceq 'png'){return $null}
    $payload=$leasePayloads[$role];$leaseLimits[$role]=$MaxBytes
    if($payload.Length -gt $MaxBytes){return $null}
    $stream=[pscustomobject]@{Disposed=$false;FailDispose=($artifactCase -ceq 'dispose-error' -and $role -ceq 'png')}
    $stream|Add-Member -MemberType ScriptMethod -Name Dispose -Value {$this.Disposed=$true;if($this.FailDispose){throw 'Labelled lease disposal failure'}}
    $leasedStreams[$role]=$stream
    $canonical=[IO.Path]::GetFullPath((Join-Path $Base $RelativePath))
    if($artifactCase -ceq 'path-substitution' -and $role -ceq 'metadata'){$canonical=[IO.Path]::GetFullPath((Join-Path $Base 'wrong-metadata.json'))}
    $fileIdentity=if($role -ceq 'metadata' -or $artifactCase -ceq 'same-file-identity'){'00000001:0000000000000001'}else{'00000001:0000000000000002'}
    return [pscustomobject]@{CanonicalPath=$canonical;Sha256=$ExpectedSha256;Bytes=$payload;FileIdentity=$fileIdentity;Stream=$stream}
  }
  $artifactCases=0;$caseName='recorder-artifact-fixtures'
  foreach($artifactCase in @('valid','duplicate-metadata-key','incomplete','approved','not-synthetic','provider-verified','comparison-passed','provenance-verified',
    'schema-array','claim-array','wrong-claim','wrong-slot','wrong-reference','byte-count','dimension','unsupported-dimension',
    'metadata-hash-drift','png-hash-drift','bad-png','same-file-identity','absent-lease','observations-array','dispose-error','path-substitution','pin-drift')) {
    $captureFixture=ConvertFrom-Json -InputObject ($baseCapture|ConvertTo-Json -Depth 20 -Compress)
    [byte[]]$pngBytes=$fixturePng.Clone()
    if($artifactCase -ceq 'bad-png'){$pngBytes=[byte[]]$fixturePng[0..32]}
    $pngHash=Get-OctoberCompatibilityByteHash $pngBytes
    $captureFixture.PngSha256=$pngHash;$captureFixture.Event.pngSha256=$pngHash.ToLowerInvariant()
    $metadata=[pscustomobject]@{schema='moolsocial.current-technical-capture.v1';classification='technical-observation';syntheticFixture=$true;complete=$true;
      founderApproved=$false;comparisonPassed=$false;providerVerified=$false;provenanceClaimsVerified=$false;
      provenanceClaims=$captureFixture.Event.provenanceClaims;originalReference=$captureFixture.Event.originalReference;slotId=$captureFixture.Event.slotId;
      pngWidth=4;pngHeight=3;pngBytes=$pngBytes.Length;pngSha256=$pngHash.ToLowerInvariant();observations=[pscustomobject]@{unverifiedFixture='geometry pending'}}
    switch($artifactCase) {
      'incomplete' {$metadata.complete=$false}
      'approved' {$metadata.founderApproved=$true}
      'not-synthetic' {$metadata.syntheticFixture=$false}
      'provider-verified' {$metadata.providerVerified=$true}
      'comparison-passed' {$metadata.comparisonPassed=$true}
      'provenance-verified' {$metadata.provenanceClaimsVerified=$true}
      'schema-array' {$metadata.schema=@('moolsocial.current-technical-capture.v1')}
      'claim-array' {$metadata.provenanceClaims=ConvertFrom-Json -InputObject ($metadata.provenanceClaims|ConvertTo-Json -Compress);$metadata.provenanceClaims.runId=@($metadata.provenanceClaims.runId)}
      'wrong-claim' {$metadata.provenanceClaims=ConvertFrom-Json -InputObject ($metadata.provenanceClaims|ConvertTo-Json -Compress);$metadata.provenanceClaims.sourceCommit=('e'*40)}
      'wrong-slot' {$metadata.slotId='H02-visual-1'}
      'wrong-reference' {$metadata.originalReference='workspace-requirements.png'}
      'byte-count' {$metadata.pngBytes++}
      'dimension' {$metadata.pngWidth=5}
      'unsupported-dimension' {$metadata.pngWidth=8193}
      'observations-array' {$metadata.observations=@([pscustomobject]@{unverifiedFixture='geometry pending'})}
    }
    $metadataJson=$metadata|ConvertTo-Json -Depth 20 -Compress
    if($artifactCase -ceq 'duplicate-metadata-key'){$metadataJson=$metadataJson.Substring(0,$metadataJson.Length-1)+',"schema":"moolsocial.current-technical-capture.v1"}'}
    [byte[]]$metadataBytes=[Text.UTF8Encoding]::new($false,$true).GetBytes($metadataJson)
    $metadataHash=Get-OctoberCompatibilityByteHash $metadataBytes
    $captureFixture.MetadataSha256=$metadataHash;$captureFixture.Event.metadataSha256=$metadataHash.ToLowerInvariant()
    $leasePayloads=@{metadata=$metadataBytes;png=$pngBytes}
    if($artifactCase -ceq 'metadata-hash-drift'){$leasePayloads.metadata=[byte[]]$metadataBytes.Clone();$leasePayloads.metadata[0]=32}
    if($artifactCase -ceq 'png-hash-drift'){$leasePayloads.png=[byte[]]$pngBytes.Clone();$leasePayloads.png[0]=0}
    $metaPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot $captureFixture.MetadataRelativePath))
    $pngPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot $captureFixture.PngRelativePath))
    $virtualHashes=@{};$virtualHashes[$metaPath]=$metadataHash;$virtualHashes[$pngPath]=$pngHash
    if($artifactCase -ceq 'pin-drift'){$virtualHashes[$metaPath]=('F'*64)}
    $reads=@{};$leasedStreams=@{};$leaseLimits=@{}
    $artifact=Read-OctoberCompatibilityCurrentRecorderArtifactBytes -Capture $captureFixture
    if(($null -ne $artifact) -ne ($artifactCase -ceq 'valid')){throw ('Recorder artifact-byte result mismatch: '+$artifactCase)}
    foreach($stream in $leasedStreams.Values){if(-not $stream.Disposed){throw ('Recorder lease not disposed: '+$artifactCase)}}
    if($artifactCase -ceq 'dispose-error' -and $leasedStreams.Count -ne 2){throw 'Disposal failure did not exercise both leases'}
    if($artifactCase -ceq 'pin-drift' -and ($reads.Count -ne 1 -or $reads[$metaPath] -ne 1 -or $captureFixture.MetadataSha256 -cne $metadataHash)) {
      throw 'Recorder late metadata fence not reached or original hash refreshed'
    }
    if($artifactCase -ceq 'valid') {
      if(-not $artifact.ArtifactBytesVerified -or $artifact.GeometryObservationVerified -or $artifact.InspectionVerified -or $artifact.QualificationPassed -or $artifact.ApkAuthority -or
        $artifact.OriginalFileHashes.Count -ne 2 -or $artifact.OriginalFileHashes[$metaPath] -cne $metadataHash -or $artifact.OriginalFileHashes[$pngPath] -cne $pngHash -or
        $artifact.PngWidth -ne 4 -or $artifact.PngHeight -ne 3 -or $artifact.Metadata.slotId -cne 'H01-visual-1' -or
        $leaseLimits.metadata -ne 4194304 -or $leaseLimits.png -ne 67108864 -or $reads.Count -ne 2){throw 'Recorder artifact-byte positive binding/limits changed'}
    }
    $artifactCases++
  }
  if($artifactCases -ne 25){throw 'Recorder artifact-byte probe inventory changed.'}
  # Labelled geometry fixtures, not native captures or visual acceptance.
  $geometrySeed='{"logicalViewport":{"width":12,"height":8},"devicePixelRatio":3,"rasterRatio":2,"textScale":1.5,"padding":{"left":1,"top":2,"right":0,"bottom":1},"viewPadding":{"left":0,"top":0,"right":0,"bottom":3},"viewInsets":{"left":0,"top":0,"right":0,"bottom":4},"boundaryRect":{"left":1,"top":2,"width":2,"height":1.5},"rasterWidth":4,"rasterHeight":3}'
  $observationSeed='{"fixtureKind":"existing-authored-widget-test-state","requestedTargetType":"LabelledMeasurementTarget","requestedTargetKey":null,"requestedTargetGlobalRect":{"left":3,"top":3,"width":2,"height":1.5},"boundaryType":"LabelledBoundary","boundaryLocalPaintBounds":{"left":1,"top":2,"width":2,"height":1.5},"boundaryToGlobalTransform":[1,0,0,0,0,1,0,0,0,0,1,0,2,1,0,1],"boundaryGlobalPaintBounds":{"left":3,"top":3,"width":2,"height":1.5},"rasterPixelRatio":2,"rootView":{"devicePixelRatio":3,"physicalWidth":36,"physicalHeight":24,"logicalWidth":12,"logicalHeight":8,"padding":{"left":3,"top":6,"right":0,"bottom":3},"viewPadding":{"left":0,"top":0,"right":0,"bottom":9},"viewInsets":{"left":0,"top":0,"right":0,"bottom":12}},"descendantMediaQuery":{"width":12,"height":8,"padding":{"left":0,"top":0,"right":0,"bottom":0},"viewPadding":{"left":0,"top":0,"right":0,"bottom":0},"viewInsets":{"left":0,"top":0,"right":0,"bottom":0},"textScaleAtOne":1.5}}'
  $geometryCases=0
  $geometryPins=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
  $geometryPins.Add($metaPath,$metadataHash);$geometryPins.Add($pngPath,$pngHash)
  foreach($geometryCase in @('valid','key-string','fractional-ceil','transform-roundoff','transform-outside-tolerance','reviewed-exact','nonfinite-transform','no-descendant','string-density','zero-density','root-size','negative-inset','text-scale','raster-density-confusion','short-transform','zero-w','mixed-w','global-bounds','target-outside','wrong-target','bad-key','zero-boundary','png-dimension','extra-observation','unit-fixture','unverified-bytes')) {
    $observed=ConvertFrom-Json $observationSeed
    $risk=[pscustomobject]@{target='LabelledMeasurementTarget';geometry=(ConvertFrom-Json $geometrySeed)}
    $geometryArtifact=@{ArtifactBytesVerified=$true;Metadata=[pscustomobject]@{observations=$observed};PngWidth=4;PngHeight=3;OriginalFileHashes=$geometryPins}
    switch($geometryCase) {
      'key-string' {$observed.requestedTargetKey='[<labelled-key>]'}
      'fractional-ceil' {$observed.boundaryLocalPaintBounds.width=1.51;$observed.boundaryGlobalPaintBounds.width=1.51;$observed.requestedTargetGlobalRect.width=1.51;$risk.geometry.boundaryRect.width=1.51}
      'transform-roundoff' {$observed.boundaryGlobalPaintBounds.width=2.00000005}
      'transform-outside-tolerance' {$observed.boundaryGlobalPaintBounds.width=2.0000002}
      'reviewed-exact' {$risk.geometry.boundaryRect.width=2.00000001}
      'nonfinite-transform' {$observed.boundaryToGlobalTransform[0]=[double]::PositiveInfinity}
      'no-descendant' {$observed.descendantMediaQuery=$null}
      'string-density' {$observed.rootView.devicePixelRatio='3'}
      'zero-density' {$observed.rootView.devicePixelRatio=0}
      'root-size' {$observed.rootView.logicalWidth=13}
      'negative-inset' {$observed.rootView.padding.left=-3}
      'text-scale' {$observed.descendantMediaQuery.textScaleAtOne=1}
      'raster-density-confusion' {$observed.rasterPixelRatio=3}
      'short-transform' {$observed.boundaryToGlobalTransform=@(1,0)}
      'zero-w' {$observed.boundaryToGlobalTransform[15]=0}
      'mixed-w' {$observed.boundaryToGlobalTransform[3]=1;$observed.boundaryToGlobalTransform[15]=-2}
      'global-bounds' {$observed.boundaryGlobalPaintBounds.left=4}
      'target-outside' {$observed.requestedTargetGlobalRect.width=3}
      'wrong-target' {$observed.requestedTargetType='OtherTarget'}
      'bad-key' {$observed.requestedTargetKey=@('key')}
      'zero-boundary' {$observed.boundaryLocalPaintBounds.width=0}
      'png-dimension' {$geometryArtifact.PngWidth=5}
      'extra-observation' {$observed|Add-Member NoteProperty unexpected 1}
      'unit-fixture' {$observed.fixtureKind='unit-only'}
      'unverified-bytes' {$geometryArtifact.ArtifactBytesVerified=$false}
    }
    $geometryResult=Read-OctoberCompatibilityCurrentRecorderGeometry -Artifact $geometryArtifact -Risk $risk
    if(($null -ne $geometryResult) -ne ($geometryCase -cin @('valid','key-string','fractional-ceil','transform-roundoff'))){throw ('Recorder geometry result mismatch: '+$geometryCase)}
    if($null -ne $geometryResult -and (-not $geometryResult.GeometryObservationVerified -or $geometryResult.TargetSemanticsVerified -or $geometryResult.InspectionVerified -or $geometryResult.QualificationPassed -or $geometryResult.ApkAuthority -or $geometryResult.Geometry.rasterRatio -ne 2 -or $geometryResult.Geometry.devicePixelRatio -ne 3 -or $geometryResult.Observations.descendantMediaQuery.padding.left -ne 0)){throw 'Recorder geometry positive binding/authority changed'}
    if($null -ne $geometryResult) {
      $geometryResult.OriginalFileHashes[$metaPath]='D'*64
      if($geometryPins[$metaPath] -cne $metadataHash){throw 'Recorder geometry mutated its original byte pins'}
    }
    $geometryCases++
  }
  $renderCases=0
  foreach($renderCase in @('valid','event-test','metadata-bytes','geometry','late-pin','missing-success','source-claims','extra-event')) {
    $inventory=ConvertFrom-Json $seed;$inventory=@($inventory)
    $inventory[0].target='LabelledMeasurementTarget';$inventory[0].geometry=ConvertFrom-Json $geometrySeed
    $captureFixture=ConvertFrom-Json ($baseCapture|ConvertTo-Json -Depth 20 -Compress)
    [byte[]]$pngBytes=$fixturePng.Clone();$pngHash=Get-OctoberCompatibilityByteHash $pngBytes
    $captureFixture.PngSha256=$pngHash;$captureFixture.Event.pngSha256=$pngHash.ToLowerInvariant()
    $metadata=[pscustomobject]@{schema='moolsocial.current-technical-capture.v1';classification='technical-observation';syntheticFixture=$true;complete=$true;
      founderApproved=$false;comparisonPassed=$false;providerVerified=$false;provenanceClaimsVerified=$false;
      provenanceClaims=$captureFixture.Event.provenanceClaims;originalReference=$captureFixture.Event.originalReference;slotId=$captureFixture.Event.slotId;
      pngWidth=4;pngHeight=3;pngBytes=$pngBytes.Length;pngSha256=$pngHash.ToLowerInvariant();observations=(ConvertFrom-Json $observationSeed)}
    if($renderCase -ceq 'geometry'){$metadata.observations.descendantMediaQuery.textScaleAtOne=1}
    [byte[]]$metadataBytes=[Text.UTF8Encoding]::new($false,$true).GetBytes(($metadata|ConvertTo-Json -Depth 20 -Compress))
    $metadataHash=Get-OctoberCompatibilityByteHash $metadataBytes
    $captureFixture.MetadataSha256=$metadataHash;$captureFixture.Event.metadataSha256=$metadataHash.ToLowerInvariant()
    $metaPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot $captureFixture.MetadataRelativePath))
    $pngPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot $captureFixture.PngRelativePath))
    $virtualHashes=@{};$virtualHashes[$metaPath]=$metadataHash;$virtualHashes[$pngPath]=$pngHash
    $leasePayloads=@{metadata=$metadataBytes;png=$pngBytes};$leaseLimits=@{};$leasedStreams=@{};$reads=@{}
    $artifactCase='valid';$caseName=if($renderCase -ceq 'late-pin'){'render-late-drift'}else{'render-chain-fixture'}
    $renderEvents=ConvertFrom-Json ($events.ToArray()|ConvertTo-Json -Depth 20 -Compress)
    $renderEvents[2].message='MOOL_TECHNICAL_CAPTURE '+($captureFixture.Event|ConvertTo-Json -Depth 20 -Compress)
    $renderKeys=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $null=$renderKeys.Add($inventory[0].representative.testKey)
    switch($renderCase) {
      'event-test' {$renderEvents[2].testID=99}
      'metadata-bytes' {$leasePayloads.metadata=[byte[]]$metadataBytes.Clone();$leasePayloads.metadata[0]=32}
      'missing-success' {$renderKeys.Clear()}
      'source-claims' {$captureFixture.Event.provenanceClaims.sourceCommit='f'*40;$renderEvents[2].message='MOOL_TECHNICAL_CAPTURE '+($captureFixture.Event|ConvertTo-Json -Depth 20 -Compress)}
      'extra-event' {$renderEvents=@($renderEvents[0],$renderEvents[1],$renderEvents[2],$renderEvents[2],$renderEvents[3])}
    }
    $render=Read-OctoberCompatibilityCurrentSelectedRenderBindings -Events @($renderEvents) -Context $context -Inventory $inventory -SourceIdentity $identity -SuccessfulKeys $renderKeys
    if(($null -ne $render) -ne ($renderCase -ceq 'valid')){throw ('Selected render chain result mismatch: '+$renderCase)}
    foreach($stream in $leasedStreams.Values){if(-not $stream.Disposed){throw 'Selected render chain leaked artifact lease'}}
    if($null -ne $render -and (-not $render.RecordedRenderBindingsVerified -or $render.InspectionVerified -or $render.QualificationPassed -or $render.ApkAuthority -or
      $render.RenderedSlots.Count -ne 1 -or $render.OriginalFileHashes.Count -ne 2 -or $render.OriginalFileHashes[$metaPath] -cne $metadataHash -or $reads[$metaPath] -ne 2)){throw 'Selected render chain lost original pins or authority boundary'}
    if($renderCase -ceq 'late-pin' -and $reads[$metaPath] -ne 2){throw 'Selected render late fence not reached'}
    $renderCases++
  }
  # Two-risk pairing: actual event/geometry/compositor, labelled byte-reader mock.
  $pairCases=& {
    function Get-OctoberCoverageBoundHash($Path) {
      if(-not $pairHashes.ContainsKey($Path)){throw 'Pairing read an unexpected original'}
      return $pairHashes[$Path]
    }
    function Read-OctoberCompatibilityCurrentRecorderArtifactBytes($Capture) {
      $pairCalls.bytes++
      $risk=@($pairInventory|Where-Object {$_.representative.slotId -ceq $Capture.Event.slotId})
      if($risk.Count -ne 1 -or $Capture.RiskId -cne $risk[0].id -or $Capture.TestKey -cne $risk[0].representative.testKey){throw 'Pairing substituted risk/test identity'}
      $observations=ConvertFrom-Json $observationSeed
      $width=$risk[0].geometry.logicalViewport.width
      if($pairCase -ceq 'swapped'){$width=if($width -eq 12){13}else{12}}
      $observations.rootView.logicalWidth=$width;$observations.rootView.physicalWidth=3*$width
      $observations.descendantMediaQuery.width=$width
      $pins=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
      foreach($role in @('metadata','png')) {
        $path=[IO.Path]::GetFullPath($Capture.Event.($role+'Path'));$hash=$Capture.Event.($role+'Sha256').ToUpperInvariant()
        $pins.Add($path,$hash);$pairHashes[$path]=$hash
      }
      return @{ArtifactBytesVerified=$true;Metadata=[pscustomobject]@{observations=$observations};PngWidth=4;PngHeight=3;OriginalFileHashes=$pins}
    }
    $count=0
    foreach($pairCase in @('valid','swapped','missing')) {
      $first=ConvertFrom-Json $seed;$first=@($first)[0];$first.target='LabelledMeasurementTarget';$first.geometry=ConvertFrom-Json $geometrySeed
      $second=ConvertFrom-Json ($first|ConvertTo-Json -Depth 20 -Compress)
      $second.id='risk-second';$second.slotIds=@('H02-visual-1');$second.representative.slotId='H02-visual-1'
      $second.representative.testKey='work_workspace_layout_safety_test.dart:Workspace overnight visual - requirements'
      $second.geometry.logicalViewport.width=13;$second.currentSurface='Labelled second surface';$second.state='distinct viewport'
      $pairInventory=@($first,$second)
      $selected=Read-OctoberCompatibilityCurrentSelectedRiskBindings -Inventory $pairInventory -ExecutionId workspace_capture -SourceIdentity $identity
      if($null -eq $selected){throw 'Pairing selection invalid'}
      $pairContext=ConvertFrom-Json ($context|ConvertTo-Json -Depth 20 -Compress)
      $pairContext.selectedSlots=@($selected.SelectedSlots);$pairContext.selectedTestKeys=@($selected.SelectedTestKeys)
      $pairContext.selectedRiskIds=@($selected.SelectedRisks|ForEach-Object {$_.id}|Sort-Object -CaseSensitive)
      $pairEvents=[Collections.Generic.List[object]]::new();$pairSuccesses=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
      $pairEvents.Add([pscustomobject]@{type='suite';suite=[pscustomobject]@{id=1;path=$suite}})
      $pairHashes=@{};$pairCalls=@{bytes=0};$pairTestId=0
      foreach($risk in $pairInventory) {
        $pairTestId++;$key=$risk.representative.testKey;$null=$pairSuccesses.Add($key)
        $pairEvents.Add([pscustomobject]@{type='testStart';test=[pscustomobject]@{id=$pairTestId;suiteID=1;name=$key.Substring($key.IndexOf(':')+1)}})
        $captureEvent=ConvertFrom-Json ($baseCapture.Event|ConvertTo-Json -Depth 20 -Compress)
        $captureEvent.slotId=$risk.representative.slotId
        $captureEvent.originalReference=@((Read-OctoberCompatibilityCurrentQualificationContract).visualSlots|Where-Object {$_.slot -ceq $captureEvent.slotId})[0].reference
        $captureEvent.pngPath=[IO.Path]::GetFullPath((Join-Path $fixtureRoot ('apps/mobile/build/compat-current-technical/'+$run+'/workspace_capture/'+$captureEvent.slotId+'.png')))
        $captureEvent.metadataPath=$captureEvent.pngPath.Substring(0,$captureEvent.pngPath.Length-4)+'.json'
        if($pairCase -cne 'missing' -or $pairTestId -ne 2){$pairEvents.Add([pscustomobject]@{type='print';testID=$pairTestId;message=('MOOL_TECHNICAL_CAPTURE '+($captureEvent|ConvertTo-Json -Depth 20 -Compress))})}
        $pairEvents.Add([pscustomobject]@{type='testDone';testID=$pairTestId;result='success';hidden=$false;skipped=$false})
      }
      $paired=Read-OctoberCompatibilityCurrentSelectedRenderBindings -Events $pairEvents.ToArray() -Context $pairContext -Inventory $pairInventory -SourceIdentity $identity -SuccessfulKeys $pairSuccesses
      if(($null -ne $paired) -ne ($pairCase -ceq 'valid')){throw ('Render multiple-risk pairing mismatch: '+$pairCase)}
      if($pairCase -ceq 'valid') {
        if($paired.RenderedSlots.Count -ne 2 -or $paired.OriginalFileHashes.Count -ne 4 -or $pairCalls.bytes -ne 2 -or $paired.InspectionVerified -or $paired.QualificationPassed -or $paired.ApkAuthority){throw 'Valid pair lost originals/count/authority'}
        foreach($risk in $pairInventory) {
          $actual=$paired.RenderedSlots[$risk.representative.slotId]
          if($actual.RiskId -cne $risk.id -or $actual.TestKey -cne $risk.representative.testKey -or $actual.GeometryBinding.Geometry.logicalViewport.width -ne $risk.geometry.logicalViewport.width){throw 'Valid pair matched by position rather than exact identity'}
        }
      }
      if($pairCase -ceq 'swapped' -and $pairCalls.bytes -ne 1){throw 'Swapped pair did not fail at first geometry binding'}
      if($pairCase -ceq 'missing' -and $pairCalls.bytes -ne 0){throw 'Missing pair reached bytes before event completeness check'}
      $count++
    }
    return $count
  }
  # Actual retained-file reader, labelled receipt/sidecar/render mocks. No Flutter.
  $boundaryCases=& {
    $boundaryRoot=Join-Path ([IO.Path]::GetTempPath()) ('mool-labelled-reader-'+[Guid]::NewGuid().ToString('N'))
    $boundaryBuild=Join-Path $boundaryRoot 'apps/mobile/build'
    [void][IO.Directory]::CreateDirectory($boundaryBuild)
    $createdFiles=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    function Get-OctoberCompatibilityBinding {return @{worktreePath=$boundaryRoot}}
    function Get-OctoberCoverageBoundHash($Path) {
      if(-not $boundaryReads.ContainsKey($Path)){$boundaryReads[$Path]=0};$boundaryReads[$Path]++
      return Get-OctoberCompatibilityByteHash ([IO.File]::ReadAllBytes($Path))
    }
    function Read-OctoberCompatibilityCurrentSelectionContextFile {
      param($RelativePath,$ExpectedSha256,$ReportId,$ExecutionId,$RunId,$SourceIdentity)
      if($RelativePath -cne $relative+'.selection.json' -or $ExpectedSha256 -cne $sidecarHash){throw 'Boundary wrong retained selection query'}
      return $boundaryProof
    }
    function Read-OctoberCompatibilityCurrentExecutionEvents {
      param($Capture,$Events,$ReportId,$ExecutionId,$Mode,$RunId,$SourceIdentity,$LogSha,$SelectedSlots,$SelectedTestKeys,$SelectionContextPath,$SelectionContextSha256)
      if((ConvertTo-Json -InputObject @($Events) -Depth 20 -Compress) -cne $boundaryEventJson -or $LogSha -cne $logHash){throw 'Boundary receipt did not consume actual log bytes'}
      return @{Successes=$boundarySuccesses;QualificationPassed=$false;ApkAuthority=$false}
    }
    function Read-OctoberCompatibilityCurrentSelectedRenderBindings {
      param($Events,$Context,$Inventory,$SourceIdentity,$SuccessfulKeys)
      $boundaryCalls.render++
      if((ConvertTo-Json -InputObject @($Events) -Depth 20 -Compress) -cne $boundaryEventJson -or
        -not [object]::ReferenceEquals($Context,$boundaryProof.Context) -or -not [object]::ReferenceEquals($Inventory,$boundaryProof.Inventory) -or
        -not [object]::ReferenceEquals($SuccessfulKeys,$boundarySuccesses) -or -not [object]::ReferenceEquals($SourceIdentity,$identity)){throw 'Boundary substituted log/success/selection/source objects'}
      if($boundaryCase -ceq 'render-null'){return $null}
      if($boundaryCase -ceq 'render-throw'){throw 'Labelled render failure'}
      if($boundaryCase -ceq 'render-malformed'){return @{RecordedRenderBindingsVerified='true'}}
      if($boundaryCase -ceq 'late-native'){[IO.File]::AppendAllText($logPath,"`n")}
      return @{RecordedRenderBindingsVerified=$true;OriginalFileHashes=$boundaryArtifactPins;InspectionVerified=$false;QualificationPassed=$false;ApkAuthority=$false}
    }
    $count=0
    try {
      foreach($boundaryCase in @('valid','render-null','render-throw','render-malformed','late-native','behavior-only')) {
        $mode=if($boundaryCase -ceq 'behavior-only'){'behavior_only'}else{'selected_visual_risks'}
        $profile=if($mode -ceq 'behavior_only'){'default'}else{'workspace_capture'}
        $slots=if($mode -ceq 'behavior_only'){@()}else{@('H01-visual-1')}
        $names=if($mode -ceq 'behavior_only'){@()}else{@('Workspace overnight visual - choose')}
        $relative='apps/mobile/build/compat-current-boundary-'+$boundaryCase+'.jsonl'
        $logPath=[IO.Path]::GetFullPath((Join-Path $boundaryRoot $relative));$capturePath=$logPath+'.capture.json';$stderrPath=$logPath+'.stderr.txt'
        $sidecarPath=$logPath+'.selection.json';$inventoryPath=Join-Path $boundaryBuild 'inventory.json'
        foreach($path in @($logPath,$capturePath,$stderrPath,$sidecarPath,$inventoryPath)){[void]$createdFiles.Add($path)}
        [IO.File]::WriteAllText($sidecarPath,'labelled sidecar reader mock');[IO.File]::WriteAllText($inventoryPath,'labelled inventory reader mock');[IO.File]::WriteAllBytes($stderrPath,[byte[]]@())
        $sidecarHash=Get-OctoberCompatibilityByteHash ([IO.File]::ReadAllBytes($sidecarPath))
        $boundaryEvents=@([pscustomobject]@{type='print';message='Labelled native receipt fixture'})
        if($mode -ceq 'selected_visual_risks'){$boundaryEvents+=@([pscustomobject]@{type='print';message='moolsocialSelectionContext';selectionContext=[pscustomobject]@{path=$relative+'.selection.json';sha256=$sidecarHash}})}
        $boundaryEventJson=ConvertTo-Json -InputObject @($boundaryEvents) -Depth 20 -Compress
        [IO.File]::WriteAllText($logPath,(@($boundaryEvents|ForEach-Object{$_|ConvertTo-Json -Depth 20 -Compress}) -join "`n"))
        $logHash=Get-OctoberCompatibilityByteHash ([IO.File]::ReadAllBytes($logPath))
        [IO.File]::WriteAllText($capturePath,([pscustomobject]@{stderrPath=$relative+'.stderr.txt';stderrSha256=(Get-OctoberCompatibilityByteHash ([byte[]]@()))}|ConvertTo-Json -Compress))
        $plan=Get-OctoberCompatibilityCurrentExecutionPlan -ReportId store_layout_and_recovery -ExecutionId $profile -Mode $mode -RunId $run -SourceIdentity $identity -SelectedSlots @($slots) -SelectedTestKeys @($names)
        if($null -eq $plan){throw 'Boundary plan invalid'}
        $evidence=[pscustomobject]@{executionId=$profile;path=$relative;capturePath=$relative+'.capture.json';sha256=$logHash;captureSha256=(Get-OctoberCompatibilityByteHash ([IO.File]::ReadAllBytes($capturePath)));runtimeDefines=@($plan.RuntimeDefines)}
        $boundaryProof=[pscustomobject]@{CanonicalPath=$sidecarPath;Sha256=$sidecarHash;InventoryCanonicalPath=$inventoryPath;InventorySha256=(Get-OctoberCompatibilityByteHash ([IO.File]::ReadAllBytes($inventoryPath)));
          Context=[pscustomobject]@{labelledBoundary='context'};Inventory=@([pscustomobject]@{labelledBoundary='inventory'});Selection=[pscustomobject]@{SelectedSlots=@($slots);SelectedTestKeys=@($names)}}
        $boundarySuccesses=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$null=$boundarySuccesses.Add('labelled-success-this-execution')
        $boundaryArtifactPins=@{};$boundaryArtifactPins[$sidecarPath]=$sidecarHash;$boundaryArtifactPins[$inventoryPath]=$boundaryProof.InventorySha256
        $boundaryReads=@{};$boundaryCalls=@{render=0}
        $actual=Read-OctoberCompatibilityCurrentExecutionEvidence -Evidence $evidence -ReportId store_layout_and_recovery -ExecutionId $profile -Mode $mode -RunId $run -SourceIdentity $identity -SelectedSlots @($slots) -SelectedTestKeys @($names)
        if(($null -ne $actual) -ne ($boundaryCase -cin @('valid','behavior-only'))){throw ('Retained reader boundary result mismatch: '+$boundaryCase)}
        if($mode -ceq 'behavior_only') {if($boundaryCalls.render -ne 0 -or $actual.ContainsKey('CurrentRenderBindings')){throw 'Behavior-only reader invoked render chain'}}
        elseif($boundaryCalls.render -ne 1){throw 'Selected retained reader did not invoke render chain once'}
        if($boundaryCase -ceq 'valid' -and ($actual.CurrentRenderBindings.QualificationPassed -or $boundaryReads[$logPath] -ne 2 -or $boundaryReads[$sidecarPath] -ne 2)){throw 'Retained reader lost final originals/authority boundary'}
        if($boundaryCase -ceq 'late-native' -and $boundaryReads[$logPath] -ne 2){throw 'Post-render native original fence not reached'}
        $count++
      }
    }finally {
      foreach($path in $createdFiles){if([IO.File]::Exists($path)){[IO.File]::Delete($path)}}
      foreach($dir in @($boundaryBuild,(Join-Path $boundaryRoot 'apps/mobile'),(Join-Path $boundaryRoot 'apps'),$boundaryRoot)){[IO.Directory]::Delete($dir,$false)}
    }
    return $count
  }
  [pscustomobject]@{Cases=$cases;CombinedPinCases=$pinCases;RecorderEventCases=$recorderCases;ArtifactByteCases=$artifactCases;GeometryCases=$geometryCases;RenderChainCases=$renderCases;MultiRiskPairCases=$pairCases;RetainedReaderBoundaryCases=$boundaryCases;ActualRiskSelector=$true;
   NativeAndFileHashes='labelled native/hash/lease mocks; actual byte hash and PNG decoder';SourceAdmission=$false;
   EquivalenceVerified=$false;ActualRender=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress


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

function Invoke-OctoberCompatibilityCurrentPrimaryVisualReviewProbes {
  # Labelled upstream render/native mocks. This tests binding, not actual images.
  $identity=@{runtimeSourceCommit='3c3f38136db8bb184866635203d04ea4643f1eac';contractCommit=('a'*40);
    captureSourceCommit=('b'*40);captureSourceTree=('c'*40);producerBlob=('d'*40);executionHead=('b'*40)}
  $base=(Get-OctoberCompatibilityBinding).worktreePath
  $png='apps/mobile/build/compat-current-technical/current-'+('0'*32)+'/workspace_capture/H01-visual-1.png'
  $metadata=$png.Substring(0,$png.Length-4)+'.json'
  $log='apps/mobile/build/compat-current-store_layout_and_recovery-workspace_capture-current-'+('0'*32)+'.jsonl'
  $capture=$log+'.capture.json'
  $fields=@('riskId','artifactPath','artifactSha256','executionCapturePath','executionCaptureSha256','recorderMetadataPath',
    'recorderMetadataSha256','eventLogPath','eventLogSha256','executionId','testKey','sourceIdentity','geometry','inspectedBy','inspectedAtUtc','findings','resolved')
  function Read-OctoberCompatibilityCurrentSuccessorSpecification {param($Commit) return [pscustomobject]@{visuals=[pscustomobject]@{observationFields=$fields}}}
  $count=0
  foreach($case in @('valid','missing-primary','untyped-primary','untyped-selection','primary-source','missing-review',
    'review-difference','inventory-difference','unresolved','wrong-inspector','bad-time','observation-source','foreign-risk',
    'wrong-test','wrong-execution','png-path','png-hash','metadata-hash','log-hash','capture-hash','geometry',
    'missing-slot','wrong-render-risk','missing-original','duplicate-observation',
    'valid-empty-findings','original-pin-hash','cross-risk-substitution')) {
    $risk=[pscustomobject]@{id='risk-choose';slotIds=@('H01-visual-1');representative=[pscustomobject]@{
      slotId='H01-visual-1';executionId='workspace_capture';testKey='work_workspace_layout_safety_test.dart:choose'};state='Labelled fixture';geometry=[pscustomobject]@{width=4}}
    $observation=[pscustomobject][ordered]@{riskId=$risk.id;artifactPath=$png;artifactSha256=('A'*64);executionCapturePath=$capture;
      executionCaptureSha256=('D'*64);recorderMetadataPath=$metadata;recorderMetadataSha256=('B'*64);eventLogPath=$log;eventLogSha256=('C'*64);
      executionId='workspace_capture';testKey=$risk.representative.testKey;sourceIdentity=[pscustomobject]$identity.Clone();geometry=$risk.geometry;
      inspectedBy='primary:/root';inspectedAtUtc='2026-10-11T00:00:00.0000000+00:00';findings=@('Labelled review fixture, not an actual inspected image');resolved=$true}
    $originals=@{}
    foreach($pair in @(@($png,('A'*64)),@($metadata,('B'*64)),@($log,('C'*64)),@($capture,('D'*64)))) {
      $originals[[IO.Path]::GetFullPath((Join-Path $base $pair[0]))]=$pair[1]
    }
    $row=@{RiskId=$risk.id;TestKey=$risk.representative.testKey;
      Capture=@{PngRelativePath=$png;PngSha256=('A'*64);MetadataRelativePath=$metadata;MetadataSha256=('B'*64)};
      GeometryBinding=@{Geometry=$risk.geometry;GeometryObservationVerified=$true}}
    $render=@{RecordedRenderBindingsVerified=$true;RenderedSlots=@{'H01-visual-1'=$row}}
    $execution=@{RetainedFilePaths=@{log=[IO.Path]::GetFullPath((Join-Path $base $log));capture=[IO.Path]::GetFullPath((Join-Path $base $capture))};
      RetainedFileHashes=@{log=('C'*64);capture=('D'*64)};CurrentRenderBindings=$render}
    $selection=@{RetainedSelectionBindingsVerified=$true;OriginalFileHashes=$originals;SelectedExecutions=@{workspace_capture=$execution}}
    $primaryEntry=[pscustomobject]@{riskId=$risk.id;inventoryEntry=$risk;observation=$observation}
    $primaryEntry=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($primaryEntry|ConvertTo-Json -Depth 40 -Compress)))
    $primary=@{PrimaryReviewRecordBound=$true;Report=[pscustomobject]@{sourceIdentity=[pscustomobject]$identity.Clone();visualReviews=@($primaryEntry)}}
    switch($case) {
      'missing-primary' {$primary=$null}
      'untyped-primary' {$primary.PrimaryReviewRecordBound='true'}
      'untyped-selection' {$selection.RetainedSelectionBindingsVerified='true'}
      'primary-source' {$primary.Report.sourceIdentity.executionHead=('f'*40)}
      'missing-review' {$primary.Report.visualReviews=@()}
      'review-difference' {$primaryEntry.observation.findings=@('Different independently retained review')}
      'inventory-difference' {$primaryEntry.inventoryEntry.state='Different reviewed fixture'}
      'unresolved' {$observation.resolved=$false;$primaryEntry.observation.resolved=$false}
      'wrong-inspector' {$observation.inspectedBy='subagent';$primaryEntry.observation.inspectedBy='subagent'}
      'bad-time' {$observation.inspectedAtUtc='yesterday';$primaryEntry.observation.inspectedAtUtc='yesterday'}
      'observation-source' {$observation.sourceIdentity.producerBlob=('f'*40);$primaryEntry.observation.sourceIdentity.producerBlob=('f'*40)}
      'foreign-risk' {$observation.riskId='other-risk'}
      'wrong-test' {$observation.testKey='other';$primaryEntry.observation.testKey='other'}
      'wrong-execution' {$observation.executionId='other';$primaryEntry.observation.executionId='other'}
      'png-path' {$observation.artifactPath='apps/mobile/build/unrelated.png';$primaryEntry.observation.artifactPath=$observation.artifactPath}
      'png-hash' {$observation.artifactSha256=('F'*64);$primaryEntry.observation.artifactSha256=$observation.artifactSha256}
      'metadata-hash' {$observation.recorderMetadataSha256=('F'*64);$primaryEntry.observation.recorderMetadataSha256=$observation.recorderMetadataSha256}
      'log-hash' {$observation.eventLogSha256=('F'*64);$primaryEntry.observation.eventLogSha256=$observation.eventLogSha256}
      'capture-hash' {$observation.executionCaptureSha256=('F'*64);$primaryEntry.observation.executionCaptureSha256=$observation.executionCaptureSha256}
      'geometry' {$observation.geometry=[pscustomobject]@{width=5};$primaryEntry.observation.geometry=$observation.geometry}
      'missing-slot' {$render.RenderedSlots=@{}}
      'wrong-render-risk' {$row.RiskId='other'}
      'missing-original' {$originals.Remove([IO.Path]::GetFullPath((Join-Path $base $png)))}
      'valid-empty-findings' {$observation.findings=@();$primaryEntry.observation.findings=@()}
      'original-pin-hash' {$originals[[IO.Path]::GetFullPath((Join-Path $base $png))]=('F'*64)}
      'cross-risk-substitution' {
        # An otherwise valid retained render from risk B cannot occupy risk A's
        # representative slot, even with identical geometry and test identity.
        $otherPng=$png.Replace('H01-visual-1','H02-visual-1')
        $otherMetadata=$otherPng.Substring(0,$otherPng.Length-4)+'.json'
        $originals[[IO.Path]::GetFullPath((Join-Path $base $otherPng))]=('E'*64)
        $originals[[IO.Path]::GetFullPath((Join-Path $base $otherMetadata))]=('F'*64)
        $render.RenderedSlots['H01-visual-1']=@{RiskId='risk-other';TestKey=$risk.representative.testKey;
          Capture=@{PngRelativePath=$otherPng;PngSha256=('E'*64);MetadataRelativePath=$otherMetadata;MetadataSha256=('F'*64)};
          GeometryBinding=@{Geometry=$risk.geometry;GeometryObservationVerified=$true}}
        $observation.artifactPath=$otherPng;$observation.artifactSha256=('E'*64)
        $observation.recorderMetadataPath=$otherMetadata;$observation.recorderMetadataSha256=('F'*64)
        $primaryEntry.observation=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($observation|ConvertTo-Json -Depth 40 -Compress)))
      }
    }
    $observations=@($observation);if($case -ceq 'duplicate-observation'){$observations+=@($observation)}
    $result=Read-OctoberCompatibilityCurrentPrimaryVisualReview -Inventory @($risk) -Observations $observations -SourceIdentity $identity -SelectionEvidence $selection -PrimaryBinding $primary
    $expectValid=$case -in @('valid','valid-empty-findings')
    if(($null -ne $result) -ne $expectValid){throw ('Primary visual review mismatch: '+$case)}
    if($expectValid -and (-not $result.PrimaryVisualReviewBound -or $result.Reviews.Count -ne 1 -or
      $result.EquivalenceVerified -or $result.FounderApprovalVerified -or $result.QualificationPassed -or $result.ApkAuthority)){throw 'Primary visual review overclaimed authority.'}
    $count++
  }
  $slotCases=Invoke-OctoberCompatibilityCurrentVisualSlotAccountingProbes
  $presentationCases=Invoke-OctoberCompatibilityCurrentPresentationReviewProbes
  $compositionCases=Invoke-OctoberCompatibilityCurrentQualifiedEvidenceProbes
  $activationCases=Invoke-OctoberCompatibilityCurrentQualificationActivationProbes
  $incrementalCases=Invoke-OctoberCompatibilityIncrementalMetadataPhaseProbes
  [pscustomobject]@{PrimaryVisualReviewCases=$count;VisualSlotAccountingCases=$slotCases;PresentationReviewCases=$presentationCases;CompositionCases=$compositionCases;ActivationCases=$activationCases;IncrementalStageCases=$incrementalCases;LabelledUpstreamRenderMocks=$true;ActualInspection=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
}

function Invoke-OctoberCompatibilityIncrementalMetadataPhaseProbes {
  # Actual incremental predicate; labelled index/preparation observations.
  $phaseTokens=$null;$phaseErrors=$null
  $phaseAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'check-cross-agent-incremental-ticket-gate.ps1'),[ref]$phaseTokens,[ref]$phaseErrors)
  if($phaseErrors.Count){throw 'Incremental phase parser failed.'}
  $phaseNodes=@($phaseAst.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-CompatibilityIncrementalImplementationStage'},$true))
  if($phaseNodes.Count -ne 1){throw 'Incremental phase predicate missing/duplicated.'}
  . ([scriptblock]::Create($phaseNodes[0].Extent.Text))
  $count=0
  foreach($phaseCase in @('working','staged','unprepared','untyped','index-failure','foreign-staged','untyped-stage','qualified-stage')) {
    $phaseReads=@{count=0}
    function Get-OctoberCompatibilityGitLines {
      param([string[]]$Arguments)
      if(($Arguments -join '|') -cne 'diff|--cached|--name-only'){throw 'Unexpected incremental phase read.'}
      if($phaseCase -ceq 'index-failure'){throw 'Labelled index failure.'}
      if($phaseCase -ceq 'staged'){return @('scripts/check-cross-agent-incremental-ticket-gate.ps1')}
      if($phaseCase -ceq 'foreign-staged'){return @('apps/mobile/lib/unowned.dart')}
      return @()
    }
    function Test-OctoberCompatibilityCurrentPreparation {
      param([string]$Phase)
      $phaseReads.count++
      $expected=if($phaseCase -cin @('staged','foreign-staged')){'pre_commit'}else{'implementation'}
      if($Phase -cne $expected -or $phaseCase -cin @('unprepared','foreign-staged')){return $false}
      if($phaseCase -ceq 'untyped'){return 'true'};return $true
    }
    $stage=if($phaseCase -ceq 'untyped-stage'){'16'}elseif($phaseCase -ceq 'qualified-stage'){19}else{16}
    $result=Test-CompatibilityIncrementalImplementationStage $stage
    if($result -isnot [bool] -or $result -ne ($phaseCase -cin @('working','staged'))){throw ('Incremental phase mismatch: '+$phaseCase)}
    if($result -and $phaseReads.count -ne 1){throw 'Incremental stage bypassed preparation.'}
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityCurrentQualificationActivationProbes {
  # Actual boolean adapter, labelled already-composed evidence only.
  $count=0
  foreach($activationCase in @('valid-working','valid-index','valid-committed','invalid-both','missing','untyped-bound','provider','untyped-provider','images','untyped-images','apk','untyped-apk')) {
    $activationHistory=@{Stage=$(if($activationCase -ceq 'valid-committed'){19}else{18})}
    $activationWorking=$activationCase -cnotin @('valid-committed','valid-index')
    $activationIndex=$activationCase -cin @('valid-index','invalid-both')
    $activationEvidence=@{CurrentFrontendEvidenceBound=$true;ProviderVerified=$false;FounderApprovedImages=$false;ApkAuthority=$false}
    switch($activationCase){
      'untyped-bound' {$activationEvidence.CurrentFrontendEvidenceBound='true'}
      'provider' {$activationEvidence.ProviderVerified=$true}
      'untyped-provider' {$activationEvidence.ProviderVerified='false'}
      'images' {$activationEvidence.FounderApprovedImages=$true}
      'untyped-images' {$activationEvidence.FounderApprovedImages='false'}
      'apk' {$activationEvidence.ApkAuthority=$true}
      'untyped-apk' {$activationEvidence.ApkAuthority='false'}
    }
    function Read-OctoberCompatibilityCurrentQualifiedEvidence {
      param($History,[switch]$FromWorkingTree,[switch]$FromIndex)
      if($History.Stage -ne $activationHistory.Stage -or [bool]$FromWorkingTree -ne $activationWorking -or
        [bool]$FromIndex -ne $activationIndex){throw 'Activation changed history/read mode.'}
      if($activationCase -ceq 'missing'){return $null};return $activationEvidence
    }
    $result=Test-OctoberCompatibilityQualification -History $activationHistory -FromWorkingTree:$activationWorking -FromIndex:$activationIndex
    if($result -isnot [bool] -or $result -ne ($activationCase -in @('valid-working','valid-index','valid-committed'))){throw ('Activation mismatch: '+$activationCase)}
    $count++
  }
  # Execute the three actual staged-Q call expressions with a labelled callee.
  # This checks caller wiring, not a live staged qualification or acceptance.
  $callerTokens=$null;$callerErrors=$null
  $callerAst=[Management.Automation.Language.Parser]::ParseFile($checkerPath,[ref]$callerTokens,[ref]$callerErrors)
  if($callerErrors.Count){throw 'Qualification caller parser failed.'}
  $indexCalls=@($callerAst.FindAll({param($node)
    $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Test-OctoberCompatibilityQualification' -and
    @($node.CommandElements|Where-Object {$_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -ceq 'FromIndex'}).Count -eq 1
  },$true))
  if($indexCalls.Count -ne 3){throw 'Exact staged-Q caller set changed.'}
  $compatibilityHistory=@{Stage=18};$callerChecks=@{count=0}
  function Test-OctoberCompatibilityQualification {
    param($History,[switch]$FromWorkingTree,[switch]$FromIndex)
    if($History.Stage -ne 18 -or $FromWorkingTree -or -not $FromIndex){throw 'Precommit caller changed staged-Q mode.'}
    $callerChecks.count++;return $true
  }
  foreach($call in $indexCalls){if((& ([scriptblock]::Create($call.Extent.Text))) -ne $true){throw 'Staged-Q caller expression failed.'};$count++}
  if($callerChecks.count -ne 3){throw 'Staged-Q caller omitted invocation.'}
  return $count
}

function Invoke-OctoberCompatibilityCurrentQualifiedEvidenceProbes {
  param([object]$SlotFixture)
  # Labelled leaf mocks exercise orchestration and final fences, not actual Q.
  $operativeSlot=(Get-Command Read-OctoberCompatibilityCurrentVisualSlotAccounting -CommandType Function -ErrorAction SilentlyContinue).ScriptBlock
  $count=0
  $compositionCases=if($null -ne $SlotFixture){@('valid')}else{@('valid','proof','primary','cycles','assertions','skips','presentation','selection','plan','execution','retained','visual','slots','files','pin-conflict','pin-drift','document-drift','proof-drift','history-drift',
    'untyped-proof','untyped-primary','untyped-cycles','untyped-assertions','untyped-skips','untyped-presentation','untyped-retained','untyped-visual','untyped-slots','untyped-files',
    'final-render-drift','final-primary-drift','selected-log-mismatch','selected-profile-mismatch')}
  foreach($case in $compositionCases) {
    $calls=@{proof=0;renderDrift=$false;primaryDrift=$false}
    $task=[IO.Path]::GetFullPath('C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store')
    $pins=@{};foreach($n in 1..4){$pins[(Join-Path $task ('probe-'+$n+'.json'))]='A'*64}
    $other=@{};foreach($n in 3..4){$other[(Join-Path $task ('probe-'+$n+'.json'))]='A'*64}
    if($case -ceq 'pin-conflict'){$other[(Join-Path $task 'probe-3.json')]='B'*64}
    $compositionProof=[pscustomobject]@{runtimeSourceCommit=('a'*40);contractCommit=('b'*40);captureSourceCommit=('c'*40);
      captureSourceTree=('d'*40);producerBlob=('e'*40);cycles=@();obligations=@();visualReconciliation=@();providerDeferrals=@('pending');
      visualRiskInventory=@([pscustomobject]@{representative=[pscustomobject]@{executionId='workspace_capture'}});
      visualObservations=@([pscustomobject]@{executionId='workspace_capture';eventLogPath=('apps/mobile/build/compat-current-store_layout_and_recovery-workspace_capture-current-'+('a'*32)+'.jsonl');
        eventLogSha256=('A'*64);executionCapturePath='fixture.capture.json';executionCaptureSha256=('A'*64)})}
    $leaves=@{primary=@{PrimaryReviewRecordBound=$true;OriginalTaskFileHashes=$pins};cycles=@{CyclesVerified=$true;OriginalFileHashes=@{native='A'}};
      assertions=@{PrimaryAssertionReviewBound=$true};skips=@{SkippedCoverageVerified=$true};presentation=@{SpecificPresentationReviewBound=$true;OriginalTaskFileHashes=$other};
      selection=@{SelectedSlots=@('H01@portrait');SelectedTestKeys=@('test')};plan=@{RuntimeDefines=@()};execution=@{actual=$true};
      retained=@{RetainedSelectionBindingsVerified=$true;OriginalFileHashes=@{render='A'}};visual=@{PrimaryVisualReviewBound=$true};
      slots=@{HistoricalSlotsAccounted=$true;CurrentVisualDispositionReviewBound=$true};files=@{FinalFileBindingsVerified=$true;OriginalFileHashes=@{native='A';render='A'}}}
    if($null -ne $SlotFixture){
      $compositionProof.obligations=$SlotFixture.Primary.Report.sourceReviews
      $compositionProof.visualRiskInventory=$SlotFixture.Inventory
      $compositionProof.visualReconciliation=$SlotFixture.Rows
      $leaves.primary=$SlotFixture.Primary.Clone();$leaves.primary.OriginalTaskFileHashes=$pins
      $leaves.assertions=$SlotFixture.Assertions;$leaves.visual=$SlotFixture.Visual
      $leaves.presentation=$SlotFixture.Presentation.Clone();$leaves.presentation.OriginalTaskFileHashes=$other
    }
    $flags=@{primary='PrimaryReviewRecordBound';cycles='CyclesVerified';assertions='PrimaryAssertionReviewBound';skips='SkippedCoverageVerified';
      presentation='SpecificPresentationReviewBound';retained='RetainedSelectionBindingsVerified';visual='PrimaryVisualReviewBound';
      slots='HistoricalSlotsAccounted';files='FinalFileBindingsVerified'}
    foreach($name in $flags.Keys){if($case -ceq ('untyped-'+$name)){$leaves[$name][$flags[$name]]='true'}}
    if($case -ceq 'selected-log-mismatch'){$compositionProof.visualObservations[0].eventLogPath='apps/mobile/build/unrelated.jsonl'}
    if($case -ceq 'selected-profile-mismatch'){$compositionProof.visualObservations[0].executionId='founder_capture'}
    function Read-ProbeLeaf([string]$Name){
      if($case -ceq $Name -or ($Name -ceq 'files' -and $calls.renderDrift)){return $null};return $leaves[$Name]
    }
    function Read-OctoberCompatibilityCurrentQualificationProof {
      $calls.proof++
      if($case -ceq 'proof'){return $null}
      $snapshot='A'*64;$history=@{Stage=18}
      if($calls.proof -eq 2){
        if($case -ceq 'document-drift'){$snapshot='B'*64}
        if($case -ceq 'proof-drift'){$compositionProof.providerDeferrals=@('changed')}
        if($case -ceq 'history-drift'){$history.Stage=19}
        if($case -ceq 'final-render-drift'){$calls.renderDrift=$true}
        if($case -ceq 'final-primary-drift'){$calls.primaryDrift=$true}
      }
      # Copy: mutating the final reader must not mutate the initial snapshot.
      $copy=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($compositionProof|ConvertTo-Json -Depth 20 -Compress)))
      return @{Proof=$copy;History=$history;StructureVerified=$(if($case -ceq 'untyped-proof'){'true'}else{$true});QualificationDocumentSnapshotSha256=$snapshot}
    }
    function Read-OctoberCompatibilityCurrentPrimaryReviewBinding {Read-ProbeLeaf primary}
    function Read-OctoberCompatibilityCurrentCycles {Read-ProbeLeaf cycles}
    function Read-OctoberCompatibilityCurrentPrimaryAssertionReview {Read-ProbeLeaf assertions}
    function Read-OctoberCompatibilityCurrentSkippedCoverage {Read-ProbeLeaf skips}
    function Read-OctoberCompatibilityCurrentPresentationReview {Read-ProbeLeaf presentation}
    function Read-OctoberCompatibilityCurrentSelectedRiskBindings {Read-ProbeLeaf selection}
    function Get-OctoberCompatibilityCurrentExecutionPlan {Read-ProbeLeaf plan}
    function Read-OctoberCompatibilityCurrentExecutionEvidence {Read-ProbeLeaf execution}
    function Read-OctoberCompatibilityCurrentRetainedSelectionBindings {Read-ProbeLeaf retained}
    function Read-OctoberCompatibilityCurrentPrimaryVisualReview {Read-ProbeLeaf visual}
    function Read-OctoberCompatibilityCurrentVisualSlotAccounting {
      param($Reconciliation,$Inventory,$SourceIdentity,$PrimaryVisualReview,$PrimaryAssertionReview,$PrimaryBinding,$PresentationReview)
      if($null -eq $SlotFixture){return (Read-ProbeLeaf slots)}
      return (& $operativeSlot -Reconciliation $Reconciliation -Inventory $Inventory -SourceIdentity $SourceIdentity `
        -PrimaryVisualReview $PrimaryVisualReview -PrimaryAssertionReview $PrimaryAssertionReview -PrimaryBinding $PrimaryBinding -PresentationReview $PresentationReview)
    }
    function Read-OctoberCompatibilityCurrentCombinedOriginalFilePins {Read-ProbeLeaf files}
    function Get-OctoberCoverageBoundHash {if($case -ceq 'pin-drift' -or $calls.primaryDrift){return ('B'*64)};return ('A'*64)}
    $result=Read-OctoberCompatibilityCurrentQualifiedEvidence -History @{Stage=18} -FromWorkingTree
    $expected=if($null -ne $SlotFixture){$SlotFixture.ExpectedSuccess}else{$case -ceq 'valid'}
    if(($null -ne $result) -ne $expected){throw ('Current composition mismatch: '+$case)}
    if($expected -and (-not $result.CurrentFrontendEvidenceBound -or $result.ProviderVerified -or
      $result.FounderApprovedImages -or $result.ApkAuthority -or $result.QualificationPassed)){throw 'Composition overclaimed authority.'}
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityCurrentPresentationReviewProbes {
  # Actual pinned manifest bytes; labelled access-receipt/authority/lease mocks.
  # No TASK source, approval, application data or evidence file is written.
  $taskBase='C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store'
  $manifestPath=[IO.Path]::GetFullPath((Join-Path $taskBase 'work/founder-input-gate.json'))
  $statePath=[IO.Path]::GetFullPath((Join-Path $taskBase 'work/founder-input-read-state.local.json'))
  $actualManifestBytes=[IO.File]::ReadAllBytes($manifestPath)
  $actualManifest=Read-OctoberCompatibilityJsonObject $actualManifestBytes
  $presentationForward=Read-OctoberCompatibilitySource19ForwardAmendment -FromWorkingTree
  $actualManifestHash=Get-OctoberCompatibilityByteHash $actualManifestBytes
  if($null -eq $presentationForward -or $presentationForward.founderSourceCount -ne 42 -or
    $presentationForward.founderManifestSha256 -cne $actualManifestHash){throw 'Current presentation fixture requires the pinned42-source amendment.'}
  # Isolated labelled contract identity, not a published source or approval.
  function Read-OctoberCompatibilitySource19ForwardAmendment {
    param([string]$Commit,[switch]$FromIndex,[switch]$FromWorkingTree)
    if($Commit -cne ('b'*40) -or $FromIndex -or $FromWorkingTree){throw 'Unexpected presentation fixture contract selection.'}
    return $presentationForward
  }
  $sourcePath=[IO.Path]::GetFullPath((Join-Path $taskBase $actualManifest.sources[20]))
  $source40Path=[IO.Path]::GetFullPath((Join-Path $taskBase $actualManifest.sources[40]))
  $source40Bytes=[IO.File]::ReadAllBytes($source40Path)
  $source40Hash=Get-OctoberCompatibilityByteHash $source40Bytes
  $source41Path=[IO.Path]::GetFullPath((Join-Path $taskBase $actualManifest.sources[41]))
  $source41Bytes=[IO.File]::ReadAllBytes($source41Path)
  $source41Hash=Get-OctoberCompatibilityByteHash $source41Bytes
  $count=0
  foreach($presentationProbeCase in @('valid','missing-primary','untyped-assertions','primary-source','manifest-pin','state-task',
    'duplicate-receipt','unlisted-path','candidate-hash','authority-bytes','absent-excerpt','wrong-case','wrong-clause',
    'wrong-requirement','unknown-slot','duplicate-slot','empty-change','authentic-unreviewed-change','source39',
    'late-authority-drift','late-state-drift','file-alias','untyped-receipt-index','other-case-known-slot',
    'stale-manifest-state','missing-source40-receipt','source40','stale41-manifest-state','missing-source41-receipt','source41')) {
    $authorityBytes=[Text.Encoding]::UTF8.GetBytes('Labelled fixture: approved compact current layout for this specific case.')
    $authorityHash=Get-OctoberCompatibilityByteHash $authorityBytes
    $readState=[pscustomobject]@{task='store-buy-compatibility-20261008';manifestHash=$actualManifestHash;
      reads=@(0..41|ForEach-Object {[pscustomobject]@{index=$_;hash=$(if($_ -eq 20){$authorityHash}elseif($_ -eq 40){$source40Hash}elseif($_ -eq 41){$source41Hash}else{'A'*64});utc='2026-10-11T00:00:00.0000000Z'}});consumed=$false}
    if($presentationProbeCase -ceq 'stale-manifest-state'){$readState.manifestHash='78A0C5E9C653EF10E708C5B5CD61370083942EDDE0665D74C19506BBE6A85A9D';$readState.reads=@($readState.reads[0..39])}
    if($presentationProbeCase -ceq 'missing-source40-receipt'){$readState.reads=@($readState.reads|Where-Object {$_.index -ne 40})}
    if($presentationProbeCase -ceq 'missing-source41-receipt'){$readState.reads=@($readState.reads|Where-Object {$_.index -ne 41})}
    if($presentationProbeCase -ceq 'stale41-manifest-state'){$readState.manifestHash='F77FEBDD4117C856269A391B6AA151A3509B7DE020117F4165A59521BD8682D3';$readState.reads=@($readState.reads[0..40])}
    if($presentationProbeCase -ceq 'state-task'){$readState.task='other-task'}
    if($presentationProbeCase -ceq 'duplicate-receipt'){$readState.reads[39]=$readState.reads[38]}
    if($presentationProbeCase -ceq 'untyped-receipt-index'){$readState.reads[0].index='0'}
    $stateBytes=[Text.Encoding]::UTF8.GetBytes(($readState|ConvertTo-Json -Depth 10 -Compress))
    $snapshots=@{}
    $snapshots[$manifestPath]=@{Bytes=$actualManifestBytes;Hash=(Get-OctoberCompatibilityByteHash $actualManifestBytes);Id='00000001:0000000000000001'}
    $snapshots[$statePath]=@{Bytes=$stateBytes;Hash=(Get-OctoberCompatibilityByteHash $stateBytes);Id='00000001:0000000000000002'}
    $snapshots[$sourcePath]=@{Bytes=$authorityBytes;Hash=$authorityHash;Id='00000001:0000000000000003'}
    $snapshots[$source40Path]=@{Bytes=$source40Bytes;Hash=$source40Hash;Id='00000001:0000000000000004'}
    $snapshots[$source41Path]=@{Bytes=$source41Bytes;Hash=$source41Hash;Id='00000001:0000000000000005'}
    if($presentationProbeCase -ceq 'manifest-pin'){$snapshots[$manifestPath].Hash='F'*64}
    if($presentationProbeCase -ceq 'authority-bytes'){$snapshots[$sourcePath].Bytes=[Text.Encoding]::UTF8.GetBytes('Changed authority bytes')}
    if($presentationProbeCase -ceq 'file-alias'){$snapshots[$statePath].Id=$snapshots[$manifestPath].Id}
    $hashReads=@{};$opened=[Collections.Generic.List[object]]::new()
    function Get-OctoberCoverageBoundHash {
      param([string]$Path)
      if(-not $snapshots.ContainsKey($Path)){throw 'Unexpected presentation hash path.'}
      if(-not $hashReads.ContainsKey($Path)){$hashReads[$Path]=0};$hashReads[$Path]++
      if(($presentationProbeCase -ceq 'late-authority-drift' -and $Path -ceq $sourcePath -and $hashReads[$Path] -ge 2) -or
        ($presentationProbeCase -ceq 'late-state-drift' -and $Path -ceq $statePath -and $hashReads[$Path] -ge 3)){return ('F'*64)}
      return $snapshots[$Path].Hash
    }
    function Open-OctoberCompatibilityVisualArtifact {
      param($Base,$RelativePath,$ExpectedSha256,$MaxBytes)
      $path=[IO.Path]::GetFullPath((Join-Path $Base $RelativePath))
      if(-not $snapshots.ContainsKey($path)){throw 'Unexpected presentation lease path.'}
      $snapshot=$snapshots[$path]
      $lease=[pscustomobject]@{CanonicalPath=$path;Sha256=$snapshot.Hash;Bytes=[byte[]]$snapshot.Bytes;
        FileIdentity=$snapshot.Id;Stream=[IO.MemoryStream]::new()}
      $opened.Add($lease);return $lease
    }
    function Read-OctoberCompatibilityCurrentQualificationContract {param($Commit) return [pscustomobject]@{
      visualSlots=@([pscustomobject]@{slot='H01-visual-1'},[pscustomobject]@{slot='H02-visual-1'})}}
    $identity=@{runtimeSourceCommit=('a'*40);contractCommit=('b'*40);captureSourceCommit=('c'*40);
      captureSourceTree=('d'*40);producerBlob=('e'*40);executionHead=('c'*40)}
    $decision=[pscustomobject]@{schemaVersion=1;ordinal=1;clause=1;requirement='Labelled retained requirement';
      founderExcerpt='approved compact current layout for this specific case';currentChange='Labelled compact current layout';
      reason='Labelled primary review of exact case-specific applicability';limitations='No real founder approval or APK evidence';slotIds=@('H01-visual-1')}
    $authority=[pscustomobject]@{path=$sourcePath;sha256=$authorityHash;decision=''}
    switch($presentationProbeCase) {
      'unlisted-path' {$authority.path=[IO.Path]::GetFullPath((Join-Path $taskBase 'outputs/not-in-manifest.md'))}
      'candidate-hash' {$authority.sha256='F'*64}
      'absent-excerpt' {$decision.founderExcerpt='Not present in the retained source'}
      'wrong-case' {$decision.ordinal=2}
      'wrong-clause' {$decision.clause=2}
      'wrong-requirement' {$decision.requirement='Other retained requirement'}
      'unknown-slot' {$decision.slotIds=@('H01-visual-99')}
      'duplicate-slot' {$decision.slotIds=@('H01-visual-1','H01-visual-1')}
      'other-case-known-slot' {$decision.slotIds=@('H02-visual-1')}
      'empty-change' {$decision.currentChange=' '}
      'source39' {$authority.path=[IO.Path]::GetFullPath((Join-Path $taskBase $actualManifest.sources[39]));$authority.sha256='A'*64}
      'source40' {$authority.path=$source40Path;$authority.sha256=$source40Hash;
        $decision.founderExcerpt='This approves the previously requested exact Source17-bound preparation'}
      'source41' {$authority.path=$source41Path;$authority.sha256=$source41Hash;
        $decision.founderExcerpt='Public Store preview'}
    }
    $authority.decision=$decision|ConvertTo-Json -Depth 10 -Compress
    $obligations=@([pscustomobject]@{ordinal=1;clauses=@([pscustomobject]@{index=1;parts=@([pscustomobject]@{
      requirement=$decision.requirement;disposition='superseded_presentation';presentationAuthority=$authority})})})
    if($presentationProbeCase -ceq 'wrong-requirement'){$obligations[0].clauses[0].parts[0].requirement='Labelled retained requirement'}
    $reviewEnvelope=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(
      (ConvertTo-Json -InputObject ([pscustomobject]@{sourceReviews=$obligations}) -Depth 100 -Compress)))
    $primary=@{PrimaryReviewRecordBound=$true;Report=[pscustomobject]@{sourceIdentity=[pscustomobject]$identity.Clone();
      sourceReviews=$reviewEnvelope.sourceReviews}}
    $assertions=@{PrimaryAssertionReviewBound=$true}
    if($presentationProbeCase -ceq 'missing-primary'){$primary=$null}
    if($presentationProbeCase -ceq 'untyped-assertions'){$assertions.PrimaryAssertionReviewBound='true'}
    if($presentationProbeCase -ceq 'primary-source'){$primary.Report.sourceIdentity.producerBlob='f'*40}
    if($presentationProbeCase -ceq 'authentic-unreviewed-change'){
      $decision.currentChange='Different change not approved for this case';$authority.decision=$decision|ConvertTo-Json -Depth 10 -Compress
    }
    $result=Read-OctoberCompatibilityCurrentPresentationReview -Obligations $obligations -SourceIdentity $identity `
      -PrimaryAssertionReview $assertions -PrimaryBinding $primary
    foreach($lease in $opened){if($lease.Stream.CanRead){throw 'Presentation probe lease was not closed.'}}
    if(($null -ne $result) -ne ($presentationProbeCase -ceq 'valid')){throw ('Presentation review mismatch: '+$presentationProbeCase)}
    if($presentationProbeCase -ceq 'valid' -and ($result.Decisions.Count -ne 1 -or $result.OriginalTaskFileHashes.Count -ne 3 -or
      -not $result.SpecificPresentationReviewBound -or $result.MachineAuthorityMeaningVerified -or $result.FounderApprovedImages -or
      $result.QualificationPassed -or $result.ApkAuthority)){throw 'Presentation review overclaimed authority.'}
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityCurrentVisualSlotAccountingProbes {
  # Labelled historical/native/review fixtures, not actual 65-slot acceptance.
  # Legacy Source17 contract only; current Source19 is independently exercised
  # by the actual pinned joins/65-slot full dependency conjunction.
  function Read-OctoberCompatibilitySource19ForwardAmendment {
    param([string]$Commit,[switch]$FromIndex,[switch]$FromWorkingTree)
    if($Commit -cne ('b'*40) -or $FromIndex -or $FromWorkingTree){throw 'Unexpected legacy slot fixture contract selection.'}
    return $null
  }
  $identity=@{runtimeSourceCommit=('a'*40);contractCommit=('b'*40);captureSourceCommit=('c'*40);
    captureSourceTree=('d'*40);producerBlob=('e'*40);executionHead=('c'*40)}
  $count=0
  foreach($case in @('valid','missing-row','duplicate-row','literal-drift','wrong-risk','representative-relabel',
    'missing-visual','untyped-assertions','source-drift','empty-reason','state-drift','geometry-drift',
    'anchor-assertion','anchor-ordinal','anchor-slot','anchor-test','provider-anchor','orphan-risk','historical-approval',
    'same-case-review-association','valid-superseded-shared','valid-superseded-representative',
    'missing-specific-presentation','wrong-supersession-slot','supersession-equivalence-label',
    'missing-reviewed-anchor-pair','duplicated-reviewed-anchor-pair','representative-missing-presentation',
    'anchor-supersession-wrong-slot','representative-supersession-without-pair')) {
    $slots=@(1..65|ForEach-Object {[pscustomobject]@{profile='workspace_capture';slot=('H{0:D2}-visual-1' -f $_);
      reference=('historical-'+$_+'.png');referenceRole='historical_not_current_oracle';
      newEvidenceRule='case_specific_visual_risk_or_verified_shared_current_surface';equivalenceProven=$false}})
    function Read-OctoberCompatibilityCurrentQualificationContract {param($Commit) return [pscustomobject]@{visualSlots=$slots}}
    $sourceReviews=@(1..65|ForEach-Object {[pscustomobject]@{ordinal=$_;clauses=@([pscustomobject]@{index=1;parts=@([pscustomobject]@{
      requirement='Labelled retained requirement';disposition='asserted';successfulTests=@([pscustomobject]@{reportId='store_layout_and_recovery';executionId='default';testKey=('test:'+$_)});
      assertionEvidence=@([pscustomobject]@{owner='apps/mobile/test/labelled.dart';sourceBlob=('f'*40);firstLine=$_;lastLine=$_;
        excerptSha256=('A'*64);reviewObservation=('Labelled primary assertion '+$_)})})})}})
    $risk=[pscustomobject]@{id='labelled-risk';slotIds=@($slots|ForEach-Object {$_.slot});representative=[pscustomobject]@{
      slotId=$slots[0].slot;profile='workspace_capture'};currentSurface='labelled-surface';target='labelled-target';
      state='labelled-state';geometry=[pscustomobject]@{width=4};equivalenceEvidence=@()}
    $risk.equivalenceEvidence=@(2..65|ForEach-Object {
      $slotIndex=$_-1
      [pscustomobject]@{slotId=$slots[$slotIndex].slot;disposition='equivalent';presentationKey=$null;currentSurface=$risk.currentSurface;target=$risk.target;state=$risk.state;
        geometry=$risk.geometry;reason=('Labelled reviewed equivalence for '+$slots[$slotIndex].slot);sourceAssertions=@(
          [pscustomobject]@{role='slot';slotId=$slots[$slotIndex].slot;slotMeaning=('Labelled slot meaning '+$_);ordinal=$_;
            successfulTest=$sourceReviews[$slotIndex].clauses[0].parts[0].successfulTests[0];
            assertionEvidence=$sourceReviews[$slotIndex].clauses[0].parts[0].assertionEvidence[0]},
          [pscustomobject]@{role='representative';slotId=$slots[0].slot;slotMeaning='Labelled representative meaning';ordinal=1;
            successfulTest=$sourceReviews[0].clauses[0].parts[0].successfulTests[0];
            assertionEvidence=$sourceReviews[0].clauses[0].parts[0].assertionEvidence[0]})}
    })
    $inventory=@($risk)
    $rows=@($slots|ForEach-Object {[pscustomobject]@{profile=$_.profile;slot=$_.slot;reference=$_.reference;
      referenceRole=$_.referenceRole;newEvidenceRule=$_.newEvidenceRule;equivalenceProven=$_.equivalenceProven;
      riskId=$risk.id;captureRole=$(if($_.slot -ceq $risk.representative.slotId){'representative'}else{'shared'});
      presentationKey=$null;disposition=$(if($_.slot -ceq $risk.representative.slotId){'representative'}else{'equivalent'})}})
    $primary=@{PrimaryReviewRecordBound=$true;Report=[pscustomobject]@{sourceIdentity=[pscustomobject]$identity.Clone();sourceReviews=$sourceReviews}}
    $reviewedRisk=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($risk|ConvertTo-Json -Depth 100 -Compress)))
    $visual=@{PrimaryVisualReviewBound=$true;Reviews=@{$risk.id=@{inventoryEntry=$reviewedRisk}}}
    $pairs=@($sourceReviews|ForEach-Object {[pscustomobject]@{Ordinal=$_.ordinal;Clause=1;Requirement=$_.clauses[0].parts[0].requirement;
      Disposition='asserted';SuccessfulTest=$_.clauses[0].parts[0].successfulTests[0];AssertionEvidence=$_.clauses[0].parts[0].assertionEvidence[0]}})
    $assertions=@{PrimaryAssertionReviewBound=$true;ReviewedAssertionPairs=$pairs}
    $presentation=@{SpecificPresentationReviewBound=$true;Decisions=@{}}
    $evidence=$risk.equivalenceEvidence[0]
    if($case -in @('valid-superseded-shared','missing-specific-presentation','wrong-supersession-slot',
      'supersession-equivalence-label','anchor-supersession-wrong-slot')) {
      $key='H2:1:Labelled retained requirement'
      $sourceReviews[1].clauses[0].parts[0].disposition='superseded_presentation';$pairs[1].Disposition='superseded_presentation'
      $evidence.disposition='superseded_presentation';$evidence.presentationKey=$key
      $rows[1].disposition='superseded_presentation';$rows[1].presentationKey=$key
      $path=[IO.Path]::GetFullPath('C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/labelled-only.md')
      $presentation.Decisions[$key]=@{Decision=[pscustomobject]@{ordinal=2;clause=1;requirement='Labelled retained requirement';slotIds=@($slots[1].slot)};
        SourcePath=$path;Authority=[pscustomobject]@{path=$path}}
    }
    if($case -in @('valid-superseded-representative','representative-missing-presentation','representative-supersession-without-pair')) {
      $key='H1:1:Labelled retained requirement'
      $sourceReviews[0].clauses[0].parts[0].disposition='superseded_presentation';$pairs[0].Disposition='superseded_presentation'
      $rows[0].disposition='superseded_presentation';$rows[0].presentationKey=$key
      $path=[IO.Path]::GetFullPath('C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/labelled-only.md')
      $presentation.Decisions[$key]=@{Decision=[pscustomobject]@{ordinal=1;clause=1;requirement='Labelled retained requirement';slotIds=@($slots[0].slot)};
        SourcePath=$path;Authority=[pscustomobject]@{path=$path}}
    }
    switch($case) {
      'missing-row' {$rows=$rows[0..63]}
      'duplicate-row' {$rows[64]=$rows[63]}
      'literal-drift' {$rows[1].reference='other.png'}
      'wrong-risk' {$rows[1].riskId='other'}
      'representative-relabel' {$rows[0].disposition='equivalent'}
      'missing-visual' {$visual=$null}
      'untyped-assertions' {$assertions.PrimaryAssertionReviewBound='true'}
      'source-drift' {$primary.Report.sourceIdentity.producerBlob=('a'*40)}
      'empty-reason' {$evidence.reason=' '}
      'state-drift' {$evidence.state='other'}
      'geometry-drift' {$evidence.geometry=[pscustomobject]@{width=5}}
      'anchor-assertion' {$evidence.sourceAssertions[0].assertionEvidence=$sourceReviews[2].clauses[0].parts[0].assertionEvidence[0]}
      'anchor-ordinal' {$evidence.sourceAssertions[0].ordinal=3}
      'anchor-slot' {$evidence.sourceAssertions[0].slotId=$slots[2].slot}
      'anchor-test' {$evidence.sourceAssertions[0].successfulTest=$sourceReviews[2].clauses[0].parts[0].successfulTests[0]}
      'provider-anchor' {$sourceReviews[1].clauses[0].parts[0].disposition='provider_unmet'}
      'orphan-risk' {$visual.Reviews['other']=@{inventoryEntry=$risk}}
      'historical-approval' {$rows[0].equivalenceProven=$true}
      'missing-specific-presentation' {$presentation=$null}
      'wrong-supersession-slot' {$presentation.Decisions['H2:1:Labelled retained requirement'].Decision.slotIds=@($slots[2].slot)}
      'supersession-equivalence-label' {$rows[1].disposition='equivalent'}
      'missing-reviewed-anchor-pair' {$assertions.ReviewedAssertionPairs=@($pairs|Where-Object {$_.Ordinal -ne 2})}
      'duplicated-reviewed-anchor-pair' {$assertions.ReviewedAssertionPairs+=@($pairs[1])}
      'representative-missing-presentation' {$presentation.Decisions=@{}}
      'anchor-supersession-wrong-slot' {$evidence.sourceAssertions[0].slotId=$slots[2].slot}
      'representative-supersession-without-pair' {$pairs[0].Disposition='asserted';$sourceReviews[0].clauses[0].parts[0].disposition='asserted'}
      'same-case-review-association' {
        # Both assertions and their test are valid in the same case. Only the
        # first was independently reviewed for this slot's equivalence anchor.
        $otherAssertion=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(
          ($sourceReviews[1].clauses[0].parts[0].assertionEvidence[0]|ConvertTo-Json -Depth 100 -Compress)))
        $otherAssertion.reviewObservation='Another valid assertion in the same historical case'
        $sourceReviews[1].clauses+=@([pscustomobject]@{parts=@([pscustomobject]@{disposition='asserted';
          successfulTests=@($sourceReviews[1].clauses[0].parts[0].successfulTests[0]);assertionEvidence=@($otherAssertion)})})
        $evidence.sourceAssertions[0].assertionEvidence=$otherAssertion
      }
    }
    if($null -ne $visual -and $case -cne 'same-case-review-association') {
      # Other controls intentionally keep the review aligned with the changed
      # input so they exercise the semantic/accounting checks, not only equality.
      $visual.Reviews[$risk.id].inventoryEntry=Read-OctoberCompatibilityJsonObject (
        [Text.Encoding]::UTF8.GetBytes(($risk|ConvertTo-Json -Depth 100 -Compress)))
    }
    $result=Read-OctoberCompatibilityCurrentVisualSlotAccounting -Reconciliation $rows -Inventory $inventory -SourceIdentity $identity `
      -PrimaryVisualReview $visual -PrimaryAssertionReview $assertions -PrimaryBinding $primary -PresentationReview $presentation
    $positive=$case -in @('valid','valid-superseded-shared','valid-superseded-representative')
    if(($null -ne $result) -ne $positive){throw ('Visual slot accounting mismatch: '+$case)}
    if($positive -and ($result.Slots.Count -ne 65 -or -not $result.HistoricalSlotsAccounted -or -not $result.CurrentVisualDispositionReviewBound -or
      -not $result.PrimaryEquivalenceReviewBound -or $result.MachineEquivalenceVerified -or
      $result.PresentationAuthorityVerified -or $result.QualificationPassed -or $result.ApkAuthority)){throw 'Slot accounting overclaimed authority.'}
    if($case -ceq 'valid-superseded-shared' -and $result.Slots[$slots[1].slot].Disposition -cne 'superseded_presentation'){throw 'Shared supersession mislabeled equivalence.'}
    if($case -ceq 'valid-superseded-representative' -and $result.Slots[$slots[0].slot].Disposition -cne 'superseded_presentation'){throw 'Representative supersession lost.'}
    if($case -in @('valid-superseded-shared','valid-superseded-representative','wrong-supersession-slot')) {
      # Reuse this exact actual slot-reader fixture inside the complete consumer.
      # Other leaves stay labelled; success is not actual source/render acceptance.
      $risk.representative|Add-Member -NotePropertyName executionId -NotePropertyValue workspace_capture
      $visual.Reviews[$risk.id].inventoryEntry=Read-OctoberCompatibilityJsonObject ([Text.Encoding]::UTF8.GetBytes(($risk|ConvertTo-Json -Depth 100 -Compress)))
      $composed=Invoke-OctoberCompatibilityCurrentQualifiedEvidenceProbes -SlotFixture @{
        Rows=$rows;Inventory=$inventory;Primary=$primary;Assertions=$assertions;Visual=$visual;Presentation=$presentation;ExpectedSuccess=$positive}
      if($composed -ne 1){throw 'Actual slot composition control missing.'}
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityCurrentPrimaryAssertionReviewProbes {
  # Labelled upstream admission/native/Git mocks; actual source excerpt hashing
  # and primary-record/structured-review joins. Not actual Source17 qualification.
  $identity=@{runtimeSourceCommit='3c3f38136db8bb184866635203d04ea4643f1eac';contractCommit=('a'*40);
    captureSourceCommit=('b'*40);captureSourceTree=('c'*40);producerBlob=('d'*40);executionHead=('b'*40)}
  $sourceLines=@("test('case', () {",'  expect(1, 1);','  // Labelled static test body','});','expect(2, 2);')
  $owner='apps/mobile/test/work_workspace_layout_safety_test.dart';$blob=('e'*40)
  $helperOwner='apps/mobile/test/review_helper.dart';$helperBlob=('f'*40)
  $helperLines=@('void helperCheck() {','  expect(1, 1);','}','void otherCheck() {','  expect(2, 2);','}')
  $sourcePath=[IO.Path]::GetFullPath((Join-Path (Get-OctoberCompatibilityBinding).worktreePath $owner))
  function Read-OctoberCompatibilityCurrentObligationJoins {
    param($Obligations,$SourceIdentity,$CycleEvidence)
    if($case -ceq 'upstream-rejected'){return $null}
    return @{RetentionAndSuccessJoinsVerified=$true;AssertionSemanticsVerified=$false;QualificationPassed=$false}
  }
  function Get-OctoberCompatibilityGitLines {
    param([string[]]$Arguments)
    $gitReads.Add(($Arguments -join '|'))
    if(($Arguments -join '|') -ceq ('rev-parse|'+$identity.captureSourceCommit+':'+$owner)) {
      if($case -ceq 'blob-drift'){return ('f'*40)}
      return $blob
    }
    if(($Arguments -join '|') -ceq ('show|'+$identity.captureSourceCommit+':'+$owner)){return $sourceLines}
    if(($Arguments -join '|') -ceq ('rev-parse|'+$identity.captureSourceCommit+':'+$helperOwner)){return $helperBlob}
    if(($Arguments -join '|') -ceq ('show|'+$identity.captureSourceCommit+':'+$helperOwner)){return $helperLines}
    throw 'Unexpected assertion source read.'
  }
  $count=0
  foreach($case in @('valid','upstream-rejected','missing-primary','untyped-primary','primary-source','review-difference',
    'duplicate-row','blob-drift','excerpt-drift','range-outside','review-unstructured','wrong-test',
    'body-outside','assertion-expression','native-line','native-column','native-path','missing-native','review-empty-meaning',
    'valid-loop','reviewed-loop-mismatch','assertion-outside-body','helper-valid','helper-blob','helper-excerpt',
    'helper-call','helper-call-outside','helper-expression','helper-function','helper-wrong-function-assertion')) {
    $gitReads=[Collections.Generic.List[string]]::new()
    $sourceLines=@("test('case', () {",'  expect(1, 1);','  // Labelled static test body','});','expect(2, 2);')
    if($case.StartsWith('helper-',[StringComparison]::Ordinal)){$sourceLines[1]='  helperCheck();'}
    $review=[ordered]@{schemaVersion=1;testKey='work_workspace_layout_safety_test.dart:case';declarationLine=1;declarationColumn=1;
      bodyFirstLine=1;bodyLastLine=4;loopBindings=@();helperEvidence=@();assertions=@([pscustomobject]@{firstLine=2;lastLine=2;expression=$sourceLines[1]});
      meaning='Labelled primary review: this static equality assertion is associated with this case only.';limitations='No live behavior or render qualification.'}
    switch($case) {
      'wrong-test' {$review.testKey='work_workspace_layout_safety_test.dart:other'}
      'body-outside' {$review.bodyLastLine=99}
      'assertion-expression' {$review.assertions[0].expression='expect(2, 2);'}
      'review-empty-meaning' {$review.meaning=' '}
      'assertion-outside-body' {$review.assertions=@([pscustomobject]@{firstLine=5;lastLine=5;expression=$sourceLines[4]})}
    }
    if($case -in @('valid-loop','reviewed-loop-mismatch')){$review.loopBindings=@([pscustomobject]@{expression='case';value='choose'})}
    if($case.StartsWith('helper-',[StringComparison]::Ordinal)) {
      $helper=[pscustomobject]@{owner=$helperOwner;sourceBlob=$helperBlob;firstLine=1;lastLine=3;
        excerptSha256=(Get-OctoberCompatibilityByteHash ([Text.Encoding]::UTF8.GetBytes(($helperLines[0..2] -join "`n"))));
        functionName='helperCheck';callFirstLine=2;callLastLine=2;callExpression=$sourceLines[1];
        assertions=@([pscustomobject]@{firstLine=2;lastLine=2;expression=$helperLines[1]})}
      switch($case) {
        'helper-blob' {$helper.sourceBlob=('a'*40)}
        'helper-excerpt' {$helper.excerptSha256=('A'*64)}
        'helper-call' {$helper.callExpression='  otherCheck();'}
        'helper-call-outside' {$helper.callFirstLine=5;$helper.callLastLine=5}
        'helper-expression' {$helper.assertions[0].expression='  expect(2, 2);'}
        'helper-function' {$helper.functionName='otherCheck'}
        'helper-wrong-function-assertion' {$helper.assertions=@([pscustomobject]@{firstLine=5;lastLine=5;expression=$helperLines[4]})}
      }
      $review.helperEvidence=@($helper)
    }
    $obligations=@(1..84|ForEach-Object {
      [pscustomobject]@{ordinal=$_;historicalKey=('H'+$_);clauses=@([pscustomobject]@{index=1;text='Labelled retained clause';parts=@(
        [pscustomobject]@{requirement='Labelled retained clause';disposition='asserted';dependency=$null;presentationAuthority=$null;
          successfulTests=@([pscustomobject]@{reportId='store_layout_and_recovery';executionId='default';testKey='work_workspace_layout_safety_test.dart:case'});
          assertionEvidence=@([pscustomobject]@{owner=$owner;sourceBlob=$blob;firstLine=1;lastLine=4;
            excerptSha256=(Get-OctoberCompatibilityByteHash ([Text.Encoding]::UTF8.GetBytes(($sourceLines[0..3] -join "`n"))));
            reviewObservation=($review|ConvertTo-Json -Depth 20 -Compress)})})})}
    })
    switch($case) {
      'excerpt-drift' {$obligations[0].clauses[0].parts[0].assertionEvidence[0].excerptSha256=('F'*64)}
      'range-outside' {$obligations[0].clauses[0].parts[0].assertionEvidence[0].lastLine=6}
      'review-unstructured' {$obligations[0].clauses[0].parts[0].assertionEvidence[0].reviewObservation='Unstructured prose alone is not source association.'}
      'duplicate-row' {$obligations[1]=$obligations[0]}
    }
    $primaryRows=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $obligations -Depth 50 -Compress);$primaryRows=@($primaryRows)
    if($case -ceq 'review-difference'){$primaryRows[0].clauses[0].text='Different independently reviewed clause'}
    if($case -ceq 'reviewed-loop-mismatch') {
      $different=ConvertFrom-Json -InputObject $obligations[0].clauses[0].parts[0].assertionEvidence[0].reviewObservation
      $different.loopBindings[0].value='requirements'
      $obligations[0].clauses[0].parts[0].assertionEvidence[0].reviewObservation=$different|ConvertTo-Json -Depth 20 -Compress
    }
    $primary=@{PrimaryReviewRecordBound=$true;Report=[pscustomobject]@{sourceIdentity=[pscustomobject]$identity.Clone();sourceReviews=$primaryRows}}
    if($case -ceq 'missing-primary'){$primary=$null}
    if($case -ceq 'untyped-primary'){$primary.PrimaryReviewRecordBound='true'}
    if($case -ceq 'primary-source'){$primary.Report.sourceIdentity.executionHead=('f'*40)}
    $location=[pscustomobject]@{DeclarationLocationReferenceVerified=$true;SelectedPath=$sourcePath;SelectedTuple='';Direct=[pscustomobject]@{Complete=$true;Line=1;Column=1};Root=$null}
    switch($case) {
      'native-line' {$location.Direct.Line=2}
      'native-column' {$location.Direct.Column=2}
      'native-path' {$location.SelectedPath=[IO.Path]::GetFullPath('C:/not-the-reviewed-test.dart')}
    }
    $native=@{Name='case';DeclarationLocation=$location}
    $cycles=@{CyclesVerified=$true;QualificationPassed=$false;Executions=@{}}
    foreach($id in @('cycle1','cycle2')) {
      $tests=@{'1'=$native};if($case -ceq 'missing-native' -and $id -ceq 'cycle2'){$tests=@{}}
      $cycles.Executions[$id+':store_layout_and_recovery:default']=@{TestIdentities=$tests}
    }
    $result=Read-OctoberCompatibilityCurrentPrimaryAssertionReview -Obligations $obligations -SourceIdentity $identity -CycleEvidence $cycles -PrimaryBinding $primary
    $positive=$case -in @('valid','valid-loop','helper-valid')
    if(($null -ne $result) -ne $positive){throw ('Primary assertion review mismatch: '+$case)}
    $ownerCount=if($case -ceq 'helper-valid'){2}else{1}
    if($positive -and (-not $result.PrimaryAssertionReviewBound -or $result.SourceOwners.Count -ne $ownerCount -or
      $result.ReviewedAssertionPairs.Count -ne 84 -or
      $gitReads.Count -ne (2*$ownerCount) -or $result.MachineSemanticsVerified -or $result.QualificationPassed -or $result.ApkAuthority)){throw 'Primary assertion review positive overclaimed or reread source.'}
    $count++
  }
  [pscustomobject]@{PrimaryAssertionReviewCases=$count;LabelledUpstreamAndGitMocks=$true;ActualPrimaryReview=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
}

function Invoke-OctoberCompatibilityCurrentPrimaryReviewBindingProbes {
  # Actual JSON/byte hashes; labelled leased-file and final-hash mocks only.
  $taskRoot='C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store'
  $authorityRelative='outputs/founder-current-baseline-qualification-direction-20261010.json'
  $authorityBytes=[IO.File]::ReadAllBytes((Join-Path $taskRoot $authorityRelative))
  $authorityHash='F76F211F42CE11D4842532E7BBE5FAF54C94DAF14150CC1522E93393D97D06BD'
  if((Get-OctoberCompatibilityByteHash $authorityBytes) -cne $authorityHash){throw 'Primary review authority fixture drift.'}
  $identity=@{runtimeSourceCommit='3c3f38136db8bb184866635203d04ea4643f1eac';contractCommit=('a'*40);
    captureSourceCommit=('b'*40);captureSourceTree=('c'*40);producerBlob=('d'*40);executionHead=('b'*40)}
  $ledgerRelative='outputs/codex-integration-readiness-20261008.md'
  $reportRelative='outputs/compatibility-primary-review-'+$identity.captureSourceCommit+'-r1.json'
  $sealRelative='outputs/compatibility-primary-review-'+$identity.captureSourceCommit+'-r1.seal.json'
  function Get-OctoberCoverageBoundHash {
    param($Path)
    if(-not $files.ContainsKey($Path)){return $null}
    if(-not $reads.ContainsKey($Path)){$reads[$Path]=0};$reads[$Path]++
    if($case -ceq 'late-ledger' -and $Path -ceq $ledgerPath -and $reads[$Path] -gt 1){return ('F'*64)}
    if($case -ceq 'late-report' -and $Path -ceq $reportPath -and $reads[$Path] -gt 1){return ('F'*64)}
    return Get-OctoberCompatibilityByteHash $files[$Path]
  }
  function Open-OctoberCompatibilityVisualArtifact {
    param($Base,$RelativePath,$ExpectedSha256,$MaxBytes)
    if($Base -cne $taskRoot){throw 'Primary reader widened root.'}
    $path=[IO.Path]::GetFullPath((Join-Path $Base $RelativePath))
    if(-not $files.ContainsKey($path)){return $null}
    $bytes=$files[$path];$hash=Get-OctoberCompatibilityByteHash $bytes
    if($hash -cne $ExpectedSha256 -or $bytes.Length -gt $MaxBytes){return $null}
    $stream=[IO.MemoryStream]::new($bytes,$false);$primaryProbeLeases.Add($stream)
    return @{CanonicalPath=$path;Bytes=$bytes;Sha256=$hash;Stream=$stream;FileIdentity=('00000000:'+$primaryProbeLeases.Count.ToString('X16'))}
  }
  $count=0
  foreach($case in @('valid','missing-binding','duplicate-binding','wrong-source','wrong-authority',
    'report-path-injection','report-digest','seal-digest','report-writer','report-extra-field',
    'report-source','report-approved','report-short-clauses','report-empty-visuals','seal-source',
    'late-ledger','late-report','missing-report','missing-seal')) {
    $files=@{};$reads=@{};$primaryProbeLeases=[Collections.Generic.List[object]]::new()
    $report=[ordered]@{schemaVersion=1;sourceIdentity=[pscustomobject]$identity.Clone();revision=1;authoritySha256=$authorityHash;
      writerRole='primary';writerTask='/root';trustModel='procedural-primary-attestation';
      sourceReviews=@(1..84|ForEach-Object {[pscustomobject]@{ordinal=$_;review='Labelled shape fixture; no semantic qualification'}});
      visualReviews=@([pscustomobject]@{riskId='labelled-risk';review='Labelled shape fixture; not an actual inspected image'});
      founderApproved=$false;providerVerified=$false;apkAuthority=$false}
    switch($case) {
      'report-writer' {$report.writerRole='subagent'}
      'report-extra-field' {$report.extra='candidate'}
      'report-source' {$report.sourceIdentity.executionHead=('f'*40)}
      'report-approved' {$report.founderApproved=$true}
      'report-short-clauses' {$report.sourceReviews=@($report.sourceReviews[0])}
      'report-empty-visuals' {$report.visualReviews=@()}
    }
    $reportBytes=[Text.Encoding]::UTF8.GetBytes(($report|ConvertTo-Json -Depth 20 -Compress))
    $reportHash=Get-OctoberCompatibilityByteHash $reportBytes
    $seal=[ordered]@{schemaVersion=1;sourceIdentity=[pscustomobject]$identity.Clone();revision=1;authoritySha256=$authorityHash;
      reportSha256=$reportHash;writerRole='primary';writerTask='/root'}
    if($case -ceq 'seal-source'){$seal.sourceIdentity.captureSourceTree=('f'*40)}
    $sealBytes=[Text.Encoding]::UTF8.GetBytes(($seal|ConvertTo-Json -Depth 20 -Compress))
    $binding=[ordered]@{schemaVersion=1;sourceIdentity=[pscustomobject]$identity.Clone();revision=1;
      authoritySha256=$authorityHash;reportSha256=$reportHash;sealSha256=(Get-OctoberCompatibilityByteHash $sealBytes)}
    switch($case) {
      'wrong-source' {$binding.sourceIdentity.producerBlob=('f'*40)}
      'wrong-authority' {$binding.authoritySha256=('F'*64)}
      'report-path-injection' {$binding.reportPath='candidate-selected.json'}
      'report-digest' {$binding.reportSha256=('F'*64)}
      'seal-digest' {$binding.sealSha256=('F'*64)}
    }
    $block='<!-- COMPATIBILITY_PRIMARY_TECHNICAL_REVIEW_BINDING_JSON_BEGIN -->'+($binding|ConvertTo-Json -Depth 20 -Compress)+
      '<!-- COMPATIBILITY_PRIMARY_TECHNICAL_REVIEW_BINDING_JSON_END -->'
    $ledger=if($case -ceq 'missing-binding'){'Labelled ledger without binding'}elseif($case -ceq 'duplicate-binding'){$block+$block}else{$block}
    $ledgerPath=[IO.Path]::GetFullPath((Join-Path $taskRoot $ledgerRelative))
    $reportPath=[IO.Path]::GetFullPath((Join-Path $taskRoot $reportRelative))
    $sealPath=[IO.Path]::GetFullPath((Join-Path $taskRoot $sealRelative))
    $files[$ledgerPath]=[Text.Encoding]::UTF8.GetBytes($ledger);$files[$reportPath]=$reportBytes;$files[$sealPath]=$sealBytes
    $files[[IO.Path]::GetFullPath((Join-Path $taskRoot $authorityRelative))]=$authorityBytes
    if($case -ceq 'missing-report'){$files.Remove($reportPath)}
    if($case -ceq 'missing-seal'){$files.Remove($sealPath)}
    $result=@(Read-OctoberCompatibilityCurrentPrimaryReviewBinding -SourceIdentity $identity)
    $expected=$case -ceq 'valid'
    if(($result.Count -eq 1 -and $null -ne $result[0]) -ne $expected){throw ('Primary review binding result mismatch: '+$case)}
    if($expected -and (-not $result[0].PrimaryReviewRecordBound -or $result[0].OriginalTaskFileHashes.Count -ne 4 -or
      $result[0].SemanticsVerified -or $result[0].InspectionVerified -or $result[0].QualificationPassed -or $result[0].ApkAuthority)) {
      throw 'Primary review binding overclaimed authority.'
    }
    foreach($stream in $primaryProbeLeases){if($stream.CanRead){throw 'Primary reader leaked lease.'}}
    if($case -ceq 'late-ledger' -and $reads[$ledgerPath] -ne 2){throw 'Late ledger control not reached.'}
    if($case -ceq 'late-report' -and $reads[$reportPath] -ne 2){throw 'Late report control not reached.'}
    $count++
  }
  if($count -ne 19){throw 'Primary review probe count changed.'}
  [pscustomobject]@{PrimaryReviewBindingCases=$count;LabelledFileMocks=$true;ActualPrimaryReview=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
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

function Invoke-OctoberCompatibilityForwardHistoryProbes {
  # Actual history/qualification-source predicates with labelled future Git
  # objects. Existing sealed objects are read from Git; no commit is created.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage '737eea29357d5f42375b865754f3762f10545e37'
  Assert-RepairContract ($prefixHistory.Stage -eq 18 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source17Preparation -and -not $prefixHistory.Forward) 'Source17 must select its exact metadata preparation, not capture/Q.'
  $prefix=@($prefixHistory.Commits);$metadata=('a'*40);$source=('b'*40);$qualified=('c'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource17ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('metadata','source','qualified','metadata-parent','metadata-owner','metadata-apps',
      'source-owner','source-runtime','qualified-apps','missing-delta','duplicate-delta','changed-original','forged-roles')) {
    & {
      $tip=if($case -cin @('source','source-owner','source-runtime')){$source}elseif($case -cin @('qualified','qualified-apps')){$qualified}else{$metadata}
      $graph=@($prefix)+@($metadata);if($tip -cin @($source,$qualified)){$graph+=@($source)};if($tip -ceq $qualified){$graph+=@($qualified)}
      $observations=@{Ancestry=0;QualificationSourceReads=0;Unexpected=$false}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 18..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-18]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($index -eq 18 -and $case -ceq 'metadata-parent'){return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)){return [string]$entry.subject}
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 18 -and $case -ceq 'metadata-owner') -or ($index -eq 19 -and $case -ceq 'source-owner')){
              return @($entry.owners)+@('apps/mobile/lib/unowned.dart')
            }
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            switch($case) {
              'missing-delta' {return $document.Substring(0,$document.IndexOf('<!-- COMPATIBILITY_SOURCE17_FORWARD_AMENDMENT_JSON_BEGIN -->'))}
              'duplicate-delta' {return $document+"`n"+$document}
              'changed-original' {return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
              'forged-roles' {return $document.Replace('"captureSourceIndex":19','"captureSourceIndex":17')}
              default {return $document}
            }
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 18 -and $case -ceq 'metadata-apps') -or ($index -eq 20 -and $case -ceq 'qualified-apps')){
              return @(('e'*40),('d'*40))
            }
            $apps=if($index -eq 18){'d5186fff2aba142f75de4ca3e4b053261880cab7'}else{('d'*40)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($index -eq 19 -and $case -ceq 'source-runtime'){return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        # Cache only immutable sealed-object reads, not status, refs or paths.
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$rejection=''
      try {$result=Get-OctoberCompatibilityHistoryStage $tip;$accepted=$true}catch{$rejection=$_.Exception.Message}
      $expected=$case -cin @('metadata','source','qualified')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1) ('forward immutable graph mismatch: '+$case+'; '+$rejection)
      if($expected) {
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq ($graph.Count-2) -and
          $result.Forward -and -not $result.Source17Preparation -and $result.ContractIndex -eq 18 -and
          $result.CaptureIndex -eq 19) ('forward roles were inferred from old stage count: '+$case)
      }
      if($case -ceq 'metadata') {
        # A caller's old-Q role fields cannot change independently recollected
        # forward count19 into qualified count21 or start source-proof reads.
        $forged=$result.Clone();$forged.PhaseStage=19;$forged.ContractIndex=16;$forged.CaptureIndex=17
        function Read-OctoberCompatibilityCurrentSourceState {
          $observations.QualificationSourceReads++;throw 'Premature source proof read.'
        }
        foreach($selection in @('working','index','committed')) {
          $q=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree:($selection -ceq 'working') -FromIndex:($selection -ceq 'index')
          Assert-RepairContract ($null -eq $q -and $observations.QualificationSourceReads -eq 0) 'old stage19 or forged source roles qualified forward metadata.'
        }
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource19FullDependencyProbes {
  $ExpectedCheckerSha256=(Get-FileHash -LiteralPath $checkerPath).Hash
  Set-StrictMode -Version Latest
  $ErrorActionPreference='Stop'
  $checker='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-REPAIR-store-buy-compatibility-20261008/scripts/check-codex-subagent-coordination-policy.ps1'
  $root=Split-Path (Split-Path $checker)
  if((Get-FileHash -LiteralPath $checker).Hash -cne $ExpectedCheckerSha256){throw 'Unreviewed checker identity'}
  $tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($checker,[ref]$tokens,[ref]$errors)
  if($errors.Count){throw 'Checker parse failure'}
  foreach($name in @('Read-OctoberCompatibilityJsonObject','Get-OctoberCompatibilityByteHash','Get-OctoberCompatibilityGitLines',
    'Read-OctoberCompatibilityCurrentQualificationContract','Read-OctoberCompatibilityCurrentSuccessorSpecification',
    'Read-OctoberCompatibilitySource17ForwardAmendment','Read-OctoberCompatibilitySource19ForwardAmendment',
    'Read-OctoberCompatibilityCurrentObligationJoins','Read-OctoberCompatibilityCurrentVisualSlotAccounting')) {
    $nodes=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'Function inventory differs'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
  }
  # Real pinned contract readers precede any isolated upstream mocking. The future
  # commit identity, cycle successes and review bindings below are unit fixtures,
  # never native evidence, source semantics, approved renders or runtime records.
  $contract=Read-OctoberCompatibilityCurrentQualificationContract -FromWorkingTree
  $spec=Read-OctoberCompatibilityCurrentSuccessorSpecification -FromWorkingTree
  $forward=Read-OctoberCompatibilitySource19ForwardAmendment -FromWorkingTree
  if($null -eq $contract -or $null -eq $spec -or $null -eq $forward -or $contract.cases.Count -ne 84 -or $contract.visualSlots.Count -ne 65){throw 'Current pinned contracts missing'}
  $identity=@{runtimeSourceCommit='3c3f38136db8bb184866635203d04ea4643f1eac';contractCommit=('a'*40);captureSourceCommit=('b'*40);captureSourceTree=('c'*40);producerBlob=('d'*40);executionHead=('b'*40)}
  function Read-OctoberCompatibilityCurrentQualificationContract {param($Commit) if($Commit -cne $identity.contractCommit){throw 'Unexpected mocked source'};return $contract}
  function Read-OctoberCompatibilityCurrentSuccessorSpecification {param($Commit) if($Commit -cne $identity.contractCommit){throw 'Unexpected mocked source'};return $spec}
  function Read-OctoberCompatibilitySource19ForwardAmendment {param($Commit) if($Commit -cne $identity.contractCommit){throw 'Unexpected mocked source'};if($amendmentPresent){return $forward};return $null}
  function New-ObligationFixture {
    $obligations=@();$executions=@{}
    foreach($id in @('cycle1','cycle2')) {
      $executions[$id+':store_layout_and_recovery:fixture_designated']=@{Successes=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)}
    }
    foreach($case in $contract.cases) {
      $clauses=@();$index=1
      foreach($text in $case.retainedObligations) {
        $requirements=@($text)
        foreach($split in $spec.obligations.requiredSplit){if($split.ordinal -eq $case.ordinal -and $split.clause -eq $index){$requirements=@($split.parts)}}
        $parts=@()
        foreach($requirement in $requirements) {
          $test=@{reportId='store_layout_and_recovery';executionId='fixture_designated';testKey=$case.historicalKey}
          $assertion=@{owner=('apps/mobile/test/'+$case.historicalKey.Split(':')[0]);sourceBlob=('c'*40);firstLine=1;lastLine=2;
            excerptSha256=('D'*64);reviewObservation='Labelled shape fixture; not source/assertion review or qualification.'}
          $part=@{requirement=$requirement;disposition='asserted';successfulTests=@($test);assertionEvidence=@($assertion);presentationAuthority=$null;dependency=$null}
          $allowed=@($spec.obligations.providerUnmetAllowed|Where-Object {$_.ordinal -eq $case.ordinal -and $_.clause -eq $index -and $_.requirement -ceq $requirement})
          if($allowed.Count) {
            $deferral=@($contract.providerDeferrals|Where-Object {$_.case -ceq ('H'+$case.ordinal)})[0]
            $part.disposition='provider_unmet';$part.successfulTests=@();$part.assertionEvidence=@();$part.dependency=@{owner=$deferral.owner;completion=$deferral.completion}
          }
          if($case.ordinal -eq 40) {
            $part.disposition='provider_unmet';$part.successfulTests=@();$part.assertionEvidence=@()
            $part.dependency=@{owner=$forward.providerDependency.owner;completion=$forward.providerDependency.completion}
          }
          if($part.disposition -cne 'provider_unmet') {
            foreach($id in @('cycle1','cycle2')){[void]$executions[$id+':store_layout_and_recovery:fixture_designated'].Successes.Add($case.historicalKey)}
          }
          $parts+=@($part)
        }
        $clauses+=@(@{index=$index;text=$text;parts=$parts});$index++
      }
      $obligations+=@(@{ordinal=$case.ordinal;historicalKey=$case.historicalKey;clauses=$clauses})
    }
    # This constructor supplies labelled typed fixtures only; strict sidecar JSON
    # parsing has its own real reader tests. Avoid rescanning the full84-case
    # constructor in PowerShell for every mutation.
    $container=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject @{obligations=$obligations} -Depth 24 -Compress)
    return @{Obligations=$container.obligations;CycleEvidence=@{CyclesVerified=$true;QualificationPassed=$false;Executions=$executions}}
  }

  $count=0
  foreach($mode in @('valid','wrong-owner','wrong-completion','preview-success','preview-assertion','missing-cycle2','missing-preview-row','duplicate-preview-row','preview-risk','preview-presentation','preview-representative','preview-equivalent','preview-risk-inventory','amendment-absent','preview-literal-drift','old-owner','old-completion')) {
    $amendmentPresent=$true;$fixture=New-ObligationFixture
    $obligations=$fixture.Obligations;$preview=$obligations[39].clauses[0].parts[0]
    $inventory=@();$rows=@();$reviews=@{}
    foreach($slot in $contract.visualSlots) {
      $deferred=$slot.slot -cmatch '\AH40-visual-[1-9][0-9]*\z'
      $id=if($deferred){$null}else{'unit-'+$slot.slot}
      $rows+=@([pscustomobject]@{profile=$slot.profile;slot=$slot.slot;reference=$slot.reference;referenceRole=$slot.referenceRole;
        newEvidenceRule=$slot.newEvidenceRule;equivalenceProven=$slot.equivalenceProven;riskId=$id;presentationKey=$null;
        captureRole=$(if($deferred){'dependency'}else{'representative'});disposition=$(if($deferred){'provider_unmet'}else{'representative'})})
      if(-not $deferred) {
        $risk=[pscustomobject]@{id=$id;slotIds=@($slot.slot);representative=[pscustomobject]@{slotId=$slot.slot;profile=$slot.profile};
          currentSurface='labelled unit surface';target='labelled unit target';state='labelled unit state';geometry=[pscustomobject]@{width=4};equivalenceEvidence=@()}
        $inventory+=@($risk);$reviews[$id]=@{inventoryEntry=$risk}
      }
    }
    $previewRow=@($rows|Where-Object {$_.slot -ceq 'H40-visual-1'})
    if($inventory.Count -ne 64 -or $previewRow.Count -ne 1){throw 'Actual slot inventory differs'}
    $primary=@{PrimaryReviewRecordBound=$true;Report=[pscustomobject]@{sourceIdentity=[pscustomobject]$identity.Clone();sourceReviews=$obligations}}
    $pairs=@()
    foreach($entry in $obligations){foreach($clause in $entry.clauses){foreach($part in $clause.parts){
      if($part.disposition -cne 'provider_unmet'){$pairs+=@([pscustomobject]@{Ordinal=$entry.ordinal;Clause=$clause.index;Requirement=$part.requirement;Disposition=$part.disposition;SuccessfulTest=$part.successfulTests[0];AssertionEvidence=$part.assertionEvidence[0]})}
    }}}
    $assertions=@{PrimaryAssertionReviewBound=$true;ReviewedAssertionPairs=$pairs}
    $visual=@{PrimaryVisualReviewBound=$true;Reviews=$reviews}
    switch($mode) {
      'wrong-owner' {$preview.dependency.owner='wrong'}
      'wrong-completion' {$preview.dependency.completion='wrong'}
      'old-owner' {$preview.dependency.owner=$contract.providerDeferrals[2].owner}
      'old-completion' {$preview.dependency.completion=$contract.providerDeferrals[2].completion}
      'preview-success' {$preview.successfulTests=@($obligations[0].clauses[0].parts[0].successfulTests[0])}
      'preview-assertion' {$preview.assertionEvidence=@($obligations[0].clauses[0].parts[0].assertionEvidence[0])}
      'missing-cycle2' {[void]$fixture.CycleEvidence.Executions['cycle2:store_layout_and_recovery:fixture_designated'].Successes.Remove($obligations[0].historicalKey)}
      'missing-preview-row' {$rows=@($rows|Where-Object {$_.slot -cne 'H40-visual-1'})}
      'duplicate-preview-row' {$rows[0]=$previewRow[0]}
      'preview-risk' {$previewRow[0].riskId='fake'}
      'preview-presentation' {$previewRow[0].presentationKey='fake'}
      'preview-representative' {$previewRow[0].captureRole='representative';$previewRow[0].disposition='representative'}
      'preview-equivalent' {$previewRow[0].disposition='equivalent'}
      'preview-risk-inventory' {$inventory[0].slotIds+=@('H40-visual-1');$inventory[0].equivalenceEvidence+=@([pscustomobject]@{slotId='H40-visual-1';disposition='equivalent';presentationKey=$null;currentSurface='labelled unit surface';target='labelled unit target';state='labelled unit state';geometry=[pscustomobject]@{width=4};reason='labelled invalid inclusion';sourceAssertions=@()})}
      'amendment-absent' {$amendmentPresent=$false}
      'preview-literal-drift' {$previewRow[0].reference='different.png'}
    }
    $join=Read-OctoberCompatibilityCurrentObligationJoins -Obligations $obligations -SourceIdentity $identity -CycleEvidence $fixture.CycleEvidence
    $joinExpected=$mode -cnotin @('wrong-owner','wrong-completion','old-owner','old-completion','preview-success','preview-assertion','missing-cycle2','amendment-absent')
    if(($null -ne $join) -ne $joinExpected){throw ('Actual join rejection differs: '+$mode)}
    $slots=$null;$called=$false
    if($null -ne $join) {
      if($join.RetentionAndSuccessJoinsVerified -isnot [bool] -or -not $join.RetentionAndSuccessJoinsVerified -or $join.QualificationPassed){throw 'Join overclaims acceptance'}
      $called=$true
      $slots=Read-OctoberCompatibilityCurrentVisualSlotAccounting -Reconciliation $rows -Inventory $inventory -SourceIdentity $identity -PrimaryVisualReview $visual -PrimaryAssertionReview $assertions -PrimaryBinding $primary -PresentationReview $null
    }
    if(($null -ne $slots) -ne ($mode -ceq 'valid') -or $called -ne $joinExpected){throw ('Actual slot conjunction differs: '+$mode)}
    if($mode -ceq 'valid') {
      if($slots.Slots.Count -ne 65 -or $slots.QualificationPassed -or $slots.ApkAuthority -or $slots.MachineEquivalenceVerified){throw 'Full fixture overclaims authority'}
      foreach($slot in $contract.visualSlots) {
        $assignment=$slots.Slots[$slot.slot]
        if($slot.slot -ceq 'H40-visual-1') {
          if($assignment.Disposition -cne 'provider_unmet' -or $assignment.CaptureRole -cne 'dependency' -or $null -ne $assignment.RiskId -or $null -ne $assignment.PresentationKey){throw 'Preview promoted to visual success'}
        }elseif($assignment.Disposition -cne 'representative' -or $assignment.RiskId -cne ('unit-'+$slot.slot)){throw 'Active assignment changed'}
      }
      foreach($execution in $fixture.CycleEvidence.Executions.Values){if($execution.Successes.Contains($obligations[39].historicalKey)){throw 'Preview success injected into fixture'}}
    }
    [pscustomobject]@{UnitCase=$mode;ActualJoinCalled=$true;ActualSlotCalled=$called;Accepted=($null -ne $slots);QualificationPassed=$false}|ConvertTo-Json -Compress
    $count++
  }
  if($count -ne 17 -or (Get-FileHash -LiteralPath $checker).Hash -cne $ExpectedCheckerSha256){throw 'Fixture/source changed'}
  "PASS: $count full84 obligation/full65 slot conjunction controls; native cycles, review flags and source identity mocked; no source semantics/render/provider/APK acceptance."
}

function Invoke-OctoberCompatibilitySource19HistoryProbes {
  # Actual history/qualification-source predicates with labelled future Git
  # objects. Existing sealed objects are read from Git; no commit is created.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage '51b3dc076ab10ff4f233a420791e4d2b25d2512a'
  Assert-RepairContract ($prefixHistory.Stage -eq 20 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source19Preparation -and $prefixHistory.Forward) 'Source19 must select its exact metadata preparation, not capture/Q.'
  $prefix=@($prefixHistory.Commits);$metadata=('a'*40);$source=('b'*40);$qualified=('c'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource19ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('metadata','source','qualified','metadata-parent','metadata-owner','metadata-apps',
      'source-owner','source-runtime','qualified-apps','missing-delta','duplicate-delta','changed-original','forged-roles')) {
    & {
      $tip=if($case -cin @('source','source-owner','source-runtime')){$source}elseif($case -cin @('qualified','qualified-apps')){$qualified}else{$metadata}
      $graph=@($prefix)+@($metadata);if($tip -cin @($source,$qualified)){$graph+=@($source)};if($tip -ceq $qualified){$graph+=@($qualified)}
      $observations=@{Ancestry=0;QualificationSourceReads=0;Unexpected=$false;MutationHits=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 20..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-20]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($index -eq 20 -and $case -ceq 'metadata-parent'){$observations.MutationHits++;return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)){return [string]$entry.subject}
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 20 -and $case -ceq 'metadata-owner') -or ($index -eq 21 -and $case -ceq 'source-owner')){
              $observations.MutationHits++;return @($entry.owners)+@('apps/mobile/lib/unowned.dart')
            }
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            switch($case) {
              'missing-delta' {$observations.MutationHits++;return $document.Substring(0,$document.IndexOf('<!-- COMPATIBILITY_SOURCE19_FORWARD_AMENDMENT_JSON_BEGIN -->'))}
              'duplicate-delta' {$observations.MutationHits++;return $document+"`n"+$document}
              'changed-original' {$observations.MutationHits++;return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
              'forged-roles' {$observations.MutationHits++;return $document.Replace('"captureSourceIndex":21','"captureSourceIndex":19')}
              default {return $document}
            }
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 20 -and $case -ceq 'metadata-apps') -or ($index -eq 22 -and $case -ceq 'qualified-apps')){
              $observations.MutationHits++;return @(('e'*40),('d'*40))
            }
            $apps=if($index -eq 20){'db20aff3244eec2f4ae84311876afa3b58280f08'}else{('d'*40)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($index -eq 21 -and $case -ceq 'source-runtime'){$observations.MutationHits++;return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        # Cache only immutable sealed-object reads, not status, refs or paths.
        if($query.Contains($metadata) -or $query.Contains($source) -or $query.Contains($qualified)){$observations.Unexpected=$true;throw 'Unexpected future-object query in labelled fixture'}
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$rejection=''
      $stagePayloads=[Collections.Generic.List[object]]::new()
      try {Get-OctoberCompatibilityHistoryStage $tip|ForEach-Object {$stagePayloads.Add($_)};$accepted=$true;if($stagePayloads.Count -eq 1){$result=$stagePayloads[0]}}catch{$rejection=$_.Exception.Message}
      $expected=$case -cin @('metadata','source','qualified')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1) ('forward immutable graph mismatch: '+$case+'; '+$rejection)
      if($observations.Unexpected){throw 'Unexpected future query invalidates graph fixture'}
      if(-not $expected) {
        $expectedReason=switch($case) {
          'metadata-parent' {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('metadata-owner','source-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('metadata-apps','qualified-apps')} {'Compatibility metadata commit changed apps.'}
          'source-runtime' {'Forward test/qualification correction changed frozen runtime.'}
          default {'Current obligation amendment requires exact Source18/19 history.'}
        }
        Assert-RepairContract ($observations.MutationHits -gt 0 -and $stagePayloads.Count -eq 0 -and
          $rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedReason)) ('negative did not reach intended discriminator: '+$case+'; '+$rejection)
      }elseif($stagePayloads.Count -ne 1 -or $result -isnot [hashtable]){throw 'Positive graph emitted wrong stage payload'}
      if($expected) {
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq ($graph.Count-4) -and
          $result.Forward -and $result.Source19Forward -and -not $result.Source19Preparation -and $result.ContractIndex -eq 20 -and
          $result.CaptureIndex -eq 21) ('forward roles were inferred from old stage count: '+$case)
      }
      if($case -ceq 'metadata') {
        # A caller's old-Q role fields cannot change independently recollected
        # forward count19 into qualified count21 or start source-proof reads.
        $forged=$result.Clone();$forged.PhaseStage=19;$forged.ContractIndex=16;$forged.CaptureIndex=17
        function Read-OctoberCompatibilityCurrentSourceState {
          $observations.QualificationSourceReads++;throw 'Premature source proof read.'
        }
        foreach($selection in @('working','index','committed')) {
          $q=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree:($selection -ceq 'working') -FromIndex:($selection -ceq 'index')
          Assert-RepairContract ($null -eq $q -and $observations.QualificationSourceReads -eq 0) 'old stage19 or forged source roles qualified forward metadata.'
        }
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityQualificationCountDispatchProbes {
  # Labelled history/source-state mocks test dispatch only, never qualification.
  $count=0
  $dispatchCases=@(foreach($physicalStage in @(18,19,20,21,22,23,24,25,26,27,28,29)) {
    $phaseStage=if($physicalStage % 2 -eq 0){18}else{19}
    @{Stage=$physicalStage;Phase=$phaseStage;
      ContractIndex=($physicalStage-$(if($phaseStage -eq 18){2}else{3}));
      CaptureIndex=($physicalStage-$(if($phaseStage -eq 18){1}else{2}));
      QualificationIndex=($physicalStage-$(if($phaseStage -eq 18){0}else{1}));
      QualificationBaseIndex=($physicalStage-$(if($phaseStage -eq 18){2}else{3}))}
  })+@(
    @{Stage=29;Phase=18;ContractIndex=26;CaptureIndex=27;QualificationIndex=29;QualificationBaseIndex=28},
    @{Stage=30;Phase=19;ContractIndex=26;CaptureIndex=27;QualificationIndex=29;QualificationBaseIndex=28},
    @{Stage=31;Phase=18;ContractIndex=29;CaptureIndex=30;QualificationIndex=31;QualificationBaseIndex=29},
    @{Stage=32;Phase=19;ContractIndex=29;CaptureIndex=30;QualificationIndex=31;QualificationBaseIndex=29})
  foreach($dispatchCase in $dispatchCases) {
    $stage=$dispatchCase.Stage
    foreach($mode in @('working','index','committed')) {
      & {
        $commits=@(for($index=1;$index -le $stage;$index++){'{0:x40}' -f $index})
        $phase=$dispatchCase.Phase
        $history=@{Stage=$stage;Commits=$commits;Head=$commits[-1];PhaseStage=$phase;
          ContractIndex=$dispatchCase.ContractIndex;CaptureIndex=$dispatchCase.CaptureIndex;
          QualificationIndex=$dispatchCase.QualificationIndex;QualificationBaseIndex=$dispatchCase.QualificationBaseIndex}
        $observations=@{History=0;Source=0;ExpectedPhase='';ExpectedReadOnly=$false;
          ExpectedContractIndex=$history.ContractIndex;ExpectedCaptureIndex=$history.CaptureIndex;
          UnexpectedDispatch=$false;UnexpectedHistory=$false;DispatchValidationComplete=$false;
          ReceivedPhase='';ReceivedReadOnly=$false;
          ReceivedContractIndex=-1;ReceivedCaptureIndex=-1}
        function Get-OctoberCompatibilityHistoryStage([string]$HeadCommit) {
          $observations.History++
          if($HeadCommit -cne $history.Head){$observations.UnexpectedHistory=$true}
          Assert-RepairContract (-not $observations.UnexpectedHistory) 'Wrong qualification history query.'
          return $history.Clone()
        }
        function Read-OctoberCompatibilityCurrentSourceState {
          param([hashtable]$History,[string]$Phase,[switch]$ReadOnlyQualifiedSource)
          $observations.Source++
          $observations.DispatchValidationComplete=$false
          $observations.ReceivedPhase=$Phase
          $observations.ReceivedReadOnly=[bool]$ReadOnlyQualifiedSource
          $observations.ReceivedContractIndex=$History.ContractIndex
          $observations.ReceivedCaptureIndex=$History.CaptureIndex
          if($observations.Source -ne 1 -or -not ($History.Stage -eq $stage -and
            $History.ContractIndex -eq $observations.ExpectedContractIndex -and
            $History.CaptureIndex -eq $observations.ExpectedCaptureIndex -and
            $Phase -ceq $observations.ExpectedPhase -and
            [bool]$ReadOnlyQualifiedSource -eq $observations.ExpectedReadOnly)) {
            $observations.UnexpectedDispatch=$true
          }
          $observations.DispatchValidationComplete=$true
          return $null # Sentinel rejection: dispatch reachability is not proof.
        }
        $eligible=($phase -eq 18 -and $mode -cin @('working','index')) -or
          ($phase -eq 19 -and $mode -ceq 'committed')
        $observations.ExpectedPhase=if($phase -eq 19){'qualification'}elseif($mode -ceq 'index'){'pre_commit'}else{'implementation'}
        $observations.ExpectedReadOnly=$phase -eq 19
        $result=Read-OctoberCompatibilityCurrentQualificationProof -History $history `
          -FromWorkingTree:($mode -ceq 'working') -FromIndex:($mode -ceq 'index')
        Assert-RepairContract ($null -eq $result -and $observations.History -eq 1 -and
          -not $observations.UnexpectedHistory -and -not $observations.UnexpectedDispatch -and
          (-not $eligible -or $observations.DispatchValidationComplete) -and
          $observations.Source -eq $(if($eligible){1}else{0})) ('Qualification count dispatch failed: '+$stage+'/'+$mode)
      }
      $count++
    }
  }
  $extraCases=& {
    $count=0
    $commits=@(for($index=1;$index -le 25;$index++){'{0:x40}' -f $index})
    $observed=@{Stage=25;Commits=$commits;Head=$commits[-1];PhaseStage=17;ContractIndex=24;CaptureIndex=25}
    $forged=$observed.Clone();$forged.PhaseStage=19;$forged.ContractIndex=22;$forged.CaptureIndex=23
    $observations=@{History=0;Source=0;UnexpectedHistory=$false}
    function Get-OctoberCompatibilityHistoryStage([string]$HeadCommit) {
      $observations.History++
      if($HeadCommit -cne $observed.Head){$observations.UnexpectedHistory=$true}
      Assert-RepairContract (-not $observations.UnexpectedHistory) 'Wrong metadata history query.'
      return $observed.Clone()
    }
    function Read-OctoberCompatibilityCurrentSourceState {
      $observations.Source++;throw 'Metadata must not reach qualification source reads.'
    }
    foreach($mode in @('working','index','committed')) {
      $observations.History=0;$observations.Source=0;$observations.UnexpectedHistory=$false
      $result=Read-OctoberCompatibilityCurrentQualificationProof -History $forged `
        -FromWorkingTree:($mode -ceq 'working') -FromIndex:($mode -ceq 'index')
      Assert-RepairContract ($null -eq $result -and $observations.History -eq 1 -and
        $observations.Source -eq 0 -and -not $observations.UnexpectedHistory) 'Forged old-Q roles bypassed independently recollected metadata phase.'
      $count++
    }
    $baseline=$observed.Clone()
    foreach($shape in @('wrong-head','wrong-count','recollected-count','recollected-commits')) {
      $invalid=$forged.Clone();$observed=$baseline.Clone()
      switch($shape) {
        'wrong-head' {$invalid.Head=('f'*40)}
        'wrong-count' {$invalid.Stage=24}
        'recollected-count' {$observed.Stage=27}
        'recollected-commits' {$observed.Commits=@($commits);$observed.Commits[0]=('f'*40)}
      }
      $observations.History=0;$observations.Source=0;$observations.UnexpectedHistory=$false
      $result=Read-OctoberCompatibilityCurrentQualificationProof -History $invalid
      $expectedReads=if($shape -like 'recollected-*'){1}else{0}
      Assert-RepairContract ($null -eq $result -and $observations.History -eq $expectedReads -and
        $observations.Source -eq 0 -and -not $observations.UnexpectedHistory) ('Qualification history shape bypassed: '+$shape)
      $count++
    }
    $observed=$baseline.Clone()
    foreach($invalidStage in @(17,33,'26',26.0)) {
      $invalid=$forged.Clone();$invalid.Stage=$invalidStage
      if($invalidStage -is [int] -and $invalidStage -eq 33) {
        $invalid.Commits=@(for($index=1;$index -le 33;$index++){'{0:x40}' -f $index})
        $invalid.Head=$invalid.Commits[-1]
      }
      $observations.History=0;$observations.Source=0
      $result=Read-OctoberCompatibilityCurrentQualificationProof -History $invalid
      Assert-RepairContract ($null -eq $result -and $observations.History -eq 0 -and
        $observations.Source -eq 0) 'Invalid physical stage reached history/source checking.'
      $count++
    }
    $observations.History=0;$observations.Source=0
    $result=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree -FromIndex
    Assert-RepairContract ($null -eq $result -and $observations.History -eq 0 -and
      $observations.Source -eq 0) 'Mixed qualification selectors reached history checking.'
    $count++
    return $count
  }
  $count+=$extraCases
  return $count
}

function Invoke-OctoberCompatibilitySource23HistoryProbes {
  # Actual history/qualification-source predicates with labelled future Git
  # objects. Existing sealed objects are read from Git; no commit is created.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage '880eea8fa679712ce800f2408e264de1ef75a198'
  Assert-RepairContract ($prefixHistory.Stage -eq 24 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source23Preparation -and $prefixHistory.Forward) 'Source23 must select its exact metadata preparation, not capture/Q.'
  $prefix=@($prefixHistory.Commits);$metadata=('a'*40);$source=('b'*40);$qualified=('c'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource23ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('metadata','source','qualified','metadata-parent','metadata-owner','metadata-apps',
      'source-owner','source-runtime','qualified-apps','missing-delta','duplicate-delta','changed-original','forged-roles')) {
    & {
      $tip=if($case -cin @('source','source-owner','source-runtime')){$source}elseif($case -cin @('qualified','qualified-apps')){$qualified}else{$metadata}
      $graph=@($prefix)+@($metadata);if($tip -cin @($source,$qualified)){$graph+=@($source)};if($tip -ceq $qualified){$graph+=@($qualified)}
      $observations=@{Ancestry=0;QualificationSourceReads=0;Unexpected=$false;MutationHits=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 24..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-24]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($index -eq 24 -and $case -ceq 'metadata-parent'){$observations.MutationHits++;return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)){return [string]$entry.subject}
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 24 -and $case -ceq 'metadata-owner') -or ($index -eq 25 -and $case -ceq 'source-owner')){
              $observations.MutationHits++;return @($entry.owners)+@('apps/mobile/lib/unowned.dart')
            }
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            switch($case) {
              'missing-delta' {$observations.MutationHits++;return $document.Substring(0,$document.IndexOf('<!-- COMPATIBILITY_SOURCE23_FORWARD_AMENDMENT_JSON_BEGIN -->'))}
              'duplicate-delta' {$observations.MutationHits++;return $document+"`n"+$document}
              'changed-original' {$observations.MutationHits++;return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
              'forged-roles' {$observations.MutationHits++;return $document.Replace('"captureSourceIndex":25','"captureSourceIndex":21')}
              default {return $document}
            }
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 24 -and $case -ceq 'metadata-apps') -or ($index -eq 26 -and $case -ceq 'qualified-apps')){
              $observations.MutationHits++;return @(('e'*40),('d'*40))
            }
            $apps=if($index -eq 24){'26be96d19ba6c9f1f12a66ae2dd332b73e092dd8'}else{('d'*40)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($index -eq 25 -and $case -ceq 'source-runtime'){$observations.MutationHits++;return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        # Cache only immutable sealed-object reads, not status, refs or paths.
        if($query.Contains($metadata) -or $query.Contains($source) -or $query.Contains($qualified)){$observations.Unexpected=$true;throw 'Unexpected future-object query in labelled fixture'}
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$rejection=''
      $stagePayloads=[Collections.Generic.List[object]]::new()
      try {Get-OctoberCompatibilityHistoryStage $tip|ForEach-Object {$stagePayloads.Add($_)};$accepted=$true;if($stagePayloads.Count -eq 1){$result=$stagePayloads[0]}}catch{$rejection=$_.Exception.Message}
      $expected=$case -cin @('metadata','source','qualified')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1) ('forward immutable graph mismatch: '+$case+'; '+$rejection)
      if($observations.Unexpected){throw 'Unexpected future query invalidates graph fixture'}
      if(-not $expected) {
        $expectedReason=switch($case) {
          'metadata-parent' {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('metadata-owner','source-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('metadata-apps','qualified-apps')} {'Compatibility metadata commit changed apps.'}
          'source-runtime' {'Forward test/qualification correction changed frozen runtime.'}
          default {'Stored-order amendment requires exact Source22/23 history.'}
        }
        Assert-RepairContract ($observations.MutationHits -gt 0 -and $stagePayloads.Count -eq 0 -and
          $rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedReason)) ('negative did not reach intended discriminator: '+$case+'; '+$rejection)
      }elseif($stagePayloads.Count -ne 1 -or $result -isnot [hashtable]){throw 'Positive graph emitted wrong stage payload'}
      if($expected) {
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq ($graph.Count-8) -and
          $result.Forward -and $result.Source23Forward -and -not $result.Source23Preparation -and $result.ContractIndex -eq 24 -and
          $result.CaptureIndex -eq 25) ('forward roles were inferred from old stage count: '+$case)
      }
      if($case -ceq 'metadata') {
        # A caller's old-Q role fields cannot change independently recollected
        # forward count19 into qualified count21 or start source-proof reads.
        $forged=$result.Clone();$forged.PhaseStage=19;$forged.ContractIndex=16;$forged.CaptureIndex=17
        function Read-OctoberCompatibilityCurrentSourceState {
          $observations.QualificationSourceReads++;throw 'Premature source proof read.'
        }
        foreach($selection in @('working','index','committed')) {
          $q=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree:($selection -ceq 'working') -FromIndex:($selection -ceq 'index')
          Assert-RepairContract ($null -eq $q -and $observations.QualificationSourceReads -eq 0) 'old stage19 or forged source roles qualified forward metadata.'
        }
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource23ReaderProbes {
  # Actual reader and exact sealed delta; document transport alone is mocked.
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $positive=Read-OctoberCompatibilitySource23ForwardAmendment -FromWorkingTree
  Assert-RepairContract ($null -ne $positive) 'Exact Source23 working delta rejected.'
  $block=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE23_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE23_FORWARD_AMENDMENT_JSON_END -->')
  $probeText=$document;$observations=@{Reads=0;Expected='';Unexpected=$false};$count=1
  function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
    $observations.Reads++
    if(($Arguments -join '|') -cne $observations.Expected){$observations.Unexpected=$true;throw 'Wrong Source23 document source.'}
    return $probeText
  }
  foreach($selection in @('index','commit')) {
    $observations.Expected=if($selection -ceq 'index'){'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{'show|'+('a'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
    $observations.Reads=0;$observations.Unexpected=$false
    $result=if($selection -ceq 'index'){Read-OctoberCompatibilitySource23ForwardAmendment -FromIndex}else{Read-OctoberCompatibilitySource23ForwardAmendment -Commit ('a'*40)}
    Assert-RepairContract ($null -ne $result -and $observations.Reads -eq 6 -and -not $observations.Unexpected) 'Source23 reader lost inherited validation or selected wrong source.'
    $count++
  }
  $observations.Expected='show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
  foreach($property in $positive.PSObject.Properties.Name) {
    $changed=$positive|ConvertTo-Json -Depth 40 -Compress|ConvertFrom-Json
    $changed.PSObject.Properties[$property].Value='altered'
    $probeText=$document.Replace($block.Groups[1].Value,($changed|ConvertTo-Json -Depth 40 -Compress))
    $observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource23ForwardAmendment -FromIndex) -and
      $observations.Reads -eq 6 -and -not $observations.Unexpected) ('Altered Source23 property admitted: '+$property)
    $count++
  }
  foreach($candidate in @($document.Replace($block.Value,''),($document+"`n"+$block.Value),
      $document.Replace($block.Groups[1].Value,'{malformed}'),
      $document.Replace('source21_forward_capture_route_amendment_not_qualification','altered-inherited-contract'))) {
    $probeText=$candidate;$observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource23ForwardAmendment -FromIndex) -and
      -not $observations.Unexpected) 'Missing/duplicate/malformed Source23 or changed inherited contract admitted.'
    $count++
  }
  $probeText=$document;$observations.Reads=0;$observations.Unexpected=$false
  foreach($arguments in @(@{},@{Commit=''},@{Commit='bad'},@{FromWorkingTree=$true;FromIndex=$true},
      @{Commit=('a'*40);FromIndex=$true},@{Commit=('a'*40);FromIndex=$true;FromWorkingTree=$true})) {
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource23ForwardAmendment @arguments) -and
      $observations.Reads -eq 0 -and -not $observations.Unexpected) 'Invalid Source23 selector reached document transport.'
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource23FinalStageProbes {
  # Facts are labelled unit mocks; execute the actual final stage predicate.
  $binding=Get-OctoberCompatibilityBinding
  $seed=@{Role=$binding.role;Task=$binding.task;Lane=$binding.lane;WorkId=$binding.workId;TicketId=$binding.ticketId;
    Root=$binding.worktreePath;Branch=$binding.branch;Base=$binding.baselineHead;Stage=19;Phase='handoff';
    PhysicalStage=27;ForwardHistory=$true;Source19ForwardHistory=$true;Source21ForwardHistory=$true;Source23ForwardHistory=$true;
    CurrentSourceVerified=$true;CurrentQualificationVerified=$true;BaseGraphValid=$true;SourceRemotesExact=$true;
    NativeUnchanged=$true;GenerationExact=$true;BindingsExact=$true;HistoryValid=$true;NTestAdmissionVerified=$true;
    Clean=$true;HostQualificationPassed=$true;Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
  $count=0
  foreach($mode in @('valid','missing-forward','false-forward','coerced-forward','metadata-forged-phase','wrong-phase',
      'old-physical-count','missing-proof','dirty','unverified-native','unowned','stale-generation','missing-source19','missing-source21')) {
    $facts=$seed.Clone()
    switch($mode) {
      'missing-forward' {$facts.Remove('Source23ForwardHistory')}
      'false-forward' {$facts.Source23ForwardHistory=$false}
      'coerced-forward' {$facts.Source23ForwardHistory='true'}
      'metadata-forged-phase' {$facts.PhysicalStage=25}
      'wrong-phase' {$facts.Stage=18}
      'old-physical-count' {$facts.PhysicalStage=21}
      'missing-proof' {$facts.CurrentQualificationVerified=$false}
      'dirty' {$facts.Clean=$false}
      'unverified-native' {$facts.NativeUnchanged=$false}
      'unowned' {$facts.Owners+=@('apps/mobile/lib/unowned.dart')}
      'stale-generation' {$facts.GenerationExact=$false}
      'missing-source19' {$facts.Remove('Source19ForwardHistory')}
      'missing-source21' {$facts.Remove('Source21ForwardHistory')}
    }
    Assert-RepairContract ((Test-OctoberCompatibilityStageFacts $facts) -eq ($mode -ceq 'valid')) ('Source23 final stage discriminator changed: '+$mode)
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource25HistoryProbes {
  # Actual history/qualification-source predicates with labelled future Git
  # objects. Existing sealed objects are read from Git; no commit is created.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage '17fb46dcbd22271e8ba495f1aada24ba5f746360'
  Assert-RepairContract ($prefixHistory.Stage -eq 26 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source25Preparation -and $prefixHistory.Forward) 'Source25 must select its exact metadata preparation, not capture/Q.'
  $prefix=@($prefixHistory.Commits);$metadata=('a'*40);$source=('b'*40);$qualified=('c'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource25ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('metadata','source','qualified','metadata-parent','metadata-owner','metadata-apps',
      'source-owner','source-runtime','qualified-apps','missing-delta','duplicate-delta','changed-original','forged-roles')) {
    & {
      $tip=if($case -cin @('source','source-owner','source-runtime')){$source}elseif($case -cin @('qualified','qualified-apps')){$qualified}else{$metadata}
      $graph=@($prefix)+@($metadata);if($tip -cin @($source,$qualified)){$graph+=@($source)};if($tip -ceq $qualified){$graph+=@($qualified)}
      $observations=@{Ancestry=0;QualificationSourceReads=0;Unexpected=$false;MutationHits=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 26..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-26]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($index -eq 26 -and $case -ceq 'metadata-parent'){$observations.MutationHits++;return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)){return [string]$entry.subject}
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 26 -and $case -ceq 'metadata-owner') -or ($index -eq 27 -and $case -ceq 'source-owner')){
              $observations.MutationHits++;return @($entry.owners)+@('apps/mobile/lib/unowned.dart')
            }
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            switch($case) {
              'missing-delta' {$observations.MutationHits++;return $document.Substring(0,$document.IndexOf('<!-- COMPATIBILITY_SOURCE25_FORWARD_AMENDMENT_JSON_BEGIN -->'))}
              'duplicate-delta' {$observations.MutationHits++;return $document+"`n"+$document}
              'changed-original' {$observations.MutationHits++;return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
              'forged-roles' {
                $roleBlock=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE25_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE25_FORWARD_AMENDMENT_JSON_END -->')
                $changedRoles=$roleBlock.Groups[1].Value|ConvertFrom-Json
                Assert-RepairContract ($changedRoles.chain[1].index -eq 27) 'Source25 role mutation requires the actual capture index.'
                $changedRoles.chain[1].index=25
                $changedDocument=$document.Replace($roleBlock.Groups[1].Value,($changedRoles|ConvertTo-Json -Depth 40 -Compress))
                Assert-RepairContract ($changedDocument -cne $document) 'Source25 role mutation must alter document bytes.'
                $observations.MutationHits++;return $changedDocument
              }
              default {return $document}
            }
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 26 -and $case -ceq 'metadata-apps') -or ($index -eq 28 -and $case -ceq 'qualified-apps')){
              $observations.MutationHits++;return @(('e'*40),('d'*40))
            }
            $apps=if($index -eq 26){'4f220d7635b0ac6fc53bf9d656e5b73b7d44e24a'}else{('d'*40)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($index -eq 27 -and $case -ceq 'source-runtime'){$observations.MutationHits++;return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        # Cache only immutable sealed-object reads, not status, refs or paths.
        if($query.Contains($metadata) -or $query.Contains($source) -or $query.Contains($qualified)){$observations.Unexpected=$true;throw 'Unexpected future-object query in labelled fixture'}
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$rejection=''
      $stagePayloads=[Collections.Generic.List[object]]::new()
      try {Get-OctoberCompatibilityHistoryStage $tip|ForEach-Object {$stagePayloads.Add($_)};$accepted=$true;if($stagePayloads.Count -eq 1){$result=$stagePayloads[0]}}catch{$rejection=$_.Exception.Message}
      $expected=$case -cin @('metadata','source','qualified')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1) ('forward immutable graph mismatch: '+$case+'; '+$rejection)
      if($observations.Unexpected){throw 'Unexpected future query invalidates graph fixture'}
      if(-not $expected) {
        $expectedReason=switch($case) {
          'metadata-parent' {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('metadata-owner','source-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('metadata-apps','qualified-apps')} {'Compatibility metadata commit changed apps.'}
          'source-runtime' {'Forward test/qualification correction changed frozen runtime.'}
          default {'Capture context amendment requires exact Source24/25 history.'}
        }
        Assert-RepairContract ($observations.MutationHits -gt 0 -and $stagePayloads.Count -eq 0 -and
          $rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedReason)) ('negative did not reach intended discriminator: '+$case+'; '+$rejection)
      }elseif($stagePayloads.Count -ne 1 -or $result -isnot [hashtable]){throw 'Positive graph emitted wrong stage payload'}
      if($expected) {
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq ($graph.Count-10) -and
          $result.Forward -and $result.Source25Forward -and -not $result.Source25Preparation -and $result.ContractIndex -eq 26 -and
          $result.CaptureIndex -eq 27) ('forward roles were inferred from old stage count: '+$case)
      }
      if($case -ceq 'metadata') {
        # A caller's old-Q role fields cannot change independently recollected
        # forward count19 into qualified count21 or start source-proof reads.
        $forged=$result.Clone();$forged.PhaseStage=19;$forged.ContractIndex=16;$forged.CaptureIndex=17
        function Read-OctoberCompatibilityCurrentSourceState {
          $observations.QualificationSourceReads++;throw 'Premature source proof read.'
        }
        foreach($selection in @('working','index','committed')) {
          $q=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree:($selection -ceq 'working') -FromIndex:($selection -ceq 'index')
          Assert-RepairContract ($null -eq $q -and $observations.QualificationSourceReads -eq 0) 'old stage19 or forged source roles qualified forward metadata.'
        }
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource28FinalStageProbes {
  # Facts are labelled unit mocks; execute the actual final stage predicate.
  $binding=Get-OctoberCompatibilityBinding
  $seed=@{Role=$binding.role;Task=$binding.task;Lane=$binding.lane;WorkId=$binding.workId;TicketId=$binding.ticketId;
    Root=$binding.worktreePath;Branch=$binding.branch;Base=$binding.baselineHead;Stage=19;Phase='handoff';
    PhysicalStage=32;ForwardHistory=$true;Source19ForwardHistory=$true;Source21ForwardHistory=$true;Source23ForwardHistory=$true;Source25ForwardHistory=$true;Source27ForwardHistory=$true;Source28ForwardHistory=$true;
    CurrentSourceVerified=$true;CurrentQualificationVerified=$true;BaseGraphValid=$true;SourceRemotesExact=$true;
    NativeUnchanged=$true;GenerationExact=$true;BindingsExact=$true;HistoryValid=$true;NTestAdmissionVerified=$true;
    Clean=$true;HostQualificationPassed=$true;Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
  $count=0
  foreach($mode in @('valid','missing-forward','false-forward','coerced-forward','metadata-forged-phase','wrong-phase',
      'old-physical-count','missing-proof','dirty','unverified-native','unowned','stale-generation','missing-source19','missing-source21','missing-source23','missing-source25','missing-source27','capture-forged-phase')) {
    $facts=$seed.Clone()
    switch($mode) {
      'missing-forward' {$facts.Remove('Source28ForwardHistory')}
      'false-forward' {$facts.Source28ForwardHistory=$false}
      'coerced-forward' {$facts.Source28ForwardHistory='true'}
      'metadata-forged-phase' {$facts.PhysicalStage=27}
      'wrong-phase' {$facts.Stage=18}
      'old-physical-count' {$facts.PhysicalStage=21}
      'missing-proof' {$facts.CurrentQualificationVerified=$false}
      'dirty' {$facts.Clean=$false}
      'unverified-native' {$facts.NativeUnchanged=$false}
      'unowned' {$facts.Owners+=@('apps/mobile/lib/unowned.dart')}
      'stale-generation' {$facts.GenerationExact=$false}
      'missing-source19' {$facts.Remove('Source19ForwardHistory')}
      'missing-source21' {$facts.Remove('Source21ForwardHistory')}
      'missing-source23' {$facts.Remove('Source23ForwardHistory')}
      'missing-source25' {$facts.Remove('Source25ForwardHistory')}
      'missing-source27' {$facts.Remove('Source27ForwardHistory')}
      'capture-forged-phase' {$facts.PhysicalStage=31}
    }
    Assert-RepairContract ((Test-OctoberCompatibilityStageFacts $facts) -eq ($mode -ceq 'valid')) ('Source28 final stage discriminator changed: '+$mode)
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource28HistoryProbes {
  # Actual sealed prefix; only the three prospective objects are labelled mocks.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage 'fbf31fea1e6f4375f3e828259b26abe145cd20ef'
  Assert-RepairContract ($prefixHistory.Stage -eq 29 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source28Preparation -and -not $prefixHistory.Source28Forward) 'Evaluator28 preparation identity changed.'
  $prefix=@($prefixHistory.Commits);$future=@(('a'*40),('b'*40),('c'*40));$extra=('d'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource28ForwardAmendment -FromWorkingTree
  Assert-RepairContract ($null -ne $delta) 'Source28 exact amendment missing.'
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application|Select-Object -First 1).Source
  $cache=@{};$count=0
  foreach($case in @('metadata','capture','qualified','extra','metadata-parent','capture-parent','q-parent',
      'metadata-owner','capture-owner','q-owner','metadata-apps','q-apps','metadata-runtime','capture-runtime','q-runtime',
      'layout-preimage','missing-delta','changed-delta','q-lost-delta','capture-subject','q-subject','premature-q')) {
    & {
      $size=if($case -eq 'metadata'){1}elseif($case -eq 'capture'){2}else{3}
      $graph=@($prefix)+@($future[0..($size-1)]);if($case -eq 'extra'){$graph+=@($extra)}
      $tip=$graph[-1];$hits=@{mutation=0;ancestry=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $hits.ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        if($query -ceq ('rev-parse|'+$prefix[-1]+'^{tree}|'+$prefix[-1]+':apps|'+$prefix[-1]+':apps/mobile/lib|'+$prefix[-1]+':apps/mobile/test/work_workspace_layout_safety_test.dart')) {
          $layout=$delta.layoutPredecessorBlob
          if($case -eq 'layout-preimage'){$hits.mutation++;$layout=('e'*40)}
          return @($delta.predecessorTree,$delta.frozenAppsTree,$delta.frozenRuntimeTree,$layout)
        }
        foreach($index in 29..($graph.Count-1)) {
          $commit=$graph[$index];$role=if($index -eq 29){'metadata'}elseif($index -eq 30){'capture'}else{'q'}
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($case -ceq ($role+'-parent')){$hits.mutation++;return @($prefix[27])}
            return @($graph[$index-1])
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)) {
            if($index -gt 31){return @('qualification(store-buy-compatibility-20261008): unauthorized extra')}
            if($case -ceq ($role+'-subject') -or ($case -eq 'premature-q' -and $index -eq 30)){$hits.mutation++;return @($delta.chain[2].subject+' premature')}
            return @($delta.chain[$index-29].subject)
          }
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if($case -ceq ($role+'-owner')){$hits.mutation++;return @('config/codex-subagent-coordination-policy.json')}
            return @($delta.chain[$index-29].owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            if(($case -eq 'missing-delta' -and $index -eq 29) -or ($case -eq 'q-lost-delta' -and $index -eq 31)) {
              $hits.mutation++;return @([regex]::Replace($document,'(?s)<!-- COMPATIBILITY_SOURCE28_FORWARD_AMENDMENT_JSON_BEGIN -->.*?<!-- COMPATIBILITY_SOURCE28_FORWARD_AMENDMENT_JSON_END -->',''))
            }
            if($case -eq 'changed-delta' -and $index -eq 29){$hits.mutation++;return @($document.Replace('source28_forward_operational_capture_correction_not_qualification','changed-role'))}
            return @($document)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            $apps=if($index -eq 29){$delta.frozenAppsTree}else{('f'*40)}
            if($case -ceq ($role+'-apps')){$hits.mutation++;return @(('e'*40),$apps)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($case -ceq ($role+'-runtime')){$hits.mutation++;return @(('e'*40),$delta.frozenRuntimeTree)}
            return @($delta.frozenRuntimeTree,$delta.frozenRuntimeTree)
          }
        }
        if(@($future)+@($extra)|Where-Object {$query.Contains($_)}){throw ('Unexpected future-object probe: '+$query)}
        if(-not $cache.ContainsKey($query)){$cache[$query]=@(& $originalGit $Arguments)}
        return $cache[$query]
      }
      $result=$null;$reason=$null
      try{$result=Get-OctoberCompatibilityHistoryStage $tip}catch{$reason=$_.Exception.Message}
      if($case -cin @('metadata','capture','qualified')) {
        Assert-RepairContract ($null -ne $result -and $hits.ancestry -eq 1 -and $result.Stage -eq $graph.Count -and
          $result.PhaseStage -eq (16+$size) -and $result.Source28Forward -and $result.ContractIndex -eq 29 -and
          $result.CaptureIndex -eq 30 -and $result.QualificationIndex -eq 31 -and $result.QualificationBaseIndex -eq 29) ('Source28 roles rejected: '+$case+'; '+$reason)
      }else{
        $expected=switch($case) {
          'extra' {'Compatibility history contains an extra commit or merge.'}
          {$_ -cin @('metadata-parent','capture-parent','q-parent','capture-subject','q-subject','premature-q')} {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('metadata-owner','capture-owner','q-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('metadata-apps','q-apps')} {'Compatibility metadata commit changed apps.'}
          {$_ -cin @('metadata-runtime','capture-runtime','q-runtime')} {'Forward test/qualification correction changed frozen runtime.'}
          'layout-preimage' {'Operational capture predecessor source changed.'}
          'q-lost-delta' {'Operational capture successor lost its sealed forward contract.'}
          default {'Operational capture amendment requires exact evaluator28 history.'}
        }
        Assert-RepairContract ($null -eq $result -and ($case -eq 'extra' -or $hits.mutation -gt 0) -and
          $reason -ceq ('Codex subagent coordination gate rejected: '+$expected)) ('Source28 discriminator masked: '+$case+'; '+$reason)
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource27HistoryProbes {
  # Exact immutable prefix plus labelled future objects, never real admission.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage 'a03eff1c0e37cc71d0c9bd26d2724de12e63a2d3'
  Assert-RepairContract ($prefixHistory.Stage -eq 28 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source27Preparation -and -not $prefixHistory.Source27Forward -and
    $prefixHistory.ContractIndex -eq 26 -and $prefixHistory.CaptureIndex -eq 27) 'Source27 must remain exact preparation.'
  $prefix=@($prefixHistory.Commits);$evaluator=('a'*40);$qualified=('c'*40);$oldQ=('b'*40);$extra=('d'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource27ForwardAmendment -FromWorkingTree
  Assert-RepairContract ($null -ne $delta) 'Source27 probe requires the real sealed amendment.'
  $block=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE27_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE27_FORWARD_AMENDMENT_JSON_END -->')
  $oldDelta=Read-OctoberCompatibilitySource25ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('evaluator','qualified','old-q','old-q-extra','evaluator-parent','q-parent',
      'evaluator-owner','q-owner','evaluator-apps','q-apps','evaluator-subject','q-subject','q-old-subject',
      'missing-delta','duplicate-delta','changed-original','forged-roles','q-lost-delta','q-changed-delta','evaluator-runtime','q-runtime')) {
    & {
      $qCase=$case -cin @('qualified','q-parent','q-owner','q-apps','q-subject','q-old-subject','q-lost-delta','q-changed-delta','q-runtime')
      $oldCase=$case -cin @('old-q','old-q-extra')
      $graph=if($oldCase){@($prefix)+@($oldQ)}else{@($prefix)+@($evaluator)}
      if($qCase){$graph+=@($qualified)};if($case -ceq 'old-q-extra'){$graph+=@($extra)}
      $tip=$graph[-1];$observations=@{Ancestry=0;Unexpected=$false;MutationHits=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 28..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-28]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if(($index -eq 28 -and $case -ceq 'evaluator-parent') -or ($index -eq 29 -and $case -ceq 'q-parent')){$observations.MutationHits++;return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)) {
            if($oldCase -and $index -eq 28){return [string]$oldDelta.chain[2].subject}
            if(($index -eq 28 -and $case -ceq 'evaluator-subject') -or ($index -eq 29 -and $case -ceq 'q-subject')){$observations.MutationHits++;return 'invalid: future subject'}
            if($index -eq 29 -and $case -ceq 'q-old-subject'){$observations.MutationHits++;return [string]$oldDelta.chain[2].subject}
            return [string]$entry.subject
          }
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 28 -and $case -ceq 'evaluator-owner') -or ($index -eq 29 -and $case -ceq 'q-owner')){$observations.MutationHits++;return @($entry.owners)+@('apps/mobile/lib/unowned.dart')}
            if($oldCase){return @('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            if($oldCase){return $document.Replace($block.Value,'')}
            if(($index -eq 28 -and $case -ceq 'missing-delta') -or ($index -eq 29 -and $case -ceq 'q-lost-delta')){$observations.MutationHits++;return $document.Replace($block.Value,'')}
            if($index -eq 28 -and $case -ceq 'duplicate-delta'){$observations.MutationHits++;return $document+"`n"+$block.Value}
            if($index -eq 28 -and $case -ceq 'changed-original'){$observations.MutationHits++;return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
            if(($index -eq 28 -and $case -ceq 'forged-roles') -or ($index -eq 29 -and $case -ceq 'q-changed-delta')) {
              $changedRoles=$block.Groups[1].Value|ConvertFrom-Json
              Assert-RepairContract ($changedRoles.sourceRoles.captureIndex -eq 27) 'Role mutation must target original capture27.'
              $changedRoles.sourceRoles.captureIndex=28
              $changedDocument=$document.Replace($block.Groups[1].Value,($changedRoles|ConvertTo-Json -Depth 40 -Compress))
              Assert-RepairContract ($changedDocument -cne $document) 'Role mutation must change bytes.'
              $observations.MutationHits++;return $changedDocument
            }
            return $document
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 28 -and $case -ceq 'evaluator-apps') -or ($index -eq 29 -and $case -ceq 'q-apps')){$observations.MutationHits++;return @(('e'*40),'85d4d2b79d0bf308688365f216240eef79455509')}
            return @('85d4d2b79d0bf308688365f216240eef79455509','85d4d2b79d0bf308688365f216240eef79455509')
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if(($index -eq 28 -and $case -ceq 'evaluator-runtime') -or ($index -eq 29 -and $case -ceq 'q-runtime')){$observations.MutationHits++;return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        if(@($evaluator,$qualified,$oldQ,$extra|Where-Object {$query.Contains($_)}).Count){$observations.Unexpected=$true;throw 'Unexpected future-object query'}
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$reason=''
      try{$result=Get-OctoberCompatibilityHistoryStage $tip;$accepted=$true}catch{$reason=$_.Exception.Message}
      $expected=$case -cin @('evaluator','qualified','old-q')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1 -and -not $observations.Unexpected) ('Source27 history mismatch: '+$case+'; '+$reason)
      if($expected) {
        $expectedPhase=if($case -ceq 'evaluator'){18}else{19}
        $expectedQ=if($oldCase){28}else{29};$expectedBase=if($oldCase){26}else{28}
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq $expectedPhase -and
          $result.ContractIndex -eq 26 -and $result.CaptureIndex -eq 27 -and $result.QualificationIndex -eq $expectedQ -and
          $result.QualificationBaseIndex -eq $expectedBase -and $result.Commits[26] -ceq $prefix[26] -and
          $result.Commits[27] -ceq $prefix[27] -and $result.Source27Forward -eq (-not $oldCase)) 'Source27 history roles changed.'
      }else{
        $expectedReason=switch($case) {
          'old-q-extra' {'Source27 qualification cannot admit arbitrary later successors.'}
          'evaluator-subject' {'Source27 qualification cannot admit arbitrary later successors.'}
          {$_ -cin @('q-subject','q-old-subject')} {'Evaluator qualification cannot admit arbitrary later successors.'}
          {$_ -cin @('evaluator-parent','q-parent')} {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('evaluator-owner','q-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('evaluator-apps','q-apps')} {'Compatibility metadata commit changed apps.'}
          {$_ -cin @('evaluator-runtime','q-runtime')} {'Forward test/qualification correction changed frozen runtime.'}
          {$_ -cin @('q-lost-delta','q-changed-delta')} {'Evaluator successor lost its sealed forward contract.'}
          default {'Evaluator amendment requires exact Source26/27 history.'}
        }
        Assert-RepairContract (($case -ceq 'old-q-extra' -or $observations.MutationHits -gt 0) -and
          $reason -ceq ('Codex subagent coordination gate rejected: '+$expectedReason)) ('Source27 negative discriminator masked: '+$case+'; '+$reason)
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource25ReaderProbes {
  # Actual reader and exact sealed delta; document transport alone is mocked.
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $positive=Read-OctoberCompatibilitySource25ForwardAmendment -FromWorkingTree
  Assert-RepairContract ($null -ne $positive) 'Exact Source25 working delta rejected.'
  $block=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE25_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE25_FORWARD_AMENDMENT_JSON_END -->')
  $probeText=$document;$observations=@{Reads=0;Expected='';Unexpected=$false};$count=1
  function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
    $observations.Reads++
    if(($Arguments -join '|') -cne $observations.Expected){$observations.Unexpected=$true;throw 'Wrong Source25 document source.'}
    return $probeText
  }
  foreach($selection in @('index','commit')) {
    $observations.Expected=if($selection -ceq 'index'){'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{'show|'+('a'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
    $observations.Reads=0;$observations.Unexpected=$false
    $result=if($selection -ceq 'index'){Read-OctoberCompatibilitySource25ForwardAmendment -FromIndex}else{Read-OctoberCompatibilitySource25ForwardAmendment -Commit ('a'*40)}
    Assert-RepairContract ($null -ne $result -and $observations.Reads -eq 7 -and -not $observations.Unexpected) 'Source25 reader lost inherited validation or selected wrong source.'
    $count++
  }
  $observations.Expected='show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
  foreach($property in $positive.PSObject.Properties.Name) {
    $changed=$positive|ConvertTo-Json -Depth 40 -Compress|ConvertFrom-Json
    $changed.PSObject.Properties[$property].Value='altered'
    $probeText=$document.Replace($block.Groups[1].Value,($changed|ConvertTo-Json -Depth 40 -Compress))
    $observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource25ForwardAmendment -FromIndex) -and
      $observations.Reads -eq 7 -and -not $observations.Unexpected) ('Altered Source25 property admitted: '+$property)
    $count++
  }
  foreach($candidate in @($document.Replace($block.Value,''),($document+"`n"+$block.Value),
      $document.Replace($block.Groups[1].Value,'{malformed}'),
      $document.Replace('source23_forward_stored_order_capture_amendment_not_qualification','altered-inherited-contract'))) {
    $probeText=$candidate;$observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource25ForwardAmendment -FromIndex) -and
      -not $observations.Unexpected) 'Missing/duplicate/malformed Source25 or changed inherited contract admitted.'
    $count++
  }
  $probeText=$document;$observations.Reads=0;$observations.Unexpected=$false
  foreach($arguments in @(@{},@{Commit=''},@{Commit='bad'},@{FromWorkingTree=$true;FromIndex=$true},
      @{Commit=('a'*40);FromIndex=$true},@{Commit=('a'*40);FromIndex=$true;FromWorkingTree=$true})) {
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource25ForwardAmendment @arguments) -and
      $observations.Reads -eq 0 -and -not $observations.Unexpected) 'Invalid Source25 selector reached document transport.'
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource25FinalStageProbes {
  # Facts are labelled unit mocks; execute the actual final stage predicate.
  $binding=Get-OctoberCompatibilityBinding
  $seed=@{Role=$binding.role;Task=$binding.task;Lane=$binding.lane;WorkId=$binding.workId;TicketId=$binding.ticketId;
    Root=$binding.worktreePath;Branch=$binding.branch;Base=$binding.baselineHead;Stage=19;Phase='handoff';
    PhysicalStage=29;ForwardHistory=$true;Source19ForwardHistory=$true;Source21ForwardHistory=$true;Source23ForwardHistory=$true;Source25ForwardHistory=$true;
    CurrentSourceVerified=$true;CurrentQualificationVerified=$true;BaseGraphValid=$true;SourceRemotesExact=$true;
    NativeUnchanged=$true;GenerationExact=$true;BindingsExact=$true;HistoryValid=$true;NTestAdmissionVerified=$true;
    Clean=$true;HostQualificationPassed=$true;Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
  $count=0
  foreach($mode in @('valid','missing-forward','false-forward','coerced-forward','metadata-forged-phase','wrong-phase',
      'old-physical-count','missing-proof','dirty','unverified-native','unowned','stale-generation','missing-source19','missing-source21','missing-source23')) {
    $facts=$seed.Clone()
    switch($mode) {
      'missing-forward' {$facts.Remove('Source25ForwardHistory')}
      'false-forward' {$facts.Source25ForwardHistory=$false}
      'coerced-forward' {$facts.Source25ForwardHistory='true'}
      'metadata-forged-phase' {$facts.PhysicalStage=27}
      'wrong-phase' {$facts.Stage=18}
      'old-physical-count' {$facts.PhysicalStage=21}
      'missing-proof' {$facts.CurrentQualificationVerified=$false}
      'dirty' {$facts.Clean=$false}
      'unverified-native' {$facts.NativeUnchanged=$false}
      'unowned' {$facts.Owners+=@('apps/mobile/lib/unowned.dart')}
      'stale-generation' {$facts.GenerationExact=$false}
      'missing-source19' {$facts.Remove('Source19ForwardHistory')}
      'missing-source21' {$facts.Remove('Source21ForwardHistory')}
      'missing-source23' {$facts.Remove('Source23ForwardHistory')}
    }
    Assert-RepairContract ((Test-OctoberCompatibilityStageFacts $facts) -eq ($mode -ceq 'valid')) ('Source25 final stage discriminator changed: '+$mode)
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource21HistoryProbes {
  # Actual history/qualification-source predicates with labelled future Git
  # objects. Existing sealed objects are read from Git; no commit is created.
  $prefixHistory=Get-OctoberCompatibilityHistoryStage '43ea27a81e7c1876abc0df15b39342da96b63c10'
  Assert-RepairContract ($prefixHistory.Stage -eq 22 -and $prefixHistory.PhaseStage -eq 16 -and
    $prefixHistory.Source21Preparation -and $prefixHistory.Forward) 'Source21 must select its exact metadata preparation, not capture/Q.'
  $prefix=@($prefixHistory.Commits);$metadata=('a'*40);$source=('b'*40);$qualified=('c'*40)
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $delta=Read-OctoberCompatibilitySource21ForwardAmendment -FromWorkingTree
  $originalGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock
  $gitExecutable=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
  $immutableCache=@{};$count=0
  foreach($case in @('metadata','source','qualified','metadata-parent','metadata-owner','metadata-apps',
      'source-owner','source-runtime','qualified-apps','missing-delta','duplicate-delta','changed-original','forged-roles')) {
    & {
      $tip=if($case -cin @('source','source-owner','source-runtime')){$source}elseif($case -cin @('qualified','qualified-apps')){$qualified}else{$metadata}
      $graph=@($prefix)+@($metadata);if($tip -cin @($source,$qualified)){$graph+=@($source)};if($tip -ceq $qualified){$graph+=@($qualified)}
      $observations=@{Ancestry=0;QualificationSourceReads=0;Unexpected=$false;MutationHits=0}
      function git {
        if(($args -join '|') -ceq ('-C|'+$root+'|merge-base|--is-ancestor|'+$prefixHistory.Base+'|'+$tip)) {
          $observations.Ancestry++;$global:LASTEXITCODE=0;return
        }
        & $gitExecutable @args
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|'
        if($query -ceq ('rev-list|--reverse|'+$prefixHistory.Base+'..'+$tip) -or
           $query -ceq ('rev-list|--first-parent|--reverse|'+$prefixHistory.Base+'..'+$tip)){return $graph}
        foreach($index in 22..($graph.Count-1)) {
          $commit=[string]$graph[$index];$entry=$delta.chain[$index-22]
          if($query -ceq ('show|-s|--format=%P|'+$commit)) {
            if($index -eq 22 -and $case -ceq 'metadata-parent'){$observations.MutationHits++;return ('f'*40)}
            return [string]$graph[$index-1]
          }
          if($query -ceq ('show|-s|--format=%s|'+$commit)){return [string]$entry.subject}
          if($query -ceq ('diff-tree|--no-commit-id|--name-only|-r|'+$commit)) {
            if(($index -eq 22 -and $case -ceq 'metadata-owner') -or ($index -eq 23 -and $case -ceq 'source-owner')){
              $observations.MutationHits++;return @($entry.owners)+@('apps/mobile/lib/unowned.dart')
            }
            return @($entry.owners)
          }
          if($query -ceq ('show|'+$commit+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')) {
            switch($case) {
              'missing-delta' {$observations.MutationHits++;return $document.Substring(0,$document.IndexOf('<!-- COMPATIBILITY_SOURCE21_FORWARD_AMENDMENT_JSON_BEGIN -->'))}
              'duplicate-delta' {$observations.MutationHits++;return $document+"`n"+$document}
              'changed-original' {$observations.MutationHits++;return $document.Replace('current_successor_and_qualification_specification_not_admission','changed-original')}
              'forged-roles' {$observations.MutationHits++;return $document.Replace('"captureSourceIndex":23','"captureSourceIndex":21')}
              default {return $document}
            }
          }
          if($query -ceq ('rev-parse|'+$commit+':apps|'+$graph[$index-1]+':apps')) {
            if(($index -eq 22 -and $case -ceq 'metadata-apps') -or ($index -eq 24 -and $case -ceq 'qualified-apps')){
              $observations.MutationHits++;return @(('e'*40),('d'*40))
            }
            $apps=if($index -eq 22){'dcbf4f8f0fa63858427cc7a7879738b69f8093ff'}else{('d'*40)}
            return @($apps,$apps)
          }
          if($query -ceq ('rev-parse|'+$commit+':apps/mobile/lib|3c3f38136db8bb184866635203d04ea4643f1eac:apps/mobile/lib')) {
            if($index -eq 23 -and $case -ceq 'source-runtime'){$observations.MutationHits++;return @(('e'*40),'1636d17025a9e80b362709f24c600d976ed6030f')}
            return @('1636d17025a9e80b362709f24c600d976ed6030f','1636d17025a9e80b362709f24c600d976ed6030f')
          }
        }
        # Cache only immutable sealed-object reads, not status, refs or paths.
        if($query.Contains($metadata) -or $query.Contains($source) -or $query.Contains($qualified)){$observations.Unexpected=$true;throw 'Unexpected future-object query in labelled fixture'}
        if($immutableCache.ContainsKey($query)){return $immutableCache[$query]}
        $lines=@(& $originalGit $Arguments)
        if($Arguments[0] -cin @('show','diff-tree') -or ($Arguments[0] -ceq 'rev-parse' -and
            @($Arguments|Select-Object -Skip 1|Where-Object {$_ -cnotmatch '\A[0-9a-f]{40}:.+\z'}).Count -eq 0)){$immutableCache[$query]=$lines}
        return $lines
      }
      $accepted=$false;$result=$null;$rejection=''
      $stagePayloads=[Collections.Generic.List[object]]::new()
      try {Get-OctoberCompatibilityHistoryStage $tip|ForEach-Object {$stagePayloads.Add($_)};$accepted=$true;if($stagePayloads.Count -eq 1){$result=$stagePayloads[0]}}catch{$rejection=$_.Exception.Message}
      $expected=$case -cin @('metadata','source','qualified')
      Assert-RepairContract ($accepted -eq $expected -and $observations.Ancestry -eq 1) ('forward immutable graph mismatch: '+$case+'; '+$rejection)
      if($observations.Unexpected){throw 'Unexpected future query invalidates graph fixture'}
      if(-not $expected) {
        $expectedReason=switch($case) {
          'metadata-parent' {'Compatibility successor parent/subject changed.'}
          {$_ -cin @('metadata-owner','source-owner')} {'Compatibility successor changed unexpected owners.'}
          {$_ -cin @('metadata-apps','qualified-apps')} {'Compatibility metadata commit changed apps.'}
          'source-runtime' {'Forward test/qualification correction changed frozen runtime.'}
          default {'Capture callback amendment requires exact Source20/21 history.'}
        }
        Assert-RepairContract ($observations.MutationHits -gt 0 -and $stagePayloads.Count -eq 0 -and
          $rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedReason)) ('negative did not reach intended discriminator: '+$case+'; '+$rejection)
      }elseif($stagePayloads.Count -ne 1 -or $result -isnot [hashtable]){throw 'Positive graph emitted wrong stage payload'}
      if($expected) {
        Assert-RepairContract ($result.Stage -eq $graph.Count -and $result.PhaseStage -eq ($graph.Count-6) -and
          $result.Forward -and $result.Source21Forward -and -not $result.Source21Preparation -and $result.ContractIndex -eq 22 -and
          $result.CaptureIndex -eq 23) ('forward roles were inferred from old stage count: '+$case)
      }
      if($case -ceq 'metadata') {
        # A caller's old-Q role fields cannot change independently recollected
        # forward count19 into qualified count21 or start source-proof reads.
        $forged=$result.Clone();$forged.PhaseStage=19;$forged.ContractIndex=16;$forged.CaptureIndex=17
        function Read-OctoberCompatibilityCurrentSourceState {
          $observations.QualificationSourceReads++;throw 'Premature source proof read.'
        }
        foreach($selection in @('working','index','committed')) {
          $q=Read-OctoberCompatibilityCurrentQualificationProof -History $forged -FromWorkingTree:($selection -ceq 'working') -FromIndex:($selection -ceq 'index')
          Assert-RepairContract ($null -eq $q -and $observations.QualificationSourceReads -eq 0) 'old stage19 or forged source roles qualified forward metadata.'
        }
      }
    }
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource21ReaderProbes {
  # Actual reader and exact sealed delta; document transport alone is mocked.
  $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
  $positive=Read-OctoberCompatibilitySource21ForwardAmendment -FromWorkingTree
  Assert-RepairContract ($null -ne $positive) 'Exact Source21 working delta rejected.'
  $block=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE21_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE21_FORWARD_AMENDMENT_JSON_END -->')
  $probeText=$document;$observations=@{Reads=0;Expected='';Unexpected=$false};$count=1
  function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
    $observations.Reads++
    if(($Arguments -join '|') -cne $observations.Expected){$observations.Unexpected=$true;throw 'Wrong Source21 document source.'}
    return $probeText
  }
  foreach($selection in @('index','commit')) {
    $observations.Expected=if($selection -ceq 'index'){'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{'show|'+('a'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
    $observations.Reads=0;$observations.Unexpected=$false
    $result=if($selection -ceq 'index'){Read-OctoberCompatibilitySource21ForwardAmendment -FromIndex}else{Read-OctoberCompatibilitySource21ForwardAmendment -Commit ('a'*40)}
    Assert-RepairContract ($null -ne $result -and $observations.Reads -eq 5 -and -not $observations.Unexpected) 'Source21 reader lost inherited validation or selected wrong source.'
    $count++
  }
  $observations.Expected='show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
  foreach($property in $positive.PSObject.Properties.Name) {
    $changed=$positive|ConvertTo-Json -Depth 40 -Compress|ConvertFrom-Json
    $changed.PSObject.Properties[$property].Value='altered'
    $probeText=$document.Replace($block.Groups[1].Value,($changed|ConvertTo-Json -Depth 40 -Compress))
    $observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource21ForwardAmendment -FromIndex) -and
      $observations.Reads -eq 5 -and -not $observations.Unexpected) ('Altered Source21 property admitted: '+$property)
    $count++
  }
  foreach($candidate in @($document.Replace($block.Value,''),($document+"`n"+$block.Value),
      $document.Replace($block.Groups[1].Value,'{malformed}'),
      $document.Replace('source19_forward_qualification_amendment_not_qualification','altered-inherited-contract'))) {
    $probeText=$candidate;$observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource21ForwardAmendment -FromIndex) -and
      -not $observations.Unexpected) 'Missing/duplicate/malformed Source21 or changed inherited contract admitted.'
    $count++
  }
  $probeText=$document;$observations.Reads=0;$observations.Unexpected=$false
  foreach($arguments in @(@{},@{Commit=''},@{Commit='bad'},@{FromWorkingTree=$true;FromIndex=$true},
      @{Commit=('a'*40);FromIndex=$true},@{Commit=('a'*40);FromIndex=$true;FromWorkingTree=$true})) {
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource21ForwardAmendment @arguments) -and
      $observations.Reads -eq 0 -and -not $observations.Unexpected) 'Invalid Source21 selector reached document transport.'
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilitySource21FinalStageProbes {
  # Facts are labelled unit mocks; execute the actual final stage predicate.
  $binding=Get-OctoberCompatibilityBinding
  $seed=@{Role=$binding.role;Task=$binding.task;Lane=$binding.lane;WorkId=$binding.workId;TicketId=$binding.ticketId;
    Root=$binding.worktreePath;Branch=$binding.branch;Base=$binding.baselineHead;Stage=19;Phase='handoff';
    PhysicalStage=25;ForwardHistory=$true;Source19ForwardHistory=$true;Source21ForwardHistory=$true;
    CurrentSourceVerified=$true;CurrentQualificationVerified=$true;BaseGraphValid=$true;SourceRemotesExact=$true;
    NativeUnchanged=$true;GenerationExact=$true;BindingsExact=$true;HistoryValid=$true;NTestAdmissionVerified=$true;
    Clean=$true;HostQualificationPassed=$true;Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
  $count=0
  foreach($mode in @('valid','missing-forward','false-forward','coerced-forward','metadata-forged-phase','wrong-phase',
      'old-physical-count','missing-proof','dirty','unverified-native','unowned','stale-generation','missing-source19')) {
    $facts=$seed.Clone()
    switch($mode) {
      'missing-forward' {$facts.Remove('Source21ForwardHistory')}
      'false-forward' {$facts.Source21ForwardHistory=$false}
      'coerced-forward' {$facts.Source21ForwardHistory='true'}
      'metadata-forged-phase' {$facts.PhysicalStage=23}
      'wrong-phase' {$facts.Stage=18}
      'old-physical-count' {$facts.PhysicalStage=21}
      'missing-proof' {$facts.CurrentQualificationVerified=$false}
      'dirty' {$facts.Clean=$false}
      'unverified-native' {$facts.NativeUnchanged=$false}
      'unowned' {$facts.Owners+=@('apps/mobile/lib/unowned.dart')}
      'stale-generation' {$facts.GenerationExact=$false}
      'missing-source19' {$facts.Remove('Source19ForwardHistory')}
    }
    Assert-RepairContract ((Test-OctoberCompatibilityStageFacts $facts) -eq ($mode -ceq 'valid')) ('Source21 final stage discriminator changed: '+$mode)
    $count++
  }
  return $count
}

function Invoke-OctoberCompatibilityForwardConsumerProbes {
  # Execute the actual final-admission assertion from each consumer. Future
  # qualifier results are labelled mocks, never genuine published admission.
  $original=Get-OctoberCompatibilityHistoryStage '737eea29357d5f42375b865754f3762f10545e37'
  $count=0
  foreach($consumer in @(
      @{Owner='scripts/check-codex-subagent-coordination-policy.ps1';Message='Final compatibility integration rejects E/G/C/L or incomplete source qualification.'},
      @{Owner='scripts/check-cross-agent-incremental-ticket-gate.ps1';Message='Compatibility handoff requires the exact published forward Q and complete native qualification; intermediate phases remain blocked.'})) {
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root $consumer.Owner),[ref]$tokens,[ref]$errors)
    Assert-RepairContract ($errors.Count -eq 0) 'actual admission consumer parse failed.'
    $nodes=@($ast.FindAll({param($node)
      $node -is [Management.Automation.Language.CommandAst] -and $node.CommandElements.Count -ge 2 -and
      $node.CommandElements[-1] -is [Management.Automation.Language.StringConstantExpressionAst] -and
      $node.CommandElements[-1].Value -ceq $consumer.Message
    },$true))
    Assert-RepairContract ($nodes.Count -eq 1) 'actual admission consumer assertion missing/duplicated.'
    $statement=[scriptblock]::Create($nodes[0].Extent.Text)
    foreach($probe in @(
        @{Name='actual-source17';History=$original;Verified=$true;Expected=$false;Calls=0},
        @{Name='forward-metadata';History=@{Stage=19;PhaseStage=17;Forward=$true;Head=('a'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='forward-capture';History=@{Stage=20;PhaseStage=18;Forward=$true;Head=('b'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='old-qualified-count';History=@{Stage=19;PhaseStage=19;Forward=$false;Head=('c'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='qualified-without-proof';History=@{Stage=21;PhaseStage=19;Forward=$true;Head=('c'*40)};Verified=$false;Expected=$false;Calls=1},
        @{Name='qualified-mechanism';History=@{Stage=21;PhaseStage=19;Forward=$true;Head=('c'*40)};Verified=$true;Expected=$true;Calls=1},
        @{Name='wrong-qualified-phase';History=@{Stage=21;PhaseStage=18;Forward=$true;Head=('c'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='current-metadata';History=@{Stage=21;PhaseStage=17;Forward=$true;CaptureIndex=21;Head=('d'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='current-capture';History=@{Stage=22;PhaseStage=18;Forward=$true;CaptureIndex=21;Head=('e'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='current-qualified-without-proof';History=@{Stage=23;PhaseStage=19;Forward=$true;CaptureIndex=21;Head=('f'*40)};Verified=$false;Expected=$false;Calls=1},
        @{Name='current-qualified-mechanism';History=@{Stage=23;PhaseStage=19;Forward=$true;CaptureIndex=21;Head=('f'*40)};Verified=$true;Expected=$true;Calls=1},
        @{Name='corrected-metadata-forged-phase';History=@{Stage=23;PhaseStage=19;Forward=$true;ContractIndex=22;CaptureIndex=23;Head=('d'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='corrected-capture';History=@{Stage=24;PhaseStage=18;Forward=$true;ContractIndex=22;CaptureIndex=23;Head=('e'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='corrected-qualified-without-proof';History=@{Stage=25;PhaseStage=19;Forward=$true;ContractIndex=22;CaptureIndex=23;Head=('f'*40)};Verified=$false;Expected=$false;Calls=1},
        @{Name='corrected-qualified-mechanism';History=@{Stage=25;PhaseStage=19;Forward=$true;ContractIndex=22;CaptureIndex=23;Head=('f'*40)};Verified=$true;Expected=$true;Calls=1},
        @{Name='source25-qualified-mechanism';History=@{Stage=29;PhaseStage=19;Forward=$true;ContractIndex=26;CaptureIndex=27;QualificationIndex=28;Head=('f'*40)};Verified=$true;Expected=$true;Calls=1},
        @{Name='source27-evaluator-not-qualified';History=@{Stage=29;PhaseStage=18;Forward=$true;ContractIndex=26;CaptureIndex=27;QualificationIndex=29;Head=('e'*40)};Verified=$true;Expected=$false;Calls=0},
        @{Name='source27-qualified-without-proof';History=@{Stage=30;PhaseStage=19;Forward=$true;ContractIndex=26;CaptureIndex=27;QualificationIndex=29;Head=('f'*40)};Verified=$false;Expected=$false;Calls=1},
        @{Name='source27-qualified-mechanism';History=@{Stage=30;PhaseStage=19;Forward=$true;ContractIndex=26;CaptureIndex=27;QualificationIndex=29;Head=('f'*40)};Verified=$true;Expected=$true;Calls=1},
        @{Name='source27-wrong-qualification-index';History=@{Stage=30;PhaseStage=19;Forward=$true;ContractIndex=26;CaptureIndex=27;QualificationIndex=28;Head=('f'*40)};Verified=$true;Expected=$false;Calls=0})) {
      if(-not $probe.History.ContainsKey('CaptureIndex')){$probe.History.CaptureIndex=19}
      if(-not $probe.History.ContainsKey('QualificationIndex')){$probe.History.QualificationIndex=$probe.History.CaptureIndex+1}
      & {
        $observations=@{Calls=0;WrongHead=$false};$qualifiedHistory=$probe.History;$compatibilityHistory=$probe.History
        function Assert-Coordination([bool]$Condition,[string]$Message) {
          if(-not $Condition){throw ('Labelled consumer rejection: '+$Message)}
        }
        function Assert-IncrementalTicket([bool]$Condition,[string]$Message) {
          if(-not $Condition){throw ('Labelled consumer rejection: '+$Message)}
        }
        function Test-OctoberCompatibilityPublishedForwardCheckpoint([string]$ExpectedHead) {
          $observations.Calls++;if($ExpectedHead -cne $probe.History.Head){$observations.WrongHead=$true}
          return [bool]$probe.Verified
        }
        $accepted=$false;$reason=''
        try {& $statement;$accepted=$true}catch{$reason=$_.Exception.Message}
        Assert-RepairContract ($accepted -eq $probe.Expected -and $observations.Calls -eq $probe.Calls -and
          -not $observations.WrongHead -and ($accepted -or $reason -ceq ('Labelled consumer rejection: '+$consumer.Message))) ('actual consumer boundary mismatch: '+$consumer.Owner+' / '+$probe.Name+'; '+$reason)
      }
      $count++
    }
  }
  return $count
}

if($RequireSource19FullDependencyProbes) {
  Assert-RepairContract (-not $RequireQualifiedGraph -and -not $RequireOctoberSourceAdmission -and
    -not $RequireOctoberBootstrapProbes -and -not $RequireCompatibilityStageProbes -and
    -not $RequireCompatibilityLiveAdmissionProbes -and -not $RequireCurrentSelectionAggregationProbes -and
    -not $RequireCurrentPrimaryReviewBindingProbes -and -not $RequireCurrentPrimaryAssertionReviewProbes -and
    -not $RequireCurrentPrimaryVisualReviewProbes -and -not $RequireSource17ForwardAmendmentProbes -and
    -not $RequireSource19ForwardAmendmentProbes -and -not $RequireSource21ForwardAmendmentProbes -and -not $CaptureCompatibilityReport -and
    $CaptureExecutionId -ceq 'default' -and $CaptureMode -ceq 'behavior_only') 'dependency probes require standalone noncapture mode.'
  Invoke-OctoberCompatibilitySource19FullDependencyProbes
  return
}

if($RequireSource17ForwardAmendmentProbes -or $RequireSource19ForwardAmendmentProbes -or $RequireSource21ForwardAmendmentProbes) {
  Assert-RepairContract (@($RequireSource17ForwardAmendmentProbes,$RequireSource19ForwardAmendmentProbes,$RequireSource21ForwardAmendmentProbes|Where-Object {$_}).Count -eq 1 -and -not $RequireSource19FullDependencyProbes) 'select exactly one forward reader probe mode.'
  Assert-RepairContract (-not $RequireQualifiedGraph -and -not $RequireOctoberSourceAdmission -and
    -not $RequireOctoberBootstrapProbes -and -not $RequireCompatibilityStageProbes -and
    -not $RequireCompatibilityLiveAdmissionProbes -and -not $RequireCurrentSelectionAggregationProbes -and
    -not $RequireCurrentPrimaryReviewBindingProbes -and -not $RequireCurrentPrimaryAssertionReviewProbes -and
    -not $RequireCurrentPrimaryVisualReviewProbes -and -not $CaptureCompatibilityReport -and
    $CaptureExecutionId -ceq 'default' -and $CaptureMode -ceq 'behavior_only') 'forward reader probes require standalone noncapture mode.'
  $forwardTokens=$null;$forwardErrors=$null
  $forwardAst=[Management.Automation.Language.Parser]::ParseFile($checkerPath,[ref]$forwardTokens,[ref]$forwardErrors)
  Assert-RepairContract ($forwardErrors.Count -eq 0) 'forward reader checker parse errors.'
  foreach($name in @('Assert-Coordination','Get-OctoberCompatibilityBinding',
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityAmendmentOwners',
      'Get-OctoberCompatibilityLayoutOwners','Get-OctoberCompatibilityHandoverOwners',
      'Get-OctoberCompatibilityCoverageCartOwners','Get-OctoberCompatibilityInheritedCartTestOwners',
      'Get-OctoberCompatibilityRetentionOwners','Get-OctoberCompatibilityScrollRepairOwners',
      'Read-OctoberCompatibilityTestAdmissionContract','Read-OctoberCompatibilityScopeRepairAdmission',
      'Read-OctoberCompatibilityClaimHandoff','Get-OctoberCompatibilityClaimHandoff','Get-OctoberCompatibilityHistoryStage',
      'Read-OctoberCompatibilityCurrentQualificationProof','Read-OctoberCompatibilityCurrentQualificationContract',
      'Read-OctoberCompatibilityCurrentSuccessorSpecification','Read-OctoberCompatibilitySource17ForwardAmendment',
      'Read-OctoberCompatibilitySource19ForwardAmendment',
      'Read-OctoberCompatibilitySource21ForwardAmendment',
      'Read-OctoberCompatibilitySource23ForwardAmendment',
      'Read-OctoberCompatibilitySource25ForwardAmendment',
      'Read-OctoberCompatibilitySource27ForwardAmendment',
      'Read-OctoberCompatibilitySource28ForwardAmendment',
      'Test-OctoberCompatibilityStageFacts',
      'Read-OctoberCompatibilityJsonObject','Get-OctoberCompatibilityByteHash','Get-OctoberCompatibilityGitLines')) {
    $nodes=@($forwardAst.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    Assert-RepairContract ($nodes.Count -eq 1) ('missing/duplicate forward reader dependency '+$name)
    . ([scriptblock]::Create($nodes[0].Extent.Text))
  }
  & {
    # Actual hash/type/source-selection readers; only Git document transport is
    # labelled mocked. These probes grant no live admission or qualification.
    $document=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
    $positive=Read-OctoberCompatibilitySource17ForwardAmendment -FromWorkingTree
    Assert-RepairContract ($null -ne $positive) 'exact working forward append rejected.'
    $count=1;$probeText=$document;$observations=@{Reads=0;Expected='';Unexpected=$false}
    function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
      $observations.Reads++
      if(($Arguments -join '|') -cne $observations.Expected){$observations.Unexpected=$true;throw 'Wrong forward document source.'}
      return $probeText
    }
    foreach($selection in @('index','commit')) {
      $observations.Expected=if($selection -ceq 'index'){'show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}else{'show|'+('a'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'}
      $observations.Reads=0;$observations.Unexpected=$false
      $result=if($selection -ceq 'index'){Read-OctoberCompatibilitySource17ForwardAmendment -FromIndex}else{Read-OctoberCompatibilitySource17ForwardAmendment -Commit ('a'*40)}
      Assert-RepairContract ($null -ne $result -and $observations.Reads -eq 3 -and -not $observations.Unexpected) 'forward reader selected wrong source or skipped original contract validation.'
      $count++
    }
    $block=[regex]::Match($document,'(?s)<!-- COMPATIBILITY_SOURCE17_FORWARD_AMENDMENT_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SOURCE17_FORWARD_AMENDMENT_JSON_END -->')
    $observations.Expected='show|:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'
    foreach($property in $positive.PSObject.Properties.Name) {
      $changed=$positive|ConvertTo-Json -Depth 40 -Compress|ConvertFrom-Json
      $changed.PSObject.Properties[$property].Value='altered'
      $probeText=$document.Replace($block.Groups[1].Value,($changed|ConvertTo-Json -Depth 40 -Compress))
      $observations.Reads=0;$observations.Unexpected=$false
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment -FromIndex) -and
        $observations.Reads -eq 3 -and -not $observations.Unexpected) ('altered forward property admitted: '+$property)
      $count++
    }
    foreach($candidate in @($document.Replace($block.Value,''),($document+"`n"+$block.Value),
        $document.Replace($block.Groups[1].Value,'{malformed}'),
        $document.Replace('current_successor_and_qualification_specification_not_admission','altered-original-spec'),
        $document.Replace('current_frontend_qualification_contract_not_qualification','altered-original-contract'))) {
      $probeText=$candidate;$observations.Reads=0;$observations.Unexpected=$false
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment -FromIndex) -and
        -not $observations.Unexpected) 'missing/duplicate/malformed forward append or changed original contract admitted.'
      $count++
    }
    $probeText=$document;$observations.Reads=0;$observations.Unexpected=$false
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment)) 'missing forward source selector admitted.';$count++
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment -FromWorkingTree -FromIndex)) 'mixed forward source selectors admitted.';$count++
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment -Commit ('a'*40) -FromIndex)) 'mixed forward commit/index admitted.';$count++
    Assert-RepairContract ($null -eq (Read-OctoberCompatibilitySource17ForwardAmendment -Commit 'bad')) 'invalid forward commit admitted.';$count++
    Assert-RepairContract ($observations.Reads -eq 0 -and -not $observations.Unexpected) 'invalid forward selector reached Git transport.'
    [pscustomobject]@{Source17ForwardReaderCases=$count;LabelledGitDocumentMocks=$true;
      LiveAdmission=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
  }
  $historyCases=Invoke-OctoberCompatibilityForwardHistoryProbes
  if($RequireSource21ForwardAmendmentProbes) {
    $current=Get-OctoberCompatibilityHistoryStage '43ea27a81e7c1876abc0df15b39342da96b63c10'
    Assert-RepairContract ($current.Stage -eq 22 -and $current.PhaseStage -eq 16 -and $current.Source21Preparation -and -not $current.Source21Forward) 'Actual Source21 is preparation only, not qualified.'
    $source21HistoryCases=Invoke-OctoberCompatibilitySource21HistoryProbes
    $source21ReaderCases=Invoke-OctoberCompatibilitySource21ReaderProbes
    $source21FinalCases=Invoke-OctoberCompatibilitySource21FinalStageProbes
    [pscustomobject]@{Source21HistoryCases=$source21HistoryCases;Source21ReaderCases=$source21ReaderCases;Source21FinalStageCases=$source21FinalCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $source23HistoryCases=Invoke-OctoberCompatibilitySource23HistoryProbes
    $source23ReaderCases=Invoke-OctoberCompatibilitySource23ReaderProbes
    $source23FinalCases=Invoke-OctoberCompatibilitySource23FinalStageProbes
    [pscustomobject]@{Source23HistoryCases=$source23HistoryCases;Source23ReaderCases=$source23ReaderCases;Source23FinalStageCases=$source23FinalCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $source25HistoryCases=Invoke-OctoberCompatibilitySource25HistoryProbes
    $source25ReaderCases=Invoke-OctoberCompatibilitySource25ReaderProbes
    $source25FinalCases=Invoke-OctoberCompatibilitySource25FinalStageProbes
    [pscustomobject]@{Source25HistoryCases=$source25HistoryCases;Source25ReaderCases=$source25ReaderCases;Source25FinalStageCases=$source25FinalCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $source27HistoryCases=Invoke-OctoberCompatibilitySource27HistoryProbes
    [pscustomobject]@{Source27HistoryCases=$source27HistoryCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $source28HistoryCases=Invoke-OctoberCompatibilitySource28HistoryProbes
    [pscustomobject]@{Source28HistoryCases=$source28HistoryCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $source28FinalCases=Invoke-OctoberCompatibilitySource28FinalStageProbes
    [pscustomobject]@{Source28FinalStageCases=$source28FinalCases;LabelledFactsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
    $qualificationCountCases=Invoke-OctoberCompatibilityQualificationCountDispatchProbes
    [pscustomobject]@{QualificationCountDispatchCases=$qualificationCountCases;HistoryAndSourceStateMocked=$true;SentinelRejectsQualification=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
  }
  if($RequireSource19ForwardAmendmentProbes) {
    $current=Get-OctoberCompatibilityHistoryStage '51b3dc076ab10ff4f233a420791e4d2b25d2512a'
    Assert-RepairContract ($current.Stage -eq 20 -and $current.PhaseStage -eq 16 -and $current.Source19Preparation -and -not $current.Source19Forward) 'Actual Source19 is preparation only, not qualified.'
    $source19HistoryCases=Invoke-OctoberCompatibilitySource19HistoryProbes
    [pscustomobject]@{Source19HistoryCases=$source19HistoryCases;ActualSealedPrefixRead=$true;FutureObjectsMocked=$true;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
  }
  [pscustomobject]@{ForwardHistoryCases=$historyCases;LabelledFutureGitObjects=$true;SealedPrefixReadFromGit=$true;
    LiveAdmission=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
  $consumerCases=Invoke-OctoberCompatibilityForwardConsumerProbes
  [pscustomobject]@{ActualConsumerAssertionCases=$consumerCases;LabelledQualifierMocks=$true;ActualSource17Rejected=$true;
    LiveAdmission=$false;QualificationPassed=$false;ApkAuthority=$false}|ConvertTo-Json -Compress
  return
}

Assert-RepairContract ($CaptureCompatibilityReport -or $CaptureExecutionId -ceq 'default') 'execution selection requires capture mode.'
if($RequireCurrentSelectionAggregationProbes -or $RequireCurrentPrimaryReviewBindingProbes -or $RequireCurrentPrimaryAssertionReviewProbes -or $RequireCurrentPrimaryVisualReviewProbes) {
  Assert-RepairContract (-not $RequireQualifiedGraph -and -not $RequireOctoberSourceAdmission -and
    -not $RequireOctoberBootstrapProbes -and -not $RequireCompatibilityStageProbes -and
    -not $RequireCompatibilityLiveAdmissionProbes -and -not $CaptureCompatibilityReport -and
    $CaptureMode -ceq 'behavior_only') 'current aggregation probes require standalone noncapture mode.'
  Assert-RepairContract (@($RequireCurrentSelectionAggregationProbes,$RequireCurrentPrimaryReviewBindingProbes,$RequireCurrentPrimaryAssertionReviewProbes,$RequireCurrentPrimaryVisualReviewProbes|Where-Object {$_}).Count -eq 1) 'select exactly one focused probe mode.'
}

if ($RequireCompatibilityStageProbes -or $RequireCompatibilityLiveAdmissionProbes -or $CaptureCompatibilityReport -or $RequireCurrentSelectionAggregationProbes -or $RequireCurrentPrimaryReviewBindingProbes -or $RequireCurrentPrimaryAssertionReviewProbes -or $RequireCurrentPrimaryVisualReviewProbes) {
  $tokens=$null; $errors=$null
  $ast=[System.Management.Automation.Language.Parser]::ParseFile(
    $checkerPath,[ref]$tokens,[ref]$errors)
  Assert-RepairContract ($errors.Count -eq 0) 'checker has parse errors.'
  foreach ($name in @('Get-OctoberCompatibilityBinding',
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityAmendmentOwners','Get-OctoberCompatibilityLayoutOwners','Get-OctoberCompatibilityHandoverOwners','Get-OctoberCompatibilityCoverageCartOwners','Get-OctoberCompatibilityInheritedCartTestOwners','Get-OctoberCompatibilityRetentionOwners','Get-OctoberCompatibilityForwardLayoutTestOwners','Get-OctoberCompatibilityScrollRepairOwners','Read-OctoberCompatibilityTestAdmissionContract','Test-OctoberCompatibilityBindingInventory',
      'Test-OctoberCompatibilityStageFacts','Test-OctoberCompatibilityIntegrationIdentity','Assert-Coordination',
      'Get-OctoberCoverageBoundHash','New-OctoberCoverageMutex','Test-OctoberCoveragePreparation','Test-OctoberHandoverPreparation',
      'Get-OctoberCompatibilityGitLines','Get-OctoberCompatibilityHistoryStage','Read-OctoberCompatibilityScopeRepairAdmission',
      'Test-OctoberCompatibilityQualification','Test-OctoberCompatibilityHistoricalQualificationCore','Get-OctoberCompatibilityComparatorIdentity','Test-OctoberCompatibilityCaptureComparator','Test-OctoberCompatibilityVisualQualification','Test-OctoberCompatibilityLegacyQualification','Read-OctoberCompatibilityExecutionCoverage','Read-OctoberCompatibilityVisualManifestBinding','Test-OctoberCompatibilityVisualEvidenceShape','Read-OctoberCompatibilityVisualArtifactBytes','Read-OctoberCompatibilityJsonObject','Get-OctoberCompatibilityQualificationExecutions','Read-OctoberCompatibilityExecutionEvents','Read-OctoberCompatibilityExecutionEvidence','Get-OctoberCompatibilityByteHash','Read-OctoberCompatibilityReportEvents',
      'Read-OctoberCompatibilityClaimHandoff','Get-OctoberCompatibilityClaimHandoff','Read-OctoberCompatibilityDerivedClaims',
      'Get-OctoberCompatibilityReportPlan','Get-OctoberCompatibilityExecutionPlan','Get-OctoberCompatibilityCurrentExecutionPlan','Test-OctoberCompatibilityCapture',
      'Read-OctoberCompatibilityCurrentQualificationContract','Read-OctoberCompatibilityCurrentSuccessorSpecification',
      'Read-OctoberCompatibilitySource17ForwardAmendment',
      'Read-OctoberCompatibilitySource19ForwardAmendment',
      'Read-OctoberCompatibilitySource21ForwardAmendment',
      'Test-OctoberCompatibilitySource21Preparation','Test-OctoberCompatibilitySource21CurrentPreparation',
      'Read-OctoberCompatibilitySource23ForwardAmendment',
      'Test-OctoberCompatibilitySource23Preparation','Test-OctoberCompatibilitySource23CurrentPreparation',
      'Read-OctoberCompatibilitySource25ForwardAmendment',
      'Test-OctoberCompatibilitySource25Preparation','Test-OctoberCompatibilitySource25CurrentPreparation',
      'Read-OctoberCompatibilitySource27ForwardAmendment',
      'Read-OctoberCompatibilitySource28ForwardAmendment',
      'Test-OctoberCompatibilitySource27Preparation','Test-OctoberCompatibilitySource27CurrentPreparation',
      'Test-OctoberCompatibilitySource28Preparation','Test-OctoberCompatibilitySource28CurrentPreparation',
      'Read-OctoberCompatibilityCurrentSourceState','Read-OctoberCompatibilityCurrentCaptureSource',
      'Test-OctoberCompatibilityCurrentGeometry','Read-OctoberCompatibilityCurrentSelectedRiskBindings',
      'Read-OctoberCompatibilityCurrentRiskInventoryBuffer','Read-OctoberCompatibilityCurrentRiskInventoryFile',
      'New-OctoberCompatibilityCurrentSelectionContext','Read-OctoberCompatibilityCurrentSelectionContextFile',
      'Test-OctoberCompatibilityCurrentSelectionEventSequence',
      'Test-OctoberCompatibilityCurrentExecutionReceipt','Read-OctoberCompatibilityCurrentTestSourceLocation',
      'Read-OctoberCompatibilityCurrentExecutionEvents','Read-OctoberCompatibilityCurrentExecutionEvidence',
      'Read-OctoberCompatibilityCurrentRetainedSelectionBindings',
      'Read-OctoberCompatibilityCurrentSelectedRecorderEvents',
      'Read-OctoberCompatibilityCurrentRecorderArtifactBytes',
      'Read-OctoberCompatibilityCurrentRecorderGeometry',
      'Read-OctoberCompatibilityCurrentSelectedRenderBindings',
      'Read-OctoberCompatibilityCurrentCombinedOriginalFilePins',
      'Read-OctoberCompatibilityCurrentPrimaryReviewBinding',
      'Read-OctoberCompatibilityCurrentObligationJoins','Initialize-Source27NamedCallbackTokenizer','Test-Source27NamedCallbackBinding','Read-OctoberCompatibilityCurrentPrimaryAssertionReview',
      'Read-OctoberCompatibilityCurrentPrimaryVisualReview',
      'Read-OctoberCompatibilityCurrentVisualSlotAccounting',
      'Read-OctoberCompatibilityCurrentPresentationReview',
      'Read-OctoberCompatibilityCurrentQualifiedEvidence',
      'Read-OctoberCompatibilityCurrentQualificationProof','Read-OctoberCompatibilityCurrentCycles','Read-OctoberCompatibilityCurrentSkippedCoverage',
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
  if($RequireCurrentPrimaryVisualReviewProbes) {
    $beforeSpec=(Get-Command Read-OctoberCompatibilityCurrentSuccessorSpecification -CommandType Function).ScriptBlock.ToString()
    $beforeContract=(Get-Command Read-OctoberCompatibilityCurrentQualificationContract -CommandType Function).ScriptBlock.ToString()
    $beforePresentationHash=(Get-Command Get-OctoberCoverageBoundHash -CommandType Function).ScriptBlock.ToString()
    $beforePresentationOpen=(Get-Command Open-OctoberCompatibilityVisualArtifact -CommandType Function).ScriptBlock.ToString()
    $output=@(Invoke-OctoberCompatibilityCurrentPrimaryVisualReviewProbes)
    Assert-RepairContract ($output.Count -eq 1 -and
      (Get-Command Read-OctoberCompatibilityCurrentSuccessorSpecification -CommandType Function).ScriptBlock.ToString() -ceq $beforeSpec -and
      (Get-Command Read-OctoberCompatibilityCurrentQualificationContract -CommandType Function).ScriptBlock.ToString() -ceq $beforeContract -and
      (Get-Command Get-OctoberCoverageBoundHash -CommandType Function).ScriptBlock.ToString() -ceq $beforePresentationHash -and
      (Get-Command Open-OctoberCompatibilityVisualArtifact -CommandType Function).ScriptBlock.ToString() -ceq $beforePresentationOpen) 'visual review probes leaked mocks/output.'
    Write-Output $output[0]
    return
  }
  if($RequireCurrentPrimaryAssertionReviewProbes) {
    $beforeJoins=(Get-Command Read-OctoberCompatibilityCurrentObligationJoins -CommandType Function).ScriptBlock.ToString()
    $beforeGit=(Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock.ToString()
    $output=@(Invoke-OctoberCompatibilityCurrentPrimaryAssertionReviewProbes)
    Assert-RepairContract ($output.Count -eq 1 -and
      (Get-Command Read-OctoberCompatibilityCurrentObligationJoins -CommandType Function).ScriptBlock.ToString() -ceq $beforeJoins -and
      (Get-Command Get-OctoberCompatibilityGitLines -CommandType Function).ScriptBlock.ToString() -ceq $beforeGit) 'assertion review probes leaked mocks/output.'
    Write-Output $output[0]
    return
  }
  if($RequireCurrentPrimaryReviewBindingProbes) {
    $beforeOpen=(Get-Command Open-OctoberCompatibilityVisualArtifact -CommandType Function).ScriptBlock.ToString()
    $beforeHash=(Get-Command Get-OctoberCoverageBoundHash -CommandType Function).ScriptBlock.ToString()
    $output=@(Invoke-OctoberCompatibilityCurrentPrimaryReviewBindingProbes)
    Assert-RepairContract ($output.Count -eq 1 -and
      (Get-Command Open-OctoberCompatibilityVisualArtifact -CommandType Function).ScriptBlock.ToString() -ceq $beforeOpen -and
      (Get-Command Get-OctoberCoverageBoundHash -CommandType Function).ScriptBlock.ToString() -ceq $beforeHash) 'primary review probes leaked mocks/output.'
    Write-Output $output[0]
    return
  }
  if($RequireCurrentSelectionAggregationProbes) {
    $productionMocks=@{}
    foreach($probeName in @('Get-OctoberCompatibilityBinding','Get-OctoberCoverageBoundHash',
      'Read-OctoberCompatibilityCurrentSuccessorSpecification','Read-OctoberCompatibilityCurrentQualificationContract','Open-OctoberCompatibilityVisualArtifact',
      'Read-OctoberCompatibilityCurrentExecutionEvents','Read-OctoberCompatibilityCurrentSelectionContextFile','Read-OctoberCompatibilityCurrentSelectedRenderBindings',
      'Read-OctoberCompatibilityCurrentRecorderArtifactBytes')) {
      $productionMocks[$probeName]=(Get-Command $probeName -CommandType Function).ScriptBlock.ToString()
    }
    $probeOutput=@(Invoke-OctoberCompatibilityCurrentSelectionAggregationProbes)
    foreach($probeName in $productionMocks.Keys) {
      Assert-RepairContract ((Get-Command $probeName -CommandType Function).ScriptBlock.ToString() -ceq $productionMocks[$probeName]) 'aggregation probe leaked a production mock.'
    }
    Assert-RepairContract ($probeOutput.Count -eq 1 -and (Get-OctoberCompatibilityBinding).worktreePath -ceq $binding.worktreePath) 'aggregation probe changed binding or output inventory.'
    Write-Output $probeOutput[0]
    return
  }
  if($RequireCompatibilityStageProbes) {
    $resolutionText=[IO.File]::ReadAllText((Join-Path $root 'docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))
    & {
      $scopeContract=Read-OctoberCompatibilityScopeRepairAdmission -FromWorkingTree
      Assert-RepairContract ($null -ne $scopeContract) 'exact working scoped repair contract rejected.'
      $scopeCases=1;$scopeReadText=$resolutionText
      $scopeReadContext=@{Expected=@();Count=0;Unexpected=$false}
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $scopeReadContext.Count++
        if(($Arguments -join '|') -cne ($scopeReadContext.Expected -join '|')){
          $scopeReadContext.Unexpected=$true;throw 'Unexpected scope contract source query.'
        }
        return $scopeReadText
      }
      foreach($selection in @('index','commit')) {
        $expected=if($selection -ceq 'index'){@('show',':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')}
          else{@('show',(('a'*40)+':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md'))}
        $scopeReadContext.Expected=$expected;$scopeReadContext.Count=0;$scopeReadContext.Unexpected=$false
        $result=if($selection -ceq 'index'){Read-OctoberCompatibilityScopeRepairAdmission -FromIndex}
          else{Read-OctoberCompatibilityScopeRepairAdmission -Commit ('a'*40)}
        Assert-RepairContract ($null -ne $result -and $scopeReadContext.Count -eq 1 -and -not $scopeReadContext.Unexpected) 'scope reader selected wrong source or made extra reads.'
        $scopeCases++
      }
      $scopeReadContext.Expected=@('show',':docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
      $scopeBlock=[regex]::Match($resolutionText,'(?s)<!-- COMPATIBILITY_SCOPE_REPAIR_JSON_BEGIN -->\s*(.*?)\s*<!-- COMPATIBILITY_SCOPE_REPAIR_JSON_END -->')
      foreach($property in $scopeContract.PSObject.Properties.Name) {
        $changed=$scopeContract|ConvertTo-Json -Depth 100 -Compress|ConvertFrom-Json
        $changed.PSObject.Properties[$property].Value='altered'
        $scopeReadText=$resolutionText.Replace($scopeBlock.Groups[1].Value,($changed|ConvertTo-Json -Depth 100 -Compress))
        $scopeReadContext.Count=0;$scopeReadContext.Unexpected=$false
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityScopeRepairAdmission -FromIndex) -and
          $scopeReadContext.Count -eq 1 -and -not $scopeReadContext.Unexpected) 'mutated scoped repair contract admitted or wrong read concealed.';$scopeCases++
      }
      foreach($text in @($resolutionText.Replace($scopeBlock.Value,''),($resolutionText+"`n"+$scopeBlock.Value),
          $resolutionText.Replace($scopeBlock.Groups[1].Value,'{malformed}'))) {
        $scopeReadText=$text
        $scopeReadContext.Count=0;$scopeReadContext.Unexpected=$false
        Assert-RepairContract ($null -eq (Read-OctoberCompatibilityScopeRepairAdmission -FromIndex) -and
          $scopeReadContext.Count -eq 1 -and -not $scopeReadContext.Unexpected) 'missing/duplicate/malformed scope contract admitted or wrong read concealed.';$scopeCases++
      }
      $scopeReadText=$resolutionText
      $scopeReadContext.Count=0;$scopeReadContext.Unexpected=$false
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityScopeRepairAdmission -FromIndex -FromWorkingTree)) 'conflicting scope source selection admitted.';$scopeCases++
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityScopeRepairAdmission -FromIndex -Commit ('a'*40))) 'mixed scope index/commit selection admitted.';$scopeCases++
      Assert-RepairContract ($null -eq (Read-OctoberCompatibilityScopeRepairAdmission -Commit 'bad')) 'invalid scope commit admitted.';$scopeCases++
      Assert-RepairContract ($scopeReadContext.Count -eq 0 -and -not $scopeReadContext.Unexpected) 'invalid selection reached a document/Git reader.'
      foreach($stage in @(14,15,16,17,18)) {
        foreach($working in @($false,$true)) {
          Assert-RepairContract (-not(Test-OctoberCompatibilityQualification @{Stage=$stage;Commits=@();Head=('a'*40)} -FromWorkingTree:$working)) 'intermediate qualification boundary admitted source.';$scopeCases++
        }
      }
      Assert-RepairContract ($scopeCases -eq 35) 'scope repair contract/boundary fixture inventory changed.'
      Write-Output "Compatibility scoped repair: $scopeCases exact payload/source-selection and blocked qualification cases passed; no live admission or app qualification."
    }
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
        'N-positive','T-positive','Q-stage16-handoff-denied','N-unverified','N-coerced','N-missing-proof','N-empty-contract',
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
          'Q-stage16-handoff-denied' {$claimFixtureContext.Stage=16;$claimFixtureContext.Phase='handoff'}
          'N-unverified' {$claimFixtureContext.ImmutableNVerified=$false}
          'N-coerced' {$claimFixtureContext.ImmutableNVerified='true'}
          'N-missing-proof' {$claimFixtureContext.Remove('ImmutableNVerified')}
          'N-empty-contract' {$claimFixtureTestCandidate=''}
          'N-altered-contract' {$claimFixtureTestCandidate=$claimFixtureNJson.Replace('specified_test_addition_not_active_until_committed_N','unapproved_test_addition')}
          'N-as-L' {$claimFixtureContext.NCommit='0da3630d1c857390c173ec83ba5c0210cb1e5ec2'}
          'N-draft-pre-N' {$claimFixtureContext.Stage=8}
          'N-premature-handoff' {$claimFixtureContext.Phase='handoff'}
          'Q-implementation' {$claimFixtureContext.Stage=16}
          'T-unrelated-owner' {$claimFixtureContext.Stage=10;$claimFixtureClaims[1].owners+=@('extra.dart')}
        }
        $claimFixtureBefore=$claimFixtureClaims|ConvertTo-Json -Depth 30 -Compress
        $claimFixtureResult=@(Read-OctoberCompatibilityDerivedClaims -Claims $claimFixtureClaims -ContractJson $claimFixtureCandidate -Context $claimFixtureContext -TestAdmissionJson $claimFixtureTestCandidate)
        # Metadata-only Stage16 cannot hand off. Keep this original fixture as
        # a denial case; current Stage19 qualification needs a separate positive
        # composition after the operative Q4 path is complete, before publication.
        $claimFixtureAccepted=$claimFixtureMode -cin @('positive','N-positive','T-positive')
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
      # Same actual-statement harness as K, now for the scoped B25 continuation.
      $scopeBlocks=@{}
      foreach($selection in @(
          @('facts14','$compatibilityFacts.ScopePreparationVerified=Test-OctoberCompatibilityScopePreparation $ProductionPhase'),
          @('facts15','$compatibilityFacts.ScopeRepairAdmissionVerified=$null -ne'),
          @('owner','$octoberCoveragePreservedOwner=@(Get-OctoberCompatibilityScrollRepairOwners) -ccontains $changedOwner'),
          @('inventory','Scope amendment precommit must stage exact metadata4'),
          @('late','Scoped repair amendment requires fresh independent B25 preservation'))) {
        $needle=$selection[1]
        $nodes=@($ast.FindAll({param($n)
          $n -is [System.Management.Automation.Language.IfStatementAst] -and
          $n.Extent.Text.Contains($needle) -and $n.Extent.Text.Length -lt 2000
        },$true))
        Assert-RepairContract ($nodes.Count -eq 1) ('ambiguous/missing scope dispatch '+$selection[0])
        $scopeBlocks[$selection[0]]=[scriptblock]::Create($nodes[0].Extent.Text)
      }
      $scopeDispatch=@{Preparation=$true;Contract=$true;Calls=@();Reads=@()}
      function Test-OctoberCompatibilityScopePreparation([string]$Phase) {
        $scopeDispatch.Calls+=@($Phase);return $scopeDispatch.Preparation
      }
      function Read-OctoberCompatibilityScopeRepairAdmission {
        param([string]$Commit,[switch]$FromIndex,[switch]$FromWorkingTree)
        $scopeDispatch.Reads+=@($(if($FromIndex){'index'}elseif($FromWorkingTree){'working'}else{'commit:'+ $Commit}))
        if($scopeDispatch.Contract){return @{predecessorCommit='b25e5913d088cc49b8c0fe40623cef49778e462a'}}
        return $null
      }
      function Assert-Coordination([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
      $scopeDispatchCases=0
      foreach($phase in @('implementation','pre_commit')) {
        $compatibilityHistory=@{Stage=14;Commits=@()};$ProductionPhase=$phase;$compatibilityFacts=@{}
        $scopeDispatch.Calls=@();$scopeDispatch.Reads=@()
        . $scopeBlocks.facts14
        Assert-RepairContract ($compatibilityFacts.ScopePreparationVerified -eq $true -and
          $compatibilityFacts.ScopeContractVerified -eq $true -and
          ($scopeDispatch.Calls -join '|') -ceq $phase -and
          ($scopeDispatch.Reads -join '|') -ceq $(if($phase -ceq 'pre_commit'){'index'}else{'working'})) 'scope facts chose wrong proof/source.'
        $scopeDispatchCases++
      }
      $compatibilityHistory=@{Stage=15;Commits=@(('0'*40))*14+@('a'*40)};$ProductionPhase='implementation';$compatibilityFacts=@{}
      $scopeDispatch.Reads=@();. $scopeBlocks.facts15
      Assert-RepairContract ($compatibilityFacts.ScopeRepairAdmissionVerified -eq $true -and
        ($scopeDispatch.Reads -join '|') -ceq ('commit:'+('a'*40))) 'repair facts did not read immutable admission at index14.';$scopeDispatchCases++
      $staged=@(Get-OctoberCompatibilityAmendmentOwners);$frozen=@(Get-OctoberCompatibilityScrollRepairOwners)
      foreach($mode in @('positive','missing-staged','extra-staged','staged-app','missing-dashboard','missing-layout',
          'extra-unstaged','untracked','late-preparation-false','late-contract-false','foreign-identity','stage15','prep-coerced','extra-frozen-copy')) {
        $compatibilityHistory.Stage=14;$octoberCompatibilityIdentity=$true;$compatibilityFacts=@{ScopePreparationVerified=$true;ScopeContractVerified=$true}
        $preCommitStagedOwners=@($staged);$preCommitUnstagedOwners=@($frozen);$preCommitUntrackedOwners=@()
        $scopeDispatch.Preparation=$true;$scopeDispatch.Contract=$true;$scopeDispatch.Calls=@();$scopeDispatch.Reads=@()
        switch($mode) {
          'missing-staged' {$preCommitStagedOwners=@($staged[0..2])}
          'extra-staged' {$preCommitStagedOwners+=@('extra.txt')}
          'staged-app' {$preCommitStagedOwners+=@($frozen[0])}
          'missing-dashboard' {$preCommitUnstagedOwners=@($frozen[1])}
          'missing-layout' {$preCommitUnstagedOwners=@($frozen[0])}
          'extra-unstaged' {$preCommitUnstagedOwners+=@('apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart')}
          'untracked' {$preCommitUntrackedOwners=@('extra.txt')}
          'late-preparation-false' {$scopeDispatch.Preparation=$false}
          'late-contract-false' {$scopeDispatch.Contract=$false}
          'foreign-identity' {$octoberCompatibilityIdentity=$false}
          'stage15' {$compatibilityHistory.Stage=15}
          'prep-coerced' {$scopeDispatch.Preparation='true'}
          'extra-frozen-copy' {$preCommitUnstagedOwners+=@($frozen[0])}
        }
        $octoberCoveragePreparationPending=$false;$rejected=$false;$rejection=''
        $dispatchOutput=[Collections.Generic.List[object]]::new()
        try{. $scopeBlocks.inventory | ForEach-Object {[void]$dispatchOutput.Add($_)}}catch{$rejected=$true;$rejection=$_.Exception.Message}
        Assert-RepairContract ($octoberCoveragePreparationPending -eq ($mode -ceq 'positive') -and
          $rejected -eq ($mode -cnotin @('positive','foreign-identity','stage15'))) ('scope staged inventory result '+$mode)
        Assert-RepairContract ($dispatchOutput.Count -eq 0 -and (-not $rejected -or
          $rejection -ceq 'Scope amendment precommit must stage exact metadata4 and preserve frozen unstaged dashboard/layout.')) 'scope inventory concealed output or unrelated exception.'
        if($mode -cnotin @('foreign-identity','stage15')) {
          Assert-RepairContract (($scopeDispatch.Calls -join '|') -ceq 'pre_commit' -and
            ($scopeDispatch.Reads -join '|') -ceq 'index') 'inventory trusted old proof or wrong source.'
        }
        $scopeDispatchCases++
      }
      foreach($mode in @('dashboard','layout','unknown','metadata','buy','false-preparation','false-contract',
          'coerced-preparation','coerced-contract','foreign-identity','stage15','wrong-phase')) {
        $compatibilityHistory.Stage=14;$octoberCompatibilityIdentity=$true;$ProductionPhase='implementation';$changedOwner=$frozen[0]
        $compatibilityFacts=@{ScopePreparationVerified=$true;ScopeContractVerified=$true}
        switch($mode) {
          'layout' {$changedOwner=$frozen[1]}
          'unknown' {$changedOwner='extra.dart'}
          'metadata' {$changedOwner=$staged[0]}
          'buy' {$changedOwner='apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'}
          'false-preparation' {$compatibilityFacts.ScopePreparationVerified=$false}
          'false-contract' {$compatibilityFacts.ScopeContractVerified=$false}
          'coerced-preparation' {$compatibilityFacts.ScopePreparationVerified='true'}
          'coerced-contract' {$compatibilityFacts.ScopeContractVerified='true'}
          'foreign-identity' {$octoberCompatibilityIdentity=$false}
          'stage15' {$compatibilityHistory.Stage=15}
          'wrong-phase' {$ProductionPhase='handoff'}
        }
        $octoberCoveragePreservedOwner=$false;. $scopeBlocks.owner
        Assert-RepairContract ($octoberCoveragePreservedOwner -eq ($mode -cin @('dashboard','layout'))) ('scope preservation owner result '+$mode)
        $scopeDispatchCases++
      }
      foreach($mode in @('positive','late-preparation-false','late-contract-false')) {
        $compatibilityHistory.Stage=14;$compatibilityFacts=@{ScopePreparationVerified=$true;ScopeContractVerified=$true}
        $scopeDispatch.Preparation=$mode -cne 'late-preparation-false';$scopeDispatch.Contract=$mode -cne 'late-contract-false'
        $scopeDispatch.Calls=@();$scopeDispatch.Reads=@();$rejected=$false;$rejection=''
        $dispatchOutput=[Collections.Generic.List[object]]::new()
        try{. $scopeBlocks.late | ForEach-Object {[void]$dispatchOutput.Add($_)}}catch{$rejected=$true;$rejection=$_.Exception.Message}
        Assert-RepairContract ($rejected -eq ($mode -cne 'positive') -and
          ($scopeDispatch.Calls -join '|') -ceq 'pre_commit' -and ($scopeDispatch.Reads -join '|') -ceq 'index') 'late scope recollection skipped or trusted stale facts.'
        Assert-RepairContract ($dispatchOutput.Count -eq 0 -and (-not $rejected -or
          $rejection -ceq 'Scoped repair amendment requires fresh independent B25 preservation and exact staged contract.')) 'late scope proof concealed output or unrelated exception.'
        $scopeDispatchCases++
      }
      Assert-RepairContract ($scopeDispatchCases -eq 32) 'scope dispatch fixture inventory changed.'
      Write-Output "Compatibility scoped dispatch: $scopeDispatchCases actual statement fixtures passed; no live staging/admission inferred."
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
            'wrong-source' {$qualificationFixtureProof.sourceCommit='4d1b314b4f41b329998a65886cf459d18a9a12e2'}
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
              if(@(Get-PSCallStack)[1].FunctionName -ceq 'Test-OctoberCompatibilityHistoricalQualificationCore' -and
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
          $qualificationFixtureHistory=@{Stage=16;Head=('f'*40);Commits=@(('1'*40),('2'*40),('3'*40),
            '7ccc0f01372276f6bc0b654544c95fc56c7b7086','84b889430abb84e67ea1cf3838c63841429f7712',('c'*40),('6'*40),
            '0da3630d1c857390c173ec83ba5c0210cb1e5ec2',('9'*40),'4d1b314b4f41b329998a65886cf459d18a9a12e2',
            '660c4c17f03d28a2a14cad668e16f91445b610e2','aecfa68c1beb3517d57306ff7a596c539f8fe10b',
            '5a70a1728d534f72c06997d6c7146a46fa7481cf',('0'*40),('a'*40),('f'*40))}
          if($qualificationFixtureWorking) {
            $qualificationFixtureHistory.Stage=15;$qualificationFixtureHistory.Commits=@($qualificationFixtureHistory.Commits|Select-Object -First 15)
            $qualificationFixtureHistory.Head='a'*40
          }
          $qualificationFixtureResult=Test-OctoberCompatibilityHistoricalQualificationCore $qualificationFixtureHistory -FromWorkingTree:$qualificationFixtureWorking
          Assert-RepairContract (-not (Test-OctoberCompatibilityQualification $qualificationFixtureHistory -FromWorkingTree:$qualificationFixtureWorking)) 'repair-only current admission accepted a historical/core Q fixture.'
          Assert-RepairContract ($qualificationFixtureResult -eq ($qualificationFixtureMode -cin @('positive','working-positive'))) ('concrete Q conjunction result incorrect: '+$qualificationFixtureMode)
          Assert-RepairContract (-not $qualificationFixtureContext.UnexpectedRead) ('Q rejection masked unintended Git read: '+$qualificationFixtureMode)
          if($qualificationFixtureWorking){Assert-RepairContract $qualificationFixtureContext.WorkingRead 'Working Q branch did not read its isolated fixture file.'}
          if($qualificationFixtureMode -ceq 'working-missing-proof') {
            Assert-RepairContract (-not $qualificationFixtureContext.CoverageReached -and
              -not $qualificationFixtureContext.VisualReached) 'Missing working proof reached downstream qualification.'
          }
          if($qualificationFixtureMode -ceq 'wrong-source') {
            Assert-RepairContract (-not $qualificationFixtureContext.CoverageReached -and
              -not $qualificationFixtureContext.VisualReached) 'Old T proof reached downstream V qualification.'
          }
          if($qualificationFixtureMode -cin @('positive','working-positive','failed-coverage','failed-visual')) {
            Assert-RepairContract $qualificationFixtureContext.CoverageReached ('Q coverage boundary not reached: '+$qualificationFixtureMode)
          }
          if($qualificationFixtureMode -cin @('positive','working-positive','failed-visual')) {
            Assert-RepairContract $qualificationFixtureContext.VisualReached ('Q visual conjunction not reached: '+$qualificationFixtureMode)
          }
        }
      }
      Write-Output 'Compatibility concrete Q conjunction: 22 labelled cases passed; committed N and isolated stage15 working-proof branch included, no real graph, capture, approval or source qualified.'
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
    Assert-RepairContract ($CaptureMode -ceq 'behavior_only') 'selected-risk capture awaits independently reviewed source-bound risk selection.'
    $currentSource=Read-OctoberCompatibilityCurrentCaptureSource
    Assert-RepairContract ($null -ne $currentSource) 'current capture requires independently derived clean committed capture source and contract roles.'
    $source=@($currentSource.SourceIdentity.captureSourceCommit)
    $history=$currentSource.History
    $before=@(Get-OctoberCompatibilityGitLines @('status','--porcelain=v1','-z'))
    Assert-RepairContract ($before.Count -eq 0) 'capture requires clean committed scroll/layout repair source.'
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
    $plan=Get-OctoberCompatibilityCurrentExecutionPlan -ReportId $CaptureCompatibilityReport -ExecutionId $CaptureExecutionId `
      -Mode $CaptureMode -RunId ('current-'+[Guid]::NewGuid().ToString('N')) -SourceIdentity $currentSource.SourceIdentity
    Assert-RepairContract ($null -ne $plan) 'execution is not a literal plan for this report category.'
    . (Join-Path $PSScriptRoot 'invoke-flutter-with-clean-support.ps1')
    $record=Invoke-OctoberCompatibilityCurrentBehaviorCapture -Plan $plan -InitialSource $currentSource
    Write-Output (ConvertTo-Json -InputObject $record -Compress -Depth 10)
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
    UPreparationVerified=$true
    WPreparationVerified=$true
    ScrollPreparationVerified=$true
    ScopePreparationVerified=$true
    ScopeContractVerified=$true
    ScopeRepairAdmissionVerified=$true
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
  foreach ($pair in @(@('pre_commit',0),@('pre_commit',1),@('pre_commit',2),@('pre_commit',3),@('pre_commit',4),@('pre_commit',5),@('pre_commit',6),@('pre_commit',7),@('pre_commit',8),@('pre_commit',9),@('pre_commit',10),@('pre_commit',11),@('pre_commit',12),@('pre_commit',13),@('pre_commit',14),@('pre_commit',15),
      @('task_start',1),@('implementation',1),@('implementation',2),@('implementation',3),@('implementation',4),@('implementation',5),@('implementation',6),@('implementation',7),@('implementation',8),@('implementation',9),@('implementation',10),@('implementation',11),@('implementation',12),@('implementation',13),@('implementation',14),@('implementation',15))) {
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
      elseif($stageFacts.Stage -eq 10){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 11){@(Get-OctoberCompatibilityRetentionOwners)}
      elseif($stageFacts.Stage -eq 12){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 13){@(Get-OctoberCompatibilityAmendmentOwners)}
      elseif($stageFacts.Stage -eq 14){@(Get-OctoberCompatibilityAmendmentOwners)}
      else{@(Get-OctoberCompatibilityScrollRepairOwners)}
    Assert-RepairContract (Test-OctoberCompatibilityStageFacts $stageFacts) "exact stage$($pair -join '/') rejected."
    $cases++
  }
  foreach ($stage in @(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18)) {
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
  $handoff=$facts.Clone(); $handoff.Phase='handoff'; $handoff.Stage=16
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
      @{Stage=10; Owners=@(Get-OctoberCompatibilityRetentionOwners)},
      @{Stage=11; Owners=@(Get-OctoberCompatibilityRetentionOwners)+@('apps/mobile/lib/features/work/work_session.dart')},
      @{Stage=15; Owners=@(Get-OctoberCompatibilityAmendmentOwners)},
      @{Stage=13; Owners=@(Get-OctoberCompatibilityForwardLayoutTestOwners)+@('apps/mobile/lib/features/work/work_session.dart')},
      @{Stage=13; Owners=@(Get-OctoberCompatibilityForwardLayoutTestOwners)},
      @{Stage=14; Owners=@(Get-OctoberCompatibilityForwardLayoutTestOwners)},
      @{Stage=14; Owners=@('apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart')})) {
    $changed=$facts.Clone(); $changed.Phase='pre_commit'; $changed.Stage=[int]$probe.Stage
    $changed.Owners=@($probe.Owners)
    Assert-RepairContract (-not (Test-OctoberCompatibilityStageFacts $changed)) 'widened or incomplete amendment/layout/Q claim accepted.'
    $cases++
  }
  foreach($flagCase in @(@(8,'NPreparationVerified'),@(8,'NContractVerified'),@(9,'NTestAdmissionVerified'),@(10,'UPreparationVerified'),@(12,'WPreparationVerified'),@(13,'ScrollPreparationVerified'))) {
    foreach($value in @($false,'true',$null)) {
      $changed=$facts.Clone();$changed.Phase='pre_commit';$changed.Stage=[int]$flagCase[0]
      $changed.Owners=if($changed.Stage -in @(8,10,12,13)){@(Get-OctoberCompatibilityAmendmentOwners)}else{@(Get-OctoberCompatibilityInheritedCartTestOwners)}
      if($null -eq $value){$changed.Remove($flagCase[1])}else{$changed[$flagCase[1]]=$value}
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'N/T admitted without exact typed internal verification.'
      $cases++
    }
  }
  foreach($value in @($false,'true',$null)) {
    $changed=$facts.Clone();$changed.Phase='implementation';$changed.Stage=13
    $changed.Owners=@(Get-OctoberCompatibilityAmendmentOwners)
    if($null -eq $value){$changed.Remove('ScrollPreparationVerified')}else{$changed.ScrollPreparationVerified=$value}
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'scroll preparation implementation admitted without typed internal verification.'
    $cases++
  }
  foreach($phase in @('implementation','pre_commit')) {
    foreach($flagCase in @(@(14,'ScopePreparationVerified'),@(14,'ScopeContractVerified'),@(15,'ScopeRepairAdmissionVerified'))) {
      foreach($value in @($false,'true',$null)) {
        $changed=$facts.Clone();$changed.Phase=$phase;$changed.Stage=[int]$flagCase[0]
        $changed.Owners=if($changed.Stage -eq 14){@(Get-OctoberCompatibilityAmendmentOwners)}else{@(Get-OctoberCompatibilityScrollRepairOwners)}
        if($null -eq $value){$changed.Remove($flagCase[1])}else{$changed[$flagCase[1]]=$value}
        Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'scoped metadata/repair admitted without independently typed proof.'
        $cases++
      }
    }
  }
  foreach($phase in @('implementation','pre_commit','handoff','integration_admission_authorize')) {
    foreach($stage in @(16,17,18)) {
      $changed=$facts.Clone();$changed.Phase=$phase;$changed.Stage=[int]$stage
      $changed.Owners=@('docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
      Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'future stage accepted before completed qualification-contract amendment.'
      $cases++
    }
  }
  foreach($probe in @(
      @{Stage=14;Owners=@(Get-OctoberCompatibilityScrollRepairOwners)},
      @{Stage=15;Owners=@(Get-OctoberCompatibilityForwardLayoutTestOwners)},
      @{Stage=15;Owners=@(Get-OctoberCompatibilityScrollRepairOwners)+@('apps/mobile/lib/features/work/work_session.dart')})) {
    $changed=$facts.Clone();$changed.Phase='implementation';$changed.Stage=[int]$probe.Stage;$changed.Owners=$probe.Owners
    Assert-RepairContract (-not(Test-OctoberCompatibilityStageFacts $changed)) 'metadata/app owner scope crossed or widened.';$cases++
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
  # Retain prior negatives, reclassify two old closure positives as blocked,
  # and add typed scope, future-stage and exact app-owner rejection checks.
  Assert-RepairContract ($cases -eq 206) 'stage probe inventory changed.'
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
    Assert-RepairContract ($_.Exception.Message -ceq 'Integration repair fixture rejected: current capture requires independently derived clean committed capture source and contract roles.') 'premature capture failed for an unrelated reason.'
    $capturePrematureRejected=$true
  }
  Assert-RepairContract $capturePrematureRejected 'premature host capture admitted before committed scroll/layout repair.'
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
  # Extend the same actual-history boundary harness to the narrow forward scope.
  # Existing sealed reads remain real; prospective successors alone are simulated.
  $scopeB25='b25e5913d088cc49b8c0fe40623cef49778e462a'
  $scopeChain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$($binding.baselineHead)..$scopeB25"))
  Assert-RepairContract ($scopeChain.Count -eq 14) 'B25 sealed chain unavailable.'
  $scopePrevious=$binding.baselineHead
  for($i=0;$i -lt $scopeChain.Count;$i++) {
    $sealed=$scopeChain[$i]
    foreach($format in @('%P','%s')){[void]$historyAllowedReads.Add("show|-s|--format=$format|$sealed")}
    [void]$historyAllowedReads.Add("diff-tree|--no-commit-id|--name-only|-r|$sealed")
    if($i -in @(0,2,3,4,5,6,8,10,11,12,13)){
      [void]$historyAllowedReads.Add("rev-parse|${sealed}:apps|${scopePrevious}:apps")
    }
    $scopePrevious=$sealed
  }
  foreach($i in @(6,8)){[void]$historyAllowedReads.Add("show|$($scopeChain[$i]):docs/quality/STORE-BUY-COMPATIBILITY-20261008.md")}
  $scopeHistoryCases=0
  $literalMetadata=@('scripts/check-codex-subagent-coordination-policy.ps1',
    'scripts/test-codex-integration-repair-coordination-policy.ps1',
    'scripts/check-cross-agent-incremental-ticket-gate.ps1','docs/quality/STORE-BUY-COMPATIBILITY-20261008.md')
  $literalRepair=@('apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart',
    'apps/mobile/test/work_workspace_layout_safety_test.dart')
  Assert-RepairContract ((@(Get-OctoberCompatibilityAmendmentOwners) -join '|') -ceq ($literalMetadata -join '|') -and
    (@(Get-OctoberCompatibilityScrollRepairOwners) -join '|') -ceq ($literalRepair -join '|')) 'scope production inventories differ from independent literal metadata4/app2.'
  foreach($mode in @('metadata-positive','repair-source15-replacement-denied','metadata-missing-owner','metadata-extra-owner',
      'metadata-changed-apps','metadata-wrong-parent','metadata-wrong-subject',
      'missing-immutable-contract','altered-immutable-contract','duplicate-immutable-contract',
      'repair-missing-owner','repair-extra-owner','repair-wrong-parent','repair-wrong-subject','wrong-sealed-B25')) {
    & {
      $scopeCtx=@{Mode=$mode;Metadata=('a'*40);Repair=('b'*40);BadB25=('c'*40);
        Unexpected=$false;ContractReads=0;AncestryCalls=0}
      $hasRepair=$mode -cnotlike 'metadata-*';$tip=if($hasRepair){$scopeCtx.Repair}else{$scopeCtx.Metadata}
      function git {
        $query=@($args)
        if(($query -join '|') -ceq "-C|$root|merge-base|--is-ancestor|$($binding.baselineHead)|$tip") {
          $scopeCtx.AncestryCalls++;$query[-1]=$scopeB25
        }elseif($query.Count -ge 6 -and (@($query[0..4]) -join '|') -ceq
            "--no-pager|--no-optional-locks|--no-replace-objects|-C|$root" -and
            $historyAllowedReads.Contains((@($query[5..($query.Count-1)]) -join '|'))) {
          # Only the independently enumerated sealed-history reads are delegated.
        }else{$scopeCtx.Unexpected=$true;throw 'Unexpected scoped native fixture query.'}
        & $historyNativeGit @query;$global:LASTEXITCODE=$LASTEXITCODE
      }
      function Get-OctoberCompatibilityGitLines([string[]]$Arguments) {
        $query=$Arguments -join '|';$m=$scopeCtx.Metadata;$r=$scopeCtx.Repair
        if($query -ceq "rev-list|--reverse|$($binding.baselineHead)..$tip" -or
            $query -ceq "rev-list|--first-parent|--reverse|$($binding.baselineHead)..$tip") {
          $chain=@($scopeChain)
          if($scopeCtx.Mode -ceq 'wrong-sealed-B25'){$chain[13]=$scopeCtx.BadB25}
          $chain+=@($m);if($hasRepair){$chain+=@($r)};return $chain
        }
        foreach($successor in @($m,$r)) {
          if($query -ceq "show|-s|--format=%P|$successor") {
            if(($successor -ceq $m -and $scopeCtx.Mode -ceq 'metadata-wrong-parent') -or
                ($successor -ceq $r -and $scopeCtx.Mode -ceq 'repair-wrong-parent')){return $binding.baselineHead}
            if($successor -ceq $r){return $m}
            return $(if($scopeCtx.Mode -ceq 'wrong-sealed-B25'){$scopeCtx.BadB25}else{$scopeB25})
          }
          if($query -ceq "show|-s|--format=%s|$successor") {
            if(($successor -ceq $m -and $scopeCtx.Mode -ceq 'metadata-wrong-subject') -or
                ($successor -ceq $r -and $scopeCtx.Mode -ceq 'repair-wrong-subject')){return 'altered'}
            if($successor -ceq $m){return 'coordination(store-buy-compatibility-20261008): admit exact scoped search and purchase repair'}
            return 'repair(store-buy-compatibility-20261008): preserve purchase return and scoped search journeys'
          }
          if($query -ceq "diff-tree|--no-commit-id|--name-only|-r|$successor") {
            $owners=if($successor -ceq $m){@($literalMetadata)}else{@($literalRepair)}
            if(($successor -ceq $m -and $scopeCtx.Mode -ceq 'metadata-missing-owner') -or
                ($successor -ceq $r -and $scopeCtx.Mode -ceq 'repair-missing-owner')){return $owners[0..($owners.Count-2)]}
            if(($successor -ceq $m -and $scopeCtx.Mode -ceq 'metadata-extra-owner') -or
                ($successor -ceq $r -and $scopeCtx.Mode -ceq 'repair-extra-owner')){return $owners+@('apps/mobile/lib/features/work/work_session.dart')}
            return $owners
          }
        }
        $comparison=if($scopeCtx.Mode -ceq 'wrong-sealed-B25'){$scopeCtx.BadB25}else{$scopeB25}
        if($query -ceq "rev-parse|${m}:apps|${comparison}:apps") {
          if($scopeCtx.Mode -ceq 'metadata-changed-apps'){return @(('d'*40),('e'*40))}
          return @('9ad2547cea06b3a178de38af482e808ea51d27bf','9ad2547cea06b3a178de38af482e808ea51d27bf')
        }
        if($query -ceq "show|${m}:docs/quality/STORE-BUY-COMPATIBILITY-20261008.md") {
          $scopeCtx.ContractReads++
          switch($scopeCtx.Mode) {
            'missing-immutable-contract' {return 'Valid working contract must not substitute for absent committed admission.'}
            'altered-immutable-contract' {return $historyWorkingDocument.Replace('scoped_repair_admission_not_qualification','altered')}
            'duplicate-immutable-contract' {return $historyWorkingDocument+"`n"+$historyWorkingDocument}
            default {return $historyWorkingDocument}
          }
        }
        $forward=@($Arguments|ForEach-Object {
          if($_ -ceq $scopeCtx.BadB25){$scopeB25}
          elseif($_ -ceq "$($scopeCtx.BadB25):apps"){"${scopeB25}:apps"}else{$_}
        })
        if(-not $historyAllowedReads.Contains(($forward -join '|'))){$scopeCtx.Unexpected=$true;throw 'Unexpected scoped sealed query.'}
        return & $historyOriginalGitLines $forward
      }
      $accepted=$false;$rejection='';$scopeStageOutput=[Collections.Generic.List[object]]::new()
      try{Get-OctoberCompatibilityHistoryStage $tip | ForEach-Object {[void]$scopeStageOutput.Add($_)}
        $accepted=$scopeStageOutput.Count -eq 1 -and $scopeStageOutput[0].Stage -eq $(if($hasRepair){16}else{15})
      }catch{$rejection=$_.Exception.Message}
      Assert-RepairContract (-not $scopeCtx.Unexpected -and $scopeCtx.AncestryCalls -eq 1) 'scope fixture concealed unexpected reads.'
      Assert-RepairContract ($accepted -eq ($mode -ceq 'metadata-positive')) "scoped history result wrong for$mode; rejection=$rejection."
      if(-not $accepted) {
        $expectedError=switch($mode) {
          {$_ -cin @('metadata-missing-owner','metadata-extra-owner','repair-missing-owner','repair-extra-owner')} {'Compatibility successor changed unexpected owners.';break}
          {$_ -cin @('metadata-wrong-parent','metadata-wrong-subject','repair-wrong-parent','repair-wrong-subject')} {'Compatibility successor parent/subject changed.';break}
          'metadata-changed-apps' {'Compatibility metadata commit changed apps.';break}
          'wrong-sealed-B25' {'Sealed compatibility B25 changed.';break}
          'repair-source15-replacement-denied' {'Sealed Source15 runtime/test checkpoint changed.';break}
          default {'Immutable scoped repair admission missing or changed.'}
        }
        Assert-RepairContract ($scopeStageOutput.Count -eq 0 -and
          $rejection -ceq ('Codex subagent coordination gate rejected: '+$expectedError)) 'scoped history concealed stage output or unrelated rejection.'
      }
      if($mode -cin @('metadata-positive','repair-source15-replacement-denied','missing-immutable-contract','altered-immutable-contract','duplicate-immutable-contract')) {
        Assert-RepairContract ($scopeCtx.ContractReads -eq 1) 'scope admission was not read exactly once from committed metadata14.'
      }else {
        Assert-RepairContract ($scopeCtx.ContractReads -eq 0) 'structural history rejection unexpectedly reached admission contract.'
      }
    }
    $scopeHistoryCases++
  }
  Assert-RepairContract ($scopeHistoryCases -eq 15) 'scope history fixture inventory changed.'
  Write-Output "Compatibility scoped history: $scopeHistoryCases actual predicate fixtures passed; simulated successors, no live commit or qualification."
  $actualSealedSource15=Get-OctoberCompatibilityHistoryStage '3c3f38136db8bb184866635203d04ea4643f1eac'
  Assert-RepairContract ($actualSealedSource15.Stage -eq 16 -and $actualSealedSource15.Head -ceq '3c3f38136db8bb184866635203d04ea4643f1eac' -and
    $actualSealedSource15.Commits[14] -ceq '4e1c58fff39b770c32b3970470b9df9a51026b36' -and
    $actualSealedSource15.Commits[15] -ceq '3c3f38136db8bb184866635203d04ea4643f1eac') 'Actual sealed Source15 history rejected.'
  Write-Output 'Compatibility sealed Source15: actual immutable history passed; no replacement, handoff or application qualification.'
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
    $modernMissingProof=@{Stage=16;Head=$binding.baselineHead;Commits=@(('1'*40),('2'*40),('3'*40),('4'*40),('5'*40),('6'*40),('7'*40),
      '0da3630d1c857390c173ec83ba5c0210cb1e5ec2',('9'*40),'4d1b314b4f41b329998a65886cf459d18a9a12e2',
      '660c4c17f03d28a2a14cad668e16f91445b610e2','aecfa68c1beb3517d57306ff7a596c539f8fe10b',
      '5a70a1728d534f72c06997d6c7146a46fa7481cf',('0'*40),('a'*40),$binding.baselineHead)}
    Assert-RepairContract (-not(Test-OctoberCompatibilityHistoricalQualificationCore $modernMissingProof)) 'historical/core valid-stage missing Q proof accepted.'
    Assert-RepairContract ($proofReadContext.Read -and -not $proofReadContext.Unexpected) 'missing Q rejection did not reach the intended proof read.'
  }
  Write-Output 'Compatibility qualification: operative boundary rejects source; historical/core missing-proof read also rejected, no host pass manufactured.'
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
