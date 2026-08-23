# C29W compact Flutter carriage-return output-truncation recurrence

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Cycle 2 result: 24 format owners unchanged; full analysis clean; 149/149 assertions passed

Flutter's compact reporter uses carriage-return terminal refreshes. The tool transport expanded those refreshes and again truncated the middle of the transcript, although the final `All tests passed`, assertion total and exit code zero were preserved. Future broad suites use a bounded rolling tail while preserving the child-process exit code; reporter selection alone is not accepted as an output bound. No source, build, install or provider mutation resulted.
