Set-StrictMode -Version Latest

$script:C30TProject = "moolsocial-dev-503018"
$script:C30TAccount = "hello@moolsocial.com"
$script:C30TBranch = "remediation/prototype-conformance-2026-07-20"
$script:C30THead = "f6dfe7587aa02d782e94282d14af8bafff48ded0"
$script:C30TTicket = (
  "UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T"
)
$script:C30TAuthorizationId = (
  "UAW-C30T-DEV-YOUTUBE-PROVIDER-HOSTING-DEPLOYMENT-20260813"
)
$script:C30TAuthorizationText = (
  "Authorize C30T bounded Dev YouTube provider and Firebase Hosting " +
  "deployments only; no AAB."
)
$script:C30TProviderTarget = "functions:provider:youtubeProvider"
$script:C30THostingSite = "moolsocial-dev-503018"
$script:C30TRegion = "asia-south1"

function Assert-C30T {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )
  if (-not $Condition) { throw "C30T deployment rejected: $Message" }
}

function Get-C30TSha256 {
  param([Parameter(Mandatory = $true)][string]$LiteralPath)
  Assert-C30T (Test-Path -LiteralPath $LiteralPath -PathType Leaf) `
    "required file is missing: $LiteralPath"
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $LiteralPath).Hash.ToUpperInvariant()
}

function Get-C30TAuthorization {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [switch]$RequireDeploymentReady
  )
  $authorizationPath = Join-Path $RepositoryRoot `
    "config/uaw-c30t-dev-provider-hosting-deployment-authorization.json"
  Assert-C30T (Test-Path -LiteralPath $authorizationPath -PathType Leaf) `
    "deployment authorization is missing"
  $authorization = Get-Content -Raw -LiteralPath $authorizationPath |
    ConvertFrom-Json

  Assert-C30T ($authorization.schemaVersion -eq 1) `
    "authorization schema changed"
  Assert-C30T ($authorization.authorizationId -ceq $script:C30TAuthorizationId) `
    "authorization identity changed"
  Assert-C30T ($authorization.ticketId -ceq $script:C30TTicket) `
    "ticket identity changed"
  Assert-C30T (
    $authorization.founderAuthorization.exactText -ceq
      $script:C30TAuthorizationText
  ) "founder authorization text changed"
  Assert-C30T (
    $authorization.founderAuthorization.project -ceq $script:C30TProject -and
    $authorization.founderAuthorization.account -ceq $script:C30TAccount
  ) "authorized account or project changed"
  Assert-C30T (
    $authorization.allowedExternalWrites.firebaseFunctionTarget -ceq
      $script:C30TProviderTarget -and
    $authorization.allowedExternalWrites.cloudRunService -ceq
      "youtubeprovider" -and
    $authorization.allowedExternalWrites.cloudRunRegion -ceq
      $script:C30TRegion -and
    $authorization.allowedExternalWrites.firebaseHostingSite -ceq
      $script:C30THostingSite
  ) "allowed external-write boundary changed"
  foreach ($forbidden in @(
    "youtubeOAuthCallbackDeploy",
    "moolSocialContentDeploy",
    "moolSocialChatDeploy",
    "firestoreRulesDeploy",
    "storageRulesDeploy",
    "iamPrincipalChanges",
    "stagingOrProduction",
    "aabBuildUploadOrInstall",
    "gmailOrQuotaSubmission"
  )) {
    Assert-C30T ([bool]$authorization.forbiddenExternalWrites.$forbidden) `
      "forbidden boundary weakened: $forbidden"
  }
  if ($RequireDeploymentReady) {
    Assert-C30T (
      @(
        "founder_authorized_deployment_ready",
        "provider_deployed_hosting_pending"
      ) -ccontains [string]$authorization.state
    ) "authorization is not in an exact deployment-ready state"
  }

  $branch = (& git -C $RepositoryRoot rev-parse --abbrev-ref HEAD 2>$null |
    Out-String).Trim()
  Assert-C30T ($LASTEXITCODE -eq 0 -and $branch -ceq $script:C30TBranch) `
    "branch changed"
  $head = (& git -C $RepositoryRoot rev-parse HEAD 2>$null | Out-String).Trim()
  Assert-C30T ($LASTEXITCODE -eq 0 -and $head -ceq $script:C30THead) `
    "HEAD changed"

  $manifestRelative = [string](
    $authorization.predeploymentEvidence.sourceManifest.path
  )
  Assert-C30T (-not [string]::IsNullOrWhiteSpace($manifestRelative)) `
    "source manifest path is blank"
  $manifestPath = Join-Path $RepositoryRoot $manifestRelative
  $manifestHash = Get-C30TSha256 $manifestPath
  Assert-C30T (
    $manifestHash -ceq
      [string]$authorization.predeploymentEvidence.sourceManifest.sha256
  ) "source manifest checksum changed"
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  Assert-C30T ($manifest.ticketId -ceq $script:C30TTicket) `
    "source manifest ticket changed"
  Assert-C30T (
    $manifest.branch -ceq $script:C30TBranch -and
    $manifest.head -ceq $script:C30THead
  ) "source manifest branch or HEAD changed"

  return [pscustomobject]@{
    Authorization = $authorization
    AuthorizationPath = $authorizationPath
    Manifest = $manifest
    ManifestPath = $manifestPath
    ManifestHash = $manifestHash
  }
}

function Assert-C30TManifestSection {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][object]$Section,
    [Parameter(Mandatory = $true)][string]$ExpectedFingerprint,
    [Parameter(Mandatory = $true)][string]$Label
  )
  Assert-C30T ($Section.sourceFingerprint -ceq $ExpectedFingerprint) `
    "$Label source fingerprint changed"
  $records = @($Section.files)
  Assert-C30T ($records.Count -eq [int]$Section.fileCount) `
    "$Label source file count changed"
  Assert-C30T (
    $records.Count -eq @($records.path | Sort-Object -Unique).Count
  ) "$Label source manifest contains duplicate paths"
  foreach ($record in $records) {
    $absolute = Join-Path $RepositoryRoot ([string]$record.path)
    Assert-C30T (Test-Path -LiteralPath $absolute -PathType Leaf) `
      "$Label source file is missing: $($record.path)"
    $file = Get-Item -LiteralPath $absolute
    Assert-C30T ($file.Length -eq [long]$record.bytes) `
      "$Label source byte count changed: $($record.path)"
    Assert-C30T ((Get-C30TSha256 $absolute) -ceq [string]$record.sha256) `
      "$Label source checksum changed: $($record.path)"
  }
}

function Invoke-C30TChecked {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$Command,
    [Parameter(Mandatory = $true)][string]$FailureMessage
  )
  $global:LASTEXITCODE = 0
  & $Command
  if ($LASTEXITCODE -ne 0) { throw "C30T deployment rejected: $FailureMessage" }
}

function Get-C30TCloudRunState {
  param(
    [Parameter(Mandatory = $true)][string]$ServiceName,
    [Parameter(Mandatory = $true)][string]$ProjectId
  )
  $format = (
    "json(metadata.name,status.latestReadyRevisionName," +
    "status.latestCreatedRevisionName,status.traffic," +
    "spec.template.metadata.annotations," +
    "spec.template.spec.serviceAccountName," +
    "spec.template.spec.containers[0].env)"
  )
  $output = & gcloud run services describe $ServiceName `
    --region=$script:C30TRegion `
    --project=$ProjectId `
    --format=$format 2>$null
  Assert-C30T ($LASTEXITCODE -eq 0) `
    "Cloud Run service read failed: $ServiceName"
  $state = ($output | Out-String) | ConvertFrom-Json
  Assert-C30T ($state.metadata.name -ceq $ServiceName) `
    "Cloud Run service identity changed: $ServiceName"
  return $state
}

function Assert-C30TExactTraffic {
  param(
    [Parameter(Mandatory = $true)][object]$State,
    [Parameter(Mandatory = $true)][string]$ExpectedRevision,
    [Parameter(Mandatory = $true)][string]$Label
  )
  $traffic = @($State.status.traffic)
  Assert-C30T (
    $traffic.Count -eq 1 -and
    [int]$traffic[0].percent -eq 100 -and
    $traffic[0].revisionName -ceq $ExpectedRevision
  ) "$Label traffic changed"
}
