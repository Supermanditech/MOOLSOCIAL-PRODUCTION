# C30J findings — truthful YouTube account-state journey

## Founder finding

The YouTube Home header currently shows an `M` avatar with the native label `MoolSocial account` and opens the MoolSocial account page. That visual treatment resembles a signed-in YouTube account even though the public surface never reads a YouTube OAuth/channel state.

## Truthful user-state model

1. A user signed in to MoolSocial may browse, search and watch public YouTube-hosted videos and Shorts without connecting a Google/YouTube account.
2. A creator deliberately opens `YouTube channel status`, sees a disconnected explanation, and chooses Google OAuth only when they want a channel-authorized action.
3. Google consent returns through the existing allowlisted callback route. A return flag alone never establishes authority.
4. The existing real gateway refreshes `connectionStatus`; only `YouTubeConnected` may display the exact server-verified channel title/id/scopes.
5. `YouTubeDisconnected`, reconnect-required, capability unavailable, MoolSocial authentication-required, provider/network failure, disconnect and retry states fail closed and remain explicit.

## Reuse and duplicate audit

- Reuse C29L's real system-browser OAuth, PKCE/state callback, server token vault, exact `channels.list(mine=true)` identity, connection-status model, disconnect/revoke path and tested creator screen.
- Reuse the exact `/app/creator/youtube-connect` owner; do not create a parallel account route or local connection boolean.
- The public consumer currently has no injected `YouTubeConnectionStatus` owner. Therefore its header must remain neutral and route to the authoritative owner rather than synthesizing a connected badge.
- No new backend, scope, provider capability, screen or route is necessary.

## API/policy assessment

YouTube's current official guidance distinguishes public search/watch data, which does not require user authorization, from uploads/private user actions, which require OAuth and specific user-granted scopes. Developer policies require transparency, active user consent, user control, prompt revocation and prohibit collecting or storing YouTube login credentials. C30J therefore separates public viewing from creator connection and exposes disconnect/re-auth recovery through the existing real owner.

## Execution order and locks

- C30J is next after C30I and is source/test only.
- r60.38 remains installed, rejected and preserved.
- Real connected-channel device proof remains gated on the existing Dev `privateUpload` provider activation and supervised Google consent; no status may be fabricated while that gate is closed.
- No APK build/install, backend/provider/Firebase/Production deployment, credential access, commit or push under this ticket.
