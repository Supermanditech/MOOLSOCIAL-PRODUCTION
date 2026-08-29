import assert from "node:assert/strict";
import test from "node:test";

import type { DocumentData, Firestore } from "firebase-admin/firestore";

import {
  ChatError,
  type ChatPhotoAttachmentStore,
  type ChatPhotoContentType,
  type ChatPhotoUploadGrant,
  type ChatProfile,
  type ChatValidatedPhoto,
} from "./contracts.js";
import { FirestoreChatRepository } from "./firestore_store.js";

const actor: ChatProfile = {
  userId: "user-actor",
  name: "Actor",
  handle: "@actor",
};

test("persists an immutable same-thread reply preview", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-14T00:00:00.000Z"),
  );

  const saved = await repository.sendMessage(
    actor,
    "thread-1",
    "This is the reply body.",
    "chat-reply-idempotency-0001",
    "reply-request-digest",
    "message-original",
  );

  assert.equal(saved.replyTo?.messageId, "message-original");
  assert.equal(saved.replyTo?.senderName, "Member");
  assert.equal(saved.replyTo?.text.length, 160);
  assert.match(saved.replyTo?.text ?? "", /\.\.\.$/u);
  assert.equal(saved.reactionCount, 0);
  assert.equal(saved.reactedByMe, false);
  assert.equal(saved.readCount, 0);
  assert.equal(saved.readByOthers, false);
});

test("rejects a reply target missing from the selected conversation", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
  );

  await assert.rejects(
    repository.sendMessage(
      actor,
      "thread-1",
      "This reply must fail closed.",
      "chat-reply-idempotency-0002",
      "missing-reply-request-digest",
      "message-from-another-thread",
    ),
    (error: unknown) => error instanceof ChatError && error.code === "not_found",
  );
});

test("reaction set repeat and clear are idempotent and privacy bounded", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
  );

  const added = await repository.setReaction(
    actor,
    "thread-1",
    "message-original",
    true,
  );
  const repeated = await repository.setReaction(
    actor,
    "thread-1",
    "message-original",
    true,
  );
  const cleared = await repository.setReaction(
    actor,
    "thread-1",
    "message-original",
    false,
  );

  assert.deepEqual(
    [added.reactionCount, repeated.reactionCount, cleared.reactionCount],
    [1, 1, 0],
  );
  assert.deepEqual(
    [added.reactedByMe, repeated.reactedByMe, cleared.reactedByMe],
    [true, true, false],
  );
  assert.equal(JSON.stringify(added).includes(actor.userId), false);
  assert.deepEqual(
    database.data("chatThreads/thread-1/messages/message-original")?.reactions,
    {},
  );
});

test("unread counts and aggregate read state are idempotent and private", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-14T00:00:00.000Z"),
  );

  const sent = await repository.sendMessage(
    actor,
    "thread-1",
    "Unread until the other member opens Chat.",
    "chat-unread-idempotency-0001",
    "unread-request-digest",
  );
  await repository.sendMessage(
    actor,
    "thread-1",
    "Unread until the other member opens Chat.",
    "chat-unread-idempotency-0001",
    "unread-request-digest",
  );
  const memberThreads = await repository.listThreads("user-member", 10);

  assert.equal(sent.readByOthers, false);
  assert.equal(memberThreads[0]?.unreadCount, 1);
  assert.deepEqual(database.data("chatThreads/thread-1")?.unreadCounts, {
    [actor.userId]: 0,
    "user-member": 1,
  });

  await repository.markThreadRead("user-member", "thread-1");
  await repository.markThreadRead("user-member", "thread-1");
  const actorMessages = await repository.listMessages(actor.userId, "thread-1", 20);
  const readMessage = actorMessages.find((item) => item.id === sent.id);

  assert.equal(readMessage?.readByOthers, true);
  assert.equal(readMessage?.readCount, 1);
  assert.equal(JSON.stringify(readMessage).includes("user-member"), false);
  assert.equal(
    (await repository.listThreads("user-member", 10))[0]?.unreadCount,
    0,
  );
});

test("legacy threads without read maps decode as zero unread and delivered", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
  );

  const legacyThread = (await repository.listThreads(actor.userId, 10))[0];
  const legacyMessage = (
    await repository.listMessages(actor.userId, "thread-1", 10)
  )[0];

  assert.equal(legacyThread?.unreadCount, 0);
  assert.equal(legacyMessage?.readCount, 0);
  assert.equal(legacyMessage?.readByOthers, false);
});

test("forward copies exact server text once without source metadata", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-14T01:00:00.000Z"),
  );

  const first = await repository.forwardMessage(
    actor,
    "thread-1",
    "message-original",
    "thread-2",
    "chat-forward-idempotency-0001",
    "forward-request-digest",
  );
  const repeated = await repository.forwardMessage(
    actor,
    "thread-1",
    "message-original",
    "thread-2",
    "chat-forward-idempotency-0001",
    "forward-request-digest",
  );
  const targetMessages = await repository.listMessages(
    actor.userId,
    "thread-2",
    20,
  );

  assert.equal(first.id, repeated.id);
  assert.equal(targetMessages.length, 1);
  assert.equal(targetMessages[0]?.text, "A".repeat(180));
  assert.equal(targetMessages[0]?.forwarded, true);
  assert.equal(JSON.stringify(targetMessages[0]).includes("thread-1"), false);
  assert.equal(
    JSON.stringify(targetMessages[0]).includes("message-original"),
    false,
  );
  assert.deepEqual(database.data("chatThreads/thread-2")?.unreadCounts, {
    [actor.userId]: 0,
    "user-target": 1,
  });
});

test("forward requires membership in both threads and a text-only source", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
  );

  await assert.rejects(
    repository.forwardMessage(
      actor,
      "thread-1",
      "message-original",
      "thread-private",
      "chat-forward-idempotency-0002",
      "private-target-digest",
    ),
    (error: unknown) =>
      error instanceof ChatError && error.code === "permission_denied",
  );
  database.data(
    "chatThreads/thread-1/messages/message-original",
  )!.attachmentLabel = "private.pdf";
  await assert.rejects(
    repository.forwardMessage(
      actor,
      "thread-1",
      "message-original",
      "thread-2",
      "chat-forward-idempotency-0003",
      "attachment-source-digest",
    ),
    (error: unknown) => error instanceof ChatError && error.code === "bad_request",
  );
});

test("photo prepare proves membership before issuing a private upload grant", async () => {
  const database = chatDatabase();
  const photos = new FakePhotoStore();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-15T00:00:00.000Z"),
    photos,
  );

  const grant = await repository.preparePhotoUpload(
    actor,
    "thread-1",
    "family.png",
    "image/png",
    2048,
  );

  assert.equal(grant.uploadId, photoUploadId);
  assert.deepEqual(photos.prepareInput, {
    userId: actor.userId,
    threadId: "thread-1",
    fileName: "family.png",
    contentType: "image/png",
    sizeBytes: 2048,
  });
  await assert.rejects(
    repository.preparePhotoUpload(
      actor,
      "thread-private",
      "private.png",
      "image/png",
      2048,
    ),
    (error: unknown) =>
      error instanceof ChatError && error.code === "permission_denied",
  );
  assert.equal(photos.prepareCalls, 1);
});

test("photo finalize is idempotent private and increments unread once", async () => {
  const database = chatDatabase();
  const photos = new FakePhotoStore();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-15T00:01:00.000Z"),
    photos,
  );
  const args = [
    actor,
    "thread-1",
    photoUploadId,
    "family.png",
    "image/png" as const,
    2048,
    "Family market list",
    "chat-photo-idempotency-0001",
    "photo-request-digest",
  ] as const;

  const first = await repository.sendPhotoMessage(...args);
  const repeated = await repository.sendPhotoMessage(...args);
  const memberMessages = await repository.listMessages(
    "user-member",
    "thread-1",
    20,
  );

  assert.equal(first.id, repeated.id);
  assert.equal(first.photo?.id, photoUploadId);
  assert.equal(first.photo?.readUrl, photoReadUrl);
  assert.equal(first.text, "Family market list");
  assert.equal(memberMessages.filter((item) => item.photo).length, 1);
  assert.equal(
    JSON.stringify(first).includes("chat-private/v1"),
    false,
  );
  assert.equal(JSON.stringify(first).includes("generation-17"), false);
  assert.deepEqual(database.data("chatThreads/thread-1")?.unreadCounts, {
    [actor.userId]: 0,
    "user-member": 1,
  });
  const messageId = first.id;
  assert.equal(
    database.data(
      `chatThreads/thread-1/attachmentReceipts/${photoUploadId}`,
    )?.messageId,
    messageId,
  );
  assert.ok(photos.readInputs.length >= 3);
});

test("one uploaded photo cannot be consumed by a second message", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-15T00:01:00.000Z"),
    new FakePhotoStore(),
  );

  await repository.sendPhotoMessage(
    actor,
    "thread-1",
    photoUploadId,
    "family.png",
    "image/png",
    2048,
    "First caption",
    "chat-photo-idempotency-0001",
    "photo-request-digest-one",
  );
  await assert.rejects(
    repository.sendPhotoMessage(
      actor,
      "thread-1",
      photoUploadId,
      "family.png",
      "image/png",
      2048,
      "Second caption",
      "chat-photo-idempotency-0002",
      "photo-request-digest-two",
    ),
    (error: unknown) => error instanceof ChatError && error.code === "conflict",
  );
});

test("privacy persistence hides disabled read receipts", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    () => new Date("2026-08-29T01:00:00.000Z"),
  );
  await repository.updatePrivacySettings("user-member", {
    whoCanMessage: "connections",
    messageRequestsEnabled: true,
    shareLastSeen: false,
    readReceipts: false,
  });
  const sent = await repository.sendMessage(
    actor,
    "thread-1",
    "Private read state",
    "chat-privacy-receipt-0001",
    "privacy-receipt-digest",
  );
  await repository.markThreadRead("user-member", "thread-1");
  const loaded = (await repository.listMessages(actor.userId, "thread-1", 20))
    .find((message) => message.id === sent.id);
  assert.equal(loaded?.readCount, 0);
  assert.equal(loaded?.readByOthers, false);
  assert.equal((await repository.getPrivacySettings("user-member")).shareLastSeen, false);
});

test("blocking hides and denies the exact direct conversation", async () => {
  const database = chatDatabase();
  const repository = new FirestoreChatRepository(database as unknown as Firestore);
  await repository.setBlockedAccount(
    actor,
    { userId: "user-member", name: "Member", handle: "@member" },
    true,
  );
  assert.equal((await repository.listThreads(actor.userId, 10)).length, 1);
  assert.equal(
    (await repository.listThreads(actor.userId, 10))[0]?.id,
    "thread-2",
  );
  await assert.rejects(
    repository.listMessages(actor.userId, "thread-1", 10),
    (error: unknown) =>
      error instanceof ChatError && error.code === "permission_denied",
  );
  assert.equal((await repository.listBlockedAccounts(actor.userId))[0]?.userId,
    "user-member");
  await repository.setBlockedAccount(
    actor,
    { userId: "user-member", name: "Member", handle: "@member" },
    false,
  );
  assert.equal((await repository.listBlockedAccounts(actor.userId)).length, 0);
});

test("pending message request is isolated until its recipient accepts", async () => {
  const database = chatDatabase();
  const pendingId = "thread-request";
  database.create(new FakeDocumentReference(database, `chatThreads/${pendingId}`), {
    schemaVersion: 1,
    type: "people",
    participantIds: [actor.userId, "user-requester"],
    profiles: {
      [actor.userId]: { name: actor.name, handle: actor.handle },
      "user-requester": { name: "Requester", handle: "@requester" },
    },
    preview: "Hello",
    updatedAt: "2026-08-29T02:00:00.000Z",
    verified: false,
    requestStatus: "pending",
    requestedByUserId: "user-requester",
    requestRecipientId: actor.userId,
    requestedAt: "2026-08-29T02:00:00.000Z",
  });
  const repository = new FirestoreChatRepository(database as unknown as Firestore);
  assert.equal((await repository.listThreads(actor.userId, 10)).some(
    (thread) => thread.id === pendingId,
  ), false);
  assert.equal((await repository.listMessageRequests(actor.userId))[0]?.thread.id,
    pendingId);
  await repository.resolveMessageRequest(actor.userId, pendingId, true);
  assert.equal((await repository.listMessageRequests(actor.userId)).length, 0);
  assert.equal((await repository.listThreads(actor.userId, 10)).some(
    (thread) => thread.id === pendingId,
  ), true);
});

test("call availability exposes recipient off and completes call lifecycle", async () => {
  const database = chatDatabase();
  const now = () => new Date("2026-08-29T03:00:00.000Z");
  const repository = new FirestoreChatRepository(
    database as unknown as Firestore,
    now,
  );
  await repository.updateCallPreferences("user-member", {
    voiceCallsEnabled: false,
    videoCallsEnabled: true,
  });
  const disabled = await repository.getCallAvailability(
    actor.userId,
    "thread-1",
    "voice",
  );
  assert.equal(disabled.canStart, false);
  assert.equal(disabled.status, "calls_off");
  assert.match(disabled.message, /turned off voice calls/u);

  await repository.updateCallPreferences("user-member", {
    voiceCallsEnabled: true,
    videoCallsEnabled: true,
  });
  await repository.setPresence("user-member", "active");
  const availability = await repository.getCallAvailability(
    actor.userId,
    "thread-1",
    "voice",
  );
  assert.equal(availability.status, "available");
  const started = await repository.startCall(
    actor,
    "thread-1",
    "voice",
    "chat-call-lifecycle-0001",
  );
  assert.equal(started.status, "ringing");
  const accepted = await repository.respondToCall(
    "user-member",
    started.id,
    true,
  );
  assert.equal(accepted.status, "accepted");
  const ended = await repository.endCall(actor.userId, started.id);
  assert.equal(ended.status, "ended");
});

function chatDatabase(): FakeFirestore {
  return new FakeFirestore({
    "chatThreads/thread-1": {
      schemaVersion: 1,
      type: "people",
      participantIds: [actor.userId, "user-member"],
      profiles: {
        [actor.userId]: { name: actor.name, handle: actor.handle },
        "user-member": { name: "Member", handle: "@member" },
      },
      preview: "Original preview",
      updatedAt: "2026-08-13T00:00:00.000Z",
      verified: false,
    },
    "chatThreads/thread-1/messages/message-original": {
      schemaVersion: 1,
      threadId: "thread-1",
      senderId: "user-member",
      senderName: "Member",
      text: "A".repeat(180),
      createdAt: "2026-08-13T00:00:00.000Z",
      reactions: {},
    },
    "chatThreads/thread-2": {
      schemaVersion: 1,
      type: "people",
      participantIds: [actor.userId, "user-target"],
      profiles: {
        [actor.userId]: { name: actor.name, handle: actor.handle },
        "user-target": { name: "Target", handle: "@target" },
      },
      preview: "Target preview",
      updatedAt: "2026-08-13T00:00:00.000Z",
      unreadCounts: { [actor.userId]: 0, "user-target": 0 },
      lastReadAtBy: {
        [actor.userId]: "2026-08-13T00:00:00.000Z",
        "user-target": "2026-08-13T00:00:00.000Z",
      },
      verified: false,
    },
    "chatThreads/thread-private": {
      schemaVersion: 1,
      type: "people",
      participantIds: ["user-private-1", "user-private-2"],
      profiles: {},
      preview: "Private preview",
      updatedAt: "2026-08-13T00:00:00.000Z",
      verified: false,
    },
  });
}

class FakeFirestore {
  private readonly documents: Map<string, DocumentData>;

  constructor(initial: Record<string, DocumentData>) {
    this.documents = new Map(
      Object.entries(initial).map(([path, data]) => [path, { ...data }]),
    );
  }

  collection(path: string): FakeCollectionReference {
    return new FakeCollectionReference(this, path);
  }

  runTransaction<T>(
    action: (transaction: FakeTransaction) => Promise<T>,
  ): Promise<T> {
    return action(new FakeTransaction(this));
  }

  data(path: string): DocumentData | undefined {
    return this.documents.get(path);
  }

  snapshot(reference: FakeDocumentReference): FakeDocumentSnapshot {
    return new FakeDocumentSnapshot(
      reference,
      this.documents.get(reference.path),
    );
  }

  collectionSnapshots(path: string): FakeDocumentSnapshot[] {
    const prefix = `${path}/`;
    return [...this.documents.entries()]
      .filter(([documentPath]) => {
        if (!documentPath.startsWith(prefix)) return false;
        return !documentPath.slice(prefix.length).includes("/");
      })
      .map(([documentPath, data]) =>
        new FakeDocumentSnapshot(
          new FakeDocumentReference(this, documentPath),
          data,
        )
      );
  }

  create(reference: FakeDocumentReference, data: DocumentData): void {
    if (this.documents.has(reference.path)) {
      throw new Error(`Document already exists: ${reference.path}`);
    }
    this.documents.set(reference.path, { ...data });
  }

  update(reference: FakeDocumentReference, data: DocumentData): void {
    const current = this.documents.get(reference.path);
    if (!current) {
      throw new Error(`Document is missing: ${reference.path}`);
    }
    Object.assign(current, data);
  }

  set(reference: FakeDocumentReference, data: DocumentData, merge = false): void {
    const current = this.documents.get(reference.path);
    this.documents.set(reference.path, merge && current
      ? { ...current, ...data }
      : { ...data });
  }

  delete(reference: FakeDocumentReference): void {
    this.documents.delete(reference.path);
  }
}

class FakeCollectionReference {
  constructor(
    private readonly database: FakeFirestore,
    readonly path: string,
  ) {}

  doc(id: string): FakeDocumentReference {
    return new FakeDocumentReference(this.database, `${this.path}/${id}`);
  }

  where(
    field: string,
    operator: string,
    value: unknown,
  ): FakeQuery {
    return new FakeQuery(this.database, this.path).where(
      field,
      operator,
      value,
    );
  }

  orderBy(field: string, direction: string): FakeQuery {
    return new FakeQuery(this.database, this.path).orderBy(field, direction);
  }
}

class FakeDocumentReference {
  constructor(
    private readonly database: FakeFirestore,
    readonly path: string,
  ) {}

  collection(name: string): FakeCollectionReference {
    return new FakeCollectionReference(this.database, `${this.path}/${name}`);
  }

  async get(): Promise<FakeDocumentSnapshot> {
    return this.database.snapshot(this);
  }

  async set(data: DocumentData, options?: { merge?: boolean }): Promise<void> {
    this.database.set(this, data, options?.merge === true);
  }

  async delete(): Promise<void> {
    this.database.delete(this);
  }
}

class FakeDocumentSnapshot {
  constructor(
    readonly ref: FakeDocumentReference,
    private readonly savedData: DocumentData | undefined,
  ) {}

  get exists(): boolean {
    return this.savedData !== undefined;
  }

  get id(): string {
    return this.ref.path.split("/").at(-1) ?? "";
  }

  data(): DocumentData | undefined {
    return this.savedData;
  }

  get(field: string): unknown {
    return this.savedData?.[field];
  }
}

class FakeQuery {
  private whereField?: string;
  private whereOperator?: string;
  private whereValue?: unknown;
  private orderField?: string;
  private orderDirection = "asc";
  private maximum = Number.MAX_SAFE_INTEGER;

  constructor(
    private readonly database: FakeFirestore,
    private readonly path: string,
  ) {}

  where(field: string, operator: string, value: unknown): FakeQuery {
    this.whereField = field;
    this.whereOperator = operator;
    this.whereValue = value;
    return this;
  }

  orderBy(field: string, direction: string): FakeQuery {
    this.orderField = field;
    this.orderDirection = direction;
    return this;
  }

  limit(value: number): FakeQuery {
    this.maximum = value;
    return this;
  }

  async get(): Promise<{ docs: FakeDocumentSnapshot[] }> {
    let documents = this.database.collectionSnapshots(this.path);
    if (this.whereField && this.whereOperator === "array-contains") {
      const field = this.whereField;
      const value = this.whereValue;
      documents = documents.filter((document) => {
        const selected = document.data()?.[field];
        return Array.isArray(selected) && selected.includes(value);
      });
    }
    if (this.whereField && this.whereOperator === "==") {
      const field = this.whereField;
      const value = this.whereValue;
      documents = documents.filter((document) => document.data()?.[field] === value);
    }
    if (this.orderField) {
      const field = this.orderField;
      const direction = this.orderDirection;
      documents.sort((left, right) => {
        const leftValue = String(left.data()?.[field] ?? "");
        const rightValue = String(right.data()?.[field] ?? "");
        return direction === "desc"
          ? rightValue.localeCompare(leftValue)
          : leftValue.localeCompare(rightValue);
      });
    }
    return { docs: documents.slice(0, this.maximum) };
  }
}

class FakeTransaction {
  constructor(private readonly database: FakeFirestore) {}

  async get(reference: FakeDocumentReference): Promise<FakeDocumentSnapshot> {
    return this.database.snapshot(reference);
  }

  create(reference: FakeDocumentReference, data: DocumentData): void {
    this.database.create(reference, data);
  }

  update(reference: FakeDocumentReference, data: DocumentData): void {
    this.database.update(reference, data);
  }
}

const photoUploadId = "00000000-0000-4000-8000-000000000001";
const photoReadUrl =
  `https://storage.googleapis.test/chat-private%2Fv1%2F${photoUploadId}?signed=1`;

class FakePhotoStore implements ChatPhotoAttachmentStore {
  prepareCalls = 0;
  prepareInput?: {
    userId: string;
    threadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  };
  validateInput?: {
    userId: string;
    threadId: string;
    uploadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  };
  readonly readInputs: Array<{ objectPath: string; generation: string }> = [];

  async prepare(input: {
    userId: string;
    threadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatPhotoUploadGrant> {
    this.prepareCalls += 1;
    this.prepareInput = input;
    return {
      uploadId: photoUploadId,
      uploadUrl: "https://storage.googleapis.test/private-upload?signed=1",
      expiresAt: "2026-08-15T00:05:00.000Z",
      requiredHeaders: {
        "content-type": input.contentType,
        "content-length": String(input.sizeBytes),
        "x-goog-if-generation-match": "0",
      },
    };
  }

  async validate(input: {
    userId: string;
    threadId: string;
    uploadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatValidatedPhoto> {
    this.validateInput = input;
    return {
      uploadId: input.uploadId,
      objectPath: `chat-private/v1/${input.uploadId}`,
      generation: "generation-17",
      contentType: input.contentType,
      sizeBytes: input.sizeBytes,
    };
  }

  async readUrl(input: {
    objectPath: string;
    generation: string;
  }): Promise<{ readUrl: string; expiresAt: string }> {
    this.readInputs.push(input);
    return {
      readUrl: photoReadUrl,
      expiresAt: "2026-08-15T00:06:00.000Z",
    };
  }
}
