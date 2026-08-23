# C24D connected-launcher global Chat continuity rejection

- Observed: 2026-08-09 during protected Screen04 qualification.
- Rejected state: `MoolDestinationNavigationV2` forwarded `onOpenChat`, but the new single-launcher `MoolGlobalNavigationV2` and connected chooser never exposed or called it.
- Customer impact: after the founder-approved removal of the multi-button dock and top destination icons, Chat was no longer globally reachable from the single persistent destination control.
- Required correction: keep exactly one bottom `MoolSocial` launcher; place one 48px Chat utility action inside its connected chooser; close the chooser before opening Chat; system Back must restore the exact originating destination and substate.
- Prohibited correction: do not restore the old dock, add a second persistent button, add redundant top branding/navigation, or route through Home.
