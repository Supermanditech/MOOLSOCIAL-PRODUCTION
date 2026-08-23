# REG-20260818-2952 C34P MVP-state non-unique hunk target

Date: 18 August 2026 (IST)
State: registered before exact restoration and unique-anchor retry

## Incident

After the selected C34P assessment identity was patched, the primary applied a
two-line disposition/owner hunk whose old text occurred in more than one C34L
assessment. `apply_patch` accepted the hunk, but immediate parsed readback showed
the current `selectedTicketAssessment` still had the old dispositions and seven
release owners. The new values therefore reached a different historical
assessment inside the same large state owner. No runtime, test, provider,
build, device, private or external action followed the wrong-target mutation.

## Root cause

The hunk used two repeated assessment fields without including the unique
current `ticketId` and current manifest context. File-local ownership alone did
not make the textual anchor unique inside the append-heavy JSON document.

## Prevention

Locate the wrong mutation by the new unique owner literal, identify its named
historical subtree, and restore its exact prior two lines before any C34P retry.
Every later assessment hunk includes the current C34P `ticketId` or another
unique adjacent current-assessment anchor, and immediate parsed readback must
show both the intended current value and the unchanged/restored named historical
value.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
