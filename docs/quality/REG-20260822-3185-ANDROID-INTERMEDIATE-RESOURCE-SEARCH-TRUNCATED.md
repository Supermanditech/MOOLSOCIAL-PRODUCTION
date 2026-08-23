# REG3185 - Android intermediate resource search truncated

## Classification

Registered read-only diagnostic-output ambiguity with zero source repair,
build, APK, install or device action.

## Evidence

A recursive filename projection across Android build intermediates returned
1,225 lines and was truncated. Although its visible prefix showed the base
launch background in packaged release resources, the output cannot prove the
complete merge/link state and is not accepted as authoritative evidence.

## Prevention

Query only exact release intermediate directories and exact
`launch_background` filenames. Project existence, size, timestamp and checksum
as bounded objects; inspect the specific merge-blame records separately. Never
infer a complete resource state from truncated recursive output.
