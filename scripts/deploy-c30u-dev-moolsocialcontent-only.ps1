[CmdletBinding()]
param(
  [ValidateSet('Validate', 'Deploy', 'Reconcile')][string]$Mode = 'Validate',
  [string]$ProjectId = 'moolsocial-dev-503018',
  [string]$Confirmation = '',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$aggregatePath = Join-Path $root 'config/play-internal-social-repairs-acceptance-gate-state-c30u.json'
$aabPath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30u.json'
$evidenceRoot = Join-Path $root 'artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01'
$expectedConfirmation = 'DEPLOY_C30U_DEV_MOOLSOCIALCONTENT_ONLY'

function Assert-C30UDeploy {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30U Dev moolSocialContent deployment rejected: $Message" }
}

function Write-C30UJson {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Suffix)
  $temporary = $Path + $Suffix
  Assert-C30UDeploy -Condition (-not (Test-Path -LiteralPath $temporary)) -Message "stale temporary state exists: $temporary"
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Invoke-C30UCaptured {
  param(
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$LogPath
  )
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    Push-Location $WorkingDirectory
    try { & $Command @Arguments *> $LogPath; return $LASTEXITCODE }
    finally { Pop-Location }
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
}

function Get-C30UServiceState {
  param([Parameter(Mandatory)][string]$Service)
  $format = 'json(metadata.name,status.latestReadyRevisionName,status.latestCreatedRevisionName,status.traffic)'
  $output = & gcloud run services describe $Service --region=asia-south1 --project=$ProjectId --format=$format 2>$null
  Assert-C30UDeploy -Condition ($LASTEXITCODE -eq 0) -Message "Cloud Run service read failed: $Service"
  $serviceState = ($output | Out-String) | ConvertFrom-Json
  Assert-C30UDeploy -Condition ([string]$serviceState.metadata.name -ceq $Service) -Message "Cloud Run service identity changed: $Service"
  return $serviceState
}

function Assert-C30UTraffic {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Revision, [Parameter(Mandatory)][string]$Label)
  $traffic = @($State.status.traffic)
  Assert-C30UDeploy -Condition (
    $traffic.Count -eq 1 -and
    [int]$traffic[0].percent -eq 100 -and
    [string]$traffic[0].revisionName -ceq $Revision
  ) -Message "$Label traffic changed."
}

function Assert-C30UManifestCurrent {
  param([Parameter(Mandatory)][object]$Manifest)
  foreach ($record in @($Manifest.backendPayload.files)) {
    $path = Join-Path $root ([string]$record.path)
    Assert-C30UDeploy -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "deployment owner missing: $($record.path)"
    $item = Get-Item -LiteralPath $path
    Assert-C30UDeploy -Condition ([long]$item.Length -eq [long]$record.bytes) -Message "deployment owner byte count changed: $($record.path)"
    Assert-C30UDeploy -Condition (
      (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq [string]$record.sha256
    ) -Message "deployment owner checksum changed: $($record.path)"
  }
  foreach ($record in @($Manifest.hostingPayload.files)) {
    $path = Join-Path $root ([string]$record.path)
    Assert-C30UDeploy -Condition (
      (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq [string]$record.sha256
    ) -Message "unauthorized Hosting payload changed: $($record.path)"
  }
}

Assert-C30UDeploy -Condition ($ProjectId -ceq 'moolsocial-dev-503018') -Message 'only the exact Dev project is authorized.'
Assert-C30UDeploy -Condition (Test-Path -LiteralPath $aggregatePath -PathType Leaf) -Message 'aggregate state missing.'
Assert-C30UDeploy -Condition (Test-Path -LiteralPath $aabPath -PathType Leaf) -Message 'AAB state missing.'
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
$aab = Get-Content -Raw -LiteralPath $aabPath | ConvertFrom-Json
Assert-C30UDeploy -Condition (
  [string]$aggregate.machineState -ceq 'pre_aab_reconciliation_in_progress_authority_available' -and
  [string]$aab.machineState -ceq 'pre_aab_reconciliation_in_progress_authority_available' -and
  [int]$aggregate.candidate.buildCount -eq 0 -and
  [int]$aggregate.candidate.uploadCount -eq 0 -and
  [int]$aggregate.candidate.installCount -eq 0 -and
  [int]$aab.buildResult.buildCount -eq 0 -and
  [int]$aab.playReleaseResult.uploadCount -eq 0 -and
  [int]$aab.installResult.candidateInstallCount -eq 0
) -Message 'release mutation began before the required backend deployment.'
Assert-C30UDeploy -Condition (
  [bool]$aggregate.authority.DevMoolSocialContentDeploymentAuthorized -and
  -not [bool]$aggregate.authority.HostingDeploymentAuthorized -and
  -not [bool]$aggregate.authority.youtubeProviderDeploymentAuthorized -and
  -not [bool]$aggregate.authority.youtubeOAuthCallbackDeploymentAuthorized -and
  -not [bool]$aggregate.authority.moolSocialChatDeploymentAuthorized -and
  -not [bool]$aggregate.authority.firestoreOrStorageRulesDeploymentAuthorized -and
  -not [bool]$aggregate.authority.iamMutationAuthorized
) -Message 'exact external-write boundary changed.'
Assert-C30UDeploy -Condition (
  [string]$aggregate.providerAndHostingBoundary.deployTarget -ceq 'functions:provider:moolSocialContent' -and
  [int]$aggregate.providerAndHostingBoundary.deploymentCount -in @(0, 1) -and
  [int]$aggregate.providerAndHostingBoundary.deploymentAttemptCount -in @(0, 1)
) -Message 'deployment target or counts changed.'

$manifestPath = Join-Path $root ([string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestPath)
Assert-C30UDeploy -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) -Message 'deployment payload manifest missing.'
Assert-C30UDeploy -Condition (
  (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ceq [string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestSha256
) -Message 'deployment payload manifest checksum changed.'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
Assert-C30UDeploy -Condition (
  [string]$manifest.exactDeployTarget -ceq 'functions:provider:moolSocialContent' -and
  [string]$manifest.backendPayload.sourceFingerprint -ceq [string]$aggregate.providerAndHostingBoundary.deploymentPayloadFingerprint -and
  [bool]$manifest.hostingPayload.unchanged -and
  -not [bool]$manifest.hostingPayload.deploymentAuthorized -and
  [string]$manifest.restoredIgnoredEnvironmentSha256 -ceq '5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702' -and
  -not [bool]$manifest.ignoredEnvironmentValuesReadByAgent
) -Message 'sealed deployment manifest boundary changed.'
Assert-C30UManifestCurrent -Manifest $manifest

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation -BuildMode none -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root -RequireTicketSelectionAssessment
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId ([string]$aggregate.candidate.id) -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30u.ps1') -Phase reconcile -RepositoryRoot $root

$services = [ordered]@{
  youtubeprovider = Get-C30UServiceState -Service 'youtubeprovider'
  youtubeoauthcallback = Get-C30UServiceState -Service 'youtubeoauthcallback'
  moolsocialcontent = Get-C30UServiceState -Service 'moolsocialcontent'
  moolsocialchat = Get-C30UServiceState -Service 'moolsocialchat'
}
$preserved = $aggregate.providerAndHostingBoundary.preservedRevisions
foreach ($name in @('youtubeprovider', 'youtubeoauthcallback', 'moolsocialchat')) {
  $expected = [string]$preserved.$name
  Assert-C30UDeploy -Condition (
    [string]$services[$name].status.latestReadyRevisionName -ceq $expected -and
    [string]$services[$name].status.latestCreatedRevisionName -ceq $expected
  ) -Message "$name revision changed before deployment."
  Assert-C30UTraffic -State $services[$name] -Revision $expected -Label $name
}
$oldContentRevision = [string]$preserved.moolsocialcontent
$currentContentRevision = [string]$services.moolsocialcontent.status.latestReadyRevisionName
Assert-C30UDeploy -Condition (
  [string]$services.moolsocialcontent.status.latestCreatedRevisionName -ceq $currentContentRevision
) -Message 'moolSocialContent latest-created and ready revisions differ.'
Assert-C30UTraffic -State $services.moolsocialcontent -Revision $currentContentRevision -Label 'moolSocialContent'

$hostingOutput = & firebase hosting:channel:list --site moolsocial-dev-503018 --project $ProjectId --json 2>$null
Assert-C30UDeploy -Condition ($LASTEXITCODE -eq 0) -Message 'unable to inspect live Hosting channel.'
$hosting = ($hostingOutput | Out-String) | ConvertFrom-Json
$live = @($hosting.result.channels | Where-Object {
  [string]$_.name -ceq "projects/$ProjectId/sites/moolsocial-dev-503018/channels/live"
})
Assert-C30UDeploy -Condition ($live.Count -eq 1) -Message 'live Hosting channel identity changed.'
$hostingRelease = ([string]$live[0].release.name -split '/')[-1]
$hostingVersion = ([string]$live[0].release.version.name -split '/')[-1]
Assert-C30UDeploy -Condition (
  $hostingRelease -ceq [string]$aggregate.providerAndHostingBoundary.hostingRelease -and
  $hostingVersion -ceq [string]$aggregate.providerAndHostingBoundary.hostingVersion
) -Message 'live Hosting release or version changed.'

if ($Mode -eq 'Reconcile') {
  Assert-C30UDeploy -Condition (
    [string]$aggregate.providerAndHostingBoundary.deploymentState -ceq 'attempt_started_external_state_must_be_reconciled' -and
    [int]$aggregate.providerAndHostingBoundary.deploymentAttemptCount -eq 1 -and
    [int]$aggregate.providerAndHostingBoundary.deploymentCount -eq 0 -and
    $currentContentRevision -cne $oldContentRevision
  ) -Message 'no interrupted successful deployment is available to reconcile.'
} else {
  Assert-C30UDeploy -Condition (
    [string]$aggregate.providerAndHostingBoundary.deploymentState -ceq 'not_started' -and
    [int]$aggregate.providerAndHostingBoundary.deploymentAttemptCount -eq 0 -and
    [int]$aggregate.providerAndHostingBoundary.deploymentCount -eq 0 -and
    $currentContentRevision -ceq $oldContentRevision
  ) -Message 'deployment is already attempted, completed or externally changed; use Reconcile only for a proven interrupted success.'
}

if ($Mode -in @('Validate', 'Deploy')) {
  $verifyLog = Join-Path $evidenceRoot '03-backend-predeploy-verify.log'
  $verifyExit = Invoke-C30UCaptured -Command 'npm' -Arguments @('run', 'verify') -WorkingDirectory (Join-Path $root 'backend/functions') -LogPath $verifyLog
  Assert-C30UDeploy -Condition ($verifyExit -eq 0) -Message "backend verify failed with exit $verifyExit."

  $dryRunLog = Join-Path $evidenceRoot '04-moolsocialcontent-deploy-dry-run.log'
  $dryRunExit = Invoke-C30UCaptured -Command 'firebase' -Arguments @(
    'deploy', '--only', 'functions:provider:moolSocialContent', '--project', $ProjectId, '--dry-run', '--non-interactive'
  ) -WorkingDirectory $root -LogPath $dryRunLog
  Assert-C30UDeploy -Condition ($dryRunExit -eq 0) -Message "exact moolSocialContent dry run failed with exit $dryRunExit."
  $credentialPattern = '(?i)(AIza[0-9A-Za-z_-]{20,}|private[_ -]?key\s*[:=]|client[_ -]?secret\s*[:=]|refresh[_ -]?token\s*[:=]|access[_ -]?token\s*[:=])'
  Assert-C30UDeploy -Condition (-not (Select-String -LiteralPath $verifyLog,$dryRunLog -Pattern $credentialPattern -Quiet)) -Message 'credential-shaped text appeared in a predeploy log.'
}

if ($Mode -eq 'Validate') {
  Write-Output "C30U Dev moolSocialContent validation passed: target=functions:provider:moolSocialContent; predecessor=$oldContentRevision; Hosting=$hostingRelease/$hostingVersion; no external mutation."
  return
}

if ($Mode -eq 'Deploy') {
  Assert-C30UDeploy -Condition ($Confirmation -ceq $expectedConfirmation) -Message "deployment requires -Confirmation $expectedConfirmation"
  $aggregate.providerAndHostingBoundary.deploymentState = 'attempt_started_external_state_must_be_reconciled'
  $aggregate.providerAndHostingBoundary.deploymentAttemptCount = 1
  Write-C30UJson -State $aggregate -Path $aggregatePath -Suffix '.c30u-deploy-attempt-write'

  $deployLog = Join-Path $evidenceRoot '05-moolsocialcontent-deploy.log'
  $deployExit = Invoke-C30UCaptured -Command 'firebase' -Arguments @(
    'deploy', '--only', 'functions:provider:moolSocialContent', '--project', $ProjectId, '--non-interactive'
  ) -WorkingDirectory $root -LogPath $deployLog
  Assert-C30UDeploy -Condition ($deployExit -eq 0) -Message "exact moolSocialContent deployment failed with exit $deployExit; do not retry until external state is reconciled and a regression entry is registered."
  $credentialPattern = '(?i)(AIza[0-9A-Za-z_-]{20,}|private[_ -]?key\s*[:=]|client[_ -]?secret\s*[:=]|refresh[_ -]?token\s*[:=]|access[_ -]?token\s*[:=])'
  Assert-C30UDeploy -Condition (-not (Select-String -LiteralPath $deployLog -Pattern $credentialPattern -Quiet)) -Message 'credential-shaped text appeared in the deployment log.'
}

$after = [ordered]@{
  youtubeprovider = Get-C30UServiceState -Service 'youtubeprovider'
  youtubeoauthcallback = Get-C30UServiceState -Service 'youtubeoauthcallback'
  moolsocialcontent = Get-C30UServiceState -Service 'moolsocialcontent'
  moolsocialchat = Get-C30UServiceState -Service 'moolsocialchat'
}
foreach ($name in @('youtubeprovider', 'youtubeoauthcallback', 'moolsocialchat')) {
  $expected = [string]$preserved.$name
  Assert-C30UDeploy -Condition (
    [string]$after[$name].status.latestReadyRevisionName -ceq $expected -and
    [string]$after[$name].status.latestCreatedRevisionName -ceq $expected
  ) -Message "$name revision changed during the bounded deployment."
  Assert-C30UTraffic -State $after[$name] -Revision $expected -Label $name
}
$newRevision = [string]$after.moolsocialcontent.status.latestReadyRevisionName
Assert-C30UDeploy -Condition (
  -not [string]::IsNullOrWhiteSpace($newRevision) -and
  $newRevision -cne $oldContentRevision -and
  [string]$after.moolsocialcontent.status.latestCreatedRevisionName -ceq $newRevision
) -Message 'moolSocialContent did not advance to one fresh ready revision.'
Assert-C30UTraffic -State $after.moolsocialcontent -Revision $newRevision -Label 'moolSocialContent'

$evidenceRelative = 'artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/06-moolsocialcontent-deployment-evidence.json'
$evidencePath = Join-Path $root $evidenceRelative
$evidence = [ordered]@{
  schemaVersion = 1
  candidateId = [string]$aggregate.candidate.id
  project = $ProjectId
  region = 'asia-south1'
  target = 'functions:provider:moolSocialContent'
  predecessorRevision = $oldContentRevision
  deployedRevision = $newRevision
  trafficPercent = 100
  preservedRevisions = [ordered]@{
    youtubeprovider = [string]$after.youtubeprovider.status.latestReadyRevisionName
    youtubeoauthcallback = [string]$after.youtubeoauthcallback.status.latestReadyRevisionName
    moolsocialchat = [string]$after.moolsocialchat.status.latestReadyRevisionName
  }
  hostingRelease = $hostingRelease
  hostingVersion = $hostingVersion
  backendPayloadManifest = [string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestPath
  backendPayloadManifestSha256 = [string]$aggregate.providerAndHostingBoundary.deploymentPayloadManifestSha256
  secretValuesReadOrRecordedByAgent = $false
  IAMRulesHostingOrOtherFunctionMutationAuthorized = $false
  deployedAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($evidencePath, (($evidence | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
$aab = Get-Content -Raw -LiteralPath $aabPath | ConvertFrom-Json
$aggregate.providerAndHostingBoundary.deploymentState = 'succeeded_exact_Dev_moolSocialContent_only'
$aggregate.providerAndHostingBoundary.deploymentCount = 1
$aggregate.providerAndHostingBoundary.deployedRevision = $newRevision
$aggregate.providerAndHostingBoundary.deploymentEvidence = $evidenceRelative
$aggregate.providerAndHostingBoundary.deployedAt = [string]$evidence.deployedAt
$aab.providerRevisions.moolsocialcontent = $newRevision
$aab.providerRevisions.backendDeploymentCompleted = $true
$aab.providerRevisions.additionalBackendDeploymentAuthorized = $false
Write-C30UJson -State $aab -Path $aabPath -Suffix '.c30u-deploy-success-write'
Write-C30UJson -State $aggregate -Path $aggregatePath -Suffix '.c30u-deploy-success-write'

Write-Output "C30U Dev moolSocialContent deployed and contained: $oldContentRevision -> $newRevision; youtubeProvider/callback/chat and Hosting unchanged."
