[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gate = Join-Path $PSScriptRoot `
  'check-google-android-oauth-signing-readiness.ps1'
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $temporaryRoot (
  'moolsocial-google-oauth-signing-' + [guid]::NewGuid().ToString('N')
)
$keystore = Join-Path $fixtureRoot 'fixture.jks'
$configuration = Join-Path $fixtureRoot 'google-services.json'
$fixturePasswordEnvironmentName = 'MOOLSOCIAL_FIXTURE_STORE_PASSWORD'
$fixturePassword = 'fixture-password-only'

function Assert-Fixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
}

function Write-FixtureConfiguration([string]$CertificateHash) {
  $body = [ordered]@{
    project_info = [ordered]@{ project_number = '1'; project_id = 'fixture' }
    client = @(
      [ordered]@{
        client_info = [ordered]@{
          mobilesdk_app_id = 'fixture-app-id'
          android_client_info = [ordered]@{
            package_name = 'com.moolsocial.app'
          }
        }
        oauth_client = @(
          [ordered]@{
            client_id = 'fixture-android-client'
            client_type = 1
            android_info = [ordered]@{
              package_name = 'com.moolsocial.app'
              certificate_hash = $CertificateHash
            }
          },
          [ordered]@{
            client_id = 'fixture-web-client'
            client_type = 3
          }
        )
        api_key = @([ordered]@{ current_key = 'fixture-api-key' })
      }
    )
  }
  $body | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $configuration -Encoding utf8
}

function Invoke-Rejection(
  [string]$ExpectedMessage,
  [string]$GoogleServerClientId = 'fixture-web-client'
) {
  try {
    & $gate `
      -GoogleServicesPath $configuration `
      -GoogleServerClientId $GoogleServerClientId `
      -KeystorePath $keystore `
      -KeyAlias 'fixture' `
      -StorePasswordEnvironmentName $fixturePasswordEnvironmentName `
      -KeytoolPath $keytool | Out-Null
    throw 'Expected Google Android OAuth signing rejection was not raised.'
  } catch {
    Assert-Fixture `
      ($_.Exception.Message -ceq $ExpectedMessage) `
      "Unexpected rejection: $($_.Exception.Message)"
  }
}

try {
  Assert-Fixture (Test-Path -LiteralPath $gate -PathType Leaf) `
    'Google Android OAuth signing gate is missing.'
  Assert-Fixture (Test-Path -LiteralPath $keytool -PathType Leaf) `
    'Qualified Android Studio keytool is missing.'
  [void](New-Item -ItemType Directory -Path $fixtureRoot)
  & $keytool `
    -genkeypair `
    -noprompt `
    -alias fixture `
    -keystore $keystore `
    -storepass $fixturePassword `
    -keypass $fixturePassword `
    -dname 'CN=MoolSocial Fixture' `
    -validity 2 `
    -keyalg RSA 2>&1 | Out-Null
  Assert-Fixture ($LASTEXITCODE -eq 0) 'Fixture keystore creation failed.'

  $certificateOutput = & $keytool `
    -list `
    -v `
    -keystore $keystore `
    -alias fixture `
    -storepass $fixturePassword 2>&1
  Assert-Fixture ($LASTEXITCODE -eq 0) 'Fixture certificate read failed.'
  $sha1Match = [regex]::Match(
    ($certificateOutput -join [Environment]::NewLine),
    'SHA1:\s*((?:[0-9A-Fa-f]{2}:){19}[0-9A-Fa-f]{2})'
  )
  Assert-Fixture $sha1Match.Success 'Fixture SHA-1 identity is missing.'
  $fixtureSha1 = $sha1Match.Groups[1].Value.Replace(':', '').ToUpperInvariant()

  [Environment]::SetEnvironmentVariable(
    $fixturePasswordEnvironmentName,
    $fixturePassword,
    'Process'
  )
  Write-FixtureConfiguration $fixtureSha1
  $positive = & $gate `
    -GoogleServicesPath $configuration `
    -GoogleServerClientId 'fixture-web-client' `
    -KeystorePath $keystore `
    -KeyAlias 'fixture' `
    -StorePasswordEnvironmentName $fixturePasswordEnvironmentName `
    -KeytoolPath $keytool
  Assert-Fixture ($LASTEXITCODE -eq 0) 'Positive signer fixture failed.'
  Assert-Fixture `
    (($positive -join [Environment]::NewLine) -match 'signerMatched=true') `
    'Positive signer fixture emitted no safe pass marker.'
  Assert-Fixture `
    (($positive -join [Environment]::NewLine) -match 'serverClientMatched=true') `
    'Positive server-client fixture emitted no safe pass marker.'

  Invoke-Rejection `
    (
      'Google Android OAuth signing readiness rejected: ' +
      'the runtime Google server client does not match the Web OAuth client.'
    ) `
    'fixture-mismatched-web-client'

  Invoke-Rejection `
    (
      'Google Android OAuth signing readiness rejected: ' +
      'the runtime Google server client input is missing.'
    ) `
    '   '

  Write-FixtureConfiguration ('0' * 40)
  Invoke-Rejection (
    'Google Android OAuth signing readiness rejected: ' +
    'the selected signer is not registered for the package Android OAuth client.'
  )

  $withoutAndroidClient = Get-Content -LiteralPath $configuration -Raw |
    ConvertFrom-Json
  $withoutAndroidClient.client[0].oauth_client = @(
    $withoutAndroidClient.client[0].oauth_client |
      Where-Object { [int]$_.client_type -ne 1 }
  )
  $withoutAndroidClient | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $configuration -Encoding utf8
  Invoke-Rejection (
    'Google Android OAuth signing readiness rejected: ' +
    'no valid Android OAuth signing certificate is registered for the package.'
  )
} finally {
  [Environment]::SetEnvironmentVariable(
    $fixturePasswordEnvironmentName,
    $null,
    'Process'
  )
  $fixturePassword = $null
  $resolvedFixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
  Assert-Fixture `
    ($resolvedFixtureRoot.StartsWith(
      $temporaryRoot,
      [StringComparison]::OrdinalIgnoreCase
    )) `
    'Fixture cleanup target escaped the system temporary directory.'
  if (Test-Path -LiteralPath $resolvedFixtureRoot) {
    Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
  }
}

Write-Output (
  'Google Android OAuth signing readiness fixtures passed: ' +
  'matching signer and server client accepted; mismatched or missing server client ' +
  'and mismatched or missing Android OAuth signer rejected; ' +
  'secret values emitted=false.'
)
