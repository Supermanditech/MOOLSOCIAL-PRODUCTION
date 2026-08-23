# UAW C30T Social-tabs guessed-widget-file rejection — 2026-08-13

## Outcome

The Social tab-key lookup included the nonexistent file
`apps/mobile/lib/ui_v2/social/social_v2_widgets.dart`. Ripgrep returned useful
matches from the other files but also a path error, so that combined query is
not accepted as complete evidence.

The proven tab component owner imported by the consumer is
`screen04_universal_components.dart`. No source state changed.

## Permanent prevention

Use imported exact component paths or `rg --files` inventory before querying a
supporting widget file. Do not add conventional filenames to an otherwise
bounded search.
