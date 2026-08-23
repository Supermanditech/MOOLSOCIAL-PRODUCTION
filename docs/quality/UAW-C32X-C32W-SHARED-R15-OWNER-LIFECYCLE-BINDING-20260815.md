# C32X C32W shared R15 owner lifecycle binding

## Finding

After C32X produced a clean 16/16 R15 result, the predecessor C32W gate still
required the exact intermediate R15 hash that represented C32W's preserved
15-pass/1-hidden-failure state. C32X is authorized to migrate the remaining
hidden assertion block in that same test owner, so a final historical gate
replay would reject the legitimate successor bytes.

## Classification

This is a fail-closed gate-lifecycle defect, not a production runtime defect.
C32W's intermediate machine state and qualification document preserve its
exact historical hash and result. The executable predecessor gate must accept
the intermediate hash only while C32W is active, and otherwise require either
the active C32X binding or a preserved qualified C32X assessment before it
accepts the final successor hash.

## Repair boundary

- Keep the C32W ticket and intermediate evidence immutable.
- Do not weaken any current R15 source assertion.
- Bind the shared test owner to C32X's exact final hash only through an active
  C32X selection or a preserved qualified C32X assessment.
- Keep runtime, backend, build, device, external-service and secret authority
  closed.

No predecessor-gate retry is evidence until this mistake is registered in the
permanent regression memory and the corrected gate passes on both PowerShell
hosts.

## Result

REG-2289 was registered before repair. The C32W gate now requires its
intermediate R15 hash only while C32W is active. Under C32X it requires the
exact active C32X ticket binding and final R15 hash; future scopes must preserve
a qualified C32X assessment. C32W and C32X then passed on PowerShell 7 and
Windows PowerShell.
