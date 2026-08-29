import { createHash } from "node:crypto";

import type {
  DocumentData,
  Firestore,
  Transaction,
} from "firebase-admin/firestore";

import {
  ChatError,
  type ChatMessageRecord,
  type ChatMessagePermission,
  type ChatMessageRequestRecord,
  type ChatCallAvailability,
  type ChatCallKind,
  type ChatCallPreferences,
  type ChatCallRecord,
  type ChatPresenceState,
  type ChatAttachmentKind,
  type ChatAttachmentStore,
  type ChatAttachmentUploadGrant,
  type ChatGroupInfoRecord,
  type ChatGroupInvitePermission,
  type ChatGroupInviteRecord,
  type ChatPhotoAttachmentStore,
  type ChatPhotoContentType,
  type ChatPhotoUploadGrant,
  type ChatProfile,
  type ChatPrivacySettings,
  type ChatRepository,
  type ChatThreadRecord,
} from "./contracts.js";

export class FirestoreChatRepository implements ChatRepository {
  constructor(
    private readonly firestore: Firestore,
    private readonly now: () => Date = () => new Date(),
    private readonly photoStore?: ChatPhotoAttachmentStore,
    private readonly attachmentStore?: ChatAttachmentStore,
  ) {}

  async listThreads(userId: string, limit: number): Promise<ChatThreadRecord[]> {
    const snapshot = await this.firestore
      .collection("chatThreads")
      .where("participantIds", "array-contains", userId)
      .limit(limit)
      .get();
    const visible = await Promise.all(snapshot.docs.map(async (document) => {
      const data = document.data();
      if (!requestVisibleInInbox(data, userId)) return undefined;
      if (await this.blockedForDirectThread(userId, data)) return undefined;
      return threadFromDocument(document.id, data, userId);
    }));
    return visible
      .filter((thread): thread is ChatThreadRecord => thread !== undefined)
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
  }

  async listMessages(
    userId: string,
    threadId: string,
    limit: number,
  ): Promise<ChatMessageRecord[]> {
    const thread = await this.threadForParticipant(userId, threadId);
    const snapshot = await thread.ref
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();
    return Promise.all(
      snapshot.docs.reverse().map((document) => this.publicMessage(
        document.id,
        document.data(),
        userId,
        thread.snapshot.data(),
      )),
    );
  }

  async createDirectThread(
    actor: ChatProfile,
    target: ChatProfile,
  ): Promise<ChatThreadRecord> {
    const participantIds = [actor.userId, target.userId].sort();
    const threadId = `direct-${digest(participantIds.join(":"))}`;
    const ref = this.firestore.collection("chatThreads").doc(threadId);
    await this.firestore.runTransaction(async (transaction) => {
      const targetPreferencesRef = this.privacyRef(target.userId);
      const actorBlocksTarget = this.blockRef(actor.userId, target.userId);
      const targetBlocksActor = this.blockRef(target.userId, actor.userId);
      const actorFollowsTarget = this.followRef(actor.userId, target.userId);
      const targetFollowsActor = this.followRef(target.userId, actor.userId);
      const [existing, targetPreferences, actorBlock, targetBlock, actorFollow, targetFollow] =
        await Promise.all([
          transaction.get(ref),
          transaction.get(targetPreferencesRef),
          transaction.get(actorBlocksTarget),
          transaction.get(targetBlocksActor),
          transaction.get(actorFollowsTarget),
          transaction.get(targetFollowsActor),
        ]);
      if (actorBlock.exists || targetBlock.exists) {
        throw new ChatError(
          "permission_denied",
          "This conversation is unavailable.",
          403,
        );
      }
      if (existing.exists) {
        if (existing.get("requestStatus") === "rejected") {
          throw new ChatError(
            "permission_denied",
            "This conversation request was not accepted.",
            403,
          );
        }
        return;
      }
      const preferences = privacyFromData(targetPreferences.data());
      const mutuallyConnected = actorFollow.get("followed") === true &&
        targetFollow.get("followed") === true;
      const accepted = preferences.whoCanMessage === "everyone" ||
        (preferences.whoCanMessage === "connections" && mutuallyConnected);
      if (!accepted &&
          (preferences.whoCanMessage === "nobody" ||
            !preferences.messageRequestsEnabled)) {
        throw new ChatError(
          "permission_denied",
          "This member is not accepting new conversations.",
          403,
        );
      }
      const updatedAt = this.now().toISOString();
      transaction.create(ref, {
        schemaVersion: 1,
        type: "people",
        participantIds,
        profiles: {
          [actor.userId]: profileData(actor),
          [target.userId]: profileData(target),
        },
        preview: "No messages yet",
        updatedAt,
        verified: false,
        unreadCounts: {
          [actor.userId]: 0,
          [target.userId]: 0,
        },
        lastReadAtBy: {
          [actor.userId]: updatedAt,
          [target.userId]: updatedAt,
        },
        requestStatus: accepted ? "accepted" : "pending",
        requestedByUserId: actor.userId,
        requestRecipientId: target.userId,
        requestedAt: updatedAt,
        requestMessageSent: false,
      });
    });
    const saved = await ref.get();
    return threadFromDocument(saved.id, saved.data()!, actor.userId);
  }

  async sendMessage(
    actor: ChatProfile,
    threadId: string,
    text: string,
    idempotencyKey: string,
    requestDigest: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageRecord> {
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    const messageId = digest(`${actor.userId}:${idempotencyKey}`);
    const messageRef = threadRef.collection("messages").doc(messageId);
    const replyRef = replyToMessageId
      ? threadRef.collection("messages").doc(replyToMessageId)
      : undefined;
    const createdAt = this.now().toISOString();
    let messageData: DocumentData | undefined;
    let messageThreadData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(threadRef);
      const existing = await transaction.get(messageRef);
      const repliedMessage = replyRef ? await transaction.get(replyRef) : undefined;
      assertParticipant(thread.data(), actor.userId);
      await this.assertTransactionNotBlocked(transaction, actor.userId, thread.data());
      assertRequestCanSend(thread.data(), actor.userId);
      if (existing.exists) {
        if (existing.get("requestDigest") !== requestDigest) {
          throw new ChatError(
            "conflict",
            "That retry key belongs to a different message.",
            409,
          );
        }
        messageData = existing.data();
        messageThreadData = thread.data();
        return;
      }
      if (replyRef && !repliedMessage?.exists) {
        throw new ChatError(
          "not_found",
          "The message you replied to is no longer available.",
          404,
        );
      }
      const replyData = repliedMessage?.data();
      if (replyData && String(replyData.threadId) !== threadId) {
        throw new ChatError(
          "bad_request",
          "Choose a message from this conversation.",
          400,
        );
      }
      messageData = {
        schemaVersion: 1,
        threadId,
        senderId: actor.userId,
        senderName: actor.name,
        text,
        createdAt,
        requestDigest,
        reactions: {},
        ...(replyToMessageId && replyData
          ? {
              replyTo: {
                messageId: replyToMessageId,
                senderName: String(replyData.senderName ?? "MoolSocial member"),
                text: replyPreview(String(replyData.text ?? "")),
              },
            }
          : {}),
      };
      const threadData = thread.data()!;
      const participantIds = participantIdsFrom(threadData);
      const unreadCounts = numericMap(threadData.unreadCounts);
      const lastReadAtBy = stringMap(threadData.lastReadAtBy);
      for (const participantId of participantIds) {
        unreadCounts[participantId] = participantId === actor.userId
          ? 0
          : (unreadCounts[participantId] ?? 0) + 1;
      }
      lastReadAtBy[actor.userId] = createdAt;
      messageThreadData = {
        ...threadData,
        unreadCounts,
        lastReadAtBy,
      };
      transaction.create(messageRef, messageData);
      transaction.update(threadRef, {
        preview: text.length > 120 ? `${text.slice(0, 117)}...` : text,
        updatedAt: createdAt,
        unreadCounts,
        lastReadAtBy,
        ...(threadData.requestStatus === "pending"
          ? { requestMessageSent: true }
          : {}),
      });
    });
    return this.publicMessage(
      messageId,
      messageData!,
      actor.userId,
      messageThreadData,
    );
  }

  async preparePhotoUpload(
    actor: ChatProfile,
    threadId: string,
    fileName: string,
    contentType: ChatPhotoContentType,
    sizeBytes: number,
  ): Promise<ChatPhotoUploadGrant> {
    await this.threadForParticipant(actor.userId, threadId);
    return this.requirePhotoStore().prepare({
      userId: actor.userId,
      threadId,
      fileName,
      contentType,
      sizeBytes,
    });
  }

  async sendPhotoMessage(
    actor: ChatProfile,
    threadId: string,
    uploadId: string,
    fileName: string,
    contentType: ChatPhotoContentType,
    sizeBytes: number,
    caption: string,
    idempotencyKey: string,
    requestDigest: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageRecord> {
    await this.threadForParticipant(actor.userId, threadId);
    const validated = await this.requirePhotoStore().validate({
      userId: actor.userId,
      threadId,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
    });
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    const messageId = digest(`${actor.userId}:${idempotencyKey}`);
    const messageRef = threadRef.collection("messages").doc(messageId);
    const replyRef = replyToMessageId
      ? threadRef.collection("messages").doc(replyToMessageId)
      : undefined;
    const receiptRef = threadRef
      .collection("attachmentReceipts")
      .doc(uploadId);
    const createdAt = this.now().toISOString();
    let messageData: DocumentData | undefined;
    let messageThreadData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(threadRef);
      const existing = await transaction.get(messageRef);
      const receipt = await transaction.get(receiptRef);
      const repliedMessage = replyRef ? await transaction.get(replyRef) : undefined;
      assertParticipant(thread.data(), actor.userId);
      if (existing.exists) {
        if (existing.get("requestDigest") !== requestDigest) {
          throw new ChatError(
            "conflict",
            "That retry key belongs to a different message.",
            409,
          );
        }
        messageData = existing.data();
        messageThreadData = thread.data();
        return;
      }
      if (receipt.exists) {
        throw new ChatError(
          "conflict",
          "That photo was already sent.",
          409,
        );
      }
      if (replyRef && !repliedMessage?.exists) {
        throw new ChatError(
          "not_found",
          "The message you replied to is no longer available.",
          404,
        );
      }
      const replyData = repliedMessage?.data();
      if (replyData && String(replyData.threadId) !== threadId) {
        throw new ChatError(
          "bad_request",
          "Choose a message from this conversation.",
          400,
        );
      }
      const threadData = thread.data()!;
      const participantIds = participantIdsFrom(threadData);
      const unreadCounts = numericMap(threadData.unreadCounts);
      const lastReadAtBy = stringMap(threadData.lastReadAtBy);
      for (const participantId of participantIds) {
        unreadCounts[participantId] = participantId === actor.userId
          ? 0
          : (unreadCounts[participantId] ?? 0) + 1;
      }
      lastReadAtBy[actor.userId] = createdAt;
      messageData = {
        schemaVersion: 1,
        messageType: "photo",
        threadId,
        senderId: actor.userId,
        senderName: actor.name,
        text: caption,
        createdAt,
        requestDigest,
        reactions: {},
        ...(replyToMessageId && replyData
          ? {
              replyTo: {
                messageId: replyToMessageId,
                senderName: String(replyData.senderName ?? "MoolSocial member"),
                text: messageReplyPreview(replyData),
              },
            }
          : {}),
        photo: {
          attachmentId: uploadId,
          displayName: fileName,
          contentType,
          sizeBytes,
          objectPath: validated.objectPath,
          generation: validated.generation,
        },
      };
      messageThreadData = {
        ...threadData,
        unreadCounts,
        lastReadAtBy,
      };
      transaction.create(messageRef, messageData);
      transaction.create(receiptRef, {
        schemaVersion: 1,
        messageId,
        senderId: actor.userId,
        createdAt,
      });
      const preview = caption || "Photo";
      transaction.update(threadRef, {
        preview: preview.length > 120 ? `${preview.slice(0, 117)}...` : preview,
        updatedAt: createdAt,
        unreadCounts,
        lastReadAtBy,
      });
    });
    return this.publicMessage(
      messageId,
      messageData!,
      actor.userId,
      messageThreadData,
    );
  }

  async prepareAttachmentUpload(
    actor: ChatProfile,
    threadId: string,
    kind: ChatAttachmentKind,
    fileName: string,
    contentType: string,
    sizeBytes: number,
    durationMilliseconds?: number,
  ): Promise<ChatAttachmentUploadGrant> {
    await this.threadForParticipant(actor.userId, threadId);
    return this.requireAttachmentStore().prepare({
      userId: actor.userId,
      threadId,
      kind,
      fileName,
      contentType,
      sizeBytes,
      ...(durationMilliseconds === undefined ? {} : { durationMilliseconds }),
    });
  }

  async sendAttachmentMessage(
    actor: ChatProfile,
    threadId: string,
    kind: ChatAttachmentKind,
    uploadId: string,
    fileName: string,
    contentType: string,
    sizeBytes: number,
    durationMilliseconds: number | undefined,
    caption: string,
    idempotencyKey: string,
    requestDigest: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageRecord> {
    await this.threadForParticipant(actor.userId, threadId);
    const validated = await this.requireAttachmentStore().validate({
      userId: actor.userId,
      threadId,
      kind,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
      ...(durationMilliseconds === undefined ? {} : { durationMilliseconds }),
    });
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    const messageId = digest(`${actor.userId}:${idempotencyKey}`);
    const messageRef = threadRef.collection("messages").doc(messageId);
    const replyRef = replyToMessageId
      ? threadRef.collection("messages").doc(replyToMessageId)
      : undefined;
    const receiptRef = threadRef.collection("attachmentReceipts").doc(uploadId);
    const createdAt = this.now().toISOString();
    let messageData: DocumentData | undefined;
    let messageThreadData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(threadRef);
      const existing = await transaction.get(messageRef);
      const receipt = await transaction.get(receiptRef);
      const replied = replyRef ? await transaction.get(replyRef) : undefined;
      assertParticipant(thread.data(), actor.userId);
      await this.assertTransactionNotBlocked(transaction, actor.userId, thread.data());
      assertRequestCanSend(thread.data(), actor.userId);
      if (existing.exists) {
        if (existing.get("requestDigest") !== requestDigest) {
          throw new ChatError(
            "conflict",
            "That retry key belongs to another attachment.",
            409,
          );
        }
        messageData = existing.data();
        messageThreadData = thread.data();
        return;
      }
      if (receipt.exists) {
        throw new ChatError("conflict", "That attachment was already sent.", 409);
      }
      if (replyRef && !replied?.exists) {
        throw new ChatError(
          "not_found",
          "The message you replied to is no longer available.",
          404,
        );
      }
      const threadData = thread.data()!;
      const participantIds = participantIdsFrom(threadData);
      const unreadCounts = numericMap(threadData.unreadCounts);
      const lastReadAtBy = stringMap(threadData.lastReadAtBy);
      for (const participantId of participantIds) {
        unreadCounts[participantId] = participantId === actor.userId
          ? 0
          : (unreadCounts[participantId] ?? 0) + 1;
      }
      lastReadAtBy[actor.userId] = createdAt;
      const repliedData = replied?.data();
      messageData = {
        schemaVersion: 1,
        messageType: "attachment",
        threadId,
        senderId: actor.userId,
        senderName: actor.name,
        text: caption,
        createdAt,
        requestDigest,
        reactions: {},
        ...(replyToMessageId && repliedData
          ? {
              replyTo: {
                messageId: replyToMessageId,
                senderName: String(repliedData.senderName ?? "MoolSocial member"),
                text: messageReplyPreview(repliedData),
              },
            }
          : {}),
        attachment: {
          attachmentId: uploadId,
          kind,
          displayName: fileName,
          contentType,
          sizeBytes,
          ...(durationMilliseconds === undefined ? {} : { durationMilliseconds }),
          objectPath: validated.objectPath,
          generation: validated.generation,
        },
      };
      messageThreadData = { ...threadData, unreadCounts, lastReadAtBy };
      transaction.create(messageRef, messageData);
      transaction.create(receiptRef, {
        schemaVersion: 1,
        messageId,
        senderId: actor.userId,
        createdAt,
      });
      const fallback = kind === "voice"
        ? "Voice message"
        : kind === "video"
          ? "Video"
          : fileName;
      const preview = caption || fallback;
      transaction.update(threadRef, {
        preview: preview.length > 120 ? `${preview.slice(0, 117)}...` : preview,
        updatedAt: createdAt,
        unreadCounts,
        lastReadAtBy,
        ...(threadData.requestStatus === "pending"
          ? { requestMessageSent: true }
          : {}),
      });
    });
    return this.publicMessage(
      messageId,
      messageData!,
      actor.userId,
      messageThreadData,
    );
  }

  async forwardMessage(
    actor: ChatProfile,
    sourceThreadId: string,
    sourceMessageId: string,
    targetThreadId: string,
    idempotencyKey: string,
    requestDigest: string,
  ): Promise<ChatMessageRecord> {
    if (sourceThreadId === targetThreadId) {
      throw new ChatError("bad_request", "Choose another conversation.", 400);
    }
    const sourceThreadRef = this.firestore
      .collection("chatThreads")
      .doc(sourceThreadId);
    const targetThreadRef = this.firestore
      .collection("chatThreads")
      .doc(targetThreadId);
    const sourceMessageRef = sourceThreadRef
      .collection("messages")
      .doc(sourceMessageId);
    const messageId = digest(`${actor.userId}:forward:${idempotencyKey}`);
    const targetMessageRef = targetThreadRef
      .collection("messages")
      .doc(messageId);
    const createdAt = this.now().toISOString();
    let messageData: DocumentData | undefined;
    let messageThreadData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const sourceThread = await transaction.get(sourceThreadRef);
      const targetThread = await transaction.get(targetThreadRef);
      const sourceMessage = await transaction.get(sourceMessageRef);
      const existing = await transaction.get(targetMessageRef);
      assertParticipant(sourceThread.data(), actor.userId);
      assertParticipant(targetThread.data(), actor.userId);
      if (existing.exists) {
        if (existing.get("requestDigest") !== requestDigest) {
          throw new ChatError(
            "conflict",
            "That retry key belongs to a different forward.",
            409,
          );
        }
        messageData = existing.data();
        messageThreadData = targetThread.data();
        return;
      }
      if (!sourceMessage.exists) {
        throw new ChatError(
          "not_found",
          "That message is no longer available.",
          404,
        );
      }
      const sourceData = sourceMessage.data()!;
      const text = typeof sourceData.text === "string"
        ? sourceData.text.trim()
        : "";
      const messageType = String(sourceData.messageType ?? "text");
      if (
        text.length === 0 ||
        messageType !== "text" ||
        sourceData.attachment !== undefined ||
        sourceData.attachmentLabel !== undefined ||
        sourceData.media !== undefined
      ) {
        throw new ChatError(
          "bad_request",
          "Only text messages can be forwarded right now.",
          400,
        );
      }
      const targetData = targetThread.data()!;
      const participantIds = participantIdsFrom(targetData);
      const unreadCounts = numericMap(targetData.unreadCounts);
      const lastReadAtBy = stringMap(targetData.lastReadAtBy);
      for (const participantId of participantIds) {
        unreadCounts[participantId] = participantId === actor.userId
          ? 0
          : (unreadCounts[participantId] ?? 0) + 1;
      }
      lastReadAtBy[actor.userId] = createdAt;
      messageData = {
        schemaVersion: 1,
        threadId: targetThreadId,
        senderId: actor.userId,
        senderName: actor.name,
        text,
        createdAt,
        requestDigest,
        reactions: {},
        forwarded: true,
      };
      messageThreadData = {
        ...targetData,
        unreadCounts,
        lastReadAtBy,
      };
      transaction.create(targetMessageRef, messageData);
      transaction.update(targetThreadRef, {
        preview: text.length > 120 ? `${text.slice(0, 117)}...` : text,
        updatedAt: createdAt,
        unreadCounts,
        lastReadAtBy,
      });
    });
    return this.publicMessage(
      messageId,
      messageData!,
      actor.userId,
      messageThreadData,
    );
  }

  async setReaction(
    actor: ChatProfile,
    threadId: string,
    messageId: string,
    reacted: boolean,
  ): Promise<ChatMessageRecord> {
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    const messageRef = threadRef.collection("messages").doc(messageId);
    let messageData: DocumentData | undefined;
    let messageThreadData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(threadRef);
      const message = await transaction.get(messageRef);
      assertParticipant(thread.data(), actor.userId);
      if (!message.exists) {
        throw new ChatError(
          "not_found",
          "That message is no longer available.",
          404,
        );
      }
      const saved = message.data()!;
      messageThreadData = thread.data();
      const reactions = saved.reactions && typeof saved.reactions === "object"
        ? { ...(saved.reactions as Record<string, unknown>) }
        : {};
      if (reacted) {
        reactions[actor.userId] = true;
      } else {
        delete reactions[actor.userId];
      }
      messageData = { ...saved, reactions };
      transaction.update(messageRef, { reactions });
    });
    return this.publicMessage(
      messageId,
      messageData!,
      actor.userId,
      messageThreadData,
    );
  }

  async markThreadRead(userId: string, threadId: string) {
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(threadRef);
      const threadData = thread.data();
      assertParticipant(threadData, userId);
      const unreadCounts = numericMap(threadData!.unreadCounts);
      const lastReadAtBy = stringMap(threadData!.lastReadAtBy);
      unreadCounts[userId] = 0;
      lastReadAtBy[userId] = this.now().toISOString();
      transaction.update(threadRef, { unreadCounts, lastReadAtBy });
    });
    return { threadId, unreadCount: 0 };
  }

  async getPrivacySettings(userId: string): Promise<ChatPrivacySettings> {
    const snapshot = await this.privacyRef(userId).get();
    return privacyFromData(snapshot.data());
  }

  async updatePrivacySettings(
    userId: string,
    settings: Omit<ChatPrivacySettings, "updatedAt">,
  ): Promise<ChatPrivacySettings> {
    const updatedAt = this.now().toISOString();
    await this.privacyRef(userId).set({
      schemaVersion: 1,
      ...settings,
      updatedAt,
    }, { merge: true });
    return { ...settings, updatedAt };
  }

  async listBlockedAccounts(userId: string) {
    const snapshot = await this.firestore
      .collection("chatBlocks")
      .where("blockerUserId", "==", userId)
      .get();
    return snapshot.docs.map((document) => ({
      userId: String(document.get("blockedUserId")),
      name: String(document.get("blockedName") ?? "MoolSocial member"),
      handle: String(document.get("blockedHandle") ?? ""),
      blockedAt: String(document.get("blockedAt") ?? ""),
    })).sort((left, right) => right.blockedAt.localeCompare(left.blockedAt));
  }

  async setBlockedAccount(
    actor: ChatProfile,
    target: ChatProfile,
    blocked: boolean,
  ) {
    const ref = this.blockRef(actor.userId, target.userId);
    if (blocked) {
      await ref.set({
        schemaVersion: 1,
        blockerUserId: actor.userId,
        blockedUserId: target.userId,
        blockedName: target.name,
        blockedHandle: target.handle,
        blockedAt: this.now().toISOString(),
      });
    } else {
      await ref.delete();
    }
    return { blocked };
  }

  async listMessageRequests(userId: string): Promise<ChatMessageRequestRecord[]> {
    const snapshot = await this.firestore
      .collection("chatThreads")
      .where("participantIds", "array-contains", userId)
      .limit(50)
      .get();
    const requests = await Promise.all(snapshot.docs.map(async (document) => {
      const data = document.data();
      if (data.requestStatus !== "pending" || data.requestRecipientId !== userId) {
        return undefined;
      }
      if (await this.blockedForDirectThread(userId, data)) return undefined;
      return {
        thread: threadFromDocument(document.id, data, userId),
        requestedByUserId: String(data.requestedByUserId),
        requestedAt: String(data.requestedAt ?? data.updatedAt ?? ""),
      };
    }));
    return requests
      .filter((request): request is ChatMessageRequestRecord => request !== undefined)
      .sort((left, right) => right.requestedAt.localeCompare(left.requestedAt));
  }

  async resolveMessageRequest(
    userId: string,
    threadId: string,
    accepted: boolean,
  ) {
    const ref = this.firestore.collection("chatThreads").doc(threadId);
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(ref);
      const data = thread.data();
      assertParticipant(data, userId);
      if (data?.requestStatus !== "pending" || data.requestRecipientId !== userId) {
        throw new ChatError("not_found", "That message request is no longer available.", 404);
      }
      transaction.update(ref, {
        requestStatus: accepted ? "accepted" : "rejected",
        requestResolvedAt: this.now().toISOString(),
      });
    });
    return { threadId, accepted };
  }

  async getCallPreferences(userId: string): Promise<ChatCallPreferences> {
    const snapshot = await this.privacyRef(userId).get();
    return callPreferencesFromData(snapshot.data());
  }

  async updateCallPreferences(
    userId: string,
    preferences: Omit<ChatCallPreferences, "updatedAt">,
  ): Promise<ChatCallPreferences> {
    const updatedAt = this.now().toISOString();
    await this.privacyRef(userId).set({
      schemaVersion: 1,
      ...preferences,
      updatedAt,
    }, { merge: true });
    return { ...preferences, updatedAt };
  }

  async setPresence(userId: string, state: ChatPresenceState) {
    const updatedAt = this.now().toISOString();
    await this.presenceRef(userId).set({
      schemaVersion: 1,
      userId,
      state,
      updatedAt,
      ...(state === "offline" ? { activeCallId: null } : {}),
    }, { merge: true });
    return { state, updatedAt };
  }

  async getCallAvailability(
    userId: string,
    threadId: string,
    kind: ChatCallKind,
  ): Promise<ChatCallAvailability> {
    const thread = await this.threadForParticipant(userId, threadId);
    const data = thread.snapshot.data()!;
    const participants = participantIdsFrom(data);
    if (participants.length !== 2) {
      throw new ChatError(
        "bad_request",
        "Start group voice chat from Group info.",
        400,
      );
    }
    const recipientUserId = participants.find((item) => item !== userId)!;
    const [preferencesSnapshot, presenceSnapshot] = await Promise.all([
      this.privacyRef(recipientUserId).get(),
      this.presenceRef(recipientUserId).get(),
    ]);
    const preferences = callPreferencesFromData(preferencesSnapshot.data());
    const enabled = kind === "voice"
      ? preferences.voiceCallsEnabled
      : preferences.videoCallsEnabled;
    const profiles = data.profiles && typeof data.profiles === "object"
      ? data.profiles as Record<string, DocumentData>
      : {};
    const recipientName = String(
      profiles[recipientUserId]?.name ?? "This member",
    );
    if (!enabled) {
      return {
        threadId,
        kind,
        recipientUserId,
        recipientName,
        canStart: false,
        status: "calls_off",
        message: `${recipientName} has turned off ${kind} calls.`,
      };
    }
    if (String(presenceSnapshot.get("activeCallId") ?? "").trim()) {
      return {
        threadId,
        kind,
        recipientUserId,
        recipientName,
        canStart: false,
        status: "busy",
        message: `${recipientName} is already on another call.`,
      };
    }
    const lastActive = Date.parse(String(presenceSnapshot.get("updatedAt") ?? ""));
    const recentlyActive = presenceSnapshot.get("state") === "active" &&
      Number.isFinite(lastActive) &&
      this.now().getTime() - lastActive <= 90_000;
    return {
      threadId,
      kind,
      recipientUserId,
      recipientName,
      canStart: true,
      status: recentlyActive ? "available" : "offline",
      message: recentlyActive
        ? `${recipientName} is available for a ${kind} call.`
        : `${recipientName} may be offline. The call request can still be sent.`,
    };
  }

  async startCall(
    actor: ChatProfile,
    threadId: string,
    kind: ChatCallKind,
    idempotencyKey: string,
  ): Promise<ChatCallRecord> {
    const availability = await this.getCallAvailability(
      actor.userId,
      threadId,
      kind,
    );
    if (!availability.canStart) {
      throw new ChatError(
        availability.status === "calls_off"
          ? "recipient_calls_disabled"
          : "recipient_busy",
        availability.message,
        409,
      );
    }
    const callId = digest(`${actor.userId}:call:${idempotencyKey}`);
    const ref = this.firestore.collection("chatCalls").doc(callId);
    const existing = await ref.get();
    if (existing.exists) {
      const saved = callFromDocument(existing.id, existing.data()!);
      if (saved.callerUserId !== actor.userId ||
          saved.threadId !== threadId || saved.kind !== kind) {
        throw new ChatError(
          "conflict",
          "That call retry belongs to another request.",
          409,
        );
      }
      return saved;
    }
    const createdAt = this.now().toISOString();
    const data = {
      schemaVersion: 1,
      threadId,
      kind,
      callerUserId: actor.userId,
      recipientUserId: availability.recipientUserId,
      status: "ringing",
      createdAt,
      updatedAt: createdAt,
    };
    await ref.set(data);
    await this.presenceRef(actor.userId).set({
      schemaVersion: 1,
      userId: actor.userId,
      state: "active",
      activeCallId: callId,
      updatedAt: createdAt,
    }, { merge: true });
    return callFromDocument(callId, data);
  }

  async respondToCall(
    userId: string,
    callId: string,
    accepted: boolean,
  ): Promise<ChatCallRecord> {
    const ref = this.firestore.collection("chatCalls").doc(callId);
    let result: ChatCallRecord | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const call = await transaction.get(ref);
      if (!call.exists || call.get("recipientUserId") !== userId) {
        throw new ChatError("not_found", "That call is no longer available.", 404);
      }
      if (call.get("status") !== "ringing") {
        result = callFromDocument(call.id, call.data()!);
        return;
      }
      const updatedAt = this.now().toISOString();
      const status = accepted ? "accepted" : "declined";
      transaction.update(ref, { status, updatedAt });
      result = callFromDocument(call.id, { ...call.data()!, status, updatedAt });
    });
    if (accepted) {
      await this.presenceRef(userId).set({
        activeCallId: callId,
        state: "active",
        updatedAt: this.now().toISOString(),
      }, { merge: true });
    }
    return result!;
  }

  async endCall(userId: string, callId: string): Promise<ChatCallRecord> {
    const ref = this.firestore.collection("chatCalls").doc(callId);
    let result: ChatCallRecord | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const call = await transaction.get(ref);
      if (!call.exists ||
          (call.get("callerUserId") !== userId &&
            call.get("recipientUserId") !== userId)) {
        throw new ChatError("not_found", "That call is no longer available.", 404);
      }
      const updatedAt = this.now().toISOString();
      transaction.update(ref, { status: "ended", updatedAt });
      result = callFromDocument(call.id, {
        ...call.data()!,
        status: "ended",
        updatedAt,
      });
    });
    await this.presenceRef(userId).set({
      activeCallId: null,
      updatedAt: this.now().toISOString(),
    }, { merge: true });
    return result!;
  }

  async listIncomingCalls(userId: string): Promise<ChatCallRecord[]> {
    const snapshot = await this.firestore.collection("chatCalls")
      .where("recipientUserId", "==", userId)
      .where("status", "==", "ringing")
      .limit(10)
      .get();
    return snapshot.docs
      .map((document) => callFromDocument(document.id, document.data()))
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
  }

  async getGroupInfo(
    userId: string,
    threadId: string,
  ): Promise<ChatGroupInfoRecord> {
    const thread = await this.threadForParticipant(userId, threadId);
    return groupInfoFromDocument(threadId, thread.snapshot.data()!, userId);
  }

  async inviteGroupMember(
    actor: ChatProfile,
    threadId: string,
    target: ChatProfile,
  ): Promise<ChatGroupInviteRecord> {
    const threadRef = this.firestore.collection("chatThreads").doc(threadId);
    const inviteId = digest(`${threadId}:${target.userId}`);
    const inviteRef = this.firestore.collection("chatGroupInvites").doc(inviteId);
    let result: ChatGroupInviteRecord | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const [thread, existing, actorBlock, targetBlock] = await Promise.all([
        transaction.get(threadRef),
        transaction.get(inviteRef),
        transaction.get(this.blockRef(actor.userId, target.userId)),
        transaction.get(this.blockRef(target.userId, actor.userId)),
      ]);
      const data = thread.data();
      assertParticipant(data, actor.userId);
      const group = groupInfoFromDocument(threadId, data!, actor.userId);
      if (!group.canInvite) {
        throw new ChatError(
          "permission_denied",
          "Only group admins can invite members.",
          403,
        );
      }
      if (participantIdsFrom(data).includes(target.userId)) {
        throw new ChatError("conflict", "This member is already in the group.", 409);
      }
      if (actorBlock.exists || targetBlock.exists) {
        throw new ChatError("permission_denied", "This member cannot be invited.", 403);
      }
      if (existing.exists && existing.get("status") === "pending") {
        result = groupInviteFromDocument(existing.id, existing.data()!);
        return;
      }
      const invitedAt = this.now().toISOString();
      const inviteData = {
        schemaVersion: 1,
        threadId,
        groupTitle: group.title,
        invitedByUserId: actor.userId,
        invitedByName: actor.name,
        targetUserId: target.userId,
        targetProfile: profileData(target),
        status: "pending",
        invitedAt,
      };
      if (existing.exists) transaction.update(inviteRef, inviteData);
      else transaction.create(inviteRef, inviteData);
      result = groupInviteFromDocument(inviteId, inviteData);
    });
    return result!;
  }

  async updateGroupPermissions(
    userId: string,
    threadId: string,
    invitePermission: ChatGroupInvitePermission,
  ): Promise<ChatGroupInfoRecord> {
    const ref = this.firestore.collection("chatThreads").doc(threadId);
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(ref);
      const data = thread.data();
      assertParticipant(data, userId);
      const admins = stringArray(data?.adminIds);
      if (!admins.includes(userId)) {
        throw new ChatError(
          "permission_denied",
          "Only a group admin can change permissions.",
          403,
        );
      }
      assertGroup(data);
      transaction.update(ref, { invitePermission });
    });
    const saved = await ref.get();
    return groupInfoFromDocument(threadId, saved.data()!, userId);
  }

  async leaveGroup(userId: string, threadId: string) {
    const ref = this.firestore.collection("chatThreads").doc(threadId);
    await this.firestore.runTransaction(async (transaction) => {
      const thread = await transaction.get(ref);
      const data = thread.data();
      assertParticipant(data, userId);
      assertGroup(data);
      const groupData = data!;
      const participants = participantIdsFrom(groupData);
      if (participants.length <= 2) {
        throw new ChatError(
          "conflict",
          "You cannot leave until another member joins this group.",
          409,
        );
      }
      const remaining = participants.filter((item) => item !== userId);
      const profiles = { ...objectMap(groupData.profiles) };
      const unreadCounts = numericMap(groupData.unreadCounts);
      const lastReadAtBy = stringMap(groupData.lastReadAtBy);
      delete profiles[userId];
      delete unreadCounts[userId];
      delete lastReadAtBy[userId];
      const admins = stringArray(groupData.adminIds)
        .filter((item) => item !== userId);
      if (admins.length === 0) admins.push(remaining[0]!);
      transaction.update(ref, {
        participantIds: remaining,
        profiles,
        unreadCounts,
        lastReadAtBy,
        adminIds: admins,
        updatedAt: this.now().toISOString(),
      });
    });
    return { threadId, left: true };
  }

  async listGroupInvites(userId: string): Promise<ChatGroupInviteRecord[]> {
    const snapshot = await this.firestore.collection("chatGroupInvites")
      .where("targetUserId", "==", userId)
      .where("status", "==", "pending")
      .limit(30)
      .get();
    return snapshot.docs
      .map((document) => groupInviteFromDocument(document.id, document.data()))
      .sort((left, right) => right.invitedAt.localeCompare(left.invitedAt));
  }

  async respondToGroupInvite(
    userId: string,
    inviteId: string,
    accepted: boolean,
  ) {
    const inviteRef = this.firestore.collection("chatGroupInvites").doc(inviteId);
    let threadId = "";
    await this.firestore.runTransaction(async (transaction) => {
      const invite = await transaction.get(inviteRef);
      if (!invite.exists || invite.get("targetUserId") !== userId ||
          invite.get("status") !== "pending") {
        throw new ChatError("not_found", "That group invitation is unavailable.", 404);
      }
      threadId = String(invite.get("threadId"));
      const threadRef = this.firestore.collection("chatThreads").doc(threadId);
      const thread = await transaction.get(threadRef);
      const data = thread.data();
      assertGroup(data);
      const groupData = data!;
      if (accepted) {
        const participants = participantIdsFrom(groupData);
        if (!participants.includes(userId)) participants.push(userId);
        const profiles = { ...objectMap(groupData.profiles) };
        profiles[userId] = objectMap({ value: invite.get("targetProfile") }).value ?? {};
        const unreadCounts = numericMap(groupData.unreadCounts);
        const lastReadAtBy = stringMap(groupData.lastReadAtBy);
        unreadCounts[userId] = 0;
        lastReadAtBy[userId] = this.now().toISOString();
        transaction.update(threadRef, {
          participantIds: participants,
          profiles,
          unreadCounts,
          lastReadAtBy,
          updatedAt: this.now().toISOString(),
        });
      }
      transaction.update(inviteRef, {
        status: accepted ? "accepted" : "declined",
        resolvedAt: this.now().toISOString(),
      });
    });
    return { inviteId, accepted, threadId };
  }

  private async threadForParticipant(userId: string, threadId: string) {
    const ref = this.firestore.collection("chatThreads").doc(threadId);
    const snapshot = await ref.get();
    const data = snapshot.data();
    assertParticipant(data, userId);
    if (snapshot.get("requestStatus") === "rejected") {
      throw new ChatError("permission_denied", "This conversation is unavailable.", 403);
    }
    if (await this.blockedForDirectThread(userId, data!)) {
      throw new ChatError("permission_denied", "This conversation is unavailable.", 403);
    }
    return { ref, snapshot };
  }

  private privacyRef(userId: string) {
    return this.firestore.collection("chatPrivacySettings").doc(userId);
  }

  private presenceRef(userId: string) {
    return this.firestore.collection("chatPresence").doc(userId);
  }

  private blockRef(blockerUserId: string, blockedUserId: string) {
    return this.firestore.collection("chatBlocks")
      .doc(digest(`${blockerUserId}:${blockedUserId}`));
  }

  private followRef(viewerUserId: string, authorId: string) {
    return this.firestore.collection("socialFollowRelationships")
      .doc(digest(`${viewerUserId}:${authorId}`));
  }

  private async blockedForDirectThread(userId: string, data: DocumentData) {
    const participants = participantIdsFrom(data);
    if (participants.length !== 2) return false;
    const other = participants.find((participant) => participant !== userId);
    if (!other) return false;
    const [outgoing, incoming] = await Promise.all([
      this.blockRef(userId, other).get(),
      this.blockRef(other, userId).get(),
    ]);
    return outgoing?.exists === true || incoming?.exists === true;
  }

  private async assertTransactionNotBlocked(
    transaction: Transaction,
    userId: string,
    data: DocumentData | undefined,
  ) {
    const participants = participantIdsFrom(data);
    if (participants.length !== 2) return;
    const other = participants.find((participant) => participant !== userId);
    if (!other) return;
    const [outgoing, incoming] = await Promise.all([
      transaction.get(this.blockRef(userId, other)),
      transaction.get(this.blockRef(other, userId)),
    ]);
    if (outgoing.exists || incoming.exists) {
      throw new ChatError("permission_denied", "This conversation is unavailable.", 403);
    }
  }

  private requirePhotoStore(): ChatPhotoAttachmentStore {
    if (!this.photoStore) {
      throw new ChatError(
        "service_unavailable",
        "Photo sharing is unavailable right now. Try again later.",
        503,
        true,
      );
    }
    return this.photoStore;
  }

  private requireAttachmentStore(): ChatAttachmentStore {
    if (!this.attachmentStore) {
      throw new ChatError(
        "service_unavailable",
        "Attachment delivery is unavailable right now. Try again later.",
        503,
        true,
      );
    }
    return this.attachmentStore;
  }

  private async publicMessage(
    id: string,
    data: DocumentData,
    userId: string,
    threadData?: DocumentData,
  ): Promise<ChatMessageRecord> {
    const hiddenReceiptUsers = await this.hiddenReceiptUsers(data, threadData);
    const message = messageFromDocument(
      id,
      data,
      userId,
      threadData,
      hiddenReceiptUsers,
    );
    const photo = photoFromDocument(data);
    const attachment = attachmentFromDocument(data);
    if (attachment) {
      const signed = await this.requireAttachmentStore().readUrl({
        objectPath: attachment.objectPath,
        generation: attachment.generation,
      });
      return {
        ...message,
        attachment: {
          id: attachment.attachmentId,
          kind: attachment.kind,
          name: attachment.displayName,
          contentType: attachment.contentType,
          sizeBytes: attachment.sizeBytes,
          ...(attachment.durationMilliseconds === undefined
            ? {}
            : { durationMilliseconds: attachment.durationMilliseconds }),
          readUrl: signed.readUrl,
          readUrlExpiresAt: signed.expiresAt,
        },
      };
    }
    if (!photo) return message;
    const signed = await this.requirePhotoStore().readUrl({
      objectPath: photo.objectPath,
      generation: photo.generation,
    });
    return {
      ...message,
      photo: {
        id: photo.attachmentId,
        name: photo.displayName,
        contentType: photo.contentType,
        sizeBytes: photo.sizeBytes,
        readUrl: signed.readUrl,
        readUrlExpiresAt: signed.expiresAt,
      },
    };
  }

  private async hiddenReceiptUsers(
    messageData: DocumentData,
    threadData?: DocumentData,
  ): Promise<ReadonlySet<string>> {
    const senderId = String(messageData.senderId ?? "");
    const recipients = participantIdsFrom(threadData)
      .filter((participantId) => participantId !== senderId);
    if (recipients.length === 0) return new Set();
    const snapshots = await Promise.all(
      recipients.map((participantId) => this.privacyRef(participantId).get()),
    );
    return new Set(
      snapshots.flatMap((snapshot, index) =>
        snapshot?.get("readReceipts") === false ? [recipients[index]!] : []
      ),
    );
  }
}

function assertParticipant(data: DocumentData | undefined, userId: string): void {
  if (!data) {
    throw new ChatError("not_found", "That conversation is not available.", 404);
  }
  const participants = Array.isArray(data.participantIds)
    ? data.participantIds.map(String)
    : [];
  if (!participants.includes(userId)) {
    throw new ChatError(
      "permission_denied",
      "You do not have access to that conversation.",
      403,
    );
  }
}

function threadFromDocument(
  id: string,
  data: DocumentData,
  userId: string,
): ChatThreadRecord {
  assertParticipant(data, userId);
  const participantIds = (data.participantIds as unknown[]).map(String);
  const otherUserId = participantIds.find((value) => value !== userId) ?? userId;
  const profiles = data.profiles && typeof data.profiles === "object"
    ? data.profiles as Record<string, DocumentData>
    : {};
  const profile = profiles[otherUserId] ?? {};
  const unreadCounts = numericMap(data.unreadCounts);
  if (participantIds.length > 2 || data.group === true) {
    const group = groupInfoFromDocument(id, data, userId);
    return {
      id,
      title: group.title,
      subtitle: `${group.members.length} members`,
      preview: String(data.preview ?? "No messages yet"),
      updatedAt: String(data.updatedAt ?? ""),
      type: "people",
      unreadCount: unreadCounts[userId] ?? 0,
      verified: false,
      participants: group.members,
      groupDescription: group.description,
    };
  }
  return {
    id,
    title: String(profile.name ?? "MoolSocial member"),
    subtitle: String(profile.handle ?? "MoolSocial conversation"),
    preview: String(data.preview ?? "No messages yet"),
    updatedAt: String(data.updatedAt ?? ""),
    type: data.type === "business" || data.type === "order" || data.type === "support"
      ? data.type
      : "people",
    unreadCount: unreadCounts[userId] ?? 0,
    verified: data.verified === true,
    ...(otherUserId !== userId ? { targetUserId: otherUserId } : {}),
    ...(data.requestStatus === "pending" ? { requestStatus: "pending" as const } : {}),
  };
}

function requestVisibleInInbox(data: DocumentData, userId: string): boolean {
  if (data.requestStatus === "rejected") return false;
  return data.requestStatus !== "pending" || data.requestedByUserId === userId;
}

function assertRequestCanSend(data: DocumentData | undefined, userId: string): void {
  if (data?.requestStatus !== "pending") return;
  if (data.requestedByUserId !== userId || data.requestMessageSent === true) {
    throw new ChatError(
      "permission_denied",
      "Wait for this member to accept your message request.",
      403,
    );
  }
}

function privacyFromData(data: DocumentData | undefined): ChatPrivacySettings {
  const permission: ChatMessagePermission = data?.whoCanMessage === "connections" ||
      data?.whoCanMessage === "nobody"
    ? data.whoCanMessage
    : "everyone";
  return {
    whoCanMessage: permission,
    messageRequestsEnabled: data?.messageRequestsEnabled !== false,
    shareLastSeen: data?.shareLastSeen !== false,
    readReceipts: data?.readReceipts !== false,
    updatedAt: String(data?.updatedAt ?? ""),
  };
}

function callPreferencesFromData(
  data: DocumentData | undefined,
): ChatCallPreferences {
  return {
    voiceCallsEnabled: data?.voiceCallsEnabled !== false,
    videoCallsEnabled: data?.videoCallsEnabled !== false,
    updatedAt: String(data?.updatedAt ?? ""),
  };
}

function callFromDocument(id: string, data: DocumentData): ChatCallRecord {
  const kind = data.kind === "video" ? "video" : "voice";
  const status = data.status === "accepted" || data.status === "declined" ||
      data.status === "ended"
    ? data.status
    : "ringing";
  return {
    id,
    threadId: String(data.threadId),
    kind,
    callerUserId: String(data.callerUserId),
    recipientUserId: String(data.recipientUserId),
    status,
    createdAt: String(data.createdAt),
    updatedAt: String(data.updatedAt),
  };
}

function groupInfoFromDocument(
  threadId: string,
  data: DocumentData,
  userId: string,
): ChatGroupInfoRecord {
  assertGroup(data);
  const participants = participantIdsFrom(data);
  const profiles = objectMap(data.profiles);
  const admins = stringArray(data.adminIds);
  const invitePermission: ChatGroupInvitePermission =
    data.invitePermission === "members" ? "members" : "admins";
  const isAdmin = admins.includes(userId);
  return {
    threadId,
    title: String(data.title ?? "MoolSocial group"),
    description: String(data.groupDescription ?? "Coordinate together in Chat."),
    members: participants.map((participantId) => ({
      userId: participantId,
      name: String(profiles[participantId]?.name ?? "MoolSocial member"),
      handle: String(profiles[participantId]?.handle ?? ""),
      isAdmin: admins.includes(participantId),
      isMe: participantId === userId,
    })),
    invitePermission,
    canInvite: isAdmin || invitePermission === "members",
    canManage: isAdmin,
    canLeave: participants.length > 2,
  };
}

function groupInviteFromDocument(
  id: string,
  data: DocumentData,
): ChatGroupInviteRecord {
  return {
    id,
    threadId: String(data.threadId),
    groupTitle: String(data.groupTitle ?? "MoolSocial group"),
    invitedByUserId: String(data.invitedByUserId),
    invitedByName: String(data.invitedByName ?? "MoolSocial member"),
    invitedAt: String(data.invitedAt),
  };
}

function assertGroup(data: DocumentData | undefined): void {
  if (!data || (participantIdsFrom(data).length < 3 && data.group !== true)) {
    throw new ChatError("bad_request", "That conversation is not a group.", 400);
  }
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.map(String) : [];
}

function objectMap(value: unknown): Record<string, DocumentData> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, DocumentData>
    : {};
}

function messageFromDocument(
  id: string,
  data: DocumentData,
  userId: string,
  threadData?: DocumentData,
  hiddenReceiptUsers: ReadonlySet<string> = new Set(),
): ChatMessageRecord {
  const reactions = data.reactions && typeof data.reactions === "object"
    ? data.reactions as Record<string, unknown>
    : {};
  const reply = data.replyTo && typeof data.replyTo === "object"
    ? data.replyTo as Record<string, unknown>
    : undefined;
  const replyMessageId = String(reply?.messageId ?? "").trim();
  const replySenderName = String(reply?.senderName ?? "").trim();
  const replyText = String(reply?.text ?? "").trim();
  const participantIds = participantIdsFrom(threadData);
  const lastReadAtBy = stringMap(threadData?.lastReadAtBy);
  const createdAt = String(data.createdAt);
  const senderId = String(data.senderId);
  const readCount = createdAt
    ? participantIds.filter((participantId) =>
      participantId !== senderId &&
      !hiddenReceiptUsers.has(participantId) &&
      String(lastReadAtBy[participantId] ?? "").localeCompare(createdAt) >= 0
    ).length
    : 0;
  return {
    id,
    threadId: String(data.threadId),
    senderId,
    senderName: String(data.senderName ?? "MoolSocial member"),
    text: String(data.text ?? ""),
    createdAt,
    mine: data.senderId === userId,
    ...(replyMessageId && replySenderName && replyText
      ? {
          replyTo: {
            messageId: replyMessageId,
            senderName: replySenderName,
            text: replyText,
          },
        }
      : {}),
    reactionCount: Object.values(reactions).filter((value) => value === true).length,
    reactedByMe: reactions[userId] === true,
    readCount,
    readByOthers: readCount > 0,
    forwarded: data.forwarded === true,
  };
}

function photoFromDocument(data: DocumentData): {
  attachmentId: string;
  displayName: string;
  contentType: ChatPhotoContentType;
  sizeBytes: number;
  objectPath: string;
  generation: string;
} | undefined {
  if (data.messageType !== "photo" || !data.photo || typeof data.photo !== "object") {
    return undefined;
  }
  const photo = data.photo as Record<string, unknown>;
  const contentType = photo.contentType;
  const sizeBytes = photo.sizeBytes;
  if (
    (contentType !== "image/jpeg" &&
      contentType !== "image/png" &&
      contentType !== "image/webp") ||
    !Number.isSafeInteger(sizeBytes) ||
    (sizeBytes as number) < 1
  ) {
    throw new ChatError("internal", "That photo is unavailable.", 500, true);
  }
  const result: {
    attachmentId: string;
    displayName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
    objectPath: string;
    generation: string;
  } = {
    attachmentId: String(photo.attachmentId ?? "").trim(),
    displayName: String(photo.displayName ?? "").trim(),
    contentType: contentType as ChatPhotoContentType,
    sizeBytes: sizeBytes as number,
    objectPath: String(photo.objectPath ?? "").trim(),
    generation: String(photo.generation ?? "").trim(),
  };
  if (Object.values(result).some((value) => value === "")) {
    throw new ChatError("internal", "That photo is unavailable.", 500, true);
  }
  return result;
}

function attachmentFromDocument(data: DocumentData): {
  attachmentId: string;
  kind: ChatAttachmentKind;
  displayName: string;
  contentType: string;
  sizeBytes: number;
  durationMilliseconds?: number;
  objectPath: string;
  generation: string;
} | undefined {
  if (data.messageType !== "attachment" ||
      !data.attachment || typeof data.attachment !== "object") return undefined;
  const value = data.attachment as Record<string, unknown>;
  const kind = value.kind;
  if (kind !== "document" && kind !== "video" && kind !== "voice") {
    throw new ChatError("internal", "That attachment is unavailable.", 500, true);
  }
  const sizeBytes = value.sizeBytes;
  const durationMilliseconds = value.durationMilliseconds;
  if (!Number.isSafeInteger(sizeBytes) || (sizeBytes as number) < 1 ||
      (durationMilliseconds !== undefined &&
        (!Number.isSafeInteger(durationMilliseconds) ||
          (durationMilliseconds as number) < 1))) {
    throw new ChatError("internal", "That attachment is unavailable.", 500, true);
  }
  const result: {
    attachmentId: string;
    kind: ChatAttachmentKind;
    displayName: string;
    contentType: string;
    sizeBytes: number;
    durationMilliseconds?: number;
    objectPath: string;
    generation: string;
  } = {
    attachmentId: String(value.attachmentId ?? "").trim(),
    kind,
    displayName: String(value.displayName ?? "").trim(),
    contentType: String(value.contentType ?? "").trim(),
    sizeBytes: sizeBytes as number,
    ...(durationMilliseconds === undefined
      ? {}
      : { durationMilliseconds: durationMilliseconds as number }),
    objectPath: String(value.objectPath ?? "").trim(),
    generation: String(value.generation ?? "").trim(),
  };
  if (Object.entries(result).some(([key, value]) =>
    key !== "durationMilliseconds" && value === "")) {
    throw new ChatError("internal", "That attachment is unavailable.", 500, true);
  }
  return result;
}

function profileData(profile: ChatProfile): DocumentData {
  return { name: profile.name, handle: profile.handle };
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function replyPreview(value: string): string {
  const clean = value.trim();
  return clean.length > 160 ? `${clean.slice(0, 157)}...` : clean;
}

function messageReplyPreview(data: DocumentData): string {
  const text = String(data.text ?? "").trim();
  return text ? replyPreview(text) : data.messageType === "photo" ? "Photo" : "Message";
}

function participantIdsFrom(data: DocumentData | undefined): string[] {
  return Array.isArray(data?.participantIds)
    ? data.participantIds.map(String)
    : [];
}

function numericMap(value: unknown): Record<string, number> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return Object.fromEntries(
    Object.entries(value).flatMap(([key, item]) =>
      Number.isSafeInteger(item) && (item as number) >= 0
        ? [[key, item as number]]
        : []
    ),
  );
}

function stringMap(value: unknown): Record<string, string> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return Object.fromEntries(
    Object.entries(value).flatMap(([key, item]) =>
      typeof item === "string" && item.length > 0 ? [[key, item]] : []
    ),
  );
}
