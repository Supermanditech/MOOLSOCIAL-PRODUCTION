# C33N r60.52 postbuild registry-change rejection

Date: 2026-08-16 IST

Candidate `UAW-C33N-R60-52-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE`,
version `1.0.0-r60.52` / `2026081352`, is rejected before Play upload.

The single authorized AAB succeeded and its dual-host postbuild gate passed:

- SHA-256: `E56BF124B3F46D27D34387A5AB6B12012125227095026EAB04CEC56B69A2E8A3`
- bytes: `94797520`
- counts: build/upload/install/device acceptance `1/0/0/0`
- secret transients: absent after launcher cleanup
- secret values observed by Codex: false

The AAB was sealed against regression registry 2,581 with SHA-256
`F3F450AE9D248583BDE26A8C89CF089E731BAF20F1AC954D48A6FDAE1DB58DD9`.
REG2611 and REG2612 were then truthfully added before any Play action. The
registry is now 2,583 entries with SHA-256
`810D4D54F29816BF0A6A6EEA98E1DDEDB0BD70012F7A08AAE728E0878F468005`.
That exact post-seal change triggers the candidate's fail-closed promotion
rule. The AAB must never be uploaded, installed, reused, repaired, rebuilt or
promoted. No Play, OPPO, provider, deployment, email or SMS action occurred.

A separately prepared, selected, sealed, twice-qualified and founder-approved
successor is required before another AAB can be considered. No waiver applies.
