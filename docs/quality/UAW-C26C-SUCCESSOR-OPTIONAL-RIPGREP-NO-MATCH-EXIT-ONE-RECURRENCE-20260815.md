# C26C successor optional ripgrep no-match exit-one recurrence

Date: 15 August 2026
Registry: `REG-20260815-2250-C26C-SUCCESSOR-OPTIONAL-RIPGREP-NO-MATCH-EXIT-ONE-RECURRENCE`

The first search for `compactOverlayAlignEnd`, right-edge alignment and the
C29E off-screen recovery used broad roots with restrictive filename globs. It
returned no matches and ripgrep exit 1 was not normalized, so the complete
command is zero evidence.

No repository, runtime, build, device, provider or external state changed.
The corrected diagnosis uses exact already-resolved files, captures exit 0/1
explicitly and never infers absence from the rejected broad-glob search.
