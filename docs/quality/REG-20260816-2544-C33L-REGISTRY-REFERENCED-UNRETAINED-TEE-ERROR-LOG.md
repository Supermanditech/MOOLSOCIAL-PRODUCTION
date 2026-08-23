# REG-20260816-2544 — registry referenced an unretained Tee error log

`Tee-Object` retained successful pipeline output but not the terminating FIX1
error stream, so the anticipated log file did not exist when REG-2543 first
referenced it. Regression memory correctly failed closed.

Before retry, the bounded sanitized command identity, nonzero exit, exact public
gate rejection, zero release counts, privacy boundary, and invalidated-seal
state were reconstructed with `apply_patch`. Future registry changes must verify
every evidence path with `Test-Path` first.
