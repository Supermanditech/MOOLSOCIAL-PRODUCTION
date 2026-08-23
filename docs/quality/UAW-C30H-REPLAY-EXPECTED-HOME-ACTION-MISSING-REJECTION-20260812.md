# REG-20260812-1384 — C30H expected Home action missing rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Phase: OPPO live-state replay
- Failure: The fresh hierarchy contained zero nodes labelled `Open Home, YouTube`, so the guarded Feed-to-Home action stopped before tapping.
- Rejection: `13-feed-live-before-home.xml` is preserved as rejected assumed-state evidence and is not classified as Feed proof.
- Permanent prevention: Classify the current surface from a bounded inventory of live native labels before selecting any action. Never assume a prior surface persists between device commands; derive and range-check the next action only from the classified live hierarchy.
- Protected state: No device action, rebuild, reinstall, uninstall, data clear, downgrade or deployment occurred.
