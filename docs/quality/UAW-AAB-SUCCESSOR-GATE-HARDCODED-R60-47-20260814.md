# UAW AAB successor gate hardcoded to r60.47

## Finding

The historical C30V gate requires version code `2026081347` and version name
`1.0.0-r60.47` in its post-upload, post-install and journey phases. The generic
single-AAB wrapper recognizes only C30V, C30U and C30T contracts. No new
successor contract is currently callable through that wrapper.

## Risk and required repair

The failed r60.47 state cannot truthfully represent a successor candidate. A
new exact candidate gate/state must derive every version comparison from its
own candidate object, be explicitly allowlisted by the wrapper and retain the
failed r60.47 owners unchanged as historical evidence.

## Resolution

C30X now owns a dynamic successor state and eight-phase hard gate. The generic
wrapper explicitly recognizes its contract, every postbuild/Play/install
comparison derives from the successor candidate object, and reconcile checks
that failed r60.47 remains failed with build/upload/install counts 1/1/1.
