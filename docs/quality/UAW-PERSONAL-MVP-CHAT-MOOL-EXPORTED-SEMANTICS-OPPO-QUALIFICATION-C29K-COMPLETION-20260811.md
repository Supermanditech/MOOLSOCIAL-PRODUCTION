# C29K r60.34 OPPO device qualification

## Result

`UAW-PERSONAL-MVP-CHAT-MOOL-EXPORTED-SEMANTICS-OPPO-QUALIFICATION-C29K` is device-qualified on the founder's OPPO CPH2375 and is held for founder review. This does not update any protected reference or accepted baseline.

## Installed identity

- Serial: `2b3e0f71`
- Package: `com.moolsocial.app`
- Version: `1.0.0-r60.34` / `2026081134`
- Artifact and installed APK SHA-256: `96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29`
- First install time preserved: `2026-08-04 02:51:59`
- Last update time: `2026-08-11 09:51:00`
- Exactly one build and one in-place install were performed. There was no uninstall, data clear, downgrade, second build or second install.

## Device results

- Chat's common `Mool` semantic target exports `[0,1342][720,1442]`: 100 physical pixels, or 50 logical pixels at 320 dpi. This closes the C29I 23-logical-pixel rejection and exceeds the 44-logical-pixel minimum.
- The Mool switcher exposes Social, Shop, Food, Travel, Care and Work as six 56-logical-pixel rows.
- The Social dock exposes Home, Shorts, Create, Feed, Chat and Mool with a minimum 47.5-logical-pixel height on the unobscured Home surface.
- Authenticated runtime reached the ready marker. The real provider Home returned visible Shorts and video content.
- Shorts began at exported `y=0`; one vertical swipe advanced from a Sarkar Short to a different Indiatimes Short.
- A provider video opened the YouTube watch surface with provider handoff, MoolSocial actions and MoolSocial discussion.
- Create exposed Post, Image, Image Poll, Quick Poll, Quiz and Carousel.
- Feed exposed Text, Photo and Carousel with a truthful empty state.
- No prohibited API, OAuth, Firebase, scope, lifecycle, simulation, persistence, test-target or implementation commentary appeared in the captured Create or Feed semantics.
- No MoolSocial fatal exception was found in the captured or final live device log review.

## Evidence

The machine-readable result is `artifacts/quality/uaw-personal-mvp-chat-mool-exported-semantics-oppo-qualification-c29k-r60-34-20260811-01/17-device-qualification.json`. The same directory preserves the checksum-qualified APK, source/build provenance, installed identity, runtime log, UIAutomator XML and OPPO screenshots for Chat, Mool, Home, Shorts, next Short, video watch, Create and Feed.

## Hold

The installed r60.34 identity and all C28D, C29I, C29J and C29K evidence remain preserved. Founder acceptance is required before any accepted-navigation reference, protected candidate baseline or delivery state can be promoted.
