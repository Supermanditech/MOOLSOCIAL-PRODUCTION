# REG-20260816-2629 — C33R read-only inventory repeated a foreach pipeline parser error

Date: 2026-08-16 IST

A read-only required-file inventory piped directly from a PowerShell `foreach`
statement. PowerShell rejected the empty pipeline element before reading a
file. No repository, candidate, process, browser, Play or device state changed.

The failed inventory is not counted. Known required owners are read by their
literal paths. Any future generated inventory must emit directly or wrap the
collection in parentheses, and composed PowerShell is parsed before execution.
