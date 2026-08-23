# UAW C10E Book dock migration patch boundary

- Registry: `REG-20260807-217-C10E-BOOK-MIGRATION-PATCH-ASSUMED-NONEXISTENT-FOLLOWING-CLASS`
- State: resolved before retry; rejected patch changed no Book source
- Detection: `apply_patch` could not find the assumed `class BookEmptyState` deletion boundary after `BookBottomDock`.
- Root cause: the large multi-hunk patch reused a remembered neighboring class instead of reading the immediate tail; `BookBottomDock` is the file's final class.
- Durable prevention: reconcile the exact numbered tail, split scaffold insertion from terminal-class deletion, and anchor deletion through the actual end-of-file brace.
