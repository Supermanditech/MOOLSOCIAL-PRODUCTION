# UAW C33G FIX2 interpolating provider source needle

Pre-execution review found a double-quoted PowerShell source needle containing Dart `${provider.name}`. The C33G FIX2 gate had not been executed, so no false pass or failure occurred.

The needle is represented as a PowerShell single-quoted literal with doubled embedded apostrophes. Later gates must review every cross-language dollar expression before first execution.
