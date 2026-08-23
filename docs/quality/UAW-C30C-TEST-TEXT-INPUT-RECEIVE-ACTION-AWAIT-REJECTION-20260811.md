# C30C TestTextInput receiveAction await rejection

- Regression: `REG-20260811-1366-C30C-TEST-TEXT-INPUT-RECEIVE-ACTION-AWAIT-REJECTION`
- Date: 2026-08-11
- Failure: focused tests omitted `await` on `receiveAction`, causing Flutter guarded-function conflicts.
- Prevention: await every asynchronous keyboard action before pump or any other guarded tester API.
