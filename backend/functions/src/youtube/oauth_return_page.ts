export type YouTubeOAuthReturnOutcome = "connected" | "notConnected";

export interface YouTubeOAuthReturnPage {
  readonly contentSecurityPolicy: string;
  readonly appReturnUrl: string;
  readonly html: string;
}

const APP_RETURN_BASE =
  "moolsocial:///app/creator/youtube-connect?youtubeConnect=";

export function youtubeOAuthReturnPage(
  outcome: YouTubeOAuthReturnOutcome,
): YouTubeOAuthReturnPage {
  const connected = outcome === "connected";
  const appReturnUrl = `${APP_RETURN_BASE}${
    connected ? "complete" : "failed"
  }`;
  const heading = connected
    ? "YouTube connected"
    : "YouTube was not connected";
  const detail = connected
    ? "Opening MoolSocial to confirm your channel."
    : "Opening MoolSocial so you can retry or choose another account.";

  return {
    contentSecurityPolicy:
      "default-src 'none'; style-src 'unsafe-inline'; " +
      "base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    appReturnUrl,
    html:
      "<!doctype html>" +
      '<html lang="en"><head>' +
      '<meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width,initial-scale=1">' +
      `<meta http-equiv="refresh" content="0;url=${appReturnUrl}">` +
      `<title>${heading}</title>` +
      "<style>" +
      "html{color-scheme:light dark;font-family:system-ui,sans-serif}" +
      "body{margin:0;min-height:100vh;display:grid;place-items:center;" +
      "background:#0b0b10;color:#fff}" +
      "main{max-width:32rem;padding:2rem;text-align:center}" +
      "a{display:inline-block;margin-top:1rem;padding:.8rem 1.1rem;" +
      "border-radius:999px;background:#fff;color:#111;text-decoration:none;" +
      "font-weight:700}" +
      "</style></head><body><main>" +
      `<h1>${heading}</h1><p>${detail}</p>` +
      `<a href="${appReturnUrl}">Open MoolSocial</a>` +
      "</main></body></html>",
  };
}
