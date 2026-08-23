# C30T YouTube Windows wildcard-path rejection — 2026-08-13

## Rejection

The first bounded public-YouTube symbol inventory included
`apps/mobile/lib/ui_v2/social/social_v2_youtube*` as a path operand. On Windows,
ripgrep treated the wildcard-bearing value as a literal filesystem path and
returned OS error 123. The command also produced partial, truncated output.

## Classification

This is a diagnostic-command mistake, not product evidence. No source, backend,
device, release, or external state was changed by the rejected command.

## Permanent prevention

- Discover candidate files with `rg --files`.
- Pass exact repository paths as operands, or use ripgrep `--glob` for filename
  filtering.
- Treat any nonzero diagnostic command as rejected and do not rely on its partial
  output.
- Keep subsequent source reads bounded to named classes and exact line ranges.
