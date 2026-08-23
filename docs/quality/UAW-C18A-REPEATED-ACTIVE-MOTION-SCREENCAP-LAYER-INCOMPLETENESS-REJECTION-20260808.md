# UAW C18A repeated active-motion screencap layer-incompleteness rejection — 2026-08-08

## Result

The uniquely named repeat at nominal 2,800 ms did not reproduce the first
capture's missing wordmark. It contained the complete wordmark, identity line,
tagline and business promise, but omitted the separately painted footer that
was present in the 3,500 ms settled control.

Because different layers are absent across two one-off device-side screenshots
at the same nominal active-motion point, neither image can prove a stable
runtime flicker. Both are preserved and rejected for motion continuity.

## Prevention

Single `screencap` samples are no longer admissible for C18A active-motion
continuity. One bounded device screen recording must cover system-window,
wordmark, tagline, business and settled stages across consecutive frames. A
repeatable missing layer in that recording is a runtime rejection; transient
single-frame screencap omissions are capture-method evidence only.

No APK build, install, uninstall, data clear, downgrade, source, golden or
accepted-reference mutation occurred.
