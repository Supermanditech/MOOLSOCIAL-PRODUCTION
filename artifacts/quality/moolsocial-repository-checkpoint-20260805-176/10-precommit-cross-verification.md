# Pre-commit Git cross-verification

The first complete `git diff --cached --check` failed closed only on preserved
evidence whitespace, Android/window/log output, intentional Markdown hard line
breaks and one temporary Dart capture file with an extra EOF line. Evidence was
not rewritten. The Dart file was formatted and restaged.

Subsequent verification established:

- required branch and pre-seal HEAD remained exact;
- remote remediation head remained the observed ancestor `646cf6f...`;
- zero unstaged tracked changes;
- zero remaining untracked files in durable roots `apps`, `backend`, `config`,
  `docs`, `output` and `scripts`;
- source/backend/config/script staged diff hygiene passed;
- staged founder and machine-state JSON parsed and matched FIX7 approval;
- strong credential-signature scan passed on all staged text;
- the Dev env file contained only allowlisted non-secret keys;
- exactly two APK paths used Git LFS, both pointing to the same expected
  `F0C106...5DC9` object and 134,214,109-byte size;
- `git lfs fsck` passed;
- zero ordinary staged Git blobs exceeded 95 MiB; largest was under 10 MiB;
- the FIX7 Chrome profile and raw performance atrace were explicitly excluded;
- the 2,466-entry source/APK recovery verifier passed.

Preserved evidence whitespace is an evidence-content property, not a source or
Git object-integrity failure.
