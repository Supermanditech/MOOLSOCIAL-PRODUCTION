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
    'integration/moolsocial/social-runtime-chat-v4-20260826'
  )
  $owner = $RelativePath.Replace('\', '/')
  if (-not $owner.StartsWith(
      'backend/functions/src/',
      [StringComparison]::Ordinal
    )) {
    return $false
  }
  $overlayCommit = 'd8a288cb897b5ca930425eb4a81be1a329ffa4c4'
  $ownerSpec = '{0}:{1}' -f $overlayCommit,$owner
  & git -C $RepositoryRoot cat-file -e $ownerSpec 2>$null
  $ownerExists = $LASTEXITCODE -eq 0
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
    [string]$Content
  )

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
foreach ($file in $mobileFiles) {
  $relative = Get-PortableRelativePath `
    -BasePath $RepositoryRoot `
    -Path $file.FullName
  $content = Get-Content -LiteralPath $file.FullName -Raw
  foreach ($finding in Get-MobileBoundaryViolations `
    -Label $relative `
    -Content $content) {
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

Write-Output (
  "Buy backend contract boundary passed: $($mobileFiles.Count) native V2 " +
  "files contain no invented transport/mock path; $($backendFiles.Count) " +
  "backend files and $($contractFiles.Count) contract files expose no " +
  "unapproved Buy owner."
)
