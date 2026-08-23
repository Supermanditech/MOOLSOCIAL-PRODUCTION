# Full Chat backend test directory guess rejection

Date: 2026-08-14
Registry ID: `REG-20260814-2119-FULL-CHAT-BACKEND-TEST-DIRECTORY-GUESS-REJECTION`

The first backend Chat symbol inventory included guessed `backend/functions/test` and `backend/functions/tests` directories. Neither exists. Current Chat backend tests are colocated under `backend/functions/src/chat`.

The corrected inventory must search only exact paths returned from the bounded `backend/functions/src` file enumeration. The partial output from the nonzero command is not accepted as qualification evidence. No Chat source, backend, test, reference or machine state was changed by the failed command.
