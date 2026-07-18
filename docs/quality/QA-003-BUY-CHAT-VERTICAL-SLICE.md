# QA-003 — Buy and Chat production vertical slices

Date: 19 July 2026

## Scope

- Household catalogue, product, basket, delivery checkout and tracking
- Completed-order bill, rating and problem resolution
- Explicit store selection, collection readiness, protected code and receipt
- Chat inbox and people, business, order and support conversations
- Buy-to-Chat and Chat-to-Buy return context

## Black-box cycle 1

### Buy

- Dedicated scenarios: 9
- Passed: 9
- Failed after fixes: 0
- Covered: success, empty basket, invalid search, sold-out product, cancelled
  store choice, duplicate add, coupon empty/invalid/valid, payment failure,
  retry, delivery tracking, problem report and store collection.

### Chat

- Dedicated scenarios: 5
- Passed after exact defect replays: 5
- Covered: empty search, typed and voice search, filters, new-chat selection,
  unread state, reaction, reply/cancel, attachment, empty send, successful
  send, failed send/retry, calls, video, more actions, people modes, business
  modes, order/support context and compact-device controls.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Chat inbox could fail layout before a tap | The shared full-width button style was placed directly in a horizontal row | Applied a finite 72 × 48 minimum to the priority Reply action | Open Chat inbox → priority case renders → Reply remains tappable: passed |
| Two poll choices could not coexist | Keys were generated from only the first word, so both Tomorrow choices had the same identity | Generate keys from the complete option label | Chat → group → Poll → render all choices → choose Today evening: passed |
| Opening a thread could notify while routing was still building | `markRead` notified listeners synchronously from `initState` | Mark read after the first frame | Inbox → Home Basket → Back → Inbox → Back to Buy: passed |
| Voice search did not affect results and empty input gave no correction | The sheet discarded its local query | Return validated input to the inbox controller; show an empty-input error | Voice search → submit empty → correction → enter Home Basket → result opens: passed |
| Buy issue test expected the retired generic Chat demo | The completed-order action now correctly opens the production support thread | Updated the affected journey assertion to the production thread | Completed order → report problem → submit → Chat with case support: passed |

## Affected-journey rerun

- Buy dedicated suite plus Chat dedicated suite: 14/14 passed.
- Buy issue → Order Support: passed.
- Business quote → Buy catalogue: passed.
- Business payment → Pay entry: passed.
- Chat protected return → originating Buy catalogue: passed.

## Full regression

- Analyzer: no issues.
- Flutter application regression cycle 1: 52/52 passed.
- Physical-device discovery: a previously authenticated emulator account
  could leave the opening screen waiting indefinitely when the account
  bootstrap service was unreachable.
- Root cause: account bootstrap had no completion deadline.
- Fix: an eight-second account-bootstrap deadline now moves safely to the
  existing retry screen without changing local setup.
- Exact automated timeout replay: passed.
- Flutter application regression cycle 2 after the device fix: 53/53 passed.
- Analyzer after the device fix: no issues.
- Android debug APK: built successfully for `com.moolsocial.app`.

## Physical OPPO replay

- Device: OPPO CPH2375 over ADB.
- Clean install → opening → setup → Skip now → Mobile OTP: passed.
- Device discovery: the Firebase Auth emulator created the OTP, but the
  Android native callback timed out when the emulator host was looped through
  `127.0.0.1` and adb reverse.
- Root cause: this physical-device/native-SDK route was not reliable on the
  connected phone. The laptop and phone were already on the same local
  network.
- Fix: preserve emulator-host configuration as a build parameter and use the
  laptop LAN host for the device build. The emulator-only request adapter also
  reconciles a code already confirmed by the Auth emulator instead of showing
  a false failure while waiting for the Android callback.
- Exact replay with
  `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`: request code → emulator code
  visible → Verify → account bootstrap → Universal Social: passed.
- Device evidence:
  `artifacts/device/moolsocial-clean-install.png` and
  `artifacts/device/moolsocial-lan-verified.png`.
- Device discovery after Universal: the global Chat control still opened the
  retired generic Chat intent card.
- Fix: the global Chat control now opens the production Chat inbox and carries
  the exact originating route.
- Exact physical replay: Universal Social → Chat → production inbox with four
  conversation types: passed.
- Device evidence:
  `artifacts/device/moolsocial-production-chat-device.png`.
