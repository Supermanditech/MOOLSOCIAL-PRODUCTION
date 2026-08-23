# C30K backend-suite direct-output truncation rejection

## Finding

The complete backend suite reported 498 passed and zero failed, but its direct tool response truncated intermediate output. It is retained as a non-qualifying diagnostic run.

## Disposition

Rejected and registered as `REG-20260812-1402-C30K-BACKEND-SUITE-DIRECT-OUTPUT-TRUNCATION-REJECTION`.

## Permanent prevention

Resolve a repository-local evidence path first, redirect the complete suite output there, and return only the bounded final summary, exit code and log SHA-256. A directly truncated suite is never qualifying evidence.
