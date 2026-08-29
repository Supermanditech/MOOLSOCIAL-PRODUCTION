export type ChatThreadType = "people" | "business" | "order" | "support";

export class ChatError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly httpStatus: number,
    readonly retryable = false,
  ) {
    super(message);
    this.name = "ChatError";
  }
}

export interface ChatProfile {
  userId: string;
  name: string;
  handle: string;
}

export interface ChatThreadRecord {
  id: string;
  title: string;
  subtitle: string;
  preview: string;
  updatedAt: string;
  type: ChatThreadType;
  unreadCount: number;
  verified: boolean;
  targetUserId?: string;
  requestStatus?: ChatMessageRequestStatus;
}

export type ChatMessagePermission = "everyone" | "connections" | "nobody";
export type ChatMessageRequestStatus = "pending" | "accepted";

export interface ChatPrivacySettings {
  whoCanMessage: ChatMessagePermission;
  messageRequestsEnabled: boolean;
  shareLastSeen: boolean;
  readReceipts: boolean;
  updatedAt: string;
}

export interface ChatBlockedAccount {
  userId: string;
  name: string;
  handle: string;
  blockedAt: string;
}

export interface ChatMessageRequestRecord {
  thread: ChatThreadRecord;
  requestedByUserId: string;
  requestedAt: string;
}

export type ChatCallKind = "voice" | "video";
export type ChatPresenceState = "active" | "background" | "offline";
export type ChatCallStatus = "ringing" | "accepted" | "declined" | "ended";

export interface ChatCallPreferences {
  voiceCallsEnabled: boolean;
  videoCallsEnabled: boolean;
  updatedAt: string;
}

export interface ChatCallAvailability {
  threadId: string;
  kind: ChatCallKind;
  recipientUserId: string;
  recipientName: string;
  canStart: boolean;
  status: "available" | "offline" | "calls_off" | "busy";
  message: string;
}

export interface ChatCallRecord {
  id: string;
  threadId: string;
  kind: ChatCallKind;
  callerUserId: string;
  recipientUserId: string;
  status: ChatCallStatus;
  createdAt: string;
  updatedAt: string;
}

export interface ChatMessageRecord {
  id: string;
  threadId: string;
  senderId: string;
  senderName: string;
  text: string;
  createdAt: string;
  mine: boolean;
  replyTo?: ChatReplyRecord;
  reactionCount: number;
  reactedByMe: boolean;
  readCount: number;
  readByOthers: boolean;
  forwarded: boolean;
  photo?: ChatPhotoAttachmentRecord;
  attachment?: ChatAttachmentRecord;
}

export type ChatAttachmentKind = "document" | "video" | "voice";

export interface ChatAttachmentRecord {
  id: string;
  kind: ChatAttachmentKind;
  name: string;
  contentType: string;
  sizeBytes: number;
  durationMilliseconds?: number;
  readUrl: string;
  readUrlExpiresAt: string;
}

export interface ChatAttachmentUploadGrant extends ChatPhotoUploadGrant {}

export interface ChatValidatedAttachment {
  uploadId: string;
  objectPath: string;
  generation: string;
  kind: ChatAttachmentKind;
  contentType: string;
  sizeBytes: number;
  durationMilliseconds?: number;
}

export interface ChatAttachmentStore {
  prepare(input: {
    userId: string;
    threadId: string;
    kind: ChatAttachmentKind;
    fileName: string;
    contentType: string;
    sizeBytes: number;
    durationMilliseconds?: number;
  }): Promise<ChatAttachmentUploadGrant>;
  validate(input: {
    userId: string;
    threadId: string;
    kind: ChatAttachmentKind;
    uploadId: string;
    fileName: string;
    contentType: string;
    sizeBytes: number;
    durationMilliseconds?: number;
  }): Promise<ChatValidatedAttachment>;
  readUrl(input: {
    objectPath: string;
    generation: string;
  }): Promise<{ readUrl: string; expiresAt: string }>;
}

export interface ChatPhotoAttachmentRecord {
  id: string;
  name: string;
  contentType: ChatPhotoContentType;
  sizeBytes: number;
  readUrl: string;
  readUrlExpiresAt: string;
}

export type ChatPhotoContentType = "image/jpeg" | "image/png" | "image/webp";

export interface ChatPhotoUploadGrant {
  uploadId: string;
  uploadUrl: string;
  expiresAt: string;
  requiredHeaders: Readonly<Record<string, string>>;
}

export interface ChatValidatedPhoto {
  uploadId: string;
  objectPath: string;
  generation: string;
  contentType: ChatPhotoContentType;
  sizeBytes: number;
}

export interface ChatPhotoAttachmentStore {
  prepare(input: {
    userId: string;
    threadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatPhotoUploadGrant>;
  validate(input: {
    userId: string;
    threadId: string;
    uploadId: string;
    fileName: string;
    contentType: ChatPhotoContentType;
    sizeBytes: number;
  }): Promise<ChatValidatedPhoto>;
  readUrl(input: {
    objectPath: string;
    generation: string;
  }): Promise<{ readUrl: string; expiresAt: string }>;
}

export interface ChatReplyRecord {
  messageId: string;
  senderName: string;
  text: string;
}

export interface ChatRepository {
  listThreads(userId: string, limit: number): Promise<ChatThreadRecord[]>;
  listMessages(
    userId: string,
    threadId: string,
    limit: number,
  ): Promise<ChatMessageRecord[]>;
  createDirectThread(
    actor: ChatProfile,
    target: ChatProfile,
  ): Promise<ChatThreadRecord>;
  sendMessage(
    actor: ChatProfile,
    threadId: string,
    text: string,
    idempotencyKey: string,
    requestDigest: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageRecord>;
  preparePhotoUpload(
    actor: ChatProfile,
    threadId: string,
    fileName: string,
    contentType: ChatPhotoContentType,
    sizeBytes: number,
  ): Promise<ChatPhotoUploadGrant>;
  sendPhotoMessage(
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
  ): Promise<ChatMessageRecord>;
  prepareAttachmentUpload?(
    actor: ChatProfile,
    threadId: string,
    kind: ChatAttachmentKind,
    fileName: string,
    contentType: string,
    sizeBytes: number,
    durationMilliseconds?: number,
  ): Promise<ChatAttachmentUploadGrant>;
  sendAttachmentMessage?(
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
  ): Promise<ChatMessageRecord>;
  setReaction(
    actor: ChatProfile,
    threadId: string,
    messageId: string,
    reacted: boolean,
  ): Promise<ChatMessageRecord>;
  forwardMessage(
    actor: ChatProfile,
    sourceThreadId: string,
    sourceMessageId: string,
    targetThreadId: string,
    idempotencyKey: string,
    requestDigest: string,
  ): Promise<ChatMessageRecord>;
  markThreadRead(userId: string, threadId: string): Promise<ChatReadResult>;
  getPrivacySettings?(userId: string): Promise<ChatPrivacySettings>;
  updatePrivacySettings?(
    userId: string,
    settings: Omit<ChatPrivacySettings, "updatedAt">,
  ): Promise<ChatPrivacySettings>;
  listBlockedAccounts?(userId: string): Promise<ChatBlockedAccount[]>;
  setBlockedAccount?(
    actor: ChatProfile,
    target: ChatProfile,
    blocked: boolean,
  ): Promise<{ blocked: boolean }>;
  listMessageRequests?(userId: string): Promise<ChatMessageRequestRecord[]>;
  resolveMessageRequest?(
    userId: string,
    threadId: string,
    accepted: boolean,
  ): Promise<{ threadId: string; accepted: boolean }>;
  getCallPreferences?(userId: string): Promise<ChatCallPreferences>;
  updateCallPreferences?(
    userId: string,
    preferences: Omit<ChatCallPreferences, "updatedAt">,
  ): Promise<ChatCallPreferences>;
  setPresence?(
    userId: string,
    state: ChatPresenceState,
  ): Promise<{ state: ChatPresenceState; updatedAt: string }>;
  getCallAvailability?(
    userId: string,
    threadId: string,
    kind: ChatCallKind,
  ): Promise<ChatCallAvailability>;
  startCall?(
    actor: ChatProfile,
    threadId: string,
    kind: ChatCallKind,
    idempotencyKey: string,
  ): Promise<ChatCallRecord>;
  respondToCall?(
    userId: string,
    callId: string,
    accepted: boolean,
  ): Promise<ChatCallRecord>;
  endCall?(userId: string, callId: string): Promise<ChatCallRecord>;
  listIncomingCalls?(userId: string): Promise<ChatCallRecord[]>;
}

export type ChatProfileResolver = (userId: string) => Promise<ChatProfile>;

export interface ChatReadResult {
  threadId: string;
  unreadCount: number;
}
