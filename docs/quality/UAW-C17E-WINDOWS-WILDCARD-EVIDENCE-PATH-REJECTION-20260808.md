# C17E Windows wildcard evidence-path rejection

Date: 2026-08-08

A C17E lookup passed `docs/quality/...C16H*` as a Windows ripgrep path operand.
Ripgrep rejected that path even though an earlier source operand returned valid
motion-token lines. The command's evidence-search portion is discarded. Future
lookups use verified literal directories with `-g` filename filters; source
motion values are re-read independently where needed.
