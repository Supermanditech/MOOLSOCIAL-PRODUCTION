# C24I repeated reserved HOME-variable rejection

Date: 2026-08-09

The corrected omission audit repeated REG747 by assigning the Home source to `$home`. PowerShell variable names are case-insensitive, so this attempted to overwrite the read-only HOME environment variable. The assignment failed non-terminatingly and the subsequent token checks operated on the environment path, making that audit result invalid.

No runtime, APK or OPPO application state was changed. The retry uses `$homeSourceText`, enables terminating errors and admits no output from a command that emits any error record.
