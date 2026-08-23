# C31A Chat Dart null-aware map element lint

Date: 2026-08-14
Registry ID: `REG-20260814-2124-C31A-CHAT-DART-NULL-AWARE-MAP-ELEMENT-LINT`

The first focused Flutter analyzer rejected the conditional collection entry used for optional `replyToMessageId` request data. The active Dart lint requires the null-aware map-value element form.

The correction uses the current null-aware syntax and reruns the implementation regression gate before the analyzer. No live Chat request, backend deployment, app build or device action occurred.
