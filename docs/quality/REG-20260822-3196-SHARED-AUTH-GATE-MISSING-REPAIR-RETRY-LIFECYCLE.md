# REG-20260822-3196 — Shared-auth gate missing repair-retry lifecycle

## Incident

The final shared public-authentication gate rejected the fresh authorized FIX8
repair-retry state because its successor binding ended at the repair-qualified
authority-pending lifecycle.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The action-time retry lifecycle was added to the FIX5 release gate without
first extending every inherited shared-auth gate across that exact transition.

## Permanent prevention

Before sealing a retry, replay each inherited auth gate against repair-pending
and fresh retry-authorized state, add only the exact held-authority transition,
and create a distinct build-input seal after every executable gate change.
