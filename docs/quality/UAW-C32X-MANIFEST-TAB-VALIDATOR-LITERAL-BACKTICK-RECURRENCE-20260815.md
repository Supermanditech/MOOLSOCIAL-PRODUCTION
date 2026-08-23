# C32X manifest tab validator literal-backtick recurrence

The first validation of the new C32R-C32X source/test manifest split every row
into two fields and split the header into two fields, proving that real tab
separators were present. A separate single-quoted regex nevertheless reported
all 61 rows as bad because PowerShell does not expand backtick-`t` inside a
single-quoted pattern.

The manifest was not qualified from that contradictory output. REG-2291 must
be registered before retry. The corrected validator must split each row on an
actual tab, validate the two resulting fields independently, recheck every
listed file hash, and reseal the manifest after the regression registry and
this evidence document are included as exact members.

## Result

REG-2291 was registered before retry. The corrected field-by-field validator
then reported 62 rows, zero format failures, zero stale hashes and zero
duplicate paths. This result precedes the final reseal that incorporates the
resolved registry status and completed evidence text.
