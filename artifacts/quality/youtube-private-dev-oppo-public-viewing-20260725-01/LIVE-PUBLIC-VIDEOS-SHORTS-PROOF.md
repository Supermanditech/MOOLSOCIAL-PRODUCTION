# Live public YouTube Videos + Shorts proof

Date: 25 July 2026  
Environment: dedicated private Dev (`moolsocial-dev-503018`)  
Device: founder-authorized OPPO `2b3e0f71`

## Outcome

MoolSocial now exposes both required consumer surfaces against the persistent
private-Dev YouTube provider:

- **Videos:** real public YouTube catalogue, public metadata and official
  embedded playback remain live.
- **Shorts:** Screen 04 now has a dedicated `YouTube` filter, real provider
  title/channel/count metadata, an unobscured official portrait player,
  vertical paging and separate MoolSocial Save/Discuss/Share/Details actions.

The installed candidate is `youtube-shorts-oppo-20260725-06`. The app was left
open on the live YouTube-only Shorts lane for continued founder testing.

## Live boundary

- Cloud Run revision: `youtubeprovider-00024-dol`
- Runtime profile: `PublicDataReview`
- `YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted`
- `YOUTUBE_PUBLIC_DATA_ENABLED=true`
- Owner Connect, Owner Actions, Creator Assets, Live, Private Upload and Owner
  Analytics: false
- timed proof profile/expiry: absent
- App Check: Play Integrity guarded
- current app request sample: the latest 20 provider POSTs were HTTP `200`
- one HTTP `401` at `2026-07-25T16:23:49.677365Z` is the deliberate
  unauthenticated App Check guard probe, not a customer request

Staging and Production were unchanged.

## Shorts admission

YouTube Data API v3 does not expose a public `isShort` field. MoolSocial
therefore does not treat duration alone as a Shorts classifier.

A public search result is admitted to the YouTube Shorts lane only when all of
these checks pass:

1. the current provider record is public, processed, embeddable and available
   in India;
2. the creator explicitly declares `Short`/`Shorts`/`YouTube Shorts` in the
   provider-returned title, localized text, description or tags; and
3. the ISO-8601 duration is greater than zero and no more than 180 seconds.

The installed run returned eight admitted YouTube items. The first real Short
played with official controls and `Watch on YouTube`; a vertical swipe loaded
the second real Short without a player lifecycle exception.

## Verification

- focused Screen 04, public runtime and official-player tests: `63/63`
- Flutter analysis for the changed runtime/UI: no issues
- existing backend suite before this UI-only continuation: `269/269`
- device catalogue, YouTube-only lane, explicit playback and vertical
  transition: passed
- lifecycle log scan after the visible-player ownership correction:
  `NO_UNHANDLED_PLAYER_LIFECYCLE_ERRORS`

## Candidate and evidence SHA-256

```text
5C2E72C6805F40E6A1E574A3543CDE77D816E47FBEB48F7748880C952BC4E31B  moolsocial-youtube-videos-shorts-private-dev-r6.apk
B5C1C3672A774120DC3C786B1D251F9609C4392DD7443B4A0ED2C78FCB25890D  oppo-youtube-videos-shorts-r6-short-after-play.png
60F44D90E6A8DBD2ED81868C9244F5ADEBA99406BF79385E21C082279790065B  oppo-youtube-videos-shorts-r6-short-after-play.xml
B0D60A453917C990A87962F5F20BF8683F8CDDFE85C8EE52D886A9DBA17FDD8F  oppo-youtube-videos-shorts-r6-short-playing.png
EDEF4698C2DE51C4CAD7FF58A4BA3C71F07DB28163CF47FB43C8828BE7739C56  oppo-youtube-videos-shorts-r6-short-playing.xml
C5E0F992745660C129AE58D89DF7D5348118CB9D85DAD56A024446EFCBAEA2C9  oppo-youtube-videos-shorts-r6-short-second.png
47BEBE55C3943A6F8426988E23E2E1FD6C3E018257FAFFECF133A437026C3482  oppo-youtube-videos-shorts-r6-short-second.xml
ACB5CA172B06E551B671AEC8B0C406BC5BD8E66BE3056735D4B885BC5AA94307  oppo-youtube-videos-shorts-r6-youtube-filter-playing.png
3D9BEC5382B03032C5E51E478323D9EDCE8245206421D4E10A55A4332DA14F39  oppo-youtube-videos-shorts-r6-youtube-filter-playing.xml
```

The accepted profile is intentionally public-data-only. Connected account
actions, creator uploads/assets, Analytics/Reporting and Live management keep
their existing typed contracts but remain disabled until their separate OAuth,
eligibility, consent and provider-proof gates pass.
