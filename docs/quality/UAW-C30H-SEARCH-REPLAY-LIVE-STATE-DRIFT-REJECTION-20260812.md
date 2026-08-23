# REG-20260812-1382 — C30H Search replay live-state drift rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Phase: OPPO device replay
- Failure: The first coordinate-driven Search replay used the prior stable-Home hierarchy, but the post-action native capture showed Feed was active before the text-input sequence. The resulting artifacts are not Search evidence.
- Rejection: `09-search-entry.*` and `10-search-results.*` remain preserved as rejected replay-attempt evidence and must never be claimed as Search proof.
- Permanent prevention: Before every device interaction, capture and parse the live hierarchy, derive the action bounds from that exact capture, perform only that action, then assert the expected destination in a fresh hierarchy before the next interaction.
- Protected state: r60.38 remains installed once in place. No rebuild, reinstall, uninstall, data clear, downgrade or deployment occurred.
