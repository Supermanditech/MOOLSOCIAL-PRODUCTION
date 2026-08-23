# UAW AAB preparation multi-script read truncation

## Incident

The first AAB-preparation inspection combined the complete C30W runtime gate,
the large single-AAB wrapper and its static gate. The result exceeded the
output boundary and was truncated before the wrapper could be reviewed in
full.

## Impact

The read-only command changed no source, state, artifact, device or external
service. Its truncated wrapper output is zero admissible audit evidence.

## Prevention

The release audit now locates exact symbols and reads only one bounded 20-40
line region per verified owner. No build authority, secret input or candidate
mutation may rely on a truncated release-control read.
