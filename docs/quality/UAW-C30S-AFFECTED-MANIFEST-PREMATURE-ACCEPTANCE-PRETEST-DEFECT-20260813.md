# C30S affected manifest premature-acceptance pretest defect

Date: 2026-08-13

Before execution, review found that cycle 1 would copy its fixed accepted test
manifest before tests passed. No cycle used that ordering.

The candidate manifest is now logged before testing, but cycle 1 accepts it
only after tests, release config, dependencies, repository gates, artifact
sentinels and the source fingerprint all pass. Cycle 2 requires the accepted
hash before execution and never overwrites it.
