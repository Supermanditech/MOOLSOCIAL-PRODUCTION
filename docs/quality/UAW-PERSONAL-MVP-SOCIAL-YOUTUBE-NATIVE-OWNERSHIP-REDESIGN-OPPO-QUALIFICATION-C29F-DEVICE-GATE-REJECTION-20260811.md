# C29F r60.31 Social device-gate rejection

Date: 2026-08-11
Candidate: `UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-NATIVE-OWNERSHIP-REDESIGN-OPPO-QUALIFICATION-C29F`
Installed version: `1.0.0-r60.31` / `2026081131`
Installed APK SHA-256: `497F00B5E52D17788B25353ADD36A4C91AA5C0A2BDD7967367BC3815F50AAA89`

## Decision

C29F is rejected at the OPPO device gate. Its one build and one install remain
consumed. The installed app, app data, package identity and all C29F/C29D/C28D
evidence remain immutable. No rebuild, reinstall, uninstall, data clear or
downgrade is authorized by this decision.

## Founder comparison evidence

- MoolSocial Shorts capture:
  `07-founder-recent-moolsocial-shorts.jpg`, SHA-256
  `7F19FC102B904A8B56DEA57D8CDBFEDD070C5269F465CBE22C3E10AB7D778E76`.
- Original YouTube Shorts capture:
  `08-founder-recent-original-youtube-shorts.jpg`, SHA-256
  `010F8524C10FC16F0B48FE51FBF432DC9B6F3B9765EDA87109114E1EE1657923`.
- First customer-copy escape:
  `09-founder-commentary-copy-regression.jpg`, SHA-256
  `75B388208E92119181917C3B58E83746C6EA5ADB0AB4EAE8133E88D93419501F`.
- Second customer-copy escape:
  `10-founder-commentary-copy-regression-2.jpg`, SHA-256
  `04514C46DED9B5CA4220649EBEDEA50DC662DDEA430FCC4908B90F3F5209400E`.

All files are retained under
`artifacts/quality/uaw-personal-mvp-social-youtube-native-ownership-redesign-oppo-qualification-c29f-r60-31-20260811-01`.

## Forensic findings

1. Original YouTube paints the vertical Short behind the transparent status
   region. C29F starts the provider player below an opaque 82-physical-pixel
   status strip, losing 41 logical pixels of the first viewport.
2. The original YouTube capture uses a 56dp-class bottom dock. C29F's dock is
   visually 66dp, but the OPPO hierarchy clips exported Home, Shorts, Create,
   Feed and Chat bounds to 48 physical pixels (24dp) and Mool to 41 physical
   pixels (20.5dp). This repeats the C28D rejection class and fails the 44dp
   minimum.
3. C29F displays the official generic embedded-player controls. The native
   YouTube app separately displays its own engagement rail, creator/subscribe
   controls and native navigation. MoolSocial cannot copy those controls or
   place overlays over the embedded player. Official YouTube requirements
   prohibit overlays or frames in front of any part of an embedded player.
   Authenticated likes, comments and subscriptions also remain unavailable
   without the approved OAuth journeys and scopes.
4. Two reachable center-plus states expose internal delivery language such as
   `GATED`, OAuth, provider capability, Firebase authentication, upload scope,
   lifecycle requirements and simulation policy. These are project evidence,
   not customer copy.

## Required successor boundary

The source successor must use the official provider player without copied or
fabricated YouTube engagement controls, draw Shorts edge-to-edge behind a
transparent status bar, reuse the accepted Android exported-semantics
clearance for all six dock controls, route `+` directly to available
MoolSocial creation while upload remains unavailable, and remove operational
commentary from every reachable Social state. A future APK requires a new
candidate, fresh host qualification and a new machine gate.
