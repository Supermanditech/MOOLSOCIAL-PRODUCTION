# REG-20260820-3025 Firebase deploy local credentials expired

## Incident

The founder started the explicitly authorized Dev-only Firebase deployment for
`moolSocialPublicAuth`. The predeploy TypeScript build completed, but Firebase
CLI repeatedly reported that the local credentials were no longer valid and
terminated before runtime-parameter entry or function deployment.

## Impact

- Backend predeploy build passed.
- No public client ID or redirect was entered.
- No function, hosting, provider, build, Play, OPPO, email, SMS or private-login
  state changed.
- The failed deploy is not accepted as deployment evidence.

## Root cause

The local Firebase CLI authentication session had expired even though the
separate Cloud Shell Google session remained valid.

## Prevention

Do not retry deployment before interactive `firebase login --reauth` succeeds
in the same visible PowerShell. Never use `login:ci` or print a token. After
reauthentication, recheck Dev function absence, replay the authorized gate and
run the one exact function deployment without interruption.
