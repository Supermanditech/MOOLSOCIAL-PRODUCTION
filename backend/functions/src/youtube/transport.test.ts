import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import { FetchHttpTransport } from "./transport.js";

test("fetch transport disables redirects for API and upload requests", async () => {
  const originalFetch = globalThis.fetch;
  const observations: Array<{
    readonly method: string | undefined;
    readonly redirect: RequestRedirect | undefined;
  }> = [];
  globalThis.fetch = (async (
    _input: string | URL | Request,
    init?: RequestInit,
  ) => {
    observations.push({
      method: init?.method,
      redirect: init?.redirect,
    });
    return new Response("", {
      status: 302,
      headers: { location: "https://evil.example/capture" },
    });
  }) as typeof fetch;

  try {
    for (const request of [
      {
        url: "https://www.googleapis.com/youtube/v3/videos",
      },
      {
        url:
          "https://www.googleapis.com/upload/youtube/v3/videos" +
          "?upload_id=opaque",
        method: "PUT" as const,
      },
    ]) {
      await assert.rejects(
        new FetchHttpTransport().send(request),
        (error: unknown) =>
          error instanceof YouTubeProviderError &&
          error.code === "provider_rejected" &&
          error.httpStatus === 502 &&
          error.retryable === false,
      );
    }
    assert.deepEqual(observations, [
      { method: "GET", redirect: "manual" },
      { method: "PUT", redirect: "manual" },
    ]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("fetch transport converts network failures without hiding policy errors", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async () => {
    throw new TypeError("network unavailable");
  }) as typeof fetch;

  try {
    await assert.rejects(
      new FetchHttpTransport().send({
        url: "https://www.googleapis.com/youtube/v3/videos",
      }),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "provider_unavailable" &&
        error.httpStatus === 503,
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("bounded binary responses are base64 encoded only after success", async () => {
  const originalFetch = globalThis.fetch;
  const responses = [
    new Response(new Uint8Array([0, 1, 2, 255]), {
      status: 200,
      headers: { "content-type": "application/octet-stream" },
    }),
    new Response('{"error":{"errors":[{"reason":"quotaExceeded"}]}}', {
      status: 403,
      headers: { "content-type": "application/json" },
    }),
  ];
  globalThis.fetch = (async () => responses.shift()!) as typeof fetch;

  try {
    const transport = new FetchHttpTransport();
    const success = await transport.send({
      url: "https://www.googleapis.com/youtube/v3/captions/id",
      responseEncoding: "base64",
      maxResponseBytes: 1024,
    });
    assert.equal(success.body, Buffer.from([0, 1, 2, 255]).toString("base64"));

    const failure = await transport.send({
      url: "https://www.googleapis.com/youtube/v3/captions/id",
      responseEncoding: "base64",
      maxResponseBytes: 1024,
    });
    assert.match(failure.body, /quotaExceeded/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("bounded responses fail closed before or during oversized provider streams", async () => {
  const originalFetch = globalThis.fetch;
  const responses = [
    new Response(new Uint8Array(12), {
      status: 200,
      headers: { "content-length": "12" },
    }),
    new Response(
      new ReadableStream<Uint8Array>({
        start(controller) {
          controller.enqueue(new Uint8Array(6));
          controller.enqueue(new Uint8Array(6));
          controller.close();
        },
      }),
      { status: 200 },
    ),
  ];
  globalThis.fetch = (async () => responses.shift()!) as typeof fetch;

  try {
    const transport = new FetchHttpTransport();
    for (let index = 0; index < 2; index += 1) {
      await assert.rejects(
        transport.send({
          url: "https://www.googleapis.com/youtube/v3/captions/id",
          responseEncoding: "base64",
          maxResponseBytes: 10,
        }),
        (error: unknown) =>
          error instanceof YouTubeProviderError &&
          error.code === "provider_rejected" &&
          error.httpStatus === 502,
      );
    }
  } finally {
    globalThis.fetch = originalFetch;
  }
});
