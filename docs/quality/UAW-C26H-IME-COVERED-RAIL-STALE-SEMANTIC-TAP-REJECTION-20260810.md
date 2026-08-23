# C26H IME-covered rail stale-semantic tap rejection

- Observed: the Social Create state opened Gboard (`mInputShown=true`, 598px IME inset). Flutter accessibility continued to expose the navigation rail behind the IME, so an exact semantic-center tap landed on the keyboard and could not open Mool.
- Root cause: the semantic-tap evidence driver trusted application accessibility bounds without first rejecting an active system input-method overlay.
- Classification: device evidence-driving defect. The already captured Create screenshot truthfully preserves the visible keyboard; the rejected switcher attempts created no screenshot.
- Permanent prevention: the semantic-tap owner queries `dumpsys input_method` immediately before resolving/tapping and rejects whenever `mInputShown=true`. Device journeys dismiss a visible IME with one normal system Back, then prove the exact route/selected state remains before invoking navigation semantics.
