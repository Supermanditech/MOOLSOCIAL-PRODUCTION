# C24D Screen04 repeated Videos attribution-owner rejection

- Observed: 2026-08-09 in the focused Screen04 connected-navigation cycle.
- Rejected assertion: `screen04-youtube-attribution` was expected once, but three visible discovery cards each correctly own that attribution key.
- Correction: accept one-or-more matching Videos attribution owners and retain the unique Screen04 root plus direct connected route as state proof.
