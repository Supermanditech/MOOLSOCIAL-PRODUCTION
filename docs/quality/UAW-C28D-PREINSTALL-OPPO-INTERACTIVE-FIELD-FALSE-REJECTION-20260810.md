# C28D OPPO interactive-field false rejection

- Date: 2026-08-10
- Phase: fresh preinstall device gate
- Initial rejection: the custom audit required literal `mInteractive=true` in
  `dumpsys power`, a field this OPPO Android 13 build does not emit.
- Correct readback: `mWakefulness=Awake`,
  `mHalInteractiveModeEnabled=true`, `mHoldingDisplaySuspendBlocker=true`, ADB
  state `device`, and keyguard `showing=false`.
- Product/device effect: none; install authority remained closed, install count
  remained zero and r60.26 checksum identity stayed unchanged.
- Root cause: a generic power-field assumption was used instead of the actual
  CPH2375 power-service vocabulary.
- Prevention: on this founder device require Awake plus HAL interactive plus
  display suspend blocker and unlocked keyguard. Do not wake, unlock or bypass a
  genuinely noninteractive device.
