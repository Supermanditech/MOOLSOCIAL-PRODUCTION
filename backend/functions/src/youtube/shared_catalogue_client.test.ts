import assert from "node:assert/strict";
import test from "node:test";

import { ProcessYouTubeCache } from "./adapters.js";
import { YouTubeDataClient } from "./client.js";
import { sharedShortsCatalogueContract } from "./shared_catalogue.js";
import type {
  QuotaReservation,
  YouTubeQuotaPort,
} from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";

class EmptySearchTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    return { status: 200, headers: {}, body: "{\"items\":[]}" };
  }
}

class RecordingQuota implements YouTubeQuotaPort {
  readonly reservations: QuotaReservation[] = [];

  async reserve(reservation: QuotaReservation): Promise<void> {
    this.reservations.push(reservation);
  }
}

test("explicit user search and shared refresh keep distinct quota purpose", async () => {
  const transport = new EmptySearchTransport();
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-server-key",
  });

  await client.explicitSearch("public", "request-explicit", {
    query: "India news",
    regionCode: "IN",
  });
  await client.sharedCatalogueSearch("request-shared", {
    query: "India news #Shorts",
    regionCode: "IN",
    maxResults: sharedShortsCatalogueContract.pageSize,
  });

  assert.deepEqual(
    quota.reservations.map(({ principal, bucket, operation, requestId }) => ({
      principal,
      bucket,
      operation,
      requestId,
    })),
    [
      {
        principal: "public",
        bucket: "search",
        operation: "search.list.explicit",
        requestId: "request-explicit",
      },
      {
        principal: "shared-shorts-catalogue",
        bucket: "search",
        operation: "search.list.sharedShortsRefresh",
        requestId: "request-shared",
      },
    ],
  );
  assert.equal(transport.requests.length, 2);
  assert.equal(sharedShortsCatalogueContract.pageSize, 25);
  assert.equal(
    new URL(transport.requests[1]?.url ?? "https://invalid.example").searchParams.get(
      "maxResults",
    ),
    "25",
  );
});
