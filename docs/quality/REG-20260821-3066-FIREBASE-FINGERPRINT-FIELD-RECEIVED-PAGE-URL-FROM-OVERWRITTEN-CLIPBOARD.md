# REG-20260821-3066 Firebase fingerprint field received page URL from overwritten clipboard

## Observed failure

The Firebase Add fingerprint field received the Firebase page URL because the
clipboard was overwritten after the local SHA-1 helper primed it. Firebase
rejected the format and disabled Save; nothing was persisted.

## Root cause

Clipboard priming occurred before browser navigation rather than immediately
before the destination paste.

## Impact

- no Firebase fingerprint or provider state changed;
- no certificate value was emitted;
- the invalid field remains unsaved and can be replaced safely.

## Prevention and authorized retry

Prime the clipboard from the still-open helper immediately before each paste,
then replace the entire field without copying/navigating in between. Save only
after Firebase recognizes the exact SHA type.
