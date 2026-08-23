# C31E photo fake tuple incremental correction recurrence — 15 August 2026

The correction for REG-2235 removed the duplicated text-message parameter but
still edited the photo tuple through repeated individual string slots. The
result retained a misplaced entry, and the next typecheck reported three
shifted assignments in `sendPhotoInput`.

No production or external state changed. The next correction must replace the
complete `sendPhotoInput` declaration in one exact block with ten positions:
actor, thread, upload, filename, MIME type, size, caption, retry key, request
digest and optional reply message ID. The method assignment must contain those
same ten positions.

The entire tuple block now has those ten positions in order and matches the
method assignment exactly; `tsc --noEmit` passes.
