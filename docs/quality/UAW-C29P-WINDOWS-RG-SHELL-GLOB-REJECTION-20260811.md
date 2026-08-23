# C29P Windows rg shell-glob rejection

Two bounded searches used a shell-style `*.ts` path operand that Windows passed literally to rg. Later searches name the directory and use rg's `--glob`; the failed mixed result was not admitted.
