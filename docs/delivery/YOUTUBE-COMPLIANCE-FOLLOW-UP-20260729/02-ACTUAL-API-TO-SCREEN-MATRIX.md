# Actual API-to-screen matrix

This matrix describes the recordable private-Dev client. It is not the
broader locally typed endpoint inventory.

The original quota-form method selection also included planned future
capabilities. Those selections are not evidence that the current client calls
the methods. The reviewer email and screencast therefore disclose the
difference and request guidance before a later capability or quota submission.

| Visible journey | Provider operation or surface | Current result | Screencast treatment |
|---|---|---|---|
| Videos starting library | `videos.list(chart=mostPopular, regionCode=IN)` | Live private-Dev public data | Demonstrate |
| Public video details and policy filtering | `videos.list` returned metadata | Live private-Dev public data | Demonstrate |
| Channel enrichment | `channels.list` for returned channel IDs | Live private-Dev public data | Demonstrate |
| Explicit public search | `search.list` plus `videos.list` hydration | Implemented, quota-sensitive; record only if live in exact build | Conditional |
| Approved channel/playlist paging | `channels.list`, `playlistItems.list`, `videos.list` | Typed/local contract; do not claim live unless recorded | Optional only after proof |
| Selected video playback | official YouTube IFrame Player | Live on physical OPPO | Demonstrate |
| YouTube-only Shorts lane | `search.list` candidates plus returned video metadata and official player | Live bounded private-Dev proof | Demonstrate with classification explanation |
| Owner channel connection | OAuth 2.0 system-browser flow, `youtube.readonly`, exact channel reconciliation | VetoNews proof body passed; owner profile is normally disabled | Demonstrate only in a supervised window or use clearly dated evidence |
| Browser-to-app return | OAuth callback plus token-free MoolSocial deep link | Live and device-proven | Demonstrate |
| Viewer Like/Comment/Subscribe | narrow authorized Data API mutations | Disabled/unproved | Do not depict as live |
| Creator upload | `videos.insert` resumable upload | Disabled/unproved | Do not depict as live |
| Analytics/Reporting | owner-authorized APIs | Disabled/unproved | Do not depict as live |
| Live management | Live Streaming API resources | Disabled/unproved | Do not depict as live |

## End-result statements permitted in the reply

- MoolSocial currently shows eligible public YouTube videos and a bounded
  YouTube Shorts lane on a physical Android device.
- Selecting an item plays it through the official YouTube embedded player.
- YouTube source identity and provider controls remain visible.
- MoolSocial has completed a supervised read-only VetoNews channel connection
  and exact-channel reconciliation in private Dev.
- The connection returns to the pending native MoolSocial screen without
  placing OAuth credentials in the route.

## Statements prohibited until further proof

- all 70 selected methods are active;
- MoolSocial can currently upload public or unlisted video;
- users can currently Like, Comment or Subscribe on YouTube from MoolSocial;
- YouTube Analytics, Reporting or Live Studio are customer-ready;
- YouTube has approved the Production project or requested quota;
- MoolSocial reproduces YouTube Home or the native Shorts recommendation feed;
  or
- every new YouTube upload will appear immediately in MoolSocial.
