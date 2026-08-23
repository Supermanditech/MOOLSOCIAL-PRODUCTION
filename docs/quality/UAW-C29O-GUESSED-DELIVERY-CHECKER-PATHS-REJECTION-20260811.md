# C29O guessed delivery-checker paths rejection

During the pre-mutation Social audit, one combined read correctly opened the
permanent regression checker but also guessed two delivery-checker filenames:
`scripts/check-mvp-robust-delivery-lock.ps1` and
`scripts/check-mvp-scope.ps1`. Both paths were absent, so that combined read
was rejected and supplied no delivery or scope-gate evidence. No product,
ticket, scope or machine state changed.

The bounded script inventory then resolved the actual owners as
`scripts/check-mvp-delivery-discipline-lock.ps1` and
`scripts/check-mvp-scope-gate-state.ps1`. Future gate inspection and invocation
must use exact filenames returned by a completed `rg --files scripts`
inventory; descriptive policy names never imply script filenames.
