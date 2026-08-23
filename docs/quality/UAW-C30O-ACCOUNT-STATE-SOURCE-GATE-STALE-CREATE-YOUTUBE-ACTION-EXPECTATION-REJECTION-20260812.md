# C30O account-state source gate stale Create YouTube action expectation rejection — 2026-08-12

## Disposition

Cycle 1 rejected after format and analysis passed and 192 tests completed with one stale source-gate failure. No AAB build, device, provider, console or account state changed.

## Mistake

The complete C30O test set still contained a C30J source assertion requiring `onCreateYouTubeShort: _openYouTubeChannelStatus` in the MoolSocial Create owner, even though C30O intentionally removes that action to keep Create distinct and prevent reachable upload UI.

## Root cause

The historical account-state source test encoded the previously accepted entry point rather than the durable account-status route itself.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Update only the exact C30J assertion to require the channel-status route owner while prohibiting the Create-to-YouTube action binding.
- Preserve the rejected cycle logs and restart the complete cycle under new filenames.
