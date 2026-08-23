# C30T Firebase Storage service inventory drift

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1879-C30T-CLOUD-PREFLIGHT-FIREBASE-STORAGE-SERVICE-INVENTORY-DRIFT`

## Observation

The read-only Cloud preflight compared 60 manifest services with 61 enabled Dev services. The only live addition was `firebasestorage.googleapis.com`; no manifest service was absent from the project.

## Classification and correction

Firebase Storage is an already enabled dependency of the separately gated Social media backend in the shared Dev project. The exact service name was added to the allowed enabled-service inventory. No service was enabled, disabled or reconfigured, and the C30T deploy target remains only `functions:provider:youtubeProvider` plus Firebase Hosting.

## External effect

None. This was a read-only reconciliation followed by a local manifest correction. No cloud resource changed.
