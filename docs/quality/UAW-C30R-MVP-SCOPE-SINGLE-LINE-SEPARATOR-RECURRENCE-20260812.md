# C30R MVP scope single-line separator recurrence

Date: 2026-08-12

The first promised single-line recovery patch still retyped one underscore as a
space and was rejected by `apply_patch` before modification. No repository,
device, Play or runtime state changed.

Prevention: obtain each remaining literal with a bounded `rg -n` raw-file read,
copy that exact line without reconstruction, replace it alone, and parse before
the next line.
