# C16B Social legacy-block hand-copied patch context rejection

## Incident

After connecting `Screen04ContextTabs` to the shared C16A owner, a large
hand-copied patch attempted to delete the now-unreachable 317-line legacy
Social rail block. Apply-patch could not verify one or more copied context lines
and rejected the hunk atomically. The new shared callsite remains intact and no
legacy line was partially deleted.

## Root cause and prevention

A long deletion hunk was manually reconstructed instead of derived byte-for-
byte from the current bounded file content. The retry reads the exact block
between the legacy class start and the following immutable model marker,
constructs a deletion hunk from those exact lines, and applies it once. An
atomically rejected patch is confirmed unchanged before retry.
