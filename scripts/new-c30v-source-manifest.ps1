[CmdletBinding()]
param(
  [string]$OutputPath,
  [string]$ComparePath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if ([string]::IsNullOrWhiteSpace($OutputPath) -eq [string]::IsNullOrWhiteSpace($ComparePath)) {
  throw 'C30V source manifest requires exactly one of -OutputPath or -ComparePath.'
}

function Get-C30VRelativeFiles {
  param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][string[]]$Extensions)
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
  @(
    Get-ChildItem -LiteralPath $Directory -Recurse -File | Where-Object {
      $name = $_.Name
      $_.FullName -notmatch '[\\/](build|\.gradle|\.dart_tool|node_modules|\.idea)[\\/]' -and
      @($Extensions | Where-Object { $name.EndsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    } | ForEach-Object {
      $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    }
  )
}

function Resolve-C30VOutput {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'C30V source manifest path escaped the repository.'
  }
  return $resolved
}

function Get-C30VProtectedRelativeFiles {
  $files = @()
  foreach ($relativeRoot in @(
    'apps/mobile/lib/ui_v2/social',
    'apps/mobile/lib/core/youtube',
    'apps/mobile/packages/youtube_embedded_player_private_dev',
    'backend/functions/src'
  )) {
    $absoluteRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
      throw "C30V protected source root is missing: $relativeRoot"
    }
    $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | Where-Object {
      $_.FullName -notmatch '[\\/]\.dart_tool[\\/]' -and
      $_.FullName -notmatch '[\\/]build[\\/]' -and
      $_.Name -notmatch '\.test\.(ts|js)$'
    }
  }

  foreach ($relative in @(
    'apps/mobile/lib/core/navigation/youtube_connect_return_route.dart',
    'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/YouTubeConnectReturnActivity.kt',
    'apps/mobile/assets/prototype/social-market-grocery.png',
    'backend/functions/package.json',
    'backend/functions/package-lock.json',
    'backend/functions/tsconfig.json'
  )) {
    $absolute = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
      throw "C30V protected source owner is missing: $relative"
    }
    $files += Get-Item -LiteralPath $absolute
  }

  foreach ($relativeRoot in @(
    'apps/mobile/test',
    'apps/mobile/integration_test',
    'apps/mobile/test_driver'
  )) {
    $absoluteRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
      throw "C30V protected test root is missing: $relativeRoot"
    }
    $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | Where-Object {
      $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
      $relative -match '(?i)(social|youtube|screen04)' -and
      $_.FullName -notmatch '[\\/]candidate_captures[\\/]' -and
      $_.FullName -notmatch '[\\/]failures[\\/]'
    }
  }

  return @(
    $files |
      ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
      Sort-Object -Unique
  )
}

$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
if (
  $branch -cne 'remediation/prototype-conformance-2026-07-20' -or
  $head -cne 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) { throw 'C30V source manifest branch or HEAD changed.' }

$paths = @()
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/lib') -Extensions @('.dart')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/test') -Extensions @('.dart')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/test/goldens') -Extensions @('.png')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/integration_test') -Extensions @('.dart')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/android') -Extensions @('.kt', '.kts', '.java', '.xml', '.properties', '.gradle')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/mobile/packages/youtube_embedded_player_private_dev') -Extensions @('.dart', '.kt', '.kts', '.java', '.xml', '.yaml')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'backend/functions/src') -Extensions @('.ts')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'apps/web/public') -Extensions @('.html', '.css', '.js', '.json', '.xml', '.txt', '.png', '.svg', '.ico')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'scripts') -Extensions @('.ps1', '.mjs', '.js', '.ts')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'deployment/youtube-private-dev') -Extensions @('.json', '.md', '.ps1', '.mjs')
$paths += Get-C30VRelativeFiles -Directory (Join-Path $root 'deployment/youtube-official-api-capability-registry') -Extensions @('.json', '.md', '.mjs')

$paths += @(
  'apps/mobile/pubspec.yaml',
  'apps/mobile/pubspec.lock',
  'backend/functions/package.json',
  'backend/functions/package-lock.json',
  'backend/functions/tsconfig.json',
  'backend/functions/env/moolsocial-dev-503018.env',
  'apps/web/tests/firebase-public-site.test.mjs',
  'firebase.json',
  'approved-references/manifest.json',
  'config/mvp-scope-policy.json',
  'config/mvp-scope-gate-state.json',
  'config/mvp-robust-60-75-day-delivery-lock.json',
  'config/mvp-exact-user-type-scope-matrix.json',
  'config/codex-development-regression-registry.json',
  'config/uaw-c34i-r60-73-authentication-privacy-safe-play-oppo-acceptance-ticket.json',
  'config/release-device-acceptance-actor-policy-c34i.json',
  'config/uaw-c33l-r60-50-authentication-no-regression-play-oppo-acceptance-ticket.json',
  'config/uaw-c33l-fix1-private-dev-public-review-screen04-safe-boot-regression-ticket.json',
  'config/uaw-c33l-fix2-fix1-gate-parent-replay-compatibility-ticket.json',
  'config/uaw-c33l-fix3-authoritative-flutter-null-event-classification-ticket.json',
  'config/uaw-c33l-fix4-generic-aab-postbuild-aggregate-mirror-atomicity-ticket.json',
  'config/uaw-c33l-fix5-founder-aab-launcher-postcleanup-result-retention-ticket.json',
  'config/uaw-c33l-fix6-fix4-gate-successor-replay-compatibility-ticket.json',
  'config/uaw-c33m-r60-51-authentication-no-regression-play-oppo-acceptance-ticket.json',
    'config/uaw-c33m-fix1-c33l-fix5-gate-successor-replay-compatibility-ticket.json',
    'config/uaw-c33m-fix2-c33l-fix1-gate-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33m-fix3-c33l-fix3-gate-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence-ticket.json',
    'config/uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway-ticket.json',
    'config/uaw-c33m-fix6-c33j-gate-trilogy-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33m-fix7-c33k-gate-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33m-fix8-fix4-gate-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33n-r60-52-authentication-no-regression-play-oppo-acceptance-ticket.json',
    'config/uaw-c33n-fix1-c33m-fix5-gate-generic-successor-replay-compatibility-ticket.json',
    'config/uaw-c33o-r60-53-authentication-no-regression-play-oppo-acceptance-ticket.json',
  'config/firebase-phone-auth-live-readiness-state-c33h.json',
  'config/screen03-passwordless-email-link-native-parity-state-c33j.json',
  'config/firebase-passwordless-email-link-live-readiness-state-c33k.json',
  'config/google-auth-live-provider-readiness-state-c33e-fix2.json',
  'config/uaw-c30t-r60-45-mobile-otp-gate-nonfunctional-ticket.json',
  'config/uaw-c30t-r60-45-email-otp-gate-nonfunctional-ticket.json',
  'config/play-internal-aab-regression-gate-state-c30t.json',
  'config/play-internal-live-read-recovery-gate-state-c30t.json',
  'config/uaw-c34j-r60-74-release-lifecycle-atomic-parity-play-oppo-acceptance-ticket.json',
  'config/uaw-c34k-r60-75-release-lifecycle-atomic-parity-play-oppo-acceptance-ticket.json',
  'config/uaw-c34l-r60-76-consolidated-release-transaction-evidence-play-oppo-acceptance-ticket.json',
  'docs/quality/RELEASE-GATES.md',
  'docs/quality/UAW-C34I-PRETICKET-ROBUSTNESS-REUSE-ASSESSMENT-20260817.md',
  'docs/quality/UAW-C34I-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md',
  'docs/quality/UAW-C34I-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260817.md',
  'docs/quality/UAW-C34I-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260817.md',
  'docs/quality/UAW-C34J-PRETICKET-ROBUSTNESS-REUSE-ASSESSMENT-20260817.md',
  'docs/quality/UAW-C34J-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md',
  'docs/quality/UAW-C34J-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260817.md',
  'docs/quality/UAW-C34J-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260817.md',
  'docs/quality/UAW-C34K-PRETICKET-ROBUSTNESS-REUSE-ASSESSMENT-20260817.md',
  'docs/quality/UAW-C34K-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md',
  'docs/quality/UAW-C34K-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260817.md',
  'docs/quality/UAW-C34K-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260817.md',
  'docs/quality/UAW-C34L-PRETICKET-ROBUSTNESS-REUSE-ASSESSMENT-20260817.md',
  'docs/quality/UAW-C34L-END-TO-END-FOUNDER-AUTHORIZATION-20260817.md',
  'docs/quality/UAW-C34L-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260817.md',
  'docs/quality/UAW-C34L-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260817.md',
  'docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md',
  'docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md',
  'docs/quality/UAW-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-PRESELECTION-20260815.md',
  'docs/quality/UAW-C33L-FIX1-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-QUALIFICATION-20260816.md',
  'docs/quality/UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
  'docs/quality/UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION-QUALIFICATION-20260816.md',
  'docs/quality/UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY-QUALIFICATION-20260816.md',
  'docs/quality/UAW-C33L-FIX5-FOUNDER-AAB-LAUNCHER-POSTCLEANUP-RESULT-RETENTION-QUALIFICATION-20260816.md',
  'docs/quality/UAW-C33L-FIX6-FIX4-GATE-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX1-C33L-FIX5-GATE-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX2-C33L-FIX1-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX3-C33L-FIX3-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md',
    'docs/quality/UAW-C33N-R60-52-POSTBUILD-REGISTRY-CHANGE-REJECTION-20260816.md',
    'docs/quality/REG-20260816-2611-C33N-POSTBUILD-EVIDENCE-LOOKUP-GUESSED-NONEXISTENT-RELEASE-DIRECTORY.md',
    'docs/quality/REG-20260816-2612-C33N-REJECTION-COMPOUND-PATCH-HANDOFF-CONTEXT-MISMATCH.md',
    'docs/quality/REG-20260816-2613-C33O-PRESEAL-DELIVERY-GATE-PATH-GUESS.md',
    'docs/quality/REG-20260816-2614-C33O-UPLOAD-RUNBOOK-MARKER-WRAPPED-LINE-MISMATCH.md',
    'docs/quality/REG-20260816-2615-C33O-MECHANICAL-COPY-INHERITED-FIX1-PATH-SUBSTITUTION.md',
    'docs/quality/REG-20260816-2616-C33O-PLAY-DEVELOPER-SELECTOR-GENERIC-BUTTON-LOGIN-REDIRECT.md',
    'docs/quality/REG-20260816-2617-C33O-PLAY-INTERNAL-TESTING-TEXT-SPAN-CLICK-TIMEOUT.md',
    'docs/quality/REG-20260816-2618-C33O-PLAY-INTERNAL-TESTING-PARENT-ANCHOR-CLICK-TIMEOUT.md',
    'docs/quality/REG-20260816-2619-C33O-CHROME-DOM-RECTANGLE-COORDINATE-OFFSET-OPENED-TESTING-SECTION.md',
    'docs/quality/REG-20260816-2620-C33O-PLAY-INTERNAL-TESTING-ANCHOR-KEYBOARD-ACTIVATION-TIMEOUT.md',
    'docs/quality/UAW-C33O-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260816.md',
    'docs/quality/UAW-C33O-END-TO-END-FOUNDER-AUTHORIZATION-20260816.md',
    'docs/quality/UAW-C33O-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260816.md',
  'artifacts/quality/uaw-c33l-r60-50-authentication-no-regression-preparation-20260815-01/07-postbuild-lifecycle-recovery-incident.md',
  'artifacts/quality/uaw-c33l-r60-50-authentication-no-regression-preparation-20260815-01/c33l-fix1-focused-qualification.json',
  'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1',
  'tmp/run-c30v-single-aab-founder.ps1',
  'tmp/run-c33l-r60-50-single-aab-founder.ps1',
  'tmp/run-c33m-r60-51-single-aab-founder.ps1',
  'tmp/run-c33n-r60-52-single-aab-founder.ps1',
  'tmp/run-c33o-r60-53-single-aab-founder.ps1',
  'tmp/run-c34i-r60-73-single-aab-founder.ps1',
  'tmp/prepare-c34i-candidate-state.ps1',
  'tmp/prepare-c34i-mechanical-release-owners.ps1',
  'tmp/run-c34j-r60-74-single-aab-founder.ps1',
  'tmp/prepare-c34j-candidate-state.ps1',
  'tmp/prepare-c34j-mechanical-release-owners.ps1',
  'tmp/run-c34k-r60-75-single-aab-founder.ps1',
  'tmp/prepare-c34k-candidate-state.ps1',
  'tmp/prepare-c34k-mechanical-release-owners.ps1',
  'tmp/prepare-c34l-consolidated-ticket.ps1',
  'tmp/bundletool-all-1.18.3.jar'
)
$paths += @(
  Get-ChildItem -LiteralPath (Join-Path $root 'config') -File -Filter 'uaw-c30t-*-ticket.json' |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }
)
$protectedBaselinePath = Join-Path $root 'artifacts/quality/social-protected-candidate-c30u-post-r60-45-social-repairs-20260814-01/BASELINE.json'
if (-not (Test-Path -LiteralPath $protectedBaselinePath -PathType Leaf)) {
  throw 'C30V protected Social successor baseline is missing.'
}
$protectedBaseline = Get-Content -Raw -LiteralPath $protectedBaselinePath | ConvertFrom-Json
$protectedRelativePaths = @(Get-C30VProtectedRelativeFiles)
$expectedProtectedCount = [int]$protectedBaseline.protectedRuntime.fileCount
$qualifiedSuccessorProtectedPaths = @(
  'apps/mobile/test/uaw_c33e_fix3_social_auth_rollback_independent_cleanup_test.dart',
  'apps/mobile/test/uaw_c33e_fix4_protected_social_action_intent_return_continuity_test.dart',
  'apps/mobile/test/uaw_c33g_fix2_social_identity_provider_truth_test.dart',
  'backend/functions/src/chat/attachment_store.ts'
)
$historicalManifestPath = Join-Path $root `
  'artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/source-manifest-c30y-post-fix5.txt'
if (
  -not (Test-Path -LiteralPath $historicalManifestPath -PathType Leaf) -or
  (Get-FileHash -Algorithm SHA256 -LiteralPath $historicalManifestPath).Hash -cne
    '54645062FBAA0233759B0F3C6F5C1C4C539D1A322DE7E7FA14629ECF3EDCDED4'
) {
  throw 'C30V historical C30Y source-manifest identity changed.'
}
$historicalManifestPaths = @(
  Get-Content -LiteralPath $historicalManifestPath | ForEach-Object {
    ($_ -split '  ', 2)[1]
  }
)
$missingQualifiedSuccessors = @(
  $qualifiedSuccessorProtectedPaths | Where-Object {
    $_ -cnotin $protectedRelativePaths
  }
)
$unexpectedProtectedSuccessors = @(
  $protectedRelativePaths | Where-Object {
    $_ -cnotin $historicalManifestPaths -and
    $_ -cnotin $qualifiedSuccessorProtectedPaths
  }
)
$historicalProtectedOwnersStillPresent = @(
  $protectedRelativePaths | Where-Object { $_ -cin $historicalManifestPaths }
)
$currentExpectedProtectedCount =
  $expectedProtectedCount + $qualifiedSuccessorProtectedPaths.Count
if (
  $expectedProtectedCount -ne 206 -or
  $protectedRelativePaths.Count -ne $currentExpectedProtectedCount -or
  $historicalProtectedOwnersStillPresent.Count -ne $expectedProtectedCount -or
  $missingQualifiedSuccessors.Count -ne 0 -or
  $unexpectedProtectedSuccessors.Count -ne 0
) {
  throw (
    'C30V protected source owner inventory is not exact: ' +
    "baseline=$expectedProtectedCount; expectedCurrent=$currentExpectedProtectedCount; " +
    "actual=$($protectedRelativePaths.Count); retainedHistorical=$($historicalProtectedOwnersStillPresent.Count); " +
    "missingQualifiedSuccessors=$($missingQualifiedSuccessors.Count); " +
    "unexpectedSuccessors=$($unexpectedProtectedSuccessors.Count)"
  )
}
$paths += $protectedRelativePaths

$relativePaths = @($paths | Sort-Object -Unique)
$missingProtectedPaths = @($protectedRelativePaths | Where-Object { $_ -cnotin $relativePaths })
if ($missingProtectedPaths.Count -ne 0) {
  throw "C30V source manifest omitted $($missingProtectedPaths.Count) protected source owner(s)."
}
foreach ($relativePath in $relativePaths) {
  $absolute = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    throw "C30V source manifest owner missing: $relativePath"
  }
}
$rows = @($relativePaths | ForEach-Object {
  '{0}  {1}' -f (Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash, $_
})
$text = ($rows -join [Environment]::NewLine) + [Environment]::NewLine
$bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
$hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
  $path = Resolve-C30VOutput -Path $OutputPath
  if (Test-Path -LiteralPath $path) { throw "C30V source manifest is immutable and already exists: $path" }
  $directory = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $directory)
  }
  [IO.File]::WriteAllBytes($path, $bytes)
  Write-Output "C30V source manifest sealed: $OutputPath"
} else {
  $path = Resolve-C30VOutput -Path $ComparePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'C30V comparison source manifest is missing.' }
  $existing = [IO.File]::ReadAllBytes($path)
  $existingHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($existing))
  if ($existing.Length -ne $bytes.Length -or $existingHash -cne $hash) {
    throw 'C30V source changed between qualification cycles.'
  }
  Write-Output "C30V source manifest unchanged: $ComparePath"
}

Write-Output "sourceFiles=$($relativePaths.Count); sourceFingerprintSha256=$hash; protectedSourceOwners=$($protectedRelativePaths.Count); retainedHistoricalProtectedOwners=$($historicalProtectedOwnersStillPresent.Count); qualifiedSuccessorProtectedOwners=$($qualifiedSuccessorProtectedPaths.Count); missingProtectedSourceOwners=$($missingProtectedPaths.Count); unexpectedProtectedSuccessors=$($unexpectedProtectedSuccessors.Count)"
