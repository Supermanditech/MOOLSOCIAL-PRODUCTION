param(
  [string]$RegressionStatus = "Pending current-cycle full regression"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$referenceDirectory = Join-Path `
  (Split-Path -Parent $root) `
  "supermandi-uiux-screenbook\approved-final\screens"
$outputPath = Join-Path `
  $root `
  "docs\quality\SCREEN-BY-SCREEN-READINESS.csv"
$tapInventoryPath = Join-Path `
  $root `
  "docs\quality\APPROVED-TAP-INVENTORY.csv"

if (-not (Test-Path -LiteralPath $referenceDirectory)) {
  throw "Approved screen source was not found at $referenceDirectory"
}

function Get-ScreenContract([int]$screen) {
  switch ($screen) {
    { $_ -le 4 } {
      return @{
        Journey = "Install, setup, sign-in and Universal entry"
        Client = "Flutter"
        Owner = "journey01"
        Interaction = "journey01_test.dart; journey_session_test.dart; universal_intent_completion_test.dart"
        Visual = "universal_screen_golden_test.dart"
        Backend = "Environment-isolated Firebase adapters implemented; local emulators verified; production project/config pending"
        Cascade = "PROD-FDN-001; PROD-ID-001; PROD-ID-002"
      }
    }
    { $_ -le 8 } {
      return @{
        Journey = "Social discovery and creation"
        Client = "Flutter"
        Owner = "journey01 Universal Social"
        Interaction = "universal_intent_completion_test.dart"
        Visual = "universal_screen_golden_test.dart"
        Backend = "Review state; live social graph, moderation and media services pending"
        Cascade = "PROD-SOC-001; PROD-SOC-002; PROD-SOC-003"
      }
    }
    { $_ -le 22 } {
      return @{
        Journey = "Consumer Buy, fulfilment and issue resolution"
        Client = "Flutter"
        Owner = "buy"
        Interaction = "buy_home_delivery_flow_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review order gateway; live catalogue, inventory, order and payment services pending"
        Cascade = "PROD-COM-001; PROD-COM-002; PROD-MNY-001; PROD-OPS-001"
      }
    }
    { $_ -le 25 } {
      return @{
        Journey = "People, business, order and support Chat"
        Client = "Flutter"
        Owner = "chat"
        Interaction = "chat_flow_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review send gateway; Firestore messaging, attachment and notification services pending"
        Cascade = "PROD-PLT-003; PROD-COM-004"
      }
    }
    { $_ -le 29 } {
      return @{
        Journey = "Food order, table and tiffin"
        Client = "Flutter"
        Owner = "eat"
        Interaction = "eat_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review food gateway; live menu, capacity, order and payment services pending"
        Cascade = "PROD-COM-003; PROD-MNY-001; PROD-OPS-001"
      }
    }
    { $_ -le 35 } {
      return @{
        Journey = "Ride booking, live trip and support"
        Client = "Flutter"
        Owner = "ride"
        Interaction = "ride_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review ride gateway; maps, supply, dispatch, safety and payment integrations pending"
        Cascade = "PROD-OPS-002; PROD-MNY-001; PROD-EXT-001"
      }
    }
    { $_ -le 56 } {
      return @{
        Journey = "Doctor, salon and Get It Done bookings"
        Client = "Flutter"
        Owner = "book"
        Interaction = "book_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review booking gateway; provider capacity, consent, protected payment and support APIs pending"
        Cascade = "PROD-OPS-003; PROD-MNY-001; PROD-PLT-002"
      }
    }
    { $_ -le 66 } {
      return @{
        Journey = "Pay, requests, receipts, refund and reversal"
        Client = "Flutter"
        Owner = "pay"
        Interaction = "pay_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review payment gateway; PSP, webhook inbox, ledger and reconciliation pending"
        Cascade = "PROD-MNY-001; PROD-MNY-002; PROD-MNY-003"
      }
    }
    { $_ -le 73 } {
      return @{
        Journey = "Work discovery and workspace onboarding"
        Client = "Flutter"
        Owner = "work"
        Interaction = "work_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review work gateway; eligibility, identity proof and workspace provisioning pending"
        Cascade = "PROD-WRK-001; PROD-WRK-002"
      }
    }
    { $_ -le 77 } {
      return @{
        Journey = "Retailer order fulfilment and delivery"
        Client = "Flutter"
        Owner = "retailer"
        Interaction = "retailer_order_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review retailer gateway; authoritative stock, order and delivery services pending"
        Cascade = "PROD-COM-001; PROD-COM-002; PROD-OPS-001; PROD-WRK-003"
      }
    }
    { $_ -le 80 } {
      return @{
        Journey = "Retailer POS and counter operations"
        Client = "Flutter"
        Owner = "retailer POS"
        Interaction = "retailer_pos_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review POS gateway; invoice, tax, stock movement and offline sync pending"
        Cascade = "PROD-RTL-001; PROD-RTL-002"
      }
    }
    { $_ -le 89 } {
      return @{
        Journey = "Retailer wholesale procurement"
        Client = "Flutter"
        Owner = "retailer wholesale"
        Interaction = "retailer_wholesale_vertical_slice_test.dart"
        Visual = "Widget and physical-device evidence"
        Backend = "Review wholesale gateway; supplier catalogue, PO, receipt and payment APIs pending"
        Cascade = "PROD-RTL-003; PROD-MNY-001"
      }
    }
    { $_ -le 92 } {
      return @{
        Journey = "Retailer sales, purchase, stock and Business Book"
        Client = "Flutter"
        Owner = "retailer books"
        Interaction = "retailer_books_vertical_slice_test.dart"
        Visual = "retailer_books_visual_golden_test.dart"
        Backend = "Review books gateway; ledger projections, exports and reconciliation pending"
        Cascade = "PROD-RTL-004; PROD-MNY-003"
      }
    }
    { $_ -le 96 } {
      return @{
        Journey = "Retailer result-based business services"
        Client = "Flutter"
        Owner = "retailer business services"
        Interaction = "retailer_business_services_vertical_slice_test.dart"
        Visual = "retailer_business_services_visual_golden_test.dart"
        Backend = "Review services gateway; eligibility, subscription, fulfilment and support APIs pending"
        Cascade = "PROD-WRK-004; PROD-ADM-002"
      }
    }
    { $_ -le 100 } {
      return @{
        Journey = "Retailer customers, offers and campaigns"
        Client = "Flutter"
        Owner = "retailer campaigns"
        Interaction = "retailer_campaign_vertical_slice_test.dart"
        Visual = "retailer_campaign_visual_golden_test.dart"
        Backend = "Review campaign gateway; consent, audience, budget and attribution services pending"
        Cascade = "PROD-SOC-004; PROD-ADM-002"
      }
    }
    { $_ -le 106 } {
      return @{
        Journey = "Retailer recovery, assistant, staff, settings and issues"
        Client = "Flutter"
        Owner = "retailer controls"
        Interaction = "retailer_controls_vertical_slice_test.dart"
        Visual = "retailer_controls_visual_golden_test.dart"
        Backend = "Review controls gateway; AI policy, RBAC, settings and issue APIs pending"
        Cascade = "PROD-RTL-005; PROD-AI-001; PROD-PLT-002"
      }
    }
    { $_ -le 115 } {
      return @{
        Journey = "Manufacturer sales, procurement, growth and control"
        Client = "Flutter"
        Owner = "manufacturer"
        Interaction = "manufacturer_vertical_slice_test.dart"
        Visual = "manufacturer_visual_golden_test.dart"
        Backend = "Review manufacturer gateway; B2B catalogue, order, dispatch and claims APIs pending"
        Cascade = "PROD-MFG-001; PROD-MFG-002; PROD-WRK-004"
      }
    }
    { $_ -le 123 } {
      return @{
        Journey = "Captain trips, earnings, compliance and support"
        Client = "Flutter"
        Owner = "captain"
        Interaction = "captain_vertical_slice_test.dart"
        Visual = "captain_visual_golden_test.dart"
        Backend = "Review captain gateway; dispatch, maps, safety, payouts and compliance APIs pending"
        Cascade = "PROD-OPS-002; PROD-MNY-003; PROD-EXT-001"
      }
    }
    { $_ -le 132 -or $_ -eq 166 } {
      return @{
        Journey = "Creator studio, campaigns, earnings, membership and YouTube"
        Client = "Flutter"
        Owner = "creator"
        Interaction = "creator_vertical_slice_test.dart"
        Visual = "creator_visual_golden_test.dart"
        Backend = "Review creator gateway; YouTube OAuth, campaign, media, rights and payout APIs pending"
        Cascade = "PROD-SOC-001; PROD-SOC-002; PROD-SOC-003; PROD-WRK-004"
      }
    }
    { $_ -le 138 } {
      return @{
        Journey = "Earn opportunities, work proof, payout and history"
        Client = "Flutter"
        Owner = "operations Earn"
        Interaction = "operations_vertical_slice_test.dart"
        Visual = "operations_visual_golden_test.dart"
        Backend = "Review operations gateway; funded work, proof review and payout APIs pending"
        Cascade = "PROD-WRK-001; PROD-WRK-005; PROD-MNY-003"
      }
    }
    { $_ -le 146 } {
      return @{
        Journey = "Service-provider workspace"
        Client = "Flutter"
        Owner = "operations Provider"
        Interaction = "operations_vertical_slice_test.dart"
        Visual = "operations_visual_golden_test.dart"
        Backend = "Review operations gateway; catalogue, availability, request and fulfilment APIs pending"
        Cascade = "PROD-OPS-003; PROD-WRK-004"
      }
    }
    { ($_ -ge 147 -and $_ -le 156) -or ($_ -ge 163 -and $_ -le 164) } {
      return @{
        Journey = "Superadmin governed operations"
        Client = "Next.js"
        Owner = "apps/admin"
        Interaction = "admin-intent.spec.ts; contracts.test.mjs"
        Visual = "admin-visual.spec.ts desktop and 412x915"
        Backend = "Review-mode role gate; live Firebase session, RBAC and command APIs pending"
        Cascade = "PROD-ADM-001; PROD-ADM-002; PROD-ADM-003"
      }
    }
    { ($_ -ge 157 -and $_ -le 162) -or $_ -eq 165 } {
      return @{
        Journey = "Shared activity, identity, Ask, files, security and controls"
        Client = "Flutter"
        Owner = "shared"
        Interaction = "shared_vertical_slice_test.dart"
        Visual = "shared_visual_golden_test.dart"
        Backend = "Review shared gateway; live account, files, consent, security and notification APIs pending"
        Cascade = "PROD-PLT-001; PROD-PLT-002; PROD-PLT-003"
      }
    }
    default {
      throw "No screen contract exists for screen $screen"
    }
  }
}

$sourceFiles = Get-ChildItem -LiteralPath $referenceDirectory -Filter *.html |
  ForEach-Object {
    if ($_.BaseName -notmatch '^(\d+)-(.*)$') {
      throw "Unexpected approved screen filename: $($_.Name)"
    }
    [pscustomobject]@{
      Screen = [int]$Matches[1]
      Slug = $Matches[2]
      File = $_.Name
    }
  } |
  Sort-Object Screen

if ($sourceFiles.Count -ne 167) {
  throw "Expected 167 approved screens; found $($sourceFiles.Count)."
}

for ($screen = 0; $screen -le 166; $screen += 1) {
  if ($sourceFiles[$screen].Screen -ne $screen) {
    throw "Approved screen sequence is missing screen $screen."
  }
}

$tapInventory = @{}
if (-not (Test-Path -LiteralPath $tapInventoryPath)) {
  throw @"
Approved tap inventory was not found at $tapInventoryPath.
Run: node scripts/export-approved-tap-inventory.mjs
"@
}
foreach ($tapRow in Import-Csv -LiteralPath $tapInventoryPath) {
  $tapInventory[$tapRow.Screen] = $tapRow
}
if ($tapInventory.Count -ne 167) {
  throw "Expected 167 tap-inventory rows; found $($tapInventory.Count)."
}

$rows = foreach ($source in $sourceFiles) {
  $contract = Get-ScreenContract $source.Screen
  $screenKey = $source.Screen.ToString("000")
  $tap = $tapInventory[$screenKey]
  if (-not $tap) {
    throw "Tap inventory is missing screen $screenKey."
  }
  [pscustomobject]@{
    Screen = $screenKey
    ApprovedReference = $source.File
    ScreenPurpose = ($source.Slug -replace "-", " ")
    Journey = $contract.Journey
    Client = $contract.Client
    ImplementationOwner = $contract.Owner
    ApprovedControls = $tap.DirectAndReachableControls
    InitiallyRenderedControls = $tap.InitiallyRenderedControls
    RevealedOrNestedControls = $tap.ScriptRevealedControls
    ApprovedNavigationLinks = $tap.NavigationLinks
    ApprovedInputs = $tap.Inputs
    UIUX = "Implemented; Apple-inspired shared design system"
    VisibleCopy = "Audited; production-copy gate passed"
    TapAndNestedTap = $contract.Interaction
    VisualEvidence = $contract.Visual
    CurrentRegression = $RegressionStatus
    LiveAPIStatus = $contract.Backend
    CascadingTickets = $contract.Cascade
    FounderReview = "Pending founder review"
  }
}

$rows | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding utf8
Write-Output "Exported $($rows.Count) screen readiness rows to $outputPath"
