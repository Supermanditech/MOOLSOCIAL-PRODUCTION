# UAW C18A unsynchronized ADB mid-reveal partial-composition rejection — 2026-08-08

## Rejected capture

After the founder unlocked the OPPO, C18A captured the existing installed
r60.16 launch at nominal 2,800 ms. The image
`07-r60-16-stage-2800ms-unlocked.png` contains the tagline and a very faint
business stage while the separate wordmark layer is absent. The immediately
later fresh-launch 3,500 ms capture contains the complete wordmark, identity
line, tagline, business promise and footer.

The 2,800 ms image was taken with an unsynchronized device-side `screencap`
during active Flutter composition. It is not admitted as evidence of a stable
user-visible state and is preserved rather than deleted.

No APK build, install, uninstall, data clear, downgrade, source, golden or
accepted-reference mutation occurred.

## Prevention

Active-motion device frames require a repeated uniquely named capture at the
same nominal stage and a complete settled control. A single ADB screenshot
taken while multiple layers are compositing cannot establish flicker or
presentation equivalence. If the partial state repeats, it becomes a runtime
motion rejection; if it does not, both attempts remain documented and only
the repeatable frames qualify.
