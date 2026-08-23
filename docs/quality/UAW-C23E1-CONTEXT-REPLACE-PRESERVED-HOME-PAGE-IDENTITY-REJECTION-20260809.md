# C23E1 identity-preserving replace rejection

Complete-URI page identity alone did not fix the query because GoRouter
`context.replace` preserves the current Home page identity. C23E1 requires
`pushReplacement` for destination-opened Home: remove Home, create the exact
target entry, and retain the prior destination below for Back. Root Home stays
on ordinary push. No host cycle or APK authority passed.
