# C30O Play declaration full accessibility and screenshot output truncation rejection — 2026-08-12

## Disposition

Rejected evidence-read attempt. The state refresh may have completed, but no input was dispatched and the Play app was not created.

## Mistake

The continuation requested a fresh declaration view and attempted to emit both screenshot images and the full accessibility payload in one result. The outer transcript exceeded its context budget and truncated.

## Root cause

Visual and semantic evidence were combined even though the next action required only one bounded screenshot or narrowly filtered declaration lines.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Reuse the successfully refreshed state when available.
- Emit only screenshots or only narrowly filtered declaration text in a single call.
- Never combine full accessibility output with images.
