# C30U MVP scope selected-assessment stale top-level projection

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

After resealing the C30U ticket hash, a read-only validation assumed
`selectedTicketAssessment` was a top-level property of
`config/mvp-scope-gate-state.json`. The projected manifest path was null and
`Get-FileHash` rejected it. This diagnostic proves no scope-state binding.

## Root cause

The current MVP scope schema's exact nested property path was not enumerated
before value access; an older remembered projection was reused.

## Prevention

Parse the current owner, list only its root property names, then enumerate the
candidate nested owner names before reading the selected assessment. Require a
non-null manifest path and compare the stored 64-hex digest to a fresh literal
hash before running the scope gate.

## Release effect

The failure was read-only. The ticket and C30U machine states remain parsed,
with build/upload/install counts `0/0/0`; no cycle seal, AAB, upload, Play
activation or OPPO mutation occurred.

## Corrected current-schema verification

The current owner places the assessment at
`preTicketSelectionCheckpoint.selectedTicketAssessment`. It resolves exactly:

- State: `ticket_disclosed_and_authorized`
- Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`
- Manifest:
  `config/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-ticket.json`
- Stored and actual SHA-256:
  `3595A1A65D55991BAC8DAAD0D59584470140617FBF7C919CBC580B1E06C199C1`

The binding matches and is eligible for the authoritative scope gate.
