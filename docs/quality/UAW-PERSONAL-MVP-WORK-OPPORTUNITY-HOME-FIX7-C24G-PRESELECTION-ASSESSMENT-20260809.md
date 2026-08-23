# C24G Work opportunity home preselection assessment — 2026-08-09

Customer outcome: Earn Today and Workspace open calm, direct Work homes where
the next decision is visible with truthful matching, pay, distance or location,
timing and verification context.

The bounded native inventory found six existing Work production owners,
existing `/app/work/earn` and `/app/work/my-work` routes, one WorkSession, one
ReviewWorkGateway and the shared service-home primitives. Exact duplicate
search found no need for a new screen, route, backend, persistent state owner or
subaction. The implementation disposition is reuse plus configuration.

The current first-party homes still contain the rejected horizontal
`work-local-navigation` rail below the connected destination shell. Earn Today
also leads with a dense dark promotional panel and hides the useful opportunity
decision behind expansion; the visible aggregate income and live-count copy is
not derived from the displayed opportunity inventory. Workspace uses the same
rail and a visually heavy onboarding panel. These are presentation defects,
not authority to change Work business routes or state.

Minimum work is therefore limited to the existing WorkPageScaffold,
WorkEarnScreen, MyWorkScreen and focused Work tests: remove the duplicate local
rail, reuse `MoolServiceSearchField`, `MoolServiceSectionHeader`,
`MoolServiceCard` and `MoolServicePrimaryButton`, keep Earn Today and Workspace
as the only Work actions in the shared connected chooser, show opportunity pay,
location/distance, timing and verification before the direct review action, and
retain the existing workspace setup and operating routes. No delivery onboarding,
new product category, fake live feed, copied reference asset or backend is in
scope.

Required qualification covers 320, 390 and 430 widths, 140% text, real tap
semantics, finite/reduced motion, search/filter/direct review, Workspace next
action, Back/Chat/MoolSocial continuity, complete affected Work tests, analyzer
and all repository gates. Build and install remain closed.
