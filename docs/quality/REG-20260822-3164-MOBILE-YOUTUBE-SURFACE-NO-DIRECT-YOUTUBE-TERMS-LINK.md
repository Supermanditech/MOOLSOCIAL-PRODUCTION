# REG3164 - Mobile YouTube surface has no direct YouTube Terms link

## Classification

Registered source gap, dependency-held; final YouTube submission is not ready.

## Evidence

`apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart` defines and renders links for MoolSocial Privacy, Disconnect, Google permissions and account deletion. No direct YouTube Terms of Service URI or control is present in that audited mobile surface, and no such direct link was found elsewhere in current mobile source. The public website does contain the link, but it is a separate surface.

Google's current YouTube API Services Developer Policies require each API Client to display a link to the YouTube Terms of Service. This finding records the source omission; it does not claim a provider verdict.

## Prevention

After FIX8 device acceptance, select one exact successor ticket to add direct YouTube Terms and Google Privacy links to the mobile YouTube control surface, extend focused tests, run two clean source cycles and capture exact-device reviewer proof. Do not implement this inside the active global-auth ticket.
