# C30T YouTube multi-range output-truncation rejection — 2026-08-13

## Rejection

A diagnostic read combined seven bounded ranges from the Social YouTube UI
owner. Their aggregate output exceeded the tool response budget, so middle
ranges were omitted even though the filesystem command itself completed.

No omitted source was classified from that response. No product, backend,
device, release, or external state changed.

## Permanent prevention

Subsequent YouTube reads are limited to one behavioral owner or one compact
source range per command. Truncated output is not accepted as complete evidence.
