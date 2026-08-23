# C30T qualification evidence filename assumption — 2026-08-13

## Outcome

The first restarted no-AAB qualification cycle passed, but the immediate
bounded evidence check guessed two descriptive filenames that the qualifier
does not write. The read failed for those two paths and made no mutation.

## Root cause and prevention

Summarized evidence labels were treated as literal filenames. Future evidence
reads resolve and copy the exact output names from
scripts/qualify-play-internal-live-read-recovery-c30t.ps1 before access. The
canonical names are source-aggregate-manifest-accepted.txt and the numbered
source-qualifying-cycle JSON files.

Because this registry evidence is source-sealed, both no-AAB qualification
cycles must be repeated before build authority can be activated.
