# C28F OPPO qualification completion

State: `FOUNDER_APPROVED_PROTECTED`

- Ticket: `UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-OPPO-QUALIFICATION-FIX12-C28F`.
- Classification: `mvp_required`.
- Branch/HEAD: `remediation/prototype-conformance-2026-07-20` /
  `f6dfe7587aa02d782e94282d14af8bafff48ded0`.
- Candidate: `1.0.0-r60.28` / `2026081028` / profile.
- Build count: one; wrapper provenance retained.
- Device-reaching install count: one in-place upgrade; data and first-install
  time preserved.
- Installed SHA-256:
  `FD0C1BDE24A1892C7A4E8B82504B19A88057CB63FACAE22E3BE014573843AEE6`.
- First native bounds gate: passed before interaction at minimum `54x44`.
- Full device matrix: 28/28 states, 6/6 families, 17/17 local actions passed.
- Matrix digest:
  `121AC65AFD2730CAFC3318AE57C772FBBFCFC4821A37FFD42CEB1466650046BF`.
- Permanent regression memory remained active; every newly observed failure or
  false assumption was registered before correction.
- Installed r60.28 remains preserved for founder review.
- No commit, push, deploy, promotion, Production write, credential access,
  provider/customer communication, funds movement, uninstall, clear or
  downgrade occurred.

Primary evidence:

- `artifacts/quality/uaw-personal-mvp-android-navigation-exported-semantics-oppo-qualification-fix12-c28f-r60-28-20260810-01/12-build-validation.md`
- `artifacts/quality/uaw-personal-mvp-android-navigation-exported-semantics-oppo-qualification-fix12-c28f-r60-28-20260810-01/16-installed-runtime.md`
- `artifacts/quality/uaw-personal-mvp-android-navigation-exported-semantics-oppo-qualification-fix12-c28f-r60-28-20260810-01/19-first-native-bounds-gate-pass.md`
- `artifacts/quality/uaw-personal-mvp-android-navigation-exported-semantics-oppo-qualification-fix12-c28f-r60-28-20260810-01/56-cumulative-device-matrix.md`
- `config/mvp-personal-android-navigation-device-matrix-c28f.json`

Founder decision received on 10 August 2026: C28F r60.28 is approved and
protected. The exact decision boundary is recorded in
`docs/quality/UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-OPPO-QUALIFICATION-FIX12-C28F-FOUNDER-APPROVAL-20260810.md`.
This approval is not promotion and grants no successor build or install.
