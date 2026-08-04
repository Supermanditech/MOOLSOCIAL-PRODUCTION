# Buy R56/R57 OPPO founder walkthrough

Date: 3 August 2026

Installed review identity:

- OPPO CPH2375 `2b3e0f71`;
- package `com.moolsocial.app`;
- profile `1.0.0-r56.10` (`2026080313`); and
- device-side APK SHA-256
  `B86009EFD9A74E7AB3BC7FF20FC3690C78491F9E7D8832CF41ABA5AB2D7F1711`.

The installed checksum was reverified at review preparation. Unlock the phone
normally; no rebuild/reinstall is required. Review and decide one owner at a
time. An approval is visual/interaction approval only and never activates a
backend, provider, payment, geocode, upload or live result.

## 1. R57.1 search relevance

1. In Shop Search enter `tomatos`: Fresh tomatoes should lead and tomato
   ketchup may appear only as the bounded second close-title match.
2. Enter correct `tomato`: direct results must lead and fuzzy neighbours must
   not be appended when direct matches exist.
3. Enter `frsh tomatos`: only Fresh tomatoes should remain.
4. `mlk` and `s-tomto` must stay empty because short tokens and IDs are not
   fuzzed.
5. `w-tomato` must not leak into Shop; `paracetmol` resolves only the current
   Medicine Paracetamol item; `balajii` resolves current seller text in Shop.

Decision: R57.1 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 2. R56.1 Saved-clear confirmation

1. Save one Medicine product and keep one Cart item; open the Saved shelf.
2. Tap Clear list and judge finite arrival, compact geometry and Medicine copy.
3. Keep saved, Back, outside tap, Close and drag must be non-mutating.
4. Clear list must mutate Saved only after reverse; Cart remains unchanged.

Decision: R56.1 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 3. R56.2 scanner manual-code sheet

1. Open Scanner -> Enter code. Judge compact white/navy hierarchy, restrained
   saffron cue and visible Cancel/Find product actions.
2. Focus Product code: the label persists, keyboard causes no geometry jump,
   first Back closes IME and second Back closes the sheet.
3. Cancel, outside tap and drag each return to the scanner.
4. Under Remove animations, arrival/reverse become immediate without changing
   geometry or function.

Decision: R56.2 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 4. R56.6 catalogue tools and filters

1. On Shop tap the top-right tools control: one sheet must contain tools and
   filters, with no intermediate popup.
2. Back preserves the current filter. Choose Fast delivery: reverse completes
   before the catalogue/header changes.
3. On Medicine, Prescriptions opens the existing prescription surface only
   after reverse.
4. On Wholesale, Manufacturer direct remains reachable without clipping.

Decision: R56.6 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 5. R56.7 payment-choice presentation

1. Account/DC -> Payment: UPI, Bank transfer and Purchase order are the only
   local choices; the sheet explicitly says no payment starts.
2. Back preserves selection. Bank transfer reverses first, then appears once
   in Account.
3. Wholesale Cart -> Review order -> Payment -> Purchase order updates the
   local choice without claiming eligibility, provider or payment success.
4. Remove animations resolves immediately with identical semantics.

Decision: R56.7 visual/interaction only `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 6. R56.8 prescription sheet

1. Medicine -> Prescription centre must say Add/use, never Upload.
2. Back/Close make no prescription change.
3. Meera/Arvind/Add each reverse first and update only the existing local
   matched/count owner, without upload, validity or pharmacist claims.
4. Home/resume retains the sheet; reduced motion is immediate/static.

Decision: R56.8 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 7. R56.9 address choice

1. Medicine -> DC -> Edit: judge finite arrival and stable geometry.
2. Add address must remain fully above the navigation edge; qualified native
   bounds are `[32,1352][688,1440]`.
3. Work/Home change only after reverse. Back/Close preserve selection.
4. Request address and Add address remain reachable. Repeat from Checkout Edit.

Decision: R56.9 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## 8. R56.10 request/add-address forms

1. Location -> Delivery addresses -> Request address: judge the styled sheet,
   optional recipient field, three existing share choices and Enter address.
2. First Back dismisses the keyboard; second Back returns to address choice.
3. Add address: Current/Map/Google show honest unavailable recovery and do not
   manufacture an address.
4. Focus/scroll all fields; Save and deliver here stays fully visible.
5. Home/resume retains the form; process recreation returns safely to Buy root
   without claiming a save.

Decision: R56.10 `APPROVE` / `CHANGE REQUEST` / `DEFER`.

## Excluded from approval

- R56.5 is stopped/device rejected and not review eligible.
- R51 FIX16 is deferred and not approved.
- Loading/shimmer/refresh, video/campaign, live/provider, AI-profiled and other
  dependency-held effects remain open until truthful owners/assets exist.
- Every new UI ticket must apply
  `config/buy-premium-motion-policy.json` before its first runtime write and
  document reduced motion, responsive behavior and OPPO qualification.
