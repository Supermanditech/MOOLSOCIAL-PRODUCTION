# C30T Create picker-test missing-Scaffold rejection — 2026-08-13

## Rejection

The isolated picker-failure widget test mounted the Create workbench directly
under `MaterialApp`. Its production message helper uses `ScaffoldMessenger`, but
the harness omitted the `Scaffold` that the real Social screen always owns, so
the test asserted before it could verify recovery copy.

## Prevention

The retry wraps the workbench in a production-equivalent `Scaffold`. Release
configuration was immediately restored after the failed Flutter run: the exact
15-plugin registrant is present, `IntegrationTestPlugin` is absent and no APK
exists. No provider, Play, OPPO, Hosting or communication action occurred.
