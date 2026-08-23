# C30U YouTube cancellation test used wrong session getter

The test asserted `authenticationCancelFallback`, which owns the last ready
route used for router interception. The active sign-in cancellation target is
`readyRoute()`, backed by `_authenticationCancelTo`.

The source stored the explicit Videos destination correctly. The test now
asserts the correct public owner. No release mutation occurred.
