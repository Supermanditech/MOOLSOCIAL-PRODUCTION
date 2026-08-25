import { randomUUID } from "node:crypto";

import { getApps, initializeApp } from "firebase-admin/app";
import { getAppCheck } from "firebase-admin/app-check";
import { getAuth } from "firebase-admin/auth";
import { getDataConnect } from "firebase-admin/data-connect";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { logger } from "firebase-functions";
import { defineSecret, defineString } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";

import {
  FetchXProviderTransport,
  FirebaseAdminXTokenIssuer,
  FirestoreXAttemptStore,
  HmacXSubjectProjector,
  parseXPublicAuthRequest,
  X_PUBLIC_AUTH_MAX_REQUEST_BODY_BYTES,
  XPublicAuthBroker,
  XPublicAuthError,
} from "./auth/x_pkce_broker.js";
import {
  FetchInstagramProviderTransport,
  FirebaseAdminInstagramTokenIssuer,
  FirestoreInstagramAttemptStore,
  HmacInstagramSubjectProjector,
  InstagramPublicAuthBroker,
  InstagramPublicAuthError,
  parseInstagramPublicAuthRequest,
} from "./auth/instagram_oauth_broker.js";
import {
  InstagramMetaCallbackError,
  InstagramMetaCallbackService,
} from "./auth/instagram_meta_callbacks.js";
import {
  FacebookMetaCallbackError,
  FacebookMetaCallbackService,
} from "./auth/facebook_meta_callbacks.js";
import {
  MetaAccountErasureCoordinator,
  MetaAccountErasureError,
} from "./auth/meta_account_erasure.js";
import {
  FirebaseMetaAccountErasureWorker,
  FirestoreMetaAccountErasureStore,
} from "./auth/meta_account_erasure_firebase.js";

import {
  ProcessYouTubeCache,
  YouTubeQuotaGovernorAdapter,
} from "./youtube/adapters.js";
import {
  YouTubePublicDiscoveryClient,
  type YouTubePublicActivityType,
} from "./youtube-private-dev/public-discovery/public_discovery_client.js";
import {
  type VerifiedOwnerInvocation,
  YouTubeAnalyticsReportingError,
} from "./youtube-private-dev/analytics-reporting/contracts.js";
import { FirestoreAnalyticsReportingIdempotency } from "./youtube-private-dev/analytics-reporting/firestore_idempotency.js";
import {
  createAnalyticsReportingClients,
  dispatchAnalyticsReportingOperation,
  RouterConsumedAppCheckReplay,
} from "./youtube-private-dev/analytics-reporting/registration.js";
import { YouTubeDataClient } from "./youtube/client.js";
import {
  createLiveCapabilities,
  readCapabilities,
  requireCapability,
  requireConnectPurposeCapability,
  requireOwnerConnectionStatusCapability,
} from "./youtube/config.js";
import { YouTubeProviderError } from "./youtube/errors.js";
import {
  createFirestoreYouTubeStores,
  type FirestoreYouTubeStores,
} from "./youtube/firestore_store.js";
import { YouTubeOwnerClient } from "./youtube/owner_client.js";
import { youtubeOAuthReturnPage } from "./youtube/oauth_return_page.js";
import { YouTubeProviderService } from "./youtube/provider_service.js";
import {
  FirestoreSharedShortsCatalogueStore,
  SharedShortsCatalogueCoordinator,
  sharedShortsCatalogueContract,
} from "./youtube/shared_catalogue.js";
import type {
  CreatorChannelBrandingPatch,
  CreatorChannelSectionInput,
} from "./youtube/creator_assets_client.js";
import {
  readDevYouTubeQuotaCaps,
  YouTubeQuotaGovernor,
} from "./youtube/quota.js";
import { redactSensitiveData } from "./youtube/redaction.js";
import {
  isAuthenticatedOwnerOperation,
  requiresReplayProtectedAppCheck,
} from "./youtube/request_contract.js";
import {
  assertRawRequestBodyWithinLimit,
  YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES,
} from "./youtube/request_security.js";
import {
  Aes256GcmEnvelopeCipher,
  Aes256GcmEnvelopeKeyring,
  InMemoryAccessTokenCache,
  RefreshTokenVault,
} from "./youtube/token_vault.js";
import { FetchHttpTransport } from "./youtube/transport.js";
import type { YouTubeUploadMetadata } from "./youtube/types.js";
import type { YouTubeUploadFileIdentityInput } from "./youtube/upload_identity.js";
import { ChatError, type ChatProfile } from "./chat/contracts.js";
import { GoogleCloudStorageChatPhotoStore } from "./chat/attachment_store.js";
import { FirestoreChatRepository } from "./chat/firestore_store.js";
import { ChatService } from "./chat/service.js";
import { SocialContentError } from "./social/contracts.js";
import { FirestoreSocialContentRepository } from "./social/firestore_store.js";
import { verifySocialInvocation } from "./social/request_security.js";
import { SocialContentService } from "./social/service.js";

const youtubeServerApiKey = defineSecret("YOUTUBE_SERVER_API_KEY");
const youtubeOauthClientId = defineSecret("YOUTUBE_OAUTH_CLIENT_ID");
const youtubeOauthClientSecret = defineSecret("YOUTUBE_OAUTH_CLIENT_SECRET");
const youtubeTokenEncryptionKeyV1 = defineSecret(
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1",
);
const youtubeTokenEncryptionKeyV2 = defineSecret(
  "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2",
);
const xPublicClientId = defineString("X_PUBLIC_CLIENT_ID");
const xRedirectUri = defineString("X_REDIRECT_URI");
const xSubjectProjectionKey = defineSecret("X_SUBJECT_PROJECTION_KEY");
const instagramPublicClientId = defineString("INSTAGRAM_PUBLIC_CLIENT_ID");
const instagramRedirectUri = defineString("INSTAGRAM_REDIRECT_URI");
const instagramClientSecret = defineSecret("INSTAGRAM_CLIENT_SECRET");
const instagramSubjectProjectionKey = defineSecret(
  "INSTAGRAM_SUBJECT_PROJECTION_KEY",
);
const facebookAppSecret = defineSecret("FACEBOOK_APP_SECRET");
const youtubeProviderRuntimeServiceAccount =
  "youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com";
const socialContentRuntimeServiceAccount =
  "social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com";
const publicAuthRuntimeServiceAccount =
  "public-auth-runtime@moolsocial-dev-503018.iam.gserviceaccount.com";

if (getApps().length === 0) {
  initializeApp();
}

let providerService: YouTubeProviderService | undefined;
let providerStores: FirestoreYouTubeStores | undefined;
let socialContentService: SocialContentService | undefined;
let chatRuntimeService: ChatService | undefined;
let xAuthRuntimeService: XPublicAuthBroker | undefined;
let instagramAuthRuntimeService: InstagramPublicAuthBroker | undefined;
let instagramMetaCallbackRuntimeService:
  | InstagramMetaCallbackService
  | undefined;
let facebookMetaCallbackRuntimeService:
  | FacebookMetaCallbackService
  | undefined;
let metaAccountErasureRuntimeService:
  | MetaAccountErasureCoordinator
  | undefined;

function publicAuthProjectId(): string {
  const projectId =
    getApps()[0]?.options.projectId?.trim() ??
    process.env.GCLOUD_PROJECT?.trim() ??
    process.env.GCP_PROJECT?.trim();
  if (!projectId) throw new Error("Public authentication is not configured.");
  return projectId;
}

function metaAccountErasureCoordinator(): MetaAccountErasureCoordinator {
  if (metaAccountErasureRuntimeService) {
    return metaAccountErasureRuntimeService;
  }
  const firestore = getFirestore();
  metaAccountErasureRuntimeService = new MetaAccountErasureCoordinator({
    store: new FirestoreMetaAccountErasureStore(firestore),
    worker: new FirebaseMetaAccountErasureWorker(
      firestore,
      getStorage().bucket(),
      getAuth(),
      getDataConnect({
        location: "asia-south1",
        serviceId: "moolsocial-core",
        connector: "provider",
      }),
      {
        async revokeAndDelete(userId: string): Promise<void> {
          const connection = await stores().connections.getByUser(userId);
          if (!connection) return;
          const result = await service().disconnect(userId);
          if (!result.providerRevocationConfirmed) {
            throw new Error("YouTube provider revocation was not confirmed.");
          }
        },
      },
    ),
    completionTargetDays: 30,
  });
  return metaAccountErasureRuntimeService;
}

function xPublicAuthBroker(): XPublicAuthBroker {
  if (xAuthRuntimeService) return xAuthRuntimeService;
  xAuthRuntimeService = new XPublicAuthBroker({
    clientId: xPublicClientId.value(),
    redirectUri: xRedirectUri.value(),
    attemptStore: new FirestoreXAttemptStore(getFirestore()),
    transport: new FetchXProviderTransport(),
    subjectProjector: new HmacXSubjectProjector(
      publicAuthProjectId(),
      xSubjectProjectionKey.value(),
    ),
    tokenIssuer: new FirebaseAdminXTokenIssuer(getAuth()),
  });
  return xAuthRuntimeService;
}

function instagramPublicAuthBroker(): InstagramPublicAuthBroker {
  if (instagramAuthRuntimeService) return instagramAuthRuntimeService;
  instagramAuthRuntimeService = new InstagramPublicAuthBroker({
    clientId: instagramPublicClientId.value(),
    redirectUri: instagramRedirectUri.value(),
    attemptStore: new FirestoreInstagramAttemptStore(getFirestore()),
    transport: new FetchInstagramProviderTransport(
      instagramClientSecret.value(),
    ),
    subjectProjector: new HmacInstagramSubjectProjector(
      publicAuthProjectId(),
      instagramSubjectProjectionKey.value(),
    ),
    tokenIssuer: new FirebaseAdminInstagramTokenIssuer(getAuth()),
  });
  return instagramAuthRuntimeService;
}

function instagramMetaCallbackService(): InstagramMetaCallbackService {
  if (instagramMetaCallbackRuntimeService) {
    return instagramMetaCallbackRuntimeService;
  }
  instagramMetaCallbackRuntimeService = new InstagramMetaCallbackService({
    appSecret: instagramClientSecret.value(),
    subjectProjector: new HmacInstagramSubjectProjector(
      publicAuthProjectId(),
      instagramSubjectProjectionKey.value(),
    ),
    firebaseUserDeleter: getAuth(),
    accountEraser: {
      async requestAccountErasure(
        firebaseUid: string,
        confirmationCode: string,
      ): Promise<void> {
        await metaAccountErasureCoordinator().request({
          provider: "instagram",
          confirmationCode,
          firebaseUserIds: [firebaseUid],
        });
      },
    },
  });
  return instagramMetaCallbackRuntimeService;
}

function firebaseAuthErrorCode(value: unknown): string | undefined {
  return typeof value === "object" &&
      value !== null &&
      "code" in value &&
      typeof value.code === "string"
    ? value.code
    : undefined;
}

function facebookMetaCallbackService(): FacebookMetaCallbackService {
  if (facebookMetaCallbackRuntimeService) {
    return facebookMetaCallbackRuntimeService;
  }
  facebookMetaCallbackRuntimeService = new FacebookMetaCallbackService({
    appSecret: facebookAppSecret.value(),
    accountCleaner: {
      async removeProviderAccess(providerUid: string): Promise<void> {
        const firebaseAuth = getAuth();
        const lookup = await firebaseAuth.getUsers([
          { providerId: "facebook.com", providerUid },
        ]);
        for (const user of lookup.users) {
          try {
            const providers = user.providerData.map((item) => item.providerId);
            const facebookOnly = providers.length === 1 &&
              providers[0] === "facebook.com";
            if (facebookOnly) {
              await firebaseAuth.deleteUser(user.uid);
            } else {
              await firebaseAuth.updateUser(user.uid, {
                providersToUnlink: ["facebook.com"],
              });
            }
          } catch (error) {
            if (firebaseAuthErrorCode(error) !== "auth/user-not-found") {
              throw error;
            }
          }
        }
      },
    },
    accountEraser: {
      async requestAccountErasure(
        providerUid: string,
        confirmationCode: string,
      ): Promise<void> {
        const lookup = await getAuth().getUsers([
          { providerId: "facebook.com", providerUid },
        ]);
        await metaAccountErasureCoordinator().request({
          provider: "facebook",
          confirmationCode,
          firebaseUserIds: lookup.users.map((user) => user.uid),
        });
      },
    },
  });
  return facebookMetaCallbackRuntimeService;
}

function stores(): FirestoreYouTubeStores {
  if (providerStores) return providerStores;
  providerStores = createFirestoreYouTubeStores(getFirestore());
  return providerStores;
}

function auditStore() {
  return stores().audit;
}

function socialService(): SocialContentService {
  if (socialContentService) return socialContentService;
  socialContentService = new SocialContentService(
    new FirestoreSocialContentRepository(getFirestore(), getStorage().bucket()),
    async (userId) => {
      const user = await getAuth().getUser(userId);
      const emailPrefix = user.email?.split("@")[0]?.replace(/[^A-Za-z0-9._-]/gu, "") ?? "";
      return {
        userId,
        name: user.displayName?.trim() || "MoolSocial member",
        handle: emailPrefix ? `@${emailPrefix}` : `@${userId.slice(0, 12)}`,
      };
    },
  );
  return socialContentService;
}

async function resolveChatProfile(userId: string): Promise<ChatProfile> {
  try {
    const user = await getAuth().getUser(userId);
    const emailPrefix = user.email
      ?.split("@")[0]
      ?.replace(/[^A-Za-z0-9._-]/gu, "") ?? "";
    return {
      userId,
      name: user.displayName?.trim() || "MoolSocial member",
      handle: emailPrefix ? `@${emailPrefix}` : `@${userId.slice(0, 12)}`,
    };
  } catch {
    throw new ChatError(
      "not_found",
      "That MoolSocial member is not available for Chat.",
      404,
    );
  }
}

function chatService(): ChatService {
  if (chatRuntimeService) return chatRuntimeService;
  chatRuntimeService = new ChatService(
    new FirestoreChatRepository(
      getFirestore(),
      undefined,
      new GoogleCloudStorageChatPhotoStore(getStorage().bucket()),
    ),
    resolveChatProfile,
  );
  return chatRuntimeService;
}

function requiredEnvironment(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required when YouTube owner access is enabled.`);
  }
  return value;
}

function encryptionKey(value: string, secretName: string): Buffer {
  const clean = value.trim();
  let decoded: Buffer;
  try {
    decoded = Buffer.from(clean, "base64url");
  } catch {
    throw new Error("YouTube token encryption key is invalid.");
  }
  if (decoded.byteLength !== 32) {
    throw new Error(
      `${secretName} must contain 32 base64url-encoded bytes.`,
    );
  }
  return decoded;
}

function service(): YouTubeProviderService {
  if (providerService) return providerService;
  const persistence = stores();
  const capabilities = createLiveCapabilities();
  const quota = new YouTubeQuotaGovernor(
    persistence.quota,
    { caps: readDevYouTubeQuotaCaps() },
  );
  const quotaPort = new YouTubeQuotaGovernorAdapter(quota);
  const transport = new FetchHttpTransport();
  const cache = new ProcessYouTubeCache();
  const dataClient = new YouTubeDataClient({
    transport,
    quota: quotaPort,
    cache,
    serverApiKey: youtubeServerApiKey.value(),
  });
  const sharedShortsCatalogue = new SharedShortsCatalogueCoordinator({
    store: new FirestoreSharedShortsCatalogueStore(persistence.database),
    loadPage: (requestId, pageToken) => dataClient.sharedCatalogueSearch(
      requestId,
      {
        query: sharedShortsCatalogueContract.query,
        regionCode: sharedShortsCatalogueContract.regionCode,
        maxResults: sharedShortsCatalogueContract.pageSize,
        ...(pageToken === undefined ? {} : { pageToken }),
      },
    ),
  });
  const previousKey = encryptionKey(
    youtubeTokenEncryptionKeyV1.value(),
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1",
  );
  const currentKey = encryptionKey(
    youtubeTokenEncryptionKeyV2.value(),
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2",
  );
  const refreshCipher = new Aes256GcmEnvelopeCipher(
    currentKey,
    "k2",
    "youtube-refresh-token",
  );
  const previousRefreshCipher = new Aes256GcmEnvelopeCipher(
    previousKey,
    "k1",
    "youtube-refresh-token",
  );
  const oauthVerifierCipher = new Aes256GcmEnvelopeCipher(
    currentKey,
    "k2",
    "youtube-oauth-verifier",
  );
  const uploadSessionCipher = new Aes256GcmEnvelopeCipher(
    currentKey,
    "k2",
    "youtube-upload-session",
  );
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeKeyring(
      refreshCipher,
      previousRefreshCipher,
    ),
    persistence.refreshTokens,
  );
  providerService = new YouTubeProviderService({
    capabilities,
    dataClient,
    sharedShortsCatalogue,
    publicDiscoveryClient: new YouTubePublicDiscoveryClient({
      transport,
      quota: quotaPort,
      cache,
      serverApiKey: youtubeServerApiKey.value(),
      enabled: () => capabilities.publicData,
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota: quotaPort }),
    transport,
    connections: persistence.connections,
    publications: persistence.publications,
    oauthAttempts: persistence.oauthAttempts,
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(),
    oauthVerifierCipher,
    uploadSessionCipher,
    oauthClientId: youtubeOauthClientId.value(),
    oauthClientSecret: youtubeOauthClientSecret.value(),
    oauthRedirectUri: requiredEnvironment("YOUTUBE_OAUTH_REDIRECT_URI"),
  });
  return providerService;
}

async function dispatchRegisteredAnalyticsReportingOperation(
  operation: Parameters<typeof dispatchAnalyticsReportingOperation>[0],
  body: Readonly<Record<string, unknown>>,
  userId: string,
  requestId: string,
): Promise<unknown> {
  const capabilities = readCapabilities();
  requireCapability(capabilities, "ownerAnalytics");
  const access = await service().ownerAnalyticsReportingAccess(
    userId,
    requestId,
  );
  const invocation: VerifiedOwnerInvocation = {
    ...access,
    auth: {
      verified: true,
      userId,
    },
    appCheck: {
      verified: true,
      replayProtected: true,
      replayId: requestId,
    },
  };
  const quota = new YouTubeQuotaGovernor(
    stores().quota,
    { caps: readDevYouTubeQuotaCaps() },
  );
  const clients = createAnalyticsReportingClients({
    transport: new FetchHttpTransport(),
    quota: new YouTubeQuotaGovernorAdapter(quota),
    replayProtection: new RouterConsumedAppCheckReplay(
      userId,
      requestId,
    ),
    idempotency: new FirestoreAnalyticsReportingIdempotency(
      stores().database,
      userId,
    ),
    enabled:
      capabilities.analyticsV2 === true &&
      capabilities.reportingV1 === true,
    monetaryMetricsEnabled: false,
  });
  return dispatchAnalyticsReportingOperation(
    operation,
    body,
    invocation,
    clients,
  );
}

function header(
  headers: Readonly<Record<string, string | string[] | undefined>>,
  name: string,
): string | undefined {
  const value = headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] : value;
}

function bodyObject(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A JSON request body is required.",
      400,
    );
  }
  return value as Record<string, unknown>;
}

function text(
  body: Record<string, unknown>,
  name: string,
  required = true,
): string | undefined {
  const value = body[name];
  if (value === undefined && !required) return undefined;
  if (typeof value !== "string" || !value.trim()) {
    throw new YouTubeProviderError(
      "bad_request",
      `${name} is required.`,
      400,
    );
  }
  return value;
}

function textArray(
  body: Record<string, unknown>,
  name: string,
): readonly string[] {
  const value = body[name];
  if (!Array.isArray(value) || !value.every((item) => typeof item === "string")) {
    throw new YouTubeProviderError(
      "bad_request",
      `${name} must be a list of text values.`,
      400,
    );
  }
  return value;
}

function publicActivityTypes(
  body: Record<string, unknown>,
): readonly YouTubePublicActivityType[] | undefined {
  if (body.eventTypes === undefined) return undefined;
  const values = textArray(body, "eventTypes");
  const allowed = new Set<YouTubePublicActivityType>([
    "upload",
    "like",
    "favorite",
    "playlistItem",
    "subscription",
  ]);
  if (
    values.length === 0 ||
    values.some(
      (value) => !allowed.has(value as YouTubePublicActivityType),
    )
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported public activity type is required.",
      400,
    );
  }
  return values as readonly YouTubePublicActivityType[];
}

function confirmedBoolean(
  body: Record<string, unknown>,
  name: string,
): boolean {
  if (typeof body[name] !== "boolean") {
    throw new YouTubeProviderError(
      "bad_request",
      `${name} must be confirmed.`,
      400,
    );
  }
  return body[name] as boolean;
}

function textAllowEmpty(
  body: Record<string, unknown>,
  name: string,
): string {
  const value = body[name];
  if (typeof value !== "string") {
    throw new YouTubeProviderError(
      "bad_request",
      `${name} must be text.`,
      400,
    );
  }
  return value;
}

function livePaging(body: Record<string, unknown>): {
  readonly pageToken?: string;
  readonly maxResults?: number;
} {
  const pageToken = text(body, "pageToken", false);
  const maxResults = optionalFiniteInteger(body, "maxResults");
  return {
    ...(pageToken === undefined ? {} : { pageToken }),
    ...(maxResults === undefined ? {} : { maxResults }),
  };
}

function liveChatIdentity(body: Record<string, unknown>): {
  readonly broadcastId: string;
  readonly liveChatId: string;
} {
  return {
    broadcastId: text(body, "broadcastId")!,
    liveChatId: text(body, "liveChatId")!,
  };
}

function liveBroadcastWrite(body: Record<string, unknown>): {
  readonly title: string;
  readonly description: string;
  readonly scheduledStartTime: string;
  readonly scheduledEndTime: string;
  readonly selfDeclaredMadeForKids: boolean;
  readonly enableEmbed: boolean;
  readonly enableDvr: boolean;
  readonly enableAutoStart: boolean;
  readonly enableAutoStop: boolean;
  readonly latencyPreference: "normal" | "low" | "ultraLow";
} {
  const latencyPreference = text(body, "latencyPreference")!;
  if (
    latencyPreference !== "normal" &&
    latencyPreference !== "low" &&
    latencyPreference !== "ultraLow"
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported live latency setting is required.",
      400,
    );
  }
  return {
    title: text(body, "title")!,
    description: textAllowEmpty(body, "description"),
    scheduledStartTime: text(body, "scheduledStartTime")!,
    scheduledEndTime: text(body, "scheduledEndTime")!,
    selfDeclaredMadeForKids: confirmedBoolean(
      body,
      "selfDeclaredMadeForKids",
    ),
    enableEmbed: confirmedBoolean(body, "enableEmbed"),
    enableDvr: confirmedBoolean(body, "enableDvr"),
    enableAutoStart: confirmedBoolean(body, "enableAutoStart"),
    enableAutoStop: confirmedBoolean(body, "enableAutoStop"),
    latencyPreference,
  };
}

function liveStreamWrite(body: Record<string, unknown>) {
  return {
    title: text(body, "title")!,
    description: textAllowEmpty(body, "description"),
    isReusable: confirmedBoolean(body, "isReusable"),
  };
}

function channelBrandingPatch(
  value: unknown,
): CreatorChannelBrandingPatch {
  const body = bodyObject(value);
  const allowed = [
    "country",
    "description",
    "defaultLanguage",
    "keywords",
    "trackingAnalyticsAccountId",
    "unsubscribedTrailer",
  ] as const;
  const patch: {
    -readonly [K in keyof CreatorChannelBrandingPatch]?:
      CreatorChannelBrandingPatch[K];
  } = {};
  for (const key of Object.keys(body)) {
    if (!allowed.includes(key as (typeof allowed)[number])) {
      throw new YouTubeProviderError(
        "bad_request",
        "Channel branding contains an unsupported field.",
        400,
      );
    }
  }
  for (const key of allowed) {
    const field = body[key];
    if (field === undefined) continue;
    if (field !== null && typeof field !== "string") {
      throw new YouTubeProviderError(
        "bad_request",
        `${key} must be text or null.`,
        400,
      );
    }
    patch[key] = field as string | null;
  }
  return patch;
}

function channelSection(
  value: unknown,
): CreatorChannelSectionInput {
  const body = bodyObject(value);
  const type = text(body, "type")!;
  const supported = [
    "allPlaylists",
    "completedEvents",
    "liveEvents",
    "multipleChannels",
    "multiplePlaylists",
    "popularUploads",
    "recentUploads",
    "singlePlaylist",
    "subscriptions",
    "upcomingEvents",
  ] as const;
  if (!supported.includes(type as (typeof supported)[number])) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported YouTube channel section type is required.",
      400,
    );
  }
  const title =
    body.title === undefined
      ? undefined
      : (() => {
          if (typeof body.title !== "string" || !body.title.trim()) {
            throw new YouTubeProviderError(
              "bad_request",
              "Channel section title is required.",
              400,
            );
          }
          return body.title;
        })();
  const playlistIds =
    body.playlistIds === undefined
      ? undefined
      : textArray(body, "playlistIds");
  const channelIds =
    body.channelIds === undefined
      ? undefined
      : textArray(body, "channelIds");
  return {
    type: type as CreatorChannelSectionInput["type"],
    position: finiteInteger(body, "position"),
    ...(title === undefined ? {} : { title }),
    ...(playlistIds === undefined ? {} : { playlistIds }),
    ...(channelIds === undefined ? {} : { channelIds }),
  };
}

function uploadMetadata(value: unknown): YouTubeUploadMetadata {
  const body = bodyObject(value);
  const title = text(body, "title");
  const description = text(body, "description", false) ?? "";
  const categoryId = text(body, "categoryId");
  const booleans = [
    "madeForKids",
    "containsSyntheticMedia",
    "containsPaidPromotion",
    "notifySubscribers",
  ] as const;
  for (const field of booleans) {
    if (typeof body[field] !== "boolean") {
      throw new YouTubeProviderError(
        "bad_request",
        `${field} must be confirmed.`,
        400,
      );
    }
  }
  return {
    title: title!,
    description,
    categoryId: categoryId!,
    madeForKids: body.madeForKids as boolean,
    containsSyntheticMedia: body.containsSyntheticMedia as boolean,
    containsPaidPromotion: body.containsPaidPromotion as boolean,
    notifySubscribers: body.notifySubscribers as boolean,
  };
}

function uploadFileIdentity(
  value: unknown,
): YouTubeUploadFileIdentityInput {
  const body = bodyObject(value);
  const algorithm = text(body, "algorithm");
  if (algorithm !== "sha256") {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid video file identity is required.",
      400,
    );
  }
  return {
    algorithm,
    digest: text(body, "digest")!,
    byteLength: finiteInteger(body, "byteLength"),
    contentType: text(body, "contentType")!,
  };
}

function localEmulatorBypass(): boolean {
  return (
    process.env.FUNCTIONS_EMULATOR === "true" &&
    process.env.MOOLSOCIAL_PROVIDER_ENV !== "dev"
  );
}

async function verifyApp(
  headers: Readonly<Record<string, string | string[] | undefined>>,
  consume = false,
): Promise<void> {
  if (localEmulatorBypass()) return;
  const token = header(headers, "x-firebase-appcheck");
  if (!token) {
    throw new YouTubeProviderError(
      "permission_denied",
      "App verification is required.",
      401,
    );
  }
  try {
    const verified = await getAppCheck().verifyToken(
      token,
      consume ? { consume: true } : undefined,
    );
    if (consume && verified.alreadyConsumed) {
      throw new YouTubeProviderError(
        "permission_denied",
        "App verification has expired. Try again.",
        401,
      );
    }
  } catch (error) {
    if (error instanceof YouTubeProviderError) throw error;
    throw new YouTubeProviderError(
      "permission_denied",
      "App verification is required.",
      401,
    );
  }
}

async function verifyPublicAuthApp(
  headers: Readonly<Record<string, string | string[] | undefined>>,
): Promise<void> {
  if (localEmulatorBypass()) return;
  const token = header(headers, "x-firebase-appcheck");
  if (!token) {
    throw new XPublicAuthError(
      "app_check_required",
      "App verification is required.",
      401,
      false,
    );
  }
  try {
    const verified = await getAppCheck().verifyToken(token, { consume: true });
    if (verified.alreadyConsumed) {
      throw new XPublicAuthError(
        "app_check_required",
        "App verification has expired. Try again.",
        401,
        true,
      );
    }
  } catch (error) {
    if (error instanceof XPublicAuthError) throw error;
    throw new XPublicAuthError(
      "app_check_required",
      "App verification is required.",
      401,
      false,
    );
  }
}

function assertPublicAuthBody(
  rawBody: unknown,
  contentType: string | undefined,
): void {
  if (!contentType || !/^application\/json(?:\s*;.*)?$/iu.test(contentType)) {
    throw new XPublicAuthError(
      "invalid_request",
      "A JSON request body is required.",
      415,
      false,
    );
  }
  if (
    !Buffer.isBuffer(rawBody) ||
    rawBody.byteLength === 0 ||
    rawBody.byteLength > X_PUBLIC_AUTH_MAX_REQUEST_BODY_BYTES
  ) {
    throw new XPublicAuthError(
      "invalid_request",
      "The authentication request body is invalid.",
      rawBody instanceof Uint8Array &&
        rawBody.byteLength > X_PUBLIC_AUTH_MAX_REQUEST_BODY_BYTES
        ? 413
        : 400,
      false,
    );
  }
}

async function userId(
  headers: Readonly<Record<string, string | string[] | undefined>>,
): Promise<string> {
  const authorization = header(headers, "authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw new YouTubeProviderError(
      "authentication_required",
      "Sign in to continue.",
      401,
    );
  }
  try {
    const decoded = await getAuth().verifyIdToken(
      authorization.slice("Bearer ".length),
    );
    return decoded.uid;
  } catch {
    throw new YouTubeProviderError(
      "authentication_required",
      "Sign in to continue.",
      401,
    );
  }
}

function requestId(
  headers: Readonly<Record<string, string | string[] | undefined>>,
): string {
  const supplied = header(headers, "x-request-id")?.trim();
  return supplied && /^[A-Za-z0-9._-]{1,128}$/.test(supplied)
    ? supplied
    : randomUUID();
}

function finiteInteger(
  body: Record<string, unknown>,
  name: string,
): number {
  const value = body[name];
  if (!Number.isSafeInteger(value)) {
    throw new YouTubeProviderError(
      "bad_request",
      `${name} must be a whole number.`,
      400,
    );
  }
  return value as number;
}

function optionalFiniteInteger(
  body: Record<string, unknown>,
  name: string,
): number | undefined {
  return body[name] === undefined ? undefined : finiteInteger(body, name);
}

function queryText(value: unknown): string | undefined {
  if (typeof value === "string" && value.trim()) return value.trim();
  return undefined;
}

export const youtubeProvider = onRequest(
  {
    region: "asia-south1",
    timeoutSeconds: 120,
    memory: "512MiB",
    minInstances: 0,
    maxInstances: 1,
    concurrency: 1,
    serviceAccount: youtubeProviderRuntimeServiceAccount,
    secrets: [
      youtubeServerApiKey,
      youtubeOauthClientId,
      youtubeOauthClientSecret,
      youtubeTokenEncryptionKeyV1,
      youtubeTokenEncryptionKeyV2,
    ],
  },
  async (request, response) => {
    const id = requestId(request.headers);
    response.setHeader("cache-control", "no-store");
    response.setHeader("x-request-id", id);
    try {
      if (request.method !== "POST") {
        throw new YouTubeProviderError(
          "bad_request",
          "Only POST requests are supported.",
          405,
        );
      }
      assertRawRequestBodyWithinLimit(
        request.rawBody,
        YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES,
      );
      const body = bodyObject(request.body);
      const operation = text(body, "operation")!;
      const consumesAppCheck =
        requiresReplayProtectedAppCheck(operation);
      await verifyApp(request.headers, consumesAppCheck);
      const ownerUserId = isAuthenticatedOwnerOperation(operation)
        ? await userId(request.headers)
        : undefined;
      let result: unknown;
      switch (operation) {
        case "capabilities":
          result = readCapabilities();
          break;
        case "publicMostPopular":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicMostPopular(
            id,
            text(body, "regionCode", false),
            text(body, "pageToken", false),
          );
          break;
        case "publicPlaylist":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicPlaylist(
            id,
            text(body, "playlistId")!,
            text(body, "pageToken", false),
          );
          break;
        case "publicSearch":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicSearch(
            id,
            text(body, "query")!,
            text(body, "pageToken", false),
          );
          break;
        case "publicShortsCatalogue":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicShortsCatalogue(id);
          break;
        case "publicVideoDetails":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicVideoDetails(
            id,
            textArray(body, "videoIds"),
          );
          break;
        case "publicBatchVideoStatistics":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicBatchVideoStatistics(
            id,
            textArray(body, "videoIds"),
          );
          break;
        case "publicChannelDetails":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicChannelDetails(
            id,
            text(body, "channelId")!,
          );
          break;
        case "publicChannelByHandle":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicChannelByHandle(
            id,
            text(body, "handle")!,
          );
          break;
        case "publicPlaylistDetails":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicPlaylistDetails(
            id,
            text(body, "playlistId")!,
          );
          break;
        case "publicChannelPlaylists": {
          requireCapability(readCapabilities(), "publicData");
          const pageToken = text(body, "pageToken", false);
          const maxResults = optionalFiniteInteger(body, "maxResults");
          result = await service().publicChannelPlaylists(id, {
            channelId: text(body, "channelId")!,
            ...(pageToken === undefined ? {} : { pageToken }),
            ...(maxResults === undefined ? {} : { maxResults }),
          });
          break;
        }
        case "publicRegions":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicRegions(id);
          break;
        case "publicLanguages":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicLanguages(id);
          break;
        case "publicVideoCategories":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicVideoCategories(
            id,
            text(body, "regionCode", false),
          );
          break;
        case "publicCommentThreads": {
          requireCapability(readCapabilities(), "publicData");
          const order = text(body, "order", false);
          const regionCode = text(body, "regionCode", false);
          const pageToken = text(body, "pageToken", false);
          const maxResults = optionalFiniteInteger(body, "maxResults");
          if (
            order !== undefined &&
            order !== "time" &&
            order !== "relevance"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported comment order is required.",
              400,
            );
          }
          result = await service().publicCommentThreads(id, {
            videoId: text(body, "videoId")!,
            ...(regionCode === undefined ? {} : { regionCode }),
            ...(pageToken === undefined ? {} : { pageToken }),
            ...(maxResults === undefined ? {} : { maxResults }),
            ...(order === undefined ? {} : { order }),
          });
          break;
        }
        case "publicCommentReplies": {
          requireCapability(readCapabilities(), "publicData");
          const regionCode = text(body, "regionCode", false);
          const pageToken = text(body, "pageToken", false);
          const maxResults = optionalFiniteInteger(body, "maxResults");
          result = await service().publicCommentReplies(id, {
            videoId: text(body, "videoId")!,
            threadId: text(body, "threadId")!,
            parentCommentId: text(body, "parentCommentId")!,
            ...(regionCode === undefined ? {} : { regionCode }),
            ...(pageToken === undefined ? {} : { pageToken }),
            ...(maxResults === undefined ? {} : { maxResults }),
          });
          break;
        }
        case "publicChannelActivities": {
          requireCapability(readCapabilities(), "publicData");
          const regionCode = text(body, "regionCode", false);
          const pageToken = text(body, "pageToken", false);
          const publishedAfter = text(body, "publishedAfter", false);
          const publishedBefore = text(body, "publishedBefore", false);
          const maxResults = optionalFiniteInteger(body, "maxResults");
          const eventTypes = publicActivityTypes(body);
          result = await service().publicChannelActivities(id, {
            channelId: text(body, "channelId")!,
            ...(regionCode === undefined ? {} : { regionCode }),
            ...(pageToken === undefined ? {} : { pageToken }),
            ...(publishedAfter === undefined ? {} : { publishedAfter }),
            ...(publishedBefore === undefined ? {} : { publishedBefore }),
            ...(maxResults === undefined ? {} : { maxResults }),
            ...(eventTypes === undefined ? {} : { eventTypes }),
          });
          break;
        }
        case "publicChannelSections":
          requireCapability(readCapabilities(), "publicData");
          result = await service().publicChannelSections(
            id,
            text(body, "channelId")!,
          );
          break;
        case "beginConnect": {
          const uid = ownerUserId!;
          const purpose = text(body, "purpose")!;
          if (
            purpose !== "readonly" &&
            purpose !== "write" &&
            purpose !== "creatorAssets" &&
            purpose !== "live" &&
            purpose !== "liveMemberships" &&
            purpose !== "upload" &&
            purpose !== "analytics"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported YouTube permission purpose is required.",
              400,
            );
          }
          requireConnectPurposeCapability(readCapabilities(), purpose);
          result = await service().beginConnect({
            userId: uid,
            purpose,
            ...(body.promptForConsent === undefined
              ? {}
              : { promptForConsent: body.promptForConsent === true }),
          });
          break;
        }
        case "completeConnect":
          result = await service().completeConnect({
            userId: ownerUserId!,
            state: text(body, "state")!,
            code: text(body, "code")!,
          });
          break;
        case "beginPrivateUpload":
          requireCapability(readCapabilities(), "privateUpload");
          result = await service().beginPrivateUpload({
            userId: ownerUserId!,
            requestId: id,
            idempotencyKey: text(body, "idempotencyKey")!,
            contentType: text(body, "contentType")!,
            contentLength: finiteInteger(body, "contentLength"),
            fileIdentity: uploadFileIdentity(body.fileIdentity),
            metadata: uploadMetadata(body.metadata),
          });
          break;
        case "reconcileUpload":
          requireCapability(readCapabilities(), "privateUpload");
          result = await service().reconcileUpload(
            ownerUserId!,
            id,
            text(body, "jobKey")!,
          );
          break;
        case "ownerVideos": {
          requireCapability(readCapabilities(), "ownerConnect");
          result = await service().ownerVideos(
            ownerUserId!,
            id,
            text(body, "pageToken", false),
            optionalFiniteInteger(body, "maxResults"),
          );
          break;
        }
        case "ownerSubscriptions": {
          requireCapability(readCapabilities(), "ownerConnect");
          const order = text(body, "order", false);
          if (
            order !== undefined &&
            order !== "alphabetical" &&
            order !== "relevance" &&
            order !== "unread"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported subscription order is required.",
              400,
            );
          }
          result = await service().ownerSubscriptions(
            ownerUserId!,
            id,
            text(body, "pageToken", false),
            optionalFiniteInteger(body, "maxResults"),
            order,
          );
          break;
        }
        case "ownerPlaylists": {
          requireCapability(readCapabilities(), "ownerConnect");
          result = await service().ownerPlaylists(
            ownerUserId!,
            id,
            text(body, "pageToken", false),
            optionalFiniteInteger(body, "maxResults"),
          );
          break;
        }
        case "ownerGetRating":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerGetRating(
            ownerUserId!,
            id,
            text(body, "videoId")!,
          );
          break;
        case "ownerSetRating": {
          requireCapability(readCapabilities(), "ownerActions");
          const rating = text(body, "rating")!;
          if (rating !== "like" && rating !== "dislike") {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported YouTube rating is required.",
              400,
            );
          }
          result = await service().ownerSetRating(
            ownerUserId!,
            id,
            text(body, "videoId")!,
            rating,
          );
          break;
        }
        case "ownerRemoveRating":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerRemoveRating(
            ownerUserId!,
            id,
            text(body, "videoId")!,
          );
          break;
        case "ownerCreateComment":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerCreateComment(
            ownerUserId!,
            id,
            text(body, "videoId")!,
            text(body, "text")!,
          );
          break;
        case "ownerCreateReply":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerCreateReply(
            ownerUserId!,
            id,
            text(body, "parentCommentId")!,
            text(body, "text")!,
          );
          break;
        case "ownerUpdateComment":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerUpdateComment(
            ownerUserId!,
            id,
            text(body, "commentId")!,
            text(body, "text")!,
          );
          break;
        case "ownerDeleteComment":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerDeleteComment(
            ownerUserId!,
            id,
            text(body, "commentId")!,
          );
          break;
        case "ownerSetCommentModeration": {
          requireCapability(readCapabilities(), "ownerActions");
          const moderationStatus = text(body, "moderationStatus")!;
          if (
            moderationStatus !== "published" &&
            moderationStatus !== "heldForReview" &&
            moderationStatus !== "rejected"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported moderation status is required.",
              400,
            );
          }
          if (
            body.banAuthor !== undefined &&
            typeof body.banAuthor !== "boolean"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "banAuthor must be confirmed.",
              400,
            );
          }
          result = await service().ownerSetCommentModeration(
            ownerUserId!,
            id,
            text(body, "commentId")!,
            moderationStatus,
            body.banAuthor as boolean | undefined,
          );
          break;
        }
        case "ownerSubscribe":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerSubscribe(
            ownerUserId!,
            id,
            text(body, "channelId")!,
          );
          break;
        case "ownerUnsubscribe":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerUnsubscribe(
            ownerUserId!,
            id,
            text(body, "subscriptionId")!,
          );
          break;
        case "ownerCreatePlaylist": {
          requireCapability(readCapabilities(), "ownerActions");
          const privacyStatus = text(body, "privacyStatus")!;
          if (
            privacyStatus !== "private" &&
            privacyStatus !== "unlisted" &&
            privacyStatus !== "public"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported playlist privacy state is required.",
              400,
            );
          }
          result = await service().ownerCreatePlaylist(
            ownerUserId!,
            id,
            text(body, "title")!,
            text(body, "description", false) ?? "",
            privacyStatus,
          );
          break;
        }
        case "ownerUpdatePlaylist": {
          requireCapability(readCapabilities(), "ownerActions");
          const privacyStatus = text(body, "privacyStatus")!;
          if (
            privacyStatus !== "private" &&
            privacyStatus !== "unlisted" &&
            privacyStatus !== "public"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported playlist privacy state is required.",
              400,
            );
          }
          result = await service().ownerUpdatePlaylist(
            ownerUserId!,
            id,
            text(body, "playlistId")!,
            text(body, "title")!,
            text(body, "description", false) ?? "",
            privacyStatus,
          );
          break;
        }
        case "ownerDeletePlaylist":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerDeletePlaylist(
            ownerUserId!,
            id,
            text(body, "playlistId")!,
          );
          break;
        case "ownerCreatePlaylistItem":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerCreatePlaylistItem(
            ownerUserId!,
            id,
            text(body, "playlistId")!,
            text(body, "videoId")!,
            optionalFiniteInteger(body, "position"),
          );
          break;
        case "ownerUpdatePlaylistItem":
        case "ownerReorderPlaylistItem":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerReorderPlaylistItem(
            ownerUserId!,
            id,
            text(body, "playlistItemId")!,
            finiteInteger(body, "position"),
          );
          break;
        case "ownerDeletePlaylistItem":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerDeletePlaylistItem(
            ownerUserId!,
            id,
            text(body, "playlistItemId")!,
          );
          break;
        case "ownerUpdateVideoMetadata": {
          requireCapability(readCapabilities(), "ownerActions");
          const tags =
            body.tags === undefined ? undefined : textArray(body, "tags");
          result = await service().ownerUpdateVideoMetadata(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              title: text(body, "title")!,
              description: text(body, "description", false) ?? "",
              categoryId: text(body, "categoryId")!,
              ...(tags === undefined ? {} : { tags }),
            },
          );
          break;
        }
        case "ownerDeleteVideo":
          requireCapability(readCapabilities(), "ownerActions");
          result = await service().ownerDeleteVideo(
            ownerUserId!,
            id,
            text(body, "videoId")!,
            text(body, "confirmVideoId")!,
          );
          break;
        case "creatorBeginThumbnailSet":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginThumbnailSet(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
            },
          );
          break;
        case "creatorListCaptions":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorListCaptions(
            ownerUserId!,
            id,
            text(body, "videoId")!,
          );
          break;
        case "creatorDownloadCaption": {
          requireCapability(readCapabilities(), "creatorAssets");
          const format = text(body, "format")!;
          if (
            format !== "sbv" &&
            format !== "scc" &&
            format !== "srt" &&
            format !== "ttml" &&
            format !== "vtt"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported caption download format is required.",
              400,
            );
          }
          const translatedLanguage = text(
            body,
            "translatedLanguage",
            false,
          );
          result = await service().creatorDownloadCaption(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              captionId: text(body, "captionId")!,
              format,
              ...(translatedLanguage === undefined
                ? {}
                : { translatedLanguage }),
            },
          );
          break;
        }
        case "creatorBeginCaptionInsert":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginCaptionInsert(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              language: text(body, "language")!,
              name:
                body.name === undefined
                  ? ""
                  : (() => {
                      if (typeof body.name !== "string") {
                        throw new YouTubeProviderError(
                          "bad_request",
                          "name must be text.",
                          400,
                        );
                      }
                      return body.name;
                    })(),
              isDraft: confirmedBoolean(body, "isDraft"),
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
            },
          );
          break;
        case "creatorUpdateCaptionDraft":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorUpdateCaptionDraft(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              captionId: text(body, "captionId")!,
              isDraft: confirmedBoolean(body, "isDraft"),
            },
          );
          break;
        case "creatorBeginCaptionReplacement":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginCaptionReplacement(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              captionId: text(body, "captionId")!,
              isDraft: confirmedBoolean(body, "isDraft"),
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
            },
          );
          break;
        case "creatorDeleteCaption":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorDeleteCaption(
            ownerUserId!,
            id,
            text(body, "videoId")!,
            text(body, "captionId")!,
          );
          break;
        case "creatorUpdateChannelBranding":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorUpdateChannelBranding(
            ownerUserId!,
            id,
            channelBrandingPatch(body.patch),
          );
          break;
        case "creatorListChannelSections":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorListChannelSections(
            ownerUserId!,
            id,
          );
          break;
        case "creatorInsertChannelSection":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorInsertChannelSection(
            ownerUserId!,
            id,
            channelSection(body.section),
          );
          break;
        case "creatorUpdateChannelSection":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorUpdateChannelSection(
            ownerUserId!,
            id,
            text(body, "sectionId")!,
            channelSection(body.section),
          );
          break;
        case "creatorDeleteChannelSection":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorDeleteChannelSection(
            ownerUserId!,
            id,
            text(body, "sectionId")!,
          );
          break;
        case "creatorBeginChannelBannerInsert":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginChannelBannerInsert(
            ownerUserId!,
            id,
            {
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
              width: finiteInteger(body, "width"),
              height: finiteInteger(body, "height"),
            },
          );
          break;
        case "creatorApplyChannelBanner":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorApplyChannelBanner(
            ownerUserId!,
            id,
            text(body, "bannerExternalUrl")!,
          );
          break;
        case "creatorBeginWatermarkSet": {
          requireCapability(readCapabilities(), "creatorAssets");
          const offsetFrom = text(body, "offsetFrom")!;
          const corner = text(body, "corner")!;
          if (offsetFrom !== "start" && offsetFrom !== "end") {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported watermark offset is required.",
              400,
            );
          }
          if (
            corner !== "topLeft" &&
            corner !== "topRight" &&
            corner !== "bottomLeft" &&
            corner !== "bottomRight"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported watermark position is required.",
              400,
            );
          }
          result = await service().creatorBeginWatermarkSet(
            ownerUserId!,
            id,
            {
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
              width: finiteInteger(body, "width"),
              height: finiteInteger(body, "height"),
              offsetMs: finiteInteger(body, "offsetMs"),
              durationMs: finiteInteger(body, "durationMs"),
              offsetFrom,
              corner,
            },
          );
          break;
        }
        case "creatorUnsetWatermark":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorUnsetWatermark(
            ownerUserId!,
            id,
          );
          break;
        case "creatorListPlaylistImages": {
          requireCapability(readCapabilities(), "creatorAssets");
          const pageToken = text(body, "pageToken", false);
          const maxResults = optionalFiniteInteger(body, "maxResults");
          result = await service().creatorListPlaylistImages(
            ownerUserId!,
            id,
            {
              playlistId: text(body, "playlistId")!,
              ...(pageToken === undefined ? {} : { pageToken }),
              ...(maxResults === undefined ? {} : { maxResults }),
            },
          );
          break;
        }
        case "creatorBeginPlaylistImageInsert":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginPlaylistImageInsert(
            ownerUserId!,
            id,
            {
              playlistId: text(body, "playlistId")!,
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
              width: finiteInteger(body, "width"),
              height: finiteInteger(body, "height"),
            },
          );
          break;
        case "creatorBeginPlaylistImageUpdate":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorBeginPlaylistImageUpdate(
            ownerUserId!,
            id,
            {
              playlistId: text(body, "playlistId")!,
              playlistImageId: text(body, "playlistImageId")!,
              contentType: text(body, "contentType")!,
              contentLength: finiteInteger(body, "contentLength"),
              width: finiteInteger(body, "width"),
              height: finiteInteger(body, "height"),
            },
          );
          break;
        case "creatorDeletePlaylistImage":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorDeletePlaylistImage(
            ownerUserId!,
            id,
            text(body, "playlistId")!,
            text(body, "playlistImageId")!,
          );
          break;
        case "creatorListVideoAbuseReasons":
          requireCapability(readCapabilities(), "creatorAssets");
          result = await service().creatorListVideoAbuseReasons(
            ownerUserId!,
            id,
            text(body, "language", false),
          );
          break;
        case "creatorReportVideoAbuse": {
          requireCapability(readCapabilities(), "creatorAssets");
          const secondaryReasonId = text(
            body,
            "secondaryReasonId",
            false,
          );
          const comments =
            body.comments === undefined
              ? undefined
              : (() => {
                  if (typeof body.comments !== "string") {
                    throw new YouTubeProviderError(
                      "bad_request",
                      "comments must be text.",
                      400,
                    );
                  }
                  return body.comments;
                })();
          const language = text(body, "language", false);
          result = await service().creatorReportVideoAbuse(
            ownerUserId!,
            id,
            {
              videoId: text(body, "videoId")!,
              reasonId: text(body, "reasonId")!,
              confirmVideoId: text(body, "confirmVideoId")!,
              confirmReasonId: text(body, "confirmReasonId")!,
              ...(secondaryReasonId === undefined
                ? {}
                : { secondaryReasonId }),
              ...(comments === undefined ? {} : { comments }),
              ...(language === undefined ? {} : { language }),
            },
          );
          break;
        }
        case "creatorInsertAbuseReport": {
          requireCapability(readCapabilities(), "creatorAssets");
          const description =
            body.description === undefined
              ? undefined
              : textAllowEmpty(body, "description");
          const related = body.relatedEntities;
          let relatedEntities:
            | readonly { readonly typeId: string; readonly id: string }[]
            | undefined;
          if (related !== undefined) {
            if (!Array.isArray(related)) {
              throw new YouTubeProviderError(
                "bad_request",
                "relatedEntities must be a list.",
                400,
              );
            }
            relatedEntities = related.map((value) => {
              const entity = bodyObject(value);
              return {
                typeId: text(entity, "typeId")!,
                id: text(entity, "id")!,
              };
            });
          }
          result = await service().creatorInsertAbuseReport(
            ownerUserId!,
            id,
            {
              subjectTypeId: text(body, "subjectTypeId")!,
              subjectId: text(body, "subjectId")!,
              abuseTypeIds: textArray(body, "abuseTypeIds"),
              confirmSubjectTypeId: text(
                body,
                "confirmSubjectTypeId",
              )!,
              confirmSubjectId: text(body, "confirmSubjectId")!,
              confirmAbuseTypeIds: textArray(
                body,
                "confirmAbuseTypeIds",
              ),
              ...(description === undefined ? {} : { description }),
              ...(relatedEntities === undefined
                ? {}
                : { relatedEntities }),
            },
          );
          break;
        }
        case "liveListBroadcasts": {
          requireCapability(readCapabilities(), "live");
          const status = text(body, "status")!;
          if (
            status !== "all" &&
            status !== "active" &&
            status !== "upcoming" &&
            status !== "completed"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live broadcast filter is required.",
              400,
            );
          }
          result = await service().liveListBroadcasts(
            ownerUserId!,
            id,
            { status, ...livePaging(body) },
          );
          break;
        }
        case "liveInsertBroadcast":
          requireCapability(readCapabilities(), "live");
          result = await service().liveInsertBroadcast(
            ownerUserId!,
            id,
            liveBroadcastWrite(body),
          );
          break;
        case "liveUpdateBroadcast":
          requireCapability(readCapabilities(), "live");
          result = await service().liveUpdateBroadcast(
            ownerUserId!,
            id,
            {
              broadcastId: text(body, "broadcastId")!,
              ...liveBroadcastWrite(body),
            },
          );
          break;
        case "liveBindBroadcast":
          requireCapability(readCapabilities(), "live");
          result = await service().liveBindBroadcast(
            ownerUserId!,
            id,
            {
              broadcastId: text(body, "broadcastId")!,
              streamId: text(body, "streamId")!,
              confirmBroadcastId: text(body, "confirmBroadcastId")!,
              confirmStreamId: text(body, "confirmStreamId")!,
            },
          );
          break;
        case "liveTransitionBroadcast": {
          requireCapability(readCapabilities(), "live");
          const targetStatus = text(body, "targetStatus")!;
          const confirmTargetStatus = text(body, "confirmTargetStatus")!;
          if (
            targetStatus !== "testing" &&
            targetStatus !== "live" &&
            targetStatus !== "complete"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live broadcast transition is required.",
              400,
            );
          }
          if (
            confirmTargetStatus !== "testing" &&
            confirmTargetStatus !== "live" &&
            confirmTargetStatus !== "complete"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "The live broadcast transition must be confirmed.",
              400,
            );
          }
          result = await service().liveTransitionBroadcast(
            ownerUserId!,
            id,
            {
              broadcastId: text(body, "broadcastId")!,
              targetStatus,
              confirmBroadcastId: text(body, "confirmBroadcastId")!,
              confirmTargetStatus,
            },
          );
          break;
        }
        case "liveDeleteBroadcast":
          requireCapability(readCapabilities(), "live");
          result = await service().liveDeleteBroadcast(
            ownerUserId!,
            id,
            {
              broadcastId: text(body, "broadcastId")!,
              confirmBroadcastId: text(body, "confirmBroadcastId")!,
            },
          );
          break;
        case "liveListStreams":
          requireCapability(readCapabilities(), "live");
          result = await service().liveListStreams(
            ownerUserId!,
            id,
            livePaging(body),
          );
          break;
        case "liveInsertStream": {
          requireCapability(readCapabilities(), "live");
          const resolution = text(body, "resolution")!;
          const frameRate = text(body, "frameRate")!;
          const ingestionType = text(body, "ingestionType")!;
          if (
            resolution !== "240p" &&
            resolution !== "360p" &&
            resolution !== "480p" &&
            resolution !== "720p" &&
            resolution !== "1080p" &&
            resolution !== "1440p" &&
            resolution !== "2160p" &&
            resolution !== "variable"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live stream resolution is required.",
              400,
            );
          }
          if (
            frameRate !== "30fps" &&
            frameRate !== "60fps" &&
            frameRate !== "variable"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live stream frame rate is required.",
              400,
            );
          }
          if (
            ingestionType !== "rtmp" &&
            ingestionType !== "dash" &&
            ingestionType !== "webrtc" &&
            ingestionType !== "hls"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live stream ingestion type is required.",
              400,
            );
          }
          result = await service().liveInsertStream(
            ownerUserId!,
            id,
            {
              ...liveStreamWrite(body),
              resolution,
              frameRate,
              ingestionType,
            },
          );
          break;
        }
        case "liveUpdateStream":
          requireCapability(readCapabilities(), "live");
          result = await service().liveUpdateStream(
            ownerUserId!,
            id,
            {
              streamId: text(body, "streamId")!,
              ...liveStreamWrite(body),
            },
          );
          break;
        case "liveDeleteStream":
          requireCapability(readCapabilities(), "live");
          result = await service().liveDeleteStream(
            ownerUserId!,
            id,
            {
              streamId: text(body, "streamId")!,
              confirmStreamId: text(body, "confirmStreamId")!,
            },
          );
          break;
        case "liveListChatMessages":
          requireCapability(readCapabilities(), "live");
          result = await service().liveListChatMessages(
            ownerUserId!,
            id,
            { ...liveChatIdentity(body), ...livePaging(body) },
          );
          break;
        case "liveInsertChatText":
          requireCapability(readCapabilities(), "live");
          result = await service().liveInsertChatText(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              messageText: text(body, "messageText")!,
            },
          );
          break;
        case "liveInsertChatPoll":
          requireCapability(readCapabilities(), "live");
          result = await service().liveInsertChatPoll(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              questionText: text(body, "questionText")!,
              options: textArray(body, "options"),
            },
          );
          break;
        case "liveCloseChatPoll": {
          requireCapability(readCapabilities(), "live");
          const confirmStatus = text(body, "confirmStatus")!;
          if (confirmStatus !== "closed") {
            throw new YouTubeProviderError(
              "bad_request",
              "Closing the active live poll must be confirmed.",
              400,
            );
          }
          result = await service().liveCloseChatPoll(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              pollMessageId: text(body, "pollMessageId")!,
              confirmPollMessageId: text(
                body,
                "confirmPollMessageId",
              )!,
              confirmStatus,
            },
          );
          break;
        }
        case "liveDeleteChatMessage":
          requireCapability(readCapabilities(), "live");
          result = await service().liveDeleteChatMessage(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              messageId: text(body, "messageId")!,
              confirmMessageId: text(body, "confirmMessageId")!,
            },
          );
          break;
        case "liveListModerators":
          requireCapability(readCapabilities(), "live");
          result = await service().liveListModerators(
            ownerUserId!,
            id,
            { ...liveChatIdentity(body), ...livePaging(body) },
          );
          break;
        case "liveInsertModerator":
          requireCapability(readCapabilities(), "live");
          result = await service().liveInsertModerator(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              moderatorChannelId: text(body, "moderatorChannelId")!,
            },
          );
          break;
        case "liveDeleteModerator":
          requireCapability(readCapabilities(), "live");
          result = await service().liveDeleteModerator(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              moderatorId: text(body, "moderatorId")!,
              confirmModeratorId: text(body, "confirmModeratorId")!,
            },
          );
          break;
        case "liveInsertBan": {
          requireCapability(readCapabilities(), "live");
          const type = text(body, "type")!;
          if (type !== "permanent" && type !== "temporary") {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported live chat ban type is required.",
              400,
            );
          }
          const durationSeconds = optionalFiniteInteger(
            body,
            "durationSeconds",
          );
          result = await service().liveInsertBan(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              bannedChannelId: text(body, "bannedChannelId")!,
              type,
              ...(durationSeconds === undefined
                ? {}
                : { durationSeconds }),
            },
          );
          break;
        }
        case "liveDeleteBan":
          requireCapability(readCapabilities(), "live");
          result = await service().liveDeleteBan(
            ownerUserId!,
            id,
            {
              ...liveChatIdentity(body),
              banId: text(body, "banId")!,
              confirmBanId: text(body, "confirmBanId")!,
            },
          );
          break;
        case "liveListSuperChatEvents": {
          requireCapability(readCapabilities(), "live");
          const language = text(body, "language", false);
          result = await service().liveListSuperChatEvents(
            ownerUserId!,
            id,
            {
              ...livePaging(body),
              ...(language === undefined ? {} : { language }),
            },
          );
          break;
        }
        case "liveListMembers": {
          requireCapability(readCapabilities(), "live");
          const mode = text(body, "mode")!;
          if (mode !== "all_current" && mode !== "updates") {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported membership list mode is required.",
              400,
            );
          }
          const memberChannelId = text(
            body,
            "memberChannelId",
            false,
          );
          const levelId = text(body, "levelId", false);
          result = await service().liveListMembers(
            ownerUserId!,
            id,
            {
              mode,
              ...livePaging(body),
              ...(memberChannelId === undefined
                ? {}
                : { memberChannelId }),
              ...(levelId === undefined ? {} : { levelId }),
            },
          );
          break;
        }
        case "liveListMembershipLevels":
          requireCapability(readCapabilities(), "live");
          result = await service().liveListMembershipLevels(
            ownerUserId!,
            id,
          );
          break;
        case "analyticsV2ListGroups":
        case "analyticsV2CreateGroup":
        case "analyticsV2UpdateGroup":
        case "analyticsV2DeleteGroup":
        case "analyticsV2ListGroupItems":
        case "analyticsV2InsertGroupItem":
        case "analyticsV2DeleteGroupItem":
        case "analyticsV2QueryReport":
        case "reportingV1ListReportTypes":
        case "reportingV1CreateJob":
        case "reportingV1ListJobs":
        case "reportingV1GetJob":
        case "reportingV1DeleteJob":
        case "reportingV1ListReports":
        case "reportingV1GetReport":
        case "reportingV1DownloadReportMedia":
          result = await dispatchRegisteredAnalyticsReportingOperation(
            operation,
            body,
            ownerUserId!,
            id,
          );
          break;
        case "ownerAnalyticsPreset": {
          requireCapability(readCapabilities(), "ownerAnalytics");
          const preset = text(body, "preset")!;
          if (
            preset !== "overview" &&
            preset !== "topVideos" &&
            preset !== "countries" &&
            preset !== "trafficSources" &&
            preset !== "devicesOs" &&
            preset !== "videoRetention"
          ) {
            throw new YouTubeProviderError(
              "bad_request",
              "A supported analytics preset is required.",
              400,
            );
          }
          const videoId = text(body, "videoId", false);
          const startIndex = optionalFiniteInteger(body, "startIndex");
          result = await service().ownerAnalyticsPreset(
            ownerUserId!,
            id,
            {
              preset,
              startDate: text(body, "startDate")!,
              endDate: text(body, "endDate")!,
              ...(videoId === undefined ? {} : { videoId }),
              ...(startIndex === undefined ? {} : { startIndex }),
            },
          );
          break;
        }
        case "ownerConnectionStatus":
          requireOwnerConnectionStatusCapability(readCapabilities());
          result = await service().connectionStatus(
            ownerUserId!,
            id,
          );
          break;
        case "disconnect": {
          const uid = ownerUserId!;
          await auditStore().record({
            userId: uid,
            eventType: "connection.disconnect_requested",
            requestId: id,
            detail: { localDeletionRequired: true },
            occurredAt: new Date().toISOString(),
          });
          try {
            const outcome = await service().disconnect(uid);
            await auditStore().record({
              userId: uid,
              eventType: "connection.disconnect_completed",
              requestId: id,
              detail: {
                localCredentialDeleted: true,
                localPublicationJobsDeleted: true,
                localOAuthAttemptsDeleted: true,
                providerRevocationConfirmed:
                  outcome.providerRevocationConfirmed,
              },
              occurredAt: new Date().toISOString(),
            });
            result = outcome;
          } catch (error) {
            try {
              await auditStore().record({
                userId: uid,
                eventType: "connection.disconnect_failed",
                requestId: id,
                detail: {
                  code:
                    error instanceof YouTubeProviderError
                      ? error.code
                      : "internal",
                },
                occurredAt: new Date().toISOString(),
              });
            } catch (auditError) {
              logger.error(
                "YouTube disconnect failure audit could not be recorded.",
                redactSensitiveData({
                  requestId: id,
                  auditError,
                }),
              );
            }
            throw error;
          }
          break;
        }
        default:
          throw new YouTubeProviderError(
            "bad_request",
            "Unsupported YouTube operation.",
            400,
          );
      }
      logger.info(
        "YouTube provider request completed.",
        redactSensitiveData({ operation, requestId: id }),
      );
      response.status(200).json({ ok: true, data: result });
    } catch (error) {
      const providerError =
        error instanceof YouTubeProviderError ||
        error instanceof YouTubeAnalyticsReportingError
          ? error
          : new YouTubeProviderError(
              "internal",
              "The YouTube request could not be completed.",
              500,
              false,
            );
      logger.error(
        "YouTube provider request failed.",
        redactSensitiveData({
          requestId: id,
          error,
          code: providerError.code,
          providerReason:
            error instanceof YouTubeProviderError
              ? error.providerReason
              : undefined,
        }),
      );
      response.status(providerError.httpStatus).json({
        ok: false,
        error: {
          code: providerError.code,
          message: providerError.message,
          retryable: providerError.retryable,
        },
      });
    }
  },
);

export const moolSocialContent = onRequest(
  {
    region: "asia-south1",
    timeoutSeconds: 120,
    memory: "512MiB",
    minInstances: 0,
    maxInstances: 4,
    concurrency: 20,
    serviceAccount: socialContentRuntimeServiceAccount,
  },
  async (request, response) => {
    const id = requestId(request.headers);
    response.setHeader("cache-control", "no-store");
    response.setHeader("x-content-type-options", "nosniff");
    response.setHeader("x-request-id", id);
    try {
      if (request.method !== "POST") {
        throw new SocialContentError(
          "bad_request",
          "Only POST requests are supported.",
          405,
        );
      }
      if (request.rawBody.byteLength > 29 * 1024 * 1024) {
        throw new SocialContentError(
          "payload_too_large",
          "The selected images are too large to publish.",
          413,
        );
      }
      if (
        request.body === null ||
        typeof request.body !== "object" ||
        Array.isArray(request.body)
      ) {
        throw new SocialContentError(
          "bad_request",
          "A valid request body is required.",
          400,
        );
      }
      const body = request.body as Record<string, unknown>;
      const operation = typeof body.operation === "string"
        ? body.operation.trim()
        : "";
      const mutation = operation === "publish" || operation === "interact" || operation === "reply" || operation === "follow";
      const authenticated = operation !== "feed" && operation !== "comments" && operation !== "author";
      const ownerUserId = await verifySocialInvocation(
        request.headers,
        {
          verifyAppCheck: async (token, consume) =>
            getAppCheck().verifyToken(
              token,
              consume ? { consume: true } : undefined,
            ),
          verifyIdToken: async (token) => getAuth().verifyIdToken(token),
        },
        mutation,
        authenticated,
      );
      if (authenticated && ownerUserId === undefined) {
        throw new SocialContentError(
          "authentication_required",
          "Sign in to continue.",
          401,
        );
      }
      const result = operation === "publish"
        ? await socialService().publish(ownerUserId!, body)
        : operation === "feed"
          ? await socialService().feed(ownerUserId, body)
          : operation === "comments"
            ? await socialService().comments(body)
          : operation === "author"
            ? await socialService().author(ownerUserId, body)
          : operation === "interact"
            ? await socialService().interact(ownerUserId!, body)
            : operation === "reply"
              ? await socialService().reply(ownerUserId!, body)
            : operation === "follow"
              ? await socialService().follow(ownerUserId!, body)
            : (() => {
                throw new SocialContentError(
                  "bad_request",
                  "Unsupported Social content operation.",
                  400,
                );
              })();
      logger.info("MoolSocial content request completed.", {
        operation,
        requestId: id,
      });
      response.status(200).json({ ok: true, data: result });
    } catch (error) {
      const contentError = error instanceof SocialContentError
        ? error
        : new SocialContentError(
            "internal",
            "The MoolSocial content request could not be completed.",
            500,
            true,
          );
      logger.error("MoolSocial content request failed.", {
        requestId: id,
        code: contentError.code,
        errorType: error instanceof Error ? error.name : typeof error,
      });
      response.status(contentError.httpStatus).json({
        ok: false,
        error: {
          code: contentError.code,
          message: contentError.message,
          retryable: contentError.retryable,
        },
      });
    }
  },
);

export const moolSocialChat = onRequest(
  {
    region: "asia-south1",
    timeoutSeconds: 60,
    memory: "256MiB",
    minInstances: 0,
    maxInstances: 4,
    concurrency: 40,
    serviceAccount: socialContentRuntimeServiceAccount,
  },
  async (request, response) => {
    const id = requestId(request.headers);
    response.setHeader("cache-control", "no-store");
    response.setHeader("x-content-type-options", "nosniff");
    response.setHeader("x-request-id", id);
    try {
      if (request.method !== "POST") {
        throw new ChatError(
          "bad_request",
          "Only POST requests are supported.",
          405,
        );
      }
      if (request.rawBody.byteLength > 32 * 1024) {
        throw new ChatError(
          "payload_too_large",
          "The Chat request is too large.",
          413,
        );
      }
      if (
        request.body === null ||
        typeof request.body !== "object" ||
        Array.isArray(request.body)
      ) {
        throw new ChatError(
          "bad_request",
          "A valid request body is required.",
          400,
        );
      }
      const body = request.body as Record<string, unknown>;
      const operation = typeof body.operation === "string"
        ? body.operation.trim()
        : "";
      const mutation = operation === "createDirectThread" ||
        operation === "sendMessage" ||
        operation === "preparePhotoUpload" ||
        operation === "sendPhotoMessage" ||
        operation === "setReaction" ||
        operation === "forwardMessage" ||
        operation === "markThreadRead";
      const ownerUserId = await verifySocialInvocation(
        request.headers,
        {
          verifyAppCheck: async (token, consume) =>
            getAppCheck().verifyToken(
              token,
              consume ? { consume: true } : undefined,
            ),
          verifyIdToken: async (token) => getAuth().verifyIdToken(token),
        },
        mutation,
        true,
      );
      if (!ownerUserId) {
        throw new ChatError("authentication_required", "Sign in to use Chat.", 401);
      }
      const result = operation === "listThreads"
        ? await chatService().listThreads(ownerUserId, body)
        : operation === "listMessages"
          ? await chatService().listMessages(ownerUserId, body)
          : operation === "createDirectThread"
            ? await chatService().createDirectThread(ownerUserId, body)
            : operation === "sendMessage"
            ? await chatService().sendMessage(ownerUserId, body)
            : operation === "preparePhotoUpload"
              ? await chatService().preparePhotoUpload(ownerUserId, body)
              : operation === "sendPhotoMessage"
                ? await chatService().sendPhotoMessage(ownerUserId, body)
              : operation === "setReaction"
                ? await chatService().setReaction(ownerUserId, body)
                : operation === "forwardMessage"
                  ? await chatService().forwardMessage(ownerUserId, body)
                : operation === "markThreadRead"
                  ? await chatService().markThreadRead(ownerUserId, body)
              : (() => {
                  throw new ChatError(
                    "bad_request",
                    "Unsupported Chat operation.",
                    400,
                  );
                })();
      logger.info("MoolSocial Chat request completed.", {
        operation,
        requestId: id,
      });
      response.status(200).json({ ok: true, data: result });
    } catch (error) {
      const chatError = error instanceof ChatError || error instanceof SocialContentError
        ? error
        : new ChatError(
            "internal",
            "Chat could not complete that request.",
            500,
            true,
          );
      logger.error("MoolSocial Chat request failed.", {
        requestId: id,
        code: chatError.code,
        errorType: error instanceof Error ? error.name : typeof error,
      });
      response.status(chatError.httpStatus).json({
        ok: false,
        error: {
          code: chatError.code,
          message: chatError.message,
          retryable: chatError.retryable,
        },
      });
    }
  },
);

export const youtubeOAuthCallback = onRequest(
  {
    region: "asia-south1",
    timeoutSeconds: 120,
    memory: "512MiB",
    minInstances: 0,
    maxInstances: 1,
    concurrency: 1,
    serviceAccount: youtubeProviderRuntimeServiceAccount,
    secrets: [
      youtubeServerApiKey,
      youtubeOauthClientId,
      youtubeOauthClientSecret,
      youtubeTokenEncryptionKeyV1,
      youtubeTokenEncryptionKeyV2,
    ],
  },
  async (request, response) => {
    const id = requestId(request.headers);
    response.setHeader("cache-control", "no-store");
    response.setHeader("referrer-policy", "no-referrer");
    response.setHeader("x-content-type-options", "nosniff");
    response.setHeader("x-request-id", id);
    try {
      if (request.method !== "GET") {
        throw new YouTubeProviderError(
          "bad_request",
          "Only GET requests are supported.",
          405,
        );
      }
      if (queryText(request.query.error)) {
        throw new YouTubeProviderError(
          "permission_denied",
          "YouTube was not connected.",
          400,
        );
      }
      const state = queryText(request.query.state);
      const code = queryText(request.query.code);
      if (!state || !code) {
        throw new YouTubeProviderError(
          "bad_request",
          "The YouTube authorization response is incomplete.",
          400,
        );
      }
      await service().completeConnectFromCallback(state, code);
      logger.info(
        "YouTube OAuth callback completed.",
        redactSensitiveData({ requestId: id }),
      );
      const returnPage = youtubeOAuthReturnPage("connected");
      response.setHeader(
        "content-security-policy",
        returnPage.contentSecurityPolicy,
      );
      response
        .status(200)
        .type("text/html")
        .send(returnPage.html);
    } catch (error) {
      const providerError =
        error instanceof YouTubeProviderError
          ? error
          : new YouTubeProviderError(
              "internal",
              "YouTube could not be connected.",
              500,
              false,
            );
      logger.error(
        "YouTube OAuth callback failed.",
        redactSensitiveData({
          requestId: id,
          error,
          code: providerError.code,
        }),
      );
      const returnPage = youtubeOAuthReturnPage("notConnected");
      response.setHeader(
        "content-security-policy",
        returnPage.contentSecurityPolicy,
      );
      response
        .status(providerError.httpStatus)
        .type("text/html")
        .send(returnPage.html);
    }
  },
);

export const moolSocialPublicAuth = onRequest(
  {
    region: "asia-south1",
    serviceAccount: publicAuthRuntimeServiceAccount,
    timeoutSeconds: 45,
    memory: "256MiB",
    minInstances: 0,
    maxInstances: 5,
    concurrency: 10,
    secrets: [
      xSubjectProjectionKey,
      instagramClientSecret,
      instagramSubjectProjectionKey,
      facebookAppSecret,
      youtubeServerApiKey,
      youtubeOauthClientId,
      youtubeOauthClientSecret,
      youtubeTokenEncryptionKeyV1,
      youtubeTokenEncryptionKeyV2,
    ],
  },
  async (request, response) => {
    const id = requestId(request.headers);
    let operation = "invalid";
    response.setHeader("cache-control", "no-store");
    response.setHeader("pragma", "no-cache");
    response.setHeader("x-content-type-options", "nosniff");
    response.setHeader("x-request-id", id);
    try {
      if (
        request.method === "GET" &&
        (
          request.path === "/meta/data-deletion/status" ||
          request.path === "/api/meta/data-deletion/status"
        )
      ) {
        operation = "meta_data_deletion_status";
        const confirmationCode = queryText(
          request.query.confirmation_code,
        );
        const status = await metaAccountErasureCoordinator().status(
          confirmationCode ?? "",
        );
        response.status(200).json({ ok: true, data: status });
        return;
      }
      if (request.method !== "POST") {
        response.setHeader("allow", "GET, POST");
        throw new XPublicAuthError(
          "invalid_request",
          "Only POST requests are supported.",
          405,
          false,
        );
      }
      if (
        request.path === "/instagram/deauthorize" ||
        request.path === "/instagram/data-deletion"
      ) {
        operation = request.path === "/instagram/deauthorize"
          ? "instagram_deauthorize"
          : "instagram_data_deletion";
        const callback = await instagramMetaCallbackService().execute(
          request.path,
          request.rawBody,
          header(request.headers, "content-type"),
        );
        logger.info("Instagram Meta callback completed.", {
          requestId: id,
          operation,
        });
        if (callback.operation === "data_deletion") {
          response.status(200).json({
            url: callback.statusUrl,
            confirmation_code: callback.confirmationCode,
          });
        } else {
          response.status(200).json({ ok: true });
        }
        return;
      }
      if (
        request.path === "/facebook/deauthorize" ||
        request.path === "/facebook/data-deletion"
      ) {
        operation = request.path === "/facebook/deauthorize"
          ? "facebook_deauthorize"
          : "facebook_data_deletion";
        const callback = await facebookMetaCallbackService().execute(
          request.path,
          request.rawBody,
          header(request.headers, "content-type"),
        );
        logger.info("Facebook Meta callback completed.", {
          requestId: id,
          operation,
        });
        if (callback.operation === "data_deletion") {
          response.status(200).json({
            url: callback.statusUrl,
            confirmation_code: callback.confirmationCode,
          });
        } else {
          response.status(200).json({ ok: true });
        }
        return;
      }
      assertPublicAuthBody(
        request.rawBody,
        header(request.headers, "content-type"),
      );
      await verifyPublicAuthApp(request.headers);

      let result:
        | Awaited<ReturnType<XPublicAuthBroker["execute"]>>
        | Awaited<ReturnType<InstagramPublicAuthBroker["execute"]>>;
      if (request.path === "/x/begin" || request.path === "/x/complete") {
        const parsed = parseXPublicAuthRequest(request.path, request.body);
        operation = `x_${parsed.operation}`;
        result = await xPublicAuthBroker().execute(parsed);
      } else if (
        request.path === "/instagram/begin" ||
        request.path === "/instagram/complete"
      ) {
        const parsed = parseInstagramPublicAuthRequest(
          request.path,
          request.body,
        );
        operation = `instagram_${parsed.operation}`;
        result = await instagramPublicAuthBroker().execute(parsed);
      } else {
        throw new XPublicAuthError(
          "invalid_request",
          "The authentication request is invalid.",
          404,
          false,
        );
      }
      const data = result.operation === "begin"
        ? {
            authorizationUrl: result.authorizationUrl,
            expiresAt: result.expiresAt,
          }
        : { firebaseCustomToken: result.firebaseCustomToken };
      logger.info("Public authentication request completed.", {
        requestId: id,
        operation,
      });
      response.status(200).json({ ok: true, data });
    } catch (error) {
      const authError =
        error instanceof XPublicAuthError ||
        error instanceof InstagramPublicAuthError ||
        error instanceof InstagramMetaCallbackError ||
        error instanceof FacebookMetaCallbackError ||
        error instanceof MetaAccountErasureError
          ? error
          : new XPublicAuthError(
              "internal",
              "The authentication request could not be completed.",
              500,
              true,
            );
      logger.error("Public authentication request failed.", {
        requestId: id,
        operation,
        code: authError.code,
      });
      response.status(authError.httpStatus).json({
        ok: false,
        error: {
          code: authError.code,
          message: authError.message,
          retryable: authError.retryable,
        },
      });
    }
  },
);
