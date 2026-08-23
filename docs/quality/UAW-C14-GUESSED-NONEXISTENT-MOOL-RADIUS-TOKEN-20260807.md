# C14 guessed nonexistent Mool radius token

Date: 2026-08-07

Regression:
`REG-20260807-280-C14-GUESSED-NONEXISTENT-MOOL-RADIUS-TOKEN`

## Failure

The first focused C14 analyzer run rejected
`MoolRadii.sm` in the shared local action because that radius token does not
exist. The available compact control token is `MoolRadii.control`.

## Prevention

Design-token names are copied from the exact declaring owner before use; a
spacing abbreviation is never assumed to exist in another token family. C14
reuses `MoolRadii.control` and reruns the identical focused analyzer before any
widget test or build.
