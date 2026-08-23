# UAW C33F MVP delivery-lock unsupported CandidateId parameter

Date: 2026-08-15
Regression: `REG-20260815-2362-C33F-MVP-DELIVERY-LOCK-UNSUPPORTED-CANDIDATE-ID-PARAMETER`

The r60.49 pre-ticket checkpoint confirmed all 14 named reuse owners exist, then invoked `check-mvp-delivery-discipline-lock.ps1` with a guessed `-CandidateId` argument. That script does not expose the parameter, so PowerShell stopped before the delivery lock ran. The ticket was not created or selected and no product, release, device, provider, or external-service state changed.

Recovery: register before retry, inspect the exact gate param block, and invoke only documented parameters. Extend the prior exact-path rule into an exact-path-and-parameter-contract rule for every remaining release-preparation command.
