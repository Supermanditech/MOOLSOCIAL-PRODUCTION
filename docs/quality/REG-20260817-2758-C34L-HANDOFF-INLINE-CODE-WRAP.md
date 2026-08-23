# REG-20260817-2758: C34L handoff inline-code wrap

## Truthful event

Readback of the newly inserted 18:20 C34L handoff section found that the inline
code span for `prebuild-failed -FailureStage` was split across a Markdown line
break. The technical statement and all recorded hashes are correct, but the
inline code delimiter is malformed. The primary agent stopped before correcting
the handoff.

No candidate, build, Google Play, device, private value, deployment, or external
state changed.

## Root cause

The handoff paragraph was manually wrapped inside an inline-code span instead
of keeping the complete parameter phrase on one physical line.

## Prevention

- Keep short inline-code parameter phrases on one physical Markdown line.
- Re-read the inserted top section with line numbers before declaring the
  handoff durable.
- Reject any inline-code delimiter pair that crosses a paragraph line break.

## Candidate consequence

Only handoff rendering is affected. C34L remains selection-only and all
qualification results are unchanged.
