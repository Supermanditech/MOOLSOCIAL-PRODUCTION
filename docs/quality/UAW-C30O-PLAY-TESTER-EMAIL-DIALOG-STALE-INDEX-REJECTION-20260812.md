# C30O Play tester email dialog stale-index rejection — 2026-08-12

## Disposition

Rejected before email input. The tester-list name may be present, no email row was added, and the list was not saved.

## Mistake

The email step reused edit index 775 after the list-name value change and semantic refresh; the bridge reported that index unavailable.

## Root cause

Dialog accessibility indexes were assumed stable across a value change and refresh.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Reacquire the exact current Add email addresses edit index.
- Type `supermanditech@gmail.com` once and press Return.
- Verify the added row before saving.
