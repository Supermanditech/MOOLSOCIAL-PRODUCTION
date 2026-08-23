# C30F OPPO device rejection

State: `DEVICE_GATE_REJECTED_R60_37_PRESERVED`.

- r60.37 was built exactly once and installed exactly once in place.
- Installed APK SHA-256: `09277766FC5700C886DCA4262E98611BCC299CBE3404227DB02579058A966A6F`.
- Package/version/signature/zip alignment and first native bounds passed.
- Native footer minimum: 54×44 logical pixels before interaction.
- Full-page Search loaded real `India news` results without the removed popup or
  commentary; the top YouTube logo was absent and content attribution remained
  clickable.
- Device rejection: Watch opened from Search exported the Back action as
  `Back to YouTube Home`, but tapping it restored the preserved Search results.
  The native accessibility label therefore contradicted the actual destination.

r60.37 remains installed and preserved. No uninstall, data clear, downgrade,
second build, second install, deployment, commit or push occurred. A separately
registered source successor is required before another candidate.
