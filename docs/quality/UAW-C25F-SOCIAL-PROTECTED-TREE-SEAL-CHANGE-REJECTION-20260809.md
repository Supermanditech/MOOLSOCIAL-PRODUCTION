# C25F Social protected tree seal change rejection

- Date: 2026-08-09
- Gate: `scripts/check-social-protected-baseline.ps1`
- Expected tree: `8c7e7e659633424847c7f487808ff304b50e0614cd91112c1d483cf34acb8dc1`
- Observed tree: `f14042e33d20d6f109b0977ee959877ecf1fa298c0476c52fca3a210efbc9222`
- Status: mutation paused for exact protected-delta audit

The C25F protected Social gate rejected the current tree after the founder-authorized C25 navigation/header work. The seal is not being rewritten automatically. Every protected Social delta must first be reconciled to approved chrome-only changes, with business content and behavior shown unchanged. A successor seal is permitted only after that audit passes and is durably evidenced.
