# C33I monolithic inline static-audit shell rejection

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

The first post-correction static audit aggregated source slicing, fourteen assertions and two hashes into one long inline shell command. The shell host rejected the command with `Access is denied` before any assertion result was produced. No file was changed.

## Root cause

Too many independently bounded checks were composed into one inline shell invocation, increasing host-policy and diagnostic ambiguity.

## Permanent prevention

Run source/hash verification and structural assertions as small independent read-only commands. Treat a host-level rejection as zero audit evidence and never infer which assertion would have passed.
