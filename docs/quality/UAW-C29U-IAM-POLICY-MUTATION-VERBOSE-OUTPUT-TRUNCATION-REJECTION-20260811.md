# C29U IAM policy mutation verbose-output truncation rejection

- Date: 2026-08-11
- Scope: `moolsocial-dev-503018` Dev-only C29U runtime IAM qualification
- Result: rejected as evidence; cloud state must be established by a bounded read

The App Check verifier project-role mutation printed the project-wide policy and exceeded the available execution-output context. A successful process exit cannot be inferred from truncated output, and the mutation transcript is not used as deployment evidence.

The permanent correction is to suppress mutation output where the CLI supports it and then query the exact service-account member with a role-only table. The role is accepted only when that independent read returns it.
