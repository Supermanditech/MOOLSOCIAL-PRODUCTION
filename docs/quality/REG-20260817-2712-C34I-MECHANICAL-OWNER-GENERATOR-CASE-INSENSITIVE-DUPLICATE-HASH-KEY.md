# REG2712 — C34I mechanical owner generator duplicate hash key

## Observation

PowerShell rejected the C34I mechanical release-owner generator during parsing
because the ordered hash contained both `C34H` and `c34h`. PowerShell hash keys
are case-insensitive, so the keys were duplicates. No recovery, cycle or
launcher file was created and no external action occurred.

## Root cause

Case-sensitive string substitutions were represented in a case-insensitive
PowerShell hashtable.

## Prevention

Keep the uppercase substitution in the ordered map and apply the lowercase
substitution as a separate explicit `String.Replace` after the map loop. Parse
the generator before its single retained execution. A parser rejection is zero
owner-generation evidence.
