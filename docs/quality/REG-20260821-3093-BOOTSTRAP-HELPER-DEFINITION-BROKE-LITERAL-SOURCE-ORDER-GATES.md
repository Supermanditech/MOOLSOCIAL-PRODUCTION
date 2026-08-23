# REG3093 — bootstrap helper definition broke literal source-order gates

- Date: 2026-08-21
- Status: registered before retry

The comprehensive platform test failed because it compared the first literal
`runApp(const ReleaseConfigurationFailureApp())` occurrence with
`Firebase.initializeApp`. After refactoring failure rendering into a helper,
the literal lives in a helper definition below Firebase even though the
release-configuration precheck calls the helper before Firebase. Analyzer was
clean; no build or device action followed.

The C30W source gate uses the same stale literal-order assumption.

Prevention: assert the precheck helper call and the named bootstrap `runApp`
both precede Firebase initialization, while separately asserting the helper
owns the failure `runApp`. Never infer execution order from a helper
definition's source position.
