# UAW C10D duplicate Chat Mool launchers

- Registry: `REG-20260807-205-CHAT-DUPLICATED-MOOL-LAUNCHERS-OUTSIDE-GLOBAL-DOCK`
- State: resolved; dedicated C10D, full 159/159 affected family, analyzer and static gates pass
- Runtime owners: inbox header `chat-open-mool` and thread composer `chat-thread-mool`
- Durable contract: Mool is exposed once through the fixed global-dock edge; destination-local duplicates have no reachable call site.
- Proof: static source scan reports no `chat-open-mool` or `chat-thread-mool`; no APK was built or installed.
