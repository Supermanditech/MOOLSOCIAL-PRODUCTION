# Git inclusion and local evidence policy

## Git recovery layer

The checkpoint commit includes every tracked production change plus all
currently untracked production app source, tests, goldens/captures, backend
commerce contracts/tests, non-secret Dev feature configuration, policies,
decision/delivery/quality records, scripts and review PDFs. It also includes:

- the complete R58.8.8 FIX7 compact evidence set;
- the exact wrapper and OPPO-pulled r58.23 APKs through Git LFS;
- the FIX7 founder-decision folder;
- this repository resume checkpoint and the complete local-evidence manifest.

The raw 67.72 MB performance trace is not required for source recovery because
its parser, summary and classification are included. The FIX7 captured Chrome
profile is not published because browser profile data is session material.

## Local-only historical evidence layer

At capture there were 45,755 untracked `artifacts/` and top-level `tmp/` files,
77,083,818,304 bytes. Their exact paths, sizes and SHA-256 values are recorded
in `05-untracked-artifacts-tmp-sha256.txt`; manifest SHA-256 is
`49CED5F8D2B52452D5946DB0FD999B186CA84AF7B4694FA8DAA140283A9A93F7`.
This includes 441 historical APK files and 19,654 browser-profile files. They
remain preserved locally but are not all Git transport inputs: the APK set is
65+ GB and browser profiles may contain session data. This exclusion does not
remove or overwrite any evidence.

## Recovery guarantee and limit

Git plus LFS is sufficient to recover the exact production source, backend,
tests, decision memory, current approved APK and validation method at the cut.
The local manifest proves the identity of historical evidence that is not
needed to resume production implementation. A separate controlled private
evidence archive would require an approved storage owner, lifecycle/cost policy
and credential boundary; it must not be improvised in Dev or Production.

