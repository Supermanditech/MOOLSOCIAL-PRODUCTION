import assert from "node:assert/strict";
import test from "node:test";

import type { DataConnect } from "firebase-admin/data-connect";

import { DataConnectYouTubeAuditStore } from "./audit_store.js";

interface CapturedCall {
  readonly document: string;
  readonly variables: Readonly<Record<string, unknown>>;
}

function dataConnectDouble(): {
  readonly dataConnect: DataConnect;
  readonly calls: CapturedCall[];
} {
  const calls: CapturedCall[] = [];
  const double = {
    executeGraphql: async (
      document: string,
      options: { readonly variables: Readonly<Record<string, unknown>> },
    ): Promise<unknown> => {
      calls.push({ document, variables: options.variables });
      return { data: {} };
    },
  };
  return {
    dataConnect: double as unknown as DataConnect,
    calls,
  };
}

test("audit evidence is append-only, idempotent and redacted", async () => {
  const { dataConnect, calls } = dataConnectDouble();
  const store = new DataConnectYouTubeAuditStore(dataConnect);

  await store.record({
    userId: "user-1",
    eventType: "connection.disconnected",
    requestId: "request-1",
    detail: {
      providerRevocationConfirmed: false,
      accessToken: "secret-access-token",
      note: "Authorization: Bearer secret-bearer",
    },
    occurredAt: "2026-07-24T00:00:00.000Z",
  });

  assert.equal(calls.length, 1);
  const call = calls[0];
  assert.ok(call);
  assert.match(call.document, /INSERT INTO provider_audit_event/);
  assert.match(call.document, /ON CONFLICT \(event_key\) DO NOTHING/);
  assert.equal(call.variables.userId, "user-1");
  assert.equal(call.variables.eventType, "connection.disconnected");
  assert.match(String(call.variables.eventKey), /^yta_[A-Za-z0-9_-]{43}$/u);
  const detail = String(call.variables.redactedDetailJson);
  assert.doesNotMatch(detail, /secret-access-token|secret-bearer/u);
  assert.match(detail, /\[REDACTED\]/u);
  assert.match(detail, /providerRevocationConfirmed/u);
});

test("audit evidence rejects invalid metadata before Data Connect", async () => {
  const { dataConnect, calls } = dataConnectDouble();
  const store = new DataConnectYouTubeAuditStore(dataConnect);

  await assert.rejects(
    store.record({
      eventType: "INVALID EVENT",
      requestId: "request-1",
      detail: {},
      occurredAt: "2026-07-24T00:00:00.000Z",
    }),
    /event type is invalid/u,
  );

  assert.equal(calls.length, 0);
});
