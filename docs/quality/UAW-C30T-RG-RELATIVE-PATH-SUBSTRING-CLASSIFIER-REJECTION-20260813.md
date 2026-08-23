# UAW C30T rg relative-path substring classifier rejection — 2026-08-13

A supplemental classifier assumed `rg --files` returned absolute paths and
tried to remove the absolute test-root prefix with `Substring`. In this
working directory `rg` returned repository-relative paths, so the index was
larger than many strings and produced repeated exceptions. Its one-file count
is rejected and is not evidence. The authoritative failure grouping remains
the direct parsing of 301 `[E]` markers into 76 exact files.

Future path classifiers normalize with `Resolve-Path` per file only when an
absolute path is needed, or retain the `rg --files` repository-relative value
unchanged.
