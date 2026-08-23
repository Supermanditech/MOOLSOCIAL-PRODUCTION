# C25F Buy protected tree seal change rejection

- Date: 2026-08-09
- Gate: `scripts/check-buy-protected-baseline.ps1`
- Expected tree: `17860efaf77eea199e0e6874e6e91ceb560936ce782693bcca33d2740898acfd`
- Observed tree: `37d946cd050d378a9ee60fd8b19716f59acba25dbc0c0593a9136668fcd120e7`
- Status: mutation paused for exact protected-delta audit

The C25F protected Buy gate rejected the current tree after the founder-authorized C25 navigation/header work. The predecessor seal remains preserved and is not being overwritten. Every protected Buy delta must be reconciled to the approved presentation-only route projection, compact rail and Chat header scope, with catalogue, cart, order, payment, provider and session behavior unchanged, before a successor seal may be issued.
