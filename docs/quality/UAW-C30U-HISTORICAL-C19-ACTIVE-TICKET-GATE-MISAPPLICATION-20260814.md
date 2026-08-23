# C30U historical C19 active-ticket gate misapplication

The current approved UI checksum gate passed. A manual follow-up then invoked
the historical C19 acceptance script, which correctly permits only its old C19
or C18D active tickets and therefore rejected C30U.

Current successor qualification uses `check-approved-ui-locks.ps1`. Historical
ticket-specific workflow gates are not reused as timeless successor gates.
No release mutation occurred.
