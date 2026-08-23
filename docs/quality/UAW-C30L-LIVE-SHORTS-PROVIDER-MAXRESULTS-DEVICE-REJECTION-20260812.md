# C30L live Shorts provider maxResults device rejection

## Device result

- Installed candidate: `1.0.0-r60.39+2026081239`, checksum matched.
- YouTube Home: real current video catalogue loaded.
- Shorts first entry: truthful unavailable state.
- One bounded Retry: loading settled on the same unavailable state.
- Provider log: `bad_request` at both request times.

## Exact cause

Live `youtubeprovider-00035-jis` predates C30A's implemented fix. It wires
`maxResults=50` into the public Shorts catalogue contract, whose maximum is 25.
Local source already uses the named page-size contract set to 25; that provider
change remains undeployed.

## Required recovery

A separate founder-authorized Dev-only `youtubeProvider` ticket must re-audit
the sealed local provider source, package containment, IAM/secrets without
reading values, run backend and exact-target dry-run gates, deploy only
`functions:provider:youtubeProvider`, and prove playable Shorts on the already
installed r60.39 client. No APK rebuild or reinstall is required or permitted.
