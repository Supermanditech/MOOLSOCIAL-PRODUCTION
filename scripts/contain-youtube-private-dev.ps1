[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = "None")]
param(
  [ValidateSet("moolsocial-dev-503018")]
  [string]$ProjectId = "moolsocial-dev-503018",
  [ValidateSet("asia-south1")]
  [string]$Region = "asia-south1",
  [string]$Confirmation = "",
  [switch]$StaticOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedConfirmation = "CONTAIN_YOUTUBE_PRIVATE_DEV_NOW"
$expectedRunServiceNames = @{
  youtubeProvider = "youtubeprovider"
  youtubeOAuthCallback = "youtubeoauthcallback"
}

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

function Invoke-GcloudNoOutput {
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
    & $script:GcloudExecutable @Arguments --quiet --verbosity=none *> $null
    $commandExitCode = $LASTEXITCODE
  } finally {
    if ($null -ne $nativePreference) {
      $PSNativeCommandUseErrorActionPreference = $previousNativePreference
    }
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Assert-True ($commandExitCode -eq 0) "Unable to $Description."
}

function Invoke-OptionalGcloudJson {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [Parameter(Mandatory = $true)]
    [string]$Description,
    [Parameter(Mandatory = $true)]
    [string[]]$AbsenceListArguments,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedResourceName
  )

  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    $output = & $script:GcloudExecutable @Arguments `
      --quiet --verbosity=none --format=json 2>$null
    $commandExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $text = ($output | Out-String).Trim()
  if ($commandExitCode -ne 0) {
    try {
      $ErrorActionPreference = "Continue"
      $listOutput = & $script:GcloudExecutable @AbsenceListArguments `
        --quiet --verbosity=none --format=json 2>$null
      $listExitCode = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($listExitCode -eq 0) (
      "Unable to verify absence while attempting to $Description."
    )
    $listText = ($listOutput | Out-String).Trim()
    try {
      $inventory = @($listText | ConvertFrom-Json)
    } catch {
      throw "The absence inventory for $Description was not valid JSON."
    }
    $matchingResources = @(
      $inventory |
        Where-Object {
          $name = Property-Value $_ "name"
          if ([string]::IsNullOrWhiteSpace("$name")) {
            $metadata = Property-Value $_ "metadata"
            $name = Property-Value $metadata "name"
          }
          "$name" -eq $ExpectedResourceName -or
          "$name" -match (
            "/" + [regex]::Escape($ExpectedResourceName) + "$"
          )
        }
    )
    Assert-True ($matchingResources.Count -eq 0) (
      "The exact resource still appears in inventory while attempting " +
      "to $Description."
    )
    return $null
  }
  try {
    return $text | ConvertFrom-Json
  } catch {
    throw "The $Description response was not valid JSON."
  }
}

function Get-ReviewedUnconditionalPublicInvokerBindings {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Policy
  )

  $bindings = Property-Value $Policy "bindings"
  if ($null -eq $bindings) {
    return @()
  }
  return @(
    @($bindings) |
      Where-Object {
        (Property-Value $_ "role") -eq "roles/run.invoker" -and
        $null -eq (Property-Value $_ "condition") -and
        (@($_.members) -contains "allUsers")
      }
  )
}

function Get-BroadPublicInvokerBindings {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Policy
  )

  $bindings = Property-Value $Policy "bindings"
  if ($null -eq $bindings) {
    return @()
  }
  return @(
    @($bindings) |
      Where-Object {
        (Property-Value $_ "role") -eq "roles/run.invoker" -and
        (
          (@($_.members) -contains "allUsers") -or
          (@($_.members) -contains "allAuthenticatedUsers")
        )
      }
  )
}

Assert-True ($ProjectId -eq $script:YouTubePrivateDevProject) `
  "Only the exact reviewed private Dev project may be contained."
Assert-True ($Region -eq $script:YouTubePrivateDevRegion) `
  "Only the exact reviewed private Dev region may be contained."
Assert-True ($Confirmation -eq $expectedConfirmation) `
  "Containment requires the exact one-purpose confirmation."

if ($StaticOnly) {
  Write-Host "Private Dev hard-containment contract passed locally."
  Write-Host "No cloud command was performed."
  exit 0
}

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if ($null -eq $gcloud) {
  $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
}
Assert-True ($null -ne $gcloud) "gcloud is required for hard containment."
$script:GcloudExecutable = $gcloud.Definition

$containmentFailures = @()
$containmentFailureMessages = @()
foreach ($functionName in $script:YouTubePrivateDevFunctionNames) {
  try {
    $state = Invoke-OptionalGcloudJson `
      @(
        "functions",
        "describe",
        $functionName,
        "--v2",
        "--region=$Region",
        "--project=$ProjectId"
      ) `
      "inspect the exact private Dev function $functionName" `
      @(
        "functions",
        "list",
        "--v2",
        "--regions=$Region",
        "--project=$ProjectId"
      ) `
      $functionName
    if ($null -eq $state) {
      Write-Host "$functionName is not deployed; no Run binding exists to remove."
      continue
    }
    $serviceConfig = Property-Value $state "serviceConfig"
    $runServiceResourceValue = Property-Value $serviceConfig "service"
    if ([string]::IsNullOrWhiteSpace("$runServiceResourceValue")) {
      $stateValue = "$(Property-Value $state "state")"
      $stateMessages = @(Property-Value $state "stateMessages")
      $cloudRunServiceMissing = @(
        $stateMessages |
          Where-Object {
            "$(Property-Value $_ "type")" -eq "CloudRunServiceNotFound"
          }
      ).Count -gt 0
      Assert-True (
        $stateValue -eq "FAILED" -and $cloudRunServiceMissing
      ) (
        "$functionName has no serviceConfig.service without an exact " +
        "FAILED CloudRunServiceNotFound state."
      )
      $expectedRunServiceName = $expectedRunServiceNames[$functionName]
      $unexpectedRunService = Invoke-OptionalGcloudJson `
        @(
          "run",
          "services",
          "describe",
          $expectedRunServiceName,
          "--region=$Region",
          "--project=$ProjectId"
        ) `
        "verify the absent Cloud Run service for $functionName" `
        @(
          "run",
          "services",
          "list",
          "--region=$Region",
          "--project=$ProjectId"
        ) `
        $expectedRunServiceName
      Assert-True ($null -eq $unexpectedRunService) (
        "$functionName reports CloudRunServiceNotFound, but the exact " +
        "reviewed Cloud Run service still exists."
      )
      Write-Host (
        "$functionName failed before Cloud Run service creation; " +
        "no Run binding exists to remove."
      )
      continue
    }
    $runServiceResource = "$runServiceResourceValue"
    $runServicePattern = (
      "^projects/(760290687711|" +
      [regex]::Escape($ProjectId) +
      ")/locations/" +
      [regex]::Escape($Region) +
      "/services/([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)$"
    )
    Assert-True ($runServiceResource -match $runServicePattern) `
      "$functionName does not identify an exact reviewed Cloud Run service."
    $runServiceName = ($runServiceResource -split "/")[-1]
    Assert-True (
      $runServiceName -eq $expectedRunServiceNames[$functionName]
    ) "$functionName resolved to an unexpected Cloud Run service."
    Invoke-GcloudNoOutput `
      @(
        "run",
        "services",
        "update",
        $runServiceName,
        "--invoker-iam-check",
        "--region=$Region",
        "--project=$ProjectId"
      ) `
      "restore the invoker IAM check for $runServiceName"
    $policy = Invoke-GcloudJson `
      @(
        "run",
        "services",
        "get-iam-policy",
        $runServiceName,
        "--region=$Region",
        "--project=$ProjectId"
      ) `
      "inspect invoker IAM for $runServiceName"
    $publicBindings = @(
      Get-ReviewedUnconditionalPublicInvokerBindings $policy
    )
    if ($publicBindings.Count -gt 0) {
      & $script:GcloudExecutable `
        run services remove-iam-policy-binding `
        $runServiceName `
        --member=allUsers `
        --role=roles/run.invoker `
        --condition=None `
        --region=$Region `
        --project=$ProjectId `
        --quiet *> $null
      Assert-True ($LASTEXITCODE -eq 0) `
        "Unable to remove the public invoker from $runServiceName."
    }
    $afterPolicy = Invoke-GcloudJson `
      @(
        "run",
        "services",
        "get-iam-policy",
        $runServiceName,
        "--region=$Region",
        "--project=$ProjectId"
      ) `
      "verify invoker IAM containment for $runServiceName"
    Assert-True (
      @(
        Get-BroadPublicInvokerBindings $afterPolicy
      ).Count -eq 0
    ) "A broad public invoker remains on $runServiceName."
    $containedRunState = Invoke-GcloudJson `
      @(
        "run",
        "services",
        "describe",
        $runServiceName,
        "--region=$Region",
        "--project=$ProjectId"
      ) `
      "verify the invoker IAM check for $runServiceName"
    $annotations = Property-Value $containedRunState.metadata "annotations"
    $invokerCheckDisabled = Property-Value `
      $annotations `
      "run.googleapis.com/invoker-iam-disabled"
    Assert-True (
      "$invokerCheckDisabled".ToLowerInvariant() -ne "true"
    ) "The invoker IAM check remains disabled on $runServiceName."
    Write-Host "Contained public invocation for $runServiceName."
  } catch {
    $containmentFailures += $functionName
    $containmentFailureMessages += (
      $functionName + ": " + $_.Exception.Message
    )
  }
}
if ($containmentFailures.Count -gt 0) {
  throw (
    "Hard containment could not be verified for: " +
    ($containmentFailures -join ",") +
    ". " +
    ($containmentFailureMessages -join " | ")
  )
}

Write-Host (
  "Hard containment restored the invoker IAM check and removed broad " +
  "Run invoker bindings from the exact two reviewed services."
)
