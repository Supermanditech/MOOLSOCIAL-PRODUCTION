# Temporary prototype PowerShell variable-colon parser recurrence

Date: 2026-08-09

The direct-card mapping validator constructed a PowerShell double-quoted regex
containing `$family:`. PowerShell treated the colon as part of a scoped-variable
reference and rejected the checker before reading the HTML.

Root cause: a dynamic regex was used for a fixed set of mapping literals,
repeating the avoidable interpolation class already recorded by REG856 and
REG862.

Correction: fixed JavaScript owner mappings are checked through a raw PowerShell
literal array and `Contains`. When interpolation is required, a variable next
to punctuation is explicitly delimited.

No product behavior, Flutter source, accepted screenbook, APK or OPPO state was
changed by this false failure.
