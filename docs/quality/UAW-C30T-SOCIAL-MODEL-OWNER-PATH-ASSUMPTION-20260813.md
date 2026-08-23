# C30T Social model owner path assumption

Date: 2026-08-13

The fixture-fallback audit included an assumed `apps/mobile/lib/features/shared/social_content_models.dart` owner that is not present. The search printed useful matches from verified owners, then exited nonzero.

Permanent prevention: resolve exact filenames with `rg --files` before multi-file searches, or search a verified directory root when the owner name is unknown.
