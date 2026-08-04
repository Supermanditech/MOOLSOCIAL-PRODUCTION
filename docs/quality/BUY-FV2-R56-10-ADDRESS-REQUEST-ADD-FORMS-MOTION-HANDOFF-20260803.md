# Buy Flutter V2 R56.10 address request/add forms motion handoff

Date: 3 August 2026

State: **FIX2 TECHNICALLY/DEVICE QUALIFIED — FOUNDER REVIEW PENDING**

## Qualified candidate

`BUY-R56-ADDRESS-REQUEST-ADD-FORMS-MOTION-FIX2`, profile `1.0.0-r56.10`
(`2026080313`), owns only the existing request-address and Add-address form
family. The approved FIX1 runtime remains exact: one finite 280 ms arrival/220
ms reverse, immediate/static reduced motion, stable white/navy geometry,
keyboard-safe scroll/actions, explicit close/Back recovery and form results
owned only by the existing local session.

Exact app/test source is 2,416 files at SHA-256
`B6E29743BB17F54872E86E9FD2EDAF99E6061E4153A8C6EABDC1F4CD3FDBE743`.
The only FIX2 source delta is a deterministic focused test; no application
runtime or pixel changed. The wrapper-built profile APK and checksum-matched
OPPO installed pull are 134,000,969 bytes at SHA-256
`B86009EFD9A74E7AB3BC7FF20FC3690C78491F9E7D8832CF41ABA5AB2D7F1711`.

## Native accessibility disposition

FIX1 was conservatively device rejected because generic UIAutomator XML marked
the edit fields `NAF=true`. That serializer omits the Android 13
`AccessibilityNodeInfo.hintText` property. The candidate-specific native API-33
instrumentation probe now proves that the real OPPO nodes already expose:

- request: `Recipient name or phone (optional)`;
- Add: `Recipient name`, `Recipient phone`,
  `House, street and full address`, `PIN code`, `Area or locality` and
  `Landmark`; and
- editable/focusable state plus `ACTION_SET_TEXT` after focus.

FIX1 evidence remains preserved. No duplicate semantic owner, proxy text or
synthetic form value was added because that would degrade the correct native
field contract.

## Qualification

Eleven active focused checks plus one capture skip, the 31-active combined
suite plus three skips, eight hash-matched normal/reduced/320 px at 140% and
Android/iOS captures, full analysis, two unchanged-source Buy regressions at
289 active plus 15 intentional skips, every release/protected gate, APK
identity/signature, install/pull checksum, native request/Add accessibility,
keyboard/focus/Back, hot resume, process recreation, honest provider failure,
clean failure scan and warmed profile trace pass.

The trace covers 99 joined frames at presentation p95 29.569 ms; three frames
(3.03%) exceed 33 ms, none exceeds 100 ms, maximum is 47.495 ms and no
shader/compile event occurs. The Add bottom action is fully reachable at
`[32,1352][688,1440]` inside the 1,442-pixel application viewport.

## Truth and protected boundaries

Current-location recovery states only that the provider is not connected. No
geocode, serviceability, address validation/persistence, remote save, payment,
order or backend result is invented. R43/R45-R48/R52.1/R53/R54/R55 and the
qualified earlier R56 families remain exact. PAY-001-PAY-012 and
B2B-001-B2B-010 remain separately registered foundation work.

Technical/device qualification is not founder approval. Exact evidence:
`artifacts/quality/buy-address-request-add-forms-motion-r56-10-fix2-20260803-117`.

## Founder observation points

1. From a Buy root, tap the location control, open Delivery addresses and
   choose Request address.
2. Observe the styled sheet, optional recipient field, three existing sharing
   choices and Enter address recovery.
3. Focus the field; first Back dismisses the keyboard and the next Back returns
   to address choice.
4. Choose Add address; Current location/Map/Google recovery must show an honest
   unavailable notice and must not manufacture an address.
5. Focus and scroll the form; the full-width Save action must remain completely
   visible and reachable.
6. Home/resume must retain the sheet. Process recreation must return safely to
   Buy root without claiming a save or provider result.

