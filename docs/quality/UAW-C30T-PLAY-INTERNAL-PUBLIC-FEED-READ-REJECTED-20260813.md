# C30T Public Feed read rejected on Play-installed r60.44 — 2026-08-13

On the OPPO Play installation `1.0.0-r60.44 (2026081244)`, a fresh accessibility hierarchy on the current Feed route showed:

- `MOOLSOCIAL / Your Feed / PUBLIC FEED`;
- `We couldn’t refresh your Feed`;
- `Your Feed stays clear until real MoolSocial posts are available.`;
- separate **Try again** and **Create a post** actions;
- `MoolSocial posts stay in Feed. YouTube-hosted content stays in Shorts and Videos.`

The preserved real C30K Dev corpus (three Firebase Auth authors, 36 posts and 48 media across all six required formats) was not visible. Exactly zero Create writes were attempted because live Feed read and App Check qualification did not pass.

The screenshot named `tmp/c30s-oppo-r60-44-feed-read-rejected.png` is explicitly invalid for this ticket because the founder navigated to Work before that later screenshot was captured; see `UAW-C30S-FEED-SCREENSHOT-STATE-CHANGED-BEFORE-CAPTURE-20260813.md`.
