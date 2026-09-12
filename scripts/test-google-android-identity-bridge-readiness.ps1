[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$gate = Join-Path $root 'scripts/check-google-android-identity-bridge-readiness.ps1'
if (-not (Test-Path -LiteralPath $gate -PathType Leaf)) {
  throw 'Google bridge readiness test rejected: gate is missing.'
}

& $gate -RepositoryRoot $root | Out-Null

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) (
  'moolsocial-google-bridge-' + [guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $fixtureRoot)
try {
  $activityFixture = Join-Path $fixtureRoot 'MainActivity.kt'
  $buildFixture = Join-Path $fixtureRoot 'build.gradle.kts'
  $gatewayFixture = Join-Path $fixtureRoot 'review_journey_services.dart'
  $testFixture = Join-Path $fixtureRoot 'firebase_social_auth_gateway_test.dart'
  Copy-Item -LiteralPath (
    Join-Path $root `
      'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
  ) -Destination $activityFixture
  Copy-Item -LiteralPath (
    Join-Path $root 'apps/mobile/android/app/build.gradle.kts'
  ) -Destination $buildFixture
  Copy-Item -LiteralPath (
    Join-Path $root `
      'apps/mobile/lib/features/journey01/review_journey_services.dart'
  ) -Destination $gatewayFixture
  Copy-Item -LiteralPath (
    Join-Path $root 'apps/mobile/test/firebase_social_auth_gateway_test.dart'
  ) -Destination $testFixture

  $gatewaySource = Get-Content -LiteralPath $gatewayFixture -Raw
  $broken = $gatewaySource.Replace(
    'GoogleSignIn.instance.authenticate()',
    'GoogleSignIn.instance.removedAuthenticate()'
  )
  if ($broken -ceq $gatewaySource) {
    throw 'Google bridge readiness test rejected: negative fixture target is missing.'
  }
  [IO.File]::WriteAllText(
    $gatewayFixture,
    $broken,
    [Text.UTF8Encoding]::new($false)
  )
  $rejected = $false
  try {
    & $gate `
      -RepositoryRoot $root `
      -AndroidActivityPath $activityFixture `
      -AndroidBuildPath $buildFixture `
      -DartGatewayPath $gatewayFixture `
      -DartTestPath $testFixture | Out-Null
  } catch {
    $rejected = $_.Exception.Message -like (
      'Google Android identity bridge readiness rejected:*'
    )
  }
  if (-not $rejected) {
    throw 'Google bridge readiness test rejected: negative fixture passed.'
  }

  $broken = $gatewaySource.Replace(
    '_safeFirebaseAuthExceptionCode(error.code)',
    '_removedFirebaseAuthExceptionCode(error.code)'
  )
  if ($broken -ceq $gatewaySource) {
    throw 'Google bridge readiness test rejected: telemetry fixture target is missing.'
  }
  [IO.File]::WriteAllText(
    $gatewayFixture,
    $broken,
    [Text.UTF8Encoding]::new($false)
  )
  $rejected = $false
  try {
    & $gate `
      -RepositoryRoot $root `
      -AndroidActivityPath $activityFixture `
      -AndroidBuildPath $buildFixture `
      -DartGatewayPath $gatewayFixture `
      -DartTestPath $testFixture | Out-Null
  } catch {
    $rejected = $_.Exception.Message -like (
      'Google Android identity bridge readiness rejected:*'
    )
  }
  if (-not $rejected) {
    throw 'Google bridge readiness test rejected: telemetry-negative fixture passed.'
  }

  [IO.File]::WriteAllText(
    $gatewayFixture,
    $gatewaySource,
    [Text.UTF8Encoding]::new($false)
  )
  $activitySource = Get-Content -LiteralPath $activityFixture -Raw
  $broken = $activitySource.Replace(
    'if (requestCode == googleIdentityRequestCode)',
    'if (requestCode == removedGoogleIdentityRequestCode)'
  )
  if ($broken -ceq $activitySource) {
    throw 'Google bridge readiness test rejected: activity fallback fixture target is missing.'
  }
  [IO.File]::WriteAllText(
    $activityFixture,
    $broken,
    [Text.UTF8Encoding]::new($false)
  )
  $rejected = $false
  try {
    & $gate `
      -RepositoryRoot $root `
      -AndroidActivityPath $activityFixture `
      -AndroidBuildPath $buildFixture `
      -DartGatewayPath $gatewayFixture `
      -DartTestPath $testFixture | Out-Null
  } catch {
    $rejected = $_.Exception.Message -like (
      'Google Android identity bridge readiness rejected:*'
    )
  }
  if (-not $rejected) {
    throw 'Google bridge readiness test rejected: activity fallback-negative fixture passed.'
  }

  [IO.File]::WriteAllText(
    $activityFixture,
    $activitySource,
    [Text.UTF8Encoding]::new($false)
  )
  $buildSource = Get-Content -LiteralPath $buildFixture -Raw
  $broken = $buildSource.Replace(
    'implementation("com.google.android.gms:play-services-auth:21.6.0")',
    'implementation("removed-play-services-auth")'
  )
  if ($broken -ceq $buildSource) {
    throw 'Google bridge readiness test rejected: dependency fixture target is missing.'
  }
  [IO.File]::WriteAllText(
    $buildFixture,
    $broken,
    [Text.UTF8Encoding]::new($false)
  )
  $rejected = $false
  try {
    & $gate `
      -RepositoryRoot $root `
      -AndroidActivityPath $activityFixture `
      -AndroidBuildPath $buildFixture `
      -DartGatewayPath $gatewayFixture `
      -DartTestPath $testFixture | Out-Null
  } catch {
    $rejected = $_.Exception.Message -like (
      'Google Android identity bridge readiness rejected:*'
    )
  }
  if (-not $rejected) {
    throw 'Google bridge readiness test rejected: dependency-negative fixture passed.'
  }
} finally {
  if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
  }
}

Write-Output 'Google Android identity bridge readiness tests passed: live=1; negative=4.'
