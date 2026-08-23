# C30I preselection — Android root focus edge suppression

## Founder finding

C30H r60.38 displays green vertical lines on both sides of YouTube Home after a raw hardware-keyboard Enter event. The lines are not approved Social decoration.

## Bounded owner and duplicate audit

- Stable Home before the key event has no green edge paint.
- The same installed bytes reproduce the green edge immediately after `KEYCODE_ENTER`.
- A process-only restart clears it; no reinstall or data mutation is involved.
- Android layout, touch, pointer, accessibility and HWUI debug overlays are disabled.
- No existing app resource owns `android:defaultFocusHighlightEnabled` and no existing focused resource test covers it.
- Android's official View contract defines `android:defaultFocusHighlightEnabled` as the fallback highlight for a focused View without a focused background; the API is available from level 26.

## Minimum production correction

Add day/night API-26 `NormalTheme` overrides that retain the exact current parent and window background while setting `android:defaultFocusHighlightEnabled` to `false`. This prevents the Android native fallback from framing the whole Flutter root. Flutter widgets continue to own keyboard focus visuals, semantics and actions.

## Locks

- Source and focused test work only under C30I.
- C30H r60.38 remains installed, rejected and preserved.
- No APK build/install and no backend/provider/Firebase/Production deployment.
- A separately registered successor is required for native proof.
