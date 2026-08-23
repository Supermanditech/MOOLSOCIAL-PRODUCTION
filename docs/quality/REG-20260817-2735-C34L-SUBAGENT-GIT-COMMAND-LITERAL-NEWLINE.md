# REG-20260817-2735: C34L sub-agent Git command literal newline

## Truthful event

During mandatory read-only reconstruction, the transaction sub-agent composed
the three Git identity commands in one PowerShell command string containing
literal backtick-n text. Git received the later command text as part of the
`status` argument list and rejected `branch\ngit` as an unknown option.

The sub-agent stopped without retry. Its AGENTS reads had succeeded. No file,
candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The wrapper treated textual newline escape sequences as shell statement
boundaries instead of issuing the three scalar Git commands independently.

## Prevention

- Run `git status --short --branch`, `git rev-parse --abbrev-ref HEAD`, and
  `git rev-parse HEAD` as independent exact commands or as distinct shell
  statements whose separators are authored directly.
- Admit each scalar result only from its own zero exit code.
- Never place literal backtick-n text between native Git commands.

## Candidate consequence

C34L remains selection-only at zero release actions. The failed read-only Git
command invalidated only that sub-agent reconstruction attempt.
