import { createHash } from "node:crypto";

import {
  ChatError,
  type ChatMessageRecord,
  type ChatMessagePermission,
  type ChatCallKind,
  type ChatAttachmentKind,
  type ChatAttachmentUploadGrant,
  type ChatCallPreferences,
  type ChatPresenceState,
  type ChatPhotoContentType,
  type ChatPhotoUploadGrant,
  type ChatProfileResolver,
  type ChatRepository,
  type ChatThreadRecord,
  type ChatPrivacySettings,
} from "./contracts.js";

export class ChatService {
  constructor(
    private readonly repository: ChatRepository,
    private readonly resolveProfile: ChatProfileResolver,
  ) {}

  listThreads(userId: string, raw: unknown): Promise<ChatThreadRecord[]> {
    const body = object(raw);
    return this.repository.listThreads(
      userId,
      boundedInteger(body.limit, 30, 1, 50, "Conversation limit"),
    );
  }

  listMessages(userId: string, raw: unknown): Promise<ChatMessageRecord[]> {
    const body = object(raw);
    return this.repository.listMessages(
      userId,
      requiredIdentifier(body, "threadId"),
      boundedInteger(body.limit, 50, 1, 100, "Message limit"),
    );
  }

  async createDirectThread(
    userId: string,
    raw: unknown,
  ): Promise<ChatThreadRecord> {
    const body = object(raw);
    const targetUserId = requiredText(body, "targetUserId", 128);
    if (targetUserId === userId) {
      throw new ChatError(
        "bad_request",
        "Choose another MoolSocial member.",
        400,
      );
    }
    const [actor, target] = await Promise.all([
      this.resolveProfile(userId),
      this.resolveProfile(targetUserId),
    ]);
    return this.repository.createDirectThread(actor, target);
  }

  async sendMessage(
    userId: string,
    raw: unknown,
  ): Promise<ChatMessageRecord> {
    const body = object(raw);
    const threadId = requiredIdentifier(body, "threadId");
    const text = requiredText(body, "text", 4_000);
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    const replyToMessageId = optionalIdentifier(body, "replyToMessageId");
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]{15,127}$/u.test(idempotencyKey)) {
      throw new ChatError(
        "bad_request",
        "A valid message retry key is required.",
        400,
      );
    }
    const actor = await this.resolveProfile(userId);
    const requestDigest = createHash("sha256")
      .update(JSON.stringify({ threadId, text, replyToMessageId }))
      .digest("hex");
    return this.repository.sendMessage(
      actor,
      threadId,
      text,
      idempotencyKey,
      requestDigest,
      replyToMessageId,
    );
  }

  async preparePhotoUpload(
    userId: string,
    raw: unknown,
  ): Promise<ChatPhotoUploadGrant> {
    const body = object(raw);
    const threadId = requiredIdentifier(body, "threadId");
    const fileName = requiredPhotoFileName(body);
    const contentType = requiredPhotoContentType(body);
    const sizeBytes = boundedInteger(
      body.sizeBytes,
      0,
      1,
      4 * 1024 * 1024,
      "Photo size",
    );
    const actor = await this.resolveProfile(userId);
    return this.repository.preparePhotoUpload(
      actor,
      threadId,
      fileName,
      contentType,
      sizeBytes,
    );
  }

  async sendPhotoMessage(
    userId: string,
    raw: unknown,
  ): Promise<ChatMessageRecord> {
    const body = object(raw);
    const threadId = requiredIdentifier(body, "threadId");
    const uploadId = requiredIdentifier(body, "uploadId");
    const fileName = requiredPhotoFileName(body);
    const contentType = requiredPhotoContentType(body);
    const sizeBytes = boundedInteger(
      body.sizeBytes,
      0,
      1,
      4 * 1024 * 1024,
      "Photo size",
    );
    const caption = optionalText(body, "caption", 1_000) ?? "";
    const replyToMessageId = optionalIdentifier(body, "replyToMessageId");
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    assertRetryKey(idempotencyKey, "photo");
    const actor = await this.resolveProfile(userId);
    const requestDigest = createHash("sha256")
      .update(JSON.stringify({
        threadId,
        uploadId,
        fileName,
        contentType,
        sizeBytes,
        caption,
        replyToMessageId,
      }))
      .digest("hex");
    return this.repository.sendPhotoMessage(
      actor,
      threadId,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
      caption,
      idempotencyKey,
      requestDigest,
      replyToMessageId,
    );
  }

  async prepareAttachmentUpload(
    userId: string,
    raw: unknown,
  ): Promise<ChatAttachmentUploadGrant> {
    const body = object(raw);
    const kind = requiredAttachmentKind(body.kind);
    const fileName = requiredAttachmentFileName(body);
    const contentType = requiredText(body, "contentType", 128);
    const sizeBytes = boundedInteger(
      body.sizeBytes,
      0,
      1,
      50 * 1024 * 1024,
      "Attachment size",
    );
    const durationMilliseconds = optionalBoundedInteger(
      body.durationMilliseconds,
      500,
      300_000,
      "Voice duration",
    );
    const actor = await this.resolveProfile(userId);
    return this.requireCapability("prepareAttachmentUpload")(
      actor,
      requiredIdentifier(body, "threadId"),
      kind,
      fileName,
      contentType,
      sizeBytes,
      durationMilliseconds,
    );
  }

  async sendAttachmentMessage(
    userId: string,
    raw: unknown,
  ): Promise<ChatMessageRecord> {
    const body = object(raw);
    const threadId = requiredIdentifier(body, "threadId");
    const kind = requiredAttachmentKind(body.kind);
    const uploadId = requiredIdentifier(body, "uploadId");
    const fileName = requiredAttachmentFileName(body);
    const contentType = requiredText(body, "contentType", 128);
    const sizeBytes = boundedInteger(
      body.sizeBytes,
      0,
      1,
      50 * 1024 * 1024,
      "Attachment size",
    );
    const durationMilliseconds = optionalBoundedInteger(
      body.durationMilliseconds,
      500,
      300_000,
      "Voice duration",
    );
    const caption = optionalText(body, "caption", 1_000) ?? "";
    const replyToMessageId = optionalIdentifier(body, "replyToMessageId");
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    assertRetryKey(idempotencyKey, "attachment");
    const actor = await this.resolveProfile(userId);
    const requestDigest = createHash("sha256").update(JSON.stringify({
      threadId,
      kind,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
      durationMilliseconds,
      caption,
      replyToMessageId,
    })).digest("hex");
    return this.requireCapability("sendAttachmentMessage")(
      actor,
      threadId,
      kind,
      uploadId,
      fileName,
      contentType,
      sizeBytes,
      durationMilliseconds,
      caption,
      idempotencyKey,
      requestDigest,
      replyToMessageId,
    );
  }

  async setReaction(
    userId: string,
    raw: unknown,
  ): Promise<ChatMessageRecord> {
    const body = object(raw);
    const threadId = requiredIdentifier(body, "threadId");
    const messageId = requiredIdentifier(body, "messageId");
    if (typeof body.reacted !== "boolean") {
      throw new ChatError(
        "bad_request",
        "A valid reaction state is required.",
        400,
      );
    }
    const actor = await this.resolveProfile(userId);
    return this.repository.setReaction(
      actor,
      threadId,
      messageId,
      body.reacted,
    );
  }

  async forwardMessage(
    userId: string,
    raw: unknown,
  ): Promise<ChatMessageRecord> {
    const body = object(raw);
    const sourceThreadId = requiredIdentifier(body, "sourceThreadId");
    const sourceMessageId = requiredIdentifier(body, "sourceMessageId");
    const targetThreadId = requiredIdentifier(body, "targetThreadId");
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    if (sourceThreadId === targetThreadId) {
      throw new ChatError(
        "bad_request",
        "Choose another conversation.",
        400,
      );
    }
    assertRetryKey(idempotencyKey, "forward");
    const actor = await this.resolveProfile(userId);
    const requestDigest = createHash("sha256")
      .update(JSON.stringify({
        sourceThreadId,
        sourceMessageId,
        targetThreadId,
      }))
      .digest("hex");
    return this.repository.forwardMessage(
      actor,
      sourceThreadId,
      sourceMessageId,
      targetThreadId,
      idempotencyKey,
      requestDigest,
    );
  }

  async markThreadRead(userId: string, raw: unknown) {
    const body = object(raw);
    return this.repository.markThreadRead(
      userId,
      requiredIdentifier(body, "threadId"),
    );
  }

  getPrivacySettings(userId: string, raw: unknown): Promise<ChatPrivacySettings> {
    object(raw);
    return this.requireCapability("getPrivacySettings")(userId);
  }

  updatePrivacySettings(
    userId: string,
    raw: unknown,
  ): Promise<ChatPrivacySettings> {
    const body = object(raw);
    const whoCanMessage = requiredMessagePermission(body.whoCanMessage);
    return this.requireCapability("updatePrivacySettings")(userId, {
      whoCanMessage,
      messageRequestsEnabled: requiredBoolean(body, "messageRequestsEnabled"),
      shareLastSeen: requiredBoolean(body, "shareLastSeen"),
      readReceipts: requiredBoolean(body, "readReceipts"),
    });
  }

  listBlockedAccounts(userId: string, raw: unknown) {
    object(raw);
    return this.requireCapability("listBlockedAccounts")(userId);
  }

  async setBlockedAccount(userId: string, raw: unknown) {
    const body = object(raw);
    const targetUserId = requiredIdentifier(body, "targetUserId");
    if (targetUserId === userId) {
      throw new ChatError("bad_request", "You cannot block yourself.", 400);
    }
    const [actor, target] = await Promise.all([
      this.resolveProfile(userId),
      this.resolveProfile(targetUserId),
    ]);
    return this.requireCapability("setBlockedAccount")(
      actor,
      target,
      requiredBoolean(body, "blocked"),
    );
  }

  listMessageRequests(userId: string, raw: unknown) {
    object(raw);
    return this.requireCapability("listMessageRequests")(userId);
  }

  resolveMessageRequest(userId: string, raw: unknown) {
    const body = object(raw);
    return this.requireCapability("resolveMessageRequest")(
      userId,
      requiredIdentifier(body, "threadId"),
      requiredBoolean(body, "accepted"),
    );
  }

  getCallPreferences(userId: string, raw: unknown): Promise<ChatCallPreferences> {
    object(raw);
    return this.requireCapability("getCallPreferences")(userId);
  }

  updateCallPreferences(
    userId: string,
    raw: unknown,
  ): Promise<ChatCallPreferences> {
    const body = object(raw);
    return this.requireCapability("updateCallPreferences")(userId, {
      voiceCallsEnabled: requiredBoolean(body, "voiceCallsEnabled"),
      videoCallsEnabled: requiredBoolean(body, "videoCallsEnabled"),
    });
  }

  setPresence(userId: string, raw: unknown) {
    const body = object(raw);
    return this.requireCapability("setPresence")(
      userId,
      requiredPresenceState(body.state),
    );
  }

  getCallAvailability(userId: string, raw: unknown) {
    const body = object(raw);
    return this.requireCapability("getCallAvailability")(
      userId,
      requiredIdentifier(body, "threadId"),
      requiredCallKind(body.kind),
    );
  }

  async startCall(userId: string, raw: unknown) {
    const body = object(raw);
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    assertRetryKey(idempotencyKey, "call");
    const actor = await this.resolveProfile(userId);
    return this.requireCapability("startCall")(
      actor,
      requiredIdentifier(body, "threadId"),
      requiredCallKind(body.kind),
      idempotencyKey,
    );
  }

  respondToCall(userId: string, raw: unknown) {
    const body = object(raw);
    return this.requireCapability("respondToCall")(
      userId,
      requiredIdentifier(body, "callId"),
      requiredBoolean(body, "accepted"),
    );
  }

  endCall(userId: string, raw: unknown) {
    const body = object(raw);
    return this.requireCapability("endCall")(
      userId,
      requiredIdentifier(body, "callId"),
    );
  }

  listIncomingCalls(userId: string, raw: unknown) {
    object(raw);
    return this.requireCapability("listIncomingCalls")(userId);
  }

  private requireCapability<K extends keyof ChatRepository>(
    name: K,
  ): NonNullable<ChatRepository[K]> {
    const capability = this.repository[name];
    if (typeof capability !== "function") {
      throw new ChatError(
        "service_unavailable",
        "Chat privacy controls are unavailable right now. Try again later.",
        503,
        true,
      );
    }
    return capability.bind(this.repository) as NonNullable<ChatRepository[K]>;
  }
}

function requiredMessagePermission(value: unknown): ChatMessagePermission {
  if (value === "everyone" || value === "connections" || value === "nobody") {
    return value;
  }
  throw new ChatError("bad_request", "Choose who can message you.", 400);
}

function requiredCallKind(value: unknown): ChatCallKind {
  if (value === "voice" || value === "video") return value;
  throw new ChatError("bad_request", "Choose voice or video calling.", 400);
}

function requiredPresenceState(value: unknown): ChatPresenceState {
  if (value === "active" || value === "background" || value === "offline") {
    return value;
  }
  throw new ChatError("bad_request", "A valid presence state is required.", 400);
}

function requiredBoolean(
  body: Record<string, unknown>,
  name: string,
): boolean {
  if (typeof body[name] !== "boolean") {
    throw new ChatError("bad_request", `${name} must be confirmed.`, 400);
  }
  return body[name] as boolean;
}

function requiredPhotoFileName(body: Record<string, unknown>): string {
  const fileName = requiredText(body, "fileName", 120);
  if (/[\\/\u0000-\u001f\u007f]/u.test(fileName)) {
    throw new ChatError("bad_request", "Photo name must be valid.", 400);
  }
  return fileName;
}

function requiredAttachmentFileName(body: Record<string, unknown>): string {
  const fileName = requiredText(body, "fileName", 160);
  if (/[\\/\u0000-\u001f\u007f]/u.test(fileName)) {
    throw new ChatError("bad_request", "Attachment name must be valid.", 400);
  }
  return fileName;
}

function requiredAttachmentKind(value: unknown): ChatAttachmentKind {
  if (value === "document" || value === "video" || value === "voice") {
    return value;
  }
  throw new ChatError("bad_request", "Choose a supported attachment.", 400);
}

function requiredPhotoContentType(
  body: Record<string, unknown>,
): ChatPhotoContentType {
  const contentType = requiredText(body, "contentType", 32);
  if (
    contentType !== "image/jpeg" &&
    contentType !== "image/png" &&
    contentType !== "image/webp"
  ) {
    throw new ChatError(
      "bad_request",
      "Choose a JPEG, PNG or WebP photo up to 4 MB.",
      400,
    );
  }
  return contentType;
}

function assertRetryKey(
  value: string,
  label: "forward" | "photo" | "call" | "attachment",
): void {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{15,127}$/u.test(value)) {
    throw new ChatError(
      "bad_request",
      `A valid ${label} retry key is required.`,
      400,
    );
  }
}

function optionalBoundedInteger(
  value: unknown,
  minimum: number,
  maximum: number,
  label: string,
): number | undefined {
  if (value === undefined || value === null) return undefined;
  return boundedInteger(value, minimum, minimum, maximum, label);
}

function object(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new ChatError("bad_request", "A valid request body is required.", 400);
  }
  return value as Record<string, unknown>;
}

function requiredText(
  body: Record<string, unknown>,
  name: string,
  maximum: number,
): string {
  const value = body[name];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ChatError("bad_request", `${name} is required.`, 400);
  }
  const clean = value.trim();
  if (clean.length > maximum) {
    throw new ChatError("bad_request", `${name} is too long.`, 400);
  }
  return clean;
}

function optionalText(
  body: Record<string, unknown>,
  name: string,
  maximum: number,
): string | undefined {
  const value = body[name];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ChatError("bad_request", `${name} must be valid.`, 400);
  }
  const clean = value.trim();
  if (clean.length > maximum) {
    throw new ChatError("bad_request", `${name} is too long.`, 400);
  }
  return clean;
}

function requiredIdentifier(
  body: Record<string, unknown>,
  name: string,
): string {
  return validIdentifier(requiredText(body, name, 128), name);
}

function optionalIdentifier(
  body: Record<string, unknown>,
  name: string,
): string | undefined {
  const value = optionalText(body, name, 128);
  return value === undefined ? undefined : validIdentifier(value, name);
}

function validIdentifier(value: string, name: string): string {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/u.test(value)) {
    throw new ChatError("bad_request", `${name} must be valid.`, 400);
  }
  return value;
}

function boundedInteger(
  value: unknown,
  fallback: number,
  minimum: number,
  maximum: number,
  label: string,
): number {
  const selected = value ?? fallback;
  if (
    !Number.isSafeInteger(selected) ||
    (selected as number) < minimum ||
    (selected as number) > maximum
  ) {
    throw new ChatError(
      "bad_request",
      `${label} must be between ${minimum} and ${maximum}.`,
      400,
    );
  }
  return selected as number;
}
