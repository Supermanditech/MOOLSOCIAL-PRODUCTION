# C20 guessed brand-gate filename rejection

Date: 2026-08-08

The first permanent regression-memory check after registering the C20 visual defects rejected REG411 because it referenced `scripts/check-brand-identity-token-regression.ps1`, which does not exist. The check failed before any runtime, build, install or device mutation.

A bounded `rg --files scripts` inventory identified the authoritative existing checker as `scripts/check-brand-integrity.ps1`. REG411 now uses that exact path. Future regression entries must inventory checker paths before registration.
