# C16B tool-isolate atob unavailable exact-patch rejection

## Incident

The exact legacy-block payload was read successfully as Base64, but the fresh
tool orchestration isolate does not expose the browser `atob` helper. Decoding
failed before apply-patch was called, so the Social source remained unchanged.

## Root cause and prevention

A browser global was assumed in a minimal V8 isolate. The retry uses an
explicit in-isolate Base64 decoder and `TextDecoder`, validates the decoded
legacy start/end markers, then constructs the exact deletion hunk. No mutation
is attempted when decoding or marker validation fails.
