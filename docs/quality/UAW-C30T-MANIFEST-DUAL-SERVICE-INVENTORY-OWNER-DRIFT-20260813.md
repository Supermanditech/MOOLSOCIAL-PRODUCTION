# C30T manifest dual service-inventory owner drift

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1881-C30T-MANIFEST-DUAL-SERVICE-INVENTORY-OWNER-DRIFT`

## Observation

The first Firebase Storage manifest correction updated `allowedEnabledServices`, but the local preflight still rejected the manifest because it independently derives that aggregate from `requiredServices` plus `preExistingPlatformServices`.

## Root cause and correction

The deployment manifest has two exact owners for the same classified inventory: a source classification list and the aggregate allowed list. `firebasestorage.googleapis.com` was added to the pre-existing platform classification as well as the aggregate. Both lists now retain exact-set validation.

## External effect

None. No service or external resource changed.
