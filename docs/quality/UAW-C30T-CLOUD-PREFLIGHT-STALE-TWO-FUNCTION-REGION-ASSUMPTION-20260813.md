# C30T Cloud preflight stale two-function region assumption

Date: 2026-08-13

After the exact Functions ignore inventory was reconciled, the older YouTube preflight rejected the current shared Functions codebase with `Both provider Functions must remain in asia-south1.` The codebase now also owns separately gated Social and Chat exports; today’s authorized deployment target remains exactly `functions:provider:youtubeProvider`.

Permanent prevention: inventory the current exports structurally and validate `youtubeProvider` and `youtubeOAuthCallback` independently by name and region. Do not broaden the deploy target.
