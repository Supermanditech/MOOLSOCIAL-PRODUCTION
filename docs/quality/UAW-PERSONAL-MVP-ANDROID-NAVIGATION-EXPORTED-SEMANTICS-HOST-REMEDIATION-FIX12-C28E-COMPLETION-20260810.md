# C28E Android exported-semantics host remediation completion

- Ticket: `UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-HOST-REMEDIATION-FIX12-C28E`
- Date: 2026-08-10
- State: complete
- Qualified source fingerprint:
  `52E505B59809E920ED128E16CE8AD0DB0DDD7CB7CEAE0C3C8C5CD89CAA3B3989`
- Cycle 1 evidence:
  `artifacts/quality/uaw-c28e-host-qualification-20260810-04/qualifying-cycle-1.json`
- Cycle 1 evidence SHA-256:
  `5E331824CA86F6B7CF1FDA948048F0B93A183491BDB3847B6EC0D470AC91EA6E`
- Cycle 2 evidence:
  `artifacts/quality/uaw-c28e-host-qualification-20260810-04/qualifying-cycle-2.json`
- Cycle 2 evidence SHA-256:
  `B87A444576C69C6FDFE286B1DC6B20805FB42D4B3B381677B8B90A7A4AA3184C`

Both consecutive cycles used the same source fingerprint. Each cycle completed
clean formatting across 57 owners, the complete mobile analyzer, 53 required
Flutter test files with 374 passing tests and 11 intentional skips, and all 22
machine gates before and after the suite.

The implementation explicitly selects Android edge-to-edge mode and derives a
shared Android-only bottom clearance from raw FlutterView inset geometry. The
accepted 58-pixel rail, direct routes, one-handed position, FSC01 Social-root
removal and FSC06 Products/local-Shop removal remain intact. The protected Buy
seal passed, and the additive protected Social candidate seal contains exactly
one authorized legacy test-owner migration with no Social runtime change.

No APK was built or installed during C28E. OPPO retained rejected r60.27,
version code `2026081027`, installed APK SHA-256
`E4651AEADFD2A98A7617021B8DEF645BC5D428DD1593D882D278F3706FF6BD0C`.
Build, install, backend and external-service authority remained closed.

C28E grants no device acceptance. A separately selected, checksum-unique OPPO
candidate is required before any build or install.
