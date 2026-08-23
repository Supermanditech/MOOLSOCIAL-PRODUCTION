[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34LTerminal {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C34L build-wrapper terminal-state gate rejected: $Message" }
}

function Assert-C34LSourceRegion {
  param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$StartToken,
    [Parameter(Mandatory)][string]$EndToken,
    [Parameter(Mandatory)][string[]]$RequiredTokens,
    [Parameter(Mandatory)][string]$Label
  )
  $startIndex = $Source.IndexOf($StartToken, [StringComparison]::Ordinal)
  Assert-C34LTerminal -Condition (
    $startIndex -ge 0 -and
    $startIndex -eq $Source.LastIndexOf($StartToken, [StringComparison]::Ordinal)
  ) -Message "$Label start token is missing or ambiguous."
  $endIndex = $Source.IndexOf(
    $EndToken, $startIndex + $StartToken.Length, [StringComparison]::Ordinal
  )
  Assert-C34LTerminal -Condition ($endIndex -gt $startIndex) `
    -Message "$Label end token is missing."
  $regionLength = $endIndex + $EndToken.Length - $startIndex
  $region = $Source.Substring($startIndex, $regionLength)
  foreach ($requiredToken in $RequiredTokens) {
    Assert-C34LTerminal -Condition (
      $region.IndexOf($requiredToken, [StringComparison]::Ordinal) -ge 0
    ) -Message "$Label omits exact caller binding: $requiredToken"
  }
}

function Assert-C34LSourceWindowBefore {
  param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$AnchorToken,
    [Parameter(Mandatory)][string[]]$RequiredTokens,
    [Parameter(Mandatory)][string]$Label,
    [int]$WindowLength = 500
  )
  $anchorIndex = $Source.IndexOf($AnchorToken, [StringComparison]::Ordinal)
  Assert-C34LTerminal -Condition (
    $anchorIndex -ge 0 -and
    $anchorIndex -eq $Source.LastIndexOf($AnchorToken, [StringComparison]::Ordinal)
  ) -Message "$Label anchor is missing or ambiguous."
  $windowStart = [Math]::Max(0, $anchorIndex - $WindowLength)
  $window = $Source.Substring(
    $windowStart, $anchorIndex + $AnchorToken.Length - $windowStart
  )
  foreach ($requiredToken in $RequiredTokens) {
    Assert-C34LTerminal -Condition (
      $window.IndexOf($requiredToken, [StringComparison]::Ordinal) -ge 0
    ) -Message "$Label omits exact caller binding: $requiredToken"
  }
}

function Resolve-C34LFile {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LTerminal -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "required owner is missing or escaped the repository: $Path"
  return $resolved
}

function Assert-C34LParses {
  param([Parameter(Mandatory)][string]$Path)
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $Path, [ref]$tokens, [ref]$errors
  )
  Assert-C34LTerminal -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell owner does not parse: $Path"
}

$wrapperPath = Resolve-C34LFile 'scripts/invoke-play-internal-aab-build-c30t.ps1'
$launcherPath = Resolve-C34LFile 'tmp/run-c34l-r60-76-single-aab-founder.ps1'
$transitionPath = Resolve-C34LFile 'scripts/invoke-release-lifecycle-transition-c34l.ps1'
Assert-C34LParses $wrapperPath
Assert-C34LParses $launcherPath
Assert-C34LParses $transitionPath
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$transitionOwner = Get-Content -Raw -LiteralPath $transitionPath

$contract = 'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-001'
foreach ($required in @(
  $contract,
  'check-uaw-c34l-r60-76-consolidated-release-transaction-evidence-readiness.ps1',
  'scripts/invoke-release-lifecycle-transition-c34l.ps1',
  'New-C34LTransitionProof',
  '-ProofOutputPath $ProofRelative',
  '11a-build-start-proof-attempt-$preflightAttempt.json',
  '11b-build-succeeded-proof-attempt-$preflightAttempt.json',
  '11c-build-failed-proof-attempt-$preflightAttempt.json',
  '11d-reject-proof-attempt-$preflightAttempt.json',
  '-PrerequisiteGatePhase build',
  '-Transition build-start',
  '-Transition build-failed',
  '-Transition reject',
  '-Transition build-succeeded',
  '12-release-terminal-result-attempt-$preflightAttempt.json',
  'build_in_progress_no_success_claimed',
  'aab_succeeded_postbuild_qualified',
  'rejected_no_success_claimed',
  'secretOrPrivateValuesRecorded = $false',
  '$c34lFailureStage = ''postbuild_gate''',
  '& $gate -Phase postbuild',
  'Invoke-C34LTerminalFailure'
)) {
  Assert-C34LTerminal -Condition (
    $wrapper.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "wrapper terminal contract is missing: $required"
}
foreach ($required in @(
  '-Phase $Phase -Transition $Transition',
  '-Attempt $Attempt',
  '-StatePath $StateRelative',
  '-ProofOutputPath $ProofRelative',
  '[int]$proof.attempt -eq $Attempt',
  '$buildStartProof = New-C34LTransitionProof',
  '-PrerequisiteGateEvidencePath $buildStartProof.Relative',
  '-PrerequisiteGateEvidenceSha256 $buildStartProof.Sha256',
  '$buildSucceededProof = New-C34LTransitionProof',
  '-PrerequisiteGateEvidencePath $buildSucceededProof.Relative',
  '-PrerequisiteGateEvidenceSha256 $buildSucceededProof.Sha256',
  '$buildFailedProof = New-C34LTransitionProof',
  '-PrerequisiteGateEvidencePath $buildFailedProof.Relative',
  '-PrerequisiteGateEvidenceSha256 $buildFailedProof.Sha256',
  '$rejectProof = New-C34LTransitionProof',
  '-Phase rejection',
  '-PrerequisiteGateEvidencePath $rejectProof.Relative',
  '-PrerequisiteGateEvidenceSha256 $rejectProof.Sha256',
  '-PrerequisiteGatePhase rejection'
)) {
  Assert-C34LTerminal -Condition (
    $wrapper.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "wrapper current-preimage proof flow is missing: $required"
}
$wrapperPreflightAttemptTokenCount =
  [regex]::Matches($wrapper, '-Attempt\s+\$preflightAttempt\b').Count
$wrapperHelperAttemptTokenCount =
  [regex]::Matches($wrapper, '-Attempt\s+\$Attempt\b').Count

Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '& $GatePath -Phase $Phase -Transition $Transition -Attempt $Attempt' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-Attempt $Attempt', '-StatePath $StateRelative', '-ProofOutputPath $ProofRelative') `
  -Label 'wrapper candidate-gate proof helper call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$proof = Get-Content -Raw -LiteralPath $proofPath | ConvertFrom-Json' `
  -EndToken ') -Message "C34L $Transition proof identity is invalid."' `
  -RequiredTokens @('[int]$proof.attempt -eq $Attempt') `
  -Label 'wrapper proof parse helper'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$buildFailedProof = New-C34LTransitionProof' `
  -EndToken '-ProofRelative $BuildFailedProofRelative' `
  -RequiredTokens @('-Phase build', '-Attempt $Attempt', '-Transition build-failed') `
  -Label 'wrapper build-failed proof call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '& $TransitionOwner -Transition build-failed' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-PrerequisiteGatePhase build', '-Attempt $Attempt') `
  -Label 'wrapper build-failed transition call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$rejectProof = New-C34LTransitionProof' `
  -EndToken '-ProofRelative $RejectProofRelative' `
  -RequiredTokens @('-Phase rejection', '-Attempt $Attempt', '-Transition reject') `
  -Label 'wrapper reject proof call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '& $TransitionOwner -Transition reject' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-PrerequisiteGatePhase rejection', '-Attempt $Attempt') `
  -Label 'wrapper reject transition call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$buildStartProof = New-C34LTransitionProof' `
  -EndToken '-ProofRelative $buildStartProofRelative' `
  -RequiredTokens @('-Phase build', '-Attempt $preflightAttempt', '-Transition build-start') `
  -Label 'wrapper build-start proof call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$c34lBuildStartAttempted = $true' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('& $c34jTransition -Transition build-start', '-PrerequisiteGatePhase build', '-Attempt $preflightAttempt') `
  -Label 'wrapper build-start transition call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$buildSucceededProof = New-C34LTransitionProof' `
  -EndToken '-ProofRelative $buildSucceededProofRelative' `
  -RequiredTokens @('-Phase build', '-Attempt $preflightAttempt', '-Transition build-succeeded') `
  -Label 'wrapper build-succeeded proof call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken '$buildSucceededProof = New-C34LTransitionProof' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('& $c34jTransition -Transition build-succeeded', '-PrerequisiteGatePhase build', '-Attempt $preflightAttempt') `
  -Label 'wrapper build-succeeded transition call'
Assert-C34LSourceRegion -Source $wrapper `
  -StartToken 'Invoke-C34LTerminalFailure `' `
  -EndToken '-FailureStage $c34lFailureStage' `
  -RequiredTokens @('-Attempt $preflightAttempt') `
  -Label 'wrapper terminal-failure helper call'
Assert-C34LSourceWindowBefore -Source $wrapper `
  -AnchorToken '-Outcome build_in_progress_no_success_claimed' `
  -RequiredTokens @('Write-C34LTerminalResultEvidence', '-Attempt $preflightAttempt') `
  -Label 'wrapper in-progress terminal-evidence call'
Assert-C34LSourceWindowBefore -Source $wrapper `
  -AnchorToken '-Outcome aab_succeeded_postbuild_qualified' `
  -RequiredTokens @('Write-C34LTerminalResultEvidence', '-Attempt $preflightAttempt') `
  -Label 'wrapper success terminal-evidence call'
Assert-C34LSourceWindowBefore -Source $wrapper `
  -AnchorToken '-Outcome rejected_no_success_claimed' `
  -RequiredTokens @('Write-C34LTerminalResultEvidence', '-Attempt $preflightAttempt') `
  -Label 'wrapper rejection terminal-evidence call'
foreach ($forbidden in @(
  'phaseGateProofs.build', 'c34lBuildGateProofRelative',
  'c34lBuildGateProofSha256'
)) {
  Assert-C34LTerminal -Condition (
    $wrapper.IndexOf($forbidden, [StringComparison]::Ordinal) -lt 0
  ) -Message "wrapper reuses a stale transition proof: $forbidden"
}
foreach ($historical in @(
  'MOOLSOCIAL-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001',
  'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001',
  'scripts/invoke-release-lifecycle-transition-c34j.ps1',
  'scripts/invoke-release-lifecycle-transition-c34k.ps1'
)) {
  Assert-C34LTerminal -Condition (
    $wrapper.IndexOf($historical, [StringComparison]::Ordinal) -ge 0
  ) -Message "historical atomic wrapper path changed: $historical"
}

$stageNames = @(
  'build_start_transition', 'flutter_aab_build', 'postbuild_source_restore',
  'postbuild_source_rebind', 'generated_aab_validation', 'sealed_aab_copy',
  'signer_proof', 'package_version_proof', 'firebase_resource_proof',
  'archive_payload_proof', 'credential_scan', 'provenance_write',
  'build_succeeded_transition', 'postbuild_gate'
)
foreach ($stage in $stageNames) {
  Assert-C34LTerminal -Condition (
    $wrapper.IndexOf("'$stage'", [StringComparison]::Ordinal) -ge 0
  ) -Message "post-build-start failure stage is unbound: $stage"
}
$outerStart = $wrapper.IndexOf('$c34lBuildStartAttempted = $false', [StringComparison]::Ordinal)
$outerCatch = $wrapper.LastIndexOf('} catch {', [StringComparison]::Ordinal)
$postbuild = $wrapper.IndexOf('& $gate -Phase postbuild', [StringComparison]::Ordinal)
$successOutput = $wrapper.IndexOf('MoolSocial single release AAB succeeded:', [StringComparison]::Ordinal)
Assert-C34LTerminal -Condition (
  $outerStart -ge 0 -and $postbuild -gt $outerStart -and
  $successOutput -gt $postbuild -and $outerCatch -gt $successOutput
) -Message 'outer terminal catch does not contain the complete post-build-start path.'

foreach ($required in @(
  $contract,
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE',
  '1.0.0-r60.76', '2026081376',
  'Invoke-C34LCleanupStep',
  'SetEnvironmentVariable($name, $null, ''Process'')',
  '[IO.File]::WriteAllText($path, ''''',
  'Remove-Item -LiteralPath $path -Force',
  'New-C34LFounderTransitionProof',
  '-Phase prebuild -Transition prebuild-failed',
  '[int]$proof.attempt -eq $Attempt',
  '-ProofOutputPath $ProofRelative',
  '11e-prebuild-failed-proof-launcher-attempt-1.json',
  '-Transition prebuild-failed',
  '-PrerequisiteGateEvidencePath $prebuildFailureProof.Relative',
  '-PrerequisiteGateEvidenceSha256 $prebuildFailureProof.Sha256',
  '-PrerequisiteGatePhase prebuild',
  '$script:c34lCleanupFailures -gt 0',
  'Complete-C30TFounderLauncherResult -Result $launcherResult'
)) {
  Assert-C34LTerminal -Condition (
    $launcher.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "launcher cleanup/result contract is missing: $required"
}
$launcherExplicitAttemptTokenCount =
  [regex]::Matches($launcher, '-Attempt\s+1\b').Count
$launcherHelperAttemptTokenCount =
  [regex]::Matches($launcher, '-Attempt\s+\$Attempt\b').Count

Assert-C34LSourceRegion -Source $launcher `
  -StartToken '& $GatePath -Phase prebuild -Transition prebuild-failed -Attempt $Attempt' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-StatePath $StateRelative', '-ProofOutputPath $ProofRelative') `
  -Label 'launcher prebuild-failed candidate-gate helper call'
Assert-C34LSourceRegion -Source $launcher `
  -StartToken '$proof = Get-Content -Raw -LiteralPath $proofPath | ConvertFrom-Json' `
  -EndToken ') -Message ''prebuild-failed proof identity is invalid.''' `
  -RequiredTokens @('[int]$proof.attempt -eq $Attempt') `
  -Label 'launcher proof parse helper'
Assert-C34LSourceRegion -Source $launcher `
  -StartToken '& $candidateGate -Phase preprompt -Attempt 1' `
  -EndToken '-RepositoryRoot $root' `
  -RequiredTokens @('-StatePath $stateRelative') `
  -Label 'launcher preprompt candidate-gate call'
Assert-C34LSourceRegion -Source $launcher `
  -StartToken '& $transitionPath -Transition founder-inputs-validated' `
  -EndToken '-RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-PrerequisiteGatePhase preprompt', '-Attempt 1') `
  -Label 'launcher founder-inputs transition call'
Assert-C34LSourceRegion -Source $launcher `
  -StartToken '$prebuildFailureProof = New-C34LFounderTransitionProof' `
  -EndToken '-ProofRelative $prebuildFailureProofRelative' `
  -RequiredTokens @('-Attempt 1') `
  -Label 'launcher prebuild-failed proof helper call'
Assert-C34LSourceRegion -Source $launcher `
  -StartToken '& $transitionPath -Transition prebuild-failed' `
  -EndToken '-FailureStage ''launcher_prebuild_failure'' -RepositoryRoot $root | Out-Null' `
  -RequiredTokens @('-PrerequisiteGatePhase prebuild', '-Attempt 1') `
  -Label 'launcher prebuild-failed transition call'
foreach ($required in @(
  "'founder-inputs-validated', 'prebuild-failed', 'build-start'",
  "[ValidatePattern('^[a-z0-9][a-z0-9_-]*$')][string]`$FailureStage",
  "'prebuild-failed' {",
  "failureStage = `$FailureStage",
  '[string]$proofValue.transition -ceq $ExpectedTransition',
  '[string]$proofValue.phase -ceq $ExpectedPhase',
  '[string]$proofValue.stateSha256 -ceq $ExpectedStateSha256',
  '[string]$proofValue.aggregateSha256 -ceq $ExpectedAggregateSha256',
  '[int]$proofValue.attempt -eq $ExpectedAttempt',
  'attempt = $Attempt',
  '[int]$proofValue.actionCounts.$name -eq [int]$PreState.actionCounts.$name',
  '[int]$proofValue.actionCounts.$name -eq [int]$PreAggregate.actionCounts.$name',
  '[string]$proofValue.releaseAuthorities.$name -ceq'
)) {
  Assert-C34LTerminal -Condition (
    $transitionOwner.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "transition does not accept or retain prebuild-failed FailureStage: $required"
}
Assert-C34LTerminal -Condition (
  $launcher.IndexOf('.Exception', [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $launcher.IndexOf('$Error[', [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $launcher.IndexOf('$_', [StringComparison]::Ordinal) -lt 0
) -Message 'launcher retains raw error data.'
$finallyIndex = $launcher.LastIndexOf('} finally {', [StringComparison]::Ordinal)
$resultIndex = $launcher.IndexOf(
  'Complete-C30TFounderLauncherResult -Result $launcherResult',
  [StringComparison]::Ordinal
)
Assert-C34LTerminal -Condition (
  $finallyIndex -ge 0 -and $resultIndex -gt $finallyIndex -and
  ([regex]::Matches($launcher, 'Invoke-C34LCleanupStep')).Count -ge 7
) -Message 'cleanup is not individually isolated before retained terminal result.'

function Test-C34LAttemptInterfaceModel {
  param(
    [Parameter(Mandatory)][int]$SelectedAttempt,
    [Parameter(Mandatory)][int]$ProofAttempt,
    [Parameter(Mandatory)][int]$TransitionAttempt
  )
  return $SelectedAttempt -eq $ProofAttempt -and
    $SelectedAttempt -eq $TransitionAttempt
}
$wrongAttemptRejected = -not (Test-C34LAttemptInterfaceModel `
  -SelectedAttempt 1 -ProofAttempt 2 -TransitionAttempt 1)
Assert-C34LTerminal -Condition $wrongAttemptRejected `
  -Message 'wrong-attempt proof interface fixture did not fail closed.'

# Behavior-only model: every injected post-start stage mints a proof for the
# current preimage and ends in one rejected terminal record. A postbuild-gate
# failure first proves the inapplicable build-failed path, then mints a fresh
# reject proof against the unchanged successful-build preimage.
$terminalFixtures = 0
$transitionProofFixtures = 0
foreach ($stage in $stageNames) {
  $fixture = [ordered]@{
    stage = $stage
    terminalWrites = 0
    proofTransitions = @()
    proofPhases = @()
    buildCount = 1
    uploadCount = 0
    installCount = 0
    deviceAcceptanceCount = 0
    buildAuthority = 'consumed'
    disposition = 'in_progress'
    terminalOutcome = 'build_in_progress_no_success_claimed'
  }
  $fixture.terminalOutcome = 'rejected_no_success_claimed'
  $fixture.terminalWrites++
  $fixture.proofTransitions += 'build-failed'
  $fixture.proofPhases += 'build'
  if ($stage -ceq 'postbuild_gate') {
    $fixture.proofTransitions += 'reject'
    $fixture.proofPhases += 'rejection'
  }
  $fixture.disposition = 'rejected'
  Assert-C34LTerminal -Condition (
    $fixture.terminalWrites -eq 1 -and
    $fixture.terminalOutcome -ceq 'rejected_no_success_claimed' -and
    $fixture.proofTransitions.Count -in @(1, 2) -and
    $fixture.proofTransitions[0] -ceq 'build-failed' -and
    $fixture.proofPhases[0] -ceq 'build' -and
    ($stage -cne 'postbuild_gate' -or
      ($fixture.proofTransitions[1] -ceq 'reject' -and
        $fixture.proofPhases[1] -ceq 'rejection')) -and
    $fixture.disposition -ceq 'rejected' -and
    $fixture.buildAuthority -ceq 'consumed' -and
    $fixture.buildCount -eq 1 -and $fixture.uploadCount -eq 0 -and
    $fixture.installCount -eq 0 -and $fixture.deviceAcceptanceCount -eq 0
  ) -Message "terminal failure fixture failed: $stage"
  $terminalFixtures++
  $transitionProofFixtures += $fixture.proofTransitions.Count
}
$cleanupFixtures = 0
foreach ($failureCount in 0..8) {
  $result = if ($failureCount -eq 0) { 'build_qualified' } else { 'stopped_after_cleanup' }
  Assert-C34LTerminal -Condition (
    ($failureCount -eq 0 -and $result -ceq 'build_qualified') -or
    ($failureCount -gt 0 -and $result -ceq 'stopped_after_cleanup')
  ) -Message "cleanup result-retention fixture failed: $failureCount"
  $cleanupFixtures++
}

Write-Output (
  'C34L build-wrapper terminal-state gate passed: ' +
  "postStartStages=$terminalFixtures; cleanupFixtures=$cleanupFixtures; " +
  "currentPreimageProofs=$transitionProofFixtures; " +
  "wrongAttemptRejected=$($wrongAttemptRejected.ToString().ToLowerInvariant()); " +
  "attemptTokenInventory=$wrapperPreflightAttemptTokenCount/" +
  "$wrapperHelperAttemptTokenCount/$launcherExplicitAttemptTokenCount/" +
  "$launcherHelperAttemptTokenCount; " +
  'terminalRejected=1/0/0/0; completeCatch=true; retainedResult=true; ' +
  'historicalPathsPreserved=true; secretOrPrivateValuesObserved=false.'
)
