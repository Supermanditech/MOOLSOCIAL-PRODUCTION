# REG-20260820-3036 Cursor B2 JavaScript-template PowerShell backtick-tab parser

## Incident

Cursor completed B1 by creating the separate clean worktree
`codex-cursor-baseline-reconciliation` on branch
`reconcile/codex-cursor/pre-buy-baseline-v1` at the required HEAD. Before B2
could invoke a shell, its orchestration wrapper rejected with JavaScript
`SyntaxError: Unexpected identifier 't'` because a PowerShell backtick-tab
token was embedded inside a JavaScript template literal.

## Impact

- B1 remains valid: the separate worktree and branch exist, are clean and have
  the correct HEAD; the frozen original checkout was untouched.
- B2 command-body execution was zero.
- No file copy, manifest write, staging, commit, tag, push, main, build, Play,
  OPPO, provider or external action occurred.
- The existing worktree must not be deleted or recreated.

## Root cause

Two language escape grammars were composed in one wrapper. PowerShell's
backtick escape entered a JavaScript template literal and was parsed before the
PowerShell command could be created.

## Prevention

Do not retry the wrapper text. Preserve B1, refresh all generation/digest pins,
and run B2 using an orchestration source with no embedded PowerShell backticks:
use direct argument arrays and ordinary single-quoted PowerShell literals, or a
separate exact script owner. Verify command-body execution remains bounded and
emit only sanitized manifest/count/hash outcomes.
