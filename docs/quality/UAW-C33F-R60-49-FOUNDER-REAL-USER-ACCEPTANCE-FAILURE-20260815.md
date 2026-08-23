# UAW C33F r60.49 founder real-user acceptance failure

Date: 15 August 2026

Candidate `1.0.0-r60.49` (`2026081349`) is failed and must not be promoted, reused or described as runtime-successful. Its exact history remains one AAB build, one Google Play Internal Testing upload/activation, one in-place OPPO Play update and zero device acceptances.

The earlier cold-start check remains valid only for its bounded claims: the process started, an interactive first frame appeared, and the sampled launch contained no detected blank frame, fatal exception or ANR. It did not execute the mandatory authenticated and protected Social journeys and therefore was never sufficient release acceptance.

The founder's real-user OPPO test reported four release blockers:

- signed-out Social Feed entry redirects to login instead of the approved guest read path;
- Google account selection returns without completing sign-in and shows an error;
- the visible social-media identity choices provide no usable supported sign-in outcome;
- tapping Social Create crashes the application.

These findings are registered as active release blockers before any reproduction retry. A fifth regression records the process escape: unresolved predecessor journey blockers were not carried into a fail-closed pre-AAB closure matrix, allowing an AAB, upload and update after source-only and cold-start-only evidence.

No successor version, AAB, Play action or OPPO mutation is authorized by this record. Read-only device diagnostics and reversible UI navigation on the already installed app may continue. Source repair requires exact tickets, MVP classification, regression-memory application, focused journey tests and two complete qualifying cycles before a future candidate can be proposed.

Evidence: `artifacts/quality/uaw-c33f-r60-49-successor-preparation-20260815-01/12-founder-real-user-acceptance-failure-evidence.json`.
