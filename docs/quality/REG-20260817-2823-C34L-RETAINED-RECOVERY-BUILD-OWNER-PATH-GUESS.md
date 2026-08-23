# REG2823 — C34L retained recovery build-owner path guess

Date: 17 August 2026
State: registered read-only diagnostic path failure; zero mutation

## Mistake

During recovery-schema review, the retained/privacy agent passed two guessed
nonexistent build-owner paths—`scripts/build-successor-aab.ps1` and
`scripts/build-uaw-c34l-r60-76-single-aab.ps1`—to a scoped `rg` search. `rg`
reported path-not-found errors; other matches from that command were not used
as final evidence. No mutation or test followed.

## Prevention

Discover the exact authoritative wrapper/launcher owners with bounded
`rg --files` first, then search only verified literal paths. Never invent likely
build-owner filenames for a diagnostic.
