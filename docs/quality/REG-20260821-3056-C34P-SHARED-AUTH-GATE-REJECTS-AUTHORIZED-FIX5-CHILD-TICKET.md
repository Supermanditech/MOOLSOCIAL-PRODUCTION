# REG-20260821-3056 C34P shared-auth gate rejects authorized FIX5 child ticket

## Observed failure

After the affected authentication suites passed, the shared C34P gate rejected
the current MVP state because it selects the authorized FIX5 child ticket rather
than the C34P parent literally. No alternate gate was run before registration.

## Root cause

The shared parent contract gate contains a stale exact-ticket assertion and
does not recognize current authorized descendants that inherit the same parent
authentication contract.

## Impact

- whole-mobile analysis, focused backend and affected mobile tests remain green;
- no build, Play, OPPO, provider or device action occurred;
- no shared-gateway result is claimed from the rejected run.

## Prevention and authorized continuation

Inspect the gate and ticket lineage. Accept only the exact C34P parent or an
explicit allowlist of its authorized auth child tickets; retain every source,
method-count and fail-closed assertion. Add a negative fixture for unrelated
ticket selection before retry.
