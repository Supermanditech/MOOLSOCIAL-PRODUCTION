import type { DataConnect } from "firebase-admin/data-connect";

export interface OAuthAttemptRecord {
  readonly stateHash: string;
  readonly userId: string;
  readonly encryptedCodeVerifier: string;
  readonly requestedScopes: readonly string[];
  readonly redirectUri: string;
  readonly createdAt: string;
  readonly expiresAt: string;
}

export interface OAuthAttemptStore {
  save(record: OAuthAttemptRecord): Promise<void>;
  consume(stateHash: string, userId: string): Promise<OAuthAttemptRecord | null>;
  consumeByState(stateHash: string): Promise<OAuthAttemptRecord | null>;
  deleteByUser(userId: string): Promise<void>;
}

interface OAuthAttemptRow {
  readonly state_hash?: string;
  readonly user_id?: string;
  readonly encrypted_code_verifier?: string;
  readonly requested_scopes_json?: string;
  readonly redirect_uri?: string;
  readonly created_at?: string;
  readonly expires_at?: string;
}

function parsedScopes(value: string | undefined): readonly string[] {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value) as unknown;
    return Array.isArray(parsed)
      ? parsed.filter(
          (scope): scope is string => typeof scope === "string",
        )
      : [];
  } catch {
    return [];
  }
}

export class DataConnectOAuthAttemptStore implements OAuthAttemptStore {
  constructor(private readonly dataConnect: DataConnect) {}

  async save(record: OAuthAttemptRecord): Promise<void> {
    await this.dataConnect.executeGraphql<
      unknown,
      {
        stateHash: string;
        userId: string;
        encryptedCodeVerifier: string;
        scopesJson: string;
        redirectUri: string;
        createdAt: string;
        expiresAt: string;
      }
    >(
      `mutation SaveYouTubeOAuthAttempt(
        $stateHash: String!
        $userId: String!
        $encryptedCodeVerifier: String!
        $scopesJson: String!
        $redirectUri: String!
        $createdAt: Timestamp!
        $expiresAt: Timestamp!
      ) {
        externalOAuthAttempt_upsert(data: {
          stateHash: $stateHash
          userId: $userId
          provider: YOUTUBE
          encryptedCodeVerifier: $encryptedCodeVerifier
          requestedScopesJson: $scopesJson
          redirectUri: $redirectUri
          createdAt: $createdAt
          expiresAt: $expiresAt
          consumedAt: null
        })
      }`,
      {
        variables: {
          stateHash: record.stateHash,
          userId: record.userId,
          encryptedCodeVerifier: record.encryptedCodeVerifier,
          scopesJson: JSON.stringify(record.requestedScopes),
          redirectUri: record.redirectUri,
          createdAt: record.createdAt,
          expiresAt: record.expiresAt,
        },
      },
    );
  }

  async consume(
    stateHash: string,
    userId: string,
  ): Promise<OAuthAttemptRecord | null> {
    const response = await this.dataConnect.executeGraphql<
      { readonly attempt?: OAuthAttemptRow | null },
      { stateHash: string; userId: string }
    >(
      `mutation ConsumeYouTubeOAuthAttempt(
        $stateHash: String!
        $userId: String!
      ) {
        attempt: _executeReturningFirst(
          sql: """
            UPDATE external_oauth_attempt
            SET consumed_at = NOW()
            WHERE
              state_hash = $1
              AND user_id = $2
              AND consumed_at IS NULL
              AND expires_at > NOW()
            RETURNING
              state_hash,
              user_id,
              encrypted_code_verifier,
              requested_scopes_json,
              redirect_uri,
              created_at,
              expires_at
          """
          params: [$stateHash, $userId]
        )
      }`,
      { variables: { stateHash, userId } },
    );
    return record(response.data.attempt);
  }

  async consumeByState(stateHash: string): Promise<OAuthAttemptRecord | null> {
    const response = await this.dataConnect.executeGraphql<
      { readonly attempt?: OAuthAttemptRow | null },
      { stateHash: string }
    >(
      `mutation ConsumeYouTubeOAuthAttemptByState($stateHash: String!) {
        attempt: _executeReturningFirst(
          sql: """
            UPDATE external_oauth_attempt
            SET consumed_at = NOW()
            WHERE
              state_hash = $1
              AND consumed_at IS NULL
              AND expires_at > NOW()
            RETURNING
              state_hash,
              user_id,
              encrypted_code_verifier,
              requested_scopes_json,
              redirect_uri,
              created_at,
              expires_at
          """
          params: [$stateHash]
        )
      }`,
      { variables: { stateHash } },
    );
    return record(response.data.attempt);
  }

  async deleteByUser(userId: string): Promise<void> {
    await this.dataConnect.executeGraphql<unknown, { userId: string }>(
      `mutation DeleteYouTubeOAuthAttempts($userId: String!) {
        _execute(
          sql: """
            DELETE FROM external_oauth_attempt
            WHERE user_id = $1 AND provider = 'YOUTUBE'
          """
          params: [$userId]
        )
      }`,
      { variables: { userId } },
    );
  }
}

function record(row: OAuthAttemptRow | null | undefined): OAuthAttemptRecord | null {
    if (
      !row?.state_hash ||
      !row.user_id ||
      !row.encrypted_code_verifier ||
      !row.redirect_uri ||
      !row.created_at ||
      !row.expires_at
    ) {
      return null;
    }
    return {
      stateHash: row.state_hash,
      userId: row.user_id,
      encryptedCodeVerifier: row.encrypted_code_verifier,
      requestedScopes: parsedScopes(row.requested_scopes_json),
      redirectUri: row.redirect_uri,
      createdAt: row.created_at,
      expiresAt: row.expires_at,
    };
}
