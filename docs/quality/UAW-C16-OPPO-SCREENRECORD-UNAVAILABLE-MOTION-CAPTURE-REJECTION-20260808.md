# C16 OPPO screenrecord-unavailable motion-capture rejection

## Incident

The optional predecessor motion-video attempt started the OPPO
`screenrecord` command in a hidden host process, but the process exited `127`.
A direct discovery then returned no device `screenrecord` command and the
expected remote MP4 did not exist. No video was pulled or admitted as evidence.
The interaction end state was truthfully captured as Ride / Cab and the failed
attempt is not represented as the intended motion sequence.

No install, app data, accepted reference, production source or protected
runtime state changed.

## Root cause and prevention

The physical ColorOS image does not expose Android's optional `screenrecord`
binary. C16 verifies device capture capability before choosing a recorder and
never infers evidence from a background process exit. Predecessor motion proof
uses fresh, semantics-verified screenshot frame sequences for left, right and
cross-route transitions; each frame is individually checksummed and the final
state must match the paired UIAutomator dump.
