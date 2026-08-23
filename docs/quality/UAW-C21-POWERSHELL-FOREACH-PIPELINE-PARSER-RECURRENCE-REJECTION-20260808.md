# C21 PowerShell foreach pipeline parser recurrence rejection

Date: 2026-08-08

The initial C21 read-only evidence inventory placed a pipe directly after a
PowerShell `foreach` statement. Parsing failed before any file was read. This is
a recurrence of REG-459. The retry collects loop output into an explicit array
before formatting, and no screenshot or ticket work proceeds until it passes.
