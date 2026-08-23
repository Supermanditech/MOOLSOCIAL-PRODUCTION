# UAW AAB pre-upload artifact rebinding gap

## Finding

The build wrapper calculates the sealed AAB hash, size, signer and manifest
proofs. The C30V post-build gate then checks proof booleans and resolves the AAB
and provenance paths, while pre-upload checks only state and action counts.
Neither phase independently rebinds the current artifact bytes to the retained
provenance immediately before upload.

## Required hard gate

The successor gate must recompute the AAB SHA-256 and byte length, parse the
non-secret provenance, require exact candidate/package/version/signer bindings
and reject any difference before upload authority is consumed. Artifact
existence or prior boolean proof alone is insufficient.

## Resolution

The C30X `postbuild` and `preupload` phases now independently recompute the
AAB hash and byte length, parse credential-safe provenance, compare dynamic
candidate/package/version/signer/plugin bindings, re-read the current signer
certificate and Bundletool manifest, verify the bundle payload and recheck the
qualified source manifest. Preupload additionally requires one still-unused
Internal Testing authority.
