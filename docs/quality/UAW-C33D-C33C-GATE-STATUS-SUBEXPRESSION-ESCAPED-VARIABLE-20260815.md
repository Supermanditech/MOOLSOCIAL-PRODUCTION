# C33D C33C gate status subexpression escaped variable

Inspection before execution found the C33C gate status line stored
`` `$c33dBound`` inside its PowerShell subexpression. That escape belonged to
patch composition, not the target script.

REG-2317 blocks the first gate attempt until the one token is corrected and
the exact target line is re-read.
