# REG2772 — C34L FIX1 upload-authorized phase typo

Date: 17 August 2026
State: registered before manifest hash or repair execution

## Mistake

Readback of the new PRE-AAB-3-FIX1 manifest found the minimum-scope token
`upload_authorized_preprompt`. The canonical lifecycle tuple is
`upload-authorized` / `preupload`. The ticket had not been hashed, pinned or
executed and all repair agents remained stopped. No candidate, browser, release
or external action occurred.

## Root cause and prevention

Two valid phase names were accidentally combined while manually transcribing
the audit correction. Project transition and phase as separate exact values
from the canonical map, search every new manifest for all lifecycle tokens and
reject any concatenated tuple before hashing or machine-state pinning.
