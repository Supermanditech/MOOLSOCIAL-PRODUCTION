[CmdletBinding()]
param(
  [ValidateSet("Validate", "Deploy")]
  [string]$Mode = "Validate",

  [string]$ProjectId = "moolsocial-dev-503018",

  [string]$Confirmation = "",

  [string]$ExpectedProviderRevision = "",

  [string]$ExpectedOAuthCallbackRevision = "",

  [string]$ExpectedSocialContentRevision = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedProject = "moolsocial-dev-503018"
$expectedRegion = "asia-south1"
$expectedConfirmation = "DEPLOY_C30M_DEV_YOUTUBE_PROVIDER_ONLY"
$exactDeployTarget = "functions:provider:youtubeProvider"
$expectedProviderEnvironment = "dev"
$expectedProviderOAuthCallback = (
  "https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/" +
  "youtubeOAuthCallback"
)
$expectedProviderRuntimeEnabled = "true"
$expectedProviderRuntimeMode = "accepted"
$permanentProviderRuntimeValues = @(
  "MOOLSOCIAL_PROVIDER_ENV=$expectedProviderEnvironment",
  "YOUTUBE_OAUTH_REDIRECT_URI=$expectedProviderOAuthCallback",
  "YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED=$expectedProviderRuntimeEnabled",
  "YOUTUBE_SOCIAL_RUNTIME_MODE=$expectedProviderRuntimeMode"
) -join ","
$expectedProviderService = "youtubeprovider"
$expectedOAuthCallbackService = "youtubeoauthcallback"
$expectedSocialContentService = "moolsocialcontent"
$expectedProviderServiceAccount =
  "youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com"
$expectedSocialContentServiceAccount =
  "social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com"
$repoRoot = Split-Path -Parent $PSScriptRoot
$runtimeFile = Join-Path $repoRoot `
  "backend/functions/.env.moolsocial-dev-503018"
$runtimeExistedBeforeQualification = Test-Path `
  -LiteralPath $runtimeFile `
  -PathType Leaf

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

function Invoke-C30MChecked {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command,

    [Parameter(Mandatory = $true)]
    [string]$FailureMessage
  )

  $global:LASTEXITCODE = 0
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw $FailureMessage
  }
}

function Read-C30MRunServiceState {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceName
  )

  $stateFormat = (
    "json(metadata.name,status.latestReadyRevisionName," +
    "status.latestCreatedRevisionName,status.traffic," +
    "spec.template.spec.serviceAccountName," +
    "spec.template.spec.containers)"
  )
  $stateOutput = & $script:gcloudExecutable run services describe `
    $ServiceName `
    --region=$expectedRegion `
    --project=$ProjectId `
    --format=$stateFormat
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the exact Cloud Run service: $ServiceName"
  }
  try {
    $state = ($stateOutput | Out-String) | ConvertFrom-Json
  } catch {
    throw "Cloud Run metadata was not valid JSON for $ServiceName."
  }
  if (
    $state.metadata.name -ne $ServiceName -or
    [string]::IsNullOrWhiteSpace($state.status.latestReadyRevisionName) -or
    [string]::IsNullOrWhiteSpace($state.status.latestCreatedRevisionName) -or
    [string]::IsNullOrWhiteSpace(
      $state.spec.template.spec.serviceAccountName
    )
  ) {
    throw "Cloud Run metadata was incomplete for $ServiceName."
  }
  return $state
}

function Assert-C30MServiceIdentity {
  param(
    [Parameter(Mandatory = $true)]
    [object]$State,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedRevision,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedServiceAccount,

    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  if (
    $State.status.latestReadyRevisionName -ne $ExpectedRevision -or
    $State.status.latestCreatedRevisionName -ne $ExpectedRevision
  ) {
    throw "$Label revision changed outside the authorized provider scope."
  }
  if (
    $State.spec.template.spec.serviceAccountName -ne $ExpectedServiceAccount
  ) {
    throw "$Label runtime service account changed."
  }
  Assert-C30MTrafficRevision `
    -State $State `
    -ExpectedRevision $ExpectedRevision `
    -Label $Label
}

function Assert-C30MTrafficRevision {
  param(
    [Parameter(Mandatory = $true)]
    [object]$State,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedRevision,

    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  $traffic = @($State.status.traffic)
  if (
    $traffic.Count -ne 1 -or
    [int]$traffic[0].percent -ne 100 -or
    $traffic[0].revisionName -ne $ExpectedRevision
  ) {
    throw "$Label is not routing exactly 100 percent to $ExpectedRevision."
  }
}

function Assert-C30MPermanentProviderRuntime {
  param(
    [Parameter(Mandatory = $true)]
    [object]$State,

    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  $containers = @($State.spec.template.spec.containers)
  if ($containers.Count -ne 1) {
    throw "$Label does not have one exact runtime container."
  }
  $environment = @{}
  foreach ($entry in @($containers[0].env)) {
    $valueProperty = $entry.PSObject.Properties['value']
    if (
      -not [string]::IsNullOrWhiteSpace([string]$entry.name) -and
      $null -ne $valueProperty
    ) {
      $environment[[string]$entry.name] = [string]$valueProperty.Value
    }
  }
  $expectedEnvironment = [ordered]@{
    MOOLSOCIAL_PROVIDER_ENV = $expectedProviderEnvironment
    YOUTUBE_OAUTH_REDIRECT_URI = $expectedProviderOAuthCallback
    YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED = $expectedProviderRuntimeEnabled
    YOUTUBE_SOCIAL_RUNTIME_MODE = $expectedProviderRuntimeMode
  }
  foreach ($requiredName in $expectedEnvironment.Keys) {
    if ($environment[$requiredName] -cne $expectedEnvironment[$requiredName]) {
      throw "$Label is missing permanent runtime value $requiredName."
    }
  }
}

if ($ProjectId -ne $expectedProject) {
  throw "Only $expectedProject is authorized."
}

Invoke-C30MChecked {
  & (Join-Path $PSScriptRoot `
    "check-codex-development-regression-memory.ps1") `
    -RepositoryRoot $repoRoot `
    -Phase implementation `
    -BuildMode none
} "The Codex regression-memory gate failed."

Invoke-C30MChecked {
  & (Join-Path $PSScriptRoot "check-mvp-scope-gate-state.ps1") `
    -RepositoryRoot $repoRoot `
    -RequireExecutionAuthorized
} "The MVP execution-authority gate failed."

Invoke-C30MChecked {
  & (Join-Path $PSScriptRoot `
    "check-mvp-delivery-discipline-lock.ps1") `
    -RepositoryRoot $repoRoot `
    -RequireTicketSelectionAssessment
} "The MVP delivery-discipline lock failed."

Invoke-C30MChecked {
  & (Join-Path $PSScriptRoot "check-youtube-private-dev-package.ps1") `
    -SkipFlutter `
    -AllowReviewedExistingRuntime:$runtimeExistedBeforeQualification `
    -ProviderOnlyC30M
} "The sealed local YouTube provider package failed qualification."

if ($Mode -eq "Validate") {
  Write-Host "C30M provider-only deployment control passed locally."
  Write-Host "No cloud action was performed."
  exit 0
}

if ($Confirmation -ne $expectedConfirmation) {
  throw "Deployment requires -Confirmation $expectedConfirmation"
}
foreach ($requiredRevision in @(
  @{ Name = "ExpectedProviderRevision"; Value = $ExpectedProviderRevision },
  @{
    Name = "ExpectedOAuthCallbackRevision"
    Value = $ExpectedOAuthCallbackRevision
  },
  @{
    Name = "ExpectedSocialContentRevision"
    Value = $ExpectedSocialContentRevision
  }
)) {
  if ([string]::IsNullOrWhiteSpace($requiredRevision.Value)) {
    throw "$($requiredRevision.Name) is required before deployment."
  }
}

$gcloudCommand = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if ($null -eq $gcloudCommand) {
  $gcloudCommand = Get-Command gcloud -ErrorAction Stop
}
$firebaseCommand = Get-Command firebase.cmd -ErrorAction SilentlyContinue
if ($null -eq $firebaseCommand) {
  $firebaseCommand = Get-Command firebase -ErrorAction Stop
}
$script:gcloudExecutable = $gcloudCommand.Source
$firebaseExecutable = $firebaseCommand.Source

$activeAccountOutput = & $script:gcloudExecutable auth list `
  --filter="status:ACTIVE" `
  --format="value(account)" `
  --quiet 2>$null
if ($LASTEXITCODE -ne 0) {
  throw "Unable to identify the active gcloud account."
}
$activeAccounts = @(
  $activeAccountOutput |
    ForEach-Object { "$_".Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)
if (
  $activeAccounts.Count -ne 1 -or
  $activeAccounts[0] -ne "hello@moolsocial.com"
) {
  throw "The exact authorized gcloud deployer account is not active."
}
$activeProject = (& $script:gcloudExecutable config get-value project `
  --quiet 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $activeProject -ne $expectedProject) {
  throw "The active gcloud project is not the exact authorized Dev project."
}

Invoke-C30MChecked {
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $firebaseExecutable apps:list ANDROID `
      --project $ProjectId `
      --json *> $null
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
} "Firebase CLI authentication is not ready for the exact Dev project."

$providerBefore = Read-C30MRunServiceState $expectedProviderService
$callbackBefore = Read-C30MRunServiceState $expectedOAuthCallbackService
$contentBefore = Read-C30MRunServiceState $expectedSocialContentService

Assert-C30MServiceIdentity `
  -State $providerBefore `
  -ExpectedRevision $ExpectedProviderRevision `
  -ExpectedServiceAccount $expectedProviderServiceAccount `
  -Label "youtubeProvider before deployment"
Assert-C30MPermanentProviderRuntime `
  -State $providerBefore `
  -Label "youtubeProvider before deployment"
Assert-C30MServiceIdentity `
  -State $callbackBefore `
  -ExpectedRevision $ExpectedOAuthCallbackRevision `
  -ExpectedServiceAccount $expectedProviderServiceAccount `
  -Label "youtubeOAuthCallback before deployment"
Assert-C30MServiceIdentity `
  -State $contentBefore `
  -ExpectedRevision $ExpectedSocialContentRevision `
  -ExpectedServiceAccount $expectedSocialContentServiceAccount `
  -Label "moolSocialContent before deployment"

$deploymentAttempted = $false
$deploymentVerified = $false
$runtimeMaterializedThisRun = $false
$primaryFailure = $null
$rollbackFailure = $null

try {
  if (-not $runtimeExistedBeforeQualification) {
    if (Test-Path -LiteralPath $runtimeFile -PathType Leaf) {
      throw "The ignored runtime appeared after qualification."
    }
    Invoke-C30MChecked {
      powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot `
          "prepare-youtube-private-dev-runtime.ps1") `
        -ProjectId $ProjectId `
        -CapabilityProfile PublicDataReview `
        -Confirmation `
          $script:YouTubePrivateDevAcceptedPublicReviewConfirmation `
        -Materialize
    } "The accepted Dev PublicDataReview runtime could not be materialized."
    $runtimeMaterializedThisRun = $true
  } elseif (-not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)) {
    throw "The reviewed existing runtime disappeared after qualification."
  }

  Invoke-C30MChecked {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable deploy `
        --only $exactDeployTarget `
        --project $ProjectId `
        --message "C30M Dev youtubeProvider provider-only dry run" `
        --dry-run
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The exact Dev youtubeProvider dry run failed."

  $deploymentAttempted = $true
  Invoke-C30MChecked {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable deploy `
        --only $exactDeployTarget `
        --project $ProjectId `
        --message "C30M Dev youtubeProvider page-size correction only"
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The exact Dev youtubeProvider deployment failed."

  Invoke-C30MChecked {
    & $script:gcloudExecutable run services update `
      $expectedProviderService `
      --region=$expectedRegion `
      --project=$ProjectId `
      --update-env-vars=$permanentProviderRuntimeValues `
      --no-invoker-iam-check `
      --quiet *> $null
  } "The provider App Check invocation posture could not be restored."

  Invoke-C30MChecked {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = "Continue"
      & $firebaseExecutable functions:artifacts:setpolicy `
        --days 1 `
        --location $expectedRegion `
        --project $ProjectId `
        --force
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  } "The one-day Functions artifact cleanup policy was not applied."

  $providerAfter = Read-C30MRunServiceState $expectedProviderService
  $callbackAfter = Read-C30MRunServiceState $expectedOAuthCallbackService
  $contentAfter = Read-C30MRunServiceState $expectedSocialContentService

  if (
    $providerAfter.status.latestReadyRevisionName -eq
      $ExpectedProviderRevision -or
    $providerAfter.status.latestCreatedRevisionName -eq
      $ExpectedProviderRevision
  ) {
    throw "youtubeProvider did not advance to one fresh ready revision."
  }
  if (
    $providerAfter.status.latestReadyRevisionName -ne
      $providerAfter.status.latestCreatedRevisionName
  ) {
    throw "youtubeProvider latest created and ready revisions diverged."
  }
  if (
    $providerAfter.spec.template.spec.serviceAccountName -ne
      $expectedProviderServiceAccount
  ) {
    throw "youtubeProvider runtime service account changed."
  }
  Assert-C30MTrafficRevision `
    -State $providerAfter `
    -ExpectedRevision $providerAfter.status.latestReadyRevisionName `
    -Label "youtubeProvider after deployment"
  Assert-C30MPermanentProviderRuntime `
    -State $providerAfter `
    -Label "youtubeProvider after deployment"
  Assert-C30MServiceIdentity `
    -State $callbackAfter `
    -ExpectedRevision $ExpectedOAuthCallbackRevision `
    -ExpectedServiceAccount $expectedProviderServiceAccount `
    -Label "youtubeOAuthCallback after deployment"
  Assert-C30MServiceIdentity `
    -State $contentAfter `
    -ExpectedRevision $ExpectedSocialContentRevision `
    -ExpectedServiceAccount $expectedSocialContentServiceAccount `
    -Label "moolSocialContent after deployment"

  $deploymentVerified = $true
  Write-Host (
    "C30M Dev youtubeProvider deployed and verified: " +
    $providerAfter.status.latestReadyRevisionName
  )
  Write-Host "youtubeOAuthCallback and moolSocialContent revisions are unchanged."
} catch {
  $primaryFailure = $_
} finally {
  if (
    $runtimeMaterializedThisRun -and
    (Test-Path -LiteralPath $runtimeFile -PathType Leaf)
  ) {
    Remove-Item -LiteralPath $runtimeFile -Force
  }
}

if ($deploymentAttempted -and -not $deploymentVerified) {
  try {
    $providerCurrent = Read-C30MRunServiceState $expectedProviderService
    $currentTraffic = @($providerCurrent.status.traffic)
    if (
      $currentTraffic.Count -ne 1 -or
      [int]$currentTraffic[0].percent -ne 100 -or
      $currentTraffic[0].revisionName -ne $ExpectedProviderRevision
    ) {
      Invoke-C30MChecked {
        & $script:gcloudExecutable run services update-traffic `
          $expectedProviderService `
          --region=$expectedRegion `
          --project=$ProjectId `
          --to-revisions "$ExpectedProviderRevision=100" `
          --quiet *> $null
      } "Unable to restore provider traffic to the sealed prior revision."
    }
    $providerRestored = Read-C30MRunServiceState $expectedProviderService
    Assert-C30MTrafficRevision `
      -State $providerRestored `
      -ExpectedRevision $ExpectedProviderRevision `
      -Label "youtubeProvider failure containment"
    Write-Host "Provider failure was contained to the sealed prior revision."
  } catch {
    $rollbackFailure = $_
  }
}

if ($null -ne $rollbackFailure) {
  throw (
    "The provider-only deployment failed and prior-revision traffic " +
    "containment could not be verified."
  )
}
if ($null -ne $primaryFailure) {
  throw $primaryFailure
}
