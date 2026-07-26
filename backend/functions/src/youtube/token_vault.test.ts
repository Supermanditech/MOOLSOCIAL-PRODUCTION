import assert from "node:assert/strict";
import test from "node:test";

import {
  Aes256GcmEnvelopeCipher,
  Aes256GcmEnvelopeKeyring,
  InMemoryAccessTokenCache,
  RefreshTokenVault,
  TokenVaultError,
  type EncryptedRefreshTokenPersistence,
  type EncryptedRefreshTokenRecord,
} from "./token_vault.js";

class MemoryEncryptedPersistence
  implements EncryptedRefreshTokenPersistence
{
  readonly records = new Map<string, EncryptedRefreshTokenRecord>();

  async get(
    connectionKey: string,
  ): Promise<EncryptedRefreshTokenRecord | undefined> {
    return this.records.get(connectionKey);
  }

  async put(record: EncryptedRefreshTokenRecord): Promise<void> {
    this.records.set(record.connectionKey, record);
  }

  async replaceIfCurrent(
    expectedEncryptedRefreshToken: string,
    replacement: EncryptedRefreshTokenRecord,
  ): Promise<boolean> {
    const current = this.records.get(replacement.connectionKey);
    if (
      current?.encryptedRefreshToken !== expectedEncryptedRefreshToken
    ) {
      return false;
    }
    this.records.set(replacement.connectionKey, replacement);
    return true;
  }

  async delete(connectionKey: string): Promise<void> {
    this.records.delete(connectionKey);
  }
}

test("AES-256-GCM envelope round-trips and is randomized", () => {
  const cipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x41),
    "dev-k1",
  );
  const first = cipher.encrypt("refresh-token-value", "connection-1");
  const second = cipher.encrypt("refresh-token-value", "connection-1");

  assert.match(first, /^mstv1\.dev-k1\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
  assert.notEqual(first, second);
  assert.equal(
    cipher.decrypt(first, "connection-1"),
    "refresh-token-value",
  );
  assert.doesNotMatch(first, /refresh-token-value/);
});

test("envelope authentication binds ciphertext to the connection", () => {
  const cipher = new Aes256GcmEnvelopeCipher(Buffer.alloc(32, 0x42));
  const envelope = cipher.encrypt("refresh-token-value", "connection-1");

  assert.throws(
    () => cipher.decrypt(envelope, "connection-2"),
    (error: unknown) => {
      assert.ok(error instanceof TokenVaultError);
      assert.equal(error.code, "decryption_failed");
      return true;
    },
  );
});

test("tampering and the wrong key fail closed", () => {
  const cipher = new Aes256GcmEnvelopeCipher(Buffer.alloc(32, 0x43));
  const wrongCipher = new Aes256GcmEnvelopeCipher(Buffer.alloc(32, 0x44));
  const envelope = cipher.encrypt("refresh-token-value", "connection-1");
  const parts = envelope.split(".");
  const ciphertext = parts[3];
  assert.ok(ciphertext !== undefined && ciphertext.length > 1);
  parts[3] = `${ciphertext[0] === "A" ? "B" : "A"}${ciphertext.slice(1)}`;

  assert.throws(
    () => cipher.decrypt(parts.join("."), "connection-1"),
    (error: unknown) =>
      error instanceof TokenVaultError &&
      error.code === "decryption_failed",
  );
  assert.throws(
    () => wrongCipher.decrypt(envelope, "connection-1"),
    (error: unknown) =>
      error instanceof TokenVaultError &&
      error.code === "decryption_failed",
  );
});

test("cipher rejects non-256-bit keys", () => {
  assert.throws(
    () => new Aes256GcmEnvelopeCipher(Buffer.alloc(31)),
    (error: unknown) =>
      error instanceof TokenVaultError && error.code === "invalid_key",
  );
});

test("refresh-token vault persists ciphertext and restores plaintext only on load", async () => {
  const persistence = new MemoryEncryptedPersistence();
  const cipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x45),
    "dev-k2",
  );
  const vault = new RefreshTokenVault(
    cipher,
    persistence,
    () => new Date("2026-07-23T12:00:00.000Z"),
  );

  await vault.save(
    "user-1:youtube-channel-1",
    "refresh-token-value",
    ["scope-upload", "scope-read", "scope-read"],
  );

  const stored = persistence.records.get("user-1:youtube-channel-1");
  assert.ok(stored !== undefined);
  assert.doesNotMatch(
    JSON.stringify(stored),
    /refresh-token-value/,
  );
  assert.match(stored.encryptedRefreshToken, /^mstv1\.dev-k2\./);
  assert.deepEqual(stored.grantedScopes, ["scope-read", "scope-upload"]);
  assert.equal(stored.createdAt, "2026-07-23T12:00:00.000Z");

  assert.deepEqual(
    await vault.load("user-1:youtube-channel-1"),
    {
      refreshToken: "refresh-token-value",
      grantedScopes: ["scope-read", "scope-upload"],
    },
  );

  await vault.delete("user-1:youtube-channel-1");
  assert.equal(await vault.load("user-1:youtube-channel-1"), undefined);
});

test("dual-key load migrates a previous envelope to the current write key", async () => {
  const connectionKey = "user-1:youtube-channel-1";
  const persistence = new MemoryEncryptedPersistence();
  const previousCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x46),
    "dev-k1",
  );
  const currentCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x47),
    "dev-k2",
  );
  const previousEnvelope = previousCipher.encrypt(
    "previous-key-refresh-token",
    connectionKey,
  );
  persistence.records.set(connectionKey, {
    connectionKey,
    encryptedRefreshToken: previousEnvelope,
    grantedScopes: ["scope-read"],
    createdAt: "2026-07-22T00:00:00.000Z",
    updatedAt: "2026-07-22T00:00:00.000Z",
  });
  const vault = new RefreshTokenVault(
    new Aes256GcmEnvelopeKeyring(currentCipher, previousCipher),
    persistence,
    () => new Date("2026-07-24T00:00:00.000Z"),
  );

  assert.deepEqual(await vault.load(connectionKey), {
    refreshToken: "previous-key-refresh-token",
    grantedScopes: ["scope-read"],
  });

  const migrated = persistence.records.get(connectionKey);
  assert.ok(migrated !== undefined);
  assert.match(migrated.encryptedRefreshToken, /^mstv1\.dev-k2\./);
  assert.notEqual(migrated.encryptedRefreshToken, previousEnvelope);
  assert.equal(migrated.createdAt, "2026-07-22T00:00:00.000Z");
  assert.equal(migrated.updatedAt, "2026-07-24T00:00:00.000Z");
  assert.equal(
    currentCipher.decrypt(migrated.encryptedRefreshToken, connectionKey),
    "previous-key-refresh-token",
  );

  await vault.save(connectionKey, "new-refresh-token", ["scope-upload"]);
  assert.match(
    persistence.records.get(connectionKey)?.encryptedRefreshToken ?? "",
    /^mstv1\.dev-k2\./,
  );
});

test("rotation migration never overwrites a concurrent credential replacement", async () => {
  const connectionKey = "user-1:youtube-channel-1";
  const previousCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x48),
    "dev-k1",
  );
  const currentCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x49),
    "dev-k2",
  );
  const previousEnvelope = previousCipher.encrypt(
    "stale-refresh-token",
    connectionKey,
  );
  const concurrentEnvelope = currentCipher.encrypt(
    "concurrent-refresh-token",
    connectionKey,
  );
  const records = new Map<string, EncryptedRefreshTokenRecord>([
    [
      connectionKey,
      {
        connectionKey,
        encryptedRefreshToken: previousEnvelope,
        grantedScopes: ["scope-read"],
        createdAt: "2026-07-22T00:00:00.000Z",
        updatedAt: "2026-07-22T00:00:00.000Z",
      },
    ],
  ]);
  const persistence: EncryptedRefreshTokenPersistence = {
    get: async (key) => records.get(key),
    put: async (record) => {
      records.set(record.connectionKey, record);
    },
    replaceIfCurrent: async (_expected, replacement) => {
      records.set(connectionKey, {
        ...replacement,
        encryptedRefreshToken: concurrentEnvelope,
        grantedScopes: ["scope-read", "scope-upload"],
        updatedAt: "2026-07-24T00:01:00.000Z",
      });
      return false;
    },
    delete: async (key) => {
      records.delete(key);
    },
  };
  const vault = new RefreshTokenVault(
    new Aes256GcmEnvelopeKeyring(currentCipher, previousCipher),
    persistence,
  );

  assert.deepEqual(await vault.load(connectionKey), {
    refreshToken: "concurrent-refresh-token",
    grantedScopes: ["scope-read", "scope-upload"],
  });
  assert.equal(
    records.get(connectionKey)?.encryptedRefreshToken,
    concurrentEnvelope,
  );
});

test("rotation fails closed for unknown versions and missing atomic migration", async () => {
  const connectionKey = "user-1:youtube-channel-1";
  const previousCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x4a),
    "dev-k1",
  );
  const currentCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x4b),
    "dev-k2",
  );
  const unknownCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x4c),
    "dev-k0",
  );
  const keyring = new Aes256GcmEnvelopeKeyring(
    currentCipher,
    previousCipher,
  );

  assert.throws(
    () =>
      keyring.open(
        unknownCipher.encrypt("refresh-token", connectionKey),
        connectionKey,
      ),
    (error: unknown) =>
      error instanceof TokenVaultError &&
      error.code === "unsupported_envelope",
  );

  const legacyRecord: EncryptedRefreshTokenRecord = {
    connectionKey,
    encryptedRefreshToken: previousCipher.encrypt(
      "refresh-token",
      connectionKey,
    ),
    grantedScopes: ["scope-read"],
    createdAt: "2026-07-22T00:00:00.000Z",
    updatedAt: "2026-07-22T00:00:00.000Z",
  };
  const persistenceWithoutCompareAndSwap: EncryptedRefreshTokenPersistence = {
    get: async () => legacyRecord,
    put: async () => undefined,
    delete: async () => undefined,
  };
  const vault = new RefreshTokenVault(
    keyring,
    persistenceWithoutCompareAndSwap,
  );
  await assert.rejects(
    vault.load(connectionKey),
    (error: unknown) =>
      error instanceof TokenVaultError &&
      error.code === "migration_failed",
  );
});

test("rotation keyring rejects ambiguous versions and mixed purposes", () => {
  const currentCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 0x4d),
    "dev-k2",
    "youtube-refresh-token",
  );
  assert.throws(
    () =>
      new Aes256GcmEnvelopeKeyring(
        currentCipher,
        new Aes256GcmEnvelopeCipher(
          Buffer.alloc(32, 0x4e),
          "dev-k2",
          "youtube-refresh-token",
        ),
      ),
    (error: unknown) =>
      error instanceof TokenVaultError && error.code === "invalid_key",
  );
  assert.throws(
    () =>
      new Aes256GcmEnvelopeKeyring(
        currentCipher,
        new Aes256GcmEnvelopeCipher(
          Buffer.alloc(32, 0x4f),
          "dev-k1",
          "youtube-upload-session",
        ),
      ),
    (error: unknown) =>
      error instanceof TokenVaultError && error.code === "invalid_key",
  );
});

test("access tokens expire from process memory and have no persistence path", () => {
  let now = 1_000_000;
  const cache = new InMemoryAccessTokenCache(() => now);
  cache.set("connection-1", {
    accessToken: "short-lived-access",
    expiresAtEpochMs: now + 120_000,
    grantedScopes: ["scope-read"],
  });

  assert.equal(cache.get("connection-1")?.accessToken, "short-lived-access");
  now += 100_000;
  assert.equal(cache.get("connection-1"), undefined);
  assert.equal(cache.get("connection-1", 0), undefined);
});
