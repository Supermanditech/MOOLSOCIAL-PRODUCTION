[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$GoogleServicesPath,

  [Parameter(Mandatory)]
  [string]$GoogleServerClientId,

  [Parameter(Mandatory)]
  [string]$KeystorePath,

  [Parameter(Mandatory)]
  [string]$KeyAlias,

  [string]$PackageName = 'com.moolsocial.app',

  [string]$StorePasswordEnvironmentName =
    'MOOLSOCIAL_UPLOAD_STORE_PASSWORD',

  [string]$KeytoolPath =
    'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-GoogleAndroidOAuthSigning([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Google Android OAuth signing readiness rejected: $Message"
  }
}

function Normalize-Sha1([string]$Value) {
  return $Value.Replace(':', '').Trim().ToUpperInvariant()
}

function Get-CertificateReadFailureClassification([string]$Value) {
  if ($Value -match
      '(?i)(password was incorrect|keystore was tampered with|password is incorrect|keystore password was incorrect|failed to decrypt safe contents)') {
    return 'password/input unavailable'
  }
  if ($Value -match
      '(?i)(access is denied|permission denied|being used by another process)') {
    return 'file inaccessible'
  }
  if ($Value -match
      '(?i)(alias\s+<[^>]+>\s+does not exist|alias\s+.+\s+not found)') {
    return 'incorrect environment variable'
  }
  if ($Value -match
      '(?i)(cannot find the file|no such file|file not found)') {
    return 'incorrect path'
  }
  if ($Value -match
      '(?i)(unrecognized keystore format|invalid keystore format|unsupported keystore type|keystore type .+ not found|no such algorithm)') {
    return 'certificate parsing/tool defect'
  }
  return 'other proven cause'
}

$resolvedGoogleServices = [IO.Path]::GetFullPath($GoogleServicesPath)
$resolvedKeystore = [IO.Path]::GetFullPath($KeystorePath)
$resolvedKeytool = [IO.Path]::GetFullPath($KeytoolPath)

Assert-GoogleAndroidOAuthSigning `
  (Test-Path -LiteralPath $resolvedGoogleServices -PathType Leaf) `
  'the Android Firebase configuration file is unavailable.'
Assert-GoogleAndroidOAuthSigning `
  (Test-Path -LiteralPath $resolvedKeystore -PathType Leaf) `
  'the selected Android signing keystore is unavailable.'
Assert-GoogleAndroidOAuthSigning `
  (Test-Path -LiteralPath $resolvedKeytool -PathType Leaf) `
  'the qualified Android Studio keytool is unavailable.'
Assert-GoogleAndroidOAuthSigning `
  ($PackageName -cmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') `
  'the package name is malformed.'
Assert-GoogleAndroidOAuthSigning `
  (-not [string]::IsNullOrWhiteSpace($KeyAlias)) `
  'the signing key alias is missing.'
Assert-GoogleAndroidOAuthSigning `
  (-not [string]::IsNullOrWhiteSpace($GoogleServerClientId)) `
  'the runtime Google server client input is missing.'

$configuration = Get-Content -LiteralPath $resolvedGoogleServices -Raw |
  ConvertFrom-Json
$packageClients = @($configuration.client | Where-Object {
  [string]$_.client_info.android_client_info.package_name -ceq $PackageName
})
Assert-GoogleAndroidOAuthSigning `
  ($packageClients.Count -eq 1) `
  'the package must have exactly one Firebase Android client.'

$webOAuthClients = @(
  $packageClients[0].oauth_client |
    Where-Object {
      [int]$_.client_type -eq 3 -and
      -not [string]::IsNullOrWhiteSpace([string]$_.client_id)
    }
)
Assert-GoogleAndroidOAuthSigning `
  ($webOAuthClients.Count -eq 1) `
  'the package must expose exactly one Web OAuth client.'
$runtimeServerClientId = $GoogleServerClientId.Trim()
Assert-GoogleAndroidOAuthSigning `
  ([string]$webOAuthClients[0].client_id -ceq $runtimeServerClientId) `
  'the runtime Google server client does not match the Web OAuth client.'

$registeredSha1Values = @(
  $packageClients[0].oauth_client |
    Where-Object {
      [int]$_.client_type -eq 1 -and
      [string]$_.android_info.package_name -ceq $PackageName -and
      [string]$_.android_info.certificate_hash -cmatch `
        '^(?:[0-9A-Fa-f]{40}|(?:[0-9A-Fa-f]{2}:){19}[0-9A-Fa-f]{2})$'
    } |
    ForEach-Object {
      Normalize-Sha1 ([string]$_.android_info.certificate_hash)
    } |
    Sort-Object -Unique
)
Assert-GoogleAndroidOAuthSigning `
  ($registeredSha1Values.Count -gt 0) `
  'no valid Android OAuth signing certificate is registered for the package.'

$storePassword = [Environment]::GetEnvironmentVariable(
  $StorePasswordEnvironmentName,
  'Process'
)
Assert-GoogleAndroidOAuthSigning `
  (-not [string]::IsNullOrWhiteSpace($storePassword)) `
  'the signing-store password input is missing.'

$process = $null
try {
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $resolvedKeytool
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardInput = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  foreach ($argument in @(
    '-list',
    '-v',
    '-keystore',
    $resolvedKeystore,
    '-alias',
    $KeyAlias
  )) {
    [void]$startInfo.ArgumentList.Add($argument)
  }

  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  Assert-GoogleAndroidOAuthSigning `
    $process.Start() `
    'the signing-certificate reader did not start.'
  $standardOutput = $process.StandardOutput.ReadToEndAsync()
  $standardError = $process.StandardError.ReadToEndAsync()
  $process.StandardInput.WriteLine($storePassword)
  $process.StandardInput.Close()
  $process.WaitForExit()
  $certificateText = $standardOutput.GetAwaiter().GetResult() +
    [Environment]::NewLine +
    $standardError.GetAwaiter().GetResult()
  if ($process.ExitCode -ne 0) {
    $failureClassification =
      Get-CertificateReadFailureClassification $certificateText
    throw (
      'Google Android OAuth signing readiness rejected: ' +
      'the selected signing certificate could not be read; ' +
      "cause=$failureClassification."
    )
  }

  $sha1Match = [regex]::Match(
    $certificateText,
    'SHA1:\s*((?:[0-9A-Fa-f]{2}:){19}[0-9A-Fa-f]{2})'
  )
  Assert-GoogleAndroidOAuthSigning `
    $sha1Match.Success `
    'the selected signing certificate has no readable SHA-1 identity.'
  $signerSha1 = Normalize-Sha1 $sha1Match.Groups[1].Value
  Assert-GoogleAndroidOAuthSigning `
    ($registeredSha1Values -ccontains $signerSha1) `
    'the selected signer is not registered for the package Android OAuth client.'
} finally {
  $storePassword = $null
  $runtimeServerClientId = $null
  if ($null -ne $process) {
    $process.Dispose()
  }
}

Write-Output (
  'Google Android OAuth signing readiness passed: ' +
  "package=$PackageName; registeredCertificates=$($registeredSha1Values.Count); " +
  'webOAuthClients=1; serverClientMatched=true; signerMatched=true; ' +
  'secretValuesEmitted=false.'
)
