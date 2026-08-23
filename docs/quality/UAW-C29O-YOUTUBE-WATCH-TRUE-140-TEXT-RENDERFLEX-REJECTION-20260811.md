# C29O YouTube watch true-140% RenderFlex rejection

Date: 2026-08-11

After removal of the width-based Social text-scale clamp, the focused Screen 04
test rendered the YouTube watch journey at 320x568 and a real 1.4 text scale.
The journey reached its final assertion with a `RenderFlex` overflow of 12
pixels on the right. This proves the old test matrix was not exercising the
requested scale inside Social.

The failing cycle is rejected. No build, install, device, provider or protected
release state changed.

Permanent prevention: supported-viewport tests assert the descendant
`MediaQuery` scale before judging fitment; a narrow-screen row adapts or wraps
its content and never repairs overflow by lowering the user's text scale.
