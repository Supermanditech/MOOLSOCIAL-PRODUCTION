# C30S full dirty-inventory long-path warning flood recurrence

Date: 2026-08-12

## Rejection

The C30S preflight used a full untracked `git status` inventory to derive a
bounded ownership count and checksum. Git still traversed retained browser
profile evidence whose paths exceed the host path limit, flooded stderr with
warnings and caused the tool presentation to truncate.

No workspace file, device state or external service was changed by the
read-only command.

## Retained useful result

- dirty entries: `55211`
- tracked or indexed entries: `425`
- untracked entries: `54786`
- UTF-8 line inventory SHA-256:
  `5BC8DBA5DA3A0869A55B92B19A1E5653D85C9070A2E6AB0F9F447D79103E67E0`

## Permanent prevention

Do not repeat full untracked enumeration for C30S. Preserve the captured
ownership snapshot and use path-bounded status plus exact-file fingerprints
for successor-owned files. Every pre-existing tracked and untracked file
remains user-owned and must be preserved.
