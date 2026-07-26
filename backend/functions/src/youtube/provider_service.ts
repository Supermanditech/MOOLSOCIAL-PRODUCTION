import { createHash } from "node:crypto";

import {
  requireCapability,
  requireConnectPurposeCapability,
  requireOAuthAttemptCapability,
} from "./config.js";
import { YouTubeProviderError } from "./errors.js";
import {
  buildGoogleAuthorizationUrl,
  createOAuthState,
  createPkcePair,
  exchangeAuthorizationCode,
  GoogleOAuthProtocolError,
  refreshAccessToken,
  YOUTUBE_ANALYTICS_READONLY_SCOPE,
  YOUTUBE_FORCE_SSL_SCOPE,
  YOUTUBE_INCREMENTAL_SCOPE_SETS,
  YOUTUBE_MANAGE_SCOPE,
  YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE,
  YOUTUBE_READONLY_SCOPE,
  YOUTUBE_UPLOAD_SCOPE,
  type YouTubeIncrementalScope,
} from "./oauth.js";
import type {
  OAuthAttemptRecord,
  OAuthAttemptStore,
} from "./oauth_attempt_store.js";
import type {
  Clock,
  YouTubeConnectionStore,
  YouTubePublicationStore,
} from "./ports.js";
import { systemClock } from "./ports.js";
import type {
  PublicChannelPlaylistsQuery,
  PublicCommentRepliesQuery,
  YouTubeDataClient,
} from "./client.js";
import type {
  AnalyticsPresetQuery,
  YouTubeOwnerClient,
} from "./owner_client.js";
import type {
  CreatorChannelBrandingPatch,
  CreatorChannelSectionInput,
} from "./creator_assets_client.js";
import type {
  YouTubePublicChannelActivitiesPage,
  YouTubePublicChannelActivitiesQuery,
  YouTubePublicChannelSectionsResult,
  YouTubePublicDiscoveryClient,
} from "../youtube-private-dev/public-discovery/public_discovery_client.js";
import type {
  LiveBroadcastBindRequest,
  LiveBroadcastDeleteRequest,
  LiveBroadcastInsertRequest,
  LiveBroadcastListRequest,
  LiveBroadcastTransitionRequest,
  LiveBroadcastUpdateRequest,
  LiveChatBanDeleteRequest,
  LiveChatBanInsertRequest,
  LiveChatListRequest,
  LiveChatMessageDeleteRequest,
  LiveChatModeratorDeleteRequest,
  LiveChatModeratorInsertRequest,
  LiveChatPollCloseRequest,
  LiveChatPollInsertRequest,
  LiveChatTextInsertRequest,
  LiveListRequest,
  LiveMemberListRequest,
  LiveOwnerRequest,
  LiveStreamDeleteRequest,
  LiveStreamInsertRequest,
  LiveStreamUpdateRequest,
  LiveSuperChatListRequest,
} from "./live_client.js";
import {
  Aes256GcmEnvelopeCipher,
  InMemoryAccessTokenCache,
  RefreshTokenVault,
} from "./token_vault.js";
import {
  assertYouTubeUploadFileIdentityMatches,
  normalizeYouTubeUploadFileIdentity,
  youtubeUploadRequestFingerprint,
  type YouTubeUploadFileIdentityInput,
} from "./upload_identity.js";
import type {
  HttpTransport,
  YouTubeBatchStatisticsResult,
  YouTubeChannelIdentity,
  YouTubeOwnerAnalyticsResult,
  YouTubeOwnerPlaylistsPage,
  YouTubeOwnerSubscriptionsPage,
  YouTubeOwnerVideosPage,
  YouTubePage,
  YouTubeProviderConnectionRecord,
  YouTubeDisconnectResult,
  YouTubePublicationJobRecord,
  YouTubePublicChannelDetails,
  YouTubePublicCommentRepliesPage,
  YouTubePublicCommentThreadsPage,
  YouTubePublicLanguage,
  YouTubePublicPlaylistDetails,
  YouTubePublicRegion,
  YouTubePublicVideoCategory,
  YouTubeRuntimeCapabilities,
  YouTubeTokenResponse,
  YouTubeUploadMetadata,
  YouTubeVideoSummary,
} from "./types.js";

const GOOGLE_REVOKE_ENDPOINT = "https://oauth2.googleapis.com/revoke";
const OAUTH_ATTEMPT_TTL_MS = 10 * 60 * 1000;
const ACCESS_TOKEN_SAFETY_MS = 60 * 1000;
const UPLOAD_SESSION_CREATING_LEASE_MS = 2 * 60 * 1000;
const UPLOAD_SESSION_FALLBACK_TTL_MS = 24 * 60 * 60 * 1000;
const OWNER_CONNECTION_REVALIDATION_MS = 30 * 24 * 60 * 60 * 1000;
const UPLOAD_SESSION_CREATION_EXPIRED =
  "upload_session_creation_expired";
const UPLOAD_SESSION_EXPIRED = "upload_session_expired";

type LiveRequestInput<T extends LiveOwnerRequest> = Omit<
  T,
  keyof LiveOwnerRequest
>;

export interface YouTubeProviderServiceOptions {
  readonly capabilities: YouTubeRuntimeCapabilities;
  readonly dataClient: YouTubeDataClient;
  readonly publicDiscoveryClient?: Pick<
    YouTubePublicDiscoveryClient,
    "listChannelActivities" | "listChannelSections"
  >;
  readonly ownerClient: YouTubeOwnerClient;
  readonly transport: HttpTransport;
  readonly connections: YouTubeConnectionStore;
  readonly publications: YouTubePublicationStore;
  readonly oauthAttempts: OAuthAttemptStore;
  readonly refreshTokens: RefreshTokenVault;
  readonly accessTokens: InMemoryAccessTokenCache;
  readonly oauthVerifierCipher: Aes256GcmEnvelopeCipher;
  readonly uploadSessionCipher: Aes256GcmEnvelopeCipher;
  readonly oauthClientId: string;
  readonly oauthClientSecret: string;
  readonly oauthRedirectUri: string;
  readonly clock?: Clock;
}

export interface BeginYouTubeConnectRequest {
  readonly userId: string;
  readonly purpose: YouTubeIncrementalScope;
  readonly promptForConsent?: boolean;
}

export interface CompleteYouTubeConnectRequest {
  readonly userId: string;
  readonly state: string;
  readonly code: string;
}

export interface BeginYouTubeUploadRequest {
  readonly userId: string;
  readonly requestId: string;
  readonly idempotencyKey: string;
  readonly contentType: string;
  readonly contentLength: number;
  readonly fileIdentity: YouTubeUploadFileIdentityInput;
  readonly metadata: YouTubeUploadMetadata;
}

export interface BeginYouTubeUploadResult {
  readonly jobKey: string;
  readonly sessionUrl: string;
  readonly expiresAt: string;
  readonly privacyStatus: "private";
}

export interface YouTubeAnalyticsReportingOwnerAccess {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly owner: {
    readonly userId: string;
    readonly channelId: string;
    readonly status: "ACTIVE";
    readonly grantedScopes: readonly string[];
  };
}

function stableKey(prefix: string, ...parts: readonly string[]): string {
  return `${prefix}_${createHash("sha256")
    .update(parts.join("\u001f"), "utf8")
    .digest("base64url")}`;
}

function hashState(state: string): string {
  return createHash("sha256").update(state, "utf8").digest("base64url");
}

function timestamp(value: string | undefined): number | null {
  if (!value) return null;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function creatingLeaseExpired(
  job: YouTubePublicationJobRecord,
  now: Date,
): boolean {
  const updatedAt = timestamp(job.updatedAt);
  return (
    updatedAt === null ||
    updatedAt + UPLOAD_SESSION_CREATING_LEASE_MS <= now.getTime()
  );
}

function sessionExpiryEpochMs(
  job: YouTubePublicationJobRecord,
): number | null {
  const explicitExpiry = timestamp(job.sessionExpiresAt);
  if (explicitExpiry !== null) return explicitExpiry;
  const createdAt = timestamp(job.createdAt);
  return createdAt === null
    ? null
    : createdAt + UPLOAD_SESSION_FALLBACK_TTL_MS;
}

function readySessionExpired(
  job: YouTubePublicationJobRecord,
  now: Date,
): boolean {
  const expiresAt = sessionExpiryEpochMs(job);
  return expiresAt === null || expiresAt <= now.getTime();
}

function connectionNeedsRevalidation(
  connection: YouTubeProviderConnectionRecord,
  now: Date,
): boolean {
  const verifiedAt = timestamp(connection.lastVerifiedAt);
  return (
    verifiedAt === null ||
    verifiedAt + OWNER_CONNECTION_REVALIDATION_MS <= now.getTime()
  );
}

function connectionNextVerificationDueAt(
  connection: YouTubeProviderConnectionRecord,
): string | null {
  const verifiedAt = timestamp(connection.lastVerifiedAt);
  return verifiedAt === null
    ? null
    : new Date(verifiedAt + OWNER_CONNECTION_REVALIDATION_MS).toISOString();
}

function normalizeScopes(scopes: readonly string[]): readonly string[] {
  return [...new Set(scopes.map((scope) => scope.trim()).filter(Boolean))].sort();
}

function scopesForPurpose(
  purpose: YouTubeIncrementalScope,
): readonly string[] {
  return YOUTUBE_INCREMENTAL_SCOPE_SETS[purpose];
}

function tokenScopes(
  tokenScope: string | undefined,
  requestedScopes: readonly string[],
): readonly string[] {
  if (!tokenScope) return normalizeScopes(requestedScopes);
  return normalizeScopes(tokenScope.split(/\s+/u));
}

function includesScopes(
  granted: readonly string[],
  required: readonly string[],
): boolean {
  const set = new Set(granted);
  return required.every((scope) => set.has(scope));
}

function sameScopes(
  first: readonly string[],
  second: readonly string[],
): boolean {
  const normalizedFirst = normalizeScopes(first);
  const normalizedSecond = normalizeScopes(second);
  return (
    normalizedFirst.length === normalizedSecond.length &&
    normalizedFirst.every(
      (scope, index) => scope === normalizedSecond[index],
    )
  );
}

function validateIdentity(value: string, label: string): string {
  const clean = value.trim();
  if (!/^[A-Za-z0-9._:@/-]{1,180}$/.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      `A valid ${label} is required.`,
      400,
    );
  }
  return clean;
}

function validatedOAuthRedirectUri(value: string): string {
  let url: URL;
  try {
    url = new URL(value.trim());
  } catch {
    throw new Error("A valid Google OAuth redirect URI is required.");
  }
  const local =
    url.protocol === "http:" &&
    (url.hostname === "127.0.0.1" ||
      url.hostname === "localhost" ||
      url.hostname === "::1");
  if (
    (!local && url.protocol !== "https:") ||
    url.username ||
    url.password ||
    url.hash
  ) {
    throw new Error(
      "Google OAuth redirect URI must be HTTPS or a local proof callback.",
    );
  }
  return url.toString();
}

function statusForVideo(
  video: YouTubeVideoSummary,
): YouTubePublicationJobRecord["state"] {
  if (video.uploadStatus === "rejected" || video.uploadStatus === "failed") {
    return "FAILED";
  }
  if (video.uploadStatus === "processed") return "COMPLETE";
  return "PROCESSING";
}

function mapOAuthFailure(error: unknown): YouTubeProviderError {
  if (error instanceof YouTubeProviderError) return error;
  if (error instanceof GoogleOAuthProtocolError) {
    if (error.httpStatus === 400 || error.httpStatus === 401) {
      return new YouTubeProviderError(
        "authentication_required",
        "Reconnect the selected YouTube channel.",
        401,
      );
    }
    if (error.httpStatus === 429 || error.httpStatus >= 500) {
      return new YouTubeProviderError(
        "provider_unavailable",
        "YouTube is temporarily unavailable.",
        503,
        true,
      );
    }
    return new YouTubeProviderError(
      "provider_rejected",
      "YouTube could not complete the channel authorization.",
      502,
    );
  }
  return new YouTubeProviderError(
    "provider_unavailable",
    "YouTube is temporarily unavailable.",
    503,
    true,
  );
}

export class YouTubeProviderService {
  private readonly clock: Clock;

  constructor(private readonly options: YouTubeProviderServiceOptions) {
    this.clock = options.clock ?? systemClock;
    if (!options.oauthClientId.trim()) {
      throw new Error("A Google OAuth client identifier is required.");
    }
    if (!options.oauthClientSecret.trim()) {
      throw new Error("A Google OAuth client secret is required.");
    }
    validatedOAuthRedirectUri(options.oauthRedirectUri);
  }

  capabilities(): YouTubeRuntimeCapabilities {
    return this.options.capabilities;
  }

  async publicMostPopular(
    requestId: string,
    regionCode?: string,
    pageToken?: string,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.mostPopular("public", requestId, {
      ...(regionCode === undefined ? {} : { regionCode }),
      ...(pageToken === undefined ? {} : { pageToken }),
    });
  }

  async publicPlaylist(
    requestId: string,
    playlistId: string,
    pageToken?: string,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.playlistVideos(
      "public",
      requestId,
      playlistId,
      pageToken,
    );
  }

  async publicSearch(
    requestId: string,
    query: string,
    pageToken?: string,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.explicitSearch("public", requestId, {
      query,
      ...(pageToken === undefined ? {} : { pageToken }),
    });
  }

  async publicVideoDetails(
    requestId: string,
    videoIds: readonly string[],
  ): Promise<readonly YouTubeVideoSummary[]> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.videoDetails(
      "public",
      requestId,
      videoIds,
    );
  }

  async publicBatchVideoStatistics(
    requestId: string,
    videoIds: readonly string[],
  ): Promise<YouTubeBatchStatisticsResult> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.batchVideoStatistics(
      "public",
      requestId,
      videoIds,
    );
  }

  async publicChannelDetails(
    requestId: string,
    channelId: string,
  ): Promise<YouTubePublicChannelDetails> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicChannelDetails(
      "public",
      requestId,
      channelId,
    );
  }

  async publicChannelByHandle(
    requestId: string,
    handle: string,
  ): Promise<YouTubePublicChannelDetails> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicChannelByHandle(
      "public",
      requestId,
      handle,
    );
  }

  async publicPlaylistDetails(
    requestId: string,
    playlistId: string,
  ): Promise<YouTubePublicPlaylistDetails> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicPlaylistDetails(
      "public",
      requestId,
      playlistId,
    );
  }

  async publicChannelPlaylists(
    requestId: string,
    query: PublicChannelPlaylistsQuery,
  ): Promise<YouTubePage<YouTubePublicPlaylistDetails>> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicChannelPlaylists(
      "public",
      requestId,
      query,
    );
  }

  async publicRegions(
    requestId: string,
  ): Promise<readonly YouTubePublicRegion[]> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicRegions("public", requestId);
  }

  async publicLanguages(
    requestId: string,
  ): Promise<readonly YouTubePublicLanguage[]> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicLanguages("public", requestId);
  }

  async publicVideoCategories(
    requestId: string,
    regionCode?: string,
  ): Promise<readonly YouTubePublicVideoCategory[]> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicVideoCategories(
      "public",
      requestId,
      regionCode,
    );
  }

  async publicCommentThreads(
    requestId: string,
    query: {
      readonly videoId: string;
      readonly regionCode?: string;
      readonly pageToken?: string;
      readonly maxResults?: number;
      readonly order?: "time" | "relevance";
    },
  ): Promise<YouTubePublicCommentThreadsPage> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicCommentThreads(
      "public",
      requestId,
      query,
    );
  }

  async publicCommentReplies(
    requestId: string,
    query: PublicCommentRepliesQuery,
  ): Promise<YouTubePublicCommentRepliesPage> {
    requireCapability(this.options.capabilities, "publicData");
    return this.options.dataClient.publicCommentReplies(
      "public",
      requestId,
      query,
    );
  }

  async publicChannelActivities(
    requestId: string,
    query: YouTubePublicChannelActivitiesQuery,
  ): Promise<YouTubePublicChannelActivitiesPage> {
    requireCapability(this.options.capabilities, "publicData");
    return this.publicDiscoveryClient().listChannelActivities(
      "public",
      requestId,
      query,
    );
  }

  async publicChannelSections(
    requestId: string,
    channelId: string,
  ): Promise<YouTubePublicChannelSectionsResult> {
    requireCapability(this.options.capabilities, "publicData");
    return this.publicDiscoveryClient().listChannelSections(
      "public",
      requestId,
      channelId,
    );
  }

  async beginConnect(
    request: BeginYouTubeConnectRequest,
  ): Promise<{ readonly authorizationUrl: string; readonly expiresAt: string }> {
    requireConnectPurposeCapability(
      this.options.capabilities,
      request.purpose,
    );
    const userId = validateIdentity(request.userId, "user");
    const state = createOAuthState();
    const pair = createPkcePair();
    const stateHash = hashState(state);
    const context = `oauth:${stateHash}`;
    const now = this.clock.now();
    const expiresAt = new Date(
      now.getTime() + OAUTH_ATTEMPT_TTL_MS,
    ).toISOString();
    const requestedScopes = scopesForPurpose(request.purpose);
    await this.options.oauthAttempts.save({
      stateHash,
      userId,
      encryptedCodeVerifier: this.options.oauthVerifierCipher.encrypt(
        pair.codeVerifier,
        context,
      ),
      requestedScopes,
      redirectUri: this.options.oauthRedirectUri,
      createdAt: now.toISOString(),
      expiresAt,
    });
    return {
      authorizationUrl: buildGoogleAuthorizationUrl({
        clientId: this.options.oauthClientId,
        redirectUri: this.options.oauthRedirectUri,
        state,
        codeChallenge: pair.codeChallenge,
        scopes: requestedScopes,
        ...(request.promptForConsent === undefined
          ? {}
          : { promptForConsent: request.promptForConsent }),
      }),
      expiresAt,
    };
  }

  async completeConnect(
    request: CompleteYouTubeConnectRequest,
  ): Promise<YouTubeChannelIdentity> {
    const userId = validateIdentity(request.userId, "user");
    const { state, code } = this.oauthResponse(request.state, request.code);
    const stateHash = hashState(state);
    const attempt = await this.options.oauthAttempts.consume(
      stateHash,
      userId,
    );
    if (!attempt) {
      throw new YouTubeProviderError(
        "authentication_required",
        "The YouTube authorization has expired or was already used.",
        401,
      );
    }
    requireOAuthAttemptCapability(
      this.options.capabilities,
      attempt.requestedScopes,
    );
    return this.finishConnect(attempt, stateHash, code);
  }

  async completeConnectFromCallback(
    stateInput: string,
    codeInput: string,
  ): Promise<YouTubeChannelIdentity> {
    const { state, code } = this.oauthResponse(stateInput, codeInput);
    const stateHash = hashState(state);
    const attempt =
      await this.options.oauthAttempts.consumeByState(stateHash);
    if (!attempt) {
      throw new YouTubeProviderError(
        "authentication_required",
        "The YouTube authorization has expired or was already used.",
        401,
      );
    }
    requireOAuthAttemptCapability(
      this.options.capabilities,
      attempt.requestedScopes,
    );
    return this.finishConnect(attempt, stateHash, code);
  }

  private async finishConnect(
    attempt: OAuthAttemptRecord,
    stateHash: string,
    code: string,
  ): Promise<YouTubeChannelIdentity> {
    const codeVerifier = this.options.oauthVerifierCipher.decrypt(
      attempt.encryptedCodeVerifier,
      `oauth:${stateHash}`,
    );
    let token: YouTubeTokenResponse;
    try {
      token = await exchangeAuthorizationCode(this.options.transport, {
        clientId: this.options.oauthClientId,
        clientSecret: this.options.oauthClientSecret,
        redirectUri: attempt.redirectUri,
        code,
        codeVerifier,
      });
    } catch (error) {
      throw mapOAuthFailure(error);
    }
    const callbackGrantedScopes = tokenScopes(
      token.scope,
      attempt.requestedScopes,
    );
    if (!includesScopes(callbackGrantedScopes, attempt.requestedScopes)) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube did not grant every requested permission.",
        403,
      );
    }
    const channel = await this.options.dataClient.channel(
      attempt.userId,
      stableKey("req", attempt.userId, stateHash),
      "",
      token.access_token,
    );
    const connectionKey = stableKey("ytc", attempt.userId);
    const existingConnection =
      await this.options.connections.getByUser(attempt.userId);
    const existingToken =
      await this.options.refreshTokens.load(connectionKey);
    const reconnectingSameChannel =
      existingConnection?.channelId === channel.channelId;
    const providerOmittedScope = !token.scope?.trim();
    const effectiveGrantedScopes = normalizeScopes([
      ...callbackGrantedScopes,
      ...(reconnectingSameChannel && providerOmittedScope
        ? existingConnection.grantedScopes
        : []),
      ...(reconnectingSameChannel && providerOmittedScope
        ? existingToken?.grantedScopes ?? []
        : []),
    ]);
    let credentialChanged = false;
    if (token.refresh_token) {
      await this.options.refreshTokens.save(
        connectionKey,
        token.refresh_token,
        effectiveGrantedScopes,
      );
      credentialChanged = true;
    } else if (!existingToken || !reconnectingSameChannel) {
      throw new YouTubeProviderError(
        "authentication_required",
        "Google did not return a reusable channel authorization. Connect again and approve access.",
        401,
      );
    } else if (
      !sameScopes(existingToken.grantedScopes, effectiveGrantedScopes)
    ) {
      await this.options.refreshTokens.save(
        connectionKey,
        existingToken.refreshToken,
        effectiveGrantedScopes,
      );
      credentialChanged = true;
    }
    const now = this.clock.now().toISOString();
    const record: YouTubeProviderConnectionRecord = {
      connectionKey,
      userId: attempt.userId,
      channelId: channel.channelId,
      channelTitle: channel.title,
      grantedScopes: effectiveGrantedScopes,
      connectedAt: reconnectingSameChannel
        ? existingConnection?.connectedAt ?? now
        : now,
      lastVerifiedAt: now,
      status: "ACTIVE",
    };
    try {
      await this.options.connections.save(record);
    } catch (connectionSaveError) {
      if (credentialChanged) {
        try {
          if (existingToken) {
            await this.options.refreshTokens.save(
              connectionKey,
              existingToken.refreshToken,
              existingToken.grantedScopes,
            );
          } else {
            await this.options.refreshTokens.delete(connectionKey);
          }
        } catch (credentialRollbackError) {
          throw new AggregateError(
            [connectionSaveError, credentialRollbackError],
            "YouTube connection persistence failed and credential rollback did not complete.",
          );
        }
      }
      throw connectionSaveError;
    }
    this.options.accessTokens.set(connectionKey, {
      accessToken: token.access_token,
      expiresAtEpochMs:
        this.clock.now().getTime() +
        token.expires_in * 1000 -
        ACCESS_TOKEN_SAFETY_MS,
      grantedScopes: record.grantedScopes,
    });
    return channel;
  }

  private oauthResponse(
    stateInput: string,
    codeInput: string,
  ): { readonly state: string; readonly code: string } {
    const state = stateInput.trim();
    const code = codeInput.trim();
    if (!state || !code) {
      throw new YouTubeProviderError(
        "bad_request",
        "The YouTube authorization response is incomplete.",
        400,
      );
    }
    return { state, code };
  }

  async beginPrivateUpload(
    request: BeginYouTubeUploadRequest,
  ): Promise<BeginYouTubeUploadResult> {
    requireCapability(this.options.capabilities, "privateUpload");
    const userId = validateIdentity(request.userId, "user");
    const idempotencyKey = validateIdentity(
      request.idempotencyKey,
      "idempotency key",
    );
    const fileIdentity = normalizeYouTubeUploadFileIdentity(
      request.fileIdentity,
    );
    assertYouTubeUploadFileIdentityMatches(
      fileIdentity,
      request.contentType,
      request.contentLength,
    );
    const requestFingerprint = youtubeUploadRequestFingerprint(
      fileIdentity,
      request.metadata,
    );
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      request.requestId,
      [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE],
    );
    const jobKey = stableKey("ytj", userId, idempotencyKey);
    const now = this.clock.now().toISOString();
    const reservation = await this.options.publications.reserve({
      jobKey,
      userId,
      connectionKey: connection.connectionKey,
      idempotencyKey,
      requestFingerprint,
      title: request.metadata.title.trim(),
      privacyStatus: "private",
      contentLength: request.contentLength,
      encryptedSessionUrl: "",
      state: "SESSION_CREATING",
      createdAt: now,
      updatedAt: now,
    });
    if (!reservation.created) {
      const existing = reservation.record;
      if (existing.requestFingerprint !== requestFingerprint) {
        throw new YouTubeProviderError(
          "conflict",
          "This upload key is already assigned to a different video request.",
          409,
        );
      }
      const duplicateAt = this.clock.now();
      if (
        existing.state === "SESSION_CREATING" &&
        creatingLeaseExpired(existing, duplicateAt)
      ) {
        await this.failExpiredUpload(
          existing,
          UPLOAD_SESSION_CREATION_EXPIRED,
          duplicateAt,
        );
        throw new YouTubeProviderError(
          "conflict",
          "The YouTube upload request expired before its session was created. Start a new upload.",
          409,
        );
      }
      if (
        existing.state === "SESSION_READY" &&
        readySessionExpired(existing, duplicateAt)
      ) {
        await this.failExpiredUpload(
          existing,
          UPLOAD_SESSION_EXPIRED,
          duplicateAt,
        );
        throw new YouTubeProviderError(
          "conflict",
          "The YouTube upload session expired. Start a new upload.",
          409,
        );
      }
      if (
        existing.state !== "SESSION_READY" ||
        !existing.encryptedSessionUrl
      ) {
        throw new YouTubeProviderError(
          "conflict",
          existing.state === "SESSION_CREATING"
            ? "This upload request is already starting. Try again."
            : "This upload request has already advanced.",
          409,
          existing.state === "SESSION_CREATING",
        );
      }
      return {
        jobKey: existing.jobKey,
        sessionUrl: this.options.uploadSessionCipher.decrypt(
          existing.encryptedSessionUrl,
          `upload:${existing.jobKey}`,
        ),
        expiresAt: new Date(
          sessionExpiryEpochMs(existing) ??
            duplicateAt.getTime(),
        ).toISOString(),
        privacyStatus: "private",
      };
    }
    try {
      const session = await this.options.ownerClient.beginPrivateUpload({
        principal: userId,
        requestId: request.requestId,
        accessToken,
        contentType: request.contentType,
        contentLength: request.contentLength,
        metadata: request.metadata,
      });
      await this.options.publications.update(userId, jobKey, {
        encryptedSessionUrl: this.options.uploadSessionCipher.encrypt(
          session.sessionUrl,
          `upload:${jobKey}`,
        ),
        sessionExpiresAt: session.expiresAt,
        state: "SESSION_READY",
        updatedAt: this.clock.now().toISOString(),
      });
      return { jobKey, ...session };
    } catch (error) {
      await this.options.publications.update(userId, jobKey, {
        encryptedSessionUrl: "",
        state: "FAILED",
        failureCode: "provider_session_initialization_failed",
        updatedAt: this.clock.now().toISOString(),
      });
      throw error;
    }
  }

  private async failExpiredUpload(
    job: YouTubePublicationJobRecord,
    failureCode:
      | typeof UPLOAD_SESSION_CREATION_EXPIRED
      | typeof UPLOAD_SESSION_EXPIRED,
    now: Date,
  ): Promise<void> {
    await this.options.publications.update(job.userId, job.jobKey, {
      encryptedSessionUrl: "",
      state: "FAILED",
      failureCode,
      updatedAt: now.toISOString(),
    });
  }

  async reconcileUpload(
    userIdInput: string,
    requestId: string,
    jobKey: string,
  ): Promise<YouTubeVideoSummary> {
    requireCapability(this.options.capabilities, "privateUpload");
    const userId = validateIdentity(userIdInput, "user");
    const job = await this.options.publications.getByKey(userId, jobKey);
    if (!job) {
      throw new YouTubeProviderError(
        "not_found",
        "The YouTube upload could not be found.",
        404,
      );
    }
    if (job.state === "SESSION_CREATING") {
      const checkedAt = this.clock.now();
      if (creatingLeaseExpired(job, checkedAt)) {
        await this.failExpiredUpload(
          job,
          UPLOAD_SESSION_CREATION_EXPIRED,
          checkedAt,
        );
        throw new YouTubeProviderError(
          "conflict",
          "The YouTube upload request expired before its session was created. Start a new upload.",
          409,
        );
      }
      throw new YouTubeProviderError(
        "conflict",
        "The YouTube upload is not ready for confirmation.",
        409,
        true,
      );
    }
    if (
      job.state === "SESSION_READY" &&
      readySessionExpired(job, this.clock.now())
    ) {
      await this.failExpiredUpload(
        job,
        UPLOAD_SESSION_EXPIRED,
        this.clock.now(),
      );
      throw new YouTubeProviderError(
        "conflict",
        "The YouTube upload session expired. Start a new upload.",
        409,
      );
    }
    if (
      job.state === "FAILED" ||
      job.state === "CANCELLED" ||
      (job.state !== "SESSION_READY" &&
        job.state !== "PROCESSING" &&
        job.state !== "COMPLETE")
    ) {
      throw new YouTubeProviderError(
        "conflict",
        "The YouTube upload cannot be confirmed.",
        409,
      );
    }
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE],
    );
    if (job.connectionKey !== connection.connectionKey) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube upload belongs to another channel connection.",
        403,
      );
    }
    let videoId = job.videoId;
    if (job.state === "SESSION_READY") {
      if (!job.encryptedSessionUrl) {
        throw new YouTubeProviderError(
          "conflict",
          "The YouTube upload session is unavailable.",
          409,
        );
      }
      const sessionUrl = this.options.uploadSessionCipher.decrypt(
        job.encryptedSessionUrl,
        `upload:${job.jobKey}`,
      );
      videoId = await this.options.ownerClient.completedUploadVideoId({
        accessToken,
        sessionUrl,
        contentLength: job.contentLength,
      });
    }
    if (!videoId) {
      throw new YouTubeProviderError(
        "conflict",
        "The YouTube upload identity is unavailable.",
        409,
        job.state === "PROCESSING",
      );
    }
    const video = await this.options.ownerClient.ownedVideo(
      userId,
      requestId,
      accessToken,
      videoId,
    );
    if (video.channelId !== connection.channelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube video does not belong to the connected channel.",
        403,
      );
    }
    if (video.privacyStatus !== "private") {
      throw new YouTubeProviderError(
        "permission_denied",
        "Private Dev may reconcile only private YouTube uploads.",
        403,
      );
    }
    const state = statusForVideo(video);
    await this.options.publications.update(userId, jobKey, {
      encryptedSessionUrl: "",
      videoId: video.videoId,
      state,
      updatedAt: this.clock.now().toISOString(),
      ...(state === "FAILED" ? { failureCode: "provider_upload_failed" } : {}),
    });
    return video;
  }

  async ownerVideos(
    userIdInput: string,
    requestId: string,
    pageToken?: string,
    maxResults?: number,
  ): Promise<YouTubeOwnerVideosPage> {
    requireCapability(this.options.capabilities, "ownerConnect");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE],
    );
    return this.options.ownerClient.ownerVideos({
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
      expectedChannelTitle: connection.channelTitle,
      ...(pageToken === undefined ? {} : { pageToken }),
      ...(maxResults === undefined ? {} : { maxResults }),
    });
  }

  async ownerSubscriptions(
    userIdInput: string,
    requestId: string,
    pageToken?: string,
    maxResults?: number,
    order?: "alphabetical" | "relevance" | "unread",
  ): Promise<YouTubeOwnerSubscriptionsPage> {
    requireCapability(this.options.capabilities, "ownerConnect");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE],
    );
    return this.options.ownerClient.ownerSubscriptions({
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
      expectedChannelTitle: connection.channelTitle,
      ...(pageToken === undefined ? {} : { pageToken }),
      ...(maxResults === undefined ? {} : { maxResults }),
      ...(order === undefined ? {} : { order }),
    });
  }

  async ownerPlaylists(
    userIdInput: string,
    requestId: string,
    pageToken?: string,
    maxResults?: number,
  ): Promise<YouTubeOwnerPlaylistsPage> {
    requireCapability(this.options.capabilities, "ownerConnect");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE],
    );
    return this.options.ownerClient.ownerPlaylists({
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
      expectedChannelTitle: connection.channelTitle,
      ...(pageToken === undefined ? {} : { pageToken }),
      ...(maxResults === undefined ? {} : { maxResults }),
    });
  }

  async ownerGetRating(
    userIdInput: string,
    requestId: string,
    videoId: string,
  ) {
    return this.options.ownerClient.ownerGetRating({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      videoId,
    });
  }

  async ownerSetRating(
    userIdInput: string,
    requestId: string,
    videoId: string,
    rating: "like" | "dislike",
  ) {
    return this.options.ownerClient.ownerSetRating({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      videoId,
      rating,
    });
  }

  async ownerRemoveRating(
    userIdInput: string,
    requestId: string,
    videoId: string,
  ) {
    return this.options.ownerClient.ownerRemoveRating({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      videoId,
    });
  }

  async ownerCreateComment(
    userIdInput: string,
    requestId: string,
    videoId: string,
    text: string,
  ) {
    return this.options.ownerClient.ownerCreateComment({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      videoId,
      text,
    });
  }

  async ownerCreateReply(
    userIdInput: string,
    requestId: string,
    parentCommentId: string,
    text: string,
  ) {
    return this.options.ownerClient.ownerCreateReply({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      parentCommentId,
      text,
    });
  }

  async ownerUpdateComment(
    userIdInput: string,
    requestId: string,
    commentId: string,
    text: string,
  ) {
    return this.options.ownerClient.ownerUpdateComment({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      commentId,
      text,
    });
  }

  async ownerDeleteComment(
    userIdInput: string,
    requestId: string,
    commentId: string,
  ) {
    return this.options.ownerClient.ownerDeleteComment({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      commentId,
    });
  }

  async ownerSetCommentModeration(
    userIdInput: string,
    requestId: string,
    commentId: string,
    moderationStatus: "published" | "heldForReview" | "rejected",
    banAuthor?: boolean,
  ) {
    return this.options.ownerClient.ownerSetCommentModeration({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      commentId,
      moderationStatus,
      ...(banAuthor === undefined ? {} : { banAuthor }),
    });
  }

  async ownerSubscribe(
    userIdInput: string,
    requestId: string,
    channelId: string,
  ) {
    return this.options.ownerClient.ownerSubscribe({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      channelId,
    });
  }

  async ownerUnsubscribe(
    userIdInput: string,
    requestId: string,
    subscriptionId: string,
  ) {
    return this.options.ownerClient.ownerUnsubscribe({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      subscriptionId,
    });
  }

  async ownerCreatePlaylist(
    userIdInput: string,
    requestId: string,
    title: string,
    description: string,
    privacyStatus: "private" | "unlisted" | "public",
  ) {
    return this.options.ownerClient.ownerCreatePlaylist({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      title,
      description,
      privacyStatus,
    });
  }

  async ownerUpdatePlaylist(
    userIdInput: string,
    requestId: string,
    playlistId: string,
    title: string,
    description: string,
    privacyStatus: "private" | "unlisted" | "public",
  ) {
    return this.options.ownerClient.ownerUpdatePlaylist({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      playlistId,
      title,
      description,
      privacyStatus,
    });
  }

  async ownerDeletePlaylist(
    userIdInput: string,
    requestId: string,
    playlistId: string,
  ) {
    return this.options.ownerClient.ownerDeletePlaylist({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      playlistId,
    });
  }

  async ownerCreatePlaylistItem(
    userIdInput: string,
    requestId: string,
    playlistId: string,
    videoId: string,
    position?: number,
  ) {
    return this.options.ownerClient.ownerCreatePlaylistItem({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      playlistId,
      videoId,
      ...(position === undefined ? {} : { position }),
    });
  }

  async ownerReorderPlaylistItem(
    userIdInput: string,
    requestId: string,
    playlistItemId: string,
    position: number,
  ) {
    return this.options.ownerClient.ownerReorderPlaylistItem({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      playlistItemId,
      position,
    });
  }

  async ownerDeletePlaylistItem(
    userIdInput: string,
    requestId: string,
    playlistItemId: string,
  ) {
    return this.options.ownerClient.ownerDeletePlaylistItem({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      playlistItemId,
    });
  }

  async ownerUpdateVideoMetadata(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly title: string;
      readonly description: string;
      readonly categoryId: string;
      readonly tags?: readonly string[];
    },
  ) {
    return this.options.ownerClient.ownerUpdateVideoMetadata({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async ownerDeleteVideo(
    userIdInput: string,
    requestId: string,
    videoId: string,
    confirmVideoId: string,
  ) {
    return this.options.ownerClient.ownerDeleteVideo({
      ...(await this.ownerActionAccess(userIdInput, requestId)),
      videoId,
      confirmVideoId,
    });
  }

  async creatorBeginThumbnailSet(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly contentType: string;
      readonly contentLength: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginThumbnailSet({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorListCaptions(
    userIdInput: string,
    requestId: string,
    videoId: string,
  ) {
    return this.options.ownerClient.creatorAssets.listCaptions({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      videoId,
    });
  }

  async creatorDownloadCaption(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly captionId: string;
      readonly format: "sbv" | "scc" | "srt" | "ttml" | "vtt";
      readonly translatedLanguage?: string;
    },
  ) {
    return this.options.ownerClient.creatorAssets.downloadCaption({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorBeginCaptionInsert(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly language: string;
      readonly name: string;
      readonly isDraft: boolean;
      readonly contentType: string;
      readonly contentLength: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginCaptionInsert({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorUpdateCaptionDraft(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly captionId: string;
      readonly isDraft: boolean;
    },
  ) {
    return this.options.ownerClient.creatorAssets.updateCaptionDraft({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorBeginCaptionReplacement(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly captionId: string;
      readonly isDraft: boolean;
      readonly contentType: string;
      readonly contentLength: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginCaptionReplacement({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorDeleteCaption(
    userIdInput: string,
    requestId: string,
    videoId: string,
    captionId: string,
  ) {
    return this.options.ownerClient.creatorAssets.deleteCaption({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      videoId,
      captionId,
    });
  }

  async creatorUpdateChannelBranding(
    userIdInput: string,
    requestId: string,
    patch: CreatorChannelBrandingPatch,
  ) {
    return this.options.ownerClient.creatorAssets.updateChannelBranding({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      patch,
    });
  }

  async creatorListChannelSections(
    userIdInput: string,
    requestId: string,
  ) {
    return this.options.ownerClient.creatorAssets.listChannelSections(
      await this.creatorAssetAccess(userIdInput, requestId),
    );
  }

  async creatorInsertChannelSection(
    userIdInput: string,
    requestId: string,
    section: CreatorChannelSectionInput,
  ) {
    return this.options.ownerClient.creatorAssets.insertChannelSection({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      section,
    });
  }

  async creatorUpdateChannelSection(
    userIdInput: string,
    requestId: string,
    sectionId: string,
    section: CreatorChannelSectionInput,
  ) {
    return this.options.ownerClient.creatorAssets.updateChannelSection({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      sectionId,
      section,
    });
  }

  async creatorDeleteChannelSection(
    userIdInput: string,
    requestId: string,
    sectionId: string,
  ) {
    return this.options.ownerClient.creatorAssets.deleteChannelSection({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      sectionId,
    });
  }

  async creatorBeginChannelBannerInsert(
    userIdInput: string,
    requestId: string,
    input: {
      readonly contentType: string;
      readonly contentLength: number;
      readonly width: number;
      readonly height: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginChannelBannerInsert({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorApplyChannelBanner(
    userIdInput: string,
    requestId: string,
    bannerExternalUrl: string,
  ) {
    return this.options.ownerClient.creatorAssets.applyChannelBanner({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      bannerExternalUrl,
    });
  }

  async creatorBeginWatermarkSet(
    userIdInput: string,
    requestId: string,
    input: {
      readonly contentType: string;
      readonly contentLength: number;
      readonly width: number;
      readonly height: number;
      readonly offsetMs: number;
      readonly durationMs: number;
      readonly offsetFrom: "start" | "end";
      readonly corner:
        | "topLeft"
        | "topRight"
        | "bottomLeft"
        | "bottomRight";
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginWatermarkSet({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorUnsetWatermark(
    userIdInput: string,
    requestId: string,
  ) {
    return this.options.ownerClient.creatorAssets.unsetWatermark(
      await this.creatorAssetAccess(userIdInput, requestId),
    );
  }

  async creatorListPlaylistImages(
    userIdInput: string,
    requestId: string,
    input: {
      readonly playlistId: string;
      readonly pageToken?: string;
      readonly maxResults?: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.listPlaylistImages({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorBeginPlaylistImageInsert(
    userIdInput: string,
    requestId: string,
    input: {
      readonly playlistId: string;
      readonly contentType: string;
      readonly contentLength: number;
      readonly width: number;
      readonly height: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginPlaylistImageInsert({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorBeginPlaylistImageUpdate(
    userIdInput: string,
    requestId: string,
    input: {
      readonly playlistId: string;
      readonly playlistImageId: string;
      readonly contentType: string;
      readonly contentLength: number;
      readonly width: number;
      readonly height: number;
    },
  ) {
    return this.options.ownerClient.creatorAssets.beginPlaylistImageUpdate({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorDeletePlaylistImage(
    userIdInput: string,
    requestId: string,
    playlistId: string,
    playlistImageId: string,
  ) {
    return this.options.ownerClient.creatorAssets.deletePlaylistImage({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      playlistId,
      playlistImageId,
    });
  }

  async creatorListVideoAbuseReasons(
    userIdInput: string,
    requestId: string,
    language?: string,
  ) {
    return this.options.ownerClient.creatorAssets.listVideoAbuseReasons({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...(language === undefined ? {} : { language }),
    });
  }

  async creatorReportVideoAbuse(
    userIdInput: string,
    requestId: string,
    input: {
      readonly videoId: string;
      readonly reasonId: string;
      readonly secondaryReasonId?: string;
      readonly comments?: string;
      readonly language?: string;
      readonly confirmVideoId: string;
      readonly confirmReasonId: string;
    },
  ) {
    return this.options.ownerClient.creatorAssets.reportVideoAbuse({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async creatorInsertAbuseReport(
    userIdInput: string,
    requestId: string,
    input: {
      readonly subjectTypeId: string;
      readonly subjectId: string;
      readonly abuseTypeIds: readonly string[];
      readonly description?: string;
      readonly relatedEntities?: readonly {
        readonly typeId: string;
        readonly id: string;
      }[];
      readonly confirmSubjectTypeId: string;
      readonly confirmSubjectId: string;
      readonly confirmAbuseTypeIds: readonly string[];
    },
  ) {
    return this.options.ownerClient.creatorAssets.insertAbuseReport({
      ...(await this.creatorAssetAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListBroadcasts(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastListRequest>,
  ) {
    return this.options.ownerClient.live.listBroadcasts({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertBroadcast(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertBroadcast({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveUpdateBroadcast(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastUpdateRequest>,
  ) {
    return this.options.ownerClient.live.updateBroadcast({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveBindBroadcast(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastBindRequest>,
  ) {
    return this.options.ownerClient.live.bindBroadcast({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveTransitionBroadcast(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastTransitionRequest>,
  ) {
    return this.options.ownerClient.live.transitionBroadcast({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveDeleteBroadcast(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveBroadcastDeleteRequest>,
  ) {
    return this.options.ownerClient.live.deleteBroadcast({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListStreams(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveListRequest>,
  ) {
    return this.options.ownerClient.live.listStreams({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertStream(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveStreamInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertStream({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveUpdateStream(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveStreamUpdateRequest>,
  ) {
    return this.options.ownerClient.live.updateStream({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveDeleteStream(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveStreamDeleteRequest>,
  ) {
    return this.options.ownerClient.live.deleteStream({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListChatMessages(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatListRequest>,
  ) {
    return this.options.ownerClient.live.listMessages({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertChatText(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatTextInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertTextMessage({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertChatPoll(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatPollInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertPoll({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveCloseChatPoll(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatPollCloseRequest>,
  ) {
    return this.options.ownerClient.live.closePoll({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveDeleteChatMessage(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatMessageDeleteRequest>,
  ) {
    return this.options.ownerClient.live.deleteMessage({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListModerators(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatListRequest>,
  ) {
    return this.options.ownerClient.live.listModerators({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertModerator(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatModeratorInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertModerator({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveDeleteModerator(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatModeratorDeleteRequest>,
  ) {
    return this.options.ownerClient.live.deleteModerator({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveInsertBan(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatBanInsertRequest>,
  ) {
    return this.options.ownerClient.live.insertBan({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveDeleteBan(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveChatBanDeleteRequest>,
  ) {
    return this.options.ownerClient.live.deleteBan({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListSuperChatEvents(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveSuperChatListRequest>,
  ) {
    return this.options.ownerClient.live.listSuperChatEvents({
      ...(await this.liveAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListMembers(
    userIdInput: string,
    requestId: string,
    input: LiveRequestInput<LiveMemberListRequest>,
  ) {
    return this.options.ownerClient.live.listMembers({
      ...(await this.liveMembershipAccess(userIdInput, requestId)),
      ...input,
    });
  }

  async liveListMembershipLevels(
    userIdInput: string,
    requestId: string,
  ) {
    return this.options.ownerClient.live.listMembershipLevels(
      await this.liveMembershipAccess(userIdInput, requestId),
    );
  }

  /**
   * Returns the existing revalidated active-owner token boundary without
   * asserting Firebase Auth or App Check. The HTTP router owns those checks
   * and attaches their verified state to the isolated adapter invocation.
   */
  async ownerAnalyticsReportingAccess(
    userIdInput: string,
    requestId: string,
  ): Promise<YouTubeAnalyticsReportingOwnerAccess> {
    requireCapability(this.options.capabilities, "ownerAnalytics");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE, YOUTUBE_ANALYTICS_READONLY_SCOPE],
    );
    return {
      principal: userId,
      requestId,
      accessToken,
      owner: {
        userId,
        channelId: connection.channelId,
        status: "ACTIVE",
        grantedScopes: connection.grantedScopes,
      },
    };
  }

  async ownerAnalyticsPreset(
    userIdInput: string,
    requestId: string,
    query: Omit<
      AnalyticsPresetQuery,
      "principal" | "requestId" | "accessToken"
    >,
  ): Promise<YouTubeOwnerAnalyticsResult> {
    requireCapability(this.options.capabilities, "ownerAnalytics");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE, YOUTUBE_ANALYTICS_READONLY_SCOPE],
    );
    if (query.preset === "videoRetention") {
      const videoId = query.videoId?.trim() ?? "";
      const video = await this.options.ownerClient.ownedVideo(
        userId,
        requestId,
        accessToken,
        videoId,
      );
      if (video.channelId !== connection.channelId) {
        throw new YouTubeProviderError(
          "permission_denied",
          "The requested YouTube video does not belong to the connected channel.",
          403,
        );
      }
    }
    return this.options.ownerClient.analyticsPreset({
      ...query,
      principal: userId,
      requestId,
      accessToken,
    });
  }

  async connectionStatus(
    userIdInput: string,
    requestId: string,
  ): Promise<
    | {
        readonly connected: false;
        readonly lastVerifiedAt: string | null;
        readonly nextVerificationDueAt: string | null;
        readonly verificationState: "reconnect_required";
      }
    | {
        readonly connected: true;
        readonly channelId: string;
        readonly channelTitle: string;
        readonly grantedScopes: readonly string[];
        readonly lastVerifiedAt: string;
        readonly nextVerificationDueAt: string;
        readonly verificationState: "current" | "due";
      }
  > {
    requireCapability(this.options.capabilities, "ownerConnect");
    const userId = validateIdentity(userIdInput, "user");
    const connection = await this.options.connections.getByUser(userId);
    if (!connection || connection.status !== "ACTIVE") {
      return {
        connected: false,
        lastVerifiedAt: connection?.lastVerifiedAt ?? null,
        nextVerificationDueAt: connection
          ? connectionNextVerificationDueAt(connection)
          : null,
        verificationState: "reconnect_required",
      };
    }
    const { connection: verifiedConnection } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE],
    );
    const nextVerificationDueAt =
      connectionNextVerificationDueAt(verifiedConnection);
    if (nextVerificationDueAt === null) {
      throw new YouTubeProviderError(
        "authentication_required",
        "Reconnect the selected YouTube channel.",
        401,
      );
    }
    return {
      connected: true,
      channelId: verifiedConnection.channelId,
      channelTitle: verifiedConnection.channelTitle,
      grantedScopes: verifiedConnection.grantedScopes,
      lastVerifiedAt: verifiedConnection.lastVerifiedAt,
      nextVerificationDueAt,
      verificationState: "current",
    };
  }

  async disconnect(
    userIdInput: string,
  ): Promise<YouTubeDisconnectResult> {
    const userId = validateIdentity(userIdInput, "user");
    const connection = await this.options.connections.getByUser(userId);
    let providerRevocationConfirmed = false;
    if (connection) {
      const material =
        await this.options.refreshTokens.load(connection.connectionKey);
      if (material) {
        try {
          const body = new URLSearchParams({ token: material.refreshToken });
          const response = await this.options.transport.send({
            url: GOOGLE_REVOKE_ENDPOINT,
            method: "POST",
            headers: {
              "content-type": "application/x-www-form-urlencoded",
            },
            body: body.toString(),
          });
          providerRevocationConfirmed =
            response.status >= 200 && response.status < 300;
        } catch {
          providerRevocationConfirmed = false;
        }
      }
      await this.options.refreshTokens.delete(connection.connectionKey);
      this.options.accessTokens.delete(connection.connectionKey);
      await this.options.connections.delete(connection.connectionKey);
    }
    await this.options.publications.deleteByUser(userId);
    await this.options.oauthAttempts.deleteByUser(userId);
    return {
      disconnected: true,
      providerRevocationConfirmed,
    };
  }

  private async ownerActionAccess(
    userIdInput: string,
    requestId: string,
  ): Promise<{
    readonly principal: string;
    readonly requestId: string;
    readonly accessToken: string;
    readonly expectedChannelId: string;
  }> {
    requireCapability(this.options.capabilities, "ownerActions");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_READONLY_SCOPE, YOUTUBE_FORCE_SSL_SCOPE],
    );
    return {
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
    };
  }

  private publicDiscoveryClient(): Pick<
    YouTubePublicDiscoveryClient,
    "listChannelActivities" | "listChannelSections"
  > {
    const client = this.options.publicDiscoveryClient;
    if (client === undefined) {
      throw new YouTubeProviderError(
        "provider_unavailable",
        "YouTube public discovery is temporarily unavailable.",
        503,
        true,
      );
    }
    return client;
  }

  private async creatorAssetAccess(
    userIdInput: string,
    requestId: string,
  ): Promise<{
    readonly principal: string;
    readonly requestId: string;
    readonly accessToken: string;
    readonly expectedChannelId: string;
  }> {
    requireCapability(this.options.capabilities, "creatorAssets");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_FORCE_SSL_SCOPE],
    );
    return {
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
    };
  }

  private async liveAccess(
    userIdInput: string,
    requestId: string,
  ): Promise<LiveOwnerRequest> {
    requireCapability(this.options.capabilities, "live");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_MANAGE_SCOPE],
    );
    return {
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
    };
  }

  private async liveMembershipAccess(
    userIdInput: string,
    requestId: string,
  ): Promise<LiveOwnerRequest> {
    requireCapability(this.options.capabilities, "live");
    const userId = validateIdentity(userIdInput, "user");
    const { connection, accessToken } = await this.ownerAccess(
      userId,
      requestId,
      [YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE],
    );
    return {
      principal: userId,
      requestId,
      accessToken,
      expectedChannelId: connection.channelId,
    };
  }

  private async ownerAccess(
    userId: string,
    requestId: string,
    requiredScopes: readonly string[],
  ): Promise<{
    readonly connection: YouTubeProviderConnectionRecord;
    readonly accessToken: string;
  }> {
    const connection = await this.options.connections.getByUser(userId);
    if (!connection || connection.status !== "ACTIVE") {
      throw new YouTubeProviderError(
        "authentication_required",
        "Connect a YouTube channel to continue.",
        401,
      );
    }
    if (!includesScopes(connection.grantedScopes, requiredScopes)) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The connected YouTube channel needs additional permission.",
        403,
      );
    }
    const mustRevalidate = connectionNeedsRevalidation(
      connection,
      this.clock.now(),
    );
    const cached = this.options.accessTokens.get(connection.connectionKey);
    if (
      !mustRevalidate &&
      cached &&
      includesScopes(cached.grantedScopes, requiredScopes)
    ) {
      return { connection, accessToken: cached.accessToken };
    }
    const material =
      await this.options.refreshTokens.load(connection.connectionKey);
    if (!material) {
      throw new YouTubeProviderError(
        "authentication_required",
        "Reconnect the selected YouTube channel.",
        401,
      );
    }
    let token: YouTubeTokenResponse;
    try {
      token = await refreshAccessToken(this.options.transport, {
        clientId: this.options.oauthClientId,
        clientSecret: this.options.oauthClientSecret,
        refreshToken: material.refreshToken,
      });
    } catch (error) {
      throw mapOAuthFailure(error);
    }
    const grantedScopes = tokenScopes(
      token.scope,
      material.grantedScopes,
    );
    if (!includesScopes(grantedScopes, requiredScopes)) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The connected YouTube channel needs additional permission.",
        403,
      );
    }
    this.options.accessTokens.set(connection.connectionKey, {
      accessToken: token.access_token,
      expiresAtEpochMs:
        this.clock.now().getTime() +
        token.expires_in * 1000 -
        ACCESS_TOKEN_SAFETY_MS,
      grantedScopes,
    });
    if (!mustRevalidate) {
      return { connection, accessToken: token.access_token };
    }
    const verifiedChannel = await this.options.ownerClient.connectedChannel(
      userId,
      requestId,
      token.access_token,
    );
    if (verifiedChannel.channelId !== connection.channelId) {
      const revokedAt = this.clock.now().toISOString();
      await this.options.connections.markRevoked(
        connection.connectionKey,
        revokedAt,
      );
      this.options.accessTokens.delete(connection.connectionKey);
      throw new YouTubeProviderError(
        "authentication_required",
        "Reconnect the selected YouTube channel.",
        401,
      );
    }
    const verifiedConnection: YouTubeProviderConnectionRecord = {
      ...connection,
      channelTitle: verifiedChannel.title,
      lastVerifiedAt: this.clock.now().toISOString(),
    };
    await this.options.connections.save(verifiedConnection);
    return {
      connection: verifiedConnection,
      accessToken: token.access_token,
    };
  }
}
