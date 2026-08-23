# C30T Image composer title assertion rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: non-writing Create-format journey inventory

The unique Image selector opened the exact Android photo picker and one reversible Back action cancelled it without selecting media. The postcondition incorrectly expected the shorthand accessibility title `New image`; the fresh released hierarchy exposes `New image post`. The verifier therefore stopped before screenshot capture.

The current state remains MoolSocial's Image composer, the six format selectors are present, and no media or content was selected or written. The retry must require exactly one `New image post` node from a new hierarchy, confirm no picker is focused and no content exists, and then capture the evidence without another UI action.
