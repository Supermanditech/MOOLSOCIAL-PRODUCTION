# C30A loaded Feed post-CTA test migration rejection

The independent Feed ownership test retained an absence assertion for `screen04-feed-create-post`. The founder-approved C29Z contract requires real public content first and one posting-ready CTA after the timeline. The test must assert that order instead of rejecting the CTA.

Regression: `REG-20260811-1354-C30A-LOADED-FEED-POST-CTA-TEST-MIGRATION-REJECTION`.
