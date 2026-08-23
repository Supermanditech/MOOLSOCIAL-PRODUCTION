# C29U gcloud Storage IAM filter and native-failure propagation rejection

- Date: 2026-08-11
- Scope: Dev default-bucket IAM verification
- Mutation status: the preceding bucket binding exited successfully; this failed read made no cloud mutation

`gcloud storage buckets get-iam-policy` on this installed CLI rejected the project-IAM-style `--filter` flag. Because PowerShell does not convert a native nonzero exit into a terminating error through `ErrorActionPreference`, the composed command continued to a later metadata read.

The permanent correction is to request policy JSON, check `LASTEXITCODE` immediately, select the exact service-account member locally, and print only matching roles. Native cloud reads are kept isolated or explicitly guarded.
