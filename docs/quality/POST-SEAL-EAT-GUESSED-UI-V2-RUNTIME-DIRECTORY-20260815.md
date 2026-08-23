# Post-seal Eat guessed ui_v2 runtime directory

The first exact Eat test-title inventory succeeded, but the same command then
guessed `apps/mobile/lib/ui_v2/eat` from the presence of
`apps/mobile/test/ui_v2/eat`. No corresponding runtime directory exists, so
ripgrep returned an OS path error after partial output.

No state changed. REG-2295 must be registered before retry. Runtime owners will
be resolved from each exact test's imports and from existing directories
returned by `rg --files`; test-tree layout is not evidence of a parallel
production tree.
