[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$LedgerPath,
  [string]$CandidateId,
  [string]$CandidateVersionCode,
  [ValidateSet('validate', 'prebuild', 'postinstall')]
  [string]$Phase = 'validate',
  [switch]$RunSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $LedgerPath) {
  $LedgerPath = Join-Path $root 'config/release-acceptance-blocker-ledger-c33g.json'
}

function Assert-C33GFix4 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33G FIX4 acceptance-blocker ledger rejected: $Message" }
}

function Get-C33GProperty {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Name)
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Resolve-C33GRepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C33GFix4 -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is missing."
  Assert-C33GFix4 -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33GFix4 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  Assert-C33GFix4 -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) `
    -Message "$Label is missing: $Path"
  return $resolved
}

function Test-C33GRepoFile {
  param([object]$Path)
  $text = [string]$Path
  if ([string]::IsNullOrWhiteSpace($text) -or [IO.Path]::IsPathRooted($text)) {
    return $false
  }
  try {
    $resolved = [IO.Path]::GetFullPath((Join-Path $root $text))
  } catch {
    return $false
  }
  return (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  )
}

function Get-C33GBlockerFailures {
  param(
    [Parameter(Mandatory)][object]$Blocker,
    [Parameter(Mandatory)][long]$FailedVersionCode
  )
  $failures = [Collections.Generic.List[string]]::new()
  $regressionId = [string](Get-C33GProperty -Object $Blocker -Name 'regressionId')
  if ([string]::IsNullOrWhiteSpace($regressionId)) { $failures.Add('missing_regression_id') }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'applicable')) { return $failures }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'releaseBlocking')) {
    $failures.Add('applicable_blocker_not_release_blocking')
  }
  $ticketPath = Get-C33GProperty -Object $Blocker -Name 'repairTicketPath'
  if (-not (Test-C33GRepoFile -Path $ticketPath)) { $failures.Add('missing_repair_ticket') }
  $gatePath = Get-C33GProperty -Object $Blocker -Name 'sourceGatePath'
  if (-not (Test-C33GRepoFile -Path $gatePath)) { $failures.Add('missing_source_gate') }
  $sourceTests = @(Get-C33GProperty -Object $Blocker -Name 'sourceTestPaths')
  if ($sourceTests.Count -eq 0 -or @($sourceTests | Where-Object { -not (Test-C33GRepoFile -Path $_) }).Count -gt 0) {
    $failures.Add('missing_source_test')
  }
  $qualificationEvidence = @(Get-C33GProperty -Object $Blocker -Name 'qualificationEvidencePaths')
  if ($qualificationEvidence.Count -eq 0 -or @($qualificationEvidence | Where-Object { -not (Test-C33GRepoFile -Path $_) }).Count -gt 0) {
    $failures.Add('missing_qualification_evidence')
  }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'sourceGatePassed')) {
    $failures.Add('source_gate_not_passed')
  }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'focusedTestsPassed')) {
    $failures.Add('focused_tests_not_passed')
  }
  if ([string](Get-C33GProperty -Object $Blocker -Name 'status') -cne 'resolved_complete') {
    $failures.Add('status_not_resolved_complete')
  }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'futurePlayDeviceAcceptancePassed')) {
    $failures.Add('future_play_device_acceptance_not_passed')
  }
  if (-not (Test-C33GRepoFile -Path (Get-C33GProperty -Object $Blocker -Name 'futurePlayDeviceEvidencePath'))) {
    $failures.Add('missing_future_play_device_evidence')
  }
  $resolvedCandidateId = [string](Get-C33GProperty -Object $Blocker -Name 'resolvedCandidateId')
  if ([string]::IsNullOrWhiteSpace($resolvedCandidateId)) {
    $failures.Add('missing_resolved_candidate_id')
  }
  $resolvedVersionRaw = Get-C33GProperty -Object $Blocker -Name 'resolvedCandidateVersionCode'
  $resolvedVersion = 0L
  if ($null -eq $resolvedVersionRaw -or -not [long]::TryParse([string]$resolvedVersionRaw, [ref]$resolvedVersion)) {
    $failures.Add('missing_resolved_candidate_version')
  } elseif ($resolvedVersion -le $FailedVersionCode) {
    $failures.Add('stale_resolved_candidate')
  }
  return $failures
}

function Get-C33GBlockerPrebuildFailures {
  param([Parameter(Mandatory)][object]$Blocker)
  $failures = [Collections.Generic.List[string]]::new()
  $regressionId = [string](Get-C33GProperty -Object $Blocker -Name 'regressionId')
  if ([string]::IsNullOrWhiteSpace($regressionId)) { $failures.Add('missing_regression_id') }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'applicable')) { return $failures }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'releaseBlocking')) {
    $failures.Add('applicable_blocker_not_release_blocking')
  }
  if (-not (Test-C33GRepoFile -Path (Get-C33GProperty -Object $Blocker -Name 'repairTicketPath'))) {
    $failures.Add('missing_repair_ticket')
  }
  if (-not (Test-C33GRepoFile -Path (Get-C33GProperty -Object $Blocker -Name 'sourceGatePath'))) {
    $failures.Add('missing_source_gate')
  }
  $sourceTests = @(Get-C33GProperty -Object $Blocker -Name 'sourceTestPaths')
  if ($sourceTests.Count -eq 0 -or @($sourceTests | Where-Object { -not (Test-C33GRepoFile -Path $_) }).Count -gt 0) {
    $failures.Add('missing_source_test')
  }
  $qualificationEvidence = @(Get-C33GProperty -Object $Blocker -Name 'qualificationEvidencePaths')
  if ($qualificationEvidence.Count -eq 0 -or @($qualificationEvidence | Where-Object { -not (Test-C33GRepoFile -Path $_) }).Count -gt 0) {
    $failures.Add('missing_qualification_evidence')
  }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'sourceGatePassed')) {
    $failures.Add('source_gate_not_passed')
  }
  if (-not [bool](Get-C33GProperty -Object $Blocker -Name 'focusedTestsPassed')) {
    $failures.Add('focused_tests_not_passed')
  }
  if ([string](Get-C33GProperty -Object $Blocker -Name 'status') -cnotin @(
      'source_qualified_candidate_device_pending',
      'resolved_complete'
    )) {
    $failures.Add('status_not_prebuild_qualified')
  }
  return $failures
}

function Copy-C33GObject {
  param([Parameter(Mandatory)][object]$Object)
  return ($Object | ConvertTo-Json -Depth 20 | ConvertFrom-Json)
}

function Invoke-C33GSelfTest {
  param([Parameter(Mandatory)][long]$FailedVersionCode)
  $existing = 'config/uaw-c33g-fix4-unresolved-acceptance-blocker-pre-aab-ledger-ticket.json'
  $base = [pscustomobject]@{
    regressionId = 'REG-SELF-TEST'
    applicable = $true
    releaseBlocking = $true
    repairTicketPath = $existing
    sourceGatePath = 'scripts/check-codex-development-regression-memory.ps1'
    sourceTestPaths = @($existing)
    qualificationEvidencePaths = @($existing)
    sourceGatePassed = $true
    focusedTestsPassed = $true
    futurePlayDeviceEvidencePath = $existing
    futurePlayDeviceAcceptancePassed = $true
    resolvedCandidateId = 'SELF-TEST-FUTURE-CANDIDATE'
    resolvedCandidateVersionCode = $FailedVersionCode + 1
    status = 'resolved_complete'
  }
  Assert-C33GFix4 -Condition (
    @(Get-C33GBlockerFailures -Blocker $base -FailedVersionCode $FailedVersionCode).Count -eq 0
  ) -Message 'resolved-complete positive fixture failed.'

  $prebuild = Copy-C33GObject -Object $base
  $prebuild.status = 'source_qualified_candidate_device_pending'
  $prebuild.futurePlayDeviceEvidencePath = $null
  $prebuild.futurePlayDeviceAcceptancePassed = $false
  $prebuild.resolvedCandidateId = $null
  $prebuild.resolvedCandidateVersionCode = $null
  Assert-C33GFix4 -Condition (
    @(Get-C33GBlockerPrebuildFailures -Blocker $prebuild).Count -eq 0
  ) -Message 'source-qualified/device-pending prebuild fixture failed.'

  $cases = @(
    @{ name = 'device_pending_postinstall'; mutate = { param($b) $b.status = 'source_qualified_candidate_device_pending' }; expected = 'status_not_resolved_complete' },
    @{ name = 'missing_ticket'; mutate = { param($b) $b.repairTicketPath = 'config/missing-c33g-ticket.json' }; expected = 'missing_repair_ticket' },
    @{ name = 'missing_test'; mutate = { param($b) $b.sourceTestPaths = @('apps/mobile/test/missing-c33g-test.dart') }; expected = 'missing_source_test' },
    @{ name = 'missing_device'; mutate = { param($b) $b.futurePlayDeviceEvidencePath = $null }; expected = 'missing_future_play_device_evidence' },
    @{ name = 'stale_candidate'; mutate = { param($b) $b.resolvedCandidateVersionCode = $FailedVersionCode }; expected = 'stale_resolved_candidate' }
  )
  foreach ($case in $cases) {
    $fixture = Copy-C33GObject -Object $base
    & $case.mutate $fixture
    $failures = @(Get-C33GBlockerFailures -Blocker $fixture -FailedVersionCode $FailedVersionCode)
    Assert-C33GFix4 -Condition ($failures -ccontains [string]$case.expected) `
      -Message "negative fixture was not rejected: $($case.name)"
  }
}

$ledgerResolved = [IO.Path]::GetFullPath($LedgerPath)
Assert-C33GFix4 -Condition (
  $ledgerResolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
) -Message 'ledger escaped the repository.'
Assert-C33GFix4 -Condition (Test-Path -LiteralPath $ledgerResolved -PathType Leaf) `
  -Message 'ledger file is missing.'
$ledger = Get-Content -Raw -LiteralPath $ledgerResolved | ConvertFrom-Json
Assert-C33GFix4 -Condition ([int]$ledger.schemaVersion -eq 1) `
  -Message 'unsupported ledger schema.'
Assert-C33GFix4 -Condition (
  [string]$ledger.contractId -ceq 'MOOLSOCIAL-C33G-RELEASE-ACCEPTANCE-BLOCKER-LEDGER-001'
) -Message 'ledger contract changed.'
Assert-C33GFix4 -Condition (
  [string]$ledger.state -ceq 'active_fail_closed_r60_49_acceptance_failed' -and
  [string]$ledger.scope -ceq 'candidate_independent_all_future_release_candidates'
) -Message 'ledger is not the active candidate-independent fail-closed owner.'
Assert-C33GFix4 -Condition (
  [string]$ledger.failedCandidate.versionName -ceq '1.0.0-r60.49' -and
  [long]$ledger.failedCandidate.versionCode -eq 2026081349 -and
  [string]$ledger.failedCandidate.machineState -ceq 'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [int]$ledger.failedCandidate.buildCount -eq 1 -and
  [int]$ledger.failedCandidate.uploadCount -eq 1 -and
  [int]$ledger.failedCandidate.installCount -eq 1 -and
  [int]$ledger.failedCandidate.deviceAcceptanceCount -eq 0
) -Message 'failed r60.49 identity or 1/1/1/0 history changed.'
foreach ($rule in @(
  'coldStartOnlyNeverCompletesJourneyAcceptance',
  'prebuildRequiresEveryApplicableBlockerSourceQualified',
  'prebuildRejectsSourceQualifiedPrebuildProviderPending',
  'prebuildRequiresDeviceAcceptancePendingOrComplete',
  'postinstallRequiresEveryApplicableBlockerResolvedComplete',
  'sourceQualificationCannotReplacePostinstallPlayDeviceAcceptance',
  'futureCandidateMustBeNewerThanFailedCandidate',
  'gateBeforeHiddenInputPrompt',
  'gateBeforeAuthorityConsumption'
)) {
  Assert-C33GFix4 -Condition ([bool](Get-C33GProperty -Object $ledger.releaseRule -Name $rule)) `
    -Message "release rule is not active: $rule"
}
Assert-C33GFix4 -Condition (-not [bool]$ledger.releaseRule.waiversAllowed) `
  -Message 'acceptance blocker waivers must remain disabled.'

$requiredRegressions = @(
  'REG-20260815-2428-C33F-R60-49-GOOGLE-SIGN-IN-INCOMPLETE',
  'REG-20260815-2429-C33F-R60-49-SOCIAL-CREATE-CRASH',
  'REG-20260815-2430-C33F-R60-49-GUEST-FEED-REDIRECTED-TO-SIGN-IN',
  'REG-20260815-2431-C33F-R60-49-SOCIAL-IDENTITY-PROVIDER-TRUTH',
  'REG-20260815-2451-C33G-PROTECTED-SOCIAL-INTENT-NOT-RESUMED-AFTER-RESTART',
  'REG-20260815-2220-C30Z-R60-48-PHONE-OTP-ADVERTISED-WITHOUT-LIVE-PROVIDER-READINESS'
)
$blockers = @($ledger.blockers)
Assert-C33GFix4 -Condition ($blockers.Count -eq $requiredRegressions.Count) `
  -Message 'ledger blocker count changed.'
$ids = @($blockers | ForEach-Object { [string]$_.regressionId })
Assert-C33GFix4 -Condition (@($ids | Select-Object -Unique).Count -eq $ids.Count) `
  -Message 'ledger contains duplicate blocker ids.'
foreach ($requiredId in $requiredRegressions) {
  Assert-C33GFix4 -Condition ($ids -ccontains $requiredId) `
    -Message "required blocker is missing: $requiredId"
}

foreach ($blocker in $blockers) {
  [void](Resolve-C33GRepoFile -Path ([string]$blocker.repairTicketPath) -Label 'repair ticket')
  $ticket = Get-Content -Raw -LiteralPath (Resolve-C33GRepoFile -Path ([string]$blocker.repairTicketPath) -Label 'repair ticket') | ConvertFrom-Json
  Assert-C33GFix4 -Condition ([string]$ticket.ticketId -ceq [string]$blocker.repairTicketId) `
    -Message "repair ticket identity changed for $($blocker.regressionId)."
  [void](Resolve-C33GRepoFile -Path ([string]$blocker.sourceGatePath) -Label 'source gate')
  foreach ($path in @($blocker.sourceTestPaths)) {
    [void](Resolve-C33GRepoFile -Path ([string]$path) -Label 'source test')
  }
  foreach ($path in @($blocker.qualificationEvidencePaths)) {
    [void](Resolve-C33GRepoFile -Path ([string]$path) -Label 'qualification evidence')
  }
  Assert-C33GFix4 -Condition (
    [string]$blocker.status -cin @(
      'source_qualified_prebuild_provider_pending',
      'source_qualified_candidate_device_pending',
      'resolved_complete'
    )
  ) -Message "unsupported blocker status for $($blocker.regressionId)."
}

$launcher = Get-Content -Raw -LiteralPath (
  Resolve-C33GRepoFile -Path 'tmp/run-c30x-successor-single-aab-founder.ps1' -Label 'founder launcher'
)
$wrapper = Get-Content -Raw -LiteralPath (
  Resolve-C33GRepoFile -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' -Label 'single AAB wrapper'
)
$gateNeedle = '& $acceptanceBlockerGate'
$prebuildNeedle = '-Phase prebuild'
Assert-C33GFix4 -Condition (
  $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf($prebuildNeedle, [StringComparison]::Ordinal) -gt
    $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal) -and
  $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal) -lt
    $launcher.IndexOf('& $candidateGate', [StringComparison]::Ordinal) -and
  $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal) -lt
    $launcher.IndexOf('Read-Host', [StringComparison]::Ordinal)
) -Message 'founder launcher does not compose the blocker gate before candidate gate and hidden prompts.'
Assert-C33GFix4 -Condition (
  $wrapper.IndexOf($gateNeedle, [StringComparison]::Ordinal) -ge 0 -and
  $wrapper.IndexOf($prebuildNeedle, [StringComparison]::Ordinal) -gt
    $wrapper.IndexOf($gateNeedle, [StringComparison]::Ordinal) -and
  $wrapper.IndexOf($gateNeedle, [StringComparison]::Ordinal) -lt
    $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal) -and
  $wrapper.IndexOf($gateNeedle, [StringComparison]::Ordinal) -lt
    $wrapper.IndexOf("`$state.buildAuthorization = 'consumed'", [StringComparison]::Ordinal)
) -Message 'single AAB wrapper does not compose the blocker gate before release gate and authority consumption.'

$failedVersionCode = [long]$ledger.failedCandidate.versionCode
if ($RunSelfTest) { Invoke-C33GSelfTest -FailedVersionCode $failedVersionCode }
if ($Phase -cne 'validate') {
  $candidateCode = 0L
  Assert-C33GFix4 -Condition (
    -not [string]::IsNullOrWhiteSpace($CandidateVersionCode) -and
    [long]::TryParse($CandidateVersionCode, [ref]$candidateCode) -and
    $candidateCode -gt $failedVersionCode
  ) -Message 'future candidate is missing or not newer than failed r60.49.'
  $failures = [Collections.Generic.List[string]]::new()
  foreach ($blocker in $blockers) {
    $blockerFailures = if ($Phase -ceq 'prebuild') {
      @(Get-C33GBlockerPrebuildFailures -Blocker $blocker)
    } else {
      @(Get-C33GBlockerFailures -Blocker $blocker -FailedVersionCode $failedVersionCode)
    }
    foreach ($failure in $blockerFailures) {
      $failures.Add("$($blocker.regressionId):$failure")
    }
    if ($Phase -ceq 'postinstall') {
      if ([string]::IsNullOrWhiteSpace($CandidateId) -or
          [string]$blocker.resolvedCandidateId -cne $CandidateId) {
        $failures.Add("$($blocker.regressionId):resolved_candidate_id_mismatch")
      }
      if ([string]$blocker.resolvedCandidateVersionCode -cne $CandidateVersionCode) {
        $failures.Add("$($blocker.regressionId):resolved_candidate_version_mismatch")
      }
    }
  }
  Assert-C33GFix4 -Condition ($failures.Count -eq 0) `
    -Message ("$Phase blockers remain: " + ($failures -join ', '))
}

Write-Output (
  'C33G FIX4 acceptance-blocker ledger passed: blockers=' + $blockers.Count +
  '; open=' + @($blockers | Where-Object { $_.status -cne 'resolved_complete' }).Count +
  '; selfTest=' + [bool]$RunSelfTest +
  '; phase=' + $Phase +
  '; buildPlayDevice=false.'
)
