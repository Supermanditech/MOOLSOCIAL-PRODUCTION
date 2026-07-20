# First-open real-user state matrix

Status: **mandatory release gate**

Owner confirmation: 20 July 2026

This matrix prevents a clean-install-only test from being reported as proof of
the real first-open journey. It applies to the production app, HTML-to-Flutter
acceptance work and every physical-device replay.

## Strict machine rule

The required sequence is:

`Screen 01 → Screen 02 → Screen 03 → Universal`

The machine must enforce these transitions:

| Machine condition | Required result |
| --- | --- |
| No completion record exists for the currently required Screen 02 version | Screen 01 must hand off to Screen 02 |
| Screen 01 is visible and the app becomes inactive, paused, hidden, locked or interrupted by a call | Cancel the pending handoff; on resume, show Screen 01 for a new uninterrupted foreground interval |
| The app process is killed or force-stopped during Screen 01 | A new open starts at Screen 01 and then reaches Screen 02 |
| Screen 02 is visible but neither completion action has been tapped | Screen 02 remains incomplete; backgrounding, calls, process death, permission callbacks and location callbacks cannot complete it |
| Android permission or Location Settings temporarily covers Screen 02 | Return to Screen 02 and show resolved, denied, services-off or retry state; never jump to Screen 03 |
| The user taps `Continue` after a resolved location | Persist completion for the current Screen 02 version and move to Screen 03 |
| The user taps `Continue for now` | Persist an explicit skip for the current Screen 02 version and move to Screen 03 |
| An older Screen 02 version was completed | Require the current Screen 02 once; an older completion record cannot bypass it |
| Current Screen 02 was explicitly completed and the user is signed out | A later app open may move from Screen 01 to Screen 03 |
| Current Screen 02 was explicitly completed and the user is signed in | A later app open may move from Screen 01 to Universal or a preserved safe route |

No timer, automatic location result, operating-system callback, lifecycle
event, test fixture or prior candidate version may write the current Screen 02
completion record.

The completion version is a dedicated monotonic gate, not the version of the
last data write. Saving language, location results, authentication state,
pending deep links, account preferences or any other journey data must preserve
the previously completed Screen 02 version. Only the explicit Screen 02
`Continue` and `Continue for now` actions may advance it to the currently
required version. A candidate that stamps the current version during any other
write fails this gate.

## Exact-candidate proof protocol

Do not report a physical-device pass until the device is proven to be running
the exact APK under review:

1. Record the branch, source commit, dirty-file list and candidate identifier.
2. Uninstall the package and verify `pm path` reports no installed package.
3. Build one APK from the recorded source state; record its SHA-256 checksum.
4. Install that APK without Android Studio, VS Code, hot reload or a debug
   session silently substituting another build.
5. Pull or stream-hash the installed base APK and prove that its checksum
   matches the reviewed APK.
6. Before first launch, prove that the app has no Screen 02 completion record.
7. Launch through the same Android launcher intent used by a customer.
8. Capture the visible screen and startup-decision log before handoff, near the
   end of the Screen 01 interval and after handoff.
9. After every interruption row, capture both the visible route and the saved
   completion version.
10. If the founder reports a different result, the founder result reopens the
    defect. A prior screenshot, automated test or developer replay cannot
    overrule it.

A run from an unidentified APK, an already-running Flutter process, a
hot-reloaded process or unverified app data is not physical-device evidence.

## Mandatory physical-device circumstances

Each first-open candidate must be replayed on the connected production-class
Android phone under all applicable circumstances:

1. fresh install with no app data;
2. update over the preceding candidate with its saved data retained;
3. app switch during Screen 01;
4. incoming-call-equivalent inactive/pause during Screen 01;
5. screen lock and unlock during Screen 01;
6. force-stop or process death during Screen 01;
7. app switch during Screen 02 before any action;
8. process death during Screen 02 before completion;
9. Android location permission allowed, denied and denied permanently;
10. Location Services off, open settings, return without enabling, then enable
    and return;
11. location resolution loading, unavailable, retry and resolved;
12. explicit `Continue for now`;
13. explicit resolved-location `Continue`;
14. relaunch after each completion choice;
15. authenticated and signed-out returning-user states.
16. mobile OTP and email OTP are requested and verified independently; a pass
    in one channel cannot stand in for the other;
17. the ADB USB transport is reconnected (clearing volatile reverse mappings)
    before a mobile OTP replay while normal device connectivity remains
    available; the exact APK must still have a verified route to its review
    Auth service and must not falsely label the customer offline.

The replay records the state before interruption, the interruption, the state
immediately after return and the next persisted route. A screenshot from a
single clean install is insufficient.

## Candidate handoff rule

Before handing the connected phone to the founder for a Screen 02 approval
decision:

- install the exact candidate being reviewed;
- prove the installed APK checksum matches the candidate APK;
- retain realistic previous-version data for the upgrade replay;
- complete the upgrade replay;
- finish with Screen 02 **incomplete and visible**;
- confirm the saved store does not contain completion for the current Screen 02
  version;
- never leave the founder's phone at Screen 03 as the result of an internal
  Screen 02 test.

Founder approval, reference freezing and branch checkpointing remain separate
actions. A passing matrix does not itself mark Screen 02 accepted.
