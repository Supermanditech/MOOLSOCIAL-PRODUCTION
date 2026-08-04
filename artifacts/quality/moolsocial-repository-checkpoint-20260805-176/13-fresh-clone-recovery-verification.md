# Fresh-clone recovery verification

The first independent GitHub clone of seal commit
`e866b7149a32e9f7a3cd1144aaa9e5d846561498` failed closed at the first missing
source-manifest path. The original workspace still contained the file.

Root cause:

- the approved source manifest intentionally hashes 2,466 source/test files;
- 384 entries are generated golden-comparison images under
  `apps/mobile/test/failures`;
- `.gitignore` excludes `**/test/failures/`; and
- the initial repository seal therefore did not carry those 384 files even
  though the local verifier could see them.

The complete missing-path audit found exactly 384 omissions, all in that one
directory, totaling 31,134,237 bytes. There were no missing non-failure paths.
Every original file matched its existing manifest SHA-256.

Recovery repair commit
`4c1f41a71f96b4ecce40e5352dd2e70b6900dca2`, tree
`39e4f28471f5cc3827a0e7320b1617c844586f20`, adds exactly those 384 files with
zero deletions. It does not change runtime source, the approved manifest, the
machine state or the APK.

Both authorized branches were fast-forwarded to the repair commit. The clean
clone at `C:\GUARANTEED OUTCOME\MOOLSOCIAL-GIT-RECOVERY-VERIFY-20260805` then
passed the 2,466-entry resume verifier, APK checksum, `git lfs fsck`,
`git fsck --full`, both remote refs, exact commit/tree, 384 tracked manifest
artifacts and zero checkout drift.

One intermediate harness check fetched only the remediation branch and then
inspected the cached checkpoint remote-tracking ref. That stale-ref result was
not accepted. After a full `git fetch origin`, both remote-tracking refs
resolved to the repair commit and the complete recovery gate passed.
