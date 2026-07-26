[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = "None")]
param(
  [ValidateSet("moolsocial-dev-503018")]
  [string]$ProjectId = "moolsocial-dev-503018",
  [string]$BillingAccountId = "",
  [string]$ServerApiKeyUid = "",
  [string]$AndroidAppId = "",
  [string]$ExpectedSha256 = "",
  [string]$BudgetDisplayName = "MoolSocial Dev Trial monthly guardrail",
  [ValidateSet(
    "Disabled",
    "PublicDataReview",
    "PublicData",
    "OwnerConnect",
    "OwnerActions",
    "CreatorAssets",
    "Live",
    "PrivateUpload",
    "OwnerAnalytics"
  )]
  [string]$ExpectedCapabilityProfile = "Disabled",
  [string]$ExpectedProofExpiresAt = "",
  [switch]$AllowNoServerIpRestriction,
  [switch]$ExpectContained,
  [switch]$StaticOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

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
  "https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/" +
  "youtubeOAuthCallback"
)
$expectedFunctions = @{
  youtubeProvider = "youtubeProvider"
  youtubeOAuthCallback = "youtubeOAuthCallback"
}
$expectedFlags = @{
  MOOLSOCIAL_PROVIDER_ENV = "dev"
  YOUTUBE_OAUTH_REDIRECT_URI = $expectedCallback
  YOUTUBE_PUBLIC_DATA_ENABLED = "false"
  YOUTUBE_OWNER_CONNECT_ENABLED = "false"
  YOUTUBE_OWNER_ACTIONS_ENABLED = "false"
  YOUTUBE_CREATOR_ASSETS_ENABLED = "false"
  YOUTUBE_LIVE_ENABLED = "false"
  YOUTUBE_PRIVATE_UPLOAD_ENABLED = "false"
  YOUTUBE_OWNER_ANALYTICS_ENABLED = "false"
  YOUTUBE_DEV_SEARCH_DAILY_CAP = "20"
  YOUTUBE_DEV_UPLOAD_DAILY_CAP = "10"
  YOUTUBE_DEV_BATCH_STATS_DAILY_CAP = "500"
  YOUTUBE_DEV_ANALYTICS_DAILY_CAP = "100"
  YOUTUBE_DEV_GENERAL_DAILY_CAP = "2000"
}
$profileForFlags = if (
  $ExpectedCapabilityProfile -eq "PublicDataReview"
) {
  "PublicData"
} else {
  $ExpectedCapabilityProfile
}
$expectedProfile = Get-YouTubePrivateDevProfile $profileForFlags
foreach ($capabilityFlag in $script:YouTubePrivateDevCapabilityKeys) {
  $expectedFlags[$capabilityFlag] = $expectedProfile.Flags[$capabilityFlag]
}
$expectedSecrets = @(
  "YOUTUBE_SERVER_API_KEY",
  "YOUTUBE_OAUTH_CLIENT_ID",
  "YOUTUBE_OAUTH_CLIENT_SECRET",
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1",
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2"
)
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

function Assert-RequiredValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  Assert-True (-not [string]::IsNullOrWhiteSpace($Value)) `
    "$Name is required for cloud verification."
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

function Invoke-GcloudJson {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  $previousErrorActionPreference = $ErrorActionPreference
  $nativePreference = Get-Variable `
    -Name PSNativeCommandUseErrorActionPreference `
    -ErrorAction SilentlyContinue
  $previousNativePreference = if ($null -ne $nativePreference) {
    $nativePreference.Value
  } else {
    $null
  }
  try {
    $ErrorActionPreference = "Continue"
    if ($null -ne $nativePreference) {
      $PSNativeCommandUseErrorActionPreference = $false
    }
    $output = & $script:GcloudExecutable `
      @Arguments --quiet --format=json 2>$null
    $commandExitCode = $LASTEXITCODE
  } finally {
    if ($null -ne $nativePreference) {
      $PSNativeCommandUseErrorActionPreference = $previousNativePreference
    }
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Assert-True ($commandExitCode -eq 0) "Unable to $Description."
  $text = ($output | Out-String).Trim()
  try {
    return $text | ConvertFrom-Json
  } catch {
    throw "The $Description response was not valid JSON."
  }
}

function Get-GoogleJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  try {
    return Invoke-RestMethod `
      -Method Get `
      -Uri $Uri `
      -Headers @{
        Authorization = "Bearer $AccessToken"
        "X-Goog-User-Project" = $ProjectId
      }
  } catch {
    throw "Unable to $Description."
  }
}

function PropertyValue {
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

function RolesForMember {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Policy,
    [Parameter(Mandatory = $true)]
    [string]$Member
  )

  $bindings = PropertyValue $Policy "bindings"
  if ($null -eq $bindings) {
    return @()
  }
  return @(
    $bindings |
      Where-Object {
        (@($_.members) -contains $Member) -and
        $null -eq (PropertyValue $_ "condition")
      } |
      ForEach-Object { $_.role }
  )
}

function Assert-RunInvocationBoundary {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Policy,
    [Parameter(Mandatory = $true)]
    [string]$ServiceName,
    [Parameter(Mandatory = $true)]
    [object]$RunState,
    [switch]$ExpectContainedBoundary
  )

  $bindingValue = PropertyValue $Policy "bindings"
  $bindings = @()
  if ($null -ne $bindingValue) {
    $bindings = @($bindingValue)
  }
  $publicBindings = @(
    $bindings |
      Where-Object {
        $members = @(PropertyValue $_ "members")
        ($members -contains "allUsers") -or
        ($members -contains "allAuthenticatedUsers")
      }
  )
  Assert-True ($publicBindings.Count -eq 0) `
    "$ServiceName must not retain a broad Run invoker IAM binding."
  $annotations = PropertyValue $RunState.metadata "annotations"
  $invokerCheckDisabled = PropertyValue `
    $annotations `
    "run.googleapis.com/invoker-iam-disabled"
  $isInvokerCheckDisabled = (
    "$invokerCheckDisabled".ToLowerInvariant() -eq "true"
  )
  if ($ExpectContainedBoundary) {
    Assert-True (-not $isInvokerCheckDisabled) `
      "$ServiceName remains publicly invokable after containment."
    return
  }
  Assert-True (
    $isInvokerCheckDisabled
  ) (
    "$ServiceName must disable only the service-level invoker IAM check " +
    "so Firebase App Check can guard application requests."
  )
}

function Normalize-Sha256 {
  param([Parameter(Mandatory = $true)][string]$Value)

  $normalized = ($Value -replace ":", "").Trim().ToUpperInvariant()
  Assert-True ($normalized -match "^[0-9A-F]{64}$") `
    "ExpectedSha256 must be one SHA-256 certificate fingerprint."
  return $normalized
}

Assert-True ($ProjectId -eq $expectedProject) `
  "Only $expectedProject is authorized by this verifier."
if (
  $ExpectedCapabilityProfile -eq "Disabled" -or
  $ExpectedCapabilityProfile -eq "PublicDataReview"
) {
  Assert-True ([string]::IsNullOrWhiteSpace($ExpectedProofExpiresAt)) `
    "A non-proof profile cannot declare a proof expiry."
} else {
  Assert-True (
    Test-YouTubePrivateDevProofExpiration $ExpectedProofExpiresAt
  ) "The expected proof expiry is malformed, expired, or exceeds 30 minutes."
}
$manifest = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot `
    "deployment/youtube-private-dev/deployment-manifest.json"
) | ConvertFrom-Json

$preflight = & powershell -NoProfile -ExecutionPolicy Bypass `
  -File (Join-Path $PSScriptRoot "check-youtube-private-dev-preflight.ps1") `
  -ProjectId $ProjectId 2>&1
Assert-True ($LASTEXITCODE -eq 0) `
  "Local private Dev preflight failed.`n$($preflight | Out-String)"

if ($StaticOnly) {
  Write-Host "YouTube private Dev deployment verifier parsed and passed its local preflight."
  Write-Host "No cloud command or endpoint request was made."
  exit 0
}

Assert-RequiredValue $BillingAccountId "BillingAccountId"
Assert-RequiredValue $ServerApiKeyUid "ServerApiKeyUid"
Assert-RequiredValue $AndroidAppId "AndroidAppId"
Assert-RequiredValue $ExpectedSha256 "ExpectedSha256"
Assert-True (
  $BillingAccountId -eq $expectedBillingAccountId
) "Only the reviewed private Dev billing account may be verified."
Assert-True (
  $BudgetDisplayName -eq $manifest.budget.displayName
) "The budget display name does not match the reviewed manifest."
Assert-True (
  [decimal]$manifest.budget.approvedMonthlyAmount -eq 1000 -and
  $manifest.budget.controlType -eq "alert-target-not-spend-cap"
) "The INR 1,000 monthly budget alert target contract changed."
Assert-True (
  $ServerApiKeyUid -match "^[A-Za-z0-9_-]{8,128}$"
) "ServerApiKeyUid must be the API key UID, never the key string."
Assert-True (
  $AndroidAppId -match "^1:[0-9]+:android:[a-fA-F0-9]+$"
) "AndroidAppId has an invalid Firebase Android app ID format."
$sha256 = Normalize-Sha256 $ExpectedSha256

$cloudPreflight = & powershell -NoProfile -ExecutionPolicy Bypass `
  -File (Join-Path $PSScriptRoot "check-youtube-private-dev-preflight.ps1") `
  -ProjectId $ProjectId `
  -Cloud `
  -RequireBilling `
  -BillingAccountId $BillingAccountId 2>&1
Assert-True ($LASTEXITCODE -eq 0) `
  "Cloud private Dev preflight failed.`n$($cloudPreflight | Out-String)"

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if ($null -eq $gcloud) {
  $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
}
Assert-True ($null -ne $gcloud) "gcloud is required for cloud verification."
$script:GcloudExecutable = $gcloud.Definition

$securityArguments = @(
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  (Join-Path $PSScriptRoot `
    "check-youtube-private-dev-security-prerequisites.ps1"),
  "-ProjectId",
  $ProjectId,
  "-ServerApiKeyUid",
  $ServerApiKeyUid,
  "-AndroidAppId",
  $AndroidAppId,
  "-ExpectedSha256",
  $ExpectedSha256
)
if ($AllowNoServerIpRestriction) {
  $securityArguments += "-AllowNoServerIpRestriction"
}
$securityPreflight = & powershell @securityArguments 2>&1
Assert-True ($LASTEXITCODE -eq 0) `
  (
    "The deployed security configuration is unsafe or incomplete.`n" +
    ($securityPreflight | Out-String)
  )

$project = Invoke-GcloudJson `
  @("projects", "describe", $ProjectId) `
  "inspect the Dev project"
Assert-True ($project.projectId -eq $expectedProject) `
  "Cloud project identity mismatch."
Assert-True ("$($project.projectNumber)" -eq $expectedProjectNumber) `
  "Cloud project number mismatch."
$projectParent = PropertyValue $project "parent"
Assert-True (
  $null -ne $projectParent -and
  (PropertyValue $projectParent "type") -eq "organization" -and
  "$(PropertyValue $projectParent "id")" -eq $expectedOrganizationId
) "The Dev project belongs to a different organization."
Assert-True ($project.lifecycleState -eq "ACTIVE") `
  "The Dev project is not ACTIVE."

$billing = Invoke-GcloudJson `
  @("billing", "projects", "describe", $ProjectId) `
  "inspect Dev project billing"
Assert-True ($billing.billingEnabled -eq $true) `
  "Billing is not enabled for the Dev project."
Assert-True (
  $billing.billingAccountName -eq "billingAccounts/$BillingAccountId"
) "The Dev project is linked to a different billing account."

$billingAccount = Invoke-GcloudJson `
  @("billing", "accounts", "describe", $BillingAccountId) `
  "inspect the authorized billing account"
Assert-True ($billingAccount.open -eq $true) `
  "The authorized billing account is not open."

$services = & $script:GcloudExecutable services list `
  --enabled `
  --project=$ProjectId `
  --quiet `
  --format="value(config.name)" 2>$null
Assert-True ($LASTEXITCODE -eq 0) "Unable to inspect enabled services."
$enabledServices = @($services | ForEach-Object { "$_".Trim() })
Assert-ExactStringSet `
  $enabledServices `
  @($manifest.allowedEnabledServices) `
  "The enabled Google service inventory"

$functionInventoryResult = Invoke-GcloudJson `
  @(
    "functions",
    "list",
    "--v2",
    "--project=$ProjectId"
  ) `
  "inspect the deployed function inventory"
$functionInventory = @(
  if ($null -ne $functionInventoryResult) {
    @($functionInventoryResult)
  }
)
$providerFunctionNames = @(
  $functionInventory |
    Where-Object {
      $labels = PropertyValue $_ "labels"
      (PropertyValue $labels "firebase-functions-codebase") -eq "provider"
    } |
    ForEach-Object {
      $name = "$(PropertyValue $_ "name")"
      ($name -split "/")[-1]
    }
)
Assert-ExactStringSet `
  $providerFunctionNames `
  @($expectedFunctions.Keys) `
  "The deployed provider-codebase function inventory"

$budgetResult = Invoke-GcloudJson `
  @(
    "billing",
    "budgets",
    "list",
    "--billing-account=$BillingAccountId"
  ) `
  "inspect billing budgets"
$budgets = @(
  if ($null -ne $budgetResult) {
    @($budgetResult)
  }
)
$projectBudget = @(
  $budgets |
    Where-Object {
      $budgetFilter = PropertyValue $_ "budgetFilter"
      $projectValue = if ($null -eq $budgetFilter) {
        $null
      } else {
        PropertyValue $budgetFilter "projects"
      }
      $projects = @(
        if ($null -ne $projectValue) {
          @($projectValue)
        }
      )
      ($projects.Count -eq 1) -and
      ($projects[0] -eq "projects/$expectedProjectNumber") -and
      (
        [string]::IsNullOrWhiteSpace($BudgetDisplayName) -or
        (PropertyValue $_ "displayName") -eq $BudgetDisplayName
      )
    }
)
Assert-True ($projectBudget.Count -eq 1) `
  "Expected exactly one project-scoped Dev billing budget."
$budget = $projectBudget[0]
$budgetAmount = PropertyValue $budget "amount"
$specifiedAmount = PropertyValue $budgetAmount "specifiedAmount"
Assert-True ($null -ne $specifiedAmount) `
  "The Dev budget must use a fixed amount."
Assert-True (
  (PropertyValue $specifiedAmount "currencyCode") -eq
    $manifest.budget.currency
) "The Dev budget currency does not match the reviewed manifest."
$unitsValue = PropertyValue $specifiedAmount "units"
$nanosValue = PropertyValue $specifiedAmount "nanos"
$units = if ($null -eq $unitsValue) { 0 } else { [decimal]$unitsValue }
$nanos = if ($null -eq $nanosValue) { 0 } else { [decimal]$nanosValue }
$actualBudgetAmount = $units + ($nanos / 1000000000)
Assert-True (
  $actualBudgetAmount -eq [decimal]$manifest.budget.approvedMonthlyAmount
) "The Dev budget amount does not match the founder-approved manifest."
Assert-True (
  (PropertyValue $budget.budgetFilter "calendarPeriod") -eq
    $manifest.budget.calendarPeriod
) "The Dev budget must use a monthly calendar period."
$thresholdRules = @(PropertyValue $budget "thresholdRules")
$thresholds = @(
  $thresholdRules |
    ForEach-Object {
      Assert-True (
        (PropertyValue $_ "spendBasis") -eq
          $manifest.budget.spendBasis
      ) "Every budget threshold must use current spend."
      [decimal](PropertyValue $_ "thresholdPercent")
    }
)
Assert-True (
  $thresholds.Count -eq @($manifest.budget.thresholds).Count -and
  @(Compare-Object `
    @($manifest.budget.thresholds | ForEach-Object { [decimal]$_ }) `
    $thresholds).Count -eq 0
) "The Dev budget thresholds do not match the reviewed manifest."

$functionStates = @{}
$functionSourceBuckets = @()
foreach ($functionName in $expectedFunctions.Keys) {
  $state = Invoke-GcloudJson `
    @(
      "functions",
      "describe",
      $functionName,
      "--v2",
      "--region=$expectedRegion",
      "--project=$ProjectId"
    ) `
    "inspect function $functionName"
  Assert-True ($state.state -eq "ACTIVE") `
    "$functionName is not ACTIVE."
  Assert-True ($state.buildConfig.runtime -eq "nodejs22") `
    "$functionName does not use nodejs22."
  Assert-True (
    (PropertyValue $state.buildConfig "serviceAccount") -eq
      "projects/$ProjectId/serviceAccounts/$expectedBuildServiceAccount"
  ) "$functionName uses an unreviewed build service account."
  Assert-True (
    $state.buildConfig.entryPoint -eq $expectedFunctions[$functionName]
  ) "$functionName has the wrong entry point."
  Assert-True (
    "$(PropertyValue $state.serviceConfig "timeoutSeconds")" -match
      "^120s?$"
  ) "$functionName must retain the 120-second timeout."
  Assert-True (
    "$(PropertyValue $state.serviceConfig "availableMemory")" -match
      "^512(M|Mi|MiB)$"
  ) "$functionName must retain 512 MiB memory."
  Assert-True (
    (PropertyValue $state.serviceConfig "serviceAccountEmail") -eq
      $expectedRuntimeServiceAccount
  ) "$functionName uses an unreviewed runtime service account."
  $buildSource = PropertyValue $state.buildConfig "source"
  $storageSource = PropertyValue $buildSource "storageSource"
  $sourceBucket = "$(PropertyValue $storageSource "bucket")"
  Assert-True (
    $sourceBucket -match (
      "^gcf-v2-sources-" +
      [regex]::Escape($expectedProjectNumber) +
      "-" +
      [regex]::Escape($expectedRegion) +
      "$"
    )
  ) "$functionName uses an unexpected Functions source bucket."
  $functionSourceBuckets += $sourceBucket
  $minInstances = PropertyValue $state.serviceConfig "minInstanceCount"
  if ($null -eq $minInstances) {
    $minInstances = 0
  }
  Assert-True ([int]$minInstances -eq 0) `
    "$functionName must scale to zero."
  Assert-True ([int]$state.serviceConfig.maxInstanceCount -eq 1) `
    "$functionName must cap max instances at one."
  Assert-True (
    [int]$state.serviceConfig.maxInstanceRequestConcurrency -eq 1
  ) "$functionName must cap concurrency at one."

  $variables = $state.serviceConfig.environmentVariables
  foreach ($entry in $expectedFlags.GetEnumerator()) {
    $actual = PropertyValue $variables $entry.Key
    Assert-True ("$actual" -eq $entry.Value) `
      "$functionName has an unexpected $($entry.Key) value."
  }
  $actualProofProfile = PropertyValue $variables "YOUTUBE_PROOF_PROFILE"
  $actualProofExpiry = PropertyValue $variables "YOUTUBE_PROOF_EXPIRES_AT"
  $actualReviewMode = PropertyValue `
    $variables `
    "YOUTUBE_PUBLIC_DATA_REVIEW_MODE"
  if ($ExpectedCapabilityProfile -eq "Disabled") {
    Assert-True ($null -eq $actualProofProfile) `
      "$functionName retains a proof profile in the all-disabled state."
    Assert-True ($null -eq $actualProofExpiry) `
      "$functionName retains a proof expiry in the all-disabled state."
    Assert-True ($null -eq $actualReviewMode) `
      "$functionName retains an accepted public review mode while disabled."
  } elseif ($ExpectedCapabilityProfile -eq "PublicDataReview") {
    Assert-True ($null -eq $actualProofProfile) `
      "$functionName mixes accepted public review with a proof profile."
    Assert-True ($null -eq $actualProofExpiry) `
      "$functionName mixes accepted public review with a proof expiry."
    Assert-True (
      "$actualReviewMode" -ceq
      $script:YouTubePrivateDevAcceptedPublicReviewMode
    ) "$functionName has an unexpected accepted public review mode."
  } else {
    Assert-True ($null -eq $actualReviewMode) `
      "$functionName mixes supervised proof with accepted public review."
    $expectedTransportExpiry = "utc:$ExpectedProofExpiresAt"
    Assert-True (
      "$actualProofProfile" -ceq "$($expectedProfile.RuntimeName)"
    ) "$functionName has an unexpected proof profile."
    Assert-True (
      "$actualProofExpiry" -ceq $expectedTransportExpiry
    ) "$functionName has an unexpected proof expiry."
    Assert-True (
      Test-YouTubePrivateDevProofExpiration (
        "$actualProofExpiry".Substring(4)
      )
    ) "$functionName proof expiry is no longer inside the safe window."
  }

  $secretKeys = @(
    $state.serviceConfig.secretEnvironmentVariables |
      ForEach-Object { $_.key }
  )
  Assert-ExactStringSet `
    $secretKeys `
    $expectedSecrets `
    "$functionName Secret Manager binding inventory"
  Assert-True ($state.serviceConfig.uri -match "^https://") `
    "$functionName does not expose an HTTPS URI."

  $runServiceResource = "$(PropertyValue $state.serviceConfig "service")"
  $runServicePattern = (
    "^projects/(" +
    [regex]::Escape($ProjectId) +
    "|" +
    [regex]::Escape($expectedProjectNumber) +
    ")/locations/" +
    [regex]::Escape($expectedRegion) +
    "/services/([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)$"
  )
  Assert-True ($runServiceResource -match $runServicePattern) `
    "$functionName does not identify its reviewed Cloud Run service."
  $runServiceName = ($runServiceResource -split "/")[-1]
  $runState = Invoke-GcloudJson `
    @(
      "run",
      "services",
      "describe",
      $runServiceName,
      "--region=$expectedRegion",
      "--project=$ProjectId"
    ) `
    "inspect Cloud Run rollout state for $functionName"
  $invokerPolicy = Invoke-GcloudJson `
    @(
      "run",
      "services",
      "get-iam-policy",
      $runServiceName,
      "--region=$expectedRegion",
      "--project=$ProjectId"
    ) `
    "inspect Cloud Run invoker IAM for $functionName"
  Assert-RunInvocationBoundary `
    $invokerPolicy `
    $runServiceName `
    $runState `
    -ExpectContainedBoundary:$ExpectContained
  Assert-True (
    "$(PropertyValue $runState.metadata "name")" -eq $runServiceName
  ) "$functionName resolved to an unexpected Cloud Run service."
  $latestReadyRevision = "$(
    PropertyValue $runState.status "latestReadyRevisionName"
  )"
  Assert-True (-not [string]::IsNullOrWhiteSpace($latestReadyRevision)) `
    "$functionName has no latest ready Cloud Run revision."
  Assert-True (
    "$(PropertyValue $runState.status "latestCreatedRevisionName")" -eq
      $latestReadyRevision
  ) "$functionName latest Cloud Run revision is not ready."
  $traffic = @(
    PropertyValue $runState.status "traffic"
  )
  Assert-True ($traffic.Count -eq 1) `
    "$functionName must route through exactly one Cloud Run traffic target."
  Assert-True ([int](PropertyValue $traffic[0] "percent") -eq 100) `
    "$functionName must route 100 percent to the latest ready revision."
  Assert-True (
    "$(PropertyValue $traffic[0] "revisionName")" -eq $latestReadyRevision
  ) "$functionName traffic does not target the latest ready revision."
  Assert-True (
    [string]::IsNullOrWhiteSpace("$(PropertyValue $traffic[0] "tag")")
  ) "$functionName must not retain a tagged alternate traffic target."
  $functionStates[$functionName] = $state
}
Assert-ExactStringSet `
  $functionSourceBuckets `
  @("gcf-v2-sources-$expectedProjectNumber-$expectedRegion") `
  "The Functions deployment-source bucket inventory"

$artifactRepository = Invoke-GcloudJson `
  @(
    "artifacts",
    "repositories",
    "describe",
    "gcf-artifacts",
    "--location=$expectedRegion",
    "--project=$ProjectId"
  ) `
  "inspect the Functions artifact repository"
$cleanupPolicies = PropertyValue $artifactRepository "cleanupPolicies"
$cleanupPolicy = PropertyValue `
  $cleanupPolicies `
  "firebase-functions-cleanup"
Assert-True ($null -ne $cleanupPolicy) `
  "The mandatory Functions artifact cleanup policy is missing."
Assert-True ((PropertyValue $cleanupPolicy "action") -eq "DELETE") `
  "The Functions artifact cleanup policy must delete old images."
$cleanupCondition = PropertyValue $cleanupPolicy "condition"
Assert-True (
  (PropertyValue $cleanupCondition "tagState") -eq "ANY" -and
  (PropertyValue $cleanupCondition "olderThan") -eq "86400s"
) "The Functions artifact cleanup policy must retain only one day."
Assert-True (
  (PropertyValue $artifactRepository "cleanupPolicyDryRun") -ne $true
) "The Functions artifact cleanup policy cannot remain in dry-run mode."
$artifactLabels = PropertyValue $artifactRepository "labels"
Assert-True (
  (PropertyValue $artifactLabels "firebase-functions-cleanup-opted-out") -ne
    "true"
) "The Functions artifact repository is opted out of cleanup."

$projectIam = Invoke-GcloudJson `
  @("projects", "get-iam-policy", $ProjectId) `
  "inspect project IAM"
$requiredManagedServiceAgentRoles = @{
  "service-$expectedProjectNumber@gcf-admin-robot.iam.gserviceaccount.com" =
    "roles/cloudfunctions.serviceAgent"
  "service-$expectedProjectNumber@serverless-robot-prod.iam.gserviceaccount.com" =
    "roles/run.serviceAgent"
}
$optionalManagedServiceAgentRoles = @{
  "service-$expectedProjectNumber@gcp-sa-eventarc.iam.gserviceaccount.com" =
    "roles/eventarc.serviceAgent"
  "service-$expectedProjectNumber@gcp-sa-pubsub.iam.gserviceaccount.com" =
    "roles/pubsub.serviceAgent"
}
foreach ($entry in $requiredManagedServiceAgentRoles.GetEnumerator()) {
  $managedServiceAgentMember = "serviceAccount:$($entry.Key)"
  $managedServiceAgentRoles = @(
    RolesForMember $projectIam $managedServiceAgentMember
  )
  Assert-True ($managedServiceAgentRoles -contains $entry.Value) (
    "The required managed service-agent role is missing for $($entry.Key)."
  )
  Assert-True (
    ($managedServiceAgentRoles -notcontains "roles/owner") -and
    ($managedServiceAgentRoles -notcontains "roles/editor")
  ) "A managed service agent has an overbroad primitive project role."
}
foreach ($entry in $optionalManagedServiceAgentRoles.GetEnumerator()) {
  $managedServiceAgentMember = "serviceAccount:$($entry.Key)"
  $managedServiceAgentRoles = @(
    RolesForMember $projectIam $managedServiceAgentMember
  )
  if ($managedServiceAgentRoles.Count -gt 0) {
    Assert-ExactStringSet `
      $managedServiceAgentRoles `
      @($entry.Value) `
      "The optional managed service-agent role inventory for $($entry.Key)"
  }
}

$runtimeAccounts = @(
  $functionStates.Values |
    ForEach-Object { $_.serviceConfig.serviceAccountEmail } |
    Select-Object -Unique
)
Assert-True ($runtimeAccounts.Count -eq 1) `
  "The provider functions must use one reviewed runtime service account."
Assert-True (
  $runtimeAccounts[0] -eq $expectedRuntimeServiceAccount
) "The provider runtime service account identity changed."
$runtimeUserManagedKeyResult = Invoke-GcloudJson `
  @(
    "iam",
    "service-accounts",
    "keys",
    "list",
    "--iam-account=$expectedRuntimeServiceAccount",
    "--managed-by=user",
    "--project=$ProjectId"
  ) `
  "inspect provider runtime service-account keys"
$runtimeUserManagedKeys = @(
  if ($null -ne $runtimeUserManagedKeyResult) {
    @($runtimeUserManagedKeyResult)
  }
)
Assert-True ($runtimeUserManagedKeys.Count -eq 0) `
  "The provider runtime service account has a user-managed key."
$runtimeMember = "serviceAccount:$($runtimeAccounts[0])"
$publicProjectBindings = @(
  @(PropertyValue $projectIam "bindings") |
    Where-Object {
      (@($_.members) -contains "allUsers") -or
      (@($_.members) -contains "allAuthenticatedUsers")
    }
)
Assert-True ($publicProjectBindings.Count -eq 0) `
  "Public project-level IAM bindings are forbidden for private Dev."
$projectSecretAccessorMembers = @(
  @(PropertyValue $projectIam "bindings") |
    Where-Object {
      (PropertyValue $_ "role") -eq "roles/secretmanager.secretAccessor"
    } |
    ForEach-Object { @($_.members) }
)
Assert-True ($projectSecretAccessorMembers.Count -eq 0) `
  "Secret accessor grants must be scoped to individual provider secrets."
$runtimeRoles = RolesForMember $projectIam $runtimeMember
Assert-True (
  $runtimeRoles -contains "roles/firebaseappcheck.tokenVerifier"
) "The runtime service account cannot consume limited-use App Check tokens."
Assert-ExactStringSet `
  $runtimeRoles `
  @(
    "roles/datastore.user",
    "roles/firebaseappcheck.tokenVerifier"
  ) `
  "The runtime service account project-role inventory"

foreach ($secret in $expectedSecrets) {
  $policy = Invoke-GcloudJson `
    @(
      "secrets",
      "get-iam-policy",
      $secret,
      "--project=$ProjectId"
    ) `
    "inspect IAM for secret $secret"
  $publicSecretBindings = @(
    @(PropertyValue $policy "bindings") |
      Where-Object {
        (@($_.members) -contains "allUsers") -or
        (@($_.members) -contains "allAuthenticatedUsers")
      }
  )
  Assert-True ($publicSecretBindings.Count -eq 0) `
    "Public Secret Manager access is forbidden for $secret."
  $secretAccessorMembers = @(
    @(PropertyValue $policy "bindings") |
      Where-Object {
        (PropertyValue $_ "role") -eq
          "roles/secretmanager.secretAccessor"
      } |
      ForEach-Object { @($_.members) }
  )
  Assert-ExactStringSet `
    $secretAccessorMembers `
    @($runtimeMember) `
    "The direct Secret Manager accessor inventory on $secret"
  $roles = RolesForMember $policy $runtimeMember
  Assert-True ($roles -contains "roles/secretmanager.secretAccessor") `
    "The runtime service account cannot access $secret."
}

$apiKey = Invoke-GcloudJson `
  @(
    "services",
    "api-keys",
    "describe",
    $ServerApiKeyUid,
    "--location=global",
    "--project=$ProjectId"
  ) `
  "inspect the restricted YouTube server API key"
Assert-True (
  $apiKey.name -eq
    "projects/$expectedProjectNumber/locations/global/keys/$ServerApiKeyUid"
) "The server API key resource identity changed."
$apiKeyDeleteTime = "$(PropertyValue $apiKey "deleteTime")".Trim()
Assert-True ([string]::IsNullOrWhiteSpace($apiKeyDeleteTime)) `
  "The server API key is deleted or pending deletion."
$keyRestrictions = PropertyValue $apiKey "restrictions"
Assert-True ($null -ne $keyRestrictions) `
  "The server API key has no restrictions."
$apiTargetValue = PropertyValue $keyRestrictions "apiTargets"
$apiTargets = @(
  if ($null -ne $apiTargetValue) {
    @($apiTargetValue)
  }
)
Assert-True ($apiTargets.Count -eq 1) `
  "The server API key must target exactly one API."
Assert-True ($apiTargets[0].service -eq "youtube.googleapis.com") `
  "The server API key is not restricted to YouTube Data API v3."
foreach ($forbiddenRestriction in @(
  "androidKeyRestrictions",
  "browserKeyRestrictions",
  "iosKeyRestrictions"
)) {
  Assert-True (
    $null -eq (PropertyValue $keyRestrictions $forbiddenRestriction)
  ) "The backend key has an invalid $forbiddenRestriction block."
}
$serverRestrictions = PropertyValue `
  $keyRestrictions `
  "serverKeyRestrictions"
$allowedIpValue = if ($null -eq $serverRestrictions) {
  $null
} else {
  PropertyValue $serverRestrictions "allowedIps"
}
$allowedIps = @(
  if ($null -ne $allowedIpValue) {
    @($allowedIpValue)
  }
)
if ($allowedIps.Count -eq 0) {
  Assert-True ($AllowNoServerIpRestriction.IsPresent) `
    (
      "The key has no fixed server IP restriction. Pass " +
      "-AllowNoServerIpRestriction only under the runbook's recorded " +
      "compensating controls."
    )
} else {
  Assert-True (
    ($allowedIps -notcontains "0.0.0.0/0") -and
    ($allowedIps -notcontains "::/0")
  ) "The server API key allows an unrestricted source range."
}

$accessTokenOutput = & $script:GcloudExecutable `
  auth print-access-token --quiet 2>$null
Assert-True ($LASTEXITCODE -eq 0) `
  "Unable to obtain a short-lived token for read-only Firebase inspection."
$accessToken = ($accessTokenOutput | Out-String).Trim()
Assert-True (-not [string]::IsNullOrWhiteSpace($accessToken)) `
  "The read-only Firebase inspection token was empty."
$escapedAppId = [uri]::EscapeDataString($AndroidAppId)

$androidApp = Get-GoogleJson `
  "https://firebase.googleapis.com/v1beta1/projects/$ProjectId/androidApps/$escapedAppId" `
  $accessToken `
  "inspect the Dev Android app"
Assert-True ((PropertyValue $androidApp "state") -eq "ACTIVE") `
  "The Firebase Android app is not active."
Assert-True (
  (PropertyValue $androidApp "packageName") -eq "com.moolsocial.app"
) "The Firebase Android app package identity changed."

$firestoreRelease = Get-GoogleJson `
  "https://firebaserules.googleapis.com/v1/projects/$ProjectId/releases/cloud.firestore" `
  $accessToken `
  "inspect the active default Firestore Rules release"
$rulesetName = PropertyValue $firestoreRelease "rulesetName"
Assert-True (
  -not [string]::IsNullOrWhiteSpace("$rulesetName")
) "The active default Firestore release has no ruleset."
$firestoreRuleset = Get-GoogleJson `
  "https://firebaserules.googleapis.com/v1/$rulesetName" `
  $accessToken `
  "inspect the active default Firestore Rules source"
$rulesSource = PropertyValue $firestoreRuleset "source"
$rulesFiles = PropertyValue $rulesSource "files"
Assert-True (
  $null -ne $rulesFiles -and @($rulesFiles).Count -eq 1
) "The active default Firestore ruleset must contain exactly one file."
$activeFirestoreRules = (
  "$(PropertyValue @($rulesFiles)[0] "content")" -replace "`r`n", "`n"
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
"@
$expectedFirestoreRules = (
  $expectedFirestoreRules -replace "`r`n", "`n"
).Trim()
Assert-True (
  $activeFirestoreRules -ceq $expectedFirestoreRules
) "The active default Firestore Rules release is not exact deny-all."

$playIntegrity = Get-GoogleJson `
  "https://firebaseappcheck.googleapis.com/v1/projects/$expectedProjectNumber/apps/$escapedAppId/playIntegrityConfig" `
  $accessToken `
  "inspect the Play Integrity App Check registration"
Assert-True (
  $playIntegrity.name -eq
    "projects/$expectedProjectNumber/apps/$AndroidAppId/playIntegrityConfig"
) "The Play Integrity App Check registration does not match the Dev app."
$appIntegrity = PropertyValue $playIntegrity "appIntegrity"
Assert-True (
  (PropertyValue $appIntegrity "allowUnrecognizedVersion") -eq $true
) "Private Dev OPPO proof requires unrecognized sideloaded versions."
$accountDetails = PropertyValue $playIntegrity "accountDetails"
Assert-True (
  Test-YouTubePrivateDevEffectiveFalse (
    PropertyValue $accountDetails "requireLicensed"
  )
) "Private Dev OPPO proof cannot require a Play Store license."
$deviceIntegrity = PropertyValue $playIntegrity "deviceIntegrity"
Assert-True (
  (PropertyValue $deviceIntegrity "minDeviceRecognitionLevel") -eq
    "MEETS_DEVICE_INTEGRITY"
) "Private Dev OPPO proof must still require device integrity."

$certificates = Get-GoogleJson `
  "https://firebase.googleapis.com/v1beta1/projects/$ProjectId/androidApps/$escapedAppId/sha" `
  $accessToken `
  "inspect the Dev Android signing certificates"
$certificateList = PropertyValue $certificates "certificates"
$sha256Certificates = @(
  if ($null -ne $certificateList) {
    @($certificateList) |
      Where-Object { (PropertyValue $_ "certType") -eq "SHA_256" } |
      ForEach-Object {
        $hash = PropertyValue $_ "shaHash"
        if ($null -ne $hash) {
          Normalize-Sha256 "$hash"
        }
      }
  }
)
Assert-True ($sha256Certificates -contains $sha256) `
  "The expected Dev SHA-256 fingerprint is not registered."

$debugTokens = Get-GoogleJson `
  "https://firebaseappcheck.googleapis.com/v1/projects/$expectedProjectNumber/apps/$escapedAppId/debugTokens?pageSize=100" `
  $accessToken `
  "inspect registered App Check debug tokens"
$registeredDebugTokens = PropertyValue $debugTokens "debugTokens"
$debugTokenCount = if ($null -eq $registeredDebugTokens) {
  0
} else {
  @($registeredDebugTokens).Count
}
Assert-True ($debugTokenCount -eq 0) `
  "Registered App Check debug tokens remain in the Dev project."

Add-Type -AssemblyName System.Net.Http
$http = [System.Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromSeconds(20)
try {
  $content = [System.Net.Http.StringContent]::new(
    '{"operation":"capabilities"}',
    [System.Text.Encoding]::UTF8,
    "application/json"
  )
  $providerUri = $functionStates["youtubeProvider"].serviceConfig.uri
  $response = $http.PostAsync($providerUri, $content).GetAwaiter().GetResult()
  $status = [int]$response.StatusCode
  $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
  if ($ExpectContained) {
    Assert-True ($status -eq 403) `
      "The contained provider endpoint did not reject invocation with HTTP 403."
  } else {
    Assert-True ($status -eq 401) `
      "A request without App Check was not rejected with HTTP 401."
    try {
      $failure = $body | ConvertFrom-Json
    } catch {
      throw "The App Check rejection response was not valid JSON."
    }
    Assert-True ($failure.ok -eq $false) `
      "The App Check rejection response was not a failure."
    Assert-True ($failure.error.code -eq "permission_denied") `
      "The App Check rejection returned an unexpected error code."
  }
} finally {
  $http.Dispose()
  $accessToken = $null
}

Write-Host "YouTube private Dev post-deployment verification passed."
Write-Host "Project: $ProjectId ($expectedProjectNumber)"
Write-Host "Region: $expectedRegion"
Write-Host "Billing: open, linked, project budget present"
Write-Host "Capabilities: $ExpectedCapabilityProfile"
Write-Host "Functions: scale-to-zero, maxInstances=1, concurrency=1"
Write-Host (
  "Invocation: " +
  $(if ($ExpectContained) { "hard-contained" } else { "App Check guarded" })
)
Write-Host "IAM/secrets/API key/App Check: verified without exposing values"
Write-Host "Cloud mutations performed: none"
