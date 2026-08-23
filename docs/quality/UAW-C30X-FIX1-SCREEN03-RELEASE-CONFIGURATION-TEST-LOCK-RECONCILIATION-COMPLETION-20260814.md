# C30X FIX1 Screen03 release-configuration test-lock completion

Date: 14 August 2026
Ticket: `UAW-C30X-FIX1-SCREEN03-RELEASE-CONFIGURATION-TEST-LOCK-RECONCILIATION`

## Outcome

The global approved-UI lock is green again. Screen03 v4 is a new immutable
native-production/test-lock acceptance package. It changes no customer-visible
runtime, UI, route, copy, provider asset, fitment owner, behavior/copy test,
golden test or golden image. Screen03 v1-v3 remain immutable.

The only locked-owner delta from v3 is the already implemented and passing
`apps/mobile/test/platform_configuration_test.dart`, now SHA-256
`725E88030D0687DE86E8770705B55A5A447E09C4CA986439B0B94ADAD80C64B1`.
It retains both the C30W safe release first-frame assertions and the accepted
profile candidate/startup provenance assertions.

During recovery, complete locked-owner comparison proved Screen01 v4—not
v3—is the unique 12/12 byte match. The manifest now has exactly one active
production acceptance for each Screen01–03, all at v4.

## Evidence

- approved manifest SHA-256:
  `9F104DD7B692BCFD68ED8262E187552937F145B877E5176E2A724876909384DB`
- Screen03 v4 checksum-file SHA-256:
  `6145812D6DC4C8812AA5EC0780CFA51524138DB2A5F1EC71FF3B3183DA2C7077`
- Screen03 v4 static-gate SHA-256:
  `D9076FE2F378E8CCFA1A742B49BA118B3AF5EB25FA2840E25CC7D161652557D3`
- focused Flutter result: 10 passed, 0 failed
- PowerShell 7 v4 gate: passed
- Windows PowerShell v4 gate: passed
- global approved-UI lock: passed
- C31C preservation gate: passed
- C30W source gate: passed on both PowerShell hosts
- generic wrapper static gate: passed on both PowerShell hosts
- retained logs:
  `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30x-fix1-flutter-tests-01.log`
  and
  `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30x-fix1-completion-gates-01.log`

No AAB, upload, Play/OPPO action, deployment or secret access occurred under
FIX1. Those actions remain governed by C30X and the founder's separate
end-to-end authorization after every hard gate passes.
