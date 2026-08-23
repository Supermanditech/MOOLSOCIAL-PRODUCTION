# C22F1 placement regression replay invoked obsolete C21B sequential gate

- Observed: 2026-08-09 after C22F1 focused tests and full Flutter analysis
  passed.
- Rejection: `check-personal-subaction-placement-regression.ps1
  -RequireImplemented` still classified its permanent contract as C21 and
  invoked the C21 implementation chain. C21B then demanded that the current
  C22F1 ticket exist inside the historical C21 sequence and rejected with
  `C21B sequential MVP selection and disclosure gate is not active`.
- Root cause: C22 changed the durable placement/design contract to fixed
  capsules, zero strap and reverse-U, but the permanent placement registry was
  never migrated from the rejected C21 optical-glass token/sequence owner.
- Prevention: the placement contract and checker explicitly recognize C22,
  freeze current capsule placement/geometry/legibility outcomes and dispatch
  to the current C22F1 gate during remediation or the C22G cumulative gate
  after restart. Historical C21 gates remain unchanged for historical C21
  replay only.
- Qualification: C22F1 analysis is clean, but the failed protected-gate run is
  not completion evidence and must be rerun after this migration.
- Device effect: none; build/install remained closed and r60.20 unchanged.
