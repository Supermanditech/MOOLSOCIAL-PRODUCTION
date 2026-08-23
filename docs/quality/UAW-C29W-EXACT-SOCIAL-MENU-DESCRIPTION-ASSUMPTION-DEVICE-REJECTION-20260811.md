# C29W exact Social menu description assumption device rejection

- Date: 2026-08-11
- Candidate: `1.0.0-r60.35` (`2026081135`)
- Result: semantic lookup rejected before tap

The fresh UI hierarchy was captured, but the lookup guessed that Social would export the exact state-dependent description `Social, current domain`. That literal was absent and no tap was performed. Subsequent device navigation first inspects the bounded clickable-node inventory, then uses the actual fresh description and bounds. No app/provider data was written.
