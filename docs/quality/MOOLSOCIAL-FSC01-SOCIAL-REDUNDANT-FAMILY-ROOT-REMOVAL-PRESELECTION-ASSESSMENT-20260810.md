# FSC01 Social redundant family-root removal — preselection assessment

## Exact outcome

A Personal user sees the four direct Social destinations — Shorts, Videos,
Feed and Create — immediately beside the compact Mool switcher without a
second Social identity cell. All four destinations remain one tap, in the same
bottom reach zone, and other family navigation remains unchanged.

## Reuse and duplicate search

- The shared owner is
  `apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart`.
- Social's complete local-action owner is
  `apps/mobile/lib/ui_v2/social/screen04_universal_components.dart`.
- Social integrates the shared shell at
  `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`.
- No second shell, screen, route, state owner or backend is necessary.
- The duplicate is exact: the shell inserts `Social` before a local rail that
  already fully represents the current Social destination family.

Implementation disposition: reuse plus configuration of the existing shared
shell. The smallest change is a Social-specific omission of the family-root
cell. Uniform removal is not selected because Shop still needs its root as the
return path after its duplicate Products cell is addressed separately.

## Robustness coverage

- Mool switcher remains present and first in the rail.
- Shorts, Videos, Feed and Create remain present, ordered and direct.
- No additional tap, route or state transition is introduced.
- Other family-root cells remain present.
- Compact rail height, target geometry, reduced motion and Back behavior remain
  under the existing shared navigation contracts.
- C28D's Android exported-semantics rejection is not treated as resolved. This
  ticket is nonbuild and cannot create an APK candidate.

## Adjustments after audit

- Do not change the accepted global family catalogue.
- Do not change YouTube, Feed, Create or Buy content in FSC01.
- Add focused regression coverage for Social root absence and other-family root
  preservation before running the complete nonbuild navigation gates.

## Exclusions and dependencies

No new screen, route, backend owner, provider call, credential access, build,
install, device mutation, external write, commit, push, deploy, promotion or
Production write is authorized. The exact dirty tree, installed OPPO r60.27
identity, C28D evidence, delivery lock, permanent regression memory and all
accepted navigation owners remain mandatory.

Estimated timeline impact: one day or less, inside the locked 60–75-day plan.
