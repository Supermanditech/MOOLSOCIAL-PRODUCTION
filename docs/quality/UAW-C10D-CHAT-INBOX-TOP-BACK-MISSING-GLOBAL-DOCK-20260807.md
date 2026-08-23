# UAW C10D Chat inbox top Back and missing global dock

- Registry: `REG-20260807-204-CHAT-INBOX-RETAINED-TOP-BACK-WITHOUT-SHARED-GLOBAL-DOCK`
- State: resolved; dedicated C10D, full 159/159 affected family, analyzer and static gates pass
- Runtime owner: `features/chat/widgets/chat_widgets.dart`
- Durable contract: inbox is global Chat root, shows Chat selected in the shared dock, has no top Back, and system Back restores exact pushed history or its protected return route.
- Proof: `chat-open-mool` and `chat-thread-mool` are absent from reachable production source; no APK was built or installed.
