# C31E photo privacy acceptance overbroad identity erasure — 15 August 2026

The first C31E ticket draft said a photo-message response must hide owner and
thread IDs. That wording was broader than the intended private-Storage rule:
the established authenticated Chat message response legitimately identifies
the sender and its current target conversation to participants.

The correct privacy boundary hides the internal Storage object path,
generation, upload owner/thread binding metadata, binding digests and signing
details. A participant may still receive the same sender and target-thread
fields that text messages already use. Short-lived read URLs are issued only
after participant membership is verified.

This specification defect was found before backend or Flutter runtime source
was changed. The ticket, assessment hash and machine state must be corrected
before implementation begins.

The ticket now scopes redaction to internal Storage fields, the new ticket hash
is bound in MVP state, and both regression-memory and MVP scope gates pass.
