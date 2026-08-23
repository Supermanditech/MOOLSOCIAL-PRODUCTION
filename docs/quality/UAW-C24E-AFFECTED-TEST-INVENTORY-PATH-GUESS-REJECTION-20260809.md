# C24E affected-test inventory path rejection — 2026-08-09

## Rejection

The first post-migration C24E affected-suite retry addressed two existing test
owners with guessed `test/ui_v2/universal/...` paths. Flutter rejected those
two paths as absent. The four correctly addressed Book and universal owners
continued to pass, but the compound invocation is rejected and counts as no
qualification cycle.

## Prevention

Before retry, the exact owners are resolved from `rg --files test`, their
existence is checked, and only that inventory is supplied to Flutter. Future
affected-suite commands may not treat a descriptive filename from notes as a
repository path authority.

## Preserved state

No runtime file changed because of this command. C24E remains the selected
host-only ticket; build, install, deployment and production writes remain
closed.
