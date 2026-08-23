# C31E signed read URL opaque object-name redaction overclaim — 15 August 2026

A direct Cloud Storage V4 signed read URL necessarily contains its object name
as part of the URL path. The C31E ticket still claimed no internal object path
could appear anywhere in a participant response, which was stronger than the
selected direct-signed-URL architecture can truthfully provide.

The correct minimum-disclosure contract uses a random UUID-only object name
under a fixed private prefix. The object name contains no user ID, thread ID,
filename, profile or business identifier. Raw object path, generation,
owner/thread binding digests and signed upload headers are not separate
message fields. A participant receives only the short-lived signed read URL
after membership verification, and that URL necessarily carries the opaque
locator until it expires.

The requirement must be corrected and rehashed before attachment-store tests
are authored. No device, backend, Storage or external state changed.

The ticket and preselection now state the exact URL disclosure boundary, the
ticket hash is rebound in MVP state, and memory and scope gates pass.
