param(
  [switch]$Cloud,
  [switch]$LocalFeaturePrebuild,
  [switch]$RequireBilling,
  [string]$ProjectId = "moolsocial-dev-503018",
  [string]$BillingAccountId = "",
  [string]$TicketId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedBranch = "remediation/prototype-conformance-2026-07-20"
$expectedFeatureBranch = "work/codex-auth/youtube-connect-prebuild-20260824-v2"
$expectedFeatureTicket = "UAW-CODEX-YOUTUBE-CONNECT-PREBUILD-20260824"
$expectedFeatureTicketHash =
  "25EA6040A4ED0D19AF595B7D0701304F6F5E44BEA592FBDEBD6888C9F5418407"
$expectedProject = "moolsocial-dev-503018"
$expectedProjectNumber = "760290687711"
$expectedOrganizationId = "1067591230270"
$expectedBillingAccountId = "01F9D3-44031C-B5E225"
$expectedRegion = "asia-south1"
$expectedRuntimeServiceAccount = (
  "youtube-provider-runtime@$expectedProject.iam.gserviceaccount.com"
)
$expectedBuildServiceAccount = (
  "$expectedProjectNumber-compute@developer.gserviceaccount.com"
)
$expectedCallback = (
  "https://asia-south1-$expectedProject.cloudfunctions.net/" +
  "youtubeOAuthCallback"
)
$expectedBaseline = "ed2a44d"
$expectedTag = "baseline-ui-before-conformance-2026-07-20"
$requiredServices = @(
  "apikeys.googleapis.com",
  "artifactregistry.googleapis.com",
  "billingbudgets.googleapis.com",
  "cloudbilling.googleapis.com",
  "cloudbuild.googleapis.com",
  "cloudfunctions.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "deploymentmanager.googleapis.com",
  "eventarc.googleapis.com",
  "firebase.googleapis.com",
  "firebaseextensions.googleapis.com",
  "firebaserules.googleapis.com",
  "firebaseappcheck.googleapis.com",
  "firestore.googleapis.com",
  "iam.googleapis.com",
  "playintegrity.googleapis.com",
  "pubsub.googleapis.com",
  "run.googleapis.com",
  "secretmanager.googleapis.com",
  "serviceusage.googleapis.com",
  "storage.googleapis.com",
  "youtube.googleapis.com",
  "youtubeanalytics.googleapis.com",
  "youtubereporting.googleapis.com"
)
$deferredServices = @(
  "firebasedataconnect.googleapis.com",
  "sqladmin.googleapis.com"
)
$expectedFunctions = @(
  "youtubeProvider",
  "youtubeOAuthCallback"
)
$expectedDeployTargets = @(
  "functions:provider:youtubeProvider",
  "functions:provider:youtubeOAuthCallback",
  "firestore:rules"
)
$expectedSecrets = @(
  "YOUTUBE_SERVER_API_KEY",
  "YOUTUBE_OAUTH_CLIENT_ID",
  "YOUTUBE_OAUTH_CLIENT_SECRET",
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1",
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2"
)

$repoRoot = Split-Path -Parent $PSScriptRoot

function Assert-True {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Get-CanonicalTextSha256 {
  param([Parameter(Mandatory = $true)][string]$Path)
  $text = [IO.File]::ReadAllText($Path)
  $canonical = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  $encoding = New-Object Text.UTF8Encoding($false)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash($encoding.GetBytes($canonical))
    )).Replace("-", "")
  } finally {
    $sha.Dispose()
  }
}

function Test-LocalFeaturePrebuildBoundary {
  param(
    [string]$Branch,
    [string]$SelectedTicket,
    [string]$TicketHash,
    [int]$ClaimOwnerCount,
    [bool]$ClaimHasGate,
    [bool]$CloudRequested,
    [bool]$BuildAuthorized,
    [bool]$DeviceAuthorized,
    [bool]$ExternalAuthorized,
    [bool]$SecretAuthorized
  )
  return (
    $Branch -ceq $expectedFeatureBranch -and
    $SelectedTicket -ceq $expectedFeatureTicket -and
    $TicketHash -ceq $expectedFeatureTicketHash -and
    $ClaimOwnerCount -eq 23 -and
    $ClaimHasGate -and
    -not $CloudRequested -and
    -not $BuildAuthorized -and
    -not $DeviceAuthorized -and
    -not $ExternalAuthorized -and
    -not $SecretAuthorized
  )
}

function Test-LocalYouTubeFirestoreComposition {
  param([Parameter(Mandatory = $true)][string]$Source)
  return (
    $Source.Contains('from "firebase-admin/firestore"') -and
    $Source.Contains('createFirestoreYouTubeStores') -and
    [regex]::IsMatch(
      $Source,
      '(?s)function\s+stores\(\)\s*:\s*FirestoreYouTubeStores\s*\{' +
        '.*?providerStores\s*=\s*createFirestoreYouTubeStores\(getFirestore\(\)\)'
    ) -and
    -not $Source.Contains("DataConnectYouTube") -and
    -not $Source.Contains("DataConnectOAuthAttemptStore")
  )
}

function Test-LocalYouTubeFunctionOptions {
  param([Parameter(Mandatory = $true)][string]$Source)
  foreach ($name in @("youtubeProvider", "youtubeOAuthCallback")) {
    $match = [regex]::Match(
      $Source,
      "(?s)export\s+const\s+$name\s*=\s*onRequest\(\s*" +
        "\{(?<options>.*?)\},\s*async\s*\("
    )
    if (-not $match.Success) { return $false }
    $options = $match.Groups["options"].Value
    foreach ($required in @(
      'region: "asia-south1"',
      "timeoutSeconds: 120",
      'memory: "512MiB"',
      "minInstances: 0",
      "maxInstances: 1",
      "concurrency: 1",
      "serviceAccount: youtubeProviderRuntimeServiceAccount"
    )) {
      if (-not $options.Contains($required)) { return $false }
    }
  }
  return $true
}

function Read-RepositoryFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $path = Join-Path $repoRoot $RelativePath
  Assert-True (Test-Path -LiteralPath $path -PathType Leaf) `
    "Required file is missing: $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

function Invoke-GitValue {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  $value = & git -C $repoRoot @Arguments 2>&1
  Assert-True ($LASTEXITCODE -eq 0) `
    "Git command failed: git $($Arguments -join ' ')"
  return ($value | Out-String).Trim()
}

function Assert-ExactStringSet {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Actual,
    [Parameter(Mandatory = $true)]
    [string[]]$Expected,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $actualValues = @($Actual | ForEach-Object { "$_" } | Sort-Object -Unique)
  $expectedValues = @($Expected | Sort-Object -Unique)
  Assert-True ($actualValues.Count -eq $expectedValues.Count) `
    "$Name has an unexpected number of entries."
  Assert-True (
    @(Compare-Object $expectedValues $actualValues).Count -eq 0
  ) "$Name does not match the reviewed inventory."
}

function Read-EnvironmentMap {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $values = @{}
  foreach ($line in ($Content -split "\r?\n")) {
    $clean = $line.Trim()
    if ($clean.Length -eq 0 -or $clean.StartsWith("#")) {
      continue
    }
    Assert-True ($clean -match "^([A-Z0-9_]+)=(.*)$") `
      "$Name contains an invalid environment line."
    $key = $Matches[1]
    Assert-True (-not $values.ContainsKey($key)) `
      "$Name contains a duplicate key: $key"
    $values[$key] = $Matches[2]
  }
  return $values
}

function Property-Value {
  param(
    [AllowNull()]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function ConvertFrom-JsonItems {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  try {
    $parsed = $Text | ConvertFrom-Json
  } catch {
    throw "$Name was not valid JSON."
  }
  foreach ($item in $parsed) {
    if ($null -ne $item) {
      Write-Output $item
    }
  }
}

Assert-True ($ProjectId -eq $expectedProject) `
  "Only $expectedProject is authorized for this private Dev preflight."

$manifest = Read-RepositoryFile `
  "deployment/youtube-private-dev/deployment-manifest.json" |
  ConvertFrom-Json
Assert-True ($manifest.projectId -eq $expectedProject) `
  "The deployment manifest project boundary changed."
Assert-True ("$($manifest.projectNumber)" -eq $expectedProjectNumber) `
  "The deployment manifest project number changed."
Assert-True ("$($manifest.organizationId)" -eq $expectedOrganizationId) `
  "The deployment manifest organization changed."
Assert-True (
  $manifest.authorizedBillingAccountId -eq $expectedBillingAccountId
) "The deployment manifest billing account boundary changed."
Assert-True ($manifest.environment -eq "dev") `
  "The deployment manifest must remain Dev-only."
Assert-True ($manifest.region -eq $expectedRegion) `
  "The private Dev provider region must remain asia-south1."
Assert-True (
  $manifest.firebase.functionsCodebase -eq "provider"
) "The deployment manifest Functions codebase changed."
Assert-True (
  $manifest.firebase.runtimeServiceAccount -eq
    $expectedRuntimeServiceAccount
) "The deployment manifest runtime service account changed."
Assert-True (
  $manifest.firebase.buildServiceAccount -eq
    $expectedBuildServiceAccount
) "The deployment manifest build service account changed."
Assert-ExactStringSet `
  @($manifest.firebase.buildAccess.projectRoles) `
  @("roles/logging.logWriter") `
  "The build service-account project-role inventory"
Assert-True (
  $manifest.firebase.buildAccess.sourceBucket -eq
    "gcf-v2-sources-$expectedProjectNumber-$expectedRegion"
) "The reviewed Functions source bucket changed."
Assert-ExactStringSet `
  @($manifest.firebase.buildAccess.sourceBucketRoles) `
  @("roles/storage.objectViewer") `
  "The build source-bucket role inventory"
Assert-True (
  $manifest.firebase.buildAccess.artifactRepository -eq
    "gcf-artifacts"
) "The reviewed Functions artifact repository changed."
Assert-True (
  $manifest.firebase.buildAccess.artifactRepositoryLocation -eq
    $expectedRegion
) "The reviewed Functions artifact-repository location changed."
Assert-ExactStringSet `
  @($manifest.firebase.buildAccess.artifactRepositoryRoles) `
  @("roles/artifactregistry.writer") `
  "The build artifact-repository role inventory"
Assert-True (
  $manifest.firebase.extensions.apiPurpose -eq
    "firebase-cli-functions-deployment-prerequisite" -and
  $manifest.firebase.extensions.installedInstancesAllowed -eq $false
) "Firebase Extensions must remain empty deployment plumbing only."
Assert-ExactStringSet `
  @($manifest.firebase.extensions.supportingServices) `
  @(
    "deploymentmanager.googleapis.com",
    "firebaseextensions.googleapis.com"
  ) `
  "The Firebase CLI extension-support service inventory"
Assert-ExactStringSet `
  @($manifest.firebase.functions) `
  $expectedFunctions `
  "The deployment manifest function inventory"
Assert-ExactStringSet `
  @($manifest.firebase.exactDeployTargets) `
  $expectedDeployTargets `
  "The deployment manifest deploy targets"
Assert-True (
  $manifest.firebase.firestoreRulesPath -eq
    "backend/firestore/youtube-private-dev.rules"
) "The deployment manifest Firestore Rules path changed."
Assert-ExactStringSet `
  @($manifest.deploymentPrerequisiteServices) `
  @(
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "deploymentmanager.googleapis.com",
    "eventarc.googleapis.com",
    "firebase.googleapis.com",
    "firebaseextensions.googleapis.com",
    "firebaserules.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com"
  ) `
  "The deployment prerequisite service inventory"
Assert-ExactStringSet `
  @($manifest.providerServices) `
  @(
    "firebaseappcheck.googleapis.com",
    "playintegrity.googleapis.com",
    "youtube.googleapis.com",
    "youtubeanalytics.googleapis.com",
    "youtubereporting.googleapis.com"
  ) `
  "The provider service inventory"
$preExistingPlatformServices = @($manifest.preExistingPlatformServices)
Assert-True ($preExistingPlatformServices.Count -gt 0) `
  "The reviewed pre-existing platform-service inventory is missing."
foreach ($service in $preExistingPlatformServices) {
  Assert-True (-not ($requiredServices -contains $service)) `
    "A pre-existing platform service duplicates a provider prerequisite."
  Assert-True (-not ($deferredServices -contains $service)) `
    "A deferred service cannot be accepted as a pre-existing platform service."
}
$reviewedAllowedServices = @(
  $requiredServices
  $preExistingPlatformServices
)
Assert-ExactStringSet `
  @($manifest.allowedEnabledServices) `
  $reviewedAllowedServices `
  "The exact allowed enabled-service inventory"
Assert-ExactStringSet `
  @($manifest.deferredServices) `
  $deferredServices `
  "The deferred service inventory"
Assert-True ($manifest.persistence.activeAdapter -eq "cloud-firestore") `
  "The private Dev persistence adapter must be Cloud Firestore."
Assert-True ($manifest.persistence.databaseId -eq "(default)") `
  "The private Dev Firestore database must be (default)."
Assert-True ($manifest.persistence.databaseType -eq "firestore-native") `
  "The private Dev database must use Firestore Native mode."
Assert-True ($manifest.persistence.edition -eq "standard") `
  "The private Dev database must use Standard edition."
Assert-True ($manifest.persistence.location -eq $expectedRegion) `
  "The private Dev Firestore location changed."
Assert-True ($manifest.persistence.deleteProtection -eq $true) `
  "The private Dev Firestore database must use delete protection."
Assert-True ($manifest.persistence.pointInTimeRecovery -eq $false) `
  "Billable Firestore point-in-time recovery must remain disabled."
Assert-True ($manifest.persistence.ttlPolicies -eq $false) `
  "Billable Firestore TTL deletion must remain disabled."
Assert-True ($manifest.persistence.clientAccess -eq $false) `
  "The YouTube control plane must remain backend-only."
Assert-True ($manifest.persistence.dataConnectAdapter -eq "preserved-deferred") `
  "The SQL adapter must remain preserved but deferred."
Assert-True ($manifest.persistence.cloudSqlProvisioningForbidden -eq $true) `
  "The private Dev proof must forbid Cloud SQL provisioning."
Assert-True ($manifest.artifactCleanup.location -eq $expectedRegion) `
  "Artifact cleanup must target the Functions region."
Assert-True ([int]$manifest.artifactCleanup.retentionDays -eq 1) `
  "Functions build artifacts must be cleaned after one day."
Assert-True (
  $manifest.artifactCleanup.requiredImmediatelyAfterFunctionDeploy -eq $true
) "Artifact cleanup must be applied immediately after Functions deployment."
Assert-True ($manifest.budget.calendarPeriod -eq "MONTH") `
  "The deployment manifest budget must remain monthly."
Assert-True ($manifest.budget.spendBasis -eq "CURRENT_SPEND") `
  "The deployment manifest budget must use current spend."
Assert-True ([decimal]$manifest.budget.approvedMonthlyAmount -eq 1000) `
  "The monthly Dev budget alert target must remain INR 1,000."
Assert-True (
  $manifest.budget.controlType -eq "alert-target-not-spend-cap"
) "The Dev budget must be described as an alert target, not a spend cap."
Assert-True ([int]$manifest.supervisedProof.maximumMinutes -eq 30) `
  "The supervised proof window cannot exceed 30 minutes."
Assert-ExactStringSet `
  @($manifest.supervisedProof.profiles) `
  @(
    "PublicData",
    "OwnerConnect",
    "OwnerActions",
    "CreatorAssets",
    "Live",
    "PrivateUpload",
    "OwnerAnalytics"
  ) `
  "The supervised proof profile inventory"
Assert-True ($manifest.supervisedProof.baselineProfile -eq "Disabled") `
  "The supervised proof baseline must remain all-disabled."
Assert-True (
  $manifest.acceptedPublicReview.profile -eq "PublicDataReview"
) "The accepted public review profile changed."
Assert-True (
  $manifest.acceptedPublicReview.allowedTarget -eq $expectedProject
) "Accepted public review must remain Dev-only."
Assert-True (
  $manifest.acceptedPublicReview.modeVariable -eq
  "YOUTUBE_PUBLIC_DATA_REVIEW_MODE"
) "The accepted public review mode variable changed."
Assert-True (
  $manifest.acceptedPublicReview.modeValue -eq "accepted"
) "The accepted public review mode value changed."
foreach ($requiredAcceptedReviewFlag in @(
  "onlyPublicDataEnabled",
  "appCheckRequired",
  "stagingForbidden",
  "productionForbidden"
)) {
  Assert-True (
    $manifest.acceptedPublicReview.$requiredAcceptedReviewFlag -eq $true
  ) "Accepted public review lost $requiredAcceptedReviewFlag."
}
Assert-True ($manifest.promotion.stagingForbidden -eq $true) `
  "The deployment manifest must forbid Staging."
Assert-True ($manifest.promotion.productionForbidden -eq $true) `
  "The deployment manifest must forbid Production."
Assert-True ($manifest.promotion.allowedTarget -eq $expectedProject) `
  "The deployment manifest promotion target changed."
Assert-True ($manifest.promotion.publicOrUnlistedUploadForbidden -eq $true) `
  "The deployment manifest must forbid public or unlisted upload."
foreach ($capabilityName in @(
  "YOUTUBE_PUBLIC_DATA_ENABLED",
  "YOUTUBE_OWNER_CONNECT_ENABLED",
  "YOUTUBE_OWNER_ACTIONS_ENABLED",
  "YOUTUBE_CREATOR_ASSETS_ENABLED",
  "YOUTUBE_LIVE_ENABLED",
  "YOUTUBE_PRIVATE_UPLOAD_ENABLED",
  "YOUTUBE_OWNER_ANALYTICS_ENABLED"
)) {
  Assert-True ($manifest.capabilities.$capabilityName -eq $false) `
    "The manifest must keep $capabilityName disabled."
}
Assert-ExactStringSet `
  @($manifest.quotaCaps.PSObject.Properties.Name) `
  @(
    "YOUTUBE_DEV_SEARCH_DAILY_CAP",
    "YOUTUBE_DEV_UPLOAD_DAILY_CAP",
    "YOUTUBE_DEV_BATCH_STATS_DAILY_CAP",
    "YOUTUBE_DEV_ANALYTICS_DAILY_CAP",
    "YOUTUBE_DEV_GENERAL_DAILY_CAP"
  ) `
  "The reviewed private Dev quota-cap inventory"
Assert-True ([int]$manifest.quotaCaps.YOUTUBE_DEV_SEARCH_DAILY_CAP -eq 20) `
  "The manifest search quota cap changed."
Assert-True ([int]$manifest.quotaCaps.YOUTUBE_DEV_UPLOAD_DAILY_CAP -eq 10) `
  "The manifest upload quota cap changed."
Assert-True ([int]$manifest.quotaCaps.YOUTUBE_DEV_BATCH_STATS_DAILY_CAP -eq 500) `
  "The manifest batch-stats quota cap changed."
Assert-True ([int]$manifest.quotaCaps.YOUTUBE_DEV_ANALYTICS_DAILY_CAP -eq 100) `
  "The manifest analytics quota cap changed."
Assert-True ([int]$manifest.quotaCaps.YOUTUBE_DEV_GENERAL_DAILY_CAP -eq 2000) `
  "The manifest general quota cap changed."
Assert-True ($manifest.oauth.clientType -eq "web") `
  "The reviewed OAuth client type changed."
Assert-True ($manifest.oauth.redirectUri -eq $expectedCallback) `
  "The reviewed OAuth callback changed."
Assert-True ($manifest.oauth.testUsersOnly -eq $true) `
  "The private Dev OAuth client must remain test-user-only."
Assert-ExactStringSet `
  @($manifest.oauth.incrementalScopes) `
  @(
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/youtube.force-ssl",
    "https://www.googleapis.com/auth/youtube",
    "https://www.googleapis.com/auth/youtube.channel-memberships.creator",
    "https://www.googleapis.com/auth/youtube.upload",
    "https://www.googleapis.com/auth/yt-analytics.readonly"
  ) `
  "The reviewed incremental OAuth scope inventory"
Assert-ExactStringSet `
  @($manifest.secretNames) `
  $expectedSecrets `
  "The reviewed Secret Manager inventory"

$branch = Invoke-GitValue @("branch", "--show-current")
Assert-True (Test-LocalFeaturePrebuildBoundary `
  -Branch $expectedFeatureBranch `
  -SelectedTicket $expectedFeatureTicket `
  -TicketHash $expectedFeatureTicketHash `
  -ClaimOwnerCount 23 -ClaimHasGate $true -CloudRequested $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
) "Local feature-prebuild positive fixture failed."
Assert-True (-not (Test-LocalFeaturePrebuildBoundary `
  -Branch "work/codex-auth/wrong" `
  -SelectedTicket $expectedFeatureTicket `
  -TicketHash $expectedFeatureTicketHash `
  -ClaimOwnerCount 23 -ClaimHasGate $true -CloudRequested $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) "Wrong-branch fixture passed unexpectedly."
Assert-True (-not (Test-LocalFeaturePrebuildBoundary `
  -Branch $expectedFeatureBranch `
  -SelectedTicket "UAW-CODEX-YOUTUBE-CONNECT-WRONG" `
  -TicketHash $expectedFeatureTicketHash `
  -ClaimOwnerCount 23 -ClaimHasGate $true -CloudRequested $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) "Wrong-ticket fixture passed unexpectedly."
Assert-True (-not (Test-LocalFeaturePrebuildBoundary `
  -Branch $expectedFeatureBranch `
  -SelectedTicket $expectedFeatureTicket `
  -TicketHash ("0" + $expectedFeatureTicketHash.Substring(1)) `
  -ClaimOwnerCount 23 -ClaimHasGate $true -CloudRequested $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) "Wrong-hash fixture passed unexpectedly."
Assert-True (-not (Test-LocalFeaturePrebuildBoundary `
  -Branch $expectedFeatureBranch `
  -SelectedTicket $expectedFeatureTicket `
  -TicketHash $expectedFeatureTicketHash `
  -ClaimOwnerCount 22 -ClaimHasGate $false -CloudRequested $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) "Wrong-claim fixture passed unexpectedly."
Assert-True (-not (Test-LocalFeaturePrebuildBoundary `
  -Branch $expectedFeatureBranch `
  -SelectedTicket $expectedFeatureTicket `
  -TicketHash $expectedFeatureTicketHash `
  -ClaimOwnerCount 23 -ClaimHasGate $true -CloudRequested $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) "Cloud-without-authority fixture passed unexpectedly."

if ($LocalFeaturePrebuild) {
  $coordination = Read-RepositoryFile `
    "config/codex-subagent-coordination-policy.json" | ConvertFrom-Json
  $scopeState = Read-RepositoryFile `
    "config/mvp-scope-gate-state.json" | ConvertFrom-Json
  $ticketRelative =
    "docs/quality/UAW-CODEX-YOUTUBE-CONNECT-PREBUILD-20260824.md"
  $ticketPath = Join-Path $repoRoot $ticketRelative
  $ticketText = Read-RepositoryFile $ticketRelative
  $ticketHash = Get-CanonicalTextSha256 $ticketPath
  $gitDiscipline = $coordination.productionGitDiscipline
  $batch = $gitDiscipline.agentTicketQueues.authPrebuildBatch
  $claims = @($coordination.activeClaims | Where-Object {
    [string]$_.task -ceq "/root/codex_auth_youtube_connect_prebuild_20260824_v2"
  })
  $claimOwnerCount = if ($claims.Count -eq 1) {
    @($claims[0].owners).Count
  } else {
    0
  }
  $claimHasGate = (
    $claims.Count -eq 1 -and
    @($claims[0].owners) -ccontains
      "scripts/check-youtube-private-dev-preflight.ps1" -and
    @($claims[0].owners) -ccontains
      "backend/functions/src/youtube/oauth_return_page.ts" -and
    @($claims[0].owners) -ccontains
      "backend/functions/src/youtube/oauth_return_page.test.ts"
  )
  $completedProviders = @($batch.completedPrebuildProviders)
  $evidenceHeld = (
    [string]$gitDiscipline.acceptedRuntimeBaseline.head -ceq
      "f105195ba505dcc9f25a35ab64aab104dadb47c2" -and
    [string]$gitDiscipline.acceptedRuntimeBaseline.tag -ceq
      "moolsocial-google-auth-r60.87-accepted-20260823" -and
    [string]$batch.state -ceq
      "founder_authorized_runtime_acceptance_deferred_2026_08_24" -and
    [string]$batch.currentProvider -ceq "youtube_connect" -and
    [int]$batch.maximumActiveMutationTickets -eq 1 -and
    [bool]$batch.runtimeAcceptanceDeferredUntilOneCombinedApk -and
    [bool]$batch.finalTicketCloseStillRequired -and
    $completedProviders.Count -eq 2 -and
    [string]$completedProviders[0].provider -ceq "email_link" -and
    [string]$completedProviders[0].qualificationCommit -ceq
      "84ab8e55414d4b87b3442a3b9631fe058efc6efe" -and
    [string]$completedProviders[1].provider -ceq "facebook" -and
    [string]$completedProviders[1].qualificationCommit -ceq
      "2024c25690b81b438c8c08f0081c6b60bd104010" -and
    $claims.Count -eq 1 -and
    [string]$claims[0].role -ceq "primary" -and
    @($claims[0].owners) -ccontains $ticketRelative -and
    @($claims[0].owners | Where-Object {
      ([string]$_).StartsWith(
        "apps/mobile/lib/ui_v2/",
        [StringComparison]::Ordinal
      )
    }).Count -eq 0 -and
    $ticketText.Contains("# $expectedFeatureTicket") -and
    $ticketText.Contains("Private YouTube consent and OPPO acceptance remain") -and
    [string]$scopeState.ticket.id -ceq
      "UAW-CODEX-EMAIL-LINK-AUTH-20260823" -and
    -not [bool]$scopeState.execution.buildAuthorized -and
    -not [bool]$scopeState.execution.deviceInstallAuthorized -and
    -not [bool]$scopeState.execution.playUploadAuthorized -and
    -not [bool]$scopeState.execution.externalServiceWriteAuthorized -and
    -not [bool]$scopeState.execution.otherProviderWriteAuthorized -and
    -not [bool]$scopeState.execution.secretValueAccessAuthorized
  )
  Assert-True ($evidenceHeld -and (Test-LocalFeaturePrebuildBoundary `
    -Branch $branch -SelectedTicket $TicketId -TicketHash $ticketHash `
    -ClaimOwnerCount $claimOwnerCount -ClaimHasGate $claimHasGate `
    -CloudRequested ([bool]$Cloud) `
    -BuildAuthorized ([bool]$scopeState.execution.buildAuthorized) `
    -DeviceAuthorized ([bool]$scopeState.execution.deviceInstallAuthorized) `
    -ExternalAuthorized ([bool]$scopeState.execution.externalServiceWriteAuthorized) `
    -SecretAuthorized ([bool]$scopeState.execution.secretValueAccessAuthorized)
  )) "Local YouTube feature-prebuild evidence or authority changed."
  $executionMode = "local_feature_prebuild"
} else {
  Assert-True ($branch -eq $expectedBranch) `
    "Wrong branch: $branch. Expected $expectedBranch."
  Assert-True ([string]::IsNullOrEmpty($TicketId)) `
    "Historical remediation mode does not accept a feature ticket."
  $executionMode = "historical_remediation"
}

$main = Invoke-GitValue @("rev-parse", "--short=8", "main")
Assert-True ($main.StartsWith($expectedBaseline)) `
  "Frozen main moved: $main. Expected prefix $expectedBaseline."

$baselineTag = Invoke-GitValue @(
  "rev-parse",
  "--short=8",
  "$expectedTag^{}"
)
Assert-True ($baselineTag.StartsWith($expectedBaseline)) `
  "Rollback tag moved: $baselineTag. Expected prefix $expectedBaseline."

if ($LocalFeaturePrebuild) {
  $uiLockState = "preserved_no_ui_owners"
} else {
  $locks = & powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot "check-approved-ui-locks.ps1") 2>&1
  Assert-True ($LASTEXITCODE -eq 0) `
    "Approved UI lock verification failed.`n$($locks | Out-String)"
  $uiLockState = "passed"
}

$environmentTemplate = Read-RepositoryFile "backend/functions/.env.example"
$deploymentEnvironment = Read-RepositoryFile `
  "backend/functions/env/moolsocial-dev-503018.env"
$expectedEnvironment = [ordered]@{
  MOOLSOCIAL_PROVIDER_ENV = "dev"
  YOUTUBE_PUBLIC_DATA_ENABLED = "false"
  YOUTUBE_OWNER_CONNECT_ENABLED = "false"
  YOUTUBE_OWNER_ACTIONS_ENABLED = "false"
  YOUTUBE_CREATOR_ASSETS_ENABLED = "false"
  YOUTUBE_LIVE_ENABLED = "false"
  YOUTUBE_PRIVATE_UPLOAD_ENABLED = "false"
  YOUTUBE_OWNER_ANALYTICS_ENABLED = "false"
  YOUTUBE_OAUTH_REDIRECT_URI = $expectedCallback
  YOUTUBE_DEV_SEARCH_DAILY_CAP = "20"
  YOUTUBE_DEV_UPLOAD_DAILY_CAP = "10"
  YOUTUBE_DEV_BATCH_STATS_DAILY_CAP = "500"
  YOUTUBE_DEV_ANALYTICS_DAILY_CAP = "100"
  YOUTUBE_DEV_GENERAL_DAILY_CAP = "2000"
}
$templateMap = Read-EnvironmentMap `
  $environmentTemplate `
  "backend/functions/.env.example"
$deploymentMap = Read-EnvironmentMap `
  $deploymentEnvironment `
  "backend/functions/env/moolsocial-dev-503018.env"
Assert-ExactStringSet `
  @($templateMap.Keys) `
  @($expectedEnvironment.Keys) `
  "The Functions environment template keys"
Assert-ExactStringSet `
  @($deploymentMap.Keys) `
  @($expectedEnvironment.Keys) `
  "The reviewed Dev environment keys"
foreach ($entry in $expectedEnvironment.GetEnumerator()) {
  Assert-True (
    "$($deploymentMap[$entry.Key])" -eq "$($entry.Value)"
  ) "The reviewed Dev environment has an unexpected $($entry.Key) value."
  if ($entry.Key -ne "YOUTUBE_OAUTH_REDIRECT_URI") {
    Assert-True (
      "$($templateMap[$entry.Key])" -eq "$($entry.Value)"
    ) "The environment template has an unexpected $($entry.Key) value."
  }
}
Assert-True (
  [string]::IsNullOrEmpty(
    "$($templateMap["YOUTUBE_OAUTH_REDIRECT_URI"])"
  )
) "The environment template must not pin a deployable callback."

Assert-True (
  $deploymentEnvironment -notmatch (
    "(?im)^(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_ID|" +
    "YOUTUBE_OAUTH_CLIENT_SECRET|YOUTUBE_TOKEN_ENCRYPTION_KEY_V[0-9]+)="
  )
) "Secret values must not be present in the deployment environment file."

$firebase = Read-RepositoryFile "firebase.json" | ConvertFrom-Json
Assert-True ($firebase.dataconnect.source -eq "dataconnect") `
  "Firebase Data Connect must use the repository dataconnect source."
Assert-True ($firebase.functions.Count -eq 1) `
  "Exactly one isolated provider Functions codebase is expected."
Assert-True ($firebase.functions[0].source -eq "backend/functions") `
  "The provider Functions source changed."
Assert-True ($firebase.functions[0].codebase -eq "provider") `
  "The provider Functions codebase identity changed."
Assert-True ($firebase.functions[0].runtime -eq "nodejs22") `
  "The provider Functions runtime must remain nodejs22."
$expectedFunctionsIgnore = @(
  ".git",
  ".runtimeconfig.json",
  "firebase-debug.log",
  "firebase-debug.*.log",
  "node_modules",
  "lib/**/*.test.js",
  "lib/**/*.test.js.map",
  "src/**/*.test.ts"
)
$actualFunctionsIgnore = @($firebase.functions[0].ignore)
Assert-True (
  $actualFunctionsIgnore.Count -eq $expectedFunctionsIgnore.Count
) "The provider Functions ignore list changed."
foreach ($entry in $expectedFunctionsIgnore) {
  Assert-True ($actualFunctionsIgnore -ccontains $entry) `
    "The provider Functions ignore list is missing $entry."
}
Assert-True ($firebase.firestore.database -eq "(default)") `
  "Firebase must deploy rules only to the default Firestore database."
Assert-True (
  $firebase.firestore.rules -eq
    "backend/firestore/youtube-private-dev.rules"
) "Firebase must deploy the reviewed backend-only Firestore Rules file."
$firestoreRules = Read-RepositoryFile `
  "backend/firestore/youtube-private-dev.rules"
$normalizedFirestoreRules = (
  $firestoreRules -replace "`r`n", "`n"
).Trim()
$expectedFirestoreRules = @"
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
"@.Trim()
$normalizedExpectedFirestoreRules = (
  $expectedFirestoreRules -replace "`r`n", "`n"
).Trim()
Assert-True (
  $normalizedFirestoreRules -ceq $normalizedExpectedFirestoreRules
) "Firestore Rules must remain the reviewed exact deny-all client policy."
$permissiveFirestoreFixture = $normalizedFirestoreRules.Replace(
  "allow read, write: if false;",
  "allow read, write: if true;"
)
Assert-True (
  $permissiveFirestoreFixture -cne $normalizedExpectedFirestoreRules
) "Permissive Firestore Rules fixture passed unexpectedly."

$functionSource = Read-RepositoryFile "backend/functions/src/index.ts"
Assert-True ($functionSource.Contains('from "firebase-admin/firestore"')) `
  "The runtime must use the Firebase Admin Firestore adapter."
Assert-True ($functionSource.Contains("getFirestore()")) `
  "The runtime must construct the default Firestore database."
if ($LocalFeaturePrebuild) {
  Assert-True (Test-LocalYouTubeFirestoreComposition $functionSource) `
    "The YouTube runtime is not exclusively composed with Firestore stores."
  $dataConnectYouTubeFixture = $functionSource.Replace(
    "createFirestoreYouTubeStores(getFirestore())",
    "new DataConnectYouTube(getDataConnect())"
  )
  Assert-True (-not (
    Test-LocalYouTubeFirestoreComposition $dataConnectYouTubeFixture
  )) "Data Connect YouTube composition fixture passed unexpectedly."
} else {
  Assert-True (-not $functionSource.Contains("getDataConnect")) `
    "Data Connect must not be reachable from the private Dev runtime."
  Assert-True (-not $functionSource.Contains("DataConnectYouTube")) `
    "The private Dev runtime must not construct a Data Connect store."
  Assert-True (-not $functionSource.Contains("DataConnectOAuthAttemptStore")) `
    "The private Dev runtime must not construct a SQL OAuth-attempt store."
}
if ($LocalFeaturePrebuild) {
  Assert-True (Test-LocalYouTubeFunctionOptions $functionSource) `
    "The YouTube provider Functions option contract changed."
  $wrongFunctionOptionFixture = $functionSource.Replace(
    "maxInstances: 1",
    "maxInstances: 2"
  )
  Assert-True (-not (
    Test-LocalYouTubeFunctionOptions $wrongFunctionOptionFixture
  )) "Wrong YouTube function option fixture passed unexpectedly."
} else {
  Assert-True (
    ([regex]::Matches($functionSource, 'region:\s*"asia-south1"')).Count -eq 2
  ) "Both provider Functions must remain in asia-south1."
  Assert-True (
    ([regex]::Matches($functionSource, "timeoutSeconds:\s*120")).Count -eq 2
  ) "Both provider Functions must retain the 120-second timeout."
  Assert-True (
    ([regex]::Matches($functionSource, 'memory:\s*"512MiB"')).Count -eq 2
  ) "Both provider Functions must retain 512MiB memory."
  Assert-True (
    ([regex]::Matches($functionSource, "minInstances:\s*0")).Count -eq 2
  ) "Both provider Functions must explicitly scale to zero."
  Assert-True (
    ([regex]::Matches($functionSource, "maxInstances:\s*1")).Count -eq 2
  ) "Private Dev must cap both provider Functions at one instance."
  Assert-True (
    ([regex]::Matches($functionSource, "concurrency:\s*1")).Count -eq 2
  ) "Private Dev must process at most one request per provider instance."
  Assert-True (
    $functionSource -match (
      "const\s+youtubeProviderRuntimeServiceAccount\s*=\s*" +
      [regex]::Escape('"' + $expectedRuntimeServiceAccount + '"')
    )
  ) "The dedicated provider runtime identity constant changed."
  Assert-True (
    (
      [regex]::Matches(
        $functionSource,
        "serviceAccount:\s*youtubeProviderRuntimeServiceAccount"
      )
    ).Count -eq 2
  ) "Both provider Functions must use the dedicated Dev runtime identity."
  $exportMatches = [regex]::Matches(
    $functionSource,
    "(?m)^export const ([A-Za-z0-9_]+)\s*="
  )
  $sourceExports = @(
    $exportMatches |
      ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactStringSet `
    $sourceExports `
    $expectedFunctions `
    "The provider Functions source export inventory"
}

foreach ($secret in $expectedSecrets) {
  $secretPattern = (
    'defineSecret\(\s*"' +
    [regex]::Escape($secret) +
    '"\s*,?\s*\)'
  )
  Assert-True ($functionSource -match $secretPattern) `
    "Missing Secret Manager declaration: $secret"
}

Assert-True ($functionSource.Contains("verifyApp(request.headers")) `
  "Firebase App Check verification is not wired into the provider."
Assert-True ($functionSource.Contains("getAuth().verifyIdToken")) `
  "Firebase Authentication verification is not wired into owner operations."

$capabilitySource = Read-RepositoryFile `
  "backend/functions/src/youtube/config.ts"
Assert-True ($capabilitySource.Contains("publicOrUnlistedUpload: false")) `
  "Public or unlisted upload must remain hard-disabled."

$backendSourceRoot = if ($LocalFeaturePrebuild) {
  Join-Path $repoRoot "backend/functions/src/youtube"
} else {
  Join-Path $repoRoot "backend/functions/src"
}
$backendSource = Get-ChildItem `
  -LiteralPath $backendSourceRoot `
  -Recurse -File -Filter "*.ts" |
  Where-Object { $_.Name -notlike "*.test.ts" } |
  ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName } |
  Out-String
Assert-True (
  $backendSource -notmatch `
    '@google-cloud/storage|firebase_storage|FirebaseStorage|storageBucket'
) "The provider must not proxy YouTube media through MoolSocial storage."
if ($LocalFeaturePrebuild) {
  $storageProxyFixture = $backendSource + "`nconst storageBucket = 'unsafe';"
  Assert-True (
    $storageProxyFixture -match
      '@google-cloud/storage|firebase_storage|FirebaseStorage|storageBucket'
  ) "YouTube storage-proxy negative fixture did not activate."
}

$mobileAppCheck = Read-RepositoryFile `
  "apps/mobile/lib/core/youtube/youtube_private_dev_app_check.dart"
Assert-True ($mobileAppCheck.Contains("'$expectedProject'")) `
  "The Flutter proof client must be pinned to the Dev Firebase project."

$mobileClient = Read-RepositoryFile `
  "apps/mobile/lib/core/youtube/youtube_private_dev_client.dart"
Assert-True (
  $mobileClient.Contains(
    "'asia-south1-moolsocial-dev-503018.cloudfunctions.net'"
  )
) "The Flutter proof client must reject non-Dev provider hosts."

foreach ($authority in @(
  "docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md",
  "docs/delivery/YOUTUBE-API-COMPLIANCE-QUOTA-VALUE-PROPOSAL-20260723.md",
  "docs/decisions/ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md",
  "docs/delivery/GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md"
)) {
  [void](Read-RepositoryFile $authority)
}

if ($Cloud) {
  $gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
  if ($null -eq $gcloud) {
    $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
  }
  Assert-True ($null -ne $gcloud) `
    "gcloud is required for -Cloud verification."
  $gcloudExecutable = $gcloud.Definition

  $project = & $gcloudExecutable `
    projects describe $ProjectId --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect $ProjectId."
  $projectState = ($project | Out-String) | ConvertFrom-Json
  Assert-True ($projectState.projectId -eq $expectedProject) `
    "Cloud project identity mismatch."
  Assert-True ("$($projectState.projectNumber)" -eq $expectedProjectNumber) `
    "Cloud project number mismatch."
  $projectParent = Property-Value $projectState "parent"
  Assert-True ($null -ne $projectParent) `
    "The Dev project has no organization parent."
  Assert-True (
    (Property-Value $projectParent "type") -eq "organization" -and
    "$(Property-Value $projectParent "id")" -eq $expectedOrganizationId
  ) "The Dev project belongs to a different organization."
  Assert-True ($projectState.lifecycleState -eq "ACTIVE") `
    "The Dev project is not ACTIVE."

  $services = & $gcloudExecutable `
    services list --enabled --project=$ProjectId `
    --format="value(config.name)" 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect enabled services."
  $enabledServices = @($services | ForEach-Object { "$_".Trim() })
  Assert-ExactStringSet `
    $enabledServices `
    @($manifest.allowedEnabledServices) `
    "The enabled Google service inventory"

  $firebaseCli = Get-Command firebase -ErrorAction SilentlyContinue
  Assert-True ($null -ne $firebaseCli) `
    "Firebase CLI is required to verify the empty Extensions inventory."
  $extensionOutput = & firebase ext:list `
    --project $ProjectId `
    --json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect the Firebase Extensions inventory."
  try {
    $extensionState = ($extensionOutput | Out-String) | ConvertFrom-Json
  } catch {
    throw "Firebase Extensions inventory was not valid JSON."
  }
  $installedExtensions = Property-Value $extensionState "result"
  Assert-True (
    $null -eq $installedExtensions -or
    @($installedExtensions).Count -eq 0
  ) "No Firebase Extension instance is authorized in private Dev."

  $runtimeIdentity = & $gcloudExecutable iam service-accounts describe `
    $expectedRuntimeServiceAccount `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "The dedicated YouTube provider runtime service account does not exist."
  $runtimeIdentityState = ($runtimeIdentity | Out-String) | ConvertFrom-Json
  Assert-True (
    (Property-Value $runtimeIdentityState "disabled") -ne $true
  ) `
    "The dedicated provider runtime service account is disabled."
  $runtimeKeyOutput = & $gcloudExecutable iam service-accounts keys list `
    --iam-account=$expectedRuntimeServiceAccount `
    --managed-by=user `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect runtime service-account keys."
  $runtimeUserManagedKeys = @(
    ConvertFrom-JsonItems `
      (($runtimeKeyOutput | Out-String).Trim()) `
      "Runtime service-account key inventory"
  )
  Assert-True (@($runtimeUserManagedKeys).Count -eq 0) `
    "The provider runtime service account must not have user-managed keys."

  $buildIdentity = & $gcloudExecutable iam service-accounts describe `
    $expectedBuildServiceAccount `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "The reviewed Functions build service account does not exist."
  $buildIdentityState = ($buildIdentity | Out-String) | ConvertFrom-Json
  Assert-True (
    (Property-Value $buildIdentityState "disabled") -ne $true
  ) "The reviewed Functions build service account is disabled."
  $buildKeyOutput = & $gcloudExecutable iam service-accounts keys list `
    --iam-account=$expectedBuildServiceAccount `
    --managed-by=user `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect build service-account keys."
  $buildUserManagedKeys = @(
    ConvertFrom-JsonItems `
      (($buildKeyOutput | Out-String).Trim()) `
      "Build service-account key inventory"
  )
  Assert-True (@($buildUserManagedKeys).Count -eq 0) `
    "The Functions build service account must not have user-managed keys."

  $activeAccountOutput = & $gcloudExecutable `
    config get-value account --quiet 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to identify the active gcloud deployer account."
  $activeAccount = ($activeAccountOutput | Out-String).Trim()
  Assert-True (
    -not [string]::IsNullOrWhiteSpace($activeAccount) -and
    $activeAccount -ne "(unset)"
  ) "No active gcloud deployer account is selected."
  $activeDeployerMember = if (
    $activeAccount.EndsWith(
      ".gserviceaccount.com",
      [System.StringComparison]::OrdinalIgnoreCase
    )
  ) {
    "serviceAccount:$activeAccount"
  } else {
    "user:$activeAccount"
  }
  $runtimeIamOutput = & $gcloudExecutable `
    iam service-accounts get-iam-policy `
    $expectedRuntimeServiceAccount `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect IAM on the provider runtime identity."
  try {
    $runtimeIam = ($runtimeIamOutput | Out-String) | ConvertFrom-Json
  } catch {
    throw "Provider runtime IAM policy was not valid JSON."
  }
  $scopedDeployerRoles = @(
    @($runtimeIam.bindings) |
      Where-Object {
        $null -eq (Property-Value $_ "condition") -and
        @($_.members) -contains $activeDeployerMember
      } |
      ForEach-Object { $_.role }
  )
  Assert-True (
    $scopedDeployerRoles -contains "roles/iam.serviceAccountUser"
  ) (
    "The active deployer lacks service-account-scoped " +
    "roles/iam.serviceAccountUser on the provider runtime identity."
  )

  $accessTokenOutput = & $gcloudExecutable `
    auth print-access-token --quiet 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to verify deployer access to the provider runtime identity."
  $accessToken = ($accessTokenOutput | Out-String).Trim()
  $serviceAccountResource = [uri]::EscapeDataString(
    $expectedRuntimeServiceAccount
  )
  try {
    $permissionCheck = Invoke-RestMethod `
      -Method Post `
      -Uri (
        "https://iam.googleapis.com/v1/projects/$ProjectId/" +
        "serviceAccounts/${serviceAccountResource}:testIamPermissions"
      ) `
      -Headers @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
        "X-Goog-User-Project" = $ProjectId
      } `
      -Body (
        @{ permissions = @("iam.serviceAccounts.actAs") } |
          ConvertTo-Json -Compress
      )
  } catch {
    throw "Unable to test deployer actAs permission on the runtime identity."
  } finally {
    $accessToken = $null
  }
  Assert-True (
    @(Property-Value $permissionCheck "permissions") -contains
      "iam.serviceAccounts.actAs"
  ) "The active deployer cannot act as the provider runtime identity."

  $projectIamOutput = & $gcloudExecutable `
    projects get-iam-policy $ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect the Dev project IAM policy."
  $projectIam = ($projectIamOutput | Out-String) | ConvertFrom-Json
  $publicProjectBindings = @(
    @($projectIam.bindings) |
      Where-Object {
        (@($_.members) -contains "allUsers") -or
        (@($_.members) -contains "allAuthenticatedUsers")
      }
  )
  Assert-True ($publicProjectBindings.Count -eq 0) `
    "Public project-level IAM bindings are forbidden for private Dev."
  $projectSecretAccessorMembers = @(
    @($projectIam.bindings) |
      Where-Object {
        $_.role -eq "roles/secretmanager.secretAccessor"
      } |
      ForEach-Object { @($_.members) }
  )
  Assert-True ($projectSecretAccessorMembers.Count -eq 0) `
    "Secret accessor grants must be scoped to individual provider secrets."
  $buildMember = "serviceAccount:$expectedBuildServiceAccount"
  $buildProjectRoles = @(
    @($projectIam.bindings) |
      Where-Object {
        $null -eq (Property-Value $_ "condition") -and
        @($_.members) -contains $buildMember
      } |
      ForEach-Object { $_.role }
  )
  Assert-ExactStringSet `
    $buildProjectRoles `
    @($manifest.firebase.buildAccess.projectRoles) `
    "The Functions build service-account project-role inventory"
  foreach ($forbiddenBuildRole in @(
    "roles/owner",
    "roles/editor",
    "roles/cloudbuild.builds.builder"
  )) {
    Assert-True ($buildProjectRoles -notcontains $forbiddenBuildRole) `
      "The Functions build identity has broad role $forbiddenBuildRole."
  }

  $sourceBucket = $manifest.firebase.buildAccess.sourceBucket
  $sourceBucketPolicyOutput = & $gcloudExecutable `
    storage buckets get-iam-policy `
    "gs://$sourceBucket" `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect the Functions source-bucket IAM policy."
  $sourceBucketPolicy = (
    $sourceBucketPolicyOutput | Out-String
  ) | ConvertFrom-Json
  $sourceBucketRoles = @(
    @($sourceBucketPolicy.bindings) |
      Where-Object {
        $null -eq (Property-Value $_ "condition") -and
        @($_.members) -contains $buildMember
      } |
      ForEach-Object { $_.role }
  )
  Assert-ExactStringSet `
    $sourceBucketRoles `
    @($manifest.firebase.buildAccess.sourceBucketRoles) `
    "The Functions build source-bucket role inventory"

  $artifactRepository = $manifest.firebase.buildAccess.artifactRepository
  $artifactLocation = (
    $manifest.firebase.buildAccess.artifactRepositoryLocation
  )
  $artifactPolicyOutput = & $gcloudExecutable `
    artifacts repositories get-iam-policy `
    $artifactRepository `
    --location=$artifactLocation `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect the Functions artifact-repository IAM policy."
  $artifactPolicy = ($artifactPolicyOutput | Out-String) | ConvertFrom-Json
  $artifactRoles = @(
    @($artifactPolicy.bindings) |
      Where-Object {
        $null -eq (Property-Value $_ "condition") -and
        @($_.members) -contains $buildMember
      } |
      ForEach-Object { $_.role }
  )
  Assert-ExactStringSet `
    $artifactRoles `
    @($manifest.firebase.buildAccess.artifactRepositoryRoles) `
    "The Functions build artifact-repository role inventory"

  $runtimeMember = "serviceAccount:$expectedRuntimeServiceAccount"
  $runtimeRoles = @(
    @($projectIam.bindings) |
      Where-Object {
        @($_.members) -contains $runtimeMember
      } |
      ForEach-Object { $_.role }
  )
  foreach ($requiredRole in @(
    "roles/datastore.user",
    "roles/firebaseappcheck.tokenVerifier"
  )) {
    Assert-True ($runtimeRoles -contains $requiredRole) `
      "The provider runtime is missing $requiredRole."
  }
  Assert-ExactStringSet `
    $runtimeRoles `
    @(
      "roles/datastore.user",
      "roles/firebaseappcheck.tokenVerifier"
    ) `
    "The provider runtime project-role inventory"

  foreach ($secret in $expectedSecrets) {
    $secretState = & $gcloudExecutable secrets describe $secret `
      --project=$ProjectId `
      --format=json 2>$null
    Assert-True ($LASTEXITCODE -eq 0) `
      "Required Secret Manager entry is missing: $secret"

    $enabledVersionOutput = & $gcloudExecutable `
      secrets versions list $secret `
      --project=$ProjectId `
      --filter="state=ENABLED" `
      --format=json 2>$null
    Assert-True ($LASTEXITCODE -eq 0) `
      "Unable to inspect enabled versions for $secret."
    $enabledVersions = @(
      ConvertFrom-JsonItems `
        (($enabledVersionOutput | Out-String).Trim()) `
        "Enabled-version inventory for $secret"
    )
    Assert-True (
      $enabledVersions.Count -eq 1 -and
      $enabledVersions[0].state -eq "ENABLED"
    ) "Required secret must have exactly one enabled value version: $secret"

    $secretPolicyOutput = & $gcloudExecutable `
      secrets get-iam-policy $secret `
      --project=$ProjectId `
      --format=json 2>$null
    Assert-True ($LASTEXITCODE -eq 0) `
      "Unable to inspect IAM for $secret."
    $secretPolicy = ($secretPolicyOutput | Out-String) | ConvertFrom-Json
    $publicSecretBindings = @(
      @($secretPolicy.bindings) |
        Where-Object {
          (@($_.members) -contains "allUsers") -or
          (@($_.members) -contains "allAuthenticatedUsers")
        }
    )
    Assert-True ($publicSecretBindings.Count -eq 0) `
      "Public Secret Manager access is forbidden for $secret."
    $secretAccessorMembers = @(
      @($secretPolicy.bindings) |
        Where-Object {
          $_.role -eq "roles/secretmanager.secretAccessor"
        } |
        ForEach-Object { @($_.members) }
    )
    Assert-ExactStringSet `
      $secretAccessorMembers `
      @($runtimeMember) `
      "The direct Secret Manager accessor inventory on $secret"
    $secretRoles = @(
      @($secretPolicy.bindings) |
        Where-Object {
          @($_.members) -contains $runtimeMember
        } |
        ForEach-Object { $_.role }
    )
    Assert-ExactStringSet `
      $secretRoles `
      @("roles/secretmanager.secretAccessor") `
      "The provider runtime role inventory on $secret"
  }
  foreach ($forbiddenRole in @(
    "roles/owner",
    "roles/editor",
    "roles/datastore.owner"
  )) {
    Assert-True ($runtimeRoles -notcontains $forbiddenRole) `
      "The provider runtime has forbidden broad role $forbiddenRole."
  }

  $databaseList = & $gcloudExecutable firestore databases list `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect Firestore database inventory."
  $databases = @(
    ConvertFrom-JsonItems `
      (($databaseList | Out-String).Trim()) `
      "Firestore database inventory"
  )
  Assert-True ($databases.Count -eq 1) `
    "Exactly one Firestore database may claim the project free quota."
  $database = & $gcloudExecutable firestore databases describe `
    --database="(default)" `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "The reviewed (default) Firestore database does not exist."
  $databaseState = ($database | Out-String) | ConvertFrom-Json
  Assert-True (
    $databaseState.name -eq
      "projects/$expectedProject/databases/(default)"
  ) "The Firestore database identity changed."
  Assert-True ($databaseState.locationId -eq $expectedRegion) `
    "The Firestore database location changed."
  Assert-True ($databaseState.type -eq "FIRESTORE_NATIVE") `
    "The database must remain in Firestore Native mode."
  Assert-True ($databaseState.databaseEdition -eq "STANDARD") `
    "The Firestore database must remain Standard edition."
  Assert-True ($databaseState.freeTier -eq $true) `
    "The reviewed Firestore database must receive the project free tier."
  Assert-True (
    $databaseState.deleteProtectionState -eq "DELETE_PROTECTION_ENABLED"
  ) "Firestore delete protection must be enabled."
  Assert-True (
    $databaseState.pointInTimeRecoveryEnablement -eq
      "POINT_IN_TIME_RECOVERY_DISABLED"
  ) "Billable Firestore point-in-time recovery must remain disabled."

  $ttlOutput = & $gcloudExecutable firestore fields ttls list `
    --database="(default)" `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect Firestore TTL policies."
  $ttlPolicies = @(
    ConvertFrom-JsonItems `
      (($ttlOutput | Out-String).Trim()) `
      "Firestore TTL policy inventory"
  )
  Assert-True (@($ttlPolicies).Count -eq 0) `
    "Billable Firestore TTL policies are forbidden for this proof."

  $backupOutput = & $gcloudExecutable firestore backups list `
    --location=$expectedRegion `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect Firestore backups."
  $backups = @(
    ConvertFrom-JsonItems `
      (($backupOutput | Out-String).Trim()) `
      "Firestore backup inventory"
  )
  Assert-True (@($backups).Count -eq 0) `
    "Billable Firestore backups are forbidden for this proof."

  $scheduleOutput = & $gcloudExecutable `
    firestore backups schedules list `
    --database="(default)" `
    --project=$ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect Firestore backup schedules."
  $backupSchedules = @(
    ConvertFrom-JsonItems `
      (($scheduleOutput | Out-String).Trim()) `
      "Firestore backup-schedule inventory"
  )
  Assert-True (@($backupSchedules).Count -eq 0) `
    "Billable Firestore backup schedules are forbidden for this proof."

  $billing = & $gcloudExecutable billing projects describe $ProjectId `
    --format=json 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect project billing."
  $billingState = ($billing | Out-String) | ConvertFrom-Json

  if ($BillingAccountId) {
    $account = & $gcloudExecutable `
      billing accounts describe $BillingAccountId `
      --format=json 2>$null
    Assert-True ($LASTEXITCODE -eq 0) `
      "Unable to inspect the authorized billing account."
    $accountState = ($account | Out-String) | ConvertFrom-Json
    Assert-True ($accountState.open -eq $true) `
      "The authorized billing account is not open."
  }

  if ($RequireBilling) {
    Assert-True ($BillingAccountId -ne "") `
      "-RequireBilling requires -BillingAccountId."
    Assert-True (
      $BillingAccountId -eq $manifest.authorizedBillingAccountId
    ) "The supplied billing account is not the reviewed Dev account."
    Assert-True ($billingState.billingEnabled -eq $true) `
      "Billing is not enabled for the Dev project."
    Assert-True (
      $billingState.billingAccountName -eq
        "billingAccounts/$BillingAccountId"
    ) "The Dev project is linked to a different billing account."
    Assert-True (
      $null -ne $manifest.budget.approvedMonthlyAmount -and
      [decimal]$manifest.budget.approvedMonthlyAmount -gt 0
    ) "A founder-approved monthly Dev budget must be recorded before deployment."

    $budgetOutput = & $gcloudExecutable billing budgets list `
      --billing-account=$BillingAccountId `
      --format=json 2>$null
    Assert-True ($LASTEXITCODE -eq 0) `
      "Unable to inspect the authorized billing account budgets."
    $budgetList = @(
      ConvertFrom-JsonItems `
        (($budgetOutput | Out-String).Trim()) `
        "Billing budget inventory"
    )
    $matchingBudgets = @(
      $budgetList |
        Where-Object {
          (Property-Value $_ "displayName") -eq
            $manifest.budget.displayName
        }
    )
    Assert-True ($matchingBudgets.Count -eq 1) `
      "Expected exactly one reviewed private Dev budget."
    $reviewedBudget = $matchingBudgets[0]
    $budgetFilter = Property-Value $reviewedBudget "budgetFilter"
    $budgetProjects = @(
      Property-Value $budgetFilter "projects"
    )
    Assert-True (
      $budgetProjects.Count -eq 1 -and
      $budgetProjects[0] -eq $manifest.budget.projectResource
    ) "The reviewed budget is not scoped only to the Dev project."
    $amount = Property-Value $reviewedBudget "amount"
    $specifiedAmount = Property-Value $amount "specifiedAmount"
    Assert-True ($null -ne $specifiedAmount) `
      "The reviewed Dev budget must use a fixed amount."
    Assert-True (
      (Property-Value $specifiedAmount "currencyCode") -eq
        $manifest.budget.currency
    ) "The reviewed Dev budget currency changed."
    $unitsValue = Property-Value $specifiedAmount "units"
    $nanosValue = Property-Value $specifiedAmount "nanos"
    $units = if ($null -eq $unitsValue) { 0 } else { [decimal]$unitsValue }
    $nanos = if ($null -eq $nanosValue) { 0 } else { [decimal]$nanosValue }
    $cloudAmount = $units + ($nanos / 1000000000)
    Assert-True (
      $cloudAmount -eq [decimal]$manifest.budget.approvedMonthlyAmount
    ) "The Cloud budget amount does not match the founder-approved manifest."
    Assert-True (
      (Property-Value $budgetFilter "calendarPeriod") -eq
        $manifest.budget.calendarPeriod
    ) "The reviewed Dev budget must use a monthly calendar period."
    $cloudThresholds = @(
      @(Property-Value $reviewedBudget "thresholdRules") |
        ForEach-Object {
          Assert-True (
            (Property-Value $_ "spendBasis") -eq
              $manifest.budget.spendBasis
          ) "Every Dev budget threshold must use current spend."
          [decimal](Property-Value $_ "thresholdPercent")
        }
    )
    Assert-True (
      $cloudThresholds.Count -eq @($manifest.budget.thresholds).Count -and
      @(Compare-Object `
        @($manifest.budget.thresholds | ForEach-Object { [decimal]$_ }) `
        $cloudThresholds).Count -eq 0
    ) "The Cloud budget alert thresholds changed."
  }

  Write-Host (
    "Cloud: project={0}; billingEnabled={1}; services={2}" -f `
      $projectState.projectId,
      $billingState.billingEnabled,
      ($requiredServices -join ",")
  )
}

Write-Host "YouTube private Dev preflight passed."
Write-Host "Mode: $executionMode"
Write-Host "Branch: $branch"
Write-Host "Project boundary: $ProjectId"
Write-Host "Provider capabilities: disabled"
Write-Host "Approved UI locks: $uiLockState"
