# C29P production fake and Storage-rules boundary rejection

The review-only Social gateway was moved out of `lib` into test support, and Firebase Storage now has an explicit deny-all direct-client rules owner referenced by `firebase.json`. Production has no process-local Social fallback and still requires the exact authenticated Dev endpoint.
