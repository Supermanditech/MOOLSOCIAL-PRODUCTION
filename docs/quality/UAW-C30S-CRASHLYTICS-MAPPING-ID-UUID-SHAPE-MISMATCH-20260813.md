# C30S Crashlytics mapping ID UUID-shape mismatch

Date: 2026-08-13

After switching to the correct `string/com.google.firebase.crashlytics.mapping_file_id`, structural bundletool inspection proved the value is present as a quoted nonempty default string with exactly 32 hexadecimal characters. It is not a canonical hyphenated UUID.

The verifier had guessed the UUID shape and therefore rejected the valid generated resource. The corrected assertion requires the exact resource name, a quoted nonempty `[STR]` value and one 32-hex identifier without printing the identifier. The sealed AAB remains unchanged; no second build, upload or install occurred.

Regression: `REG-20260813-1636-C30S-CRASHLYTICS-MAPPING-ID-UUID-SHAPE-MISMATCH`.
