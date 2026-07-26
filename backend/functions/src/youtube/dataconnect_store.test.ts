import assert from "node:assert/strict";
import test from "node:test";

import type { DataConnect } from "firebase-admin/data-connect";

import {
  DataConnectRefreshTokenPersistence,
  DataConnectYouTubePublicationStore,
} from "./dataconnect_store.js";
import type { EncryptedRefreshTokenRecord } from "./token_vault.js";
import type { YouTubePublicationJobRecord } from "./types.js";

interface CapturedCall {
  readonly document: string;
  readonly variables: Readonly<Record<string, unknown>>;
}

function dataConnectDouble(
  graphqlResults: readonly unknown[],
  readResult: unknown = { data: { externalPublicationJobs: [] } },
): { readonly dataConnect: DataConnect; readonly calls: CapturedCall[] } {
  const calls: CapturedCall[] = [];
  const results = [...graphqlResults];
  const double = {
    executeGraphql: async (
      document: string,
      options: { readonly variables: Readonly<Record<string, unknown>> },
    ): Promise<unknown> => {
      calls.push({ document, variables: options.variables });
      const result = results.shift();
      if (result === undefined) {
        throw new Error("No GraphQL result was configured.");
      }
      return result;
    },
    executeGraphqlRead: async (): Promise<unknown> => readResult,
  };
  return {
    dataConnect: double as unknown as DataConnect,
    calls,
  };
}

function reservationRecord(): YouTubePublicationJobRecord {
  return {
    jobKey: "job-1",
    userId: "user-1",
    connectionKey: "connection-1",
    idempotencyKey: "request-1",
    requestFingerprint: "sha256:request-1",
    title: "Private upload",
    privacyStatus: "private",
    contentLength: 2048,
    encryptedSessionUrl: "",
    state: "SESSION_CREATING",
    createdAt: "2026-07-23T00:00:00.000Z",
    updatedAt: "2026-07-23T00:00:00.000Z",
  };
}

test("credential key migration is one compare-and-swap update", async () => {
  const replacement: EncryptedRefreshTokenRecord = {
    connectionKey: "connection-1",
    encryptedRefreshToken: "mstv1.k2.nonce.ciphertext.tag",
    grantedScopes: ["scope-read", "scope-upload"],
    createdAt: "2026-07-22T00:00:00.000Z",
    updatedAt: "2026-07-24T00:00:00.000Z",
  };
  const { dataConnect, calls } = dataConnectDouble([
    { data: { migrated: { connection_key: "connection-1" } } },
  ]);
  const persistence = new DataConnectRefreshTokenPersistence(dataConnect);

  const migrated = await persistence.replaceIfCurrent(
    "mstv1.k1.old.nonce.tag",
    replacement,
  );

  assert.equal(migrated, true);
  assert.equal(calls.length, 1);
  const statement = calls[0]?.document ?? "";
  assert.match(statement, /UPDATE external_provider_credential/);
  assert.match(
    statement,
    /connection_key = \$1\s+AND encrypted_refresh_token = \$2/,
  );
  assert.match(statement, /RETURNING connection_key/);
  assert.equal(
    calls[0]?.variables.expectedEncryptedRefreshToken,
    "mstv1.k1.old.nonce.tag",
  );
  assert.equal(
    calls[0]?.variables.encryptedRefreshToken,
    replacement.encryptedRefreshToken,
  );
  assert.equal(
    calls[0]?.variables.scopesJson,
    JSON.stringify(replacement.grantedScopes),
  );
});

test("credential key migration reports a concurrent replacement", async () => {
  const { dataConnect } = dataConnectDouble([
    { data: { migrated: null } },
  ]);
  const persistence = new DataConnectRefreshTokenPersistence(dataConnect);

  assert.equal(
    await persistence.replaceIfCurrent("old-envelope", {
      connectionKey: "connection-1",
      encryptedRefreshToken: "new-envelope",
      grantedScopes: ["scope-read"],
      createdAt: "2026-07-22T00:00:00.000Z",
      updatedAt: "2026-07-24T00:00:00.000Z",
    }),
    false,
  );
});

test("publication reservation is one conditional insert gated by the ACTIVE YouTube connection", async () => {
  const record = reservationRecord();
  const { dataConnect, calls } = dataConnectDouble([
    { data: { reservation: { job_key: record.jobKey } } },
  ]);
  const store = new DataConnectYouTubePublicationStore(dataConnect);

  const result = await store.reserve(record);

  assert.equal(result.created, true);
  assert.equal(calls.length, 1);
  const statement = calls[0]?.document ?? "";
  assert.match(
    statement,
    /WITH active_connection AS MATERIALIZED \([\s\S]*FROM external_provider_connection AS connection[\s\S]*INSERT INTO external_publication_job/,
  );
  assert.match(statement, /connection\.connection_key = \$3/);
  assert.match(statement, /connection\.user_id = \$2/);
  assert.match(statement, /connection\.provider = 'YOUTUBE'/);
  assert.match(statement, /connection\.status = 'ACTIVE'/);
  assert.match(statement, /connection\.status = 'ACTIVE'\s+FOR UPDATE/);
  assert.match(statement, /FROM active_connection\s+ON CONFLICT/);
  assert.doesNotMatch(statement, /\bVALUES\s*\(/);
});

test("publication update is one conditional UPDATE and never read-then-upserts", async () => {
  const { dataConnect, calls } = dataConnectDouble([
    { data: { updated: { job_key: "job-1" } } },
  ]);
  const store = new DataConnectYouTubePublicationStore(dataConnect);

  await store.update("user-1", "job-1", {
    encryptedSessionUrl: "encrypted-session",
    sessionExpiresAt: "2026-07-24T00:00:00.000Z",
    state: "SESSION_READY",
    updatedAt: "2026-07-23T00:01:00.000Z",
  });

  assert.equal(calls.length, 1);
  const statement = calls[0]?.document ?? "";
  assert.match(statement, /UPDATE external_publication_job AS job/);
  assert.match(
    statement,
    /WITH active_connection AS MATERIALIZED \([\s\S]*FROM external_provider_connection AS connection/,
  );
  assert.match(statement, /connection\.provider = 'YOUTUBE'/);
  assert.match(statement, /connection\.status = 'ACTIVE'/);
  assert.match(statement, /connection\.status = 'ACTIVE'\s+FOR UPDATE/);
  assert.match(statement, /FROM active_connection AS connection/);
  assert.match(statement, /connection\.connection_key = job\.connection_key/);
  assert.match(statement, /connection\.user_id = job\.user_id/);
  assert.doesNotMatch(statement, /externalPublicationJob_upsert/);
  assert.equal(calls[0]?.variables.hasEncryptedSessionUrl, true);
  assert.equal(calls[0]?.variables.hasSessionExpiresAt, true);
  assert.equal(calls[0]?.variables.hasState, true);
  assert.equal(calls[0]?.variables.hasVideoId, false);
  assert.equal(calls[0]?.variables.hasFailureCode, false);
});

test("publication update fails closed after the ACTIVE connection is gone", async () => {
  const { dataConnect, calls } = dataConnectDouble([
    { data: { updated: null } },
  ]);
  const store = new DataConnectYouTubePublicationStore(dataConnect);

  await assert.rejects(
    store.update("user-1", "job-1", {
      state: "FAILED",
      failureCode: "provider_upload_failed",
      updatedAt: "2026-07-23T00:02:00.000Z",
    }),
    /does not exist or its YouTube connection is not active/,
  );

  assert.equal(calls.length, 1);
});

test("publication update rejects immutable-field changes before executing SQL", async () => {
  const { dataConnect, calls } = dataConnectDouble([]);
  const store = new DataConnectYouTubePublicationStore(dataConnect);

  await assert.rejects(
    store.update("user-1", "job-1", { title: "Changed title" }),
    /immutable fields: title/,
  );

  assert.equal(calls.length, 0);
});
