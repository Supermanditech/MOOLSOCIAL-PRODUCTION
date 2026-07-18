# QA-001 first black-box audit evidence

Result: **PASS for the Universal production-demo scope**

Date: 19 July 2026 (IST)

## Clean state

- Flutter dependencies resolved from the checked-in lock file.
- Firebase Authentication and SQL Connect local emulators listening on ports
  `9099` and `9399`.
- Local emulator accounts deleted.
- Existing `com.moolsocial.app` installation removed from the phone.
- Newly compiled APK installed before the device replay.

## Automated screen and intent coverage

- Flutter static analysis with fatal infos: **PASS, no issues**.
- User-facing production-copy gate: **PASS**.
- Full Flutter suite: **PASS, 37/37**.
- Golden baselines: **PASS, 4/4** at `412 x 915` and `360 x 800`.
- Android/iOS package and permission configuration: **PASS, 2/2**.
- Android native build: **PASS**.
- APK package: `com.moolsocial.app`.
- APK label: `MoolSocial`.
- APK target SDK: `36`.
- APK SHA-256:
  `4B6985DAE41F774217AD75F7513EB8D6E522A300F77C0B38278BCFF35D2313BB`.

The automated interaction suite covers:

- Entry, setup, permission denial, manual area, sign-in, OTP verification,
  session restore, sign-out cancellation and confirmed sign-out.
- Universal Search, exact sub-action results, empty results, Scan, Voice,
  Profile, Chat return and protected deep links.
- All seven Mool destinations and their return path.
- All 27 Buy, Eat, Ride, Book, Pay, Work and Chat sub-actions.
- Every option branch for each of the 27 sub-actions.
- Social Shorts, Videos, Feed and Create.
- Every reachable Social card and action-rail control, including Follow, Like,
  Comments, Share, Remix, Save, More, Reply, Repost, Profile, Post, Upload and
  Help.
- Immediate-state, choice, review, completion, empty, invalid, unselected,
  cancelled and recovery outcomes.
- Compact phone, 140 percent text scale, Reduce Motion and 44-pixel tap targets.

## Physical-device replay

- Device: OPPO CPH2375.
- Android: 13.
- ADB serial: `2b3e0f71`.

Exact replay:

1. Clean install and launch.
2. Tap **Use current location**.
3. Deny Android location permission.
4. Verify setup remains visible and offers manual-area recovery.
5. Tap **Set manually**, choose **Sardarpura**, and continue.
6. Choose **Mobile OTP**, enter the test number and continue.
7. Verify the local OTP and open Universal.
8. Tap **Scan**, choose **Scan with camera**, deny camera permission and verify
   the Settings/keyboard recovery.
9. Choose **Use keyboard instead**, enter a code and verify **Pay / Scan & Pay**
   opens.
10. Tap **Voice**, choose **Start listening**, deny microphone permission and
    verify the Settings/keyboard recovery.
11. Choose **Use keyboard instead**, enter `salon` and verify **Book / Salon**
    opens.
12. Choose a salon service, review it, request available times and verify the
    completion state.
13. Open Mool, choose **Work** and verify the funded-work surface opens.
14. Open Chat and tap **Back to Work**.
15. Verify the funded-work surface is restored.

All 15 physical-device steps passed.

Evidence:

- `OUTCOME/qa-001-device-20260719/work-return.png`
- `OUTCOME/qa-001-device-20260719/work-return.xml`

## FIX-001 defects and exact failed-tap replays

| Defect | Original failure | Root cause | Fix | Exact replay |
| --- | --- | --- | --- | --- |
| `FIX-001-A` | Close Search/Scan/Voice sheet after typing; disposed-controller exception appeared | A locally owned text controller was disposed before the animated sheet finished | Moved controller ownership to the sheet state lifecycle | **PASS** |
| `FIX-001-B` | Edit Profile area and close; disposed-controller exception appeared | Profile-area controller had the same premature lifecycle | Replaced it with form-owned state | **PASS** |
| `FIX-001-C` | Open Profile or area with keyboard visible; lower actions overflowed | Fixed-height sheet did not account for the keyboard inset | Added scrolling and keyboard-aware padding | **PASS** |
| `FIX-001-D` | Open Social/Chat/Mool on a 360 x 800 phone at 140 percent text; labels overflowed | Fixed card/dock dimensions could not absorb scaled labels | Added responsive height and fitted label layouts | **PASS** |
| `FIX-001-E` | Deny location; app continued as if area setup had succeeded | Denial result shared the success continuation path | Kept setup open and showed manual/skip recovery | **PASS on OPPO** |
| `FIX-001-F` | Search for a sub-action such as Salon; only main actions were searchable | Search index contained only the eight primary destinations | Indexed every exact sub-action and added a no-results recovery state | **PASS on OPPO** |
| `FIX-001-G` | Tap Social Comments or Share; only a generic acknowledgement appeared | Action metadata did not distinguish immediate, input and choice intents | Added composer, option selection, review and explicit completion states | **PASS** |
| `FIX-001-H` | Tap Scan or Voice; only typed simulation was possible | Native camera/speech adapters and permissions were absent | Added native scanner and speech integrations with denial recovery and typed alternatives | **PASS on OPPO** |

For every defect, the affected journey and the complete 37-test application
suite passed after the exact replay.

## External constraints

- Authentication and SQL Connect currently use local emulators because the new
  Google Cloud billing account is not active.
- Production database, live payment, provider OAuth, SMS delivery, order
  fulfilment and third-party service outcomes cannot be truthfully marked as
  production-live until their provider projects and credentials exist.
- iOS compiles cannot be executed on Windows. The iOS permission declarations
  are automated, but a macOS/Xcode build and a physical iPhone replay remain a
  release blocker.
- Android release signing is not yet provisioned; this evidence uses a debug
  review APK.
