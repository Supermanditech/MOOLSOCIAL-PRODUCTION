# C29W assumed ticket filenames nonterminating-read rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Result: partial output rejected

A read-only structured probe guessed several C29N-C29R filenames. Missing paths emitted nonterminating errors while PowerShell still returned partial JSON and exit code zero. The partial output was not used. Future ticket reads first resolve exact files with a narrow ticket-ID search, validate every path, and use terminating error handling. No build, install, or provider mutation occurred.
