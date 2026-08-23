# C29N mobile working-directory root-path rejection

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1225-C29N-MOBILE-WORKING-DIRECTORY-ROOT-PATH-REJECTION`

## Preserved observation

The first no-match-safe C29N source-absence check was launched with
`apps/mobile` as its working directory in preparation for Flutter analysis, but
the ripgrep inputs still began with `apps/mobile/`. Ripgrep correctly rejected
the doubled nonexistent paths with exit code 2. The guarded check stopped the
shell before Flutter analysis began.

## Root cause and prevention

The command mixed repository-root and package-local coordinate frames. C29N now
runs bounded source searches from the repository root and invokes Flutter in a
separate shell rooted at `apps/mobile`. The regression-memory checker permanently
retains this requirement.
