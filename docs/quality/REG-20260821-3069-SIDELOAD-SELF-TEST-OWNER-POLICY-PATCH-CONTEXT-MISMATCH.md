# REG3069 — sideload self-test owner policy patch context mismatch

- Date: 2026-08-21
- Status: registered before retry

## Incident

The first attempt to add the public-auth sideload self-test owner to the
coordination policy used a conventional JSON tail context. The policy's current
tail uses leading-comma formatting, so `apply_patch` rejected the hunk.

## Impact

No policy, repository, build, device or external state changed.

## Prevention

Read the exact raw bounded policy lines before patching a mechanically evolved
owner tail; do not infer formatting from a projected owner array.
