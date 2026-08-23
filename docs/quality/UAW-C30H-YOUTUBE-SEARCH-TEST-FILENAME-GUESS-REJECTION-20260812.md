# REG-20260812-1386 — C30H YouTube Search test filename guess rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Phase: read-only device-label lookup
- Failure: An `rg` command included the guessed path `apps/mobile/test/social_v2_consumer_youtube_search_c30c_test.dart`, which does not exist, and exited non-zero despite returning production-source matches.
- Permanent prevention: Discover the exact test path with `rg --files` before including it in any lookup. Never append a remembered or inferred filename to a gate/search command.
- Protected state: Read-only failure only; no device action, build, install or deployment occurred.
