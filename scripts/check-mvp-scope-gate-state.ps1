[CmdletBinding()]
param(
  [string]$StatePath,

  [string]$CandidateId,

  [switch]$RequireExecutionAuthorized,

  [switch]$RequireSqlConnectProvisioningAuthorized,

  [switch]$RequireSqlConnectMigrationAuthorized,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path `
    $repositoryRootFull `
    'config/mvp-scope-gate-state.json'
}

function Assert-MvpScopeGate {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "MVP scope gate rejected: $Message"
  }
}

function Resolve-RepositoryFile {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-MvpScopeGate `
    -Condition (-not [string]::IsNullOrWhiteSpace($RelativePath)) `
    -Message "$Label path is missing."
  Assert-MvpScopeGate `
    -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) `
    -Message "$Label path must be repository-relative."
  $resolved = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRootFull $RelativePath)
  )
  Assert-MvpScopeGate -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "$Label escaped the production repository."
  Assert-MvpScopeGate `
    -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) `
    -Message "$Label is missing: $resolved"
  return $resolved
}

$statePathInput = $StatePath
if (-not [IO.Path]::IsPathRooted($statePathInput)) {
  $statePathInput = Join-Path $repositoryRootFull $statePathInput
}
$resolvedStatePath = [IO.Path]::GetFullPath($statePathInput)
Assert-MvpScopeGate -Condition (
  $resolvedStatePath.StartsWith(
    $repositoryPrefix,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'machine state must stay inside the production repository.'
Assert-MvpScopeGate `
  -Condition (Test-Path -LiteralPath $resolvedStatePath -PathType Leaf) `
  -Message "machine state is missing: $resolvedStatePath"

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
Assert-MvpScopeGate -Condition ([int]$state.schemaVersion -eq 1) `
  -Message 'unsupported machine-state schema.'
Assert-MvpScopeGate -Condition (
  [string]$state.contractId -ceq 'MOOLSOCIAL-MVP-SCOPE-GATE-STATE-001'
) -Message 'unexpected machine-state contract id.'

$policyPath = Resolve-RepositoryFile `
  -RelativePath ([string]$state.policy) `
  -Label 'MVP scope policy'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
Assert-MvpScopeGate -Condition ([int]$policy.schemaVersion -eq 2) `
  -Message 'unsupported policy schema.'
Assert-MvpScopeGate -Condition (
  [string]$policy.policyId -ceq 'MOOLSOCIAL-MVP-SCOPE-POLICY-V2-20260805'
) -Message 'unexpected policy id.'
Assert-MvpScopeGate -Condition (
  [string]$policy.state -ceq 'founder_directed_active'
) -Message 'MVP policy is not active.'

$requiredRules = @(
  'discloseBeforeExecution',
  'preferSmallestCompleteJourney',
  'oneLogicalTicketAtATime',
  'noOpportunisticExpansion',
  'mvpClassificationDoesNotCreateAuthority',
  'beyondMvpRequiresSeparateExactFounderAuthorization',
  'existingProtectedAndEnvironmentGatesRemainMandatory',
  'failClosedWhenClassificationOrDisclosureIsMissing',
  'robust60To75DayDeliveryLockRequired',
  'preTicketSelectionReuseAssessmentRequired',
  'noDuplicateScreensRoutesOrBackendOwnersPerUserType',
  'ticketCountDoesNotImplyImplementationOwnerCount',
  'newImplementationOwnerRequiresNecessityProof',
  'robustnessCannotBeReducedForTimeline',
  'sqlConnectSingleAuthoritativeMappingAfterCompleteContracts',
  'sqlConnectMultipleAttemptsAndDuplicateMigrationsForbidden',
  'sqlConnectPartialBusinessLogicSchemaForbidden',
  'sqlConnectPreCompletionScopeLimitedToCompleteSharedGlobalCapabilities'
)
foreach ($ruleName in $requiredRules) {
  $rule = $policy.rules.PSObject.Properties[$ruleName]
  Assert-MvpScopeGate -Condition (
    $null -ne $rule -and [bool]$rule.Value
  ) -Message "required rule '$ruleName' is not enabled."
}

$sqlConnectRule = $policy.sqlConnectCompletionRule
$expectedSqlConnectFields = @(
  'state','authorityDate','singleAuthoritativeDatabaseMapping',
  'mappingEntryCondition','multipleProvisioningAttemptsAllowed',
  'duplicateOrRepeatedMigrationsAllowed',
  'partialOrUnderdevelopedBusinessLogicSchemaAllowed',
  'provisionalMainOrSubactionDomainSchemaAllowed',
  'preCompletionBackendScope','preCompletionExcludedScope',
  'currentSqlConnectProvisioningAuthorized',
  'currentSqlConnectMigrationAuthorized',
  'founderReactivationRequiresCompleteDatabaseMapAndFreshExactAuthorization'
)
$actualSqlConnectFields = @($sqlConnectRule.PSObject.Properties.Name)
Assert-MvpScopeGate -Condition (
  $actualSqlConnectFields.Count -eq $expectedSqlConnectFields.Count -and
  (@($actualSqlConnectFields | Sort-Object) -join '|') -ceq
    (@($expectedSqlConnectFields | Sort-Object) -join '|')
) -Message 'SQL Connect completion-rule schema changed.'
Assert-MvpScopeGate -Condition (
  [string]$sqlConnectRule.state -ceq 'founder_locked_active' -and
  [bool]$sqlConnectRule.singleAuthoritativeDatabaseMapping -and
  -not [bool]$sqlConnectRule.multipleProvisioningAttemptsAllowed -and
  -not [bool]$sqlConnectRule.duplicateOrRepeatedMigrationsAllowed -and
  -not [bool]$sqlConnectRule.partialOrUnderdevelopedBusinessLogicSchemaAllowed -and
  -not [bool]$sqlConnectRule.provisionalMainOrSubactionDomainSchemaAllowed -and
  [bool]$sqlConnectRule.founderReactivationRequiresCompleteDatabaseMapAndFreshExactAuthorization -and
  @($sqlConnectRule.preCompletionBackendScope).Count -gt 0 -and
  @($sqlConnectRule.preCompletionExcludedScope).Count -gt 0
) -Message 'SQL Connect founder completion rule is weakened or incomplete.'
if ($RequireSqlConnectProvisioningAuthorized) {
  Assert-MvpScopeGate -Condition (
    [bool]$sqlConnectRule.currentSqlConnectProvisioningAuthorized
  ) -Message (
    'SQL Connect provisioning is founder-held until the complete database map ' +
    'and a fresh exact authorization exist.'
  )
}
if ($RequireSqlConnectMigrationAuthorized) {
  Assert-MvpScopeGate -Condition (
    [bool]$sqlConnectRule.currentSqlConnectMigrationAuthorized
  ) -Message (
    'SQL Connect migration is founder-held; duplicate, repeated or partial ' +
    'business-logic migrations are forbidden.'
  )
}

$deliveryDisciplineGatePath = Join-Path `
  $repositoryRootFull `
  'scripts/check-mvp-delivery-discipline-lock.ps1'
Assert-MvpScopeGate `
  -Condition (Test-Path -LiteralPath $deliveryDisciplineGatePath -PathType Leaf) `
  -Message 'delivery-discipline machine gate is missing.'
& $deliveryDisciplineGatePath `
  -StatePath $resolvedStatePath `
  -RepositoryRoot $repositoryRootFull `
  -RequireTicketSelectionAssessment:$RequireExecutionAuthorized

$executionAuthorized = (
  [bool]$state.execution.referenceWriteAuthorized -or
  [bool]$state.execution.runtimeWriteAuthorized -or
  [bool]$state.execution.testOrGateWriteAuthorized -or
  [bool]$state.execution.backendWriteAuthorized -or
  [bool]$state.execution.buildAuthorized -or
  [bool]$state.execution.deviceInstallAuthorized -or
  [bool]$state.execution.externalServiceWriteAuthorized
)

if (-not $executionAuthorized) {
  Assert-MvpScopeGate -Condition (
    [string]$state.state -ceq 'awaiting_next_ticket_classification'
  ) -Message 'closed state must await the next ticket classification.'
  Assert-MvpScopeGate -Condition (
    [string]::IsNullOrWhiteSpace([string]$state.ticket.id)
  ) -Message 'closed state contains an unexpected ticket id.'
  Assert-MvpScopeGate -Condition (
    -not [bool]$state.checkpoint.successorRegistered
  ) -Message 'closed state claims a successor is registered.'
  if ($RequireExecutionAuthorized) {
    throw (
      'MVP scope gate rejected: execution is not authorized; disclose and ' +
      'classify the exact ticket before runtime, backend, build, install or ' +
      'external-service work.'
    )
  }
  Write-Output (
    'MVP scope gate passed closed: state=' +
    "$($state.state); ticket=none; executionAuthorized=false."
  )
  return
}

Assert-MvpScopeGate -Condition (
  [string]$state.state -ceq 'ticket_disclosed_and_authorized'
) -Message 'authorized execution requires disclosed-and-authorized state.'
$ticketId = [string]$state.ticket.id
Assert-MvpScopeGate `
  -Condition (-not [string]::IsNullOrWhiteSpace($ticketId)) `
  -Message 'authorized execution is missing a ticket id.'
if (-not [string]::IsNullOrWhiteSpace($CandidateId)) {
  Assert-MvpScopeGate -Condition ($ticketId -ceq $CandidateId) `
    -Message 'ticket id differs from the build candidate.'
}

$classification = [string]$state.ticket.classification
Assert-MvpScopeGate -Condition (
  @($policy.classifications) -ccontains $classification
) -Message "unsupported MVP classification '$classification'."
foreach ($field in @(
    'customerOutcome',
    'classificationReason'
  )) {
  Assert-MvpScopeGate -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$state.ticket.$field)
  ) -Message "ticket field '$field' is missing."
}
foreach ($field in @(
    'minimumCompleteScope',
    'explicitExclusions',
    'dependenciesAndApprovals',
    'testAndEvidencePlan'
  )) {
  Assert-MvpScopeGate -Condition (@($state.ticket.$field).Count -gt 0) `
    -Message "ticket field '$field' is empty."
}

Assert-MvpScopeGate -Condition (
  [string]$state.founderDisclosure.state -ceq 'presented_before_execution'
) -Message 'founder disclosure was not recorded before execution.'
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$state.founderDisclosure.evidence) `
  -Label 'founder disclosure evidence')

if ($classification -ceq 'beyond_mvp') {
  Assert-MvpScopeGate -Condition (
    [string]$state.authorization.state -ceq
    'explicit_beyond_mvp_founder_authorization'
  ) -Message 'beyond-MVP work lacks exact founder authorization.'
  Assert-MvpScopeGate -Condition (
    [bool]$state.authorization.beyondMvpExplicitlyAuthorized
  ) -Message 'beyond-MVP authorization flag is false.'
} else {
  Assert-MvpScopeGate -Condition (
    [string]$state.authorization.state -cin @(
      'existing_ticket_authority_confirmed',
      'founder_acknowledged_mvp_scope'
    )
  ) -Message 'MVP work lacks an applicable existing authority.'
  Assert-MvpScopeGate -Condition (
    -not [bool]$state.authorization.beyondMvpExplicitlyAuthorized
  ) -Message 'MVP ticket incorrectly claims beyond-MVP authorization.'
}
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$state.authorization.evidence) `
  -Label 'ticket authorization evidence')

Write-Output (
  'MVP scope gate passed authorized: ' +
  "ticket=$ticketId; classification=$classification."
)
