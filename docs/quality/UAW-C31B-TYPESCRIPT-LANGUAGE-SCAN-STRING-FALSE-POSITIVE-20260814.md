# C31B TypeScript language scan String false positive

Date: 2026-08-14
Registry ID: `REG-20260814-2130-C31B-TYPESCRIPT-LANGUAGE-SCAN-STRING-FALSE-POSITIVE`

The first expanded TypeScript language-boundary scan rejected valid JavaScript `String(...)` conversion. The token exists in both languages and was not evidence of a Dart syntax recurrence.

The corrected scan uses only unambiguous Dart-only constructs. The nonzero scan is not qualification evidence, and no backend execution or live write occurred.
