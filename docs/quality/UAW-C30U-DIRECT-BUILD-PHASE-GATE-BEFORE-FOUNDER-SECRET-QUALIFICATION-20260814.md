# UAW C30U direct build-phase gate before founder secret qualification

Date: 2026-08-14

## Incident

Two fresh C30U source cycles passed identically at 1,145 files and fingerprint
`40E12628AE10DC7243C79F70ACD0CBC2F2D7871157231A9D83AF7287F7BAEC49`.
The agent then directly invoked the AAB state gate with `Phase build`. The gate
correctly rejected single-build readiness because founder-only transient secret
inputs had not yet been qualified by the visible launcher.

No build authority was consumed. Build, upload and install counts remain
0/0/0.

## Prevention

After two source cycles, validate only the exact
`source_qualified_founder_secret_prompt_required` state, `available_once`
authority and zero counts. Do not call `Phase build` directly. Bring up
`tmp/run-c30u-single-aab-founder.ps1` visibly; that wrapper alone collects the
hidden upload-key password and Firebase Android API key, qualifies transient
configuration, calls the build gate at its intended boundary and consumes the
single authority.

Because this mandatory registration changes a sealed memory owner, the two
passing v2 cycle JSONs are preserved but superseded. A versioned final pair must
pass before the launcher is shown.

The exact build gate requires both founder-qualified runtime flags. The visible
launcher verifies they are initially false, obtains the two hidden inputs,
validates them without agent access, sets both flags transiently, invokes the
build gate and clears them again if no authority is consumed. Both machine
states now preserve the v2 pair and summary with exact hashes, expose zero
current cycles and retain mutation counts 0/0/0. Final evidence uses manifest
v4, cycle JSON v3 and summary v3 paths.
