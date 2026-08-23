# C30T attribution source-assertion owner overreach

Date: 2026-08-13

The first source gate forbade the generic YouTube Home URI across the entire Social consumer. That URI legitimately belongs to the separate explicit YouTube Home launcher, so the focused test failed even though the attribution fallback had been removed.

The corrected test must extract only `_YouTubeAttribution` between exact adjacent class declarations and assert within that bounded owner. The separate Home launcher remains valid.
