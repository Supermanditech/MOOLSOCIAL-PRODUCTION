# C10C Buy route test versus Social cold launch

The in-session Buy router correctly updates to the Medicine subroute. A separate stale assertion expected that route to become the next cold-launch route, contradicting C10A. The test now keeps the runtime route assertion and independently requires Social from `readyRoute()` without an explicit pending deep link.
