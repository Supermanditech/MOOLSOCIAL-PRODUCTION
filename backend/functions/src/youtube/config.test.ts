import assert from "node:assert/strict";
import test from "node:test";

import {
  ACCEPTED_PUBLIC_REVIEW_MODE,
  PRIVATE_DEV_YOUTUBE_MAX_PROOF_MILLISECONDS,
  PRIVATE_DEV_YOUTUBE_PROJECT_ID,
  connectCapabilityForPurpose,
  createLiveCapabilities,
  isPrivateDevYouTubeRuntime,
  readCapabilities,
  requireCapability,
  requireConnectPurposeCapability,
  requireOwnerConnectionStatusCapability,
  requireOAuthAttemptCapability,
} from "./config.js";
import { YouTubeProviderError } from "./errors.js";
import {
  YOUTUBE_ANALYTICS_READONLY_SCOPE,
  YOUTUBE_FORCE_SSL_SCOPE,
  YOUTUBE_MANAGE_SCOPE,
  YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE,
  YOUTUBE_READONLY_SCOPE,
  YOUTUBE_UPLOAD_SCOPE,
} from "./oauth.js";

const requestedFlags: NodeJS.ProcessEnv = {
  YOUTUBE_PUBLIC_DATA_ENABLED: "true",
  YOUTUBE_OWNER_CONNECT_ENABLED: "true",
  YOUTUBE_OWNER_ACTIONS_ENABLED: "true",
  YOUTUBE_CREATOR_ASSETS_ENABLED: "true",
  YOUTUBE_LIVE_ENABLED: "true",
  YOUTUBE_PRIVATE_UPLOAD_ENABLED: "true",
  YOUTUBE_OWNER_ANALYTICS_ENABLED: "true",
};
const now = new Date("2026-07-25T00:00:00Z");

function proofEnvironment(
  profile:
    | "publicData"
    | "ownerConnect"
    | "socialAuthRuntime"
    | "ownerActions"
    | "creatorAssets"
    | "live"
    | "privateUpload"
    | "ownerAnalytics",
  expiry = "2026-07-25T00:30:00Z",
): NodeJS.ProcessEnv {
  const flag = {
    publicData: "YOUTUBE_PUBLIC_DATA_ENABLED",
    ownerConnect: "YOUTUBE_OWNER_CONNECT_ENABLED",
    socialAuthRuntime: "YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED",
    ownerActions: "YOUTUBE_OWNER_ACTIONS_ENABLED",
    creatorAssets: "YOUTUBE_CREATOR_ASSETS_ENABLED",
    live: "YOUTUBE_LIVE_ENABLED",
    privateUpload: "YOUTUBE_PRIVATE_UPLOAD_ENABLED",
    ownerAnalytics: "YOUTUBE_OWNER_ANALYTICS_ENABLED",
  }[profile];
  return {
    MOOLSOCIAL_PROVIDER_ENV: "dev",
    GCLOUD_PROJECT: PRIVATE_DEV_YOUTUBE_PROJECT_ID,
    YOUTUBE_PROOF_PROFILE: profile,
    YOUTUBE_PROOF_EXPIRES_AT: `utc:${expiry}`,
    [flag]: "true",
  };
}

test("provider capabilities default to disabled", () => {
  assert.deepEqual(readCapabilities({}), {
    environment: "local",
    publicData: false,
    ownerConnect: false,
    ownerActions: false,
    creatorAssets: false,
    live: false,
    privateUpload: false,
    ownerAnalytics: false,
    analyticsV2: false,
    reportingV1: false,
    publicOrUnlistedUpload: false,
  });
});

test("owner connection status requires one active owner capability", () => {
  for (const profile of [
    "ownerConnect",
    "ownerActions",
    "creatorAssets",
    "live",
    "privateUpload",
    "ownerAnalytics",
  ] as const) {
    assert.doesNotThrow(() =>
      requireOwnerConnectionStatusCapability(
        readCapabilities(proofEnvironment(profile), now),
      ),
    );
  }
  for (const capabilities of [
    readCapabilities({}, now),
    readCapabilities(proofEnvironment("publicData"), now),
  ]) {
    assert.throws(
      () => requireOwnerConnectionStatusCapability(capabilities),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "capability_disabled",
    );
  }
});

test("individual flags cannot activate without the explicit Dev profile", () => {
  assert.equal(isPrivateDevYouTubeRuntime(requestedFlags), false);
  assert.deepEqual(readCapabilities(requestedFlags), {
    environment: "local",
    publicData: false,
    ownerConnect: false,
    ownerActions: false,
    creatorAssets: false,
    live: false,
    privateUpload: false,
    ownerAnalytics: false,
    analyticsV2: false,
    reportingV1: false,
    publicOrUnlistedUpload: false,
  });
});

test("one supervised profile activates only inside its server proof window", () => {
  const expected = {
    publicData: "publicData",
    ownerConnect: "ownerConnect",
    ownerActions: "ownerActions",
    creatorAssets: "creatorAssets",
    live: "live",
    privateUpload: "privateUpload",
    ownerAnalytics: "ownerAnalytics",
  } as const;
  for (const [profile, capability] of Object.entries(expected)) {
    const result = readCapabilities(
      proofEnvironment(profile as keyof typeof expected),
      now,
    );
    assert.equal(result[capability], true);
    assert.equal(
      [
        result.publicData,
        result.ownerConnect,
        result.ownerActions,
        result.creatorAssets,
        result.live,
        result.privateUpload,
        result.ownerAnalytics,
      ].filter((value) => value === true).length,
      1,
    );
    assert.equal(
      result.analyticsV2,
      profile === "ownerAnalytics",
    );
    assert.equal(
      result.reportingV1,
      profile === "ownerAnalytics",
    );
    assert.equal(result.publicOrUnlistedUpload, false);
  }
});

test("social auth runtime exposes only public data and channel connection", () => {
  const result = readCapabilities(
    proofEnvironment("socialAuthRuntime"),
    now,
  );
  assert.deepEqual(result, {
    environment: "dev",
    publicData: true,
    ownerConnect: true,
    ownerActions: false,
    creatorAssets: false,
    live: false,
    privateUpload: false,
    ownerAnalytics: false,
    analyticsV2: false,
    reportingV1: false,
    publicOrUnlistedUpload: false,
  });
  assert.deepEqual(
    readCapabilities(
      {
        ...proofEnvironment("socialAuthRuntime"),
        YOUTUBE_OWNER_CONNECT_ENABLED: "true",
      },
      now,
    ),
    {
      environment: "dev",
      publicData: false,
      ownerConnect: false,
      ownerActions: false,
      creatorAssets: false,
      live: false,
      privateUpload: false,
      ownerAnalytics: false,
      analyticsV2: false,
      reportingV1: false,
      publicOrUnlistedUpload: false,
    },
  );
});

test("accepted public review keeps only public data live in exact Dev", () => {
  const result = readCapabilities({
    MOOLSOCIAL_PROVIDER_ENV: "dev",
    GCLOUD_PROJECT: PRIVATE_DEV_YOUTUBE_PROJECT_ID,
    YOUTUBE_PUBLIC_DATA_REVIEW_MODE: ACCEPTED_PUBLIC_REVIEW_MODE,
    YOUTUBE_PUBLIC_DATA_ENABLED: "true",
    YOUTUBE_OWNER_CONNECT_ENABLED: "false",
    YOUTUBE_OWNER_ACTIONS_ENABLED: "false",
    YOUTUBE_CREATOR_ASSETS_ENABLED: "false",
    YOUTUBE_LIVE_ENABLED: "false",
    YOUTUBE_PRIVATE_UPLOAD_ENABLED: "false",
    YOUTUBE_OWNER_ANALYTICS_ENABLED: "false",
  });

  assert.deepEqual(result, {
    environment: "dev",
    publicData: true,
    ownerConnect: false,
    ownerActions: false,
    creatorAssets: false,
    live: false,
    privateUpload: false,
    ownerAnalytics: false,
    analyticsV2: false,
    reportingV1: false,
    publicOrUnlistedUpload: false,
  });
});

test("accepted public review fails closed on every ambiguous boundary", () => {
  const accepted = {
    MOOLSOCIAL_PROVIDER_ENV: "dev",
    GCLOUD_PROJECT: PRIVATE_DEV_YOUTUBE_PROJECT_ID,
    YOUTUBE_PUBLIC_DATA_REVIEW_MODE: ACCEPTED_PUBLIC_REVIEW_MODE,
    YOUTUBE_PUBLIC_DATA_ENABLED: "true",
    YOUTUBE_OWNER_CONNECT_ENABLED: "false",
    YOUTUBE_OWNER_ACTIONS_ENABLED: "false",
    YOUTUBE_CREATOR_ASSETS_ENABLED: "false",
    YOUTUBE_LIVE_ENABLED: "false",
    YOUTUBE_PRIVATE_UPLOAD_ENABLED: "false",
    YOUTUBE_OWNER_ANALYTICS_ENABLED: "false",
  };
  for (const unsafe of [
    {
      ...accepted,
      GCLOUD_PROJECT: "moolsocial-staging-503018",
    },
    {
      ...accepted,
      YOUTUBE_PUBLIC_DATA_REVIEW_MODE: "true",
    },
    {
      ...accepted,
      YOUTUBE_PROOF_PROFILE: "publicData",
      YOUTUBE_PROOF_EXPIRES_AT: "utc:2026-07-25T00:30:00Z",
    },
    {
      ...accepted,
      YOUTUBE_OWNER_CONNECT_ENABLED: "true",
    },
  ]) {
    assert.equal(readCapabilities(unsafe).publicData, false);
  }
});

test("OAuth purposes are gated by their owning supervised capability", () => {
  assert.equal(connectCapabilityForPurpose("readonly"), "ownerConnect");
  assert.equal(connectCapabilityForPurpose("write"), "ownerActions");
  assert.equal(
    connectCapabilityForPurpose("creatorAssets"),
    "creatorAssets",
  );
  assert.equal(connectCapabilityForPurpose("live"), "live");
  assert.equal(connectCapabilityForPurpose("liveMemberships"), "live");
  assert.equal(connectCapabilityForPurpose("upload"), "privateUpload");
  assert.equal(connectCapabilityForPurpose("analytics"), "ownerAnalytics");

  assert.doesNotThrow(() =>
    requireConnectPurposeCapability(
      readCapabilities(proofEnvironment("privateUpload"), now),
      "upload",
    ),
  );
  assert.throws(
    () =>
      requireConnectPurposeCapability(
        readCapabilities(proofEnvironment("ownerConnect"), now),
        "upload",
      ),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "capability_disabled",
  );
});

test("OAuth completion derives capability only from a valid readonly-rooted scope set", () => {
  const uploadCapabilities = readCapabilities(
    proofEnvironment("privateUpload"),
    now,
  );
  assert.equal(
    requireOAuthAttemptCapability(uploadCapabilities, [
      YOUTUBE_UPLOAD_SCOPE,
      YOUTUBE_READONLY_SCOPE,
      YOUTUBE_READONLY_SCOPE,
    ]),
    "upload",
  );
  assert.equal(
    requireOAuthAttemptCapability(
      readCapabilities(proofEnvironment("ownerAnalytics"), now),
      [YOUTUBE_READONLY_SCOPE, YOUTUBE_ANALYTICS_READONLY_SCOPE],
    ),
    "analytics",
  );
  assert.equal(
    requireOAuthAttemptCapability(
      readCapabilities(proofEnvironment("ownerActions"), now),
      [
        YOUTUBE_READONLY_SCOPE,
        YOUTUBE_FORCE_SSL_SCOPE,
      ],
    ),
    "write",
  );
  assert.equal(
    requireOAuthAttemptCapability(
      readCapabilities(proofEnvironment("creatorAssets"), now),
      [YOUTUBE_FORCE_SSL_SCOPE],
    ),
    "creatorAssets",
  );
  assert.equal(
    requireOAuthAttemptCapability(
      readCapabilities(proofEnvironment("live"), now),
      [YOUTUBE_MANAGE_SCOPE],
    ),
    "live",
  );
  assert.equal(
    requireOAuthAttemptCapability(
      readCapabilities(proofEnvironment("live"), now),
      [YOUTUBE_MEMBERSHIPS_CREATOR_SCOPE],
    ),
    "liveMemberships",
  );
  for (const invalidScopes of [
    [YOUTUBE_UPLOAD_SCOPE],
    [YOUTUBE_ANALYTICS_READONLY_SCOPE],
    [
      YOUTUBE_READONLY_SCOPE,
      YOUTUBE_UPLOAD_SCOPE,
      YOUTUBE_ANALYTICS_READONLY_SCOPE,
    ],
    [YOUTUBE_READONLY_SCOPE, "https://www.googleapis.com/auth/unknown"],
  ]) {
    assert.throws(
      () =>
        requireOAuthAttemptCapability(
          uploadCapabilities,
          invalidScopes,
        ),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "permission_denied",
    );
  }
});

test("proof profiles fail closed outside the exact private Dev project", () => {
  const wrongProject = readCapabilities({
    ...proofEnvironment("publicData"),
    GCLOUD_PROJECT: "moolsocial-staging-503018",
  }, now);
  assert.deepEqual(wrongProject, {
    environment: "dev",
    publicData: false,
    ownerConnect: false,
    ownerActions: false,
    creatorAssets: false,
    live: false,
    privateUpload: false,
    ownerAnalytics: false,
    analyticsV2: false,
    reportingV1: false,
    publicOrUnlistedUpload: false,
  });
});

test("missing malformed expired and overlong proof windows stay disabled", () => {
  const cases = [
    {
      ...proofEnvironment("publicData"),
      YOUTUBE_PROOF_EXPIRES_AT: undefined,
    },
    proofEnvironment("publicData", "not-a-time"),
    proofEnvironment("publicData", "2026-02-31T00:30:00Z"),
    proofEnvironment("publicData", "2026-07-25T00:00:00Z"),
    proofEnvironment("publicData", "2026-07-25T00:30:01Z"),
  ];
  for (const environment of cases) {
    assert.equal(readCapabilities(environment, now).publicData, false);
  }
  assert.equal(PRIVATE_DEV_YOUTUBE_MAX_PROOF_MILLISECONDS, 1_800_000);
});

test("a warm capability view fails closed at the exact proof expiry", () => {
  let current = new Date("2026-07-25T00:29:59Z");
  const capabilities = createLiveCapabilities(
    proofEnvironment("publicData"),
    () => current,
  );

  assert.equal(capabilities.publicData, true);
  assert.doesNotThrow(() => requireCapability(capabilities, "publicData"));

  current = new Date("2026-07-25T00:30:00Z");

  assert.equal(capabilities.publicData, false);
  assert.throws(
    () => requireCapability(capabilities, "publicData"),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "capability_disabled",
  );
});

test("mismatched or multiple requested capabilities stay disabled", () => {
  const mismatched = {
    ...proofEnvironment("publicData"),
    YOUTUBE_PROOF_PROFILE: "ownerConnect",
  };
  assert.equal(readCapabilities(mismatched, now).publicData, false);
  assert.equal(readCapabilities(mismatched, now).ownerConnect, false);

  const multiple = {
    ...proofEnvironment("publicData"),
    YOUTUBE_OWNER_CONNECT_ENABLED: "true",
  };
  assert.equal(readCapabilities(multiple, now).publicData, false);
  assert.equal(readCapabilities(multiple, now).ownerConnect, false);
});

test("runtime project identity can come from standard Google or Firebase metadata", () => {
  assert.equal(
    isPrivateDevYouTubeRuntime({
      MOOLSOCIAL_PROVIDER_ENV: "dev",
      GOOGLE_CLOUD_PROJECT: PRIVATE_DEV_YOUTUBE_PROJECT_ID,
    }),
    true,
  );
  assert.equal(
    isPrivateDevYouTubeRuntime({
      MOOLSOCIAL_PROVIDER_ENV: "dev",
      FIREBASE_CONFIG: JSON.stringify({
        projectId: PRIVATE_DEV_YOUTUBE_PROJECT_ID,
      }),
    }),
    true,
  );
  assert.equal(
    isPrivateDevYouTubeRuntime({
      MOOLSOCIAL_PROVIDER_ENV: "dev",
      FIREBASE_CONFIG: "{not-json",
    }),
    false,
  );
});

test("emulator proof requires the explicit Dev profile", () => {
  assert.equal(
    isPrivateDevYouTubeRuntime({
      FUNCTIONS_EMULATOR: "true",
      MOOLSOCIAL_PROVIDER_ENV: "dev",
    }),
    true,
  );
  assert.equal(
    isPrivateDevYouTubeRuntime({
      FUNCTIONS_EMULATOR: "true",
      MOOLSOCIAL_PROVIDER_ENV: "local",
    }),
    false,
  );
});
