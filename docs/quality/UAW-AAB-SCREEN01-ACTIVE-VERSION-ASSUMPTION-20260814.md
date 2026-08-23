# AAB Screen01 active-version assumption rejection

Date: 14 August 2026
Scope: protected manifest recovery during Screen03 v4 reconciliation

After the ambiguous manifest patch, the first correction assumed Screen01 v3
was the previously active production version. The global gate rejected v3's
locked splash source hash before reaching Screen03, proving that assumption
was not admissible.

The next correction first compares every preserved Screen01 acceptance
package's complete locked-file set with current bytes and restores only the
unique exact match. No Screen01 file, AAB, Play/OPPO state, deployment or
secret was accessed or mutated beyond the manifest status under repair.

## Resolution

Screen01 v3 differed on five of twelve locked owners; Screen01 v4 matched all
twelve current bytes. The manifest now restores v4 as the unique active
Screen01 production acceptance, and the global approved-UI gate passes.
