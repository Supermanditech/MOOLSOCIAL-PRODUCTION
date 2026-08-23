# C30T focused Flutter test cell lost during compaction

Date: 2026-08-13

The focused Feed timestamp test command yielded an execution-cell handle immediately before task compaction. After compaction the handle no longer existed, so neither a trustworthy exit code nor complete output could be recovered. The partial/unknown run is rejected and is not release evidence.

The retry rule is one fresh bounded invocation with output written to a durable evidence log. Its exit code and checksum must be recorded, followed by restoration and verification of the exact release plugin registrant. This diagnostic caused no backend, provider, device, AAB, Play or communication mutation.
