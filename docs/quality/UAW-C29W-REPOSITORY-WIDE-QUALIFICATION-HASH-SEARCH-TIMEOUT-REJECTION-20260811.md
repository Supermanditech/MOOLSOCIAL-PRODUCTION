# C29W repository-wide qualification-hash search timeout rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Result: timed-out output rejected

A fixed-string search for a known C29T qualification hash was incorrectly rooted at the repository and timed out. It made no mutation and its output was not used. Qualification/evidence searches are now restricted to their exact `config` and `docs/quality` owners with hard result bounds; repository-root evidence searches are not retried.
