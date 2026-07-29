# YouTube compliance founder-approval candidate

- Candidate: `youtube-compliance-followup-20260729-20`
- APK: `moolsocial-youtube-compliance-review-private-dev-r20.apk`
- APK SHA-256: `641957A49AFC9F6A8D742CF71A4F22E65832F2443701BDB89F7C06BEE6EAC8FC`
- Device replay: OPPO CPH2375, Android 13
- MP4: `output/video/MoolSocial-YouTube-API-Compliance-Walkthrough-r20.mp4`
- MP4 duration: `90.20 seconds`
- MP4 size: `3.20 MiB`
- MP4 SHA-256:
  `735029A8D4D46669388283C4A6093E8181CBFF17748EA1E6694B8BBE428CD8A6`
- Founder MP4 approval: received 29 July 2026
- Supporting PDF:
  `output/pdf/MoolSocial-YouTube-API-Compliance-Reference-r20.pdf`
- PDF pages: `9`
- PDF SHA-256:
  `09EA7347D0597C7733277307FEC857F6835EF6BF7BA85E70EDD7E2503F9B30CD`
- YouTube API reply sent from: `hello@moolsocial.com`
- Gmail message ID: `19fae0e9620d9306`
- Gmail thread ID: `19f9f78a25a287ee`
- Gmail sent-message attachment check: MP4 and PDF both present

## Approval sequence

1. `01-video-discovery.png` — API-backed public YouTube videos
2. `02-video-cued.png` — official YouTube player awaiting a user tap
3. `03-video-playing.png` — playback after the user tap
4. `04-shorts-cued.png` — official YouTube Shorts player awaiting a user tap
5. `05-shorts-playing.png` — Short playback after the user tap
6. `06-shorts-next-cued.png` — next Short remains cued after the user swipes
7. `07-short-discussion.png` — separate MoolSocial discussion
8. `08-short-details.png` — public metrics, provider channel, and official-player disclosure

## Passed gates

- Approved UI reference and production locks
- Dart analyzer for the modified Social/YouTube paths
- Public API mapping, region restriction, creator-declared Short, and compact-count tests
- Social navigation and customer-copy tests
- YouTube embedded-player runtime and Android bridge tests
- Screen 04 fitment at 320–430 px widths and 100%/140% text scaling
- Real-device API loading, user-initiated Video/Short playback, Short swipe, and external YouTube content/channel links

## Reviewer-surface restrictions

- No YouTube autoplay
- No `Following`, `Nearby`, or `Promoted` filters in the YouTube playback lane
- No MoolSocial ads, products, commerce cards, or rewarded actions adjacent to the YouTube player
- No simulated YouTube Like, Comment, or Subscribe controls
- MoolSocial Save, Discuss, Share, and Details remain outside the official player and clearly MoolSocial-owned
