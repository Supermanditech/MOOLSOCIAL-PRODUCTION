[CmdletBinding()]
param(
  [ValidateSet('implementation', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'implementation',

  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c33f.json',

  [string]$ScopePath = 'config/mvp-scope-gate-state.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33F {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33F r60.49 successor release gate rejected: $Message"
  }
}

function Resolve-C33FFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33F -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Assert-C33FSanitizedText {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Label
  )
  foreach ($pattern in @(
    'AIza[0-9A-Za-z_-]{35}',
    '[0-9]{6,}-[0-9A-Za-z_-]+[.]apps[.]googleusercontent[.]com',
    'Bearer\s+[A-Za-z0-9._~+/-]+=*',
    '-----BEGIN [^-]*PRIVATE KEY-----',
    'eyJ[A-Za-z0-9_-]+[.]eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+'
  )) {
    Assert-C33F -Condition (-not [regex]::IsMatch($Text, $pattern)) `
      -Message "$Label contains a credential-, token- or private-key-shaped value."
  }
  Assert-C33F -Condition (
    -not [regex]::IsMatch(
      $Text,
      '(?i)"(?:apiKey|oauthClientId|clientSecret|accessToken|refreshToken|idToken|nonce|privateKey|attestationPayload|appCheckToken)"\s*:'
    )
  ) -Message "$Label contains a forbidden private-value property."
}

function Find-C33FRequiredText {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Needle,
    [Parameter(Mandatory)][string]$Label
  )
  $index = $Text.IndexOf($Needle, [StringComparison]::Ordinal)
  Assert-C33F -Condition ($index -ge 0) -Message "$Label is missing."
  return $index
}

function Assert-C33FPowerShellOwner {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C33F -Condition (@($errors).Count -eq 0) `
    -Message "$Label PowerShell parser rejected the current owner."
}

$ticketId =
  'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
$ticketSha256 = '815C70015058DE27B0F117517FB7599F6D7D99D340A217D65F9BFF3E163660C2'
$ticketPath = Resolve-C33FFile `
  -Path 'config/uaw-c33f-r60-49-google-auth-successor-aab-play-internal-oppo-acceptance-ticket.json' `
  -Label 'C33F ticket'
Assert-C33F -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq $ticketSha256
) -Message 'ticket bytes changed.'
$ticketRaw = Get-Content -Raw -LiteralPath $ticketPath
Assert-C33FSanitizedText -Text $ticketRaw -Label 'ticket'
$ticket = $ticketRaw | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.state -ceq
    'founder_authorized_exact_candidate_registered_live_readiness_and_source_requalification_required' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$ticket.candidate.versionCode -ceq '2026081349' -and
  [string]$ticket.candidate.playTrack -ceq 'internal' -and
  [bool]$ticket.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$ticket.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$ticket.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  -not [bool]$ticket.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$ticket.authority.otherTrackAuthorized -and
  -not [bool]$ticket.authority.adbOrSideloadAuthorized -and
  -not [bool]$ticket.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$ticket.authority.providerDeploymentAuthorized -and
  -not [bool]$ticket.authority.emailOrQuotaSubmissionAuthorized
) -Message 'ticket identity, candidate or authority changed.'

$fix4TicketPath = Resolve-C33FFile `
  -Path 'config/uaw-c33f-fix4-hidden-founder-input-flag-prebuild-gate-order-ticket.json' `
  -Label 'C33F FIX4 ticket'
$fix4TicketSha256 = '102B3B6AE7B934567B58F330742D726B5B5636B700F9E84B898C0D31DFEFE3B7'
Assert-C33F -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix4TicketPath).Hash -ceq
    $fix4TicketSha256
) -Message 'C33F FIX4 ticket bytes changed.'
$fix4TicketRaw = Get-Content -Raw -LiteralPath $fix4TicketPath
Assert-C33FSanitizedText -Text $fix4TicketRaw -Label 'C33F FIX4 ticket'
$fix4Ticket = $fix4TicketRaw | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$fix4Ticket.ticketId -ceq
    'UAW-C33F-FIX4-HIDDEN-FOUNDER-INPUT-FLAG-PREBUILD-GATE-ORDER' -and
  [string]$fix4Ticket.parentTicket -ceq $ticketId -and
  [string]$fix4Ticket.finding -ceq
    'REG-20260815-2412-C33F-HIDDEN-FOUNDER-INPUT-FLAG-PREBUILD-GATE-DEADLOCK' -and
  [string]$fix4Ticket.classification -ceq 'mvp_required' -and
  [bool]$fix4Ticket.authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$fix4Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.buildPlayOrDeviceInstallAuthorizedDuringFix -and
  -not [bool]$fix4Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$fix4Ticket.authority.secretValueAccessAuthorized
) -Message 'C33F FIX4 ticket identity, classification or authority changed.'

$fix5TicketPath = Resolve-C33FFile `
  -Path 'config/uaw-c33f-fix5-phase-aware-postbuild-play-install-gate-ticket.json' `
  -Label 'C33F FIX5 ticket'
$fix5TicketSha256 = '761F287AF70FEB61426CD0523E354829603696BD9232A6908F6441FC635CD5EC'
Assert-C33F -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix5TicketPath).Hash -ceq
    $fix5TicketSha256
) -Message 'C33F FIX5 ticket bytes changed.'
$fix5TicketRaw = Get-Content -Raw -LiteralPath $fix5TicketPath
Assert-C33FSanitizedText -Text $fix5TicketRaw -Label 'C33F FIX5 ticket'
$fix5Ticket = $fix5TicketRaw | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$fix5Ticket.ticketId -ceq
    'UAW-C33F-FIX5-PHASE-AWARE-POSTBUILD-PLAY-INSTALL-GATE' -and
  [string]$fix5Ticket.parentTicket -ceq $ticketId -and
  @($fix5Ticket.findings).Count -eq 4 -and
  [string]$fix5Ticket.classification -ceq 'mvp_required' -and
  [bool]$fix5Ticket.authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$fix5Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix5Ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$fix5Ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$fix5Ticket.authority.aabRebuildAuthorizedDuringFix -and
  -not [bool]$fix5Ticket.authority.playOrDeviceActionAuthorizedDuringFix -and
  -not [bool]$fix5Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$fix5Ticket.authority.secretValueAccessAuthorized
) -Message 'C33F FIX5 ticket identity, classification or authority changed.'

$fix6TicketPath = Resolve-C33FFile `
  -Path 'config/uaw-c33f-fix6-lifecycle-fixture-template-independence-ticket.json' `
  -Label 'C33F FIX6 ticket'
$fix6TicketSha256 = 'A3B16CD7984A92F43B23275B61579F7AD894D355CE630DF399DDD5911FB5B36F'
Assert-C33F -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix6TicketPath).Hash -ceq
    $fix6TicketSha256
) -Message 'C33F FIX6 ticket bytes changed.'
$fix6TicketRaw = Get-Content -Raw -LiteralPath $fix6TicketPath
Assert-C33FSanitizedText -Text $fix6TicketRaw -Label 'C33F FIX6 ticket'
$fix6Ticket = $fix6TicketRaw | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$fix6Ticket.ticketId -ceq
    'UAW-C33F-FIX6-LIFECYCLE-FIXTURE-TEMPLATE-INDEPENDENCE' -and
  [string]$fix6Ticket.parentTicket -ceq $ticketId -and
  [string]$fix6Ticket.finding -ceq
    'REG-20260815-2423-C33F-PREUPLOAD-TEST-POSTBUILD-FIXTURE-INHERITED-LIVE-AUTHORITY' -and
  [string]$fix6Ticket.classification -ceq 'mvp_required' -and
  [bool]$fix6Ticket.authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$fix6Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix6Ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$fix6Ticket.authority.aabRebuildAuthorizedDuringFix -and
  -not [bool]$fix6Ticket.authority.playOrDeviceActionAuthorizedDuringFix -and
  -not [bool]$fix6Ticket.authority.secretValueAccessAuthorized
) -Message 'C33F FIX6 ticket identity, classification or authority changed.'

$assessmentPath = Resolve-C33FFile `
  -Path 'artifacts/quality/uaw-c33f-r60-49-successor-preparation-20260815-01/pre-ticket-selection-assessment.json' `
  -Label 'C33F pre-ticket assessment'
$assessmentSha256 = '52EBA59DB149D8CB5EAD3539740CB2D2001095B7B84222030D4D3ADAFC6C656F'
Assert-C33F -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $assessmentPath).Hash -ceq
    $assessmentSha256
) -Message 'pre-ticket assessment bytes changed.'
$assessment = Get-Content -Raw -LiteralPath $assessmentPath | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$assessment.ticketId -ceq $ticketId -and
  [string]$assessment.manifestSha256 -ceq $ticketSha256 -and
  [bool]$assessment.reuseInventoryComplete -and
  [bool]$assessment.duplicateSearchComplete -and
  @($assessment.newScreens).Count -eq 0 -and
  @($assessment.newRoutes).Count -eq 0 -and
  @($assessment.newBackendOwners).Count -eq 0 -and
  [bool]$assessment.within60To75DayLock
) -Message 'pre-ticket robustness, reuse or duplicate assessment changed.'

$resolvedStatePath = Resolve-C33FFile -Path $StatePath -Label 'C33F state'
$stateRaw = Get-Content -Raw -LiteralPath $resolvedStatePath
Assert-C33FSanitizedText -Text $stateRaw -Label 'C33F state'
$state = $stateRaw | ConvertFrom-Json
$aggregatePath = Resolve-C33FFile `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C33F aggregate'
$aggregateRaw = Get-Content -Raw -LiteralPath $aggregatePath
Assert-C33FSanitizedText -Text $aggregateRaw -Label 'C33F aggregate'
$aggregate = $aggregateRaw | ConvertFrom-Json

$launcherPath = Resolve-C33FFile `
  -Path 'tmp/run-c30x-successor-single-aab-founder.ps1' `
  -Label 'current founder launcher'
$wrapperPath = Resolve-C33FFile `
  -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' `
  -Label 'generic single-AAB wrapper'
Assert-C33FPowerShellOwner -Path $launcherPath -Label 'founder launcher'
Assert-C33FPowerShellOwner -Path $wrapperPath -Label 'single-AAB wrapper'
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath

$launcherGatePathIndex = Find-C33FRequiredText `
  -Text $launcher `
  -Needle 'scripts/check-uaw-c33f-r60-49-successor-release-readiness.ps1' `
  -Label 'launcher C33F candidate-gate binding'
$launcherGateInvocationIndex = Find-C33FRequiredText `
  -Text $launcher -Needle '& $candidateGate `' `
  -Label 'launcher C33F candidate-gate invocation'
$launcherPreStateIndex = Find-C33FRequiredText `
  -Text $launcher -Needle '$preState = Get-Content -Raw -LiteralPath $statePath' `
  -Label 'launcher post-gate state read'
$launcherFirstPromptIndex = Find-C33FRequiredText `
  -Text $launcher -Needle '$uploadSecure = Read-Host' `
  -Label 'launcher first hidden prompt'
$launcherWrapperIndex = Find-C33FRequiredText `
  -Text $launcher -Needle '& $wrapperPath -StatePath $statePath -RepositoryRoot $root' `
  -Label 'launcher wrapper invocation'
$launcherCleanupIndex = $launcher.LastIndexOf(
  '} finally {',
  [StringComparison]::Ordinal
)
Assert-C33F -Condition (
  $launcherGatePathIndex -lt $launcherGateInvocationIndex -and
  $launcherGateInvocationIndex -lt $launcherPreStateIndex -and
  $launcherPreStateIndex -lt $launcherFirstPromptIndex -and
  $launcherFirstPromptIndex -lt $launcherWrapperIndex -and
  $launcherWrapperIndex -lt $launcherCleanupIndex
) -Message 'founder launcher gate, qualification, prompt, wrapper and cleanup ordering changed.'
Assert-C33F -Condition (
  [regex]::Matches(
    $launcher,
    '(?m)^& \$candidateGate\s*`?\s*$'
  ).Count -eq 1 -and
  [regex]::Matches(
    $launcher,
    'Read-Host[^\r\n]*-AsSecureString'
  ).Count -eq 3
) -Message 'founder launcher must have one C33F invocation and three hidden prompts.'
foreach ($required in @(
  'config/successor-aab-regression-hard-gate-state-c33f.json',
  'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-STATE-001',
  'source_and_live_readiness_qualified_founder_secret_prompt_required',
  '[int]$preState.sourceQualification.completedIdenticalCycles -eq 2',
  '[int]$preState.liveReadiness.qualifiedFacts -eq 4',
  '[string]$preState.buildAuthorization -ceq ''available_once''',
  'invoke-play-internal-aab-build-c30t.ps1',
  'ZeroFreeBSTR',
  'SetEnvironmentVariable($name, $null, ''Process'')',
  'Remove-Item -LiteralPath $path -Force'
)) {
  Assert-C33F -Condition (
    $launcher.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "founder launcher required owner is missing: $required"
}
foreach ($forbidden in @(
  'Write-Host $uploadPassword',
  'Write-Output $uploadPassword',
  'Write-Host $firebaseKey',
  'Write-Output $firebaseKey',
  'Write-Host $googleServerClientId',
  'Write-Output $googleServerClientId',
  '$state.founderAuthorization.hiddenFounderInputsEntered = $true',
  'Set-Clipboard',
  'Get-Clipboard'
)) {
  Assert-C33F -Condition (
    $launcher.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "founder launcher contains forbidden output or clipboard owner: $forbidden"
}

$wrapperContractIndex = Find-C33FRequiredText `
  -Text $wrapper `
  -Needle '''MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-STATE-001''' `
  -Label 'wrapper C33F contract switch'
$wrapperGatePathIndex = Find-C33FRequiredText `
  -Text $wrapper `
  -Needle '''check-uaw-c33f-r60-49-successor-release-readiness.ps1''' `
  -Label 'wrapper C33F gate selection'
$wrapperGateIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '& $gate -Phase build' `
  -Label 'wrapper build-phase gate'
$wrapperConfigIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$releaseConfigExitCode = Invoke-NativeCaptured' `
  -Label 'wrapper release config preflight'
$wrapperManifestIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$manifestExitCode = Invoke-NativeCaptured' `
  -Label 'wrapper release manifest preflight'
$wrapperStatePreflightIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$state.sourceQualification.releasePreflightPassed = $true' `
  -Label 'wrapper state preflight result'
$wrapperAggregatePreflightIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$aggregate.sourceQualification.releasePreflightPassed = $true' `
  -Label 'wrapper aggregate preflight result'
$wrapperConsumeIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$state.buildAuthorization = ''consumed''' `
  -Label 'wrapper single authority consumption'
$wrapperFounderInputConsumeIndex = Find-C33FRequiredText `
  -Text $wrapper `
  -Needle '$state.founderAuthorization.hiddenFounderInputsEntered = $true' `
  -Label 'wrapper founder-input marker consumption'
$wrapperActionBuildCountIndex = Find-C33FRequiredText `
  -Text $wrapper `
  -Needle '$state.actionCounts.build = 1' `
  -Label 'wrapper build action-count mirror'
$wrapperStateWriteIndex = Find-C33FRequiredText `
  -Text $wrapper `
  -Needle "Write-JsonState -State `$state -Path `$stateFile -Suffix '.c30t-build-write'" `
  -Label 'wrapper consumed-state write'
$wrapperAabIndex = Find-C33FRequiredText `
  -Text $wrapper -Needle '$buildArguments = @(''build'', ''appbundle''' `
  -Label 'wrapper appbundle invocation'
Assert-C33F -Condition (
  $wrapperContractIndex -le $wrapperGatePathIndex -and
  $wrapperGatePathIndex -lt $wrapperGateIndex -and
  $wrapperGateIndex -lt $wrapperConfigIndex -and
  $wrapperConfigIndex -lt $wrapperManifestIndex -and
  $wrapperManifestIndex -lt $wrapperStatePreflightIndex -and
  $wrapperStatePreflightIndex -lt $wrapperAggregatePreflightIndex -and
  $wrapperAggregatePreflightIndex -lt $wrapperConsumeIndex -and
  $wrapperConsumeIndex -lt $wrapperFounderInputConsumeIndex -and
  $wrapperFounderInputConsumeIndex -lt $wrapperActionBuildCountIndex -and
  $wrapperActionBuildCountIndex -lt $wrapperStateWriteIndex -and
  $wrapperStateWriteIndex -lt $wrapperAabIndex
) -Message 'wrapper C33F gate, preflight, founder-input marker, authority consumption and appbundle ordering changed.'
Assert-C33F -Condition (
  [regex]::Matches(
    $wrapper,
    '\$state[.]sourceQualification[.]releasePreflightPassed\s*=\s*\$true'
  ).Count -eq 1 -and
  [regex]::Matches(
    $wrapper,
    '\$aggregate[.]sourceQualification[.]releasePreflightPassed\s*=\s*\$true'
  ).Count -eq 1 -and
    [regex]::Matches(
      $wrapper,
      '\$state[.]founderAuthorization[.]hiddenFounderInputsEntered\s*=\s*\$true'
    ).Count -eq 1 -and
  [regex]::Matches(
    $wrapper,
    '\$state[.]actionCounts[.]build\s*=\s*1'
  ).Count -eq 1 -and
  [regex]::Matches($wrapper, "'appbundle'").Count -eq 1
) -Message 'wrapper preflight, founder-input consumption or appbundle ownership is not singular.'

$fix4BehaviorGate = Resolve-C33FFile `
  -Path 'scripts/test-uaw-c33f-fix4-hidden-founder-input-flag-prebuild-gate-order.ps1' `
  -Label 'C33F FIX4 founder-input state-order test'
& $fix4BehaviorGate -RepositoryRoot $root | Out-Null

$fix5BehaviorGate = Resolve-C33FFile `
  -Path 'scripts/test-uaw-c33f-fix5-phase-aware-postbuild-play-install-gate.ps1' `
  -Label 'C33F FIX5 phase-aware lifecycle test'
$fix5BehaviorText = Get-Content -Raw -LiteralPath $fix5BehaviorGate
$postbuildFixtureWrite = '$fixture = Write-C33FFix5Fixture -Name ''postbuild'''
$postbuildFixtureWriteIndex = $fix5BehaviorText.IndexOf(
  $postbuildFixtureWrite,
  [StringComparison]::Ordinal
)
Assert-C33F -Condition ($postbuildFixtureWriteIndex -gt 0) `
  -Message 'C33F FIX6 postbuild fixture write is missing.'
$postbuildFixtureStart = [Math]::Max(0, $postbuildFixtureWriteIndex - 3000)
$postbuildFixtureBlock = $fix5BehaviorText.Substring(
  $postbuildFixtureStart,
  $postbuildFixtureWriteIndex - $postbuildFixtureStart
)
foreach ($required in @(
  '$state.machineState = ''single_release_AAB_succeeded_authority_consumed''',
  '$aggregate.machineState = $state.machineState',
  '$state.buildAuthorization = ''consumed''',
  '$state.uploadAuthorization = ''held_postbuild_qualification''',
  '$state.buildResult.buildCount = 1',
  '$state.actionCounts.build = 1',
  '$state.playResult.uploadCount = 0',
  '$state.actionCounts.upload = 0',
  '$state.installResult.installCount = 0',
  '$state.actionCounts.install = 0',
  '$state.actionCounts.deviceAcceptance = 0',
  '$aggregate.candidate.buildCount = 1',
  '$aggregate.candidate.uploadCount = 0',
  '$aggregate.candidate.installCount = 0',
  '$aggregate.candidate.deviceAcceptanceCount = 0'
)) {
  Assert-C33F -Condition (
    $postbuildFixtureBlock.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "C33F FIX6 explicit postbuild fixture owner is missing: $required"
}
& $fix5BehaviorGate -RepositoryRoot $root | Out-Null

Assert-C33F -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-STATE-001' -and
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$state.candidate.versionCode -ceq '2026081349' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.authorizedTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71' -and
  [string]$state.candidate.deviceModel -ceq 'CPH2375'
) -Message 'state repository, candidate, package, track or device identity changed.'
Assert-C33F -Condition (
  [string]$aggregate.contractId -ceq
    'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-AGGREGATE-001' -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$aggregate.candidate.versionCode -ceq '2026081349'
) -Message 'aggregate identity or candidate changed.'

$historicalPath = Resolve-C33FFile `
  -Path ([string]$state.historicalFailedCandidate.statePath) `
  -Label 'failed r60.48 state'
$historical = Get-Content -Raw -LiteralPath $historicalPath | ConvertFrom-Json
Assert-C33F -Condition (
  [string]$historical.machineState -ceq
    'acceptance_failed_r60_48_social_auth_and_action_journey_defects_successor_required' -and
  [string]$historical.candidate.versionName -ceq '1.0.0-r60.48' -and
  [string]$historical.candidate.versionCode -ceq '2026081348' -and
  [int]$historical.buildResult.buildCount -eq 1 -and
  [int]$historical.playResult.uploadCount -eq 1 -and
  [int]$historical.installResult.installCount -eq 1 -and
  [string]$historical.buildAuthorization -ceq 'consumed' -and
  [string]$historical.uploadAuthorization -ceq 'consumed' -and
  [string]$historical.installAuthorization -ceq 'consumed' -and
  [string]$historical.deviceAuthorization -ceq 'consumed' -and
  -not [bool]$historical.installResult.acceptanceSucceeded -and
  [int]$state.historicalFailedCandidate.buildCount -eq 1 -and
  [int]$state.historicalFailedCandidate.uploadCount -eq 1 -and
  [int]$state.historicalFailedCandidate.installCount -eq 1 -and
  -not [bool]$state.historicalFailedCandidate.runtimeSuccessClaimed -and
  -not [bool]$state.historicalFailedCandidate.artifactReusable
) -Message 'failed r60.48 identity, counts, consumed authorities or failure truth changed.'

$readinessPath = Resolve-C33FFile `
  -Path ([string]$state.liveReadiness.statePath) `
  -Label 'Google auth live-readiness state'
$readiness = Get-Content -Raw -LiteralPath $readinessPath | ConvertFrom-Json
$facts = @($readiness.readinessFacts)
$qualifiedFacts = @(
  $facts | Where-Object {
    [string]$_.status -ceq 'qualified_sanitized_non_secret_evidence'
  }
).Count
Assert-C33F -Condition (
  $facts.Count -eq 4 -and
  [int]$state.liveReadiness.qualifiedFacts -eq $qualifiedFacts -and
  [int]$state.liveReadiness.requiredFacts -eq 4 -and
  [int]$aggregate.liveReadiness.qualifiedFacts -eq $qualifiedFacts -and
  [int]$aggregate.liveReadiness.requiredFacts -eq 4 -and
  -not [bool]$state.liveReadiness.secretValuesObserved -and
  -not [bool]$aggregate.liveReadiness.secretValuesObserved
) -Message 'live-readiness fact count or privacy mirror changed.'

$cycles = [int]$state.sourceQualification.completedIdenticalCycles
$sourceQualified = (
  $cycles -eq 2 -and
  [int]$state.sourceQualification.requiredIdenticalCycles -eq 2 -and
  -not [string]::IsNullOrWhiteSpace([string]$state.sourceQualification.manifestPath) -and
  [regex]::IsMatch([string]$state.sourceQualification.manifestSha256, '^[0-9A-F]{64}$') -and
  [int]$state.sourceQualification.fileCount -gt 0 -and
  [bool]$state.sourceQualification.wholeMobileAnalyzerPassed -and
  [bool]$state.sourceQualification.flutterTestsPassed -and
  [bool]$state.sourceQualification.backendTestsPassed -and
  [bool]$state.sourceQualification.hostingTestsPassed -and
  [bool]$state.sourceQualification.dualPowerShellHostsPassed
)
Assert-C33F -Condition (
  [int]$aggregate.sourceQualification.completedIdenticalCycles -eq $cycles -and
  [int]$aggregate.sourceQualification.requiredIdenticalCycles -eq 2
) -Message 'source-cycle aggregate mirror changed.'

Assert-C33F -Condition (
  [bool]$state.authority.candidateIdentityApproved -and
  [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$state.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$state.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  -not [bool]$state.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$state.authority.otherTrackAuthorized -and
  -not [bool]$state.authority.adbOrSideloadAuthorized -and
  -not [bool]$state.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$state.authority.providerDeploymentAuthorized -and
  -not [bool]$state.authority.emailOrQuotaSubmissionAuthorized -and
  -not [bool]$state.privacyBoundary.secretValuesObserved -and
  -not [bool]$state.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$state.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$state.privacyBoundary.firebaseDebugLogRead
) -Message 'authority or privacy boundary changed.'

$fix5PhaseGate = Resolve-C33FFile `
  -Path 'scripts/check-uaw-c33f-fix5-release-phase-transition.ps1' `
  -Label 'C33F FIX5 release phase transition gate'
& $fix5PhaseGate `
  -Phase $Phase `
  -StatePath $resolvedStatePath `
  -RepositoryRoot $root | Out-Null

$scopeGate = Resolve-C33FFile `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -StatePath $ScopePath `
  -CandidateId $ticketId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$memoryGate = Resolve-C33FFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
$memoryBuildMode = if ($Phase -ceq 'build') { 'release' } else { 'none' }
$memoryPhase = if ($Phase -ceq 'build') { 'build' } else { 'implementation' }
& $memoryGate -Phase $memoryPhase -BuildMode $memoryBuildMode -RepositoryRoot $root | Out-Null

foreach ($gatePath in @(
  'scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1',
  'scripts/check-uaw-c33e-fix3-social-auth-rollback-independent-cleanup.ps1',
  'scripts/check-uaw-c33e-fix4-protected-social-action-intent-return-continuity.ps1'
)) {
  $gate = Resolve-C33FFile -Path $gatePath -Label 'preserved authentication gate'
  & $gate -RepositoryRoot $root -ScopePath $ScopePath | Out-Null
}
$readinessGate = Resolve-C33FFile `
  -Path 'scripts/check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1' `
  -Label 'live-readiness gate'
& $readinessGate `
  -Phase implementation `
  -StatePath ([string]$state.liveReadiness.statePath) `
  -ScopePath $ScopePath `
  -RepositoryRoot $root | Out-Null

if ($Phase -ceq 'build') {
  Assert-C33F -Condition ($qualifiedFacts -eq 4) `
    -Message 'all four sanitized live-readiness facts must qualify before a build.'
  Assert-C33F -Condition $sourceQualified `
    -Message 'two identical fresh source cycles and their manifest must qualify before a build.'
  Assert-C33F -Condition (
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$state.buildResult.state -ceq 'not_started' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered
  ) -Message 'single AAB authority is unavailable, consumed or already prompted.'
  & $readinessGate `
    -Phase build `
    -StatePath ([string]$state.liveReadiness.statePath) `
    -ScopePath $ScopePath `
    -RepositoryRoot $root | Out-Null
}

if ($Phase -ceq 'postbuild') {
  Assert-C33F -Condition (
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    [int]$state.buildResult.configOnlyCount -eq 1 -and
    [regex]::IsMatch([string]$state.buildResult.artifactSha256, '^[0-9A-F]{64}$') -and
    [int64]$state.buildResult.artifactBytes -gt 0 -and
    [bool]$state.buildResult.packageVersionManifestProved -and
    [bool]$state.buildResult.googleAppIdResourceProved -and
    [bool]$state.buildResult.crashlyticsBuildIdResourceProved -and
    [bool]$state.buildResult.splitAndArm64PayloadProved -and
    [bool]$state.buildResult.mergedReleaseManifestProved
  ) -Message 'postbuild artifact, count or payload qualification is incomplete.'
}

if ($Phase -in @('postinstall', 'journey')) {
  $runtimeGate = Resolve-C33FFile `
    -Path 'scripts/check-release-runtime-configuration-c30w.ps1' `
    -Label 'C30W postinstall runtime gate'
  & $runtimeGate `
    -Phase postinstall `
    -StatePath $resolvedStatePath `
    -AcceptanceEvidencePath ([string]$state.installResult.coldStartEvidencePath) `
    -RepositoryRoot $root | Out-Null
}

Write-Output (
  'C33F r60.49 successor release gate passed: ' +
  "phase=$Phase; liveFacts=$qualifiedFacts/4; sourceCycles=$cycles/2; " +
  "buildCount=$($state.buildResult.buildCount); uploadCount=$($state.playResult.uploadCount); " +
  "installCount=$($state.installResult.installCount); " +
  "deviceAcceptanceCount=$($state.actionCounts.deviceAcceptance); " +
  'secretValuesObserved=false.'
)
