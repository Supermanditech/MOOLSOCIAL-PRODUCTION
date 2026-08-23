# C16 optional ripgrep helper-discovery zero-match recurrence

## Incident

During the read-only C16 predecessor/tooling inventory, a required script
filename enumeration was grouped with an optional `rg` content search for
device-helper commands. The optional search found no matches and returned the
normal ripgrep exit code `1`, but the compound command surfaced the complete
inventory as failed.

No runtime, device, build, accepted-reference or protected-state mutation
occurred.

## Root cause and prevention

The optional content search did not explicitly classify exit `1` as a valid
zero-match result before it shared the required inventory command boundary.
Future C16 discovery keeps required filename enumeration separate. Every
optional ripgrep probe captures its native exit immediately, accepts `0` as
matches and `1` as a declared zero-match result, and rejects only values above
`1`.
