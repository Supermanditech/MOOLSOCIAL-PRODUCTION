# C30T provider validation existing-runtime profile mismatch

Date: 2026-08-13

The first provider-only control validation failed closed because the ignored Firebase runtime file was preserved from an earlier public-data-only profile. Its capability flags enable public data, keep owner connection disabled, and keep every mutation/upload/Live/Analytics capability disabled. It contains no forbidden secret variable names.

The file is user-owned and will not be deleted or overwritten permanently. Permanent prevention: preserve its exact bytes in memory, temporarily materialize the accepted public-data-plus-`youtube.readonly` profile only during the authorized Firebase deployment, and restore the original bytes and SHA-256 in a `finally` block.
