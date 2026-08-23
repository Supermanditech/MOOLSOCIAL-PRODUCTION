# UAW-C33F FIX3 build-rejection wrapper message classifier too narrow

- Recorded at: `2026-08-15T10:51:11.3883382Z`
- Regression: `REG-20260815-2401-C33F-FIX3-BUILD-REJECTION-WRAPPER-MESSAGE-CLASSIFIER-TOO-NARROW`

The C33F build-phase gate returned nonzero at 2/4 readiness as required. The surrounding verification wrapper then rejected its own guessed message classifier before producing the intended state-equality result. No Flutter build, AAB, upload, Play action, or OPPO action ran.

The retry first captures only the bounded actual rejection line, then binds nonzero rejection and byte-identical state/aggregate/readiness hashes on both PowerShell hosts.
