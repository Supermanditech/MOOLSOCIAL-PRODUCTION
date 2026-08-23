# YouTube API Services C30T same-thread draft and reviewer package — 2026-08-13

## Hold state

`NOT READY TO SEND — C30T AAB, PLAY-INSTALLED OPPO ACCEPTANCE, FINAL SCREENCAST AND FOUNDER APPROVAL ARE PENDING`

No Gmail draft, reply, send or quota action is authorized or performed. The private tester URL below is valid for an eligible tester account, but the target C30T artifact has not been built, uploaded or device-qualified.

## Verified request and target

- Authenticated mailbox: `hello@moolsocial.com`.
- Thread subject: `Re: YouTube API Services: Thank you for your submission`.
- Latest request date: 2026-08-06.
- Internal hard deadline: 2026-08-14.
- Google Play track: private Internal Testing only.
- Valid tester URL: <https://play.google.com/apps/internaltest/4700716609720808604>.
- Project/package: `moolsocial-dev-503018` / `com.moolsocial.app`.
- Target identity: `1.0.0-r60.45 (2026081345)`.
- Target artifact/provenance: `PENDING FINAL AUTHORIZED AAB AND PLAY-INSTALLED OPPO QUALIFICATION`.

## Same-thread response draft

Dear YouTube API Services Compliance Team,

Thank you for your 6 August follow-up. Below is the valid Android application link for the MoolSocial application that uses YouTube API Services.

Android application link (private Google Play Internal Testing):
https://play.google.com/apps/internaltest/4700716609720808604

Application identity:
- Product: MoolSocial
- Google Cloud project: `moolsocial-dev-503018`
- Android package: `com.moolsocial.app`
- Review candidate: `1.0.0-r60.45 (2026081345)`
- Play-distributed artifact identity/provenance: `PENDING SEALED FINAL EVIDENCE`

This is a private Google Play Internal Testing release. It is not a Production, open-testing or public-listing rollout. If your review Google account is not already eligible for this private tester link, please provide the Google account address to authorize on this same bounded Internal Testing track.

The Android use case remains limited to:
- discovery of eligible public YouTube videos and Shorts using `videos.list`, `channels.list` and bounded `search.list` requests;
- display of source-attributed YouTube metadata;
- playback through the official embedded YouTube player with standard controls, branding, advertising and links intact; and
- a separately user-initiated channel connection using only the minimum `youtube.readonly` OAuth scope, with visible consent, status, disconnect, privacy, deletion and Google revocation controls.

The Android review build does not provide YouTube upload, viewer mutation, playlist/channel/asset mutation, Analytics, Reporting, Live, partner, membership, Super Chat or Content Owner claim capabilities. MoolSocial Home, Feed, Create and Chats are MoolSocial-owned experiences and remain visually and functionally distinct from YouTube discovery and playback.

Reviewer steps:
1. Open the Internal Testing link on the eligible Android Google account and opt in.
2. Install MoolSocial from Google Play; do not sideload an APK.
3. Open Social > Home and inspect the source-attributed public YouTube catalogue.
4. Search for an eligible public video, open it, use the standard embedded player controls, and open the exact content on YouTube.
5. Open Shorts, select an eligible Short, and verify the official embedded player and exact YouTube link.
6. Open the YouTube channel-status control, review the read-only explanation, connect through Google consent, return to the connected-channel state, then disconnect. Review the linked Google permissions and MoolSocial privacy/deletion controls.
7. Open MoolSocial Feed, Create and Chats to confirm the independently valuable MoolSocial experiences and the absence of any YouTube upload action.

Policy and user-control links:
- YouTube API use and reviewer disclosure: https://moolsocial.com/youtube-api
- Privacy and YouTube API Data use: https://moolsocial.com/privacy
- Disconnect and revoke access: https://moolsocial.com/disconnect
- Account deletion: https://moolsocial.com/delete-account
- Google third-party permissions: https://myaccount.google.com/permissions

Updated review evidence:
- Final Play artifact and OPPO provenance: `PENDING SEALED FINAL EVIDENCE`
- Updated screencast: `PENDING FOUNDER-APPROVED LINK OR ATTACHMENT`

The website remains public but does not use YouTube API Services. The YouTube integration remains disabled and undistributed on iOS. We have not expanded the use case described in our 5 August response.

Regards,

Dharmendra Choudhary
Founder, MoolSocial
SUPERMANDI TECH PRIVATE LIMITED
hello@moolsocial.com
https://moolsocial.com/

## Final evidence gate before founder approval

- [x] Exact Internal Testing URL is recorded.
- [x] Project, package, target version and private distribution scope are exact.
- [x] Declared YouTube use case is unchanged and upload remains excluded.
- [ ] Founder tester installs the final C30T successor from Google Play without uninstall or data clear.
- [ ] Final installed version, signer, installer and artifact relationship are sealed.
- [ ] Play-recognized App Check route passes real signed-in Feed read.
- [ ] Exactly six Dev Create writes and Feed readback pass.
- [ ] C28D and the complete Home/search/video/Shorts/attribution/player journey pass.
- [ ] Unconnected, consent, connected, disconnect, error and retry states pass.
- [ ] Public Feed, formats, vote/quiz/media/carousel, refresh/relaunch/offline/retry, Chats and global navigation pass.
- [ ] Updated screencast contains no credential, token, private verdict, nonce or unrelated personal data.
- [ ] Every `PENDING` field is replaced by sealed evidence.
- [ ] Founder approves the exact final text and attachments before any Gmail or quota action.
