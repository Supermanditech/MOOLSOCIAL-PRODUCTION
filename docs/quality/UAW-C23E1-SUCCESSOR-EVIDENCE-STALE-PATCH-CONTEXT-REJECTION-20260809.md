# C23E1 successor-evidence stale patch-context rejection — 2026-08-09

## Observed rejection

A documentation-only patch attempted to append successor corrections to two
retained rejection records. Its C23G anchor came from remembered registry prose
rather than the exact Markdown file, so `apply_patch` rejected the patch and
changed no file.

## Permanent prevention

Read the exact tail of each retained evidence owner before amendment and use a
bounded anchor that exists in that file. Never infer evidence-file prose from a
related registry entry.
