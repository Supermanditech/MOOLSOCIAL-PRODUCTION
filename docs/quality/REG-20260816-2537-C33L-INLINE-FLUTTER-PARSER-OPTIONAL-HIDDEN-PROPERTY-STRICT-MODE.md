# REG-20260816-2537 C33L inline Flutter parser optional hidden property

- Date: 2026-08-16
- Failure: the first 72-file Flutter attempt completed and preserved JSONL,
  but the inline summarizer accessed the optional `test.hidden` property
  directly under strict mode. Some event metadata legitimately omits it.
- Impact: no product result or qualification cycle is claimed from the failed
  summarizer. No build, external-service, Play or OPPO action occurred.
- Root cause: the inline code did not reuse the authoritative runner's
  optional-property helper.
- Prevention: reparse the preserved JSONL with explicit optional-property
  handling, then run both final sealed cycles only through the repository
  authoritative manifest runner using the exact observed pass/skip totals.
- Resolution: the preserved JSONL reparsed successfully with optional-property
  handling and exposed the separate REG-2538 product-test result: 488 passed,
  3 skipped and 1 failed.
