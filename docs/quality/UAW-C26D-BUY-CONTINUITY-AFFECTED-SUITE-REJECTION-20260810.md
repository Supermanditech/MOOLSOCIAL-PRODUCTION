# C26D Buy continuity affected-suite rejection

## Observation

The combined C26D affected suite reported one Medicine/chooser visibility failure and one account-hub assertion failure. The combined output was truncated.

## Investigation rule

- Preserve the runtime until each named test is isolated.
- Inspect current Buy keys and route state before changing any expectation.
- Treat an overlay that removes or replaces destination content as a material defect.
- Treat an obsolete private presentation key as a test migration only after accepted current behavior is proven.

## Prevention gate

The C26D integration gate and focused real-route test must prove destination content remains mounted under the embedded switcher.

## Resolution state

Resolved. The complete Buy continuity file was rerun in isolation after the C26 Back fix and current test migrations: all 13 tests passed, including exact Medicine state, nested Account survival, root exit, persisted route, search/internal Back and connected Social return. No Buy runtime or business-content owner was changed. The file is restored to the C26G sealed host suite rather than omitted.
