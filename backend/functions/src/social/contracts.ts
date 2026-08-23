export const SOCIAL_CONTENT_TYPES = [
  "post",
  "carousel",
  "imagePoll",
  "quickPoll",
  "quiz",
] as const;

export type SocialContentType = (typeof SOCIAL_CONTENT_TYPES)[number];
export type SocialInteractionType = "like" | "save" | "vote" | "repost";

export class SocialContentError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly httpStatus: number,
    readonly retryable = false,
  ) {
    super(message);
    this.name = "SocialContentError";
  }
}

export interface SocialAuthor {
  userId: string;
  name: string;
  handle: string;
}

export interface SocialMediaInput {
  slot: string;
  fileName: string;
  contentType: string;
  byteLength: number;
  sha256: string;
  bytesBase64: string;
}

export interface VerifiedSocialMedia {
  slot: string;
  fileName: string;
  contentType: string;
  byteLength: number;
  sha256: string;
  bytes: Buffer;
}

export interface SocialChoiceInput {
  label: string;
  mediaSlot?: string;
}

export interface SocialPublishInput {
  idempotencyKey: string;
  type: SocialContentType;
  body: string;
  audience: "Public";
  mediaSlots: string[];
  media: VerifiedSocialMedia[];
  choices: SocialChoiceInput[];
  correctChoiceIndex?: number;
  quotedPostId?: string;
  requestDigest: string;
}

export interface SocialQuotedPostRecord {
  id: string;
  authorName: string;
  authorHandle: string;
  body: string;
  mediaUrl?: string;
}

export interface SocialPublishedChoiceRecord {
  label: string;
  imageUrl?: string;
  votes: number;
}

export interface SocialPostRecord {
  id: string;
  type: SocialContentType;
  authorId: string;
  authorName: string;
  authorHandle: string;
  body: string;
  audience: "Public";
  publishedAt: string;
  mediaUrls: string[];
  choices: SocialPublishedChoiceRecord[];
  correctChoiceIndex?: number;
  closesAt?: string;
  quotedPost?: SocialQuotedPostRecord;
  liked: boolean;
  saved: boolean;
  reposted?: boolean;
  selectedChoiceIndex?: number;
  likeCount: number;
  replyCount: number;
  repostCount: number;
  shareCount: number;
}

export interface SocialFeedPage {
  items: SocialPostRecord[];
  nextCursor?: string;
}

export interface SocialCommentRecord {
  id: string;
  postId: string;
  authorId: string;
  authorName: string;
  authorHandle: string;
  body: string;
  publishedAt: string;
}

export interface SocialCommentPage {
  items: SocialCommentRecord[];
  nextCursor?: string;
}

export interface SocialReplyInput {
  postId: string;
  idempotencyKey: string;
  body: string;
  requestDigest: string;
}

export interface SocialReplyResult {
  comment: SocialCommentRecord;
  post: SocialPostRecord;
}

export interface SocialAuthorProfileRecord {
  authorId: string;
  authorName: string;
  authorHandle: string;
  followerCount: number;
  followed: boolean;
  isSelf: boolean;
  posts: SocialPostRecord[];
}

export interface SocialInteractionInput {
  postId: string;
  type: SocialInteractionType;
  choiceIndex?: number;
}

export interface SocialContentRepository {
  publish(author: SocialAuthor, input: SocialPublishInput): Promise<SocialPostRecord>;
  feed(userId: string | undefined, cursor: string | undefined, limit: number): Promise<SocialFeedPage>;
  interact(userId: string, input: SocialInteractionInput): Promise<SocialPostRecord>;
  comments(postId: string, cursor: string | undefined, limit: number): Promise<SocialCommentPage>;
  reply(author: SocialAuthor, input: SocialReplyInput): Promise<SocialReplyResult>;
  author(
    viewerUserId: string | undefined,
    authorId: string,
    limit: number,
  ): Promise<SocialAuthorProfileRecord>;
  follow(
    viewer: SocialAuthor,
    authorId: string,
    followed: boolean,
  ): Promise<SocialAuthorProfileRecord>;
}

export type SocialAuthorResolver = (userId: string) => Promise<SocialAuthor>;
