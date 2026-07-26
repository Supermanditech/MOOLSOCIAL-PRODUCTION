import type { DataConnect } from "firebase-admin/data-connect";

import type {
  YouTubeConnectionStore,
  YouTubePublicationStore,
} from "./ports.js";
import type {
  YouTubeProviderConnectionRecord,
  YouTubePublicationJobRecord,
} from "./types.js";
import type {
  EncryptedRefreshTokenPersistence,
  EncryptedRefreshTokenRecord,
} from "./token_vault.js";
import type {
  YouTubeQuotaReserveRequest,
  YouTubeQuotaReserveResult,
  YouTubeQuotaStore,
} from "./quota.js";

interface ConnectionGraphql {
  readonly externalProviderConnections?: readonly {
    readonly connectionKey: string;
    readonly userId: string;
    readonly channelId: string;
    readonly channelTitle: string;
    readonly grantedScopesJson: string;
    readonly connectedAt: string;
    readonly lastVerifiedAt: string;
    readonly status:
      | "ACTIVE"
      | "REVOKED"
      | "DELETION_PENDING"
      | "DELETED";
  }[];
}

interface PublicationGraphql {
  readonly externalPublicationJobs?: readonly {
    readonly jobKey: string;
    readonly userId: string;
    readonly connectionKey: string;
    readonly idempotencyKey: string;
    readonly requestFingerprint: string;
    readonly title: string;
    readonly privacyStatus: string;
    readonly contentLength: string;
    readonly encryptedSessionUrl: string;
    readonly sessionExpiresAt?: string | null;
    readonly state:
      | "SESSION_CREATING"
      | "SESSION_READY"
      | "UPLOADING"
      | "PROCESSING"
      | "COMPLETE"
      | "FAILED"
      | "CANCELLED";
    readonly createdAt: string;
    readonly updatedAt: string;
    readonly videoId?: string | null;
    readonly failureCode?: string | null;
  }[];
}

interface CredentialGraphql {
  readonly externalProviderCredential?: {
    readonly connectionKey: string;
    readonly encryptedRefreshToken: string;
    readonly grantedScopesJson: string;
    readonly createdAt: string;
    readonly updatedAt: string;
  } | null;
}

function scopes(value: string): readonly string[] {
  try {
    const parsed = JSON.parse(value) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(
      (item): item is string => typeof item === "string",
    );
  } catch {
    return [];
  }
}

function connection(
  item: NonNullable<ConnectionGraphql["externalProviderConnections"]>[number],
): YouTubeProviderConnectionRecord {
  return {
    connectionKey: item.connectionKey,
    userId: item.userId,
    channelId: item.channelId,
    channelTitle: item.channelTitle,
    grantedScopes: scopes(item.grantedScopesJson),
    connectedAt: item.connectedAt,
    lastVerifiedAt: item.lastVerifiedAt,
    status: item.status,
  };
}

function publication(
  item: NonNullable<PublicationGraphql["externalPublicationJobs"]>[number],
): YouTubePublicationJobRecord {
  if (item.privacyStatus !== "private") {
    throw new Error("Provider store returned a non-private Dev upload.");
  }
  const contentLength = Number(item.contentLength);
  if (!Number.isSafeInteger(contentLength) || contentLength < 1) {
    throw new Error("Provider store returned an invalid upload size.");
  }
  return {
    jobKey: item.jobKey,
    userId: item.userId,
    connectionKey: item.connectionKey,
    idempotencyKey: item.idempotencyKey,
    requestFingerprint: item.requestFingerprint,
    title: item.title,
    privacyStatus: "private",
    contentLength,
    encryptedSessionUrl: item.encryptedSessionUrl,
    ...(item.sessionExpiresAt
      ? { sessionExpiresAt: item.sessionExpiresAt }
      : {}),
    state: item.state,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
    ...(item.videoId ? { videoId: item.videoId } : {}),
    ...(item.failureCode ? { failureCode: item.failureCode } : {}),
  };
}

export class DataConnectYouTubeConnectionStore
  implements YouTubeConnectionStore
{
  constructor(private readonly dataConnect: DataConnect) {}

  async getByUser(
    userId: string,
  ): Promise<YouTubeProviderConnectionRecord | null> {
    const response =
      await this.dataConnect.executeGraphqlRead<
        ConnectionGraphql,
        { userId: string }
      >(
        `query ActiveYouTubeConnection($userId: String!) {
          externalProviderConnections(
            where: {
              userId: {eq: $userId}
              provider: {eq: YOUTUBE}
              status: {eq: ACTIVE}
            }
            limit: 1
          ) {
            connectionKey
            userId
            channelId
            channelTitle
            grantedScopesJson
            connectedAt
            lastVerifiedAt
            status
          }
        }`,
        { variables: { userId } },
      );
    const item = response.data.externalProviderConnections?.[0];
    return item ? connection(item) : null;
  }

  async save(record: YouTubeProviderConnectionRecord): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      {
        connectionKey: string;
        userId: string;
        channelId: string;
        channelTitle: string;
        scopesJson: string;
        status: string;
        connectedAt: string;
        lastVerifiedAt: string;
      }
    >(
      `mutation SaveYouTubeConnection(
        $connectionKey: String!
        $userId: String!
        $channelId: String!
        $channelTitle: String!
        $scopesJson: String!
        $status: ExternalProviderConnectionStatus!
        $connectedAt: Timestamp!
        $lastVerifiedAt: Timestamp!
      ) {
        externalProviderConnection_upsert(data: {
          connectionKey: $connectionKey
          userId: $userId
          provider: YOUTUBE
          channelId: $channelId
          channelTitle: $channelTitle
          grantedScopesJson: $scopesJson
          status: $status
          connectedAt: $connectedAt
          lastVerifiedAt: $lastVerifiedAt
        })
      }`,
      {
        variables: {
          connectionKey: record.connectionKey,
          userId: record.userId,
          channelId: record.channelId,
          channelTitle: record.channelTitle,
          scopesJson: JSON.stringify(record.grantedScopes),
          status: record.status,
          connectedAt: record.connectedAt,
          lastVerifiedAt: record.lastVerifiedAt,
        },
      },
    );
  }

  async markRevoked(connectionKey: string, revokedAt: string): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      {
        connectionKey: string;
        revokedAt: string;
        deletionDueAt: string;
      }
    >(
      `mutation RevokeYouTubeConnection(
        $connectionKey: String!
        $revokedAt: Timestamp!
        $deletionDueAt: Timestamp!
      ) {
        externalProviderConnection_update(
          key: {connectionKey: $connectionKey}
          data: {
            status: REVOKED
            revokedAt: $revokedAt
            deletionDueAt: $deletionDueAt
          }
        )
      }`,
      {
        variables: {
          connectionKey,
          revokedAt,
          deletionDueAt: new Date(
            new Date(revokedAt).getTime() + 7 * 24 * 60 * 60 * 1000,
          ).toISOString(),
        },
      },
    );
  }

  async delete(connectionKey: string): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      { connectionKey: string }
    >(
      `mutation DeleteYouTubeConnection($connectionKey: String!) {
        externalProviderConnection_delete(
          key: {connectionKey: $connectionKey}
        )
      }`,
      { variables: { connectionKey } },
    );
  }
}

export class DataConnectRefreshTokenPersistence
  implements EncryptedRefreshTokenPersistence
{
  constructor(private readonly dataConnect: DataConnect) {}

  async get(
    connectionKey: string,
  ): Promise<EncryptedRefreshTokenRecord | undefined> {
    const response =
      await this.dataConnect.executeGraphqlRead<
        CredentialGraphql,
        { connectionKey: string }
      >(
        `query YouTubeCredential($connectionKey: String!) {
          externalProviderCredential(key: {connectionKey: $connectionKey}) {
            connectionKey
            encryptedRefreshToken
            grantedScopesJson
            createdAt
            updatedAt
          }
        }`,
        { variables: { connectionKey } },
      );
    const value = response.data.externalProviderCredential;
    if (!value) return undefined;
    return {
      connectionKey: value.connectionKey,
      encryptedRefreshToken: value.encryptedRefreshToken,
      grantedScopes: scopes(value.grantedScopesJson),
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    };
  }

  async put(record: EncryptedRefreshTokenRecord): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      {
        connectionKey: string;
        encryptedRefreshToken: string;
        scopesJson: string;
        createdAt: string;
        updatedAt: string;
      }
    >(
      `mutation SaveYouTubeCredential(
        $connectionKey: String!
        $encryptedRefreshToken: String!
        $scopesJson: String!
        $createdAt: Timestamp!
        $updatedAt: Timestamp!
      ) {
        externalProviderCredential_upsert(data: {
          connectionKey: $connectionKey
          encryptedRefreshToken: $encryptedRefreshToken
          grantedScopesJson: $scopesJson
          createdAt: $createdAt
          updatedAt: $updatedAt
        })
      }`,
      {
        variables: {
          connectionKey: record.connectionKey,
          encryptedRefreshToken: record.encryptedRefreshToken,
          scopesJson: JSON.stringify(record.grantedScopes),
          createdAt: record.createdAt,
          updatedAt: record.updatedAt,
        },
      },
    );
  }

  async replaceIfCurrent(
    expectedEncryptedRefreshToken: string,
    replacement: EncryptedRefreshTokenRecord,
  ): Promise<boolean> {
    const response = await this.dataConnect.executeGraphql<
      {
        readonly migrated?: {
          readonly connection_key: string;
        } | null;
      },
      {
        connectionKey: string;
        expectedEncryptedRefreshToken: string;
        encryptedRefreshToken: string;
        scopesJson: string;
        updatedAt: string;
      }
    >(
      `mutation MigrateYouTubeCredentialEncryption(
        $connectionKey: String!
        $expectedEncryptedRefreshToken: String!
        $encryptedRefreshToken: String!
        $scopesJson: String!
        $updatedAt: Timestamp!
      ) {
        migrated: _executeReturningFirst(
          sql: """
            UPDATE external_provider_credential
            SET
              encrypted_refresh_token = $3,
              granted_scopes_json = $4,
              updated_at = $5
            WHERE
              connection_key = $1
              AND encrypted_refresh_token = $2
            RETURNING connection_key
          """
          params: [
            $connectionKey
            $expectedEncryptedRefreshToken
            $encryptedRefreshToken
            $scopesJson
            $updatedAt
          ]
        )
      }`,
      {
        variables: {
          connectionKey: replacement.connectionKey,
          expectedEncryptedRefreshToken,
          encryptedRefreshToken: replacement.encryptedRefreshToken,
          scopesJson: JSON.stringify(replacement.grantedScopes),
          updatedAt: replacement.updatedAt,
        },
      },
    );
    return response.data.migrated?.connection_key === replacement.connectionKey;
  }

  async delete(connectionKey: string): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      { connectionKey: string }
    >(
      `mutation DeleteYouTubeCredential($connectionKey: String!) {
        externalProviderCredential_delete(
          key: {connectionKey: $connectionKey}
        )
      }`,
      { variables: { connectionKey } },
    );
  }
}

export class DataConnectYouTubePublicationStore
  implements YouTubePublicationStore
{
  constructor(private readonly dataConnect: DataConnect) {}

  async reserve(
    record: YouTubePublicationJobRecord,
  ): Promise<{
    readonly created: boolean;
    readonly record: YouTubePublicationJobRecord;
  }> {
    if (
      record.state !== "SESSION_CREATING" ||
      record.encryptedSessionUrl !== ""
    ) {
      throw new Error("A publication reservation must not contain a session.");
    }
    const response = await this.dataConnect.executeGraphql<
      { readonly reservation?: { readonly job_key?: string } | null },
      {
        jobKey: string;
        userId: string;
        connectionKey: string;
        idempotencyKey: string;
        requestFingerprint: string;
        title: string;
        contentLength: string;
        createdAt: string;
        updatedAt: string;
      }
    >(
      `mutation ReserveYouTubePublication(
        $jobKey: String!
        $userId: String!
        $connectionKey: String!
        $idempotencyKey: String!
        $requestFingerprint: String!
        $title: String!
        $contentLength: String!
        $createdAt: Timestamp!
        $updatedAt: Timestamp!
      ) {
        reservation: _executeReturningFirst(
          sql: """
            WITH active_connection AS MATERIALIZED (
              SELECT connection.connection_key
              FROM external_provider_connection AS connection
              WHERE
                connection.connection_key = $3
                AND connection.user_id = $2
                AND connection.provider = 'YOUTUBE'
                AND connection.status = 'ACTIVE'
              FOR UPDATE
            )
            INSERT INTO external_publication_job (
              job_key,
              user_id,
              connection_key,
              provider,
              idempotency_key,
              request_fingerprint,
              title,
              privacy_status,
              content_length,
              encrypted_session_url,
              state,
              created_at,
              updated_at
            )
            SELECT
              $1,
              $2,
              $3,
              'YOUTUBE',
              $4,
              $5,
              $6,
              'private',
              $7,
              '',
              'SESSION_CREATING',
              $8,
              $9
            FROM active_connection
            ON CONFLICT (job_key) DO NOTHING
            RETURNING job_key
          """
          params: [
            $jobKey
            $userId
            $connectionKey
            $idempotencyKey
            $requestFingerprint
            $title
            $contentLength
            $createdAt
            $updatedAt
          ]
        )
      }`,
      {
        variables: {
          jobKey: record.jobKey,
          userId: record.userId,
          connectionKey: record.connectionKey,
          idempotencyKey: record.idempotencyKey,
          requestFingerprint: record.requestFingerprint,
          title: record.title,
          contentLength: String(record.contentLength),
          createdAt: record.createdAt,
          updatedAt: record.updatedAt,
        },
      },
    );
    if (response.data.reservation?.job_key === record.jobKey) {
      return { created: true, record };
    }
    const existing = await this.byKey(record.userId, record.jobKey);
    if (!existing || existing.idempotencyKey !== record.idempotencyKey) {
      throw new Error("Publication reservation could not be resolved.");
    }
    return { created: false, record: existing };
  }

  async getByKey(
    userId: string,
    jobKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    return this.byKey(userId, jobKey);
  }

  async getByIdempotencyKey(
    userId: string,
    idempotencyKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    const response =
      await this.dataConnect.executeGraphqlRead<
        PublicationGraphql,
        { userId: string; idempotencyKey: string }
      >(
        `query YouTubePublicationByIdempotency(
          $userId: String!
          $idempotencyKey: String!
        ) {
          externalPublicationJobs(
            where: {
              userId: {eq: $userId}
              idempotencyKey: {eq: $idempotencyKey}
              provider: {eq: YOUTUBE}
            }
            limit: 1
          ) {
            jobKey
            userId
            connectionKey
            idempotencyKey
            requestFingerprint
            title
            privacyStatus
            contentLength
            encryptedSessionUrl
            sessionExpiresAt
            state
            videoId
            failureCode
            createdAt
            updatedAt
          }
        }`,
        { variables: { userId, idempotencyKey } },
      );
    const value = response.data.externalPublicationJobs?.[0];
    return value ? publication(value) : null;
  }

  async update(
    userId: string,
    jobKey: string,
    patch: Partial<YouTubePublicationJobRecord>,
  ): Promise<void> {
    const allowed = new Set<keyof YouTubePublicationJobRecord>([
      "encryptedSessionUrl",
      "sessionExpiresAt",
      "state",
      "videoId",
      "failureCode",
      "updatedAt",
    ]);
    const unsupported = Object.keys(patch).filter(
      (key) => !allowed.has(key as keyof YouTubePublicationJobRecord),
    );
    if (unsupported.length > 0) {
      throw new Error(
        `Publication update contains immutable fields: ${unsupported.join(", ")}.`,
      );
    }
    const has = (key: keyof YouTubePublicationJobRecord): boolean =>
      Object.prototype.hasOwnProperty.call(patch, key);
    const response = await this.dataConnect.executeGraphql<
      { readonly updated?: { readonly job_key?: string } | null },
      {
        jobKey: string;
        userId: string;
        hasEncryptedSessionUrl: boolean;
        encryptedSessionUrl: string;
        hasSessionExpiresAt: boolean;
        sessionExpiresAt: string | null;
        hasState: boolean;
        state: string;
        hasVideoId: boolean;
        videoId: string | null;
        hasFailureCode: boolean;
        failureCode: string | null;
        hasUpdatedAt: boolean;
        updatedAt: string;
      }
    >(
      `mutation UpdateYouTubePublicationIfConnected(
        $jobKey: String!
        $userId: String!
        $hasEncryptedSessionUrl: Boolean!
        $encryptedSessionUrl: String!
        $hasSessionExpiresAt: Boolean!
        $sessionExpiresAt: Timestamp
        $hasState: Boolean!
        $state: String!
        $hasVideoId: Boolean!
        $videoId: String
        $hasFailureCode: Boolean!
        $failureCode: String
        $hasUpdatedAt: Boolean!
        $updatedAt: Timestamp!
      ) {
        updated: _executeReturningFirst(
          sql: """
            WITH active_connection AS MATERIALIZED (
              SELECT
                connection.connection_key,
                connection.user_id
              FROM external_provider_connection AS connection
              WHERE
                connection.user_id = $2
                AND connection.provider = 'YOUTUBE'
                AND connection.status = 'ACTIVE'
              FOR UPDATE
            )
            UPDATE external_publication_job AS job
            SET
              encrypted_session_url = CASE
                WHEN $3 THEN $4
                ELSE job.encrypted_session_url
              END,
              session_expires_at = CASE
                WHEN $5 THEN $6
                ELSE job.session_expires_at
              END,
              state = CASE
                WHEN $7 THEN $8
                ELSE job.state
              END,
              video_id = CASE
                WHEN $9 THEN $10
                ELSE job.video_id
              END,
              failure_code = CASE
                WHEN $11 THEN $12
                ELSE job.failure_code
              END,
              updated_at = CASE
                WHEN $13 THEN $14
                ELSE job.updated_at
              END
            FROM active_connection AS connection
            WHERE
              job.job_key = $1
              AND job.user_id = $2
              AND job.provider = 'YOUTUBE'
              AND connection.connection_key = job.connection_key
              AND connection.user_id = job.user_id
            RETURNING job.job_key
          """
          params: [
            $jobKey
            $userId
            $hasEncryptedSessionUrl
            $encryptedSessionUrl
            $hasSessionExpiresAt
            $sessionExpiresAt
            $hasState
            $state
            $hasVideoId
            $videoId
            $hasFailureCode
            $failureCode
            $hasUpdatedAt
            $updatedAt
          ]
        )
      }`,
      {
        variables: {
          jobKey,
          userId,
          hasEncryptedSessionUrl: has("encryptedSessionUrl"),
          encryptedSessionUrl: patch.encryptedSessionUrl ?? "",
          hasSessionExpiresAt: has("sessionExpiresAt"),
          sessionExpiresAt: patch.sessionExpiresAt ?? null,
          hasState: has("state"),
          state: patch.state ?? "SESSION_CREATING",
          hasVideoId: has("videoId"),
          videoId: patch.videoId ?? null,
          hasFailureCode: has("failureCode"),
          failureCode: patch.failureCode ?? null,
          hasUpdatedAt: has("updatedAt"),
          updatedAt: patch.updatedAt ?? new Date(0).toISOString(),
        },
      },
    );
    if (response.data.updated?.job_key !== jobKey) {
      throw new Error(
        "Publication job does not exist or its YouTube connection is not active.",
      );
    }
  }

  async deleteByUser(userId: string): Promise<void> {
    await this.dataConnect.executeGraphql<unknown, { userId: string }>(
      `mutation DeleteYouTubePublications($userId: String!) {
        _execute(
          sql: """
            DELETE FROM external_publication_job
            WHERE user_id = $1 AND provider = 'YOUTUBE'
          """
          params: [$userId]
        )
      }`,
      { variables: { userId } },
    );
  }

  private async byKey(
    userId: string,
    jobKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    const response =
      await this.dataConnect.executeGraphqlRead<
        PublicationGraphql,
        { jobKey: string; userId: string }
      >(
        `query YouTubePublicationByKey(
          $jobKey: String!
          $userId: String!
        ) {
          externalPublicationJobs(
            where: {
              jobKey: {eq: $jobKey}
              userId: {eq: $userId}
            }
            limit: 1
          ) {
            jobKey
            userId
            connectionKey
            idempotencyKey
            requestFingerprint
              title
              privacyStatus
              contentLength
              encryptedSessionUrl
              sessionExpiresAt
            state
            videoId
            failureCode
            createdAt
            updatedAt
          }
        }`,
        { variables: { jobKey, userId } },
      );
    const value = response.data.externalPublicationJobs?.[0];
    return value ? publication(value) : null;
  }

}

interface QuotaRow {
  readonly quota_key?: string;
  readonly bucket?: string;
  readonly window_id?: string;
  readonly used?: number;
  readonly hard_cap?: number;
  readonly reset_at?: string;
}

export class DataConnectYouTubeQuotaStore implements YouTubeQuotaStore {
  constructor(private readonly dataConnect: DataConnect) {}

  async reserve(
    request: YouTubeQuotaReserveRequest,
  ): Promise<YouTubeQuotaReserveResult> {
    const quotaKey = `youtube:${request.windowId}:${request.bucket}`;
    const response = await this.dataConnect.executeGraphql<
      { readonly reservation?: QuotaRow | null },
      {
        quotaKey: string;
        bucket: string;
        windowId: string;
        units: number;
        hardCap: number;
        resetAt: string;
      }
    >(
      `mutation ReserveYouTubeQuota(
        $quotaKey: String!
        $bucket: String!
        $windowId: String!
        $units: Int!
        $hardCap: Int!
        $resetAt: Timestamp!
      ) {
        reservation: _executeReturningFirst(
          sql: """
            INSERT INTO provider_quota_usage
              (quota_key, bucket, window_id, used, hard_cap, reset_at, updated_at)
            SELECT $1, $2, $3, $4, $5, $6, NOW()
            WHERE $4 <= $5
            ON CONFLICT (quota_key)
            DO UPDATE SET
              used = provider_quota_usage.used + EXCLUDED.used,
              hard_cap = EXCLUDED.hard_cap,
              reset_at = EXCLUDED.reset_at,
              updated_at = NOW()
            WHERE
              provider_quota_usage.window_id = EXCLUDED.window_id
              AND provider_quota_usage.used + EXCLUDED.used
                <= EXCLUDED.hard_cap
            RETURNING quota_key, bucket, window_id, used, hard_cap, reset_at
          """
          params: [
            $quotaKey
            $bucket
            $windowId
            $units
            $hardCap
            $resetAt
          ]
        )
      }`,
      {
        variables: {
          quotaKey,
          bucket: request.bucket,
          windowId: request.windowId,
          units: request.units,
          hardCap: request.limit,
          resetAt: request.resetAt,
        },
      },
    );
    const row = response.data.reservation;
    if (!row) {
      return {
        allowed: false,
        bucket: request.bucket,
        windowId: request.windowId,
        resetAt: request.resetAt,
        used: request.limit,
        remaining: 0,
        limit: request.limit,
      };
    }
    const used = Number(row.used ?? 0);
    return {
      allowed: true,
      bucket: request.bucket,
      windowId: request.windowId,
      resetAt: String(row.reset_at ?? request.resetAt),
      used,
      remaining: Math.max(0, request.limit - used),
      limit: request.limit,
    };
  }
}
