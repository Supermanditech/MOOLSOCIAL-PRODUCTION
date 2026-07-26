import type {
  YouTubeBroadcastState,
  YouTubePublicVideoAvailability,
  YouTubePublicVideoUnavailableReason,
} from "./types.js";

export interface YouTubeRegionRestriction {
  readonly allowed?: readonly string[];
  readonly blocked?: readonly string[];
}

export interface YouTubePublicVideoPolicyInput {
  readonly regionCode: string;
  readonly privacyStatus?: string;
  readonly embeddable?: boolean;
  readonly uploadStatus?: string;
  readonly madeForKids?: boolean;
  readonly youtubeAgeRating?: string;
  readonly regionRestriction?: YouTubeRegionRestriction;
  readonly liveBroadcastContent?: string;
  readonly syndicationConfirmedBySearch?: boolean;
}

export type YouTubePublicVideoPolicyDecision =
  | {
      readonly eligible: true;
      readonly availability: YouTubePublicVideoAvailability;
    }
  | {
      readonly eligible: false;
      readonly reason: YouTubePublicVideoUnavailableReason;
    };

function unavailable(
  reason: YouTubePublicVideoUnavailableReason,
): YouTubePublicVideoPolicyDecision {
  return { eligible: false, reason };
}

function normalizedRegions(
  values: readonly string[] | undefined,
): readonly string[] | undefined | null {
  if (values === undefined) return undefined;
  const result: string[] = [];
  for (const value of values) {
    const region = value.trim().toUpperCase();
    if (!/^[A-Z]{2}$/.test(region)) return null;
    if (!result.includes(region)) result.push(region);
  }
  return result;
}

function broadcastState(
  value: string | undefined,
): YouTubeBroadcastState | undefined {
  const state = value?.trim();
  return state === "none" || state === "live" || state === "upcoming"
    ? state
    : undefined;
}

/**
 * Applies the public playback boundary to fields returned by videos.list.
 *
 * Search-origin candidates must also be requested with
 * videoSyndicated=true. Other discovery sources do not expose an equivalent
 * per-video syndication property, so status.embeddable is the strongest
 * metadata check available before the official player performs the final
 * runtime decision.
 */
export function assessPublicVideo(
  input: YouTubePublicVideoPolicyInput,
): YouTubePublicVideoPolicyDecision {
  const regionCode = input.regionCode.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(regionCode)) {
    return unavailable("metadata_invalid");
  }

  if (input.privacyStatus !== "public") {
    return unavailable("not_public");
  }
  if (input.embeddable !== true) {
    return unavailable("not_embeddable");
  }

  switch (input.uploadStatus) {
    case "processed":
      break;
    case "uploaded":
      return unavailable("processing");
    case "deleted":
    case "failed":
    case "rejected":
      return unavailable("removed_or_rejected");
    default:
      return unavailable("metadata_invalid");
  }

  const allowed = normalizedRegions(input.regionRestriction?.allowed);
  const blocked = normalizedRegions(input.regionRestriction?.blocked);
  if (
    allowed === null ||
    blocked === null ||
    (allowed !== undefined && blocked !== undefined)
  ) {
    return unavailable("metadata_invalid");
  }
  if (allowed !== undefined && !allowed.includes(regionCode)) {
    return unavailable("region_restricted");
  }
  if (blocked !== undefined && blocked.includes(regionCode)) {
    return unavailable("region_restricted");
  }

  const youtubeAgeRating = input.youtubeAgeRating?.trim();
  if (youtubeAgeRating === "ytAgeRestricted") {
    return unavailable("age_restricted");
  }
  if (youtubeAgeRating) {
    // ytRating currently has one documented value. Fail closed if the
    // provider adds an unknown value until policy is reviewed.
    return unavailable("metadata_invalid");
  }
  if (input.madeForKids === true) {
    // Children-directed playback remains outside the private MVP proof until
    // its consent and playback-data-sharing requirements are implemented.
    return unavailable("children_directed");
  }
  if (input.madeForKids !== false) {
    return unavailable("metadata_invalid");
  }

  const liveState = broadcastState(input.liveBroadcastContent);
  if (liveState === undefined) {
    return unavailable("metadata_invalid");
  }

  return {
    eligible: true,
    availability: {
      state: "available",
      regionCode,
      broadcastState: liveState,
      syndication: input.syndicationConfirmedBySearch
        ? "search_filter_confirmed"
        : "embeddable_status_only",
    },
  };
}
