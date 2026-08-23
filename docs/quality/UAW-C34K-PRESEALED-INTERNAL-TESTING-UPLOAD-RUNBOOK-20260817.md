# C34K r60.75 presealed Internal Testing upload runbook

Upload is held until C34K has one postbuild-qualified AAB whose SHA-256, byte
count, signer, package/version, Google app ID, Crashlytics ID, split/arm64
payload and source provenance match both lifecycle states. The preupload gate
must report `1/0/0/0` and exactly one Internal Testing authority.

Only the exact C34K artifact may be uploaded and activated on Google Play
Internal Testing. After sanitized retained Play evidence, the upload count must
be `1`, all other tracks must remain untouched, and only then may one Play
in-place OPPO update authority become available.
