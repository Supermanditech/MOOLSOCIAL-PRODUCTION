# C30Q Play tab title-assumption selection rejection

Date: 2026-08-12

## Mistake

After the Chrome extension setting change, the first tab selector required both the exact MoolSocial Play app URL pattern and a current tab title containing `MoolSocial`. No current tab metadata matched both predicates, so the selector rejected before claiming any tab.

## Impact

- No tab was controlled and no bundle was selected or uploaded.
- No Play release, repository, artifact, machine, device, credential, or secret state changed.

## Permanent prevention

Enumerate the current bounded open-tab metadata after an extension reconnect, select by the exact Play developer/app URL owner, and treat the mutable page title only as supporting evidence.
