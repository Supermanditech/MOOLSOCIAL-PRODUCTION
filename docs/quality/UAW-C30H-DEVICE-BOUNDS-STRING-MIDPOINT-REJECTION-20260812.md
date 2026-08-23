# REG-20260812-1383 — C30H device bounds string midpoint rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Phase: OPPO live-state replay
- Failure: PowerShell concatenated the XML bound strings before division, converting `[112,1354][236,1442]` into the impossible midpoint `56118,6770721`.
- Rejection: The action did not navigate and `12-home-after-live-action.*` is retained only as rejected calculation evidence.
- Permanent prevention: Convert every captured bound component to an integer before addition, range-check the midpoint against the live physical display, then perform the action and assert the destination.
- Protected state: No rebuild, reinstall, uninstall, data clear, downgrade or deployment occurred.
