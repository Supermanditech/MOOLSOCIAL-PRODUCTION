# UAW C10D Chat inbox-thread exact route state

- Registry: `REG-20260807-206-CHAT-INBOX-THREAD-ROUTE-REPLACEMENT-LOST-LOCAL-STATE`
- State: resolved; dedicated C10D, full 159/159 affected family, analyzer and static gates pass
- Runtime owner: `_openThread` in `chat_inbox_screen.dart`
- Durable contract: local thread depth and global destination switches push live route history; Back pops exact live state and protected return URIs are fallback-only for direct entry.
- Proof: inbox query/filter, thread draft, focus and IME exact-return journeys pass; no APK was built or installed.
