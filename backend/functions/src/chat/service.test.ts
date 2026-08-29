import assert from "node:assert/strict";
import test from "node:test";

import {
  ChatError,
  type ChatMessageRecord,
  type ChatPrivacySettings,
  type ChatPhotoContentType,
  type ChatPhotoUploadGrant,
  type ChatProfile,
  type ChatRepository,
  type ChatThreadRecord,
} from "./contracts.js";
import { ChatService } from "./service.js";

const actor: ChatProfile = {
  userId: "user-1",
  name: "Founder",
  handle: "@founder",
};
const target: ChatProfile = {
  userId: "user-2",
  name: "Member",
  handle: "@member",
};

test("lists only the authenticated user's bounded conversation page", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  await service.listThreads(actor.userId, { limit: 20 });
  assert.deepEqual(repository.listThreadsInput, [actor.userId, 20]);
  assert.throws(
    () => service.listThreads(actor.userId, { limit: 51 }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("creates one direct thread from verified profile identities", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const result = await service.createDirectThread(actor.userId, {
    targetUserId: target.userId,
  });
  assert.equal(result.id, "thread-1");
  assert.deepEqual(repository.directInput, [actor, target]);
  await assert.rejects(
    service.createDirectThread(actor.userId, { targetUserId: actor.userId }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("seals message content to a stable server-side retry digest", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  await service.sendMessage(actor.userId, {
    threadId: "thread-1",
    text: "Hello from a real Chat owner",
    idempotencyKey: "chat-message-retry-0001",
  });
  assert.equal(repository.sendInput?.[0], actor);
  assert.equal(repository.sendInput?.[1], "thread-1");
  assert.equal(repository.sendInput?.[2], "Hello from a real Chat owner");
  assert.equal(repository.sendInput?.[3], "chat-message-retry-0001");
  assert.match(repository.sendInput?.[4] ?? "", /^[a-f0-9]{64}$/u);
  assert.equal(repository.sendInput?.[5], undefined);
});

test("binds a reply to one exact message in the selected thread", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  await service.sendMessage(actor.userId, {
    threadId: "thread-1",
    text: "Reply with exact context",
    idempotencyKey: "chat-message-reply-0001",
    replyToMessageId: "message-original",
  });
  assert.equal(repository.sendInput?.[5], "message-original");
  await assert.rejects(
    service.sendMessage(actor.userId, {
      threadId: "thread-1",
      text: "Invalid reply",
      idempotencyKey: "chat-message-reply-0002",
      replyToMessageId: " ",
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("sets or clears only the authenticated member reaction state", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  await service.setReaction(actor.userId, {
    threadId: "thread-1",
    messageId: "message-1",
    reacted: true,
  });
  assert.deepEqual(repository.reactionInput, [
    actor,
    "thread-1",
    "message-1",
    true,
  ]);
  await assert.rejects(
    service.setReaction(actor.userId, {
      threadId: "thread-1",
      messageId: "message-1",
      reacted: "yes",
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("rejects Firestore path syntax in thread message and reply identifiers", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  await assert.rejects(
    service.setReaction(actor.userId, {
      threadId: "thread-1/other",
      messageId: "message-1",
      reacted: true,
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
  await assert.rejects(
    service.sendMessage(actor.userId, {
      threadId: "thread-1",
      text: "Unsafe reply target",
      idempotencyKey: "chat-message-reply-0003",
      replyToMessageId: "../message-1",
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("marks only one validated authenticated thread as read", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const result = await service.markThreadRead(actor.userId, {
    threadId: "thread-1",
  });
  assert.deepEqual(repository.readInput, [actor.userId, "thread-1"]);
  assert.deepEqual(result, { threadId: "thread-1", unreadCount: 0 });
  await assert.rejects(
    service.markThreadRead(actor.userId, { threadId: "thread-1/other" }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("binds one confirmed forward to exact source and target conversations", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const forwarded = await service.forwardMessage(actor.userId, {
    sourceThreadId: "thread-1",
    sourceMessageId: "message-1",
    targetThreadId: "thread-2",
    idempotencyKey: "chat-forward-retry-0001",
  });

  assert.equal(repository.forwardInput?.[0], actor);
  assert.deepEqual(repository.forwardInput?.slice(1, 5), [
    "thread-1",
    "message-1",
    "thread-2",
    "chat-forward-retry-0001",
  ]);
  assert.match(repository.forwardInput?.[5] ?? "", /^[a-f0-9]{64}$/u);
  assert.equal(forwarded.forwarded, true);
  await assert.rejects(
    service.forwardMessage(actor.userId, {
      sourceThreadId: "thread-1",
      sourceMessageId: "message-1",
      targetThreadId: "thread-1",
      idempotencyKey: "chat-forward-retry-0002",
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
  await assert.rejects(
    service.forwardMessage(actor.userId, {
      sourceThreadId: "thread-1",
      sourceMessageId: "../message-1",
      targetThreadId: "thread-2",
      idempotencyKey: "chat-forward-retry-0003",
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("prepares only one bounded supported photo upload for a verified actor", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const grant = await service.preparePhotoUpload(actor.userId, {
    threadId: "thread-1",
    fileName: "market-list.webp",
    contentType: "image/webp",
    sizeBytes: 2048,
  });

  assert.equal(grant.uploadId, "00000000-0000-4000-8000-000000000001");
  assert.deepEqual(repository.preparePhotoInput, [
    actor,
    "thread-1",
    "market-list.webp",
    "image/webp",
    2048,
  ]);
  await assert.rejects(
    service.preparePhotoUpload(actor.userId, {
      threadId: "thread-1",
      fileName: "oversize.jpg",
      contentType: "image/jpeg",
      sizeBytes: 4 * 1024 * 1024 + 1,
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
  await assert.rejects(
    service.preparePhotoUpload(actor.userId, {
      threadId: "thread-1",
      fileName: "../private.png",
      contentType: "image/png",
      sizeBytes: 1024,
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("finalizes a photo with one request digest and optional caption", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const saved = await service.sendPhotoMessage(actor.userId, {
    threadId: "thread-1",
    uploadId: "00000000-0000-4000-8000-000000000001",
    fileName: "market-list.png",
    contentType: "image/png",
    sizeBytes: 4096,
    caption: "Monthly market list",
    idempotencyKey: "chat-photo-retry-0001",
  });

  assert.equal(saved.photo?.name, "market-list.png");
  assert.equal(repository.sendPhotoInput?.[0], actor);
  assert.deepEqual(repository.sendPhotoInput?.slice(1, 8), [
    "thread-1",
    "00000000-0000-4000-8000-000000000001",
    "market-list.png",
    "image/png",
    4096,
    "Monthly market list",
    "chat-photo-retry-0001",
  ]);
  assert.match(repository.sendPhotoInput?.[8] ?? "", /^[a-f0-9]{64}$/u);
  assert.equal(repository.sendPhotoInput?.[9], undefined);
});

test("persists complete privacy choices without partial or invalid values", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  const saved = await service.updatePrivacySettings(actor.userId, {
    whoCanMessage: "connections",
    messageRequestsEnabled: true,
    shareLastSeen: false,
    readReceipts: false,
  });
  assert.equal(saved.whoCanMessage, "connections");
  assert.deepEqual(repository.privacyInput, [actor.userId, {
    whoCanMessage: "connections",
    messageRequestsEnabled: true,
    shareLastSeen: false,
    readReceipts: false,
  }]);
  assert.throws(
    () => service.updatePrivacySettings(actor.userId, {
      whoCanMessage: "followers",
      messageRequestsEnabled: true,
      shareLastSeen: false,
      readReceipts: false,
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("binds blocking and request decisions to the authenticated member", async () => {
  const repository = new FakeChatRepository();
  const service = createService(repository);
  assert.deepEqual(
    await service.setBlockedAccount(actor.userId, {
      targetUserId: target.userId,
      blocked: true,
    }),
    { blocked: true },
  );
  assert.deepEqual(repository.blockInput, [actor, target, true]);
  assert.deepEqual(
    await service.resolveMessageRequest(actor.userId, {
      threadId: "thread-1",
      accepted: false,
    }),
    { threadId: "thread-1", accepted: false },
  );
  assert.deepEqual(repository.requestInput, [actor.userId, "thread-1", false]);
  await assert.rejects(
    service.setBlockedAccount(actor.userId, {
      targetUserId: actor.userId,
      blocked: true,
    }),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

function createService(repository: ChatRepository): ChatService {
  return new ChatService(repository, async (userId) => {
    if (userId === actor.userId) return actor;
    if (userId === target.userId) return target;
    throw new ChatError("not_found", "Member unavailable.", 404);
  });
}

class FakeChatRepository implements ChatRepository {
  listThreadsInput?: [string, number];
  directInput?: [ChatProfile, ChatProfile];
  sendInput?: [ChatProfile, string, string, string, string, string | undefined];
  preparePhotoInput?: [
    ChatProfile,
    string,
    string,
    ChatPhotoContentType,
    number,
  ];
  sendPhotoInput?: [
    ChatProfile,
    string,
    string,
    string,
    ChatPhotoContentType,
    number,
    string,
    string,
    string,
    string | undefined,
  ];
  reactionInput?: [ChatProfile, string, string, boolean];
  forwardInput?: [ChatProfile, string, string, string, string, string];
  readInput?: [string, string];
  privacyInput?: [string, Omit<ChatPrivacySettings, "updatedAt">];
  blockInput?: [ChatProfile, ChatProfile, boolean];
  requestInput?: [string, string, boolean];

  async listThreads(userId: string, limit: number): Promise<ChatThreadRecord[]> {
    this.listThreadsInput = [userId, limit];
    return [];
  }

  async listMessages(): Promise<ChatMessageRecord[]> {
    return [];
  }

  async createDirectThread(
    selectedActor: ChatProfile,
    selectedTarget: ChatProfile,
  ): Promise<ChatThreadRecord> {
    this.directInput = [selectedActor, selectedTarget];
    return thread;
  }

  async sendMessage(
    selectedActor: ChatProfile,
    threadId: string,
    text: string,
    idempotencyKey: string,
    requestDigest: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageRecord> {
    this.sendInput = [
      selectedActor,
      threadId,
      text,
      idempotencyKey,
      requestDigest,
      replyToMessageId,
    ];
    return message;
  }

  async preparePhotoUpload(
    selectedActor: ChatProfile,
    threadId: string,
    fileName: string,
    contentType: ChatPhotoContentType,
    sizeBytes: number,
  ): Promise<ChatPhotoUploadGrant> {
    this.preparePhotoInput = [
      selectedActor,
      threadId,
      fileName,
      contentType,
      sizeBytes,
    ];
    return photoGrant;
  }

  async sendPhotoMessage(
    selectedActor: ChatProfile,
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
    this.sendPhotoInput = [
      selectedActor,
      threadId,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
      caption,
      idempotencyKey,
      requestDigest,
      replyToMessageId,
    ];
    return photoMessage;
  }

  async setReaction(
    selectedActor: ChatProfile,
    threadId: string,
    messageId: string,
    reacted: boolean,
  ): Promise<ChatMessageRecord> {
    this.reactionInput = [selectedActor, threadId, messageId, reacted];
    return {
      ...message,
      reactionCount: reacted ? 1 : 0,
      reactedByMe: reacted,
    };
  }

  async forwardMessage(
    selectedActor: ChatProfile,
    sourceThreadId: string,
    sourceMessageId: string,
    targetThreadId: string,
    idempotencyKey: string,
    requestDigest: string,
  ): Promise<ChatMessageRecord> {
    this.forwardInput = [
      selectedActor,
      sourceThreadId,
      sourceMessageId,
      targetThreadId,
      idempotencyKey,
      requestDigest,
    ];
    return {
      ...message,
      threadId: targetThreadId,
      forwarded: true,
    };
  }

  async markThreadRead(userId: string, threadId: string) {
    this.readInput = [userId, threadId];
    return { threadId, unreadCount: 0 };
  }

  async getPrivacySettings(): Promise<ChatPrivacySettings> {
    return privacy;
  }

  async updatePrivacySettings(
    userId: string,
    settings: Omit<ChatPrivacySettings, "updatedAt">,
  ): Promise<ChatPrivacySettings> {
    this.privacyInput = [userId, settings];
    return { ...settings, updatedAt: privacy.updatedAt };
  }

  async listBlockedAccounts() {
    return [];
  }

  async setBlockedAccount(
    selectedActor: ChatProfile,
    selectedTarget: ChatProfile,
    blocked: boolean,
  ) {
    this.blockInput = [selectedActor, selectedTarget, blocked];
    return { blocked };
  }

  async listMessageRequests() {
    return [];
  }

  async resolveMessageRequest(
    userId: string,
    threadId: string,
    accepted: boolean,
  ) {
    this.requestInput = [userId, threadId, accepted];
    return { threadId, accepted };
  }
}

const privacy: ChatPrivacySettings = {
  whoCanMessage: "everyone",
  messageRequestsEnabled: true,
  shareLastSeen: true,
  readReceipts: true,
  updatedAt: "2026-08-29T00:00:00.000Z",
};

const thread: ChatThreadRecord = {
  id: "thread-1",
  title: target.name,
  subtitle: target.handle,
  preview: "No messages yet",
  updatedAt: "2026-08-13T00:00:00.000Z",
  type: "people",
  unreadCount: 0,
  verified: false,
};

const message: ChatMessageRecord = {
  id: "message-1",
  threadId: thread.id,
  senderId: actor.userId,
  senderName: actor.name,
  text: "Hello from a real Chat owner",
  createdAt: "2026-08-13T00:00:00.000Z",
  mine: true,
  reactionCount: 0,
  reactedByMe: false,
  readCount: 0,
  readByOthers: false,
  forwarded: false,
};

const photoGrant: ChatPhotoUploadGrant = {
  uploadId: "00000000-0000-4000-8000-000000000001",
  uploadUrl: "https://storage.googleapis.test/private-upload",
  expiresAt: "2026-08-15T00:05:00.000Z",
  requiredHeaders: {
    "content-type": "image/webp",
    "content-length": "2048",
    "x-goog-if-generation-match": "0",
  },
};

const photoMessage: ChatMessageRecord = {
  ...message,
  text: "Monthly market list",
  photo: {
    id: "00000000-0000-4000-8000-000000000001",
    name: "market-list.png",
    contentType: "image/png",
    sizeBytes: 4096,
    readUrl: "https://storage.googleapis.test/private-read",
    readUrlExpiresAt: "2026-08-15T00:05:00.000Z",
  },
};
