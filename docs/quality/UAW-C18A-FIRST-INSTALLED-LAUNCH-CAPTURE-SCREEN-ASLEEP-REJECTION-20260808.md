# UAW C18A first installed-launch capture screen-asleep rejection — 2026-08-08

## Rejected attempt

The first C18A launch replay force-stopped and started the already installed
`com.moolsocial.app` package, waited for the activity command and captured
`01-r60-16-launch-wordmark.png`. The image is entirely black and is not
accepted as Screen01 visual evidence.

Immediate device diagnosis reported `mWakefulness=Asleep`. The capture command
had not verified an awake/unlocked display before launching. No APK build,
install, uninstall, data clear, downgrade, reference mutation or app-data
mutation occurred. The rejected image remains preserved in the C18A evidence
root.

## Permanent prevention

Every device visual replay must prove the display is awake and the keyguard is
not blocking before the app launch. A black/asleep capture is registered and
discarded; it cannot establish launch appearance or equivalence. The retry may
wake and unlock the existing device only, then must re-read display state
before capturing a uniquely named successor image.
