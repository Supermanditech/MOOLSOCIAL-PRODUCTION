import assert from "node:assert/strict";
import test from "node:test";

import {
  DEFAULT_DEV_YOUTUBE_WEBSUB_REFRESH_DAILY_CAP,
  YOUTUBE_APPROVED_CHANNEL_REFRESH_DEFAULT_ENABLED,
  YOUTUBE_WEBSUB_HUB_URL,
  buildYouTubeWebSubHubRequest,
  calculateYouTubeWebSubRenewalWindow,
  canonicalYouTubeWebSubProviderTimestamp,
  deriveYouTubeWebSubEventKey,
  evaluateYouTubeWebSubVerification,
  matchesYouTubeWebSubCapability,
  planYouTubeWebSubMaintenance,
  planYouTubeWebSubRefreshQuota,
  youtubeApprovedChannelTopicUrl,
  youtubeWebSubCapabilityHash,
  type YouTubeWebSubPendingIntent,
} from "./websub_contract.js";

const CHANNEL_ID = `UC${"a".repeat(22)}`;
const OTHER_CHANNEL_ID = `UC${"b".repeat(22)}`;
const VIDEO_ID = "A1b2C3d4E5f";
const CAPABILITY = "c".repeat(43);
const CALLBACK_BASE =
  "https://asia-south1-example.cloudfunctions.net/youtubePushCallback";
const TOPIC = youtubeApprovedChannelTopicUrl(CHANNEL_ID);
const RECEIVED_AT = new Date("2026-07-24T00:00:00.000Z");

function pendingIntent(
  partial: Partial<YouTubeWebSubPendingIntent> = {},
): YouTubeWebSubPendingIntent {
  return {
    channelId: CHANNEL_ID,
    topicUrl: TOPIC,
    capabilityHash: youtubeWebSubCapabilityHash(CAPABILITY),
    state: "PENDING_SUBSCRIBE",
    pendingMode: "subscribe",
    generation: 3,
    ...partial,
  };
}

function intentWithoutPendingMode(
  state: YouTubeWebSubPendingIntent["state"],
): YouTubeWebSubPendingIntent {
  return {
    channelId: CHANNEL_ID,
    topicUrl: TOPIC,
    capabilityHash: youtubeWebSubCapabilityHash(CAPABILITY),
    state,
    generation: 3,
  };
}

test("approved-channel refresh is disabled by default", () => {
  assert.equal(YOUTUBE_APPROVED_CHANNEL_REFRESH_DEFAULT_ENABLED, false);
});

test("builds only the canonical fixed YouTube channel topic", () => {
  assert.equal(
    TOPIC,
    `https://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}`,
  );
  assert.throws(
    () => youtubeApprovedChannelTopicUrl("channel-name"),
    /channel ID is invalid/u,
  );
  assert.throws(
    () => youtubeApprovedChannelTopicUrl(`${CHANNEL_ID}&next=bad`),
    /channel ID is invalid/u,
  );
});

test("builds a deterministic authenticated subscribe form", () => {
  const result = buildYouTubeWebSubHubRequest({
    mode: "subscribe",
    callbackBaseUrl: `${CALLBACK_BASE}/`,
    capability: CAPABILITY,
    channelId: CHANNEL_ID,
    secret: "s".repeat(32),
    requestedLeaseSeconds: 864_000,
  });
  const body = new URLSearchParams(result.body);

  assert.equal(result.hubUrl, YOUTUBE_WEBSUB_HUB_URL);
  assert.equal(
    result.callbackUrl,
    `${CALLBACK_BASE}/${CAPABILITY}`,
  );
  assert.equal(result.topicUrl, TOPIC);
  assert.equal(
    result.contentType,
    "application/x-www-form-urlencoded",
  );
  assert.deepEqual([...body.keys()], [
    "hub.callback",
    "hub.mode",
    "hub.topic",
    "hub.lease_seconds",
    "hub.secret",
  ]);
  assert.equal(body.get("hub.callback"), result.callbackUrl);
  assert.equal(body.get("hub.mode"), "subscribe");
  assert.equal(body.get("hub.topic"), TOPIC);
  assert.equal(body.get("hub.lease_seconds"), "864000");
  assert.equal(body.get("hub.secret"), "s".repeat(32));
});

test("unsubscribe reuses callback and topic without creating a new secret", () => {
  const result = buildYouTubeWebSubHubRequest({
    mode: "unsubscribe",
    callbackBaseUrl: CALLBACK_BASE,
    capability: CAPABILITY,
    channelId: CHANNEL_ID,
  });
  const body = new URLSearchParams(result.body);

  assert.equal(body.get("hub.mode"), "unsubscribe");
  assert.equal(body.get("hub.callback"), `${CALLBACK_BASE}/${CAPABILITY}`);
  assert.equal(body.get("hub.topic"), TOPIC);
  assert.equal(body.has("hub.secret"), false);
  assert.equal(body.has("hub.lease_seconds"), false);
});

test("rejects unsafe callback identities and malformed hub inputs", () => {
  const base = {
    mode: "subscribe" as const,
    capability: CAPABILITY,
    channelId: CHANNEL_ID,
    secret: "s".repeat(32),
    requestedLeaseSeconds: 864_000,
  };
  for (const callbackBaseUrl of [
    "http://example.com/youtubePushCallback",
    "https://user:pass@example.com/youtubePushCallback",
    "https://example.com/youtubePushCallback?next=bad",
    "https://example.com/youtubePushCallback#bad",
    "https://example.com:8443/youtubePushCallback",
    "https://example.com/",
  ]) {
    assert.throws(
      () =>
        buildYouTubeWebSubHubRequest({
          ...base,
          callbackBaseUrl,
        }),
      /callback base URL/u,
    );
  }
  assert.throws(
    () =>
      buildYouTubeWebSubHubRequest({
        ...base,
        callbackBaseUrl: CALLBACK_BASE,
        capability: "short",
      }),
    /callback capability/u,
  );
  assert.throws(
    () =>
      buildYouTubeWebSubHubRequest({
        ...base,
        callbackBaseUrl: CALLBACK_BASE,
        secret: "short",
      }),
    /secret must be/u,
  );
  assert.throws(
    () =>
      buildYouTubeWebSubHubRequest({
        ...base,
        callbackBaseUrl: CALLBACK_BASE,
        secret: "secret with whitespace".repeat(2),
      }),
    /base64url bytes/u,
  );
  assert.throws(
    () =>
      buildYouTubeWebSubHubRequest({
        ...base,
        callbackBaseUrl: CALLBACK_BASE,
        requestedLeaseSeconds: 0,
      }),
    /lease seconds/u,
  );
});

test("hashes and constant-time matches callback capabilities", () => {
  const hash = youtubeWebSubCapabilityHash(CAPABILITY);
  assert.match(hash, /^[a-f0-9]{64}$/u);
  assert.equal(matchesYouTubeWebSubCapability(CAPABILITY, hash), true);
  assert.equal(
    matchesYouTubeWebSubCapability("d".repeat(43), hash),
    false,
  );
  assert.equal(matchesYouTubeWebSubCapability("short", hash), false);
  assert.equal(matchesYouTubeWebSubCapability(CAPABILITY, "bad"), false);
});

test("accepts exact subscribe verification and records hub lease truth", () => {
  const decision = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "subscribe",
      "hub.topic": TOPIC,
      "hub.challenge": "opaque-challenge",
      "hub.lease_seconds": "864000",
    },
    pendingIntent(),
    RECEIVED_AT,
  );

  assert.equal(decision.accepted, true);
  if (!decision.accepted) {
    return;
  }
  assert.equal(decision.status, 200);
  assert.equal(decision.body, "opaque-challenge");
  assert.deepEqual(
    {
      kind: decision.transition.kind,
      generation: decision.transition.generation,
      state: decision.transition.state,
    },
    {
      kind: "SUBSCRIPTION_VERIFIED",
      generation: 3,
      state: "ACTIVE",
    },
  );
  assert.equal(
    decision.transition.kind === "SUBSCRIPTION_VERIFIED"
      ? decision.transition.expiresAt
      : undefined,
    "2026-08-03T00:00:00.000Z",
  );
  assert.ok(
    decision.transition.kind === "SUBSCRIPTION_VERIFIED" &&
      Date.parse(decision.transition.renewAfter) <
        Date.parse(decision.transition.expiresAt) &&
      Date.parse(decision.transition.renewAfter) >
        RECEIVED_AT.getTime(),
  );
});

test("renewal verification uses the same exact contract", () => {
  const decision = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "subscribe",
      "hub.topic": TOPIC,
      "hub.challenge": "renewal",
      "hub.lease_seconds": "432000",
    },
    pendingIntent({
      state: "RENEWING",
      pendingMode: "subscribe",
      generation: 4,
    }),
    RECEIVED_AT,
  );
  assert.equal(decision.accepted, true);
  assert.equal(
    decision.accepted ? decision.transition.generation : undefined,
    4,
  );
});

test("rejects verification mismatches with 404 and no challenge echo", () => {
  const cases = [
    {
      capability: "d".repeat(43),
      query: {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC,
        "hub.challenge": "challenge",
        "hub.lease_seconds": "864000",
      },
      intent: pendingIntent(),
      reason: "capability_mismatch",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": "subscribe",
        "hub.topic": youtubeApprovedChannelTopicUrl(OTHER_CHANNEL_ID),
        "hub.challenge": "challenge",
        "hub.lease_seconds": "864000",
      },
      intent: pendingIntent(),
      reason: "topic_mismatch",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": ["subscribe", "unsubscribe"],
        "hub.topic": TOPIC,
        "hub.challenge": "challenge",
        "hub.lease_seconds": "864000",
      },
      intent: pendingIntent(),
      reason: "duplicate_parameter",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC,
        "hub.challenge": "",
        "hub.lease_seconds": "864000",
      },
      intent: pendingIntent(),
      reason: "invalid_challenge",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC,
        "hub.challenge": "challenge",
        "hub.lease_seconds": "0",
      },
      intent: pendingIntent(),
      reason: "invalid_lease",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": "unsubscribe",
        "hub.topic": TOPIC,
        "hub.challenge": "challenge",
      },
      intent: pendingIntent(),
      reason: "invalid_pending_intent",
    },
    {
      capability: CAPABILITY,
      query: {
        "hub.mode": "subscribe",
        "hub.topic": TOPIC,
        "hub.challenge": "challenge",
        "hub.lease_seconds": "864000",
      },
      intent: pendingIntent({
        channelId: "invalid",
        topicUrl: TOPIC,
      }),
      reason: "invalid_pending_intent",
    },
  ] as const;

  for (const item of cases) {
    const decision = evaluateYouTubeWebSubVerification(
      item.capability,
      item.query,
      item.intent,
      RECEIVED_AT,
    );
    assert.deepEqual(decision, {
      accepted: false,
      status: 404,
      body: "",
      reason: item.reason,
    });
  }
});

test("accepts exact unsubscribe verification and ignores lease metadata", () => {
  const decision = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "unsubscribe",
      "hub.topic": TOPIC,
      "hub.challenge": "unsubscribe-challenge",
      "hub.lease_seconds": "999",
    },
    pendingIntent({
      state: "PENDING_UNSUBSCRIBE",
      pendingMode: "unsubscribe",
      generation: 8,
    }),
    RECEIVED_AT,
  );
  assert.deepEqual(decision, {
    accepted: true,
    status: 200,
    body: "unsubscribe-challenge",
    transition: {
      kind: "UNSUBSCRIPTION_VERIFIED",
      generation: 8,
      state: "UNSUBSCRIBED",
      verifiedAt: "2026-07-24T00:00:00.000Z",
    },
  });
});

test("records hub denial without echoing untrusted reason text", () => {
  const accepted = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "denied",
      "hub.topic": TOPIC,
      "hub.reason": "  topic unavailable  ",
    },
    pendingIntent(),
    RECEIVED_AT,
  );
  assert.deepEqual(accepted, {
    accepted: true,
    status: 204,
    body: "",
    transition: {
      kind: "SUBSCRIPTION_DENIED",
      generation: 3,
      state: "DENIED",
      deniedAt: "2026-07-24T00:00:00.000Z",
      reason: "topic unavailable",
    },
  });

  const bounded = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "denied",
      "hub.topic": TOPIC,
      "hub.reason": "x".repeat(513),
    },
    pendingIntent(),
    RECEIVED_AT,
  );
  assert.equal(
    bounded.accepted && "reason" in bounded.transition,
    false,
  );

  for (const unsafeReason of [
    "line one\nline two",
    "\nleading newline",
    "trailing newline\n",
    "tab\tseparated",
    "carriage\rreturn",
    `delete${String.fromCodePoint(0x7f)}control`,
  ]) {
    const unsafe = evaluateYouTubeWebSubVerification(
      CAPABILITY,
      {
        "hub.mode": "denied",
        "hub.topic": TOPIC,
        "hub.reason": unsafeReason,
      },
      pendingIntent(),
      RECEIVED_AT,
    );
    assert.equal(
      unsafe.accepted && "reason" in unsafe.transition,
      false,
    );
  }
});

test("accepts denial only for its matching pending subscribe generation", () => {
  const renewal = evaluateYouTubeWebSubVerification(
    CAPABILITY,
    {
      "hub.mode": "denied",
      "hub.topic": TOPIC,
      "hub.reason": "renewal unavailable",
    },
    pendingIntent({
      state: "RENEWING",
      pendingMode: "subscribe",
      generation: 4,
    }),
    RECEIVED_AT,
  );
  assert.equal(renewal.accepted, true);
  assert.equal(
    renewal.accepted ? renewal.transition.generation : undefined,
    4,
  );

  for (const intent of [
    intentWithoutPendingMode("ACTIVE"),
    pendingIntent({ state: "ACTIVE", pendingMode: "subscribe" }),
    intentWithoutPendingMode("PENDING_SUBSCRIBE"),
    pendingIntent({
      state: "PENDING_UNSUBSCRIBE",
      pendingMode: "unsubscribe",
    }),
  ]) {
    assert.deepEqual(
      evaluateYouTubeWebSubVerification(
        CAPABILITY,
        {
          "hub.mode": "denied",
          "hub.topic": TOPIC,
          "hub.reason": "stale denial",
        },
        intent,
        RECEIVED_AT,
      ),
      {
        accepted: false,
        status: 404,
        body: "",
        reason: "invalid_pending_intent",
      },
    );
  }
});

test("calculates deterministic bounded renewal windows", () => {
  const first = calculateYouTubeWebSubRenewalWindow(
    RECEIVED_AT,
    864_000,
    "subscription-a",
  );
  const repeat = calculateYouTubeWebSubRenewalWindow(
    RECEIVED_AT,
    864_000,
    "subscription-a",
  );
  const second = calculateYouTubeWebSubRenewalWindow(
    RECEIVED_AT,
    864_000,
    "subscription-b",
  );
  assert.deepEqual(first, repeat);
  assert.notEqual(first.renewAfter, second.renewAfter);
  assert.equal(first.expiresAt, "2026-08-03T00:00:00.000Z");
  assert.ok(Date.parse(first.renewAfter) < Date.parse(first.expiresAt));
  assert.ok(Date.parse(first.renewAfter) > RECEIVED_AT.getTime());

  const short = calculateYouTubeWebSubRenewalWindow(
    RECEIVED_AT,
    600,
    "short",
  );
  assert.ok(Date.parse(short.renewAfter) > RECEIVED_AT.getTime());
  assert.ok(Date.parse(short.renewAfter) < Date.parse(short.expiresAt));
  const minimum = calculateYouTubeWebSubRenewalWindow(
    RECEIVED_AT,
    60,
    "minimum",
  );
  assert.ok(Date.parse(minimum.renewAfter) > RECEIVED_AT.getTime());
  assert.ok(Date.parse(minimum.renewAfter) < Date.parse(minimum.expiresAt));
});

test("plans subscription lifecycle without clearing an active lease early", () => {
  const futureExpiry = "2026-07-25T00:00:00.000Z";
  const futureRenewal = "2026-07-24T12:00:00.000Z";
  const pastRenewal = "2026-07-23T23:59:00.000Z";
  const common = {
    featureEnabled: true,
    channelApproved: true,
    now: RECEIVED_AT,
  };
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "ACTIVE",
      expiresAt: futureExpiry,
      renewAfter: futureRenewal,
    }),
    "NONE",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "ACTIVE",
      expiresAt: futureExpiry,
      renewAfter: pastRenewal,
    }),
    "RENEW",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "RENEWING",
      expiresAt: futureExpiry,
      nextAttemptAt: "2026-07-24T01:00:00.000Z",
    }),
    "NONE",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "ACTIVE",
      expiresAt: "2026-07-23T23:59:59.000Z",
      renewAfter: pastRenewal,
    }),
    "MARK_EXPIRED",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "UNSUBSCRIBED",
    }),
    "SUBSCRIBE",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "DENIED",
    }),
    "NONE",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "ACTIVE",
      featureEnabled: false,
      expiresAt: futureExpiry,
    }),
    "UNSUBSCRIBE",
  );
  assert.equal(
    planYouTubeWebSubMaintenance({
      ...common,
      state: "ACTIVE",
      channelApproved: false,
      expiresAt: futureExpiry,
    }),
    "UNSUBSCRIBE",
  );
});

test("derives stable collision-resistant event keys from validated identity", () => {
  const identity = {
    kind: "UPSERT_CANDIDATE" as const,
    channelId: CHANNEL_ID,
    videoId: VIDEO_ID,
    entryId: `yt:video:${VIDEO_ID}`,
    providerTimestamp: "2026-07-24T00:00:00Z",
  };
  const first = deriveYouTubeWebSubEventKey(identity);
  assert.match(first, /^[a-f0-9]{64}$/u);
  assert.equal(deriveYouTubeWebSubEventKey(identity), first);
  assert.notEqual(
    deriveYouTubeWebSubEventKey({
      ...identity,
      kind: "DELETE_HINT",
    }),
    first,
  );
  assert.notEqual(
    deriveYouTubeWebSubEventKey({
      ...identity,
      providerTimestamp: "2026-07-24T00:00:01Z",
    }),
    first,
  );
  assert.equal(
    deriveYouTubeWebSubEventKey({
      ...identity,
      providerTimestamp: "2026-07-24T05:30:00+05:30",
    }),
    first,
  );
  assert.equal(
    deriveYouTubeWebSubEventKey({
      ...identity,
      providerTimestamp: "2026-07-24T00:00:00.000000000Z",
    }),
    first,
  );
  assert.throws(
    () =>
      deriveYouTubeWebSubEventKey({
        ...identity,
        entryId: "yt:video:wrong",
      }),
    /does not match/u,
  );
  assert.throws(
    () =>
      deriveYouTubeWebSubEventKey({
        ...identity,
        providerTimestamp: "2026-02-30T00:00:00Z",
      }),
    /supported RFC 3339/u,
  );
});

test("canonicalizes strict provider timestamps without losing precision", () => {
  assert.equal(
    canonicalYouTubeWebSubProviderTimestamp(
      "2015-04-01T19:05:24.552394234+00:00",
    ),
    "2015-04-01T19:05:24.552394234Z",
  );
  assert.equal(
    canonicalYouTubeWebSubProviderTimestamp(
      "2026-07-24T05:31:00.123400000+05:30",
    ),
    "2026-07-24T00:01:00.1234Z",
  );
  assert.throws(
    () =>
      canonicalYouTubeWebSubProviderTimestamp(
        "2026-01-01T24:00:00Z",
      ),
    /supported RFC 3339/u,
  );
});

test("returns an isolated atomic refresh quota reservation plan", () => {
  assert.equal(DEFAULT_DEV_YOUTUBE_WEBSUB_REFRESH_DAILY_CAP, 500);
  assert.deepEqual(planYouTubeWebSubRefreshQuota(50, 200), {
    projectBucket: "general",
    subBudget: "approvedChannelRefresh",
    projectUnits: 50,
    refreshUnits: 50,
    refreshDailyHardCap: 200,
    atomic: true,
    reserveBeforeProviderCall: true,
  });
  assert.throws(
    () => planYouTubeWebSubRefreshQuota(501),
    /cannot exceed its daily hard cap/u,
  );
  assert.throws(
    () => planYouTubeWebSubRefreshQuota(1, 501),
    /cannot exceed the reviewed Dev cap/u,
  );
});
