# QA-002 independent clean-state final regression

Result: **PASS for the Universal production-demo scope**

Recommendation: **GO for founder review; NO-GO for public production release**

Date: 19 July 2026 (IST)

## Independent clean cycle

QA-002 did not reuse the QA-001 build or app state.

1. Removed Flutter build output and generated tool state.
2. Resolved dependencies again from `pubspec.lock`.
3. Re-ran formatting, static analysis and the visible-copy gate.
4. Re-ran the complete automated application regression.
5. Re-compared every visual baseline.
6. Rebuilt the Android APK from the clean tree.
7. Deleted local authentication accounts.
8. Uninstalled `com.moolsocial.app` from the phone.
9. Installed and opened the newly built APK.
10. Repeated the device journey from setup.

## Final automated results

| Gate | Result |
| --- | --- |
| Dart formatting | PASS |
| Flutter static analysis with fatal infos | PASS, no issues |
| User-facing production-copy gate | PASS |
| Complete Flutter suite | PASS, 37/37 |
| Visual baselines | PASS, 4/4 |
| Android/iOS package and permission declarations | PASS, 2/2 |
| Android clean build | PASS |
| Final post-fix affected journey | PASS, 12/12 |
| Final post-fix complete application regression | PASS, 37/37 |
| Final post-fix visual regression | PASS, 4/4 |

Final review artifact:

- Package: `com.moolsocial.app`
- Label: `MoolSocial`
- Minimum Android SDK: `24`
- Target Android SDK: `36`
- APK:
  `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- SHA-256:
  `E43609110713DD14C32869927B2B0F5FE65088DD38366B2A07705842A48ADDC4`

## Screen-by-screen and nested-tap coverage

| Screen / surface | First taps | Nested taps and end intent | Result |
| --- | --- | --- | --- |
| Boot | automatic open, failure | Try again, safe destination restore | PASS |
| Setup | English, हिन्दी, current location, manual area, skip | allow, deny, failure, suggestion, save, cancel | PASS |
| Sign in | Mobile OTP | invalid number, request, request failure, retry, change method | PASS |
| Verify OTP | six digits, Verify | invalid, auto local code, resend countdown, change method | PASS |
| Universal header | Profile, Search, Scan, Voice | empty, exact result, native permission allow/deny, Settings/typed recovery | PASS |
| Mool navigation | Social, Buy, Eat, Ride, Book, Pay, Work | palette open/close, selection, active state, return | PASS |
| Social / Shorts | open, swipe | Follow, Like, Comments, Share, Remix, Save, More | PASS |
| Social / Videos | video, YouTube connection | Like, Comments, Share, Follow, Save, More | PASS |
| Social / Feed | post | Like, Reply, Repost, Share, Save, Profile | PASS |
| Social / Create | Text/Post, Upload | empty, invalid, review, Post, Help, cancel | PASS |
| Buy | Grocery, Categories, Medicine, Basket | all options, review, completion, cancel | PASS |
| Eat | Order Food, Book Table, Tiffin | all options, review, completion, cancel | PASS |
| Ride | Bike, Auto, Cab | all options, review, completion, cancel | PASS |
| Book | Get It Done, Doctor, Salon | all options, review, completion, cancel | PASS |
| Pay | Recharge, Bills, Scan & Pay, Receipts | all options, review, completion, cancel | PASS |
| Work | Earn Today, Delivery, Onboard, Verify, Workspace | all options, review, completion, cancel | PASS |
| Chat | People, Business, Orders, Support | all options, review, completion, cancel, Back to previous action | PASS |
| Profile | Language, area, workspaces, sign out | persist, rollback, cancel, confirm | PASS |
| Accessibility | compact screen, 140% text, Reduce Motion, semantics | 44-pixel targets, no overflow, named controls | PASS |

There are 27 non-Social focused sub-actions. Every option of every sub-action
was tapped through choice, review and visible completion. Immediate Social
actions change state on the same screen; composer/share/profile actions reveal
and complete their own required interaction.

## QA-002 physical-device results

- Device: OPPO CPH2375.
- Android: 13.
- ADB serial: `2b3e0f71`.
- Clean install: PASS.
- Setup language toggle and Skip alternative: PASS.
- Mobile OTP through local Firebase emulator: PASS.
- Universal restore: PASS.
- Native camera permission and live scanner surface: PASS.
- Native microphone permission and live listening state: PASS.
- Search no-results recovery: PASS.
- Profile open and area changed to Ratanada: PASS.
- Social, Buy, Eat, Ride, Book, Pay, Work and Chat destinations: PASS.
- Chat direct return to Work: PASS.

Device evidence:

- `OUTCOME/qa-002-device-20260719/camera-scanner.png`
- `OUTCOME/qa-002-device-20260719/camera-scanner.xml`
- `OUTCOME/qa-002-device-20260719/voice-listening.png`
- `OUTCOME/qa-002-device-20260719/voice-listening.xml`
- `OUTCOME/qa-002-device-20260719/profile-open.png`
- `OUTCOME/qa-002-device-20260719/profile-open.xml`
- `OUTCOME/qa-002-device-20260719/main-social.xml`
- `OUTCOME/qa-002-device-20260719/main-buy.xml`
- `OUTCOME/qa-002-device-20260719/main-eat.xml`
- `OUTCOME/qa-002-device-20260719/main-ride.xml`
- `OUTCOME/qa-002-device-20260719/main-book.xml`
- `OUTCOME/qa-002-device-20260719/main-pay.xml`
- `OUTCOME/qa-002-device-20260719/main-work.xml`
- `OUTCOME/qa-002-device-20260719/main-chat.xml`
- `OUTCOME/qa-002-device-20260719/chat-back-to-work.xml`

## Defect discovered during QA-002

Ticket: `FIX-002-A`

Original exact failure:

1. Install the clean QA-002 APK.
2. Complete setup and sign in.
3. Inspect the top-right tappable control with Android accessibility.
4. The control had no accessible name.

Root cause:

The profile icon used an `InkWell` and visual icon but no explicit semantic
label.

Fix:

- Added a button semantic named **Open your account**.
- Excluded the decorative icon from producing a competing label.
- Added a test that requires the label, button flag, focus action and tap
  action.

Lifecycle completed:

`discover -> reproduce -> XML evidence -> ticket -> root cause -> fix ->
affected test -> full test -> visual regression -> rebuild -> redeploy ->
exact Android replay -> open account sheet`

Exact replay result:

- Android exposes `content-desc="Open your account"`.
- Tapping it opens **Your account**.
- Affected journey: PASS, 12/12.
- Full regression: PASS, 37/37.
- Visual regression: PASS, 4/4.

## Remaining real provider and release blockers

- Google Cloud billing for the new MoolSocial organisation is not active.
- Authentication and SQL Connect therefore use local emulators in this review
  build.
- Google/Apple/social provider sign-in, production SMS, live Cloud SQL, live
  Functions, payments, fulfilment, maps, YouTube account connection and other
  provider operations require approved projects and credentials.
- Commerce/service completion surfaces demonstrate the required contract; they
  do not fabricate a live transaction.
- Android Play release signing and protected release configuration are not yet
  provisioned.
- iOS requires a macOS/Xcode build, Apple signing and physical iPhone replay;
  Windows can verify source configuration but cannot produce an iOS binary.
- हिन्दी selection is persisted, but complete app-wide Hindi localization is
  not yet shipped.
- Third-party plugins currently emit Flutter's future Kotlin built-in migration
  warning. The build passes today; plugin upgrades must be tracked before a
  later Flutter SDK upgrade.

## Evidence-based decision

**GO** to review the current Universal journey on the connected Android phone
and to begin the next end-to-end production journey from this verified base.

**NO-GO** for public production release until the cloud/provider, signing, iOS
and complete Hindi-localization blockers above are closed and replayed in
staging.
