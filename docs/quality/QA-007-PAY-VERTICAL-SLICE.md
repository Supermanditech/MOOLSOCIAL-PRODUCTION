# QA-007 — Pay production vertical slice

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 57–66
- Personal-payment home separated from business payouts
- Mobile, DTH, data and saved-connection recharge
- Electricity, water, gas and internet bill fetch and payment
- Shop, order and provider QR or UPI-ID payment
- Verified and unverified payment requests, review, decline and approval
- Explicit final debit confirmation with payee, purpose, amount and method
- Bank-confirmed receipt, share, download and support actions
- Searchable successful, pending and returned payment history
- Pending-payment lockout and automatic status refresh
- Failed-no-debit retry, reversal lockout and original-method return

## Dedicated black-box coverage

- Scenarios: 11
- Passed after exact defect replays: 11/11
- Universal entry plus Pay affected suite: 28/28
- Covered outcomes: successful, empty, invalid account, invalid UPI ID,
  unknown requester, duplicate submit, cancelled, loading, provider failure,
  payment failure, permission denied, permission recovery, pending, failed
  without debit, reversal, refund, status failure, support failure, retry, no
  duplicate debit/receipt/case, compact phone and large text.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Pay screens tried to notify listeners while their first frame was building | Screen initialization mutated shared session state synchronously | Removed build-time notifications and exposed source-specific selected values without mutation | Clean Pay mount → Recharge/Bills/Scan/Request review: no build exception; 11/11 dedicated tests passed |
| Final confirmation and outcome actions were not initially discoverable | Critical buttons were lazy children inside long scrolling lists | Moved final transaction actions into persistent, full-width action areas | Request → Review to pay → confirm; failed-no-debit → retry; reversal → status: every action remains reachable |
| Pay dock Mool returned to Social instead of the Mool action surface | Dock used the Social route as its fallback | Route Pay Mool directly to `/app/mool` | Pay → Mool: action surface opens; Pay can be selected again without browser/back dependence |
| Universal recovery tried to use Social Voice while still on Scan Pay | The regression reused a production route instead of the required clean Social state | Remount a clean Social state before replaying Voice/Profile/Chat recovery | Universal → Scan Pay → clean Social → Voice/Profile/Chat → return: passed |
| Compact-device Pay controls could exist below the initial viewport without being exercised | The test looked for descendants without physically scrolling the list | Require real `ListView` scrolling before the compact-width intent tap | 360 px width plus larger text → scroll → visible action → completed route: passed |
| OPPO pending-payment action was partly covered by the bottom dock | Status refresh and support actions were ordinary list children at the end of a tall record | Moved both into the scaffold’s dock-safe persistent action area | Pay → Receipts → pending clinic payment → Check status: action fully visible, bank confirmation succeeds and one receipt opens |

## Exact failed-operation replays

- Recharge provider failure retains number, type and selected plan; one retry
  verifies the same connection.
- Recharge payment failure deducts no money; one retry creates one receipt.
- Bill-fetch validation and provider failure keep the consumer number; retry
  loads the exact current bill.
- Camera permission denial does not block typed UPI payment; permission recovery
  reopens the scan path.
- Invalid UPI ID and unknown requester cannot reach debit confirmation.
- Request decline/cancel changes no balance. Payment failure stores one
  no-debit reference; exact retry creates one successful receipt.
- Pending status failure creates no new debit. Exact refresh checks the
  original reference and completes one receipt.
- Failed-no-debit permits one safe retry with the original payee, purpose and
  amount.
- Reversal prohibits retry. Status refresh returns the amount to the original
  method and keeps the original reference linked.
- Support failure keeps the payment state unchanged; one retry creates one
  case.
- The physical OPPO failure sequence was replayed after rebuild:
  Pay → Receipts → Dr Mehta Clinic pending record → Check status → bank
  confirmation → ₹600 successful receipt. The action is no longer obscured.

## Full regression

- Final full application cycle 1 after the physical-device fix: 98/98 passed.
- Final full application cycle 2 after the physical-device fix: 98/98 passed.
- Analyzer after all fixes: no issues.
- Android debug APK rebuilt and installed successfully for
  `com.moolsocial.app` with
  `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`.
- Non-blocking build warning: several current plugins still apply the Kotlin
  Gradle Plugin directly and must be upgraded before a future Flutter version
  removes that compatibility.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Preserved authenticated setup → Universal Social: passed.
- Universal → Mool → Pay: production Pay home opened directly: passed.
- Recharge, Bills, Scan Pay, Requests and Receipts render with complete
  customer wording, safe debit confirmation and persistent Pay navigation.
- Pending status action before the fix was captured, rebuilt and replayed.
- The fixed action is fully visible above the dock and reaches a
  bank-confirmed receipt.
- Evidence:
  - `artifacts/device/moolsocial-production-pay-home-device.png`
  - `artifacts/device/moolsocial-production-pay-recharge-device.png`
  - `artifacts/device/moolsocial-production-pay-bills-device.png`
  - `artifacts/device/moolsocial-production-pay-scan-device.png`
  - `artifacts/device/moolsocial-production-pay-requests-device.png`
  - `artifacts/device/moolsocial-production-pay-receipts-device.png`
  - `artifacts/device/moolsocial-production-pay-status-device.png`
  - `artifacts/device/moolsocial-production-pay-status-fixed-device.png`
  - `artifacts/device/moolsocial-production-pay-status-completed-device.png`

## Current gate

The Pay vertical slice is GO for continued production implementation against
deterministic gateway interfaces. RBI/UPI and BBPS provider approval, bank
callbacks and reconciliation, KYC/risk controls, live refunds/reversals,
PCI-compliant tokenization, production camera/QR validation and staffed
payment support remain external launch gates. The application does not claim
those live financial integrations are certified today.
