# C29P media and idempotency boundary hardening

Prequalification review rejected shared upload paths, incomplete conflict cleanup, MIME-only image trust, unhandled local file loss and incompatible decoded/base64 limits. Candidate media now uses unique post paths, every losing outcome cleans only its own objects, server image signatures are verified, file loss is a customer-safe domain error and the 20 MB decoded limit fits the bounded request envelope. Focused race, recovery and conflict tests pass.
