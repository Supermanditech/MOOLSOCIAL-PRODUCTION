# C30Q config-only exit-code static pattern mismatch rejection

The first C30Q static wrapper gate required the literal
`releaseConfigExitCode = $LASTEXITCODE`. The wrapper instead calls the bounded
`Invoke-NativeCaptured` helper, which returns the immediate native
`$LASTEXITCODE`, and assigns that returned value to `releaseConfigExitCode`.

All JSON and PowerShell syntax, MVP, delivery and reconcile gates passed before
the static mismatch. No config-only command, AAB build, secret prompt or
external write ran. Prevention: the gate must separately require the helper's
immediate `$LASTEXITCODE` return and the caller assignment from that helper,
rather than demand a false direct-assignment implementation detail.
