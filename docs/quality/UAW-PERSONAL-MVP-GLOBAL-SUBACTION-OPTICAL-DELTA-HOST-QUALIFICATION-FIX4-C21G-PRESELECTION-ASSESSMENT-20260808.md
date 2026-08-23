# C21G optical-delta host qualification preselection — 2026-08-08

C21G is MVP-required test-only acceptance work. It exists because r60.19 passed host checks without proving a meaningful predecessor-to-successor visual delta and was rejected on OPPO as effectively unchanged. C21A–F are complete and C21G is the next item in the locked parent sequence.

The reuse and duplicate search selected the existing C21 optical contract, C20/C17 predecessor contracts, family tests, protected release gates and source-fingerprint workflow. No new screen, route, runtime owner, backend owner, persistent state or subaction is needed. Runtime source, build, install, backend and external writes remain closed.

Minimum complete scope is a machine-readable r60.19-versus-C21 structural optical delta; explicit evidence for the 17 selected states over light/media/Buy backgrounds; repair of obsolete tests without restoring removed flat-fill APIs; two consecutive complete host cycles against an identical sealed source fingerprint; and the full protected suite. Any source change after sealing resets the cycle count. Only after C21G completes may C21H perform a separate machine authorization review for exactly one successor APK.
