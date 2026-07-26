import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const providerModule = require("../backend/functions/lib/index.js");

const actual = Object.keys(providerModule).sort();
const expected = ["youtubeOAuthCallback", "youtubeProvider"].sort();

if (JSON.stringify(actual) !== JSON.stringify(expected)) {
  process.stderr.write(
    `Unexpected provider exports: ${JSON.stringify(actual)}\n`,
  );
  process.exit(1);
}
