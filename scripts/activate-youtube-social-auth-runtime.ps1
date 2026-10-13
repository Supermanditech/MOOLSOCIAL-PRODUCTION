[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = 'None')]
param(
  [ValidateRange(5, 29)]
  [int]$LifetimeMinutes = 29,
  [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$project = 'moolsocial-dev-503018'
$region = 'asia-south1'
$profile = 'socialAuthRuntime'
$callback =
  'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/' +
  'youtubeOAuthCallback'
$services = @('youtubeprovider', 'youtubeoauthcallback')
$gcloud = (Get-Command gcloud -ErrorAction Stop).Source
$expiry = 'utc:' + [DateTime]::UtcNow.AddMinutes($LifetimeMinutes).ToString(
  'yyyy-MM-ddTHH:mm:ssZ'
)

if (-not $ValidateOnly) {
  $runtimeValues = @(
    "YOUTUBE_OAUTH_REDIRECT_URI=$callback",
    "YOUTUBE_PROOF_PROFILE=$profile",
    "YOUTUBE_PROOF_EXPIRES_AT=$expiry",
    'YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED=true',
    'MOOLSOCIAL_PROVIDER_ENV=dev'
  ) -join ','

  foreach ($service in $services) {
    & $gcloud run services update $service `
      --region=$region `
      --project=$project `
      --update-env-vars $runtimeValues `
      --quiet `
      --format='value(status.latestReadyRevisionName)' | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "YouTube runtime activation failed for $service."
    }
  }
}

$verified = @{}
foreach ($service in $services) {
  $description = & $gcloud run services describe $service `
    --region=$region `
    --project=$project `
    --format=json 2>$null | ConvertFrom-Json
  if ($LASTEXITCODE -ne 0) {
    throw "YouTube runtime verification failed for $service."
  }

  $environment = @{}
  foreach ($entry in @($description.spec.template.spec.containers[0].env)) {
    $valueProperty = $entry.PSObject.Properties['value']
    if (
      -not [string]::IsNullOrWhiteSpace([string]$entry.name) -and
      $null -ne $valueProperty
    ) {
      $environment[[string]$entry.name] = [string]$valueProperty.Value
    }
  }
  $ready = @($description.status.conditions | Where-Object {
    $_.type -eq 'Ready' -and $_.status -eq 'True'
  }).Count -eq 1
  $traffic = (@($description.status.traffic | Measure-Object percent -Sum).Sum) `
    -eq 100
  $configuredExpiry = [string]$environment['YOUTUBE_PROOF_EXPIRES_AT']
  $parsedExpiry = [DateTime]::MinValue
  $expiryIsFuture = [DateTime]::TryParse(
    ($configuredExpiry -replace '^utc:', ''),
    [ref]$parsedExpiry
  ) -and $parsedExpiry.ToUniversalTime() -gt [DateTime]::UtcNow

  if (
    -not $ready -or
    -not $traffic -or
    $environment['MOOLSOCIAL_PROVIDER_ENV'] -ne 'dev' -or
    $environment['YOUTUBE_PROOF_PROFILE'] -ne $profile -or
    $environment['YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED'] -ne 'true' -or
    $environment['YOUTUBE_OAUTH_REDIRECT_URI'] -ne $callback -or
    -not $expiryIsFuture
  ) {
    throw "YouTube runtime tuple is incomplete for $service."
  }
  $verified[$service] = @{
    revision = [string]$description.status.latestReadyRevisionName
    expiry = $configuredExpiry
  }
}

if ($verified['youtubeprovider'].expiry -ne $verified['youtubeoauthcallback'].expiry) {
  throw 'YouTube provider and callback expiry values differ.'
}
if (-not $ValidateOnly -and $verified['youtubeprovider'].expiry -ne $expiry) {
  throw 'YouTube runtime expiry differs from this activation request.'
}

Write-Output (
  'YOUTUBE_SOCIAL_AUTH_RUNTIME_READY ' +
  "provider=$($verified['youtubeprovider'].revision) " +
  "callback=$($verified['youtubeoauthcallback'].revision) " +
  "expiry=$($verified['youtubeprovider'].expiry)"
)
