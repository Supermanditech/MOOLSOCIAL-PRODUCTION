# REG3176 - FIX8 correction patch missing registry file boundary

## Classification

Registered atomic patch rejection with zero correction, build or install write.

## Evidence

The first REG3175 correction patch omitted an `Update File` boundary before its
registry JSON hunk. `apply_patch` therefore tried to locate the registry entry
inside the manifest-generator script and rejected the complete patch.

## Prevention

Apply the evidence correction, generator change, memory append and registry
append as separate one-file patches. Never combine a source-script hunk and a
registry hunk without an explicit file boundary.
