# Successor wrapper stale r60.47 success label

Date: 2026-08-14
Incident: `REG-20260814-2164-AAB-SUCCESSOR-WRAPPER-STALE-R60-47-SUCCESS-LABEL`
State: registered before correction

The generic single-AAB wrapper static gate accepts the C30X successor contract,
but its final success output still says `one dynamic r60.47 appbundle authority`.
That label is false: r60.47 is the permanently failed Play-installed candidate,
and C30X explicitly rejects reuse of its identity.

This did not build or mutate a candidate. The required correction is a bounded
gate-evidence change under an exact ticket: name the dynamic successor contract,
and statically reject the stale r60.47 success label without weakening any
historical r60.47 preservation assertion.

## Resolution

The wrapper static gate now emits `dynamic successor-contract appbundle
authority`, and an executable assertion rejects any r60.47 token in the
success evidence. The full gate passes on PowerShell 7 and Windows PowerShell.
