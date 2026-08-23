# C30T Hosting channel optional file-count absence

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1889-C30T-HOSTING-CHANNEL-OPTIONAL-FILECOUNT-ABSENT`

## Observation

The final read-only Hosting channel reconciliation returned the new finalized release and version identities but did not expose the optional `version.fileCount` value, leaving that non-authoritative evidence field blank.

## Authoritative evidence retained

- The live release advanced to `projects/moolsocial-dev-503018/sites/moolsocial-dev-503018/channels/live/releases/1786609421461000`.
- The finalized version is `projects/moolsocial-dev-503018/sites/moolsocial-dev-503018/versions/86a17ea7c0f4a41f`.
- The exact 35-file Hosting source section is checksum-sealed.
- Seven local public-site tests passed immediately before deployment.
- Both the Firebase domain and `moolsocial.com` returned HTTP 200 for the reviewed routes.
- The deployment wrapper separately verified page markers, security headers and the exact Play App Links signing identity.

## Prevention

File count is recorded only when present. Release identity, version finalization, sealed local source and live content/security readbacks remain the required qualification evidence.
