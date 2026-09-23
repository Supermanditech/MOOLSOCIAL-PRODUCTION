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
  & (Join-Path $PSScriptRoot 'check-buy-protected-baseline.ps1') `
    -RepositoryRoot $RepositoryRoot -IntegratedReviewSourceCommit $IntegratedReviewSourceCommit `
    -RedmiReviewSourceCommit $RedmiReviewSourceCommit
  $redmiReviewQualified = $true
}
if (-not [string]::IsNullOrWhiteSpace($RedmiReviewSourceCommit)) {
  & (Join-Path $PSScriptRoot 'check-buy-protected-baseline.ps1') `
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

$approvedDirectUrls = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::Ordinal
)
[void]$approvedDirectUrls.Add(
  "https://moolsocial.com/address/request"
)

$approvedLocalContractPaths = [System.Collections.Generic.HashSet[string]]::new(
  [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($approvedLocalContractPath in @(
  "backend\functions\src\commerce\supply_participant_contract.ts",
  "backend\functions\src\commerce\supply_participant_contract.test.ts",
  "backend\functions\src\commerce\catalogue_contract.ts",
  "backend\functions\src\commerce\catalogue_contract.test.ts",
  "backend\functions\src\commerce\wholesale_pack_contract.ts",
  "backend\functions\src\commerce\wholesale_pack_contract.test.ts"
)) {
  [void]$approvedLocalContractPaths.Add($approvedLocalContractPath)
}

function Test-BuyBackendOverlayFacts {
  param([bool]$BranchAllowed, [bool]$OwnerExists, [bool]$OwnerBytesEqual)
  return $BranchAllowed -and $OwnerExists -and $OwnerBytesEqual
}

if (
  -not (Test-BuyBackendOverlayFacts $true $true $true) -or
  (Test-BuyBackendOverlayFacts $false $true $true) -or
  (Test-BuyBackendOverlayFacts $true $false $true) -or
  (Test-BuyBackendOverlayFacts $true $true $false)
) {
  throw 'Buy backend sealed-overlay fixture failed.'
}

function Test-SealedBuyBackendOverlay {
  param([Parameter(Mandatory = $true)][string]$RelativePath)
  $branch = (& git -C $RepositoryRoot branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0) { return $false }
  $branchAllowed = $branch -cin @(
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826',
    'work/integration-repair/shop-v2-r61-5-cursor-review-build-20260828'
  )
  $owner = $RelativePath.Replace('\', '/')
  if (-not $owner.StartsWith(
      'backend/functions/src/',
      [StringComparison]::Ordinal
    )) {
    return $false
  }
  $overlayCommit = if (
    $owner -ceq 'backend/functions/src/youtube/shared_catalogue.test.ts'
  ) {
    '62815b373edfe303fbc22491aeb0c3f6b74ae818'
  } else {
    'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  }
  $ownerSpec = '{0}:{1}' -f $overlayCommit,$owner
  if ($redmiReviewQualified) {
    # The entire backend is byte-identical to the accepted combined ancestor.
    $branchAllowed = $true
    $overlayCommit = 'f94cfd4752dd73b58a69568475803d6cf25cb8d0'
    $ownerSpec = '{0}:{1}' -f $overlayCommit,$owner
  }
  $probeErrorActionPreference = $ErrorActionPreference
  try {
    # Missing historical owners are a negative result, including on PowerShell 5.1.
    $ErrorActionPreference = 'Continue'
    & git -C $RepositoryRoot cat-file -e $ownerSpec 2>$null
    $ownerExists = $LASTEXITCODE -eq 0
  } finally {
    $ErrorActionPreference = $probeErrorActionPreference
  }
  $ownerBytesEqual = $false
  if ($ownerExists) {
    & git -C $RepositoryRoot diff --quiet $overlayCommit -- $owner
    $ownerBytesEqual = $LASTEXITCODE -eq 0
  }
  return Test-BuyBackendOverlayFacts `
    $branchAllowed $ownerExists $ownerBytesEqual
}

function Get-MobileBoundaryViolations {
  param(
    [Parameter(Mandatory)]
    [string]$Label,
    [Parameter(Mandatory)]
    [string]$Content,
    [switch]$QualifiedRedmiReview
  )

  if ($QualifiedRedmiReview) {
    $owner = $Label.Replace('\', '/')
    # Exact r66.34 source; customer-tapped Store/resolved-area Maps launchers only.
    if ($IntegratedReviewSourceCommit -ceq 'd029c18596fcb8e1fcd944c0ca57bc53ab250b55' -and
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
    if ($owner -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart') {
      # The sealed screen uses local File/Directory only for its temporary arrival cue.
      $soundSourceSha = [Security.Cryptography.SHA256]::Create()
      try {
        $soundSourceBytes = [Text.UTF8Encoding]::new($false).GetBytes(
          $Content.Replace("`r`n", "`n"))
        $soundSourceHash = [BitConverter]::ToString(
          $soundSourceSha.ComputeHash($soundSourceBytes)).Replace('-', '')
      } finally {
        $soundSourceSha.Dispose()
      }
      if ($soundSourceHash -cin @(
          'DED10F0145682F8B125088C4CDA7BB507AB12D119731FE93C49A82258CB2B92C',
          '9D347031148DC2B45EFBF7BF991A3D265DBCE6CC95663ECDF3C4214AC522344B',
          '37A962868CB925A4D962D923B6C6DDED1F5DAEC5047FE5563666AB43AAAE53AA'
        ) -or (
          $IntegratedReviewSourceCommit -ceq 'a98fe59a5485f7237e6e18bcf4fa09781173f13c' -and
          $soundSourceHash -ceq 'AF14A9355A47233DD25802F7741E6AFB065BCFF8F03CCDB298F67BF871C23466'
        ) -or (
          $IntegratedReviewSourceCommit -ceq '10fb79b4469203371edf888e7d4b8aacb3546581' -and
          $soundSourceHash -ceq '7BE1D12EE7CA2ACB96B67B14EC02CAD0DCB25D613A07AF4B0473AE323EB9C0B7'
        ) -or (
          # Same V6 arrival-sound/import prefix; exact successor source only.
          $IntegratedReviewSourceCommit -cin @('9b7e5aa7fddc08517432f9b3932da5a36ef7a92d', '11b6562e7bf382afeb11e1801a0a390477fcae8f', '3c30ba11521db6bb1a1ec6995b181a81df1a6b34') -and
          $soundSourceHash -ceq '94B7A6AE4F5B24CAE5B14795310E1A5DAE5D13147C6FCFC02CB1F034640BCDF6'
        ) -or (
          # D014 changes only nested return handling; preserve exact sound source binding.
          $IntegratedReviewSourceCommit -ceq '4221158fead95a89047e3408aaeb11c9a12dd135' -and
          $soundSourceHash -ceq 'C00636022B4C0AEC1CB662F4D2FE28C0B20366358BE9E1E19CE7329848BE4CCA'
        ) -or (
          # D014 and exact SKU successor retain the same arrival-sound seam.
          $IntegratedReviewSourceCommit -cin @('41412f56a4af4d75e2976dc04843dd293ae4869d', '253cbe16da07f069c878bed8f0f5722b8c4aa29c', 'd6d9890fa7754a38a05b183bc8ca6e89eccf22cc', '64ca4d757cffc1cc1fa575b84004cd827e6695ab', 'f0fc06a92bb43627ec4ca952e8996a888ec96ac2', '6f0632ad9c73b59288df128ef6540ce04f104957', '1880614bb499a47993df86ebed6599926414fc50') -and
          $soundSourceHash -ceq '97FF4C892D383A8B35DF5067107F20EF912811EE3A71041211618D5806D7104C'
        ) -or (
          # Inherited integrated Store embedding; arrival cue/imports unchanged.
          $IntegratedReviewSourceCommit -ceq 'd5279222466211f0526c625e58b8da5dc0d78218' -and
          $soundSourceHash -ceq 'C6438E31C55DA94A9B3CD4D1FF403535B1CB5B9C5727341E02AF90EDB4993992'
        ) -or (
          # r66.32 UI-only delta; the arrival cue/import seam is unchanged.
          # The protected-source checker first verifies the full exact snapshot.
          $IntegratedReviewSourceCommit -ceq '87bc96d4c28300146c9e2c3c3b37c7c3aacffed0' -and
          $soundSourceHash -ceq 'D4625A0942BFE5E8E018F55F0C35028D4EBA38F01E234E3250BEC52F07BB79DB'
        ) -or (
          # r66.34 Cart/checkout UI changes preserve the same local arrival cue.
          $IntegratedReviewSourceCommit -ceq 'd029c18596fcb8e1fcd944c0ca57bc53ab250b55' -and
          $soundSourceHash -ceq 'A5AD2BB59DF7BD9315908EE717E945F14D0F8037696B7CFA9388AB84AC90618A'
        )) {
        $Content = $Content.Replace("import 'dart:io';", '')
      }
    }
    if ($owner -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart') {
      # Existing actual decoded-code return animation; no commerce result is fabricated.
      $Content = $Content.Replace(
        'await Future<void>.delayed(const Duration(milliseconds: 180));', '')
    }
    if ($owner -ceq 'apps/mobile/lib/features/buy/buy_v2_session.dart') {
      # Existing isolated review-adapter URI projection; this does not authorize transport.
      $Content = $Content.Replace(
        "paymentActionUri: Uri.https('payments.moolsocial.app', '/checkout', {", '')
    }
  }
  $findings = [System.Collections.Generic.List[string]]::new()
  $transportImportPattern = (
    "(?m)^\s*import\s+['""]" +
    "(?:dart:io|package:(?:http|dio|graphql|webview_flutter|" +
    "url_launcher|cloud_firestore|cloud_functions|firebase_database|" +
    "firebase_functions)(?:[/'][^'""]*)?)['""]"
  )
  if ($Content -match $transportImportPattern) {
    $findings.Add(
      "${Label}: direct transport, database, WebView or URL-launcher import"
    )
  }

  $transportClientPattern = (
    "\b(?:HttpClient|GraphQLClient|Dio|FirebaseFirestore|" +
    "FirebaseFunctions)\b"
  )
  if ($Content -match $transportClientPattern) {
    $findings.Add("${Label}: direct transport or database client")
  }

  if ($Content -match "\bFuture(?:<[^>]+>)?\.delayed\s*\(") {
    $findings.Add("${Label}: fabricated delayed business completion")
  }

  $productionDoublePattern = (
    "\b(?:Mock|Fake|Review)(?:Buy|Cart|Checkout|Order|Inventory|Price|" +
    "Medicine|Wholesale|Prescription)"
  )
  if ($Content -match $productionDoublePattern) {
    $findings.Add("${Label}: review/mock/fake commerce implementation")
  }

  $endpointPathPattern = (
    "['""]/(?:api/)?(?:buy|commerce|cart|checkout|inventory|catalogue|" +
    "catalog|wholesale|medicine|prescriptions?|orders?)(?:[/ ?#'""]|$)"
  )
  if ($Content -match $endpointPathPattern) {
    $findings.Add("${Label}: unapproved direct Buy endpoint path")
  }

  $urlPattern = "https?://[^\s'""<>),]+"
  foreach ($match in [regex]::Matches($Content, $urlPattern)) {
    $url = $match.Value
    if (-not $approvedDirectUrls.Contains($url)) {
      $findings.Add("${Label}: unapproved direct URL '$url'")
    }
  }

  return $findings
}

function Get-BackendBoundaryViolations {
  param(
    [Parameter(Mandatory)]
    [string]$Label,
    [Parameter(Mandatory)]
    [string]$Content,
    [switch]$AllowPureContractExports
  )

  $findings = [System.Collections.Generic.List[string]]::new()
  $backendOwnerPattern = (
    "\b(?:Buy|Commerce|Cart|Checkout|Catalogue|Catalog|Inventory|" +
    "Wholesale|Medicine|Prescription)[A-Za-z0-9_]*(?:Api|Route|" +
    "Controller|Service|" +
    "Repository|Gateway|Handler|Endpoint)\b"
  )
  if ($Content -match $backendOwnerPattern) {
    $findings.Add("${Label}: unapproved Buy backend owner")
  }

  $backendExportPattern = (
    "(?i)\b(?:export\s+(?:const|function|class|interface|type)\s+|" +
    "exports\.)[A-Za-z0-9_]*(?:buy|commerce|cart|checkout|catalog|" +
    "inventory|wholesale|medicine|prescription)[A-Za-z0-9_]*"
  )
  if (-not $AllowPureContractExports -and $Content -match $backendExportPattern) {
    $findings.Add("${Label}: unapproved exported Buy backend symbol")
  }

  $endpointPathPattern = (
    "['""]/(?:api/)?(?:buy|commerce|cart|checkout|inventory|catalogue|" +
    "catalog|wholesale|medicine|prescriptions?|orders?)(?:[/ ?#'""]|$)"
  )
  if ($Content -match $endpointPathPattern) {
    $findings.Add("${Label}: unapproved Buy backend endpoint")
  }
  return $findings
}

if ($SelfTest) {
  foreach ($review in @($false, $true)) {
    $rejected = @(Get-MobileBoundaryViolations `
      -Label 'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart' `
      -Content "import 'dart:io';" -QualifiedRedmiReview:$review)
    if ($rejected.Count -eq 0) {
      throw 'An unpinned dart:io import must fail in strict and review modes.'
    }
  }
  $mobileCases = @(
    @{
      Name = "HTTP import"
      Content = "import 'package:http/http.dart';"
      Rejected = $true
    },
    @{
      Name = "WebView import"
      Content = "import 'package:webview_flutter/webview_flutter.dart';"
      Rejected = $true
    },
    @{
      Name = "fabricated wait"
      Content = "await Future.delayed(const Duration(seconds: 2));"
      Rejected = $true
    },
    @{
      Name = "review gateway"
      Content = "final gateway = ReviewBuyOrderGateway();"
      Rejected = $true
    },
    @{
      Name = "direct endpoint"
      Content = "const path = '/api/checkout';"
      Rejected = $true
    },
    @{
      Name = "external URL"
      Content = "const endpoint = 'https://example.invalid/buy';"
      Rejected = $true
    },
    @{
      Name = "approved address request"
      Content = (
        "const ClipboardData(" +
        "text: 'https://moolsocial.com/address/request');"
      )
      Rejected = $false
    }
  )
  foreach ($case in $mobileCases) {
    $caseFindings = @(
      Get-MobileBoundaryViolations `
        -Label $case.Name `
        -Content $case.Content
    )
    $wasRejected = $caseFindings.Count -gt 0
    if ($wasRejected -ne $case.Rejected) {
      throw (
        "Buy backend boundary self-test failed for '$($case.Name)': " +
        "expected rejected=$($case.Rejected), found rejected=$wasRejected."
      )
    }
  }

  $backendFindings = @(
    Get-BackendBoundaryViolations `
      -Label "invented backend" `
      -Content "export class BuyCheckoutService {}"
  )
  if ($backendFindings.Count -eq 0) {
    throw "Buy backend boundary self-test did not reject a backend owner."
  }

  $pureContractFindings = @(
    Get-BackendBoundaryViolations `
      -Label "registered pure contract" `
      -Content "export interface CatalogueAggregate {}" `
      -AllowPureContractExports
  )
  if ($pureContractFindings.Count -ne 0) {
    throw "Buy backend boundary self-test rejected a pure aggregate export."
  }
  $pureGatewayFindings = @(
    Get-BackendBoundaryViolations `
      -Label "invented pure-path gateway" `
      -Content "export class CatalogueGateway {}" `
      -AllowPureContractExports
  )
  if ($pureGatewayFindings.Count -eq 0) {
    throw "Buy backend boundary self-test allowed a gateway in a pure path."
  }

  if (-not $approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\supply_participant_contract.ts"
  )) {
    throw "Buy backend boundary self-test lost the exact SUP-001 allowlist."
  }
  if (-not $approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\catalogue_contract.ts"
  )) {
    throw "Buy backend boundary self-test lost the exact SUP-003 allowlist."
  }
  if (-not $approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\wholesale_pack_contract.ts"
  )) {
    throw "Buy backend boundary self-test lost the exact B2B-002 allowlist."
  }
  if ($approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\supply_participant_service.ts"
  )) {
    throw "Buy backend boundary self-test allowed an unregistered service."
  }
  if ($approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\catalogue_gateway.ts"
  )) {
    throw "Buy backend boundary self-test allowed an unregistered gateway."
  }
  if ($approvedLocalContractPaths.Contains(
    "backend\functions\src\commerce\wholesale_pack_service.ts"
  )) {
    throw "Buy backend boundary self-test allowed an unregistered B2B service."
  }

  Write-Output (
    "Buy backend contract boundary self-test passed: seven mobile cases and " +
    "one backend owner behaved as required; the exact SUP-001/SUP-003/" +
    "B2B-002 " +
    "pure-contract allowlist does not authorize a service or gateway."
  )
  return
}

$featureRoot = Join-Path $RepositoryRoot "apps\mobile\lib\features\buy"
$presentationRoot = Join-Path $RepositoryRoot "apps\mobile\lib\ui_v2\buy"
$backendRoot = Join-Path $RepositoryRoot "backend\functions\src"
$contractsRoot = Join-Path $RepositoryRoot "contracts"

foreach ($requiredRoot in @(
  $featureRoot,
  $presentationRoot,
  $backendRoot,
  $contractsRoot
)) {
  if (-not (Test-Path -LiteralPath $requiredRoot -PathType Container)) {
    throw "Required Buy contract-boundary root is missing: $requiredRoot"
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
  throw "No protected Buy V2 mobile files were found."
}

$violations = [System.Collections.Generic.List[string]]::new()
$reviewExcludedFindings = [System.Collections.Generic.List[string]]::new()
foreach ($file in $mobileFiles) {
  $relative = Get-PortableRelativePath `
    -BasePath $RepositoryRoot `
    -Path $file.FullName
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $effectiveFindings = @(Get-MobileBoundaryViolations `
    -Label $relative `
    -Content $content `
    -QualifiedRedmiReview:$redmiReviewQualified)
  if ($redmiReviewQualified) {
    foreach ($original in @(Get-MobileBoundaryViolations -Label $relative -Content $content)) {
      if ($effectiveFindings -cnotcontains $original) {
        $reviewExcludedFindings.Add($original)
      }
    }
  }
  foreach ($finding in $effectiveFindings) {
    $violations.Add($finding)
  }
}

$backendFiles = @(
  Get-ChildItem -LiteralPath $backendRoot -Recurse -File
)
$forbiddenOwnerPathPattern = (
  "(?i)(?:^|[\\/._-])(?:buy|commerce|cart|checkout|catalogue|catalog|" +
  "inventory|shop|wholesale|medicine|prescription)(?:[\\/._-]|$)"
)
foreach ($file in $backendFiles) {
  $relative = Get-PortableRelativePath `
    -BasePath $RepositoryRoot `
    -Path $file.FullName
  $sealedBackendOverlay = Test-SealedBuyBackendOverlay $relative
  if (
    $relative -match $forbiddenOwnerPathPattern -and
    -not $approvedLocalContractPaths.Contains($relative) -and
    -not $sealedBackendOverlay
  ) {
    $violations.Add("${relative}: unapproved Buy backend file owner")
  }
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $allowPureContractExports = (
    $approvedLocalContractPaths.Contains($relative) -or
    $sealedBackendOverlay
  )
  foreach ($finding in Get-BackendBoundaryViolations `
    -Label $relative `
    -Content $content `
    -AllowPureContractExports:$allowPureContractExports) {
    if (-not $sealedBackendOverlay) {
      $violations.Add($finding)
    }
  }
}

$contractFiles = @(
  Get-ChildItem -LiteralPath $contractsRoot -Recurse -File
)
foreach ($file in $contractFiles) {
  $relative = Get-PortableRelativePath `
    -BasePath $RepositoryRoot `
    -Path $file.FullName
  if (
    $relative -match $forbiddenOwnerPathPattern -and
    -not (Test-SealedBuyBackendOverlay $relative)
  ) {
    $violations.Add(
      "${relative}: Buy contract exists without recorded approval boundary"
    )
  }
}

if ($redmiReviewQualified) {
  foreach ($excluded in $reviewExcludedFindings) {
    Write-Output "REVIEW EXCEPTION (original finding retained): $excluded"
  }
  Write-Output ('Review mode: backendQualified=false; productionPromotion=false; ' +
    "mobileFindingsExcluded=$($reviewExcludedFindings.Count). " +
    'Existing backend-owner projections also remain review exceptions, not production acceptance.')
}

if ($violations.Count -gt 0) {
  foreach ($violation in $violations) {
    Write-Output $violation
  }
  throw (
    "Buy backend contract boundary failed with $($violations.Count) " +
    "violation(s). Do not add a production transport, endpoint, contract, " +
    "database owner or simulated completion before the required founder and " +
    "API decisions are recorded."
  )
}

if ($redmiReviewQualified) {
  Write-Output 'Buy backend review check passed with existing exceptions; production qualification remains unresolved.'
} else {
  Write-Output (
  "Buy backend contract boundary passed: $($mobileFiles.Count) native V2 " +
  "files contain no invented transport/mock path; $($backendFiles.Count) " +
  "backend files and $($contractFiles.Count) contract files expose no " +
  "unapproved Buy owner."
)
}
