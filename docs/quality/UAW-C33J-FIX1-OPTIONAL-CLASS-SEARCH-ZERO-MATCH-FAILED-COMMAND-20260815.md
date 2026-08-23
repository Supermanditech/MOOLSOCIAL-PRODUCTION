# UAW C33J FIX1 optional class search zero-match failed command

- Regression: `REG-20260815-2510-C33J-FIX1-OPTIONAL-CLASS-SEARCH-ZERO-MATCH-FAILED-COMMAND`
- Failure: a required key lookup succeeded, but a combined optional class-name
  lookup returned zero and made the command exit 1.
- Prevention: separate required and optional searches and explicitly normalize
  optional ripgrep exit 1.
- Impact: no product or external state changed.
