# REG2876 — C34L transition FIX2 audit registry-tail truncation

- Status: registered read-only independent-audit reconstruction failure.
- Mistake: the audit combined a 30-line registry head with a 500-line tail; the tool result truncated roughly 16,427 tokens and omitted part of the intended tail.
- Root cause: an oversized textual registry projection was used instead of parsed exact entries or bounded pages.
- Prevention: project the parsed exact IDs/fields needed for the audit, or page independent nonoverlapping slices of at most 120 lines; never combine a large head and tail read.
- Impact: no transition/journal fixture, mutation, release, private, device, or external action followed.
