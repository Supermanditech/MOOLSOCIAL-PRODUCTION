# AAB negative phase empty-path binder rejection

Date: 14 August 2026
Scope: source-only C30X hard-gate negative testing

The combined negative phase test reached `postupload` while no AAB exists.
PowerShell rejected the empty artifact path at parameter binding before the
gate could emit its exact C30X evidence rejection. The phase still failed
closed and no action ran, but the diagnostic owner was not precise enough.

The correction permits an empty string through helper binding only so the
gate can reject it explicitly, and validates phase state/count transitions
before artifact or evidence resolution. No AAB, Play/OPPO action, deployment
or secret access occurred.

## Resolution

The helpers now route empty evidence through the exact C30X rejection, and
every phase validates its state/count transition before artifact resolution.
The build, postbuild, preupload, postupload, preinstall, postinstall and
journey negative gates all fail closed with phase-specific messages.
