# C09 package-dump scalar output expansion

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

The postinstall verifier converted `dumpsys package` to one multiline scalar
and then piped that scalar to `Select-String`. Because the scalar contained a
match, PowerShell emitted the complete package dump instead of the intended
four identity lines. Installation and validation succeeded and no additional
state changed, but the diagnostic output was unnecessarily large.

Future bounded package output splits the scalar into lines first, or extracts
the required values with anchored regular expressions and prints only named
scalars. A matching multiline scalar is never piped directly to
`Select-String` for evidence output.
