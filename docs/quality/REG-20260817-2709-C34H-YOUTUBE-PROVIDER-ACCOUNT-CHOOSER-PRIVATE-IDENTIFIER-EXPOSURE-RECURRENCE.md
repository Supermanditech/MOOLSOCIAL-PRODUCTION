# C34H YouTube-provider account-chooser private-identifier exposure recurrence

Date: 2026-08-17 IST

## Mistake

During C34H postinstall device acceptance, Codex tapped the displayed YouTube
identity-provider tile while attempting to classify non-Google provider
truth. Android opened a system account chooser containing private account
identifiers. No account was selected, no authentication request was
completed, and the founder manually closed the chooser. No identifier value
is copied into repository evidence.

This repeats the permanent privacy-boundary class: authentication surfaces
that may enumerate accounts must never be opened or inspected by Codex.
C34H is therefore rejected at truthful build/upload/install/device counts
`1/1/1/0`.

## Root cause

The provider tile was treated as an unsupported-provider truth probe without
first classifying it as a supported authentication action that can open a
system account chooser. The device workflow crossed the founder-only
authentication-dialog boundary.

## Permanent prevention

Every identity-provider tile is an authentication boundary unless a
prequalified source/runtime contract proves a local unavailable-state sheet.
Codex may verify the generic sign-in gateway and local unavailable paths, but
must stop before tapping Google, YouTube or any provider capable of opening an
account chooser. The founder alone performs account selection; Codex resumes
only from sanitized post-authentication state with no private identifier
visible.
