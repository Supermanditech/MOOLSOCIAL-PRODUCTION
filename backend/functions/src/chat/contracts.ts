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
}

export type ChatProfileResolver = (userId: string) => Promise<ChatProfile>;

export interface ChatReadResult {
  threadId: string;
  unreadCount: number;
}
