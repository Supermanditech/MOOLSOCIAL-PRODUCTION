# UAW-R14 Personal context restore contract V1

| Interrupted context | Restored context |
| --- | --- |
| Personal main-action root | same permitted root |
| Permitted Social/Buy/Eat/Ride/Book/Work sub-action | same safe sub-action entry |
| Deeper permitted transaction or workflow depth | owning permitted sub-action/root; no identifier |
| Chat inbox/thread with a permitted return | canonical permitted return context |
| Legacy containment recovery | current safe owning root |
| Removed, external, malformed or unknown location | Personal Social safe default |

The existing `JourneySession` snapshot and ordered persistence remain the only
restore owner. Canonicalization is an allowlist, strips unapproved query data
and never restores a removed action, transaction identifier, workspace grant
or local capability decision.
