# C27D active-only test-authorization gate preflight rejection

When C27D moved from active to complete, its newly created durable gate still
required `testOrGateWriteAuthorized` to be true unconditionally. Completion
correctly closes that authorization, so the condition would have rejected the
completed ticket and every successor.

The write-authorization assertion is therefore selection-time only. Active
C27D requires exact scope plus test/gate authorization; completed C27D requires
the authorization to be closed while its durable source/test contract remains
enforced.
