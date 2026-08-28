[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-CursorUiReviewControl {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "Cursor UI Review build-profile test rejected: $Message"
  }
}

function Test-CursorUiReviewWrapperSource {
  param([Parameter(Mandatory)][string]$Source)

  return (
    $Source.Contains("'CursorUiReview'") -and
    $Source.Contains("MOOLSOCIAL_UI_REVIEW_ONLY = 'true'") -and
    $Source.Contains("MOOLSOCIAL_DEVICE_REVIEW = 'true'") -and
    $Source.Contains("MOOLSOCIAL_USE_EMULATORS = 'true'") -and
    $Source.Contains('MOOLSOCIAL_CANDIDATE_ID = $CandidateId') -and
    $Source.Contains("'cursorreview'") -and
    $Source.Contains('Cursor UI Review permits debug APK builds only.') -and
    $Source.Contains('AndroidDebugPackage=cursorreview;Promotable=false') -and
    $Source.Contains('$isolatedDebugReview = (') -and
    $Source.Contains('if (-not $isolatedDebugReview -and (') -and
    $Source.Contains("if (`$BuildMode -ceq 'release') {") -and
    $Source.Contains("'com.moolsocial.app.cursorreview'") -and
    $Source.Contains('AllowDebugTestPlugin = $true') -and
    $Source.Contains('-CandidateId $CandidateId')
  )
}

$builderPath = Join-Path $RepositoryRoot 'scripts/build-buy-device-review.ps1'
$foundationPath = Join-Path `
  $RepositoryRoot `
  'scripts/test-public-auth-sideload-build-controls.ps1'
$apkGatePath = Join-Path `
  $RepositoryRoot `
  'scripts/check-apk-regression-gate-state.ps1'
$pluginGatePath = Join-Path `
  $RepositoryRoot `
  'scripts/check-apk-production-plugin-integrity.ps1'
$gradlePath = Join-Path `
  $RepositoryRoot `
  'apps/mobile/android/app/build.gradle.kts'

$builder = Get-Content -Raw -LiteralPath $builderPath
$foundation = Get-Content -Raw -LiteralPath $foundationPath
$apkGate = Get-Content -Raw -LiteralPath $apkGatePath
$pluginGate = Get-Content -Raw -LiteralPath $pluginGatePath
$gradle = Get-Content -Raw -LiteralPath $gradlePath

Assert-CursorUiReviewControl `
  (Test-CursorUiReviewWrapperSource -Source $builder) `
  'positive wrapper contract is incomplete.'

$missingUiReview = $builder.Replace(
  "MOOLSOCIAL_UI_REVIEW_ONLY = 'true'",
  "MOOLSOCIAL_UI_REVIEW_ONLY = 'false'"
)
Assert-CursorUiReviewControl `
  (-not (Test-CursorUiReviewWrapperSource -Source $missingUiReview)) `
  'negative missing-UI-review fixture was accepted.'

$wrongPackage = $builder.Replace(
  "'cursorreview'",
  "'runtime'"
)
Assert-CursorUiReviewControl `
  (-not (Test-CursorUiReviewWrapperSource -Source $wrongPackage)) `
  'negative runtime-package fixture was accepted.'

$missingDebugRestriction = $builder.Replace(
  'Cursor UI Review permits debug APK builds only.',
  'Cursor UI Review permits all build modes.'
)
Assert-CursorUiReviewControl `
  (-not (Test-CursorUiReviewWrapperSource -Source $missingDebugRestriction)) `
  'negative non-debug fixture was accepted.'

Assert-CursorUiReviewControl (
  $foundation.Contains(
    "if (`$CandidateId -ceq 'UAW-R60.92-SOCIAL-RUNTIME-CONSOLIDATED-APK')"
  ) -and
  $foundation.Contains(
    'generic candidate APK state is not bound to the exact candidate.'
  ) -and
  $foundation.Contains(
    "[string]`$preApkState.contractId -ceq 'APK-BUILD-REGRESSION-GATES-001'"
  )
) 'generic candidate state still routes through the r60.92-only gate.'

Assert-CursorUiReviewControl (
  $gradle.Contains('setOf("runtime", "cursorreview")') -and
  $gradle.Contains('debugApplicationIdSuffix = ".$androidDebugPackage"') -and
  $gradle.Contains('"MoolSocial Cursor Review"') -and
  $gradle.Contains('if (androidDebugPackage == "cursorreview")') -and
  $gradle.Contains('compileDebugJavaWithJavac') -and
  $gradle.Contains('sanitizeProductionGeneratedPluginRegistrant')
) 'Android cursorreview package isolation is incomplete.'

Assert-CursorUiReviewControl (
  $apkGate.Contains("'uaw_cursor_ui_review_debug'") -and
  $apkGate.Contains("'package-isolation'") -and
  $apkGate.Contains("'MOOLSOCIAL_UI_REVIEW_ONLY'") -and
  $apkGate.Contains('if (-not $isolatedDebugReview)') -and
  $apkGate.Contains('$fullSocialRequested = if ($isolatedDebugReview)')
) 'generic APK gate does not recognize the Cursor UI Review profile.'

Assert-CursorUiReviewControl (
  $pluginGate.Contains("`$ExpectedApplicationId = 'com.moolsocial.app'") -and
  $pluginGate.Contains('[switch]$AllowDebugTestPlugin') -and
  $pluginGate.Contains('if (-not $AllowDebugTestPlugin)')
) 'plugin integrity gate does not preserve release defaults and debug isolation.'

Assert-CursorUiReviewControl (
  $builder.Contains("'com.moolsocial.app.runtime'") -and
  $builder.Contains("if (`$BuildMode -cne 'debug') {") -and
  $apkGate.Contains("'uaw_runtime_debug_review'") -and
  $apkGate.Contains('runtime device review permits debug APK builds only.') -and
  $apkGate.Contains('runtime debug review must remain non-promotable.')
) 'runtime debug review is not package-isolated, debug-only and non-promotable.'

$ellipsisOwnerSegments = @('apps/admin/app/admin/[[...section]]/page.tsx'.Split('/'))
$traversalOwnerSegments = @('apps/mobile/../secret.txt'.Split('/'))
Assert-CursorUiReviewControl (
  -not ($ellipsisOwnerSegments -ccontains '..') -and
  ($traversalOwnerSegments -ccontains '..') -and
  $apkGate.Contains("-not (`$ownerSegments -ccontains '..')")
) 'source-manifest path validation does not distinguish route ellipsis from traversal.'

Write-Output 'CURSOR_UI_REVIEW_BUILD_PROFILE_TESTS_PASSED'
