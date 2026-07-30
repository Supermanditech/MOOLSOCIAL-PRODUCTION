[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$SelfTest
)

$ErrorActionPreference = "Stop"

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

$approvedClipboardPattern = (
  "(?s)Clipboard\.setData\s*\(\s*const\s+ClipboardData\s*\(\s*" +
  "text:\s*'https://moolsocial\.com/address/request'\s*\)\s*,?\s*\)"
)

function Get-BuyDataEgressViolations {
  param(
    [Parameter(Mandatory)]
    [string]$Label,
    [Parameter(Mandatory)]
    [string]$Content
  )

  $findings = [System.Collections.Generic.List[string]]::new()

  $egressImportPattern = (
    "(?m)^\s*import\s+['""]package:(?:firebase_analytics|" +
    "firebase_crashlytics|sentry(?:_flutter)?|logger|logging|" +
    "shared_preferences|hive|sqflite|flutter_secure_storage|" +
    "share_plus|url_launcher)(?:[/'][^'""]*)?['""]"
  )
  if ($Content -match $egressImportPattern) {
    $findings.Add(
      "${Label}: direct analytics, logging, sharing or storage import"
    )
  }

  $loggingPattern = (
    "(?m)(?:^|[^A-Za-z0-9_])(?:print|debugPrint|debugPrintSynchronously|" +
    "developer\.log)\s*\("
  )
  if ($Content -match $loggingPattern) {
    $findings.Add("${Label}: direct diagnostic logging sink")
  }

  $telemetryPattern = (
    "\b(?:FirebaseAnalytics|FirebaseCrashlytics|Sentry|Logger)\b|" +
    "\.(?:logEvent|recordError|captureException|captureMessage)\s*\("
  )
  if ($Content -match $telemetryPattern) {
    $findings.Add("${Label}: direct analytics or crash-reporting sink")
  }

  $storagePattern = (
    "\b(?:SharedPreferences|Hive|FlutterSecureStorage|Sqflite|" +
    "DatabaseFactory)\b"
  )
  if ($Content -match $storagePattern) {
    $findings.Add("${Label}: unapproved client-side data store")
  }

  $sharePattern = (
    "\b(?:Share|SharePlus)\.(?:share|shareXFiles)\s*\("
  )
  if ($Content -match $sharePattern) {
    $findings.Add("${Label}: direct system-share data egress")
  }

  if ($Content -match "\bClipboard\.(?:getData|hasStrings)\s*\(") {
    $findings.Add("${Label}: clipboard read")
  }

  $withoutApprovedClipboard = [regex]::Replace(
    $Content,
    $approvedClipboardPattern,
    ""
  )
  if ($withoutApprovedClipboard -match "\bClipboard\.setData\s*\(") {
    $findings.Add("${Label}: unapproved clipboard write")
  }

  $credentialPatterns = @(
    "-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "\bAIza[0-9A-Za-z_-]{20,}\b",
    "\bsk-[0-9A-Za-z_-]{20,}\b",
    "\bBearer\s+[0-9A-Za-z._~-]{12,}\b"
  )
  foreach ($pattern in $credentialPatterns) {
    if ($Content -match $pattern) {
      $findings.Add("${Label}: embedded credential-like material")
      break
    }
  }

  return $findings
}

if ($SelfTest) {
  $cases = @(
    @{
      Name = "diagnostic log"
      Content = "debugPrint('phone=' + session.selectedAddress.phone);"
      Rejected = $true
    },
    @{
      Name = "analytics"
      Content = "FirebaseAnalytics.instance.logEvent(name: 'checkout');"
      Rejected = $true
    },
    @{
      Name = "local store"
      Content = "final prefs = await SharedPreferences.getInstance();"
      Rejected = $true
    },
    @{
      Name = "system share"
      Content = "Share.share(session.selectedAddress.phone);"
      Rejected = $true
    },
    @{
      Name = "clipboard write"
      Content = "Clipboard.setData(ClipboardData(text: order.itemSummary));"
      Rejected = $true
    },
    @{
      Name = "clipboard read"
      Content = "final value = await Clipboard.getData('text/plain');"
      Rejected = $true
    },
    @{
      Name = "embedded token"
      Content = (
        "const authorization = " +
        "'Bearer abcdefghijklmnopqrstuvwxyz123456';"
      )
      Rejected = $true
    },
    @{
      Name = "approved address request"
      Content = (
        "await Clipboard.setData(" +
        "const ClipboardData(" +
        "text: 'https://moolsocial.com/address/request'))"
      )
      Rejected = $false
    },
    @{
      Name = "ordinary presentation"
      Content = "const Text('Delivering to saved address');"
      Rejected = $false
    }
  )

  foreach ($case in $cases) {
    $findings = @(
      Get-BuyDataEgressViolations `
        -Label $case.Name `
        -Content $case.Content
    )
    $wasRejected = $findings.Count -gt 0
    if ($wasRejected -ne $case.Rejected) {
      throw (
        "Buy data-egress self-test failed for '$($case.Name)': expected " +
        "rejected=$($case.Rejected), found rejected=$wasRejected."
      )
    }
  }

  Write-Output (
    "Buy data-egress boundary self-test passed: seven forbidden cases were " +
    "rejected and two safe cases were accepted."
  )
  return
}

$featureRoot = Join-Path $RepositoryRoot "apps\mobile\lib\features\buy"
$presentationRoot = Join-Path $RepositoryRoot "apps\mobile\lib\ui_v2\buy"
foreach ($requiredRoot in @($featureRoot, $presentationRoot)) {
  if (-not (Test-Path -LiteralPath $requiredRoot -PathType Container)) {
    throw "Required Buy data-egress root is missing: $requiredRoot"
  }
}

$mobileFiles = @(
  Get-ChildItem `
    -LiteralPath $featureRoot `
    -File `
    -Filter "buy_v2_*.dart"
  Get-ChildItem `
    -LiteralPath $presentationRoot `
    -Recurse `
    -File `
    -Filter "*.dart"
) | Sort-Object -Property FullName -Unique

if ($mobileFiles.Count -eq 0) {
  throw "No protected Buy V2 files were found for data-egress inspection."
}

$violations = [System.Collections.Generic.List[string]]::new()
foreach ($file in $mobileFiles) {
  $relative = [System.IO.Path]::GetRelativePath(
    $RepositoryRoot,
    $file.FullName
  )
  $content = Get-Content -LiteralPath $file.FullName -Raw
  foreach ($finding in Get-BuyDataEgressViolations `
    -Label $relative `
    -Content $content) {
    $violations.Add($finding)
  }
}

if ($violations.Count -gt 0) {
  foreach ($violation in $violations) {
    Write-Error $violation
  }
  throw (
    "Buy data-egress boundary failed with $($violations.Count) violation(s). " +
    "Do not log, persist, copy, share or embed customer/order/prescription/" +
    "payment data without an approved data classification, consent, " +
    "redaction, retention and transport contract."
  )
}

Write-Output (
  "Buy data-egress boundary passed: $($mobileFiles.Count) native V2 files " +
  "contain no direct log/analytics/share/store/credential sink; only the " +
  "approved first-party address-request clipboard action is allowed."
)
