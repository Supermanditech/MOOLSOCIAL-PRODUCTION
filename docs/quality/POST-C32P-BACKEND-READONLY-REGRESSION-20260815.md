# Post-C32P backend read-only regression

Date: 15 August 2026

The bounded backend package was discovered at `backend/functions/package.json`. Its declared `npm test` wrapper was not used because it begins with a recursive clean of the generated `lib` directory, which is outside the safe read-only overnight boundary for the founder-owned dirty tree.

Safe validation completed:

- `npm run typecheck` (`tsc --noEmit`): passed.
- Existing compiled corpus: 53 `*.test.js` files discovered under `backend/functions/lib`.
- Direct read-only `node --test "lib/**/*.test.js"`: 528 passed, 0 failed, 0 skipped/cancelled/todo.

This validates current TypeScript type consistency and the retained compiled test corpus separately. It is not a fresh build/source-to-lib equivalence claim, emulator result, backend deployment or live-service acceptance. No clean, build, deploy, provider, credential or external-service command ran.
