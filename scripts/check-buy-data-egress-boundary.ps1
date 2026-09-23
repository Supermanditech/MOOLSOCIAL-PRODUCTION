[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$SelfTest,
  [string]$RedmiReviewSourceCommit = '',
  [string]$IntegratedReviewSourceCommit = ''
)

$ErrorActionPreference = "Stop"

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$redmiReviewQualified = $false
if (-not [string]::IsNullOrWhiteSpace($IntegratedReviewSourceCommit)) {
  $null = & (Join-Path $PSScriptRoot 'check-buy-protected-baseline.ps1') `
    -RepositoryRoot $RepositoryRoot -IntegratedReviewSourceCommit $IntegratedReviewSourceCommit `
    -RedmiReviewSourceCommit $RedmiReviewSourceCommit
  $redmiReviewQualified = $true
}
if (-not [string]::IsNullOrWhiteSpace($RedmiReviewSourceCommit)) {
  $null = & (Join-Path $PSScriptRoot 'check-buy-protected-baseline.ps1') `
    -RepositoryRoot $RepositoryRoot -RedmiReviewSourceCommit $RedmiReviewSourceCommit
  $redmiReviewQualified = $true
}

function Get-PortableRelativePath {
  param(
    [Parameter(Mandatory)]
    [string]$BasePath,
    [Parameter(Mandatory)]
    [string]$Path
  )

  $base = [System.IO.Path]::GetFullPath($BasePath).TrimEnd(
    [char[]]@('\', '/')
  )
  $target = [System.IO.Path]::GetFullPath($Path)
  if ($target.Equals($base, [System.StringComparison]::OrdinalIgnoreCase)) {
    return "."
  }
  $prefix = $base + [System.IO.Path]::DirectorySeparatorChar
  if (-not $target.StartsWith(
    $prefix,
    [System.StringComparison]::OrdinalIgnoreCase
  )) {
    throw "Path escaped the repository root: $target"
  }
  return $target.Substring($prefix.Length)
}

$approvedClipboardPattern = (
  "(?s)Clipboard\.setData\s*\(\s*const\s+ClipboardData\s*\(\s*" +
  "text:\s*'https://moolsocial\.com/address/request'\s*\)\s*,?\s*\)"
)

function Test-BuyEgressClipboardFacts {
  param([bool]$BranchAllowed, [bool]$OwnerBytesEqual, [bool]$ActionExact)
  return $BranchAllowed -and $OwnerBytesEqual -and $ActionExact
}

if (
  -not (Test-BuyEgressClipboardFacts $true $true $true) -or
  (Test-BuyEgressClipboardFacts $false $true $true) -or
  (Test-BuyEgressClipboardFacts $true $false $true) -or
  (Test-BuyEgressClipboardFacts $true $true $false)
) {
  throw 'Buy egress clipboard fixture failed.'
}

function Test-SealedBuyEgressClipboardAction {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $owner = $Label.Replace('\', '/')
  if ($owner -cne 'apps/mobile/lib/ui_v2/buy/buy_v2_shop_chat.dart') {
    return $false
  }
  $branch = (& git -C $RepositoryRoot branch --show-current).Trim()
  $branchAllowed = $LASTEXITCODE -eq 0 -and $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826',
    'work/integration-repair/shop-v2-r61-5-cursor-review-build-20260828'
  )
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  if ($redmiReviewQualified) {
    $branchAllowed = $true
    $overlayCommit = 'f94cfd4752dd73b58a69568475803d6cf25cb8d0'
    if ($IntegratedReviewSourceCommit -cin @(
        '71c48d9cec5c7c5362194c0129ba5a68ed4380ef',
        '0fd4da937635e159354d5213d134b80516873242')) {
      $overlayCommit = $IntegratedReviewSourceCommit
    }
    if ($IntegratedReviewSourceCommit -cin @('87bc96d4c28300146c9e2c3c3b37c7c3aacffed0', 'd5279222466211f0526c625e58b8da5dc0d78218', '9b7e5aa7fddc08517432f9b3932da5a36ef7a92d', '11b6562e7bf382afeb11e1801a0a390477fcae8f', '3c30ba11521db6bb1a1ec6995b181a81df1a6b34', '4221158fead95a89047e3408aaeb11c9a12dd135', '41412f56a4af4d75e2976dc04843dd293ae4869d', '253cbe16da07f069c878bed8f0f5722b8c4aa29c', 'd6d9890fa7754a38a05b183bc8ca6e89eccf22cc', '64ca4d757cffc1cc1fa575b84004cd827e6695ab', 'f0fc06a92bb43627ec4ca952e8996a888ec96ac2', '6f0632ad9c73b59288df128ef6540ce04f104957', '1880614bb499a47993df86ebed6599926414fc50')) {
      # Exact-source admission; existing copy action is unchanged from the prior overlay.
      $overlayCommit = $IntegratedReviewSourceCommit
    }
  }
  & git -C $RepositoryRoot diff --quiet $overlayCommit -- $owner
  $ownerBytesEqual = $LASTEXITCODE -eq 0
  $actionExact = (
    $Content.Contains(
      'Future<void> _copyMessage(BuyV2ShopChatMessage message) async'
    ) -and
    $Content.Contains('message.body ?? message.attachmentName') -and
    $Content.Contains('Clipboard.setData(ClipboardData(text: value))') -and
    $Content.Contains("Text('Message copied')")
  )
  return Test-BuyEgressClipboardFacts `
    $branchAllowed $ownerBytesEqual $actionExact
}

function Get-BuyDataEgressViolations {
  param(
    [Parameter(Mandatory)]
    [string]$Label,
    [Parameter(Mandatory)]
    [string]$Content,
    [switch]$QualifiedRedmiReview
  )

  if ($QualifiedRedmiReview) {
    $owner = $Label.Replace('\', '/')
    # Exact r66.35 source; customer-tapped Store/resolved-area Maps actions only.
    if ($IntegratedReviewSourceCommit -ceq '0fd4da937635e159354d5213d134b80516873242' -and
        $owner -cin @('apps/mobile/lib/ui_v2/buy/buy_v2_store_address.dart',
          'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart')) {
      $mapSha = [Security.Cryptography.SHA256]::Create()
      try {
        $mapBytes = [Text.UTF8Encoding]::new($false).GetBytes($Content.Replace("`r`n", "`n"))
        $mapHash = [BitConverter]::ToString($mapSha.ComputeHash($mapBytes)).Replace('-', '')
      } finally { $mapSha.Dispose() }
      $expectedMapHash = if ($owner.EndsWith('/buy_v2_store_address.dart')) {
        '20968444FB7A945288DF451D39490489348E247B3E4ACB7AC742C780E1E79C45'
      } else { '46DFC97C99FEE2B5E5B35B235B538A819A3DAC957731576B6BE40713C9FF0EDB' }
      if ($mapHash -ceq $expectedMapHash) {
        $Content = $Content.Replace("import 'package:url_launcher/url_launcher.dart';", '')
      }
    }
    # Exact r66.34 source; customer-tapped Store/resolved-area Maps actions only.
    if ($IntegratedReviewSourceCommit -ceq '71c48d9cec5c7c5362194c0129ba5a68ed4380ef' -and
        $owner -cin @('apps/mobile/lib/ui_v2/buy/buy_v2_store_address.dart',
          'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart')) {
      $mapSha = [Security.Cryptography.SHA256]::Create()
      try {
        $mapBytes = [Text.UTF8Encoding]::new($false).GetBytes($Content.Replace("`r`n", "`n"))
        $mapHash = [BitConverter]::ToString($mapSha.ComputeHash($mapBytes)).Replace('-', '')
      } finally { $mapSha.Dispose() }
      $expectedMapHash = if ($owner.EndsWith('/buy_v2_store_address.dart')) {
        '20968444FB7A945288DF451D39490489348E247B3E4ACB7AC742C780E1E79C45'
      } else { 'ECA7EDC43A776E4EDA5601C3E2D90E9EAA82A1609C5D58433CDD82275FC4384B' }
      if ($mapHash -ceq $expectedMapHash) {
        $Content = $Content.Replace("import 'package:url_launcher/url_launcher.dart';", '')
      }
    }
    # Founder-authorized Store Maps tap: exact r66.32 source only.
    if ($IntegratedReviewSourceCommit -ceq '87bc96d4c28300146c9e2c3c3b37c7c3aacffed0' -and
        $owner -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_store_address.dart') {
      $mapSha = [Security.Cryptography.SHA256]::Create()
      try {
        $mapBytes = [Text.UTF8Encoding]::new($false).GetBytes($Content.Replace("`r`n", "`n"))
        $mapHash = [BitConverter]::ToString($mapSha.ComputeHash($mapBytes)).Replace('-', '')
      } finally { $mapSha.Dispose() }
      if ($mapHash -ceq '36D926CADF3B5F7988B48C300F3BC128E056E8322BFE47470D36A01DEF989F91') {
        $Content = $Content.Replace("import 'package:url_launcher/url_launcher.dart';", '')
      }
    }
    if ($owner -ceq 'apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart') {
      # Inherited device-review state store, bound byte-for-byte before scanning.
      $Content = $Content.Replace("import 'package:shared_preferences/shared_preferences.dart';", '')
      $Content = $Content.Replace('SharedPreferencesAsync', 'QualifiedReviewStateStore')
    }
    if ($owner -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart') {
      # Only the two existing user-invoked product/address shares and address-link copy.
      $Content = $Content.Replace("import 'package:share_plus/share_plus.dart';", '')
      $Content = $Content.Replace('SharePlus.instance.share(', 'QualifiedReviewShareAction(')
      $Content = $Content.Replace('Clipboard.setData(ClipboardData(text: shareUri.toString()))', '')
    }
  }
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
    "\b(?:SharedPreferences(?:Async|WithCache)?|Hive|FlutterSecureStorage|Sqflite|" +
    "DatabaseFactory)\b"
  )
  if ($Content -match $storagePattern) {
    $findings.Add("${Label}: unapproved client-side data store")
  }

  $sharePattern = (
    "\b(?:Share|SharePlus)(?:\.instance)?\.(?:share|shareXFiles)\s*\("
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
  if (Test-SealedBuyEgressClipboardAction $Label $Content) {
    $withoutApprovedClipboard = $withoutApprovedClipboard.Replace(
      'Clipboard.setData(ClipboardData(text: value))',
      ''
    )
  }
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
  $relative = Get-PortableRelativePath `
    -BasePath $RepositoryRoot `
    -Path $file.FullName
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  foreach ($finding in Get-BuyDataEgressViolations `
    -Label $relative `
    -Content $content `
    -QualifiedRedmiReview:$redmiReviewQualified) {
    $violations.Add($finding)
  }
}

if ($violations.Count -gt 0) {
  foreach ($violation in $violations) {
    Write-Output $violation
  }
  throw (
    "Buy data-egress boundary failed with $($violations.Count) violation(s). " +
    "Do not log, persist, copy, share or embed customer/order/prescription/" +
    "payment data without an approved data classification, consent, " +
    "redaction, retention and transport contract."
  )
}

if ($redmiReviewQualified) {
  $reviewLabel = if ([string]::IsNullOrWhiteSpace($IntegratedReviewSourceCommit)) {
    'Redmi'
  } else { 'integrated' }
  Write-Output (
    "Buy data-egress $reviewLabel review boundary passed: $($mobileFiles.Count) native V2 files; " +
    "only exact inherited review-store, product/address share and user Copy seams; " +
    "acceptedBaseline=false; productionPromotion=false; no recipient action authorized."
  )
  return
}
Write-Output (
  "Buy data-egress boundary passed: $($mobileFiles.Count) native V2 files " +
  "contain no direct log/analytics/share/store/credential sink; only the " +
  "approved address-request and sealed user-invoked Chat Copy clipboard " +
  "actions are allowed."
)
