# C30U incident patch missing add-line prefix

## Incident

The first REG-2017 registration patch omitted the required addition prefix on
one Markdown content line. The patch was rejected atomically.

## Root cause

The multiline add-file block was not checked line by line before submission.

## Permanent prevention

Keep incident patches small and verify every new content line carries the
required addition prefix before invoking apply_patch.

The rejected patch changed no files and no release action occurred.
