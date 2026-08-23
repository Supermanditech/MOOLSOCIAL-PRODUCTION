# C30T regression-memory release BuildMode enum failure — 2026-08-13

## Outcome

After the authoritative C30T reconcile, release-readiness and wrapper gates
passed, an additional read-only regression-memory probe invoked phase build
with BuildMode release. The checker rejected the call before execution because
its declared BuildMode set is exactly none, debug and profile.

No build authority was activated or consumed. Build, upload and install counts
remain zero. No source artifact, device or external service changed.

## Root cause and prevention

The auxiliary probe inferred a release-mode enum from the AAB artifact instead
of copying the checker parameter declaration. C30T release control continues to
use its existing exact AAB gate, which deliberately invokes regression memory
under its declared implementation boundary. No retry of the rejected invented
enum is permitted. Every future direct checker invocation first reads and
copies both ValidateSet declarations.

Because the regression registry and this evidence are source-sealed, both
no-AAB qualification cycles must be repeated before build authority can be
activated.
