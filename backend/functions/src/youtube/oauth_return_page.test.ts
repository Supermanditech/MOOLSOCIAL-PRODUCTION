import assert from "node:assert/strict";
import test from "node:test";

import { youtubeOAuthReturnPage } from "./oauth_return_page.js";

test("successful OAuth return automatically opens the exact MoolSocial route", () => {
  const page = youtubeOAuthReturnPage("connected");

  assert.equal(
    page.appReturnUrl,
    "moolsocial:///app/creator/youtube-connect?youtubeConnect=complete",
  );
  assert.match(page.html, /http-equiv="refresh"/u);
  assert.match(page.html, /Open MoolSocial/u);
  assert.equal(
    page.html.match(
      /moolsocial:\/\/\/app\/creator\/youtube-connect\?youtubeConnect=complete/gu,
    )?.length,
    2,
  );
  assert.doesNotMatch(
    page.html,
    /(?:access_token|refresh_token|id_token|client_secret|state=|code=)/iu,
  );
  assert.match(page.contentSecurityPolicy, /default-src 'none'/u);
  assert.match(page.contentSecurityPolicy, /frame-ancestors 'none'/u);
});

test("failed OAuth return opens the same app route without sensitive data", () => {
  const page = youtubeOAuthReturnPage("notConnected");

  assert.equal(
    page.appReturnUrl,
    "moolsocial:///app/creator/youtube-connect?youtubeConnect=failed",
  );
  assert.match(page.html, /YouTube was not connected/u);
  assert.match(page.html, /Open MoolSocial/u);
  assert.doesNotMatch(
    page.html,
    /(?:access_token|refresh_token|id_token|client_secret|state=|code=)/iu,
  );
});
