# C16B static gate Dart-formatted provider-token false rejection

## Incident

The first C16B static gate passed the Social mapping and duplicate-owner checks
but rejected the contiguous text `MoolLocalNavigationTokens.providerIconWidth`.
Dart format had legally split that receiver and property across two lines in
the shared SVG renderer.

## Root cause and prevention

The checker encoded presentation formatting instead of semantic ownership. It
now proves the `providerIconWidth = 16` and `providerIconHeight = 11`
declarations plus `SvgPicture.asset` consumption, independent of line wrapping.
