# UAW C30U final cycle-2 attempt-1 immutable log collision

Date: 2026-08-14

## Incident

Final cycle 1 passed at 1,146 source owners and fingerprint
`6FF020BA240F1BB7DD93D050F2956D6DA4700FD01701D14EAB9AD247A302A785`.
Cycle 2 was then invoked as Attempt 1. Its first intended log,
`cycle2-flutter-format.log`, already belonged to a preserved prior cycle-2 run,
so the qualifier rejected the collision before starting the test.

No cycle-2 test or source comparison ran. No build, upload or device mutation
occurred.

## Prevention

Versioned cycle JSON owners do not change the attempt-derived log stem. Before
each cycle, enumerate every exact expected log path and require all absent.
Preserve final cycle 1 as superseded because this mandatory registration changes
sealed memory, then run a new cycle-1 attempt and cycle-2 Attempt 2 with a new
versioned manifest/cycle/summary owner set. Never overwrite the existing
Attempt-1 logs.

The superseded cycle-1 JSON is preserved at SHA-256
`E4D6220D3A043D0659315269E2CC85FFB737B81620CDE403FB326F5D8BD284D9`;
its manifest is preserved at SHA-256
`6FF020BA240F1BB7DD93D050F2956D6DA4700FD01701D14EAB9AD247A302A785`.
Both machine-state owners expose zero current cycles and retain counts 0/0/0.
Final paths are manifest v5, cycle JSON v4 and summary v4; cycle 2 must use
Attempt 2 after its complete log-set absence preflight.
