# C29P emulator CommonJS import-meta rejection

The first local rules-test helper used an ESM path primitive in the CommonJS backend package. Typecheck rejected it; the helper now resolves both deny-all rules from runtime `__dirname` before emulator startup.
