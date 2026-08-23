# C24G Work gateway latency constructor guess rejection — 2026-08-09

The first focused C24G test copied the zero-latency fixture pattern used by
other service gateways and passed `latency` to `ReviewWorkGateway`. The Work
gateway has a zero-argument constructor, so the test failed to compile and no
test case ran.

The retry uses the literal Work gateway constructor already exercised by the
complete Work vertical slice. Constructor parameters are never inferred from a
different feature gateway.
