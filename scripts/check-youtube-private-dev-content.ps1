Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scopes = @(
  "backend/functions",
  "backend/firestore",
  "firebase.json",
  "dataconnect/provider",
  "dataconnect/schema/provider_integrations.gql",
  "deployment/youtube-private-dev",
  "apps/mobile/lib/core/youtube",
  "apps/mobile/test/youtube_embedded_player_runtime_test.dart",
  "apps/mobile/test/youtube_private_dev_client_test.dart",
  "docs/decisions/ADR-0006-YOUTUBE-API-FIRST-SOCIAL-INTEGRATION.md",
  "docs/decisions/ADR-0008-YOUTUBE-PRIVATE-DEV-FIRESTORE-COST-FIRST-CONTROL-PLANE.md",
  "docs/delivery/YOUTUBE-API-CAPABILITY-AND-ENDPOINT-MATRIX-20260723.md",
  "docs/delivery/YOUTUBE-API-COMPLIANCE-QUOTA-VALUE-PROPOSAL-20260723.md",
  "docs/delivery/YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md",
  "docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md",
  "docs/delivery/YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md",
  "scripts/activate-youtube-private-dev-proof.ps1",
  "scripts/check-youtube-private-dev-content.ps1",
  "scripts/check-youtube-private-dev-exports.mjs",
  "scripts/check-youtube-private-dev-package.ps1",
  "scripts/check-youtube-private-dev-preflight.ps1",
  "scripts/check-youtube-private-dev-security-prerequisites.ps1",
  "scripts/contain-youtube-private-dev.ps1",
  "scripts/deploy-youtube-private-dev.ps1",
  "scripts/prepare-youtube-private-dev-runtime.ps1",
  "scripts/test-youtube-private-dev-deployment-controls.ps1",
  "scripts/youtube-private-dev-control-common.ps1",
  "scripts/verify-youtube-private-dev-deployment.ps1"
)
$textExtensions = @(
  ".dart",
  ".env",
  ".example",
  ".gql",
  ".json",
  ".md",
  ".mjs",
  ".ps1",
  ".rules",
  ".ts",
  ".yaml",
  ".yml"
)

$listed = & git -C $repoRoot ls-files `
  --cached `
  --others `
  --exclude-standard `
  -- @scopes 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "Unable to enumerate the private Dev package."
}

$files = @(
  $listed |
    ForEach-Object { "$_".Trim() } |
    Where-Object { $_ -ne "" } |
    Sort-Object -Unique
)
if ($files.Count -eq 0) {
  throw "The private Dev package inventory is empty."
}

$requiredPackageFiles = @(
  "apps/mobile/test/youtube_embedded_player_runtime_test.dart",
  "apps/mobile/test/youtube_private_dev_client_test.dart",
  "scripts/activate-youtube-private-dev-proof.ps1",
  "scripts/contain-youtube-private-dev.ps1",
  "scripts/test-youtube-private-dev-deployment-controls.ps1",
  "scripts/youtube-private-dev-control-common.ps1"
)
foreach ($requiredPackageFile in $requiredPackageFiles) {
  if ($files -notcontains $requiredPackageFile) {
    throw "Required private Dev package file is missing: $requiredPackageFile"
  }
}

$ignoredRuntimeFile = Join-Path $repoRoot `
  "backend/functions/.env.moolsocial-dev-503018"
if (Test-Path -LiteralPath $ignoredRuntimeFile -PathType Leaf) {
  throw (
    "The ignored Firebase runtime environment exists during package " +
    "verification. It must be materialized only inside a bounded deploy."
  )
}

$secretLiteralPatterns = [ordered]@{
  "Google API key" = ("AI" + "za[0-9A-Za-z_-]{35}")
  "Google OAuth client secret" = ("GOC" + "SPX-[0-9A-Za-z_-]{20,}")
  "OAuth refresh token" = ("1/" + "/[0-9A-Za-z_-]{20,}")
  "PEM private key" = ("-----BEGIN " + "PRIVATE KEY-----")
  "Bearer credential" = (
    "(?i)\bBearer\s+(?:ey" + "J[0-9A-Za-z._-]{20,}|" +
    "[0-9A-Za-z_-]{32,})"
  )
  "JWT credential" = ("ey" + "J[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}\.")
}
$secretAssignmentPattern = (
  "(?im)^(YOUTUBE_SERVER_API_KEY|YOUTUBE_OAUTH_CLIENT_ID|" +
  "YOUTUBE_OAUTH_CLIENT_SECRET|YOUTUBE_TOKEN_ENCRYPTION_KEY_V[0-9]+)=" +
  "\s*\S+"
)

$packageGateContent = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot "scripts/check-youtube-private-dev-package.ps1"
)
$playerRuntimeTestMentions = @(
  [regex]::Matches(
    $packageGateContent,
    "test/youtube_embedded_player_runtime_test\.dart"
  )
).Count
if ($playerRuntimeTestMentions -ne 3) {
  throw (
    "The package gate must analyze, test and diff-check the embedded-player " +
    "runtime test."
  )
}

$secretInventoryScripts = [ordered]@{
  "scripts/check-youtube-private-dev-preflight.ps1" =
    '\$enabledVersions\.Count -eq 1'
  "scripts/deploy-youtube-private-dev.ps1" =
    '\$enabledSecretVersions\.Count -ne 1'
}
foreach ($secretInventoryEntry in $secretInventoryScripts.GetEnumerator()) {
  $secretInventoryScript = $secretInventoryEntry.Key
  $absolutePath = Join-Path $repoRoot $secretInventoryScript
  $content = Get-Content -Raw -LiteralPath $absolutePath
  if ($content -match "--limit(?:=|\s+)1\b") {
    throw (
      "Secret-version inventory may not hide multiple enabled versions in " +
      $secretInventoryScript
    )
  }
  if (
    -not $content.Contains(
      "Required secret must have exactly one enabled value version"
    ) -or
    $content -notmatch $secretInventoryEntry.Value
  ) {
    throw (
      "The exact-one-enabled-secret-version assertion changed in " +
      $secretInventoryScript
    )
  }
}

$backendReadme = Get-Content -Raw -LiteralPath (
  Join-Path $repoRoot "backend/functions/README.md"
)
foreach ($stalePersistencePhrase in @(
  "privileged SQL Connect tables",
  "Basic user-owned CRUD remains generated by Firebase SQL Connect"
)) {
  if ($backendReadme.Contains($stalePersistencePhrase)) {
    throw "Stale YouTube persistence wording remains in backend/functions/README.md."
  }
}
if (
  -not $backendReadme.Contains(
    "private-Dev YouTube control plane uses privileged"
  ) -or
  -not $backendReadme.Contains(
    "encrypted refresh-token storage in privileged Firestore provider documents"
  )
) {
  throw "The README no longer declares the active Firestore control plane."
}

$strictUtf8 = [System.Text.UTF8Encoding]::new(
  $false,
  $true
)
$checked = 0
foreach ($relativePath in $files) {
  $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
  if ($textExtensions -notcontains $extension) {
    continue
  }

  $absolutePath = Join-Path $repoRoot $relativePath
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    throw "Package file disappeared during verification: $relativePath"
  }

  $bytes = [System.IO.File]::ReadAllBytes($absolutePath)
  try {
    $content = $strictUtf8.GetString($bytes)
  } catch {
    throw "Package text file is not valid UTF-8: $relativePath"
  }
  if ($content.Contains([char]0)) {
    throw "Package text file contains a NUL byte: $relativePath"
  }
  foreach ($secretPattern in $secretLiteralPatterns.GetEnumerator()) {
    if ($content -match $secretPattern.Value) {
      throw (
        "Potential {0} literal found in package file: {1}" -f
          $secretPattern.Key,
          $relativePath
      )
    }
  }
  if ($content -match $secretAssignmentPattern) {
    throw "A secret environment value is present in package file: $relativePath"
  }

  $lines = $content -split "\n", -1
  for ($index = 0; $index -lt $lines.Count; $index += 1) {
    $line = $lines[$index].TrimEnd("`r")
    if ($line -match "[ `t]+$") {
      throw (
        "Trailing whitespace in {0}:{1}" -f
          $relativePath,
          ($index + 1)
      )
    }
    if (
      $line -match "^<<<<<<< " -or
      $line -eq "=======" -or
      $line -match "^>>>>>>> "
    ) {
      throw (
        "Merge-conflict marker in {0}:{1}" -f
          $relativePath,
          ($index + 1)
      )
    }
  }
  $checked += 1
}

if ($checked -eq 0) {
  throw "No private Dev package text files were verified."
}

$requiredBatchStatsDeclarations = [ordered]@{
  "deployment/youtube-private-dev/deployment-manifest.json" =
    '"YOUTUBE_DEV_BATCH_STATS_DAILY_CAP": 500'
  "backend/functions/.env.example" =
    "YOUTUBE_DEV_BATCH_STATS_DAILY_CAP=500"
  "backend/functions/env/moolsocial-dev-503018.env" =
    "YOUTUBE_DEV_BATCH_STATS_DAILY_CAP=500"
  "scripts/prepare-youtube-private-dev-runtime.ps1" =
    '"YOUTUBE_DEV_BATCH_STATS_DAILY_CAP=500"'
  "scripts/check-youtube-private-dev-preflight.ps1" =
    'YOUTUBE_DEV_BATCH_STATS_DAILY_CAP = "500"'
  "scripts/verify-youtube-private-dev-deployment.ps1" =
    'YOUTUBE_DEV_BATCH_STATS_DAILY_CAP = "500"'
}
foreach ($entry in $requiredBatchStatsDeclarations.GetEnumerator()) {
  $absolutePath = Join-Path $repoRoot $entry.Key
  $content = Get-Content -Raw -LiteralPath $absolutePath
  if (-not $content.Contains($entry.Value)) {
    throw (
      "The private Dev batch-stats quota declaration changed in {0}." -f
        $entry.Key
    )
  }
}

$requiredAnalyticsDeclarations = [ordered]@{
  "deployment/youtube-private-dev/deployment-manifest.json" =
    '"YOUTUBE_DEV_ANALYTICS_DAILY_CAP": 100'
  "backend/functions/.env.example" =
    "YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100"
  "backend/functions/env/moolsocial-dev-503018.env" =
    "YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100"
  "scripts/prepare-youtube-private-dev-runtime.ps1" =
    '"YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100"'
  "scripts/check-youtube-private-dev-preflight.ps1" =
    'YOUTUBE_DEV_ANALYTICS_DAILY_CAP = "100"'
  "scripts/verify-youtube-private-dev-deployment.ps1" =
    'YOUTUBE_DEV_ANALYTICS_DAILY_CAP = "100"'
  "docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md" =
    "YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100"
  "docs/delivery/YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md" =
    "YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100"
}
foreach ($entry in $requiredAnalyticsDeclarations.GetEnumerator()) {
  $absolutePath = Join-Path $repoRoot $entry.Key
  $content = Get-Content -Raw -LiteralPath $absolutePath
  if (-not $content.Contains($entry.Value)) {
    throw (
      "The private Dev analytics quota declaration changed in {0}." -f
        $entry.Key
    )
  }
}

$requiredOrderDeclarations = [ordered]@{
  "docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md" =
    "governance APIs and billing,\s+then the exact\s+founder-approved budget,\s+then workload prerequisites"
  "docs/delivery/YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md" =
    "governance and billing,\s+then the exact budget,\s+then\s+workload prerequisites,\s+then the read-only security preflight"
}
foreach ($entry in $requiredOrderDeclarations.GetEnumerator()) {
  $absolutePath = Join-Path $repoRoot $entry.Key
  $content = Get-Content -Raw -LiteralPath $absolutePath
  if ($content -notmatch $entry.Value) {
    throw (
      "The private Dev mutation-order declaration changed in {0}." -f
        $entry.Key
    )
  }
}

Write-Host (
  "Private Dev tracked and untracked content passed: {0} UTF-8 files." -f
    $checked
)
