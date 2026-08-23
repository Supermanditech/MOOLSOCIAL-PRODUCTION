# C29L guessed backend index test path rejection

The regression-memory gate rejected the first REG-1219 entry because it named
`backend/functions/src/index.test.ts`, a file that does not exist. The path was
inferred from the production `index.ts` owner rather than resolved from the
repository inventory.

The exact inventory confirms the applicable backend tests are the YouTube
configuration, request-contract and provider-service suites. REG-1219 now
references only those existing owners. No product source, provider, build,
device, credential or secret state changed during this false failure.
