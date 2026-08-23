# C31A Chat post-format patch context mismatch

Date: 2026-08-14
Registry ID: `REG-20260814-2125-C31A-CHAT-POST-FORMAT-PATCH-CONTEXT-MISMATCH`

The first null-aware syntax patch used the two-line source shape from before `dart format`. The formatter had condensed the conditional map entry to one line, so `apply_patch` rejected and made zero changes.

The retry enumerates and copies the exact current formatted line before patching. No runtime, backend execution, live data, build or device action occurred.
