[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet(
    'founder-inputs-validated',
    'prebuild-failed',
    'build-start',
    'build-failed',
    'build-succeeded',
    'upload-authorized',
    'upload-succeeded',
    'install-authorized',
    'install-succeeded',
    'device-accepted',
    'reject'
  )]
  [string]$Transition,

  [Parameter(Mandatory)]
  [string]$StatePath,

  [string]$ArtifactPath,
  [string]$ArtifactSha256,
  [long]$ArtifactBytes,
  [string]$UploadSignerSha256,
  [string]$ArtifactProvenance,
  [string]$EvidencePath,
  [string]$RejectionMachineState,
  [string]$RejectionRegistryId,
  [switch]$FixtureMode,
  [switch]$InjectFailureAfterStateCommit,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'

function Assert-C34JTransition {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34J lifecycle transition rejected: $Message"
  }
}

function Resolve-C34JTransitionPath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label,
    [switch]$AllowMissing
  )
  Assert-C34JTransition -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34JTransition -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the production repository."
  if (-not $AllowMissing) {
    Assert-C34JTransition -Condition (
      Test-Path -LiteralPath $resolved -PathType Leaf
    ) -Message "$Label is missing."
  }
  return $resolved
}

function Assert-C34JCommonParity {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  Assert-C34JTransition -Condition (
    [string]$State.ticketId -ceq $ticketId -and
    [string]$State.candidate.id -ceq $ticketId -and
    [string]$Aggregate.ticketId -ceq $ticketId -and
    [string]$Aggregate.candidate.id -ceq $ticketId -and
    [string]$State.machineState -ceq [string]$Aggregate.machineState -and
    [int]$State.actionCounts.build -eq [int]$Aggregate.actionCounts.build -and
    [int]$State.actionCounts.upload -eq [int]$Aggregate.actionCounts.upload -and
    [int]$State.actionCounts.install -eq [int]$Aggregate.actionCounts.install -and
    [int]$State.actionCounts.deviceAcceptance -eq
      [int]$Aggregate.actionCounts.deviceAcceptance -and
    [int]$Aggregate.candidate.buildCount -eq [int]$State.actionCounts.build -and
    [int]$Aggregate.candidate.uploadCount -eq [int]$State.actionCounts.upload -and
    [int]$Aggregate.candidate.installCount -eq [int]$State.actionCounts.install -and
    [int]$Aggregate.candidate.deviceAcceptanceCount -eq
      [int]$State.actionCounts.deviceAcceptance -and
    [string]$State.releaseAuthorities.build -ceq
      [string]$Aggregate.releaseAuthorities.build -and
    [string]$State.releaseAuthorities.uploadAndInternalActivation -ceq
      [string]$Aggregate.releaseAuthorities.uploadAndInternalActivation -and
    [string]$State.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
      [string]$Aggregate.releaseAuthorities.inPlaceOppoPlayUpdate -and
    [string]$State.releaseAuthorities.postinstallAcceptance -ceq
      [string]$Aggregate.releaseAuthorities.postinstallAcceptance -and
    [string]$State.candidate.disposition -ceq
      [string]$Aggregate.candidate.disposition -and
    [bool]$State.candidate.artifactReusable -eq
      [bool]$Aggregate.candidate.artifactReusable
  ) -Message 'detailed and aggregate identity, state, count, authority, disposition or reuse parity changed.'
}

function Set-C34JMachineAndDisposition {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$Value
  )
  $State.machineState = $Value
  $Aggregate.machineState = $Value
  $State.candidate.disposition = $Value
  $Aggregate.candidate.disposition = $Value
}

$stateFile = Resolve-C34JTransitionPath -Path $StatePath -Label 'detailed state'
$stateOriginal = [IO.File]::ReadAllText($stateFile)
$state = $stateOriginal | ConvertFrom-Json
$aggregateFile = Resolve-C34JTransitionPath `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'aggregate state'
$aggregateOriginal = [IO.File]::ReadAllText($aggregateFile)
$aggregate = $aggregateOriginal | ConvertFrom-Json

Assert-C34JCommonParity -State $state -Aggregate $aggregate
if ($InjectFailureAfterStateCommit) {
  Assert-C34JTransition -Condition $FixtureMode `
    -Message 'failure injection is fixture-only.'
  $fixturePrefix = [IO.Path]::GetFullPath((Join-Path $root 'tmp/c34j-lifecycle-fixtures'))
  Assert-C34JTransition -Condition (
    $stateFile.StartsWith($fixturePrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message 'failure injection state is outside the C34J fixture root.'
}

switch ($Transition) {
  'founder-inputs-validated' {
    $expected =
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required'
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq $expected -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [string]$state.releaseAuthorities.build -ceq 'available_once' -and
      [int]$state.actionCounts.build -eq 0 -and
      [bool]$state.authority.founderHiddenInputEntryAuthorized -and
      -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
      -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
      -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
      -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
    ) -Message 'founder-input preconditions changed.'
    $state.founderAuthorization.hiddenFounderInputsEntered = $true
    $state.authority.founderHiddenInputEntryAuthorized = $false
    $state.runtimeConfiguration.secretDefineFileQualifiedByFounder = $true
    $state.runtimeConfiguration.googleServicesFileQualifiedByFounder = $true
    $state.runtimeConfiguration.googleServerClientIdQualifiedByFounder = $true
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate `
      -Value 'founder_inputs_validated_single_aab_build_required'
  }
  'build-start' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'founder_inputs_validated_single_aab_build_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [string]$state.releaseAuthorities.build -ceq 'available_once' -and
      [int]$state.actionCounts.build -eq 0 -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
      [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
      [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
      [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
    ) -Message 'build-start preconditions changed.'
    $value = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.buildAuthorization = 'consumed'
    $state.releaseAuthorities.build = 'consumed'
    $aggregate.releaseAuthorities.build = 'consumed'
    $state.actionCounts.build = 1
    $aggregate.actionCounts.build = 1
    $aggregate.candidate.buildCount = 1
    $state.buildResult.state = $value
    $state.buildResult.buildCount = 1
    $state.buildResult.wrapperInvocationCount = 1
    $state.buildResult.configOnlyCount = 1
  }
  'prebuild-failed' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'founder_inputs_validated_single_aab_build_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [string]$state.releaseAuthorities.build -ceq 'available_once' -and
      [int]$state.actionCounts.build -eq 0 -and
      [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'prebuild-failure preconditions changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath `
        -Label 'prebuild failure owner')
    }
    $value = 'founder_inputs_validated_prebuild_failed_successor_required'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.buildAuthorization = 'rejected_candidate'
    $state.uploadAuthorization = 'rejected_candidate'
    $state.installAuthorization = 'rejected_candidate'
    $state.deviceAuthorization = 'rejected_candidate'
    foreach ($name in @(
      'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
      'postinstallAcceptance'
    )) {
      $state.releaseAuthorities.$name = 'rejected_candidate'
      $aggregate.releaseAuthorities.$name = 'rejected_candidate'
    }
    $state.candidate.disposition = 'rejected'
    $aggregate.candidate.disposition = 'rejected'
    $state.candidate.artifactReusable = $false
    $aggregate.candidate.artifactReusable = $false
    $rejection = [ordered]@{
      disposition = 'rejected'
      reason = 'founder_inputs_validated_prebuild_failure_registration_required'
      evidencePath = $EvidencePath
      artifactReusable = $false
      successorRequired = $true
      buildCount = 0
      uploadCount = 0
      installCount = 0
      deviceAcceptanceCount = 0
    }
    $state.rejection = [pscustomobject]$rejection
    $aggregate.rejection = [pscustomobject]$rejection
  }
  'build-succeeded' {
    $inProgress =
      'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq $inProgress -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [string]$state.releaseAuthorities.build -ceq 'consumed' -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactSha256) -and
      [string]$ArtifactSha256 -cmatch '^[0-9A-F]{64}$' -and
      [string]$UploadSignerSha256 -cmatch '^[0-9A-F]{64}$' -and
      $ArtifactBytes -gt 0 -and
      -not [string]::IsNullOrWhiteSpace($ArtifactPath) -and
      -not [string]::IsNullOrWhiteSpace($ArtifactProvenance)
    ) -Message 'build-success preconditions or artifact identity changed.'
    if (-not $FixtureMode) {
      $artifactFile = Resolve-C34JTransitionPath -Path $ArtifactPath -Label 'sealed AAB'
      Assert-C34JTransition -Condition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactFile).Hash -ceq
          $ArtifactSha256 -and
        (Get-Item -LiteralPath $artifactFile).Length -eq $ArtifactBytes
      ) -Message 'sealed AAB bytes do not match the supplied identity.'
      [void](Resolve-C34JTransitionPath -Path $ArtifactProvenance -Label 'AAB provenance')
    }
    $value = 'single_release_AAB_succeeded_authority_consumed'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.buildResult.state = $value
    $state.buildResult.artifactPath = $ArtifactPath
    $state.buildResult.artifactSha256 = $ArtifactSha256
    $state.buildResult.artifactBytes = $ArtifactBytes
    $state.buildResult.uploadSignerSha256 = $UploadSignerSha256
    $state.buildResult.packageVersionManifestProved = $true
    $state.buildResult.googleAppIdResourceProved = $true
    $state.buildResult.crashlyticsBuildIdResourceProved = $true
    $state.buildResult.splitAndArm64PayloadProved = $true
    $state.buildResult.mergedReleaseManifestProved = $true
    $state.buildResult.provenance = $ArtifactProvenance
    $aggregate.candidate.aabSha256 = $ArtifactSha256
    $state.candidate.artifactReusable = $true
    $aggregate.candidate.artifactReusable = $true
  }
  'build-failed' {
    $inProgress =
      'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq $inProgress -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [string]$state.releaseAuthorities.build -ceq 'consumed' -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactSha256) -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'build-failure preconditions changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath -Label 'build failure evidence')
    }
    $value = 'single_release_AAB_failed_authority_consumed_successor_required'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.buildResult.state = $value
    $state.uploadAuthorization = 'rejected_candidate'
    $state.installAuthorization = 'rejected_candidate'
    $state.deviceAuthorization = 'rejected_candidate'
    $state.releaseAuthorities.uploadAndInternalActivation = 'rejected_candidate'
    $state.releaseAuthorities.inPlaceOppoPlayUpdate = 'rejected_candidate'
    $state.releaseAuthorities.postinstallAcceptance = 'rejected_candidate'
    $aggregate.releaseAuthorities.uploadAndInternalActivation = 'rejected_candidate'
    $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'rejected_candidate'
    $aggregate.releaseAuthorities.postinstallAcceptance = 'rejected_candidate'
    $state.candidate.disposition = 'rejected'
    $aggregate.candidate.disposition = 'rejected'
    $state.candidate.artifactReusable = $false
    $aggregate.candidate.artifactReusable = $false
    $rejection = [ordered]@{
      disposition = 'rejected'
      reason = 'single_release_AAB_build_failed_registration_required'
      evidencePath = $EvidencePath
      artifactReusable = $false
      successorRequired = $true
      buildCount = 1
      uploadCount = 0
      installCount = 0
      deviceAcceptanceCount = 0
    }
    $state.rejection = [pscustomobject]$rejection
    $aggregate.rejection = [pscustomobject]$rejection
  }
  'upload-authorized' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'single_release_AAB_succeeded_authority_consumed' -and
      [string]$state.uploadAuthorization -ceq 'held_postbuild_qualification' -and
      [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
        'held_postbuild_qualification' -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.actionCounts.upload -eq 0 -and
      [bool]$state.candidate.artifactReusable
    ) -Message 'upload-authorization preconditions changed.'
    $value = 'postbuild_qualified_internal_testing_upload_authority_available_once'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.uploadAuthorization = 'available_once'
    $state.releaseAuthorities.uploadAndInternalActivation = 'available_once'
    $aggregate.releaseAuthorities.uploadAndInternalActivation = 'available_once'
  }
  'upload-succeeded' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'postbuild_qualified_internal_testing_upload_authority_available_once' -and
      [string]$state.uploadAuthorization -ceq 'available_once' -and
      [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
        'available_once' -and
      [int]$state.actionCounts.upload -eq 0 -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'upload-success preconditions changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath -Label 'Play activation evidence')
    }
    $value = 'internal_testing_upload_activation_succeeded_authority_consumed'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.uploadAuthorization = 'consumed'
    $state.releaseAuthorities.uploadAndInternalActivation = 'consumed'
    $aggregate.releaseAuthorities.uploadAndInternalActivation = 'consumed'
    $state.actionCounts.upload = 1
    $aggregate.actionCounts.upload = 1
    $aggregate.candidate.uploadCount = 1
    $state.playResult.uploadCount = 1
    $state.playResult.internalActivationCount = 1
    $state.playResult.evidencePath = $EvidencePath
  }
  'install-authorized' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'internal_testing_upload_activation_succeeded_authority_consumed' -and
      [string]$state.installAuthorization -ceq 'held_postupload_qualification' -and
      [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
        'held_postupload_qualification' -and
      [int]$state.actionCounts.upload -eq 1 -and
      [int]$state.actionCounts.install -eq 0
    ) -Message 'install-authorization preconditions changed.'
    $value = 'postupload_qualified_in_place_oppo_play_update_authority_available_once'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.installAuthorization = 'available_once'
    $state.releaseAuthorities.inPlaceOppoPlayUpdate = 'available_once'
    $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'available_once'
  }
  'install-succeeded' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'postupload_qualified_in_place_oppo_play_update_authority_available_once' -and
      [string]$state.installAuthorization -ceq 'available_once' -and
      [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
        'available_once' -and
      [int]$state.actionCounts.install -eq 0 -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'install-success preconditions changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath -Label 'OPPO update evidence')
    }
    $value = 'oppo_play_in_place_update_succeeded_postinstall_acceptance_held'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.installAuthorization = 'consumed'
    $state.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
    $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
    $state.actionCounts.install = 1
    $aggregate.actionCounts.install = 1
    $aggregate.candidate.installCount = 1
    $state.installResult.installCount = 1
    $state.installResult.coldStartEvidencePath = $EvidencePath
  }
  'device-accepted' {
    Assert-C34JTransition -Condition (
      [string]$state.machineState -ceq
        'oppo_play_in_place_update_succeeded_postinstall_acceptance_held' -and
      [string]$state.deviceAuthorization -ceq
        'held_postinstall_journey_qualification' -and
      [string]$state.releaseAuthorities.postinstallAcceptance -ceq
        'held_postinstall_journey_qualification' -and
      [int]$state.actionCounts.install -eq 1 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0 -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'device-acceptance preconditions changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath -Label 'device journey evidence')
    }
    $value = 'internal_testing_oppo_device_acceptance_succeeded'
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate -Value $value
    $state.deviceAuthorization = 'consumed'
    $state.releaseAuthorities.postinstallAcceptance = 'consumed'
    $aggregate.releaseAuthorities.postinstallAcceptance = 'consumed'
    $state.actionCounts.deviceAcceptance = 1
    $aggregate.actionCounts.deviceAcceptance = 1
    $aggregate.candidate.deviceAcceptanceCount = 1
    $state.installResult.journeyEvidencePath = $EvidencePath
    $state.installResult.acceptanceSucceeded = $true
    $state.candidate.artifactReusable = $false
    $aggregate.candidate.artifactReusable = $false
  }
  'reject' {
    Assert-C34JTransition -Condition (
      $RejectionMachineState -cmatch '^.+_successor_required$' -and
      $RejectionRegistryId -cmatch '^REG-[0-9]{8}-[0-9]+-.+$' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath) -and
      $null -eq $state.rejection -and
      $null -eq $aggregate.rejection
    ) -Message 'rejection identity, evidence or one-time state changed.'
    if (-not $FixtureMode) {
      [void](Resolve-C34JTransitionPath -Path $EvidencePath -Label 'rejection evidence')
    }
    Set-C34JMachineAndDisposition -State $state -Aggregate $aggregate `
      -Value $RejectionMachineState
    foreach ($name in @(
      'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
      'postinstallAcceptance'
    )) {
      if ([string]$state.releaseAuthorities.$name -cne 'consumed') {
        $state.releaseAuthorities.$name = 'rejected_candidate'
        $aggregate.releaseAuthorities.$name = 'rejected_candidate'
      }
    }
    if ([string]$state.releaseAuthorities.build -cne 'consumed') {
      $state.buildAuthorization = 'rejected_candidate'
      $state.releaseAuthorities.build = 'rejected_candidate'
      $aggregate.releaseAuthorities.build = 'rejected_candidate'
    }
    $state.uploadAuthorization = if (
      [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'consumed'
    ) { 'consumed' } else { 'rejected_candidate' }
    $state.installAuthorization = if (
      [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'consumed'
    ) { 'consumed' } else { 'rejected_candidate' }
    $state.deviceAuthorization = if (
      [string]$state.releaseAuthorities.postinstallAcceptance -ceq 'consumed'
    ) { 'consumed' } else { 'rejected_candidate' }
    $state.candidate.disposition = 'rejected'
    $aggregate.candidate.disposition = 'rejected'
    $state.candidate.artifactReusable = $false
    $aggregate.candidate.artifactReusable = $false
    $rejection = [ordered]@{
      disposition = 'rejected'
      reasonRegistryIds = @($RejectionRegistryId)
      evidencePath = $EvidencePath
      artifactReusable = $false
      successorRequired = $true
      buildCount = [int]$state.actionCounts.build
      uploadCount = [int]$state.actionCounts.upload
      installCount = [int]$state.actionCounts.install
      deviceAcceptanceCount = [int]$state.actionCounts.deviceAcceptance
    }
    $state.rejection = [pscustomobject]$rejection
    $aggregate.rejection = [pscustomobject]$rejection
  }
}

Assert-C34JCommonParity -State $state -Aggregate $aggregate
$stateJson = ($state | ConvertTo-Json -Depth 50) + [Environment]::NewLine
$aggregateJson = ($aggregate | ConvertTo-Json -Depth 50) + [Environment]::NewLine
[void]($stateJson | ConvertFrom-Json)
[void]($aggregateJson | ConvertFrom-Json)

$suffix = '.c34j-transition-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
$stateTemp = $stateFile + $suffix + '.state'
$aggregateTemp = $aggregateFile + $suffix + '.aggregate'
$stateRestore = $stateFile + $suffix + '.restore'
$aggregateRestore = $aggregateFile + $suffix + '.restore'
$stateCommitted = $false
$aggregateCommitted = $false
try {
  [IO.File]::WriteAllText($stateTemp, $stateJson, [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText(
    $aggregateTemp, $aggregateJson, [Text.UTF8Encoding]::new($false)
  )
  Move-Item -LiteralPath $stateTemp -Destination $stateFile -Force
  $stateCommitted = $true
  if ($InjectFailureAfterStateCommit) {
    throw 'C34J fixture injected failure after detailed-state commit.'
  }
  Move-Item -LiteralPath $aggregateTemp -Destination $aggregateFile -Force
  $aggregateCommitted = $true
} catch {
  if ($stateCommitted) {
    [IO.File]::WriteAllText(
      $stateRestore, $stateOriginal, [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $stateRestore -Destination $stateFile -Force
  }
  if ($aggregateCommitted) {
    [IO.File]::WriteAllText(
      $aggregateRestore, $aggregateOriginal, [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $aggregateRestore -Destination $aggregateFile -Force
  }
  throw
} finally {
  foreach ($temporary in @(
    $stateTemp, $aggregateTemp, $stateRestore, $aggregateRestore
  )) {
    if (Test-Path -LiteralPath $temporary) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
}

Write-Output (
  'C34J lifecycle transition passed: ' +
  "transition=$Transition; state=$($state.machineState); " +
  "counts=$($state.actionCounts.build)/$($state.actionCounts.upload)/" +
  "$($state.actionCounts.install)/$($state.actionCounts.deviceAcceptance); " +
  'detailedAggregateParity=true.'
)
