# C31B TypeScript Dart single accessor recurrence

Date: 2026-08-14
Registry ID: `REG-20260814-2128-C31B-TYPESCRIPT-DART-SINGLE-ACCESSOR-RECURRENCE`

The first C31B Firestore tests used Dart's `.single` collection accessor in three TypeScript assertions. Source review caught the recurrence before typecheck.

The correction uses exact indexed access and expands the permanent language-boundary review from constructors to the full added TypeScript block, including collection APIs. No backend execution, live Dev write or deployment occurred.
