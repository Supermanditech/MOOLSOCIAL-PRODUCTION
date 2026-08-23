# UAW C31C MVP scope large-patch output truncation

## Incident

The first C31C update to `config/mvp-scope-gate-state.json` was sent as one
large multi-hunk patch. The patch tool reported that its output exceeded the
available context and was truncated. That response is zero admissible evidence
for the resulting machine state even though the patch operation is atomic.

## Detection

A separate bounded read proved that the state file still parses as JSON and
contains C31C selection markers. Exact nested authority values were not inferred
from remembered paths; the current schema must be enumerated before the gate is
accepted.

## Prevention

Future large machine-state updates are split into bounded exact blocks. Each
block is followed by JSON parsing, current-property enumeration and one compact
projection of the required non-null fields. The regression-memory gate and the
exact MVP scope gate must pass before any C31C runtime or backend mutation.

No application source, backend source, build, deployment, device state, live
data or credentials were touched by this incident.
