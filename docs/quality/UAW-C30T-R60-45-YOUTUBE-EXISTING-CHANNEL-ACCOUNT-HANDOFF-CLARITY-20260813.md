# UAW C30T r60.45 YouTube existing-channel-account handoff clarity — 13 August 2026

The Play-installed flow does not clearly distinguish two separate boundaries: authenticating the MoolSocial user and then connecting the existing Google account that owns the user's YouTube channel. The successor must label the first boundary as MoolSocial sign-in, retain the YouTube channel return destination, and then explicitly ask for the existing Google account containing the channel while stating `youtube.readonly` and no-upload behavior before consent. No account identity or credential may be captured. No second AAB/upload/install is authorized.

## Preselection assessment

- Customer outcome: a signed-out creator understands that the first boundary signs in to MoolSocial, returns to the existing YouTube channel connection owner, and then chooses the existing Google account that owns the channel under explicit `youtube.readonly` and no-upload consent.
- Classification: `mvp_required`. The Play-installed creator path currently loops through generic authentication recovery and does not establish the distinct MoolSocial-authentication and YouTube-channel-connection purposes.
- Reuse: `JourneySession` already owns exact return and cancel routes, Screen 03 already owns Google identity sign-in and recovery, the Social consumer already owns the channel-status entry, and `SocialYouTubeCreatorUploadScreen` already owns read-only connection, consent and disconnect controls.
- Minimum correction: add an ephemeral YouTube-channel sign-in purpose to the existing session; start it from the signed-out Social entry; render one Google-only MoolSocial sign-in explanation for that purpose; keep exact retry/cancel-return behavior; and make the existing connection card name the existing Google account, `youtube.readonly`, and no-upload behavior.
- New screens, routes and backend owners: none.
- Exclusions: no direct YouTube connection claim during MoolSocial sign-in; no Email/Mobile OTP claim in this special handoff; no upload/edit/delete/viewer-mutation scope; no credential or account-identity capture; no provider, Hosting, Play, build, upload, install or device mutation.
- Dependencies: the source-qualified authentication and system-Back corrections remain preserved; the existing read-only provider and OAuth callback remain unchanged; live proof requires a future separately authorized candidate.
- Test plan: session purpose/return/cancel state, Screen 03 purpose copy/provider filtering/retry/cancel, signed-out Social channel-status entry, read-only connection copy and existing connection/disconnect regressions, followed by the current authoritative non-build Flutter/backend/Hosting/analyzer gates.

The founder authorized continued source implementation while explicitly withholding every successor AAB, upload and install authority. This ticket is selected only for source and non-build qualification.

## Source implementation and non-build qualification

The signed-out Social YouTube channel-status entry now begins one explicit
`youtubeChannelConnection` authentication purpose instead of opening the
connection owner as an unauthenticated dead end. It retains
`/app/creator/youtube-connect` as the success destination and the current Social
Videos surface as the cancel destination.

For that exact purpose, Screen 03 says `Sign in to MoolSocial`, explains that
this boundary does not connect YouTube, and exposes only the production Google
identity method. Email OTP, Mobile OTP and the separate YouTube-labelled
identity button are not offered in this special handoff. A failed Google return
offers an exact retry or `Cancel and return`; Android Back uses the same retained
cancel route. The persisted local YouTube return reconstructs the purpose and
cancel route after process death without storing a credential, account identity
or new session field.

After successful MoolSocial authentication, the existing creator connection
owner asks for the existing Google account that owns the channel and states that
the connection uses only `youtube.readonly` access and cannot upload, edit or
delete YouTube content. Its existing consent, failure, retry, connected,
disconnect, privacy, revocation and deletion controls remain the owners.

Qualification completed without an APK/AAB build, upload, install, OPPO action,
provider deployment, Hosting deployment or external write:

- Expanded handoff/session/connection partition: 50 passed.
- Authoritative C30T 59-file Social/YouTube/Chat/navigation manifest: 370 passed
  with 3 declared skips.
- Dart format audit: 474 owned `lib` and `test` files checked, 0 changed.
- `flutter analyze`: no issues found.
- Backend verification: 505 passed, 0 failed.
- Firebase Hosting/App Links static verification: 7 passed, 0 failed.
- YouTube deployment controls passed with the exact
  `No cloud command was performed.` marker.
- Android release dependency graph: `BUILD SUCCESSFUL`; no APK/AAB task ran.

The ticket state is
`source_implemented_and_non_build_qualified_live_Play_acceptance_pending`.
The currently installed r60.45 does not contain this repair. A future separately
authorized Play candidate must still prove Google sign-in success/cancel/retry,
process return, existing-channel consent, connected status, disconnect and
relaunch on OPPO. This is not a live-success or production-grade claim and does
not authorize a successor AAB.
