# UAW C33J FIX1 malformed multifile apply patch hunk

- Regression: `REG-20260815-2511-C33J-FIX1-MALFORMED-MULTIFILE-APPLY-PATCH-HUNK`
- Failure: a second file header appeared before the preceding update hunk was
  complete, so apply_patch rejected the whole patch.
- Prevention: retry each verified file through a separate complete patch.
- Impact: no file or external state changed by the rejected patch.
