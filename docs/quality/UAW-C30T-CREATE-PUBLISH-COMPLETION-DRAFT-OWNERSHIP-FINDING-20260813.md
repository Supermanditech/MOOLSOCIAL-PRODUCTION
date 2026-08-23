# C30T Create publish-completion draft-ownership finding — 2026-08-13

## Finding

Create disables duplicate publication while a request is pending but intentionally leaves text and format controls editable. When the older request succeeded, `_clearComposer` unconditionally erased the current draft. New text, choices, media or format changes entered during upload could therefore be lost.

## Bounded correction

Fingerprint the exact submitted draft, then clear only if the visible draft still matches it when the completion returns. Persist newer state instead, and do not let an old session completion own the current workbench UI.

## Verification

The complete Create/Feed publication file passed `19` tests. A delayed gateway captures the exact submitted post, the creator enters a newer draft before completion, the old post completes once, and the newer draft remains exact both immediately and after a full workbench remount. Existing public formats, Feed links, picker containment, format retention and accessibility remain green. Evidence SHA-256: `77A8E217447332EAFFC97DAF88ED0CC6EEDC7D867F3FF9D5EBF172D59A4462BF`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. The preserved C30S r60.44 AAB remains byte-identical. No real Create write, backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
