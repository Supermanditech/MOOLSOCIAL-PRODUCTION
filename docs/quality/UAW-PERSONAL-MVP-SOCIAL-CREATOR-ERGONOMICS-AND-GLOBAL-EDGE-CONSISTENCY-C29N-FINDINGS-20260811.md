# C29N Social creator ergonomics and global edge consistency findings

## Founder findings

- Social reverses the established global edge habit by placing Mool on the
  right. On black YouTube surfaces its navy foreground lacks sufficient visual
  separation. Chat needs the same stable white edge treatment.
- The universal location/search/scan/voice utility header consumes Social
  space without serving Feed or Create. YouTube Home already owns its useful
  provider discovery header separately.
- Social plus first asks for a host and then asks for a MoolSocial format,
  making Text, Image, Carousel, Image Poll, Quick Poll and Quiz more than one
  action away.
- The current workbench keeps a content library, universal header and Social
  dock while the keyboard reduces the viewport. The fixed lower-workbench
  height then leaves an unreasonably small writing area.

## Reuse and duplicate assessment

The correction reuses the current `MoolGlobalNavigationV2`, Social ownership
dock, creator gateway, create workbench, `SharedSession` and
`SocialMediaPicker`. There is no need for another route, screen, backend owner,
draft service or publish state. The one new presentation adapter is a shared
white Chat edge launcher paired with the existing Mool launcher.

## MVP and authority disposition

C29N is MVP-required because the founder confirmed contrast, muscle-memory,
tap-count and keyboard reachability regressions in the launch Social journey.
It is one atomic source-only correction before C29M. It does not authorize a
provider deployment, APK build, device install, Production write, credential
access or accepted-reference mutation.

## Locked interaction decision

Mool is fixed to the left edge and Chat to the right edge everywhere; both use
white high-contrast surfaces and at least 44 logical pixels. Social owns only
the middle Home, Shorts, Create and Feed actions. Social plus exposes YouTube
Short and all six MoolSocial formats directly. Feed Write a post opens Text
directly. Firebase/MoolSocial authentication never substitutes for separate
Google YouTube-channel consent.
