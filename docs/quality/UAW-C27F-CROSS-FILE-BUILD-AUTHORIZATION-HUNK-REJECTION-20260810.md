# C27F cross-file build-authorization hunk rejection

The first one-build authorization patch coupled ticket and scope files with a
generic `buildAuthorized` context. `apply_patch` could not verify the complete
multi-file patch and rejected it before mutation. Readback proved both owners
remained false and prebuild state remained active.

Build authority must be opened through separate exact ticket and scope owner
patches, followed by manifest-hash reconciliation before machine state opens.
