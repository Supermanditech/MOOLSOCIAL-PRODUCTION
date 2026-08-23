# Post-C33D C09 global Home semantics, copy and overflow failures

Date: 2026-08-15

Command owner:
`apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c09_test.dart`

Result: 2 passed, 3 failed.

The three exact failed cases were:

1. `selected Home is visibly first-class and retap is inert` found zero
   semantics labels matching `Mool Home, current`.
2. `missing area uses customer wording without engineering rationale` found
   zero widgets with text `Your area`.
3. `untouched compact rail announces and shows overflow` found zero semantics
   labels named `More MoolSocial options. Swipe horizontally to explore all 6.`

The contract declaration case and finite/reduced-motion case passed. No retry
or mutation followed. C07, R15, FIX2, C27B and C27D had already passed in the
same read-only audit, so the three C09 expectations require exact successor
attribution rather than a broad navigation rewrite.

## Attribution and resolution

`REG-20260813-1713-C30T-EXPANDED-SUITE-INCLUDED-SUPERSEDED-GLOBAL-CONTRACTS`
and its retained disposition explicitly classify C09's area/copy/action-grid
Home and old overflow rail as historical. The current replacements are C24B2's
fixed six-domain Home and C24B3's connected action navigator.

C24B2 passed 4 with 1 declared capture skip. C24B3 passed 8 with 1 declared
capture skip. C09 was not retried or edited, no ticket was selected, and the
retired UI was not restored. The incident is a repeated test-selection mistake,
not a current production-source defect.

No build, Play, OPPO, backend/provider, credential or external action occurred.
