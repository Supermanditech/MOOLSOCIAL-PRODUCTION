# C30T multiline semantic-label exact-match rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: read-only/non-writing Create-format journey inventory

The first atomic attempt to select the Quiz format stopped before any tap. The gate expected a single-line description rendered as `Quiz…`, while the complete fresh hierarchy contained exactly one enabled clickable selector whose description was `Quiz` followed by a newline and another `Quiz`.

No UI action, Create write, backend write, build, upload or install occurred. The retry is permitted only after normalizing the complete accessibility description into trimmed nonempty tokens, requiring every token to equal `Quiz`, requiring exactly one enabled clickable node, and deriving the tap centre from that same fresh hierarchy.
