# YouTube API Services C30O same-thread draft and reviewer package — 2026-08-12

## Hold state

`NOT READY TO SEND — AWAITING PLAY-INSTALLED OPPO ACCEPTANCE AND FOUNDER APPROVAL`

No Gmail draft, reply or send action has been performed. This local document must not be copied into Gmail until every bracketed artifact field is sealed and the founder approves the exact final text.

## Verified thread request

- Authenticated mailbox: `hello@moolsocial.com`.
- Thread subject: `Re: YouTube API Services: Thank you for your submission`.
- Latest request date: 2026-08-06 (sender timestamp: 18:34:25 -0700).
- Exact requested outcome: a valid Android mobile application link for the application using YouTube API Services, supplied within seven business days.
- Internal hard deadline: 2026-08-14.
- The prior 2026-08-05 response already and correctly stated that the website does not use YouTube API Services, Android does, and iOS does not currently enable or distribute the integration.

## Same-thread response draft

Dear YouTube API Services Compliance Team,

Thank you for your 6 August follow-up. Below is the valid Android application link for the MoolSocial application that uses YouTube API Services.

Android application link (Google Play Internal Testing):
[INSERT EXACT PLAY INTERNAL TESTER/APP LINK]

Application identity:
- Product: MoolSocial
- Google Cloud project: `moolsocial-dev-503018`
- Android package: `com.moolsocial.app`
- Review candidate: `[INSERT SEALED VERSION NAME AND VERSION CODE]`
- Play-distributed artifact SHA-256/provenance: `[INSERT SEALED RELATIONSHIP EVIDENCE]`

This is a private Google Play Internal Testing release. It is not a Production, open-testing or public-listing rollout. If your review Google account is not already eligible for this private tester link, please provide the Google account address to authorize; we will add it to this same bounded Internal Testing track.

The Android use case remains limited to:
- discovery of eligible public YouTube videos and Shorts using `videos.list`, `channels.list` and bounded `search.list` requests;
- display of source-attributed YouTube metadata;
- playback through the official embedded YouTube player with standard controls, branding, advertising and links intact; and
- a separately user-initiated channel connection using the minimum `youtube.readonly` OAuth scope, with visible consent, status, disconnect, privacy, deletion and Google revocation controls.

The Android review build does not provide YouTube upload, viewer mutation, playlist/channel/asset mutation, Analytics, Reporting, Live, partner, membership, Super Chat or Content Owner claim capabilities. MoolSocial Feed and Create are MoolSocial-owned experiences and are visually and functionally distinct from the YouTube discovery and playback surfaces.

Reviewer steps:
1. Open the Internal Testing link on an eligible Android Google account and opt in.
2. Install MoolSocial from Google Play; do not sideload an APK.
3. Open Social > Videos to view the source-attributed YouTube catalogue.
4. Search for an eligible public video, open a standard video, and use the official YouTube player controls and YouTube link.
5. Open Shorts and select an eligible Short; playback remains in the official embedded player.
6. Open the YouTube channel status control. Review the read-only explanation, connect through Google consent, return to the exact connected-channel status, then use Disconnect. Google permissions and MoolSocial privacy/deletion controls are linked on the same screen.
7. Open MoolSocial Feed and Create to confirm those MoolSocial-owned experiences are distinct and do not expose a YouTube upload action.

Policy and user-control links:
- YouTube API use and reviewer disclosure: https://moolsocial.com/youtube-api
- Privacy and YouTube API Data use: https://moolsocial.com/privacy
- Disconnect and revoke access: https://moolsocial.com/disconnect
- Account deletion: https://moolsocial.com/delete-account
- Google third-party permissions: https://myaccount.google.com/permissions

Updated review evidence:
- Screencast: `[INSERT FOUNDER-APPROVED LINK OR ATTACHMENT NAME]`
- Android/Play provenance and OPPO journey package: `[INSERT SEALED EVIDENCE REFERENCE]`

The website remains public but does not use YouTube API Services. The YouTube integration remains disabled and undistributed on iOS. We have not expanded the use case described in our 5 August response.

Regards,

Dharmendra Choudhary
Founder, MoolSocial
SUPERMANDI TECH PRIVATE LIMITED
hello@moolsocial.com
https://moolsocial.com/

## Reviewer evidence checklist

- [ ] Exact Internal Testing link opens the `com.moolsocial.app` opt-in/app page.
- [ ] Founder tester is eligible and can install from Google Play.
- [ ] Play App Signing certificate SHA-256 is registered to the exact Dev Firebase Android app.
- [ ] Installed version/package and Play installer provenance match the sealed AAB release.
- [ ] App Check accepts a signed-in live Feed read before any Create write.
- [ ] Exactly six Dev Create writes are accepted and read back.
- [ ] C28D passes two matching no-tap frames.
- [ ] YouTube Home, search, video, Shorts, attribution and official player pass.
- [ ] Unconnected, consent, connected, disconnect, error and retry states pass.
- [ ] Privacy, deletion, disconnect and Google revocation controls are visible and open the canonical URLs.
- [ ] MoolSocial Feed/Create remain distinct and expose no YouTube upload action.
- [ ] Updated screencast contains no credential, token, private verdict, nonce or unrelated personal data.
- [ ] Every bracketed draft field is replaced with sealed evidence.
- [ ] Founder approves the final text and attachments before any Gmail or quota action.
