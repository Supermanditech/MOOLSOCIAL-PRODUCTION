# UAW C30U guessed nonexistent build-script owner in launcher check

Date: 2026-08-14

## Incident

After two final cycles passed identically at 1,147 files and fingerprint
`567263733DBFA4FE21077FD2BBF76B01297343C62088538E7BF16B2FF8125EDD`, a
read-only launcher lookup included a guessed
`scripts/build-play-internal-aab-c30u.ps1` path. That file does not exist, so
ripgrep returned nonzero after partial valid matches.

The partial output confirms the exact known launcher has two secure
`Read-Host -AsSecureString` prompts and owns the `Phase build` transition, but
the mixed-output command is not accepted as complete evidence.

## Prevention

Inspect only the exact known founder launcher and its already passing static
wrapper gate. Never infer an implementation owner name from convention. Preserve
the passed pair as superseded because this mandatory registration changes
sealed memory, run a new versioned pair, then launch the exact known wrapper
directly without another exploratory search.

No AAB, Play or OPPO mutation occurred.

The exact launcher read proves its existing implementation owner is
`scripts/invoke-play-internal-aab-build-c30t.ps1`. It validates the source-
qualified state and zero build count, sets the two founder-qualified runtime
flags only after hidden input validation, invokes that exact wrapper, and
erases transient files and process environment values in `finally`.
