# C30T shared-backend storage false rejection

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1877-C30T-CLOUD-PREFLIGHT-SHARED-BACKEND-STORAGE-FALSE-REJECTION`

## Observation

After the exact YouTube export-option reconciliation passed its parser and control suites, the local private-Dev preflight rejected the shared Functions source because separately gated Social media code references Cloud Storage.

## Root cause and correction

The historic YouTube-only preflight scanned all non-test backend TypeScript after the codebase gained independent Social and Chat exports. The no-media-proxy policy is now evaluated against the exact `youtubeProvider` and `youtubeOAuthCallback` export blocks plus the non-test YouTube runtime module tree. Social and Chat remain outside this assertion and outside the authorized deploy target.

## External effect

None. The rejection occurred locally before any Firebase, Google Cloud, Hosting, AAB, Play, device, IAM, Gmail or quota mutation.
