import { createHash, randomUUID } from "node:crypto";

import type { Bucket } from "@google-cloud/storage";
import type {
  DocumentData,
  DocumentReference,
  Firestore,
} from "firebase-admin/firestore";

import {
  SocialContentError,
  type SocialAuthor,
  type SocialAuthorProfileRecord,
  type SocialCommentPage,
  type SocialCommentRecord,
  type SocialContentRepository,
  type SocialFeedPage,
  type SocialInteractionInput,
  type SocialPostRecord,
  type SocialPublishInput,
  type SocialReplyInput,
  type SocialReplyResult,
} from "./contracts.js";

export class FirestoreSocialContentRepository implements SocialContentRepository {
  constructor(
    private readonly firestore: Firestore,
    private readonly bucket: Bucket,
    private readonly now: () => Date = () => new Date(),
    private readonly createId: () => string = randomUUID,
  ) {}

  async publish(author: SocialAuthor, input: SocialPublishInput): Promise<SocialPostRecord> {
    const idempotencyId = digest(`${author.userId}:${input.idempotencyKey}`);
    const idempotencyRef = this.firestore.collection("socialPublishIdempotency").doc(idempotencyId);
    const existing = await idempotencyRef.get();
    if (existing.exists) {
      assertSameDigest(existing.data(), input.requestDigest);
      return this.readPost(author.userId, String(existing.get("postId")));
    }

    let quotedPost: DocumentData | undefined;
    if (input.quotedPostId) {
      const quoted = await this.firestore.collection("socialPosts").doc(input.quotedPostId).get();
      if (!quoted.exists || quoted.get("audience") !== "Public") {
        throw new SocialContentError(
          "not_found",
          "That shared Feed post is no longer available.",
          404,
        );
      }
      const quotedData = quoted.data()!;
      const quotedMedia = Array.isArray(quotedData.media) ? quotedData.media : [];
      quotedPost = {
        id: quoted.id,
        authorName: String(quotedData.authorName),
        authorHandle: String(quotedData.authorHandle),
        body: String(quotedData.body ?? ""),
        ...(quotedMedia[0]?.url ? { mediaUrl: String(quotedMedia[0].url) } : {}),
      };
    }

    const postId = this.createId();
    const media = await this.persistMedia(author.userId, postId, input);
    const mediaBySlot = new Map(media.map((item) => [item.slot, item]));
    const publishedAt = this.now().toISOString();
    const postRef = this.firestore.collection("socialPosts").doc(postId);
    const postData: DocumentData = {
      schemaVersion: 1,
      type: input.type,
      authorId: author.userId,
      authorName: author.name,
      authorHandle: author.handle,
      body: input.body,
      audience: input.audience,
      publishedAt,
      sortKey: `${publishedAt}_${postId}`,
      media: input.mediaSlots.map((slot) => mediaBySlot.get(slot)),
      choices: input.choices.map((choice) => ({
        label: choice.label,
        ...(choice.mediaSlot
          ? { image: mediaBySlot.get(choice.mediaSlot) }
          : {}),
        votes: 0,
      })),
      correctChoiceIndex: input.correctChoiceIndex ?? null,
      quotedPost: quotedPost ?? null,
      closesAt: input.choices.length > 0
        ? new Date(this.now().getTime() + 7 * 24 * 60 * 60 * 1000).toISOString()
        : null,
      likeCount: 0,
      replyCount: 0,
      repostCount: 0,
      shareCount: 0,
      updatedAt: publishedAt,
    };

    let selectedPostId = postId;
    try {
      await this.firestore.runTransaction(async (transaction) => {
        const current = await transaction.get(idempotencyRef);
        if (current.exists) {
          assertSameDigest(current.data(), input.requestDigest);
          selectedPostId = String(current.get("postId"));
          return;
        }
        transaction.create(postRef, postData);
        transaction.create(idempotencyRef, {
          schemaVersion: 1,
          userId: author.userId,
          postId,
          requestDigest: input.requestDigest,
          createdAt: publishedAt,
        });
      });
    } catch (error) {
      const recovered = await idempotencyRef.get().catch(() => undefined);
      if (!recovered?.exists) {
        await this.removeMedia(media);
        throw error;
      }
      try {
        assertSameDigest(recovered.data(), input.requestDigest);
      } catch (conflict) {
        await this.removeMedia(media);
        throw conflict;
      }
      selectedPostId = String(recovered.get("postId"));
    }
    if (selectedPostId !== postId) {
      await this.removeMedia(media);
    }
    return this.readPost(author.userId, selectedPostId);
  }

  async feed(userId: string | undefined, cursor: string | undefined, limit: number): Promise<SocialFeedPage> {
    let query = this.firestore
      .collection("socialPosts")
      .orderBy("sortKey", "desc")
      .limit(limit + 1);
    if (cursor) {
      if (!isValidSocialFeedCursor(cursor)) {
        throw new SocialContentError("bad_request", "Feed cursor is invalid.", 400);
      }
      query = query.startAfter(cursor);
    }
    const snapshot = await query.get();
    const visible = snapshot.docs.slice(0, limit);
    const interactionRefs = userId === undefined
      ? []
      : visible.map((document) => this.interactionRef(document.id, userId));
    const interactions = interactionRefs.length > 0
      ? await this.firestore.getAll(...interactionRefs)
      : [];
    const nextCursor = snapshot.docs.length > limit
      ? String(visible[visible.length - 1]?.get("sortKey"))
      : undefined;
    return {
      items: visible.map((document, index) =>
        recordFromDocument(document.id, document.data(), interactions[index]?.data()),
      ),
      ...(nextCursor === undefined ? {} : { nextCursor }),
    };
  }

  async interact(userId: string, input: SocialInteractionInput): Promise<SocialPostRecord> {
    const postRef = this.firestore.collection("socialPosts").doc(input.postId);
    const interactionRef = this.interactionRef(input.postId, userId);
    let postData: DocumentData | undefined;
    let interactionData: DocumentData | undefined;
    await this.firestore.runTransaction(async (transaction) => {
      const post = await transaction.get(postRef);
      if (!post.exists) {
        throw new SocialContentError("not_found", "That Feed post is no longer available.", 404);
      }
      const interaction = await transaction.get(interactionRef);
      postData = { ...post.data() };
      interactionData = interaction.exists ? { ...interaction.data() } : {};
      const now = this.now().toISOString();
      if (input.type === "like") {
        const liked = interactionData.liked === true;
        interactionData.liked = !liked;
        postData.likeCount = Math.max(0, Number(postData.likeCount ?? 0) + (liked ? -1 : 1));
      } else if (input.type === "save") {
        interactionData.saved = interactionData.saved !== true;
      } else if (input.type === "repost") {
        const reposted = interactionData.reposted === true;
        interactionData.reposted = !reposted;
        postData.repostCount = Math.max(
          0,
          Number(postData.repostCount ?? 0) + (reposted ? -1 : 1),
        );
      } else {
        if (isSocialPollClosed(postData.closesAt, this.now())) {
          throw new SocialContentError("conflict", "This poll is closed.", 409);
        }
        if (interactionData.selectedChoiceIndex !== undefined) {
          throw new SocialContentError("conflict", "You already voted on this post.", 409);
        }
        const choices = Array.isArray(postData.choices)
          ? postData.choices.map((choice: DocumentData) => ({ ...choice }))
          : [];
        const choiceIndex = input.choiceIndex!;
        const selectedChoice = choices[choiceIndex];
        if (!selectedChoice) {
          throw new SocialContentError("bad_request", "Choose a valid poll option.", 400);
        }
        selectedChoice.votes = Number(selectedChoice.votes ?? 0) + 1;
        postData.choices = choices;
        interactionData.selectedChoiceIndex = choiceIndex;
      }
      postData.updatedAt = now;
      interactionData.userId = userId;
      interactionData.postId = input.postId;
      interactionData.updatedAt = now;
      transaction.update(postRef, postData);
      transaction.set(interactionRef, interactionData);
    });
    return recordFromDocument(input.postId, postData!, interactionData);
  }

  async comments(
    postId: string,
    cursor: string | undefined,
    limit: number,
  ): Promise<SocialCommentPage> {
    const postRef = this.firestore.collection("socialPosts").doc(postId);
    const post = await postRef.get();
    if (!post.exists || post.get("audience") !== "Public") {
      throw new SocialContentError("not_found", "That Feed post is no longer available.", 404);
    }
    let query = postRef.collection("comments").orderBy("sortKey", "desc").limit(limit + 1);
    if (cursor) {
      if (!isValidSocialFeedCursor(cursor)) {
        throw new SocialContentError("bad_request", "Reply cursor is invalid.", 400);
      }
      query = query.startAfter(cursor);
    }
    const snapshot = await query.get();
    const visible = snapshot.docs.slice(0, limit);
    const nextCursor = snapshot.docs.length > limit
      ? String(visible[visible.length - 1]?.get("sortKey"))
      : undefined;
    return {
      items: visible.map((document) => commentRecordFromDocument(document.id, document.data())),
      ...(nextCursor === undefined ? {} : { nextCursor }),
    };
  }

  async reply(author: SocialAuthor, input: SocialReplyInput): Promise<SocialReplyResult> {
    const idempotencyId = digest(`${author.userId}:${input.idempotencyKey}`);
    const idempotencyRef = this.firestore.collection("socialReplyIdempotency").doc(idempotencyId);
    const postRef = this.firestore.collection("socialPosts").doc(input.postId);
    let selectedCommentId = this.createId();
    const existing = await idempotencyRef.get();
    if (existing.exists) {
      assertSameReplyDigest(existing.data(), input.requestDigest);
      selectedCommentId = String(existing.get("commentId"));
    } else {
      const publishedAt = this.now().toISOString();
      const commentRef = postRef.collection("comments").doc(selectedCommentId);
      const commentData: DocumentData = {
        schemaVersion: 1,
        postId: input.postId,
        authorId: author.userId,
        authorName: author.name,
        authorHandle: author.handle,
        body: input.body,
        publishedAt,
        sortKey: `${publishedAt}_${selectedCommentId}`,
      };
      try {
        await this.firestore.runTransaction(async (transaction) => {
          const [idempotency, post] = await Promise.all([
            transaction.get(idempotencyRef),
            transaction.get(postRef),
          ]);
          if (idempotency.exists) {
            assertSameReplyDigest(idempotency.data(), input.requestDigest);
            selectedCommentId = String(idempotency.get("commentId"));
            return;
          }
          if (!post.exists || post.get("audience") !== "Public") {
            throw new SocialContentError(
              "not_found",
              "That Feed post is no longer available.",
              404,
            );
          }
          transaction.create(commentRef, commentData);
          transaction.update(postRef, {
            replyCount: Number(post.get("replyCount") ?? 0) + 1,
            updatedAt: publishedAt,
          });
          transaction.create(idempotencyRef, {
            userId: author.userId,
            postId: input.postId,
            commentId: selectedCommentId,
            requestDigest: input.requestDigest,
            createdAt: publishedAt,
          });
        });
      } catch (error) {
        const recovered = await idempotencyRef.get().catch(() => undefined);
        if (!recovered?.exists) throw error;
        assertSameReplyDigest(recovered.data(), input.requestDigest);
        selectedCommentId = String(recovered.get("commentId"));
      }
    }
    const comment = await postRef.collection("comments").doc(selectedCommentId).get();
    if (!comment.exists) {
      throw new SocialContentError(
        "unavailable",
        "Your reply is still being confirmed. Please try again.",
        503,
        true,
      );
    }
    return {
      comment: commentRecordFromDocument(comment.id, comment.data()!),
      post: await this.readPost(author.userId, input.postId),
    };
  }

  async author(
    viewerUserId: string | undefined,
    authorId: string,
    limit: number,
  ): Promise<SocialAuthorProfileRecord> {
    const snapshot = await this.firestore
      .collection("socialPosts")
      .where("authorId", "==", authorId)
      .limit(Math.max(20, limit * 3))
      .get();
    const publicDocuments = snapshot.docs
      .filter((document) => document.get("audience") === "Public")
      .sort((left, right) => {
        const leftValue = String(left.get("sortKey") ?? left.get("publishedAt") ?? "");
        const rightValue = String(right.get("sortKey") ?? right.get("publishedAt") ?? "");
        return rightValue.localeCompare(leftValue);
      })
      .slice(0, limit);
    const first = publicDocuments[0];
    if (!first) {
      throw new SocialContentError(
        "not_found",
        "That MoolSocial author is no longer available.",
        404,
      );
    }
    const metricsRef = this.firestore.collection("socialAuthorMetrics").doc(authorId);
    const relationshipRef = viewerUserId
      ? this.followRelationshipRef(viewerUserId, authorId)
      : undefined;
    const [metrics, relationship] = await Promise.all([
      metricsRef.get(),
      relationshipRef?.get(),
    ]);
    return {
      authorId,
      authorName: String(first.get("authorName")),
      authorHandle: String(first.get("authorHandle")),
      followerCount: Math.max(0, Number(metrics.get("followerCount") ?? 0)),
      followed: relationship?.get("followed") === true,
      isSelf: viewerUserId === authorId,
      posts: publicDocuments.map((document) =>
        recordFromDocument(document.id, document.data(), undefined)),
    };
  }

  async follow(
    viewer: SocialAuthor,
    authorId: string,
    followed: boolean,
  ): Promise<SocialAuthorProfileRecord> {
    await this.author(undefined, authorId, 1);
    const relationshipRef = this.followRelationshipRef(viewer.userId, authorId);
    const metricsRef = this.firestore.collection("socialAuthorMetrics").doc(authorId);
    const updatedAt = this.now().toISOString();
    await this.firestore.runTransaction(async (transaction) => {
      const [relationship, metrics] = await Promise.all([
        transaction.get(relationshipRef),
        transaction.get(metricsRef),
      ]);
      const current = relationship.get("followed") === true;
      const currentCount = Math.max(0, Number(metrics.get("followerCount") ?? 0));
      const followerCount = current === followed
        ? currentCount
        : Math.max(0, currentCount + (followed ? 1 : -1));
      transaction.set(relationshipRef, {
        viewerUserId: viewer.userId,
        authorId,
        followed,
        updatedAt,
      });
      transaction.set(metricsRef, { followerCount, updatedAt }, { merge: true });
    });
    return this.author(viewer.userId, authorId, 12);
  }

  private async readPost(userId: string, postId: string): Promise<SocialPostRecord> {
    const postRef = this.firestore.collection("socialPosts").doc(postId);
    const [post, interaction] = await this.firestore.getAll(
      postRef,
      this.interactionRef(postId, userId),
    );
    if (!post || !post.exists) {
      throw new SocialContentError("not_found", "That Feed post is no longer available.", 404);
    }
    return recordFromDocument(post.id, post.data()!, interaction?.data());
  }

  private interactionRef(postId: string, userId: string): DocumentReference {
    return this.firestore
      .collection("socialPostInteractions")
      .doc(digest(`${postId}:${userId}`));
  }

  private followRelationshipRef(
    viewerUserId: string,
    authorId: string,
  ): DocumentReference {
    return this.firestore
      .collection("socialFollowRelationships")
      .doc(digest(`${viewerUserId}:${authorId}`));
  }

  private async persistMedia(
    userId: string,
    postId: string,
    input: SocialPublishInput,
  ): Promise<DocumentData[]> {
    const uploaded: DocumentData[] = [];
    try {
      for (const media of input.media) {
        const extension = extensionFor(media.contentType);
        const objectPath = `social-media/${userId}/${postId}/${media.slot.replace(":", "-")}.${extension}`;
        const downloadToken = this.createId();
        await this.bucket.file(objectPath).save(media.bytes, {
          resumable: false,
          validation: "crc32c",
          contentType: media.contentType,
          metadata: {
            cacheControl: "public,max-age=3600,must-revalidate",
            metadata: {
              firebaseStorageDownloadTokens: downloadToken,
              ownerUserId: userId,
              sha256: media.sha256,
            },
          },
        });
        uploaded.push({
          slot: media.slot,
          path: objectPath,
          url: firebaseDownloadUrl(this.bucket.name, objectPath, downloadToken),
          contentType: media.contentType,
          byteLength: media.byteLength,
          sha256: media.sha256,
        });
      }
      return uploaded;
    } catch (error) {
      await this.removeMedia(uploaded);
      throw error;
    }
  }

  private async removeMedia(media: DocumentData[]): Promise<void> {
    await Promise.allSettled(
      media.map((item) => this.bucket.file(String(item.path)).delete({ ignoreNotFound: true })),
    );
  }
}

export function isSocialPollClosed(closesAt: unknown, now: Date): boolean {
  if (typeof closesAt !== "string") return false;
  const closesAtMilliseconds = Date.parse(closesAt);
  return Number.isFinite(closesAtMilliseconds) && closesAtMilliseconds <= now.getTime();
}

export function isValidSocialFeedCursor(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z_[A-Za-z0-9-]{1,128}$/.test(value);
}

function recordFromDocument(
  id: string,
  post: DocumentData,
  interaction: DocumentData | undefined,
): SocialPostRecord {
  const choices = Array.isArray(post.choices) ? post.choices : [];
  const media = Array.isArray(post.media) ? post.media : [];
  return {
    id,
    type: post.type,
    authorId: String(post.authorId),
    authorName: String(post.authorName),
    authorHandle: String(post.authorHandle),
    body: String(post.body ?? ""),
    audience: "Public",
    publishedAt: String(post.publishedAt),
    mediaUrls: media.map((item: DocumentData) => String(item.url)),
    choices: choices.map((choice: DocumentData) => ({
      label: String(choice.label),
      ...(choice.image?.url ? { imageUrl: String(choice.image.url) } : {}),
      votes: Number(choice.votes ?? 0),
    })),
    ...(integerOrUndefined(post.correctChoiceIndex) === undefined
      ? {}
      : { correctChoiceIndex: integerOrUndefined(post.correctChoiceIndex)! }),
    ...(typeof post.closesAt === "string" ? { closesAt: post.closesAt } : {}),
    ...(post.quotedPost && typeof post.quotedPost === "object"
      ? {
        quotedPost: {
          id: String(post.quotedPost.id),
          authorName: String(post.quotedPost.authorName),
          authorHandle: String(post.quotedPost.authorHandle),
          body: String(post.quotedPost.body ?? ""),
          ...(post.quotedPost.mediaUrl
            ? { mediaUrl: String(post.quotedPost.mediaUrl) }
            : {}),
        },
      }
      : {}),
    liked: interaction?.liked === true,
    saved: interaction?.saved === true,
    reposted: interaction?.reposted === true,
    ...(integerOrUndefined(interaction?.selectedChoiceIndex) === undefined
      ? {}
      : { selectedChoiceIndex: integerOrUndefined(interaction?.selectedChoiceIndex)! }),
    likeCount: Number(post.likeCount ?? 0),
    replyCount: Number(post.replyCount ?? 0),
    repostCount: Number(post.repostCount ?? 0),
    shareCount: Number(post.shareCount ?? 0),
  };
}

function commentRecordFromDocument(
  id: string,
  comment: DocumentData,
): SocialCommentRecord {
  return {
    id,
    postId: String(comment.postId),
    authorId: String(comment.authorId),
    authorName: String(comment.authorName),
    authorHandle: String(comment.authorHandle),
    body: String(comment.body),
    publishedAt: String(comment.publishedAt),
  };
}

function assertSameDigest(data: DocumentData | undefined, expected: string): void {
  if (data?.requestDigest !== expected) {
    throw new SocialContentError(
      "conflict",
      "That retry key belongs to different post content.",
      409,
    );
  }
}

function assertSameReplyDigest(data: DocumentData | undefined, expected: string): void {
  if (data?.requestDigest !== expected) {
    throw new SocialContentError(
      "conflict",
      "That retry key belongs to a different reply.",
      409,
    );
  }
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function extensionFor(contentType: string): string {
  if (contentType === "image/png") return "png";
  if (contentType === "image/webp") return "webp";
  return "jpg";
}

function firebaseDownloadUrl(bucket: string, path: string, token: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucket)}/o/${encodeURIComponent(path)}?alt=media&token=${encodeURIComponent(token)}`;
}

function integerOrUndefined(value: unknown): number | undefined {
  return Number.isSafeInteger(value) ? (value as number) : undefined;
}
