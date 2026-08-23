# UAW C30W YouTube web-test directory guess nonzero rejection — 2026-08-14

## Scope

This record covers a read-only test-owner discovery command during the C30W overnight YouTube reviewer-package audit. It did not mutate repository or external state.

## Mistake

The search included guessed directories `apps/web/test` and `test` in addition to the real `apps/web/tests` owner. Although the command printed one matching file, the nonexistent operands made the command exit nonzero, so the result was rejected as qualification evidence.

## Impact

- No file was changed.
- The printed match is not credited until a clean exact-directory retry succeeds.
- No cloud, Hosting, Play, device, email, quota, or secret state was accessed or changed.

## Root cause

Likely test-directory conventions were supplied without first enumerating the actual web directory structure.

## Prevention and retry rule

- Enumerate the exact bounded parent with `rg --files` before searching content.
- Search only paths proved to exist.
- Reject any mixed-success/nonzero discovery result and do not use it to choose a gate.

## Resolution

Registered before retry as `REG-20260814-2105-C30W-YOUTUBE-WEB-TEST-DIRECTORY-GUESS-NONZERO-REJECTION`.
