# UAW C30W focused-manifest filename guess rejection — 2026-08-14

## Scope

This record covers a read-only final C30W seal check. It did not mutate source, manifests, release state, device, provider, or external state.

## Mistake

The command requested a guessed `focused-source-manifest-c30w.txt` filename instead of enumerating the exact C30W evidence-directory owner. The path did not exist, so no focused-manifest content was read.

## Impact

- The failed command provides zero evidence.
- The existing sealed focused manifest was not changed.
- No build, upload, install, device, service, secret, or communication action occurred.

## Root cause

The remembered concept “focused source manifest” was converted into a filename even though the exact artifact path was available through bounded directory enumeration.

## Prevention and retry rule

- Enumerate the exact bounded C30W evidence directory before reading a manifest owner.
- Copy the returned basename literally.
- Do not infer `source` or other filename segments from a document description.

## Resolution

Registered before retry as `REG-20260814-2107-C30W-FOCUSED-MANIFEST-FILENAME-GUESS-REJECTION`.
