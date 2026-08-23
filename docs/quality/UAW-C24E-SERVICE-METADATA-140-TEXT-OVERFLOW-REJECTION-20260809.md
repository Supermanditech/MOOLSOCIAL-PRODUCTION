# C24E service metadata 140% text overflow rejection — 2026-08-09

## Observed defect

The C24E adaptive test constructed the Doctor and Salon provider cards at
320x568 with 140% text. Exact metadata such as verification, wait and
cancellation truth overflowed the right edge by 12–63 logical pixels inside
`_ServiceMetadata`.

## Root cause and correction

The outer metadata Wrap could rearrange items, but each item used a horizontal
Row whose Text had no flexible owner. The shared primitive is corrected so the
label wraps within the finite card width while its icon, complete copy and
semantic meaning remain present.

The failed invocation counts as no qualification cycle. Build and install
remain closed.
