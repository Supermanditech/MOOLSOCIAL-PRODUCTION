import {
  createCipheriv,
  createDecipheriv,
  randomBytes,
} from "node:crypto";

const ENVELOPE_PREFIX = "mstv1";
const AES_GCM_NONCE_BYTES = 12;
const AES_GCM_TAG_BYTES = 16;
const REFRESH_TOKEN_PURPOSE = "youtube-refresh-token";

export interface EncryptedRefreshTokenRecord {
  readonly connectionKey: string;
  readonly encryptedRefreshToken: string;
  readonly grantedScopes: readonly string[];
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface EncryptedRefreshTokenPersistence {
  get(connectionKey: string): Promise<EncryptedRefreshTokenRecord | undefined>;
  put(record: EncryptedRefreshTokenRecord): Promise<void>;
  /**
   * Atomically replaces a credential only when the persisted ciphertext still
   * matches the value that was opened. Rotation migration must never overwrite
   * a refresh token concurrently replaced by a new OAuth grant.
   */
  replaceIfCurrent?(
    expectedEncryptedRefreshToken: string,
    replacement: EncryptedRefreshTokenRecord,
  ): Promise<boolean>;
  delete(connectionKey: string): Promise<void>;
}

export interface RefreshTokenMaterial {
  readonly refreshToken: string;
  readonly grantedScopes: readonly string[];
}

export interface AccessTokenMaterial {
  readonly accessToken: string;
  readonly expiresAtEpochMs: number;
  readonly grantedScopes: readonly string[];
}

export class TokenVaultError extends Error {
  constructor(
    readonly code:
      | "invalid_key"
      | "invalid_input"
      | "unsupported_envelope"
      | "decryption_failed"
      | "migration_failed",
    message: string,
  ) {
    super(message);
    this.name = "TokenVaultError";
  }
}

function assertNonEmpty(value: string, field: string): void {
  if (value.trim().length === 0) {
    throw new TokenVaultError("invalid_input", `${field} is required.`);
  }
}

function uniqueScopes(scopes: readonly string[]): readonly string[] {
  const unique = new Set<string>();
  for (const scope of scopes) {
    const normalized = scope.trim();
    if (normalized.length > 0) {
      unique.add(normalized);
    }
  }
  return [...unique].sort();
}

function additionalAuthenticatedData(
  keyVersion: string,
  purpose: string,
  context: string,
): Buffer {
  return Buffer.from(
    `${ENVELOPE_PREFIX}:${keyVersion}:${purpose}:${context}`,
    "utf8",
  );
}

function envelopeKeyVersion(envelope: string): string {
  const parts = envelope.split(".");
  const keyVersion = parts[1];
  if (
    parts.length !== 5 ||
    parts[0] !== ENVELOPE_PREFIX ||
    keyVersion === undefined ||
    !/^[A-Za-z0-9_-]{1,64}$/.test(keyVersion)
  ) {
    throw new TokenVaultError(
      "unsupported_envelope",
      "The encrypted credential envelope is unsupported.",
    );
  }
  return keyVersion;
}

/**
 * AES-256-GCM envelope encryption for small provider credentials.
 *
 * Format: mstv1.<keyVersion>.<nonce>.<ciphertext>.<authenticationTag>
 *
 * keyVersion identifies the configured server-side key used for rotation; the
 * key itself is never serialized. The context is authenticated but not stored,
 * binding a ciphertext to its connection record.
 */
export class Aes256GcmEnvelopeCipher {
  readonly #key: Buffer;

  constructor(
    key: Uint8Array,
    readonly keyVersion = "k1",
    readonly purpose = REFRESH_TOKEN_PURPOSE,
  ) {
    if (key.byteLength !== 32) {
      throw new TokenVaultError(
        "invalid_key",
        "AES-256-GCM requires a 32-byte key.",
      );
    }
    if (!/^[A-Za-z0-9_-]{1,64}$/.test(keyVersion)) {
      throw new TokenVaultError(
        "invalid_key",
        "keyVersion contains unsupported characters.",
      );
    }
    if (!/^[A-Za-z0-9_-]{1,64}$/.test(purpose)) {
      throw new TokenVaultError(
        "invalid_key",
        "purpose contains unsupported characters.",
      );
    }
    this.#key = Buffer.from(key);
  }

  encrypt(plaintextValue: string, context: string): string {
    assertNonEmpty(plaintextValue, "plaintextValue");
    assertNonEmpty(context, "context");

    const nonce = randomBytes(AES_GCM_NONCE_BYTES);
    const cipher = createCipheriv("aes-256-gcm", this.#key, nonce, {
      authTagLength: AES_GCM_TAG_BYTES,
    });
    cipher.setAAD(
      additionalAuthenticatedData(this.keyVersion, this.purpose, context),
    );

    const plaintext = Buffer.from(plaintextValue, "utf8");
    try {
      const ciphertext = Buffer.concat([
        cipher.update(plaintext),
        cipher.final(),
      ]);
      const authenticationTag = cipher.getAuthTag();
      return [
        ENVELOPE_PREFIX,
        this.keyVersion,
        nonce.toString("base64url"),
        ciphertext.toString("base64url"),
        authenticationTag.toString("base64url"),
      ].join(".");
    } finally {
      plaintext.fill(0);
    }
  }

  decrypt(envelope: string, context: string): string {
    assertNonEmpty(envelope, "envelope");
    assertNonEmpty(context, "context");

    const parts = envelope.split(".");
    if (
      parts.length !== 5 ||
      parts[0] !== ENVELOPE_PREFIX ||
      parts[1] !== this.keyVersion
    ) {
      throw new TokenVaultError(
        "unsupported_envelope",
        "The encrypted credential envelope is unsupported.",
      );
    }

    const noncePart = parts[2];
    const ciphertextPart = parts[3];
    const authenticationTagPart = parts[4];
    if (
      noncePart === undefined ||
      ciphertextPart === undefined ||
      authenticationTagPart === undefined
    ) {
      throw new TokenVaultError(
        "unsupported_envelope",
        "The encrypted credential envelope is unsupported.",
      );
    }

    try {
      const nonce = Buffer.from(noncePart, "base64url");
      const ciphertext = Buffer.from(ciphertextPart, "base64url");
      const authenticationTag = Buffer.from(
        authenticationTagPart,
        "base64url",
      );
      if (
        nonce.byteLength !== AES_GCM_NONCE_BYTES ||
        ciphertext.byteLength === 0 ||
        authenticationTag.byteLength !== AES_GCM_TAG_BYTES
      ) {
        throw new Error("Invalid envelope dimensions.");
      }

      const decipher = createDecipheriv("aes-256-gcm", this.#key, nonce, {
        authTagLength: AES_GCM_TAG_BYTES,
      });
      decipher.setAAD(
        additionalAuthenticatedData(
          this.keyVersion,
          this.purpose,
          context,
        ),
      );
      decipher.setAuthTag(authenticationTag);
      const plaintext = Buffer.concat([
        decipher.update(ciphertext),
        decipher.final(),
      ]);
      try {
        return plaintext.toString("utf8");
      } finally {
        plaintext.fill(0);
      }
    } catch {
      throw new TokenVaultError(
        "decryption_failed",
        "The encrypted provider credential could not be opened.",
      );
    }
  }
}

export interface OpenedEnvelope {
  readonly plaintextValue: string;
  readonly keyVersion: string;
  readonly requiresMigration: boolean;
}

/**
 * A two-key rotation boundary.
 *
 * New writes always use writeCipher. A single previousReadCipher may open an
 * envelope only when its embedded key version matches exactly. Keys are never
 * tried speculatively, and unknown versions fail closed.
 */
export class Aes256GcmEnvelopeKeyring {
  constructor(
    readonly writeCipher: Aes256GcmEnvelopeCipher,
    readonly previousReadCipher?: Aes256GcmEnvelopeCipher,
  ) {
    if (
      previousReadCipher !== undefined &&
      previousReadCipher.keyVersion === writeCipher.keyVersion
    ) {
      throw new TokenVaultError(
        "invalid_key",
        "Rotation keys must have distinct key versions.",
      );
    }
    if (
      previousReadCipher !== undefined &&
      previousReadCipher.purpose !== writeCipher.purpose
    ) {
      throw new TokenVaultError(
        "invalid_key",
        "Rotation keys must use the same credential purpose.",
      );
    }
  }

  encrypt(plaintextValue: string, context: string): string {
    return this.writeCipher.encrypt(plaintextValue, context);
  }

  open(envelope: string, context: string): OpenedEnvelope {
    assertNonEmpty(envelope, "envelope");
    assertNonEmpty(context, "context");
    const keyVersion = envelopeKeyVersion(envelope);
    const selected =
      keyVersion === this.writeCipher.keyVersion
        ? this.writeCipher
        : keyVersion === this.previousReadCipher?.keyVersion
          ? this.previousReadCipher
          : undefined;
    if (selected === undefined) {
      throw new TokenVaultError(
        "unsupported_envelope",
        "The encrypted credential envelope is unsupported.",
      );
    }
    return {
      plaintextValue: selected.decrypt(envelope, context),
      keyVersion,
      requiresMigration: selected !== this.writeCipher,
    };
  }
}

/**
 * Persists refresh tokens only after authenticated encryption. The persistence
 * adapter receives ciphertext and metadata, never plaintext credentials.
 */
export class RefreshTokenVault {
  readonly keyring: Aes256GcmEnvelopeKeyring;

  constructor(
    cipherOrKeyring:
      | Aes256GcmEnvelopeCipher
      | Aes256GcmEnvelopeKeyring,
    readonly persistence: EncryptedRefreshTokenPersistence,
    readonly now: () => Date = () => new Date(),
  ) {
    this.keyring =
      cipherOrKeyring instanceof Aes256GcmEnvelopeKeyring
        ? cipherOrKeyring
        : new Aes256GcmEnvelopeKeyring(cipherOrKeyring);
  }

  async save(
    connectionKey: string,
    refreshToken: string,
    grantedScopes: readonly string[],
  ): Promise<void> {
    assertNonEmpty(connectionKey, "connectionKey");
    assertNonEmpty(refreshToken, "refreshToken");

    const existing = await this.persistence.get(connectionKey);
    const timestamp = this.now().toISOString();
    const encryptedRefreshToken = this.keyring.encrypt(
      refreshToken,
      connectionKey,
    );
    await this.persistence.put({
      connectionKey,
      encryptedRefreshToken,
      grantedScopes: uniqueScopes(grantedScopes),
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
    });
  }

  async load(
    connectionKey: string,
  ): Promise<RefreshTokenMaterial | undefined> {
    assertNonEmpty(connectionKey, "connectionKey");
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const record = await this.persistence.get(connectionKey);
      if (record === undefined) {
        return undefined;
      }
      if (record.connectionKey !== connectionKey) {
        throw new TokenVaultError(
          "decryption_failed",
          "The encrypted provider credential could not be opened.",
        );
      }
      const opened = this.keyring.open(
        record.encryptedRefreshToken,
        connectionKey,
      );
      if (!opened.requiresMigration) {
        return {
          refreshToken: opened.plaintextValue,
          grantedScopes: [...record.grantedScopes],
        };
      }

      const replaceIfCurrent = this.persistence.replaceIfCurrent;
      if (replaceIfCurrent === undefined) {
        throw new TokenVaultError(
          "migration_failed",
          "The encrypted provider credential requires an atomic key migration.",
        );
      }
      const migrated = await replaceIfCurrent.call(
        this.persistence,
        record.encryptedRefreshToken,
        {
          ...record,
          encryptedRefreshToken: this.keyring.encrypt(
            opened.plaintextValue,
            connectionKey,
          ),
          grantedScopes: uniqueScopes(record.grantedScopes),
          updatedAt: this.now().toISOString(),
        },
      );
      if (migrated) {
        return {
          refreshToken: opened.plaintextValue,
          grantedScopes: [...record.grantedScopes],
        };
      }
    }
    throw new TokenVaultError(
      "migration_failed",
      "The encrypted provider credential changed during key migration.",
    );
  }

  async delete(connectionKey: string): Promise<void> {
    assertNonEmpty(connectionKey, "connectionKey");
    await this.persistence.delete(connectionKey);
  }
}

/**
 * Short-lived access tokens are process-memory only. Expired entries are
 * removed on read and there is intentionally no persistence adapter.
 */
export class InMemoryAccessTokenCache {
  readonly #entries = new Map<string, AccessTokenMaterial>();

  constructor(readonly nowEpochMs: () => number = () => Date.now()) {}

  set(connectionKey: string, material: AccessTokenMaterial): void {
    assertNonEmpty(connectionKey, "connectionKey");
    assertNonEmpty(material.accessToken, "accessToken");
    if (
      !Number.isFinite(material.expiresAtEpochMs) ||
      material.expiresAtEpochMs <= this.nowEpochMs()
    ) {
      throw new TokenVaultError(
        "invalid_input",
        "Access-token expiry must be in the future.",
      );
    }
    this.#entries.set(connectionKey, {
      accessToken: material.accessToken,
      expiresAtEpochMs: material.expiresAtEpochMs,
      grantedScopes: uniqueScopes(material.grantedScopes),
    });
  }

  get(
    connectionKey: string,
    minimumValidityMs = 30_000,
  ): AccessTokenMaterial | undefined {
    assertNonEmpty(connectionKey, "connectionKey");
    if (!Number.isFinite(minimumValidityMs) || minimumValidityMs < 0) {
      throw new TokenVaultError(
        "invalid_input",
        "minimumValidityMs must be non-negative.",
      );
    }
    const material = this.#entries.get(connectionKey);
    if (material === undefined) {
      return undefined;
    }
    if (
      material.expiresAtEpochMs - this.nowEpochMs() <= minimumValidityMs
    ) {
      this.#entries.delete(connectionKey);
      return undefined;
    }
    return {
      accessToken: material.accessToken,
      expiresAtEpochMs: material.expiresAtEpochMs,
      grantedScopes: [...material.grantedScopes],
    };
  }

  delete(connectionKey: string): void {
    this.#entries.delete(connectionKey);
  }

  clear(): void {
    this.#entries.clear();
  }
}
