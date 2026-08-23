# UAW C10D historical tests retained retired Chat navigation keys

- Registry: `REG-20260807-212-HISTORICAL-NAVIGATION-TESTS-RETAINED-CHAT-TOP-BACK-AND-DUPLICATE-MOOL-KEYS`
- State: resolved; complete affected-test inventory active
- Repair: old Mool launchers now use `mool-root-selected`; top-level Chat inbox return uses system Back and explicitly asserts `chat-back` is absent.
- Required proof: C05, action-wording/wiring Fix1 and Fix2 pass together with the C10D and Chat flow suites.
