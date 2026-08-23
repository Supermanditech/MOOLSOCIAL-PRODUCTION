# C30T cursor misclassified as keyboard-open

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: non-writing Create-format journey inventory

The post-picker Image composer evidence displayed a text cursor in the caption field but did not display the Android keyboard. A subsequent step inferred keyboard-open and sent one Back action. That action left MoolSocial and returned to the existing Google Play app-detail screen. The postcondition correctly could not find `Close composer`; its failure message also repeated the compressed `throw"..."` tokenization error.

No uninstall, data clear, downgrade, content write, backend write, build, upload or install occurred. Recovery is restricted to proving the exact Play Store app-detail activity and exactly one enabled semantic `Open` target, tapping it once, and recapturing MoolSocial. No Back action may be used for keyboard dismissal unless the keyboard is visually or structurally proven in the same atomic state.
