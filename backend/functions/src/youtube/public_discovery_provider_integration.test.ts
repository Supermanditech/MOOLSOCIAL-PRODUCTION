import assert from "node:assert/strict";
import test from "node:test";

import type {
  YouTubePublicChannelActivitiesQuery,
  YouTubePublicDiscoveryClient,
} from "../youtube-private-dev/public-discovery/public_discovery_client.js";
import { YouTubeProviderError } from "./errors.js";
import { YouTubeProviderService } from "./provider_service.js";

type PublicDiscoveryPort = Pick<
  YouTubePublicDiscoveryClient,
  "listChannelActivities" | "listChannelSections"
>;

const CHANNEL_ID = "UCabcdefghijklmnopqrstuv";

function service(
  publicData: boolean,
  publicDiscoveryClient?: PublicDiscoveryPort,
): YouTubeProviderService {
  return new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData,
      ownerConnect: false,
      ownerActions: false,
      creatorAssets: false,
      live: false,
      privateUpload: false,
      ownerAnalytics: false,
      publicOrUnlistedUpload: false,
    },
    dataClient: {} as never,
    ...(publicDiscoveryClient === undefined
      ? {}
      : { publicDiscoveryClient }),
    ownerClient: {} as never,
    transport: {} as never,
    connections: {} as never,
    publications: {} as never,
    oauthAttempts: {} as never,
    refreshTokens: {} as never,
    accessTokens: {} as never,
    oauthVerifierCipher: {} as never,
    uploadSessionCipher: {} as never,
    oauthClientId: "private-dev-web-client",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/" +
      "youtubeOAuthCallback",
  });
}

test("publicData delegates channel activities with the fixed public principal", async () => {
  const calls: Array<{
    readonly principal: string;
    readonly requestId: string;
    readonly query: YouTubePublicChannelActivitiesQuery;
  }> = [];
  const query: YouTubePublicChannelActivitiesQuery = {
    channelId: CHANNEL_ID,
    regionCode: "IN",
    maxResults: 12,
    publishedAfter: "2026-07-01T00:00:00Z",
    publishedBefore: "2026-07-25T00:00:00Z",
    eventTypes: ["upload", "playlistItem"],
  };
  const expected = {
    source: "youtube" as const,
    feedScope: "publicChannel" as const,
    channelId: CHANNEL_ID,
    regionCode: "IN",
    items: [],
    omittedByFilterOrUnsupportedCount: 0,
  };
  const client: PublicDiscoveryPort = {
    listChannelActivities: async (principal, requestId, input) => {
      calls.push({ principal, requestId, query: input });
      return expected;
    },
    listChannelSections: async () => {
      throw new Error("Unexpected channel-sections call.");
    },
  };

  const actual = await service(true, client).publicChannelActivities(
    "public-activities-1",
    query,
  );

  assert.deepEqual(actual, expected);
  assert.deepEqual(calls, [
    {
      principal: "public",
      requestId: "public-activities-1",
      query,
    },
  ]);
});

test("publicData delegates public channel sections without owner OAuth", async () => {
  const calls: Array<{
    readonly principal: string;
    readonly requestId: string;
    readonly channelId: string;
  }> = [];
  const expected = {
    source: "youtube" as const,
    channelId: CHANNEL_ID,
    items: [],
  };
  const client: PublicDiscoveryPort = {
    listChannelActivities: async () => {
      throw new Error("Unexpected activities call.");
    },
    listChannelSections: async (principal, requestId, channelId) => {
      calls.push({ principal, requestId, channelId });
      return expected;
    },
  };

  const actual = await service(true, client).publicChannelSections(
    "public-sections-1",
    CHANNEL_ID,
  );

  assert.deepEqual(actual, expected);
  assert.deepEqual(calls, [
    {
      principal: "public",
      requestId: "public-sections-1",
      channelId: CHANNEL_ID,
    },
  ]);
});

test("both discovery routes fail before delegation when publicData is disabled", async () => {
  let calls = 0;
  const client: PublicDiscoveryPort = {
    listChannelActivities: async () => {
      calls += 1;
      throw new Error("Disabled route reached the provider.");
    },
    listChannelSections: async () => {
      calls += 1;
      throw new Error("Disabled route reached the provider.");
    },
  };
  const disabled = service(false, client);
  const capabilityDisabled = (error: unknown): boolean =>
    error instanceof YouTubeProviderError &&
    error.code === "capability_disabled";

  await assert.rejects(
    disabled.publicChannelActivities("disabled-activities", {
      channelId: CHANNEL_ID,
    }),
    capabilityDisabled,
  );
  await assert.rejects(
    disabled.publicChannelSections("disabled-sections", CHANNEL_ID),
    capabilityDisabled,
  );
  assert.equal(calls, 0);
});
