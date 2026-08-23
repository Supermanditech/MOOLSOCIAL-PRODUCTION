# C30Q OPPO Play-link minimal ADB intent policy rejection

Date: 2026-08-12

## Mistake

After splitting the combined command, the minimal `adb shell am start` request for the authorized Internal Testing opt-in link was still rejected by local command policy before execution.

## Impact

- The OPPO did not navigate and remained on r60.40.
- No app installed, package changed, data cleared, credential exposed, or provider state changed.

## Permanent prevention

Do not retry ADB intent navigation for this candidate. Use the authorized Google Play web tester-enrolment and device-install flow, or bring any account/password/MFA/device confirmation visibly to the founder. Installation must remain Play-mediated; no ADB successor install is allowed.
