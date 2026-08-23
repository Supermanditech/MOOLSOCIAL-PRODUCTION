[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$PolicyPath = 'config/release-device-acceptance-actor-policy-c34i.json',
  [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34IActorPolicy {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34I device-actor policy rejected: $Message"
  }
}

function Resolve-C34IActorPolicyFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34IActorPolicy -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is blank."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C34IActorPolicy -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the production repository."
  return $resolved
}

function Test-C34IActorPolicyObject {
  param([Parameter(Mandatory)]$Policy)

  $ticketId = 'UAW-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-PLAY-OPPO-ACCEPTANCE'
  Assert-C34IActorPolicy -Condition (
    [int]$Policy.schemaVersion -eq 1 -and
    [string]$Policy.contractId -ceq
      'MOOLSOCIAL-C34I-PRIVACY-SAFE-DEVICE-ACCEPTANCE-ACTOR-POLICY-001' -and
    [string]$Policy.ticketId -ceq $ticketId
  ) -Message 'schema, contract or selected ticket changed.'

  Assert-C34IActorPolicy -Condition (
    [string]$Policy.candidate.packageName -ceq 'com.moolsocial.app' -and
    [string]$Policy.candidate.versionName -ceq '1.0.0-r60.73' -and
    [string]$Policy.candidate.versionCode -ceq '2026081373' -and
    [string]$Policy.candidate.playTrack -ceq 'internal' -and
    [string]$Policy.candidate.deviceSerial -ceq '2b3e0f71' -and
    [string]$Policy.candidate.deviceModel -ceq 'CPH2375'
  ) -Message 'candidate, track or exact OPPO binding changed.'

  Assert-C34IActorPolicy -Condition (
    [string]$Policy.predecessorRejection.ticketId -ceq
      'UAW-C34H-R60-72-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE' -and
    [int]$Policy.predecessorRejection.buildCount -eq 1 -and
    [int]$Policy.predecessorRejection.uploadCount -eq 1 -and
    [int]$Policy.predecessorRejection.installCount -eq 1 -and
    [int]$Policy.predecessorRejection.deviceAcceptanceCount -eq 0 -and
    -not [bool]$Policy.predecessorRejection.artifactReusable -and
    [string]$Policy.predecessorRejection.reasonRegistryId -ceq
      'REG-20260817-2709-C34H-YOUTUBE-PROVIDER-ACCOUNT-CHOOSER-PRIVATE-IDENTIFIER-EXPOSURE-RECURRENCE'
  ) -Message 'the C34H rejection or 1/1/1/0 nonreuse truth changed.'

  $requiredCodexNever = @(
    'tap_any_account_capable_identity_provider',
    'open_or_inspect_Android_system_account_chooser',
    'select_or_infer_any_private_account_identifier',
    'enter_or_inspect_email_phone_OTP_password_API_key_OAuth_client_ID_or_credential',
    'open_or_inspect_private_email_action_link_or_private_deep_link',
    'capture_persist_log_copy_or_emit_private_identifier_or_private_system_surface',
    'continue_after_unplanned_provider_or_private_surface_becomes_visible'
  )
  $codexNever = @($Policy.actors.codex.neverAllowedActions)
  foreach ($action in $requiredCodexNever) {
    Assert-C34IActorPolicy -Condition ($codexNever -ccontains $action) `
      -Message "Codex prohibition '$action' is missing."
  }

  $requiredFounder = @(
    'tap_every_account_capable_identity_provider',
    'handle_every_system_account_chooser_and_account_selection',
    'enter_every_email_phone_OTP_or_other_private_authentication_value',
    'open_every_private_email_action_link_or_private_deep_link',
    'close_every_private_system_surface_before_returning_control_to_Codex'
  )
  $founderActions = @($Policy.actors.founder.requiredActions)
  foreach ($action in $requiredFounder) {
    Assert-C34IActorPolicy -Condition ($founderActions -ccontains $action) `
      -Message "founder-only action '$action' is missing."
  }

  $codexAllowed = @($Policy.actors.codex.allowedPredeclaredDeviceActions)
  foreach ($forbidden in $requiredCodexNever) {
    Assert-C34IActorPolicy -Condition (-not ($codexAllowed -ccontains $forbidden)) `
      -Message "forbidden action '$forbidden' also appears in the Codex allowlist."
  }

  foreach ($property in @(
      'freshExactDeviceWindowSelectionAfterFounderAction',
      'discardAllPriorScreenshotsCoordinatesAndElementIndices',
      'resumeOnlyAfterFounderConfirmsPrivateSurfaceClosed',
      'resumeFromSanitizedMoolSocialStateOnly'
    )) {
    Assert-C34IActorPolicy -Condition ([bool]$Policy.handoff.$property) `
      -Message "handoff protection '$property' is not active."
  }

  foreach ($property in @(
      'privateIdentifierVisibleToCodexRejectsCandidate',
      'accountChooserVisibleToCodexRejectsCandidate',
      'privateLinkVisibleToCodexRejectsCandidate',
      'credentialOrSecretVisibleToCodexRejectsCandidate',
      'unplannedProviderSurfaceVisibleToCodexRejectsCandidate',
      'staleDeviceHandleInputRejectsCurrentJourney',
      'newOrHistoricalRegressionRejectsCandidate'
    )) {
    Assert-C34IActorPolicy -Condition ([bool]$Policy.failClosed.$property) `
      -Message "fail-closed protection '$property' is not active."
  }
  Assert-C34IActorPolicy -Condition (-not [bool]$Policy.failClosed.waiversAllowed) `
    -Message 'privacy or regression waivers became allowed.'

  $journeys = @($Policy.journeyOrder)
  Assert-C34IActorPolicy -Condition ($journeys.Count -eq 7) `
    -Message 'the exact seven-stage journey order changed.'
  $accountJourneys = @(
    $journeys | Where-Object {
      [string]$_.id -cin @(
        'Google_account_selection_and_return',
        'Mobile_OTP',
        'Firebase_passwordless_email_link'
      )
    }
  )
  Assert-C34IActorPolicy -Condition (
    $accountJourneys.Count -eq 3 -and
    @($accountJourneys | Where-Object { [string]$_.actor -cne 'founder' }).Count -eq 0
  ) -Message 'an account-capable journey is not founder-owned.'

  Assert-C34IActorPolicy -Condition (
    [bool]$Policy.acceptance.deviceAcceptanceCountMayBecomeOneOnlyAfterEveryRequiredJourneyPasses -and
    [bool]$Policy.acceptance.allSixC33GBlockersRequireCandidateSpecificEvidence -and
    [bool]$Policy.acceptance.sanitizedEvidenceOnly -and
    -not [bool]$Policy.acceptance.productionReadinessImplied
  ) -Message 'device-acceptance or readiness truth changed.'
}

$policyResolved = Resolve-C34IActorPolicyFile -Path $PolicyPath -Label 'device-actor policy'
$policy = Get-Content -Raw -LiteralPath $policyResolved | ConvertFrom-Json
Test-C34IActorPolicyObject -Policy $policy

if ($SelfTest) {
  $forbiddenFixture = $policy | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $forbiddenFixture.actors.codex.allowedPredeclaredDeviceActions = @(
    $forbiddenFixture.actors.codex.allowedPredeclaredDeviceActions
  ) + 'tap_any_account_capable_identity_provider'
  $forbiddenRejected = $false
  try { Test-C34IActorPolicyObject -Policy $forbiddenFixture } catch { $forbiddenRejected = $true }

  $founderFixture = $policy | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $founderFixture.journeyOrder[3].actor = 'codex'
  $founderRejected = $false
  try { Test-C34IActorPolicyObject -Policy $founderFixture } catch { $founderRejected = $true }

  $privacyFixture = $policy | ConvertTo-Json -Depth 20 | ConvertFrom-Json
  $privacyFixture.failClosed.privateIdentifierVisibleToCodexRejectsCandidate = $false
  $privacyRejected = $false
  try { Test-C34IActorPolicyObject -Policy $privacyFixture } catch { $privacyRejected = $true }

  Assert-C34IActorPolicy -Condition (
    $forbiddenRejected -and $founderRejected -and $privacyRejected
  ) -Message 'one or more fail-closed self-test fixtures did not reject.'
}

$memoryGate = Resolve-C34IActorPolicyFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

Write-Output (
  'C34I privacy-safe device-actor policy passed: ' +
  "codexNever=$(@($policy.actors.codex.neverAllowedActions).Count); " +
  "founderOnly=$(@($policy.actors.founder.requiredActions).Count); " +
  "journeys=$(@($policy.journeyOrder).Count); selfTest=$([bool]$SelfTest); " +
  'secretOrPrivateValuesObserved=false; buildPlayOppoExternal=false.'
)
