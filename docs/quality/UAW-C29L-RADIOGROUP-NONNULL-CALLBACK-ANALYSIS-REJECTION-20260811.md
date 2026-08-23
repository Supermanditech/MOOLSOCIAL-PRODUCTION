# C29L RadioGroup non-null callback analysis rejection

After migrating to `RadioGroup<bool>`, the second focused analysis found one type error because the current SDK requires a non-null `ValueChanged<bool?>` callback. Passing `null` to disable the group during upload is not supported.

The correction keeps the callback non-null, guards state mutation while uploading and blocks pointer interaction around the group. The permanent prevention is to verify the exact current constructor contract when migrating away from deprecated widget members. No build, device, provider or protected runtime changed.
