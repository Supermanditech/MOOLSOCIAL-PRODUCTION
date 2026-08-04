# Post-commit cross-verification

Production content commit:
`da656725c33bff7be42c190761892dc1d6a816bb`

Parent:
`f1ac83dea2047f40b39d772696bd0d1224edce8e`

Tree:
`512abcadf3d214fea65857aaeea2326edf0d4510`

Verified after commit:

- 2,085 committed paths and zero deletions;
- exact parent and subject;
- committed founder-approved machine state and APK checksum;
- exactly two LFS pointers to one expected APK object;
- `git lfs fsck`, 2,466-entry resume verifier and `git fsck` passed;
- no excluded FIX7 Chrome-profile or raw-atrace path entered the commit;
- tracked worktree remained unchanged.

The first tree-object command used unquoted PowerShell input `HEAD^{tree}` and
PowerShell rewrote it, causing `git rev-parse` to reject the malformed argument.
That harness output was not accepted. The literal quoted revision
`'HEAD^{tree}'` resolved tree `512abc...4510`; `git cat-file -t` classified it
as a tree and `git show --format=%T` returned the same identity.
