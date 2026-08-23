# C30U YouTube auth cancellation origin collapsed to Social root

The guest YouTube continuation test began on Videos but the recorded MoolSocial
authentication cancellation fallback was `/app/social` rather than
`/app/social?sub=videos`.

The Social owner must record the exact stable Videos origin before entering the
authentication state. The AAB remains blocked until the test passes.
