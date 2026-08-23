# REG2891 — C34L retained FIX2 real-recovery journal path missing

- Status: registered first real-recovery fixture failure after retained negatives progressed.
- Failure: fixture inventory called `Get-ChildItem` on `<fixture>/evidence/transactions`, which did not exist after the confined recovery setup.
- Root cause: the fixture assumed a journal directory location before binding it to the authoritative transition/recovery path contract, or the setup did not create the required prepared transaction.
- Prevention: inspect the transition and recovery owners' exact confined journal-path derivation, assert the expected directory/file exists before enumeration, and create it only through the real fixture transition/recovery workflow—never by a shadow path.
- Containment: no diagnosis, retry, WinPS, real release state, device, private, or external action followed.
