# C25F dirty-tree diagnostic warning-flood rejection

Date: 2026-08-09

The final state audit recovered the correct branch, HEAD, dirty counts and OPPO
identity, but Git also emitted hundreds of known long-path warnings from the
preserved artifact tree and truncated the displayed diagnostic. Future counts
must capture stdout/stderr separately, require exit zero and report only the
bounded counts. No file may be deleted or omitted to avoid the warnings.
