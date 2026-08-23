# C30T specialized Social rail keys — 2026-08-13

C25E and C26D correctly exercise the current connected six-family navigator, but their first Social assertion still expected the generic `moolsocial-local-*-selection` key family. C30T Social is a specialized YouTube/MoolSocial surface and exposes `screen04-rail-shorts`, `screen04-rail-videos`, `screen04-rail-feed`, and `screen04-rail-create`.

The bounded test correction uses those canonical Social owners while leaving the generic local-selection contract unchanged for Shop, Food, Travel, Care and Work. No product source changes are required.

## Resolution

C26D now passes the real Social-to-Shop round trip and C25E passes the complete Social, Shop, Food, Travel, Care, Work, Chat and exact-return journey. Product source was unchanged.
