# C29L full-analysis redundant test async import rejection

The first full Flutter analysis after all focused and protected tests passed found one lint: `social_v2_youtube_creator_upload_test.dart` imported `dart:async` even though the Flutter test framework already supplied the async types used.

The permanent prevention is to include new test files in the focused analysis target set, not only product owners, and remove framework-reexported imports before the full gate. No build, device, provider or protected runtime changed.
