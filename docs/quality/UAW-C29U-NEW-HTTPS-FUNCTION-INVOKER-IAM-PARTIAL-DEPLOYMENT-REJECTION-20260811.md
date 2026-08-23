# C29U new HTTPS function invoker IAM partial-deployment rejection

- Date: 2026-08-11
- Target: Dev-only `moolsocial-dev-503018`
- Deployment result: partial and not accepted

Firebase uploaded the sealed source, successfully updated `youtubeProvider` and `youtubeOAuthCallback`, and created `moolSocialContent`. The command then returned nonzero because it could not set the new Cloud Run service's invoker IAM policy. The new endpoint is therefore fail-closed until independently proven otherwise.

No broad retry is permitted. The recovery is bounded: describe all three functions, compare only their Cloud Run invoker bindings, add only the exact missing `roles/run.invoker` member if organization policy permits, and verify the new endpoint reaches application-level App Check/Auth rejection rather than platform IAM denial. Both deny-all direct-client rule deployments remain in force.
