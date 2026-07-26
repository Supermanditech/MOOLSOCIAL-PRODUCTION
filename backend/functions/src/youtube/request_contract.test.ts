import assert from "node:assert/strict";
import test from "node:test";

import {
  isAuthenticatedOwnerOperation,
  requiresReplayProtectedAppCheck,
} from "./request_contract.js";

const liveOperations = [
  "liveListBroadcasts",
  "liveInsertBroadcast",
  "liveUpdateBroadcast",
  "liveBindBroadcast",
  "liveTransitionBroadcast",
  "liveDeleteBroadcast",
  "liveListStreams",
  "liveInsertStream",
  "liveUpdateStream",
  "liveDeleteStream",
  "liveListChatMessages",
  "liveInsertChatText",
  "liveInsertChatPoll",
  "liveCloseChatPoll",
  "liveDeleteChatMessage",
  "liveListModerators",
  "liveInsertModerator",
  "liveDeleteModerator",
  "liveInsertBan",
  "liveDeleteBan",
  "liveListSuperChatEvents",
  "liveListMembers",
  "liveListMembershipLevels",
] as const;

const analyticsReportingOperations = [
  "analyticsV2ListGroups",
  "analyticsV2CreateGroup",
  "analyticsV2UpdateGroup",
  "analyticsV2DeleteGroup",
  "analyticsV2ListGroupItems",
  "analyticsV2InsertGroupItem",
  "analyticsV2DeleteGroupItem",
  "analyticsV2QueryReport",
  "reportingV1ListReportTypes",
  "reportingV1CreateJob",
  "reportingV1ListJobs",
  "reportingV1GetJob",
  "reportingV1DeleteJob",
  "reportingV1ListReports",
  "reportingV1GetReport",
  "reportingV1DownloadReportMedia",
] as const;

test("every owner read, connect, upload, analytics and disconnect route requires Firebase Auth", () => {
  for (const operation of [
    "beginConnect",
    "completeConnect",
    "beginPrivateUpload",
    "reconcileUpload",
    "ownerVideos",
    "ownerSubscriptions",
    "ownerPlaylists",
    "ownerAnalyticsPreset",
    "ownerConnectionStatus",
    "ownerGetRating",
    "ownerSetRating",
    "ownerRemoveRating",
    "ownerCreateComment",
    "ownerCreateReply",
    "ownerUpdateComment",
    "ownerDeleteComment",
    "ownerSetCommentModeration",
    "ownerSubscribe",
    "ownerUnsubscribe",
    "ownerCreatePlaylist",
    "ownerUpdatePlaylist",
    "ownerDeletePlaylist",
    "ownerCreatePlaylistItem",
    "ownerUpdatePlaylistItem",
    "ownerReorderPlaylistItem",
    "ownerDeletePlaylistItem",
    "ownerUpdateVideoMetadata",
    "ownerDeleteVideo",
    "creatorBeginThumbnailSet",
    "creatorListCaptions",
    "creatorDownloadCaption",
    "creatorBeginCaptionInsert",
    "creatorUpdateCaptionDraft",
    "creatorBeginCaptionReplacement",
    "creatorDeleteCaption",
    "creatorUpdateChannelBranding",
    "creatorListChannelSections",
    "creatorInsertChannelSection",
    "creatorUpdateChannelSection",
    "creatorDeleteChannelSection",
    "creatorBeginChannelBannerInsert",
    "creatorApplyChannelBanner",
    "creatorBeginWatermarkSet",
    "creatorUnsetWatermark",
    "creatorListPlaylistImages",
    "creatorBeginPlaylistImageInsert",
    "creatorBeginPlaylistImageUpdate",
    "creatorDeletePlaylistImage",
    "creatorListVideoAbuseReasons",
    "creatorReportVideoAbuse",
    ...liveOperations,
    ...analyticsReportingOperations,
    "disconnect",
  ]) {
    assert.equal(isAuthenticatedOwnerOperation(operation), true, operation);
  }
  for (const operation of [
    "publicMostPopular",
    "publicChannelActivities",
    "publicChannelSections",
  ]) {
    assert.equal(isAuthenticatedOwnerOperation(operation), false, operation);
  }
  assert.equal(isAuthenticatedOwnerOperation("capabilities"), false);
});

test("sensitive owner routes and every isolated live route use replay-protected App Check", () => {
  for (const operation of [
    "beginConnect",
    "completeConnect",
    "beginPrivateUpload",
    "reconcileUpload",
    "ownerAnalyticsPreset",
    "ownerGetRating",
    "ownerSetRating",
    "ownerRemoveRating",
    "ownerCreateComment",
    "ownerCreateReply",
    "ownerUpdateComment",
    "ownerDeleteComment",
    "ownerSetCommentModeration",
    "ownerSubscribe",
    "ownerUnsubscribe",
    "ownerCreatePlaylist",
    "ownerUpdatePlaylist",
    "ownerDeletePlaylist",
    "ownerCreatePlaylistItem",
    "ownerUpdatePlaylistItem",
    "ownerReorderPlaylistItem",
    "ownerDeletePlaylistItem",
    "ownerUpdateVideoMetadata",
    "ownerDeleteVideo",
    "creatorBeginThumbnailSet",
    "creatorListCaptions",
    "creatorDownloadCaption",
    "creatorBeginCaptionInsert",
    "creatorUpdateCaptionDraft",
    "creatorBeginCaptionReplacement",
    "creatorDeleteCaption",
    "creatorUpdateChannelBranding",
    "creatorListChannelSections",
    "creatorInsertChannelSection",
    "creatorUpdateChannelSection",
    "creatorDeleteChannelSection",
    "creatorBeginChannelBannerInsert",
    "creatorApplyChannelBanner",
    "creatorBeginWatermarkSet",
    "creatorUnsetWatermark",
    "creatorListPlaylistImages",
    "creatorBeginPlaylistImageInsert",
    "creatorBeginPlaylistImageUpdate",
    "creatorDeletePlaylistImage",
    "creatorListVideoAbuseReasons",
    "creatorReportVideoAbuse",
    ...liveOperations,
    ...analyticsReportingOperations,
    "disconnect",
  ]) {
    assert.equal(requiresReplayProtectedAppCheck(operation), true, operation);
  }
  for (const operation of [
    "ownerVideos",
    "ownerSubscriptions",
    "ownerPlaylists",
    "ownerConnectionStatus",
  ]) {
    assert.equal(requiresReplayProtectedAppCheck(operation), false, operation);
  }
  for (const operation of liveOperations) {
    assert.equal(requiresReplayProtectedAppCheck(operation), true, operation);
  }
  for (const operation of [
    "publicChannelActivities",
    "publicChannelSections",
  ]) {
    assert.equal(
      requiresReplayProtectedAppCheck(operation),
      false,
      operation,
    );
  }
});
