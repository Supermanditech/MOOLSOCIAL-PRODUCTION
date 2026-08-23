# C30T Node assertion for synchronous validation

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: Chat service boundary test

The Chat service correctly rejected an out-of-range conversation limit before repository I/O, but the new test passed the call directly to `assert.rejects`. Because validation is synchronous, the expected `ChatError` escaped that asynchronous assertion.

The retry must change only the test to `assert.throws` and retain the service's fail-fast validation behavior.
