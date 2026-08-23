[CmdletBinding()]
param(
  [ValidateSet('Prewrite', 'Postwrite')]
  [string]$Phase = 'Prewrite',
  [string]$RepositoryRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$repositoryPrefix = $RepositoryRoot.TrimEnd([char[]]@('\', '/')) +
  [IO.Path]::DirectorySeparatorChar

function Assert-C33K {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) {
    throw "C33K Firebase email-link live-readiness gate rejected: $Message"
  }
}

function Get-C33KGenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$C33KEvidenceExists
  )
  $c33kId = 'UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS'
  $c33kHash = '2104B114818AD7DE29671B0DFD14FF7F3E6510A6F5E95E9148CA5C5674C192FF'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33K current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $c33kId) {
    if ($SelectedTicketSha256 -cne $c33kHash) {
      throw 'C33K direct selection ticket hash changed.'
    }
    return 'C33K_active'
  }
  $qualified = $checkpoint.priorC33KSelectedTicketAssessment
  if (
    [string]$qualified.ticketId -cne $c33kId -or
    [string]$qualified.manifestPath -cne
      'config/uaw-c33k-firebase-passwordless-email-link-live-readiness-ticket.json' -or
    [string]$qualified.manifestSha256 -cne $c33kHash -or
    [string]$qualified.implementationState -cne
      'live_readiness_qualified_two_exact_Firebase_Authentication_writes_consumed_provider_domain_and_dual_origin_App_Links_readbacks_passed_live_email_release_and_device_held' -or
    [string]$qualified.evidencePath -cne
      'docs/quality/UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS-QUALIFICATION-20260815.md' -or
    -not $C33KEvidenceExists
  ) {
    throw 'C33K generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$statePath = Join-Path $RepositoryRoot `
  'config/firebase-passwordless-email-link-live-readiness-state-c33k.json'
$ticketPath = Join-Path $RepositoryRoot `
  'config/uaw-c33k-firebase-passwordless-email-link-live-readiness-ticket.json'
$scopePath = Join-Path $RepositoryRoot 'config/mvp-scope-gate-state.json'

foreach ($requiredPath in @($statePath, $ticketPath, $scopePath)) {
  Assert-C33K (Test-Path -LiteralPath $requiredPath -PathType Leaf) `
    "required owner is missing: $requiredPath"
}

$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expectedTicket = 'UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS'
$ticketHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$selectedManifestRelative =
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath
Assert-C33K (-not [IO.Path]::IsPathRooted($selectedManifestRelative)) `
  'selected ticket manifest must be repository-relative.'
$selectedManifestPath = [IO.Path]::GetFullPath(
  (Join-Path $RepositoryRoot $selectedManifestRelative)
)
Assert-C33K (
  $selectedManifestPath.StartsWith(
    $repositoryPrefix,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  (Test-Path -LiteralPath $selectedManifestPath -PathType Leaf)
) 'selected ticket manifest is missing or escaped the repository.'
$c33kEvidencePath = Join-Path $RepositoryRoot `
  'docs/quality/UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS-QUALIFICATION-20260815.md'
$selectionMode = Get-C33KGenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (
    Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifestPath
  ).Hash `
  -C33KEvidenceExists (
    Test-Path -LiteralPath $c33kEvidencePath -PathType Leaf
  )

Assert-C33K (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.ticketId -ceq $expectedTicket -and
  [string]$state.projectId -ceq 'moolsocial-dev-503018' -and
  [string]$ticket.ticketId -ceq $expectedTicket -and
  $ticketHash -ceq
    '2104B114818AD7DE29671B0DFD14FF7F3E6510A6F5E95E9148CA5C5674C192FF' -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized
) 'ticket or Dev project identity changed.'

Assert-C33K (
  [bool]$state.sanitizedBeforeFacts.phoneProviderEnabled -and
  [bool]$state.sanitizedBeforeFacts.googleProviderEnabled -and
  -not [bool]$state.sanitizedBeforeFacts.emailPasswordProviderEnabled -and
  -not [bool]$state.sanitizedBeforeFacts.passwordlessEmailLinkEnabled -and
  [bool]$state.sanitizedBeforeFacts.defaultFirebaseAppDomainAuthorized -and
  [bool]$state.sanitizedBeforeFacts.defaultWebAppDomainAuthorized -and
  -not [bool]$state.sanitizedBeforeFacts.moolSocialDomainAuthorized -and
  [bool]$state.sanitizedBeforeFacts.defaultFirebaseAppAssetLinksIdentityQualified -and
  [bool]$state.sanitizedBeforeFacts.moolSocialAssetLinksIdentityQualified
) 'sanitized prewrite live facts changed or are incomplete.'

Assert-C33K (
  [bool]$state.authority.emailProviderEnablementAuthorizedOnce -and
  [bool]$state.authority.authorizedDomainAdditionAuthorizedOnce -and
  -not [bool]$state.authority.hostingDeploymentAuthorized -and
  -not [bool]$state.authority.liveEmailSendAuthorized -and
  -not [bool]$state.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$state.authority.secretValueAccessAuthorized -and
  -not [bool]$state.privacy.secretValuesObserved -and
  -not [bool]$state.privacy.emailAddressObservedOrEntered -and
  -not [bool]$state.privacy.privateIdentityPayloadObserved
) 'authority or privacy boundary changed.'

Assert-C33K (
  [int]$state.actionCounts.hostingDeployment -eq 0 -and
  [int]$state.actionCounts.liveEmailSend -eq 0 -and
  [int]$state.actionCounts.aabBuild -eq 0 -and
  [int]$state.actionCounts.playUploadOrActivation -eq 0 -and
  [int]$state.actionCounts.oppoMutation -eq 0
) 'held action count advanced.'

if ($Phase -ceq 'Prewrite') {
  $prewriteStates = @(
    'prewrite_live_inventory_qualified_two_exact_configuration_writes_pending',
    'blocked_founder_console_reauthentication_or_IAM_refresh_required_zero_writes'
  )
  Assert-C33K (
    $prewriteStates -ccontains [string]$state.state -and
    [int]$state.actionCounts.emailProviderEnablement -eq 0 -and
    [int]$state.actionCounts.authorizedDomainAddition -eq 0
  ) 'prewrite state or exact action counts changed.'
} else {
  Assert-C33K (
    [string]$state.state -ceq
      'live_readiness_qualified_two_exact_configuration_writes_consumed' -and
    [int]$state.actionCounts.emailProviderEnablement -eq 1 -and
    [int]$state.actionCounts.authorizedDomainAddition -eq 1
  ) 'postwrite state or exact action counts changed.'
  Assert-C33K (
    [bool]$state.sanitizedAfterFacts.phoneProviderEnabled -and
    [bool]$state.sanitizedAfterFacts.googleProviderEnabled -and
    [bool]$state.sanitizedAfterFacts.emailPasswordProviderEnabled -and
    [bool]$state.sanitizedAfterFacts.passwordlessEmailLinkEnabled -and
    [bool]$state.sanitizedAfterFacts.defaultFirebaseAppDomainAuthorized -and
    [bool]$state.sanitizedAfterFacts.defaultWebAppDomainAuthorized -and
    [bool]$state.sanitizedAfterFacts.moolSocialDomainAuthorized -and
    [bool]$state.sanitizedAfterFacts.defaultFirebaseAppAssetLinksIdentityQualified -and
    [bool]$state.sanitizedAfterFacts.moolSocialAssetLinksIdentityQualified
  ) 'sanitized postwrite live facts are incomplete.'
}

Write-Output (
  "C33K Firebase email-link live-readiness gate passed: phase=$Phase; " +
  "selectionMode=$selectionMode; " +
  "project=moolsocial-dev-503018; Phone=true; Google=true; " +
  "EmailLink=$($Phase -ceq 'Postwrite'); domains=$($Phase -ceq 'Postwrite'); " +
  'HostingDeploy=0; liveEmail=0; buildPlayDevice=0; secretValuesObserved=false.'
)
