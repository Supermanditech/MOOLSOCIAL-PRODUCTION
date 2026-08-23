# C25F C24B3 connected navigator predecessor launcher rejection

- Date: 2026-08-09
- Status: registered before test migration

Eight active C24B3 presentation tests still required the removed destination `mool-home-launcher`. The production destination shell now owns the 44 px `mool-compact-launcher`, while Chat is deliberately outside the main-only menu as a direct header action.

The migration preserves direct family routing, unchanged-destination Back dismissal, adaptive widths and reduced-motion assertions. It replaces only the rejected launcher key and changes the predecessor two-tap menu Chat test into the direct `eat-global-chat` one-tap contract.
