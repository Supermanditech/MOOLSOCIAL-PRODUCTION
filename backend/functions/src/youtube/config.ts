import { YouTubeProviderError } from "./errors.js";
import {
  YOUTUBE_INCREMENTAL_SCOPE_SETS,
  type YouTubeIncrementalScope,
} from "./oauth.js";
import type {
  YouTubeCapability,
  YouTubeRuntimeCapabilities,
} from "./types.js";

export const PRIVATE_DEV_YOUTUBE_PROJECT_ID = "moolsocial-dev-503018";
export const PRIVATE_DEV_YOUTUBE_MAX_PROOF_MILLISECONDS = 30 * 60 * 1000;
export const ACCEPTED_PUBLIC_REVIEW_MODE = "accepted";

const proofProfileFlag = {
  publicData: "YOUTUBE_PUBLIC_DATA_ENABLED",
  ownerConnect: "YOUTUBE_OWNER_CONNECT_ENABLED",
  ownerActions: "YOUTUBE_OWNER_ACTIONS_ENABLED",
  creatorAssets: "YOUTUBE_CREATOR_ASSETS_ENABLED",
  live: "YOUTUBE_LIVE_ENABLED",
  privateUpload: "YOUTUBE_PRIVATE_UPLOAD_ENABLED",
  ownerAnalytics: "YOUTUBE_OWNER_ANALYTICS_ENABLED",
} as const;

type YouTubeProofProfile = keyof typeof proofProfileFlag;

function enabled(value: string | undefined): boolean {
  return value?.trim().toLowerCase() === "true";
}

function environment(value: string | undefined): "local" | "dev" {
  return value?.trim().toLowerCase() === "dev" ? "dev" : "local";
}

function firebaseConfigProjectId(value: string | undefined): string | undefined {
  if (!value?.trim()) return undefined;
  try {
    const parsed: unknown = JSON.parse(value);
    if (
      typeof parsed === "object" &&
      parsed !== null &&
      "projectId" in parsed &&
      typeof parsed.projectId === "string"
    ) {
      return parsed.projectId.trim() || undefined;
    }
  } catch {
    return undefined;
  }
  return undefined;
}

function runtimeProjectId(env: NodeJS.ProcessEnv): string | undefined {
  return (
    env.GCLOUD_PROJECT?.trim() ||
    env.GOOGLE_CLOUD_PROJECT?.trim() ||
    firebaseConfigProjectId(env.FIREBASE_CONFIG)
  );
}

/**
 * Live provider flags are valid only in the founder-authorized Dev project.
 * The emulator may exercise the same contract only when the explicit Dev
 * provider profile is selected; the default local profile stays fail-closed.
 */
export function isPrivateDevYouTubeRuntime(
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  if (environment(env.MOOLSOCIAL_PROVIDER_ENV) !== "dev") return false;
  if (enabled(env.FUNCTIONS_EMULATOR)) return true;
  return runtimeProjectId(env) === PRIVATE_DEV_YOUTUBE_PROJECT_ID;
}

function activeProofProfile(
  env: NodeJS.ProcessEnv,
  now: Date,
): YouTubeProofProfile | undefined {
  const profile = env.YOUTUBE_PROOF_PROFILE?.trim();
  if (
    profile !== "publicData" &&
    profile !== "ownerConnect" &&
    profile !== "ownerActions" &&
    profile !== "creatorAssets" &&
    profile !== "live" &&
    profile !== "privateUpload" &&
    profile !== "ownerAnalytics"
  ) {
    return undefined;
  }

  const expiryTransport = env.YOUTUBE_PROOF_EXPIRES_AT?.trim();
  const expiryMatch = expiryTransport?.match(
    /^utc:(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)$/,
  );
  if (!expiryMatch) {
    return undefined;
  }
  const expiry = expiryMatch[1];
  if (!expiry) return undefined;
  const expiryMilliseconds = Date.parse(expiry);
  if (!Number.isFinite(expiryMilliseconds)) return undefined;
  if (
    new Date(expiryMilliseconds).toISOString().replace(".000Z", "Z") !==
    expiry
  ) {
    return undefined;
  }
  const remaining = expiryMilliseconds - now.getTime();
  if (
    remaining <= 0 ||
    remaining > PRIVATE_DEV_YOUTUBE_MAX_PROOF_MILLISECONDS
  ) {
    return undefined;
  }

  const enabledProfiles = Object.entries(proofProfileFlag)
    .filter(([, flag]) => enabled(env[flag]))
    .map(([name]) => name);
  if (enabledProfiles.length !== 1 || enabledProfiles[0] !== profile) {
    return undefined;
  }
  return profile;
}

function acceptedPublicReviewActive(env: NodeJS.ProcessEnv): boolean {
  if (
    env.YOUTUBE_PUBLIC_DATA_REVIEW_MODE?.trim() !==
    ACCEPTED_PUBLIC_REVIEW_MODE
  ) {
    return false;
  }
  if (
    env.YOUTUBE_PROOF_PROFILE?.trim() ||
    env.YOUTUBE_PROOF_EXPIRES_AT?.trim()
  ) {
    return false;
  }

  const enabledProfiles = Object.entries(proofProfileFlag)
    .filter(([, flag]) => enabled(env[flag]))
    .map(([name]) => name);
  return enabledProfiles.length === 1 && enabledProfiles[0] === "publicData";
}

export function readCapabilities(
  env: NodeJS.ProcessEnv = process.env,
  now: Date = new Date(),
): YouTubeRuntimeCapabilities {
  const privateDevRuntime = isPrivateDevYouTubeRuntime(env);
  const reviewModePresent =
    env.YOUTUBE_PUBLIC_DATA_REVIEW_MODE !== undefined;
  const acceptedPublicReview =
    privateDevRuntime && acceptedPublicReviewActive(env);
  const proofProfile = privateDevRuntime && !reviewModePresent
    ? activeProofProfile(env, now)
    : undefined;
  return {
    environment: environment(env.MOOLSOCIAL_PROVIDER_ENV),
    publicData:
      acceptedPublicReview || proofProfile === "publicData",
    ownerConnect: proofProfile === "ownerConnect",
    ownerActions: proofProfile === "ownerActions",
    creatorAssets: proofProfile === "creatorAssets",
    live: proofProfile === "live",
    privateUpload: proofProfile === "privateUpload",
    ownerAnalytics: proofProfile === "ownerAnalytics",
    analyticsV2: proofProfile === "ownerAnalytics",
    reportingV1: proofProfile === "ownerAnalytics",
    publicOrUnlistedUpload: false,
  };
}

/**
 * Returns one stable capability object whose properties are re-evaluated on
 * every access. A warm Functions instance must therefore fail closed at the
 * exact proof expiry instead of retaining the construction-time snapshot.
 */
export function createLiveCapabilities(
  env: NodeJS.ProcessEnv = process.env,
  clock: () => Date = () => new Date(),
): YouTubeRuntimeCapabilities {
  const current = (): YouTubeRuntimeCapabilities =>
    readCapabilities(env, clock());
  return {
    get environment() {
      return current().environment;
    },
    get publicData() {
      return current().publicData;
    },
    get ownerConnect() {
      return current().ownerConnect;
    },
    get ownerActions() {
      return current().ownerActions === true;
    },
    get creatorAssets() {
      return current().creatorAssets === true;
    },
    get live() {
      return current().live === true;
    },
    get privateUpload() {
      return current().privateUpload;
    },
    get ownerAnalytics() {
      return current().ownerAnalytics;
    },
    get analyticsV2() {
      return current().analyticsV2 === true;
    },
    get reportingV1() {
      return current().reportingV1 === true;
    },
    get publicOrUnlistedUpload() {
      return false as const;
    },
  };
}

export function requireCapability(
  capabilities: YouTubeRuntimeCapabilities,
  capability: YouTubeCapability,
): void {
  if (!capabilities[capability]) {
    throw new YouTubeProviderError(
      "capability_disabled",
      "This YouTube capability is not enabled in the private Dev environment.",
      503,
      false,
    );
  }
}

export function connectCapabilityForPurpose(
  purpose: YouTubeIncrementalScope,
): YouTubeCapability {
  switch (purpose) {
    case "readonly":
      return "ownerConnect";
    case "write":
      return "ownerActions";
    case "creatorAssets":
      return "creatorAssets";
    case "live":
    case "liveMemberships":
      return "live";
    case "upload":
      return "privateUpload";
    case "analytics":
      return "ownerAnalytics";
  }
}

export function requireConnectPurposeCapability(
  capabilities: YouTubeRuntimeCapabilities,
  purpose: YouTubeIncrementalScope,
): void {
  requireCapability(capabilities, connectCapabilityForPurpose(purpose));
}

export function requireOwnerConnectionStatusCapability(
  capabilities: YouTubeRuntimeCapabilities,
): void {
  const ownerCapabilityAvailable = [
    capabilities.ownerConnect,
    capabilities.ownerActions,
    capabilities.creatorAssets,
    capabilities.live,
    capabilities.privateUpload,
    capabilities.ownerAnalytics,
  ].some((enabled) => enabled === true);
  if (!ownerCapabilityAvailable) {
    throw new YouTubeProviderError(
      "capability_disabled",
      "This YouTube capability is not enabled in the private Dev environment.",
      503,
      false,
    );
  }
}

function normalizedScopeSet(
  scopes: readonly string[],
): readonly string[] {
  return [...new Set(scopes.map((scope) => scope.trim()).filter(Boolean))]
    .sort();
}

function sameScopeSet(
  first: readonly string[],
  second: readonly string[],
): boolean {
  const normalizedFirst = normalizedScopeSet(first);
  const normalizedSecond = normalizedScopeSet(second);
  return (
    normalizedFirst.length === normalizedSecond.length &&
    normalizedFirst.every(
      (scope, index) => scope === normalizedSecond[index],
    )
  );
}

/**
 * OAuth completion has no client-supplied purpose. It therefore derives the
 * required proof capability only from the server-persisted, one-time attempt.
 * Unknown or incomplete scope sets fail closed before any token exchange.
 */
export function requireOAuthAttemptCapability(
  capabilities: YouTubeRuntimeCapabilities,
  requestedScopes: readonly string[],
): YouTubeIncrementalScope {
  for (const purpose of [
    "readonly",
    "write",
    "creatorAssets",
    "live",
    "liveMemberships",
    "upload",
    "analytics",
  ] as const) {
    if (
      sameScopeSet(
        requestedScopes,
        YOUTUBE_INCREMENTAL_SCOPE_SETS[purpose],
      )
    ) {
      requireConnectPurposeCapability(capabilities, purpose);
      return purpose;
    }
  }
  throw new YouTubeProviderError(
    "permission_denied",
    "The YouTube authorization request is invalid.",
    403,
    false,
  );
}
