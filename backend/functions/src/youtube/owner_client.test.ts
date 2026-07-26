import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeOwnerClient } from "./owner_client.js";
import type { YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";

class OneResponseTransport implements HttpTransport {
  request?: HttpTransportRequest;

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.request = request;
    return {
      status: 200,
      headers: {
        location:
          "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=secret",
      },
      body: "",
    };
  }
}

class UploadStatusTransport implements HttpTransport {
  request?: HttpTransportRequest;

  constructor(private readonly status: number) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.request = request;
    return {
      status: this.status,
      headers: {},
      body: this.status === 201 ? JSON.stringify({ id: "video123" }) : "",
    };
  }
}

const quota: YouTubeQuotaPort = {
  reserve: async () => undefined,
};

test("resumable upload initialization is always private and direct", async () => {
  const transport = new OneResponseTransport();
  const client = new YouTubeOwnerClient({
    transport,
    quota,
    clock: { now: () => new Date("2026-07-23T00:00:00Z") },
  });

  const session = await client.beginPrivateUpload({
    principal: "user-1",
    requestId: "request-1",
    accessToken: "access-token",
    contentType: "video/mp4",
    contentLength: 1024,
    metadata: {
      title: "Morning market",
      description: "Jodhpur market",
      categoryId: "22",
      madeForKids: false,
      containsSyntheticMedia: false,
      containsPaidPromotion: true,
      notifySubscribers: false,
    },
  });

  assert.equal(session.privacyStatus, "private");
  assert.equal(
    transport.request?.url.startsWith(
      "https://www.googleapis.com/upload/youtube/v3/videos?",
    ),
    true,
  );
  assert.equal(transport.request?.headers?.["x-upload-content-length"], "1024");
  assert.equal(transport.request?.headers?.["x-upload-content-type"], "video/mp4");
  const body = JSON.parse(transport.request?.body ?? "{}") as {
    status?: {
      privacyStatus?: string;
      selfDeclaredMadeForKids?: boolean;
      containsSyntheticMedia?: boolean;
    };
    paidProductPlacementDetails?: {
      hasPaidProductPlacement?: boolean;
    };
  };
  assert.equal(body.status?.privacyStatus, "private");
  assert.equal(body.status?.selfDeclaredMadeForKids, false);
  assert.equal(body.status?.containsSyntheticMedia, false);
  assert.equal(
    body.paidProductPlacementDetails?.hasPaidProductPlacement,
    true,
  );
});

test("completed upload identity comes from the original resumable session", async () => {
  const transport = new UploadStatusTransport(201);
  const client = new YouTubeOwnerClient({ transport, quota });

  const videoId = await client.completedUploadVideoId({
    accessToken: "access-token",
    sessionUrl:
      "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=secret",
    contentLength: 1024,
  });

  assert.equal(videoId, "video123");
  assert.equal(transport.request?.method, "PUT");
  assert.equal(transport.request?.headers?.["content-length"], "0");
  assert.equal(transport.request?.headers?.["content-range"], "bytes */1024");
});

test("incomplete resumable upload asks the caller to retry", async () => {
  const transport = new UploadStatusTransport(308);
  const client = new YouTubeOwnerClient({ transport, quota });

  await assert.rejects(
    client.completedUploadVideoId({
      accessToken: "access-token",
      sessionUrl:
        "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=secret",
      contentLength: 1024,
    }),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "conflict",
  );
});
