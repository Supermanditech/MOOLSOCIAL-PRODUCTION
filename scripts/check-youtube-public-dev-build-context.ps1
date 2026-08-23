[CmdletBinding()]
param(
  [string]$ExpectedConfiguration = 'moolsocial-dev-fsc02d',

  [string]$ExpectedAccount = 'hello@moolsocial.com',

  [string]$ExpectedProject = 'moolsocial-dev-503018'
)

$ErrorActionPreference = 'Stop'

function Invoke-GcloudSingleValue {
  param(
    [Parameter(Mandatory)]
    [string]$GcloudSource,

    [Parameter(Mandatory)]
    [string[]]$Arguments,

    [Parameter(Mandatory)]
    [string]$Boundary
  )

  $output = @(& $GcloudSource @Arguments 2>$null)
  $exitCode = $LASTEXITCODE
  $values = @(
    $output |
      ForEach-Object { ([string]$_).Trim() } |
      Where-Object { $_ }
  )
  if ($exitCode -ne 0 -or $values.Count -ne 1) {
    throw "The exact Google Cloud $Boundary boundary is unavailable."
  }
  return [string]$values[0]
}

$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
$gcloudSource = if ($null -ne $gcloud -and
    -not [string]::IsNullOrWhiteSpace([string]$gcloud.Source)) {
  [string]$gcloud.Source
} else {
  $fallbackGcloudPaths = @(
    if (-not [string]::IsNullOrWhiteSpace(${env:ProgramFiles(x86)})) {
      Join-Path `
        ${env:ProgramFiles(x86)} `
        'Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
      Join-Path `
        $env:ProgramFiles `
        'Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd'
    }
  )
  @(
    $fallbackGcloudPaths |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
  ) | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace([string]$gcloudSource)) {
  throw 'Google Cloud CLI is required for YouTube public Dev review.'
}
$gcloudSource = [string]$gcloudSource

$configuration = Invoke-GcloudSingleValue `
  -GcloudSource $gcloudSource `
  -Arguments @(
    'config',
    'configurations',
    'list',
    '--filter=is_active:true',
    '--format=value(name)',
    '--quiet'
  ) `
  -Boundary 'configuration'
if ($configuration -cne $ExpectedConfiguration) {
  throw 'The exact isolated Google Cloud configuration is not active.'
}

$account = Invoke-GcloudSingleValue `
  -GcloudSource $gcloudSource `
  -Arguments @('config', 'get-value', 'account', '--quiet') `
  -Boundary 'configured account'
if ($account -cne $ExpectedAccount) {
  throw 'The exact authorized Google Cloud account is not configured.'
}

$project = Invoke-GcloudSingleValue `
  -GcloudSource $gcloudSource `
  -Arguments @('config', 'get-value', 'project', '--quiet') `
  -Boundary 'configured project'
if ($project -cne $ExpectedProject) {
  throw 'The exact MoolSocial Dev Google Cloud project is not configured.'
}

$activeCredential = Invoke-GcloudSingleValue `
  -GcloudSource $gcloudSource `
  -Arguments @(
    'auth',
    'list',
    "--filter=account:$ExpectedAccount AND status:ACTIVE",
    '--format=value(account)',
    '--quiet'
  ) `
  -Boundary 'active credential'
if ($activeCredential -cne $ExpectedAccount) {
  throw 'The exact authorized Google Cloud credential is not active.'
}

[pscustomobject]@{
  gcloudSource = $gcloudSource
  configuration = $configuration
  account = $account
  project = $project
  activeCredential = $activeCredential
  accessTokenRequested = $false
  secretValueAccessed = $false
}
