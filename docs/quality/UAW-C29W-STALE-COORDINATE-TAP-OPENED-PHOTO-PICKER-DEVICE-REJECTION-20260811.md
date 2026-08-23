# C29W stale-coordinate tap opened Photo Picker device rejection

- Date: 2026-08-11
- Candidate: `1.0.0-r60.35` (`2026081135`)
- Evidence: `artifacts/quality/uaw-personal-mvp-social-fresh-client-preproof-oppo-qualification-c29w-r60-35-20260811-01/18-shorts-loaded.png`

A coordinate intended for the Shorts dock was reused after several route transitions without first refreshing the semantic tree. The active route had changed and the tap opened Android Photo Picker from an image-post composer. No media was selected, no post was submitted and no app/provider data was written. The picker is exited with Back. Every subsequent consequential tap is bound to a freshly captured content description and bounds.
