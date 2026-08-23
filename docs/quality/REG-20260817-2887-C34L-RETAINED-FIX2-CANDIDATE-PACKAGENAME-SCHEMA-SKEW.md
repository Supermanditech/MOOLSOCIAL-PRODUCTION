# REG2887 — C34L retained FIX2 candidate packageName schema skew

- Status: registered first fresh PowerShell 7 retained/recovery behavior failure after REG2886.
- Failure: retained validation rejected `candidate is missing property packageName` before qualification.
- Root cause: the strengthened candidate schema is not aligned with the authoritative asymmetric C34L state contract: detailed candidate owns package/track/device identity while aggregate candidate is intentionally minimal.
- Prevention: validate exact detailed and aggregate candidate schemas separately; bind their shared id/version/count/disposition fields and require package identity only from the authoritative detailed state and final proof/evidence. Do not invent aggregate package/device fields. Add a missing-detailed-package negative.
- Containment: no retry, WinPS, diagnosis, mutation, recovery, release, private, device, or external action followed.
