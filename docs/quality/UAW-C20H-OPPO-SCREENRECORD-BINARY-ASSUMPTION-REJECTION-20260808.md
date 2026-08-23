# C20H OPPO screenrecord binary assumption rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The first normal-motion evidence attempt assumed the generic Android
`screenrecord` binary was available. OPPO CPH2375 returned exit code `127` and
reported `/system/bin/sh: screenrecord: inaccessible or not found`. No remote or
local video was produced. The navigation taps completed and left the app at
Book / Doctor; that state was freshly inventoried and is not represented as a
successful motion recording.

## Prevention

Device recording capability must be probed before launch on this exact phone.
A retry may use a proven host-side connected-device recorder, with a new unique
filename, checksum, final semantic-state verification, and no mutation of the
phone's animation settings.
