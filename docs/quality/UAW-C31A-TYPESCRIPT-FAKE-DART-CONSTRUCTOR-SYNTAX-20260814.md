# C31A TypeScript fake Dart constructor syntax

Date: 2026-08-14
Registry ID: `REG-20260814-2127-C31A-TYPESCRIPT-FAKE-DART-CONSTRUCTOR-SYNTAX`

The first draft of the C31A Firestore repository test fake used Dart constructor shorthand and initializer-list syntax inside a TypeScript file. Source review caught the error before any typecheck or test retry.

The correction declares TypeScript fields explicitly and assigns them inside standard constructor bodies. No backend execution, live Dev write or deployment occurred.
