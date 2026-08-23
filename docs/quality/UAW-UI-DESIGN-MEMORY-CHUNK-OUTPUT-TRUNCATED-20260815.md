# UI design memory chunk output truncation regression

- Regression: `REG-20260815-2469-UI-DESIGN-MEMORY-CHUNK-OUTPUT-TRUNCATED`
- Failure: a 605-line required design-memory read exceeded the output/context budget and did not provide complete evidence.
- Impact: the incomplete read was not treated as qualification; no source, reference, service or device state changed.
- Prevention: read required large documents in independently verified chunks of at most 200 lines, reducing the chunk size for dense content, and require an untruncated result for every range.
