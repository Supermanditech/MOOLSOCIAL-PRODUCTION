# C29P review-gateway fixture assumption rejection

The first focused Flutter run exposed a hard-coded legacy post ID and a retry expectation against an intentionally static unavailable fixture. Tests now inject the gateway, consume acknowledged server-owned identity and keep static named states separate from runtime retry behavior.
