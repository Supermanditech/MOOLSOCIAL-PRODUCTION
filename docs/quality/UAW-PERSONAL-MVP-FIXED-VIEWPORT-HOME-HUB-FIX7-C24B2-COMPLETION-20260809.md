# C24B2 fixed-viewport Home hub completion — 2026-08-09

## Outcome

`PersonalMoolRootV2` now provides one fixed, non-scrolling Home viewport with six main families in a 3 × 2 selector and only the selected family's two-to-four direct actions. Redundant Home branding, welcome, area and decorative chrome were removed. Chat, Back, direct routing, semantics and reduced motion remain available.

The first rendered candidate exposed sparse actions stretched through a tall card. REG625 records that rejection. The qualified render instead uses a compact, top-aligned, content-driven action sheet with uniform 60 px action rows and unused space outside the surface.

## Evidence

- OPPO-class render: `apps/mobile/test/ui_v2/universal/candidate_captures/mool-home-c24b2-oppo-360x800.png`
- Fixed viewport tests: 320 × 568 at 1.4 text scale, 390 × 844, 430 × 932 at 1.3 text scale — passed.
- Consolidated seven-file compatibility batch — 48 passed, 1 evidence capture skipped, 0 failed.
- Affected source and focused test analysis — no issues.
- Regression memory — passed with 625 entries and 340 applicable.
- MVP delivery and selected scope gates — passed.

## Boundary

No APK was built or installed. OPPO r60.22 and checksum identity `778C9338DAFDEC3693337D54410946C75F9B6B1BB5977D822DF2CF7E38D9D850` remain preserved.
