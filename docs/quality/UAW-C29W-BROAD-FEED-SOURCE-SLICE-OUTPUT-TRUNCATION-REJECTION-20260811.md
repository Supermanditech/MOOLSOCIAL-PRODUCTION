# C29W broad Feed source-slice output truncation rejection

- Date: 2026-08-11
- Candidate: `1.0.0-r60.35` (`2026081135`)
- Result: source read rejected before implementation

A 326-line range from the Social feed owner exceeded the available model context and was truncated. The partial output is not accepted as source evidence. The retry resolves exact class boundaries and reads one literal owner in non-overlapping ranges of at most 120 lines. No source, build, device or provider mutation occurred from the rejected read.
