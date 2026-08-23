# C23H regression-memory stale line-count rejection

Date: 2026-08-09

The first bounded full-memory paging command asserted the 953-line count that
was observed before two new lessons were added. The current owner contained
961 lines, so the command rejected before printing the requested page. No file
was mutated by that rejected read.

Full-read paging now discovers the current line count immediately before
building verified non-overlapping ranges. A count observed before a repository
mutation is never reused as the expected current count.
