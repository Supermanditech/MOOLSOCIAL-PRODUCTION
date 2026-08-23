# C10E manifest compound patch empty hunk boundary

- Registry: `REG-20260807-229-C10E-MANIFEST-COMPOUND-PATCH-EMPTY-HUNK-BOUNDARY`
- State: resolved; permanent gate active.

The first source-manifest patch combined a new file with two evidence updates
and included an empty update hunk before the second file. `apply_patch`
rejected the entire patch atomically, so no manifest, evidence, APK state,
build or device mutation occurred.

Candidate manifest creation and evidence enrichment now use separate small
patches, each with complete literal context and immediate readback.
