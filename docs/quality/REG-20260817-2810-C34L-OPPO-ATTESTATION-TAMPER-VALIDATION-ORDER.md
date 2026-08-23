# REG2810 — C34L OPPO attestation-tamper validation order

Date: 17 August 2026
State: registered exact-class PS7 negative failure; zero real/external action

## Mistake

The late OPPO source-attestation tamper negative expected the journal's root
`sourceAttestation.sha256` mismatch, but journal validation checked the derived
cold payload binding first. Because changing the nested attestation also changes
payload bytes, the fixture rejected at `coldStart payload binding changed` and
masked the intended provenance failure class. Cleanup completed safely and no
real or external action occurred.

## Prevention

Validate the journal's root source-attestation path/hash/bytes binding before
any derived cold/retained payload binding. Keep a separate payload-tamper
negative so both failure classes remain deterministic and independently covered.
