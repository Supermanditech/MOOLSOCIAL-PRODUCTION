import { createHash } from "node:crypto";

import {
  FieldValue,
  type DocumentData,
  type Firestore,
  type Query,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";

import type {
  MetaAccountErasureStore,
  MetaAccountErasureWorker,
  MetaErasureRecord,
} from "./meta_account_erasure.js";

const REQUESTS = "metaAccountErasureRequests";

export interface MetaErasureStorageBucket {
  deleteFiles(options: { readonly prefix: string }): Promise<unknown>;
  file(path: string, options?: { readonly generation?: string }): {
    delete(options?: { readonly ignoreNotFound?: boolean }): Promise<unknown>;
  };
}

export interface MetaErasureYouTubeRevoker {
  revokeAndDelete(userId: string): Promise<void>;
}

export interface MetaErasureAuth {
  deleteUser(userId: string): Promise<void>;
}

export interface MetaErasureDataConnect {
  executeMutation(
    name: string,
    variables: Readonly<Record<string, unknown>>,
  ): Promise<unknown>;
}

function requiredString(
  value: unknown,
  field: string,
  pattern: RegExp,
): string {
  if (typeof value !== "string" || !pattern.test(value)) {
    throw new Error(`Meta erasure ${field} is invalid.`);
  }
  return value;
}

function storedRecord(
  confirmationCode: string,
  data: DocumentData,
): MetaErasureRecord {
  const firebaseUserIds = Array.isArray(data.firebaseUserIds)
    ? data.firebaseUserIds.map((value) =>
      requiredString(value, "user", /^[A-Za-z0-9:_-]{1,128}$/u))
    : [];
  if (firebaseUserIds.length > 100) {
    throw new Error("Meta erasure users are invalid.");
  }
  const state = data.state;
  if (state !== "pending" && state !== "completed" && state !== "failed") {
    throw new Error("Meta erasure state is invalid.");
  }
  const provider = data.provider;
  if (provider !== "facebook" && provider !== "instagram") {
    throw new Error("Meta erasure provider is invalid.");
  }
  if (!Number.isInteger(data.attemptCount) || data.attemptCount < 1) {
    throw new Error("Meta erasure attempt count is invalid.");
  }
  return {
    confirmationCode,
    requestDigest: requiredString(
      data.requestDigest,
      "request digest",
      /^[A-Za-z0-9_-]{43}$/u,
    ),
    provider,
    firebaseUserIds,
    state,
    requestedAt: requiredString(data.requestedAt, "requested time", /^\S+$/u),
    dueAt: requiredString(data.dueAt, "due time", /^\S+$/u),
    attemptCount: data.attemptCount,
    ...(typeof data.completedAt === "string"
      ? { completedAt: data.completedAt }
      : {}),
    ...(typeof data.failedAt === "string" ? { failedAt: data.failedAt } : {}),
    ...(typeof data.failureStage === "string"
      ? { failureStage: data.failureStage }
      : {}),
  };
}

export class FirestoreMetaAccountErasureStore
  implements MetaAccountErasureStore
{
  constructor(private readonly firestore: Firestore) {}

  async read(code: string): Promise<MetaErasureRecord | undefined> {
    const snapshot = await this.firestore.collection(REQUESTS).doc(code).get();
    return snapshot.exists
      ? storedRecord(snapshot.id, snapshot.data() ?? {})
      : undefined;
  }

  async createPending(record: MetaErasureRecord): Promise<boolean> {
    return this.firestore.runTransaction(async (transaction) => {
      const ref = this.firestore.collection(REQUESTS).doc(record.confirmationCode);
      if ((await transaction.get(ref)).exists) return false;
      transaction.create(ref, {
        schemaVersion: 1,
        requestDigest: record.requestDigest,
        provider: record.provider,
        firebaseUserIds: record.firebaseUserIds,
        state: "pending",
        requestedAt: record.requestedAt,
        dueAt: record.dueAt,
        attemptCount: record.attemptCount,
      });
      return true;
    });
  }

  async markPending(code: string, attemptCount: number): Promise<void> {
    await this.firestore.collection(REQUESTS).doc(code).update({
      state: "pending",
      attemptCount,
      completedAt: FieldValue.delete(),
      failedAt: FieldValue.delete(),
      failureStage: FieldValue.delete(),
    });
  }

  async markCompleted(code: string, completedAt: string): Promise<void> {
    await this.firestore.collection(REQUESTS).doc(code).update({
      state: "completed",
      completedAt,
      failedAt: FieldValue.delete(),
      failureStage: FieldValue.delete(),
    });
  }

  async markFailed(
    code: string,
    failedAt: string,
    failureStage: string,
  ): Promise<void> {
    await this.firestore.collection(REQUESTS).doc(code).update({
      state: "failed",
      failedAt,
      failureStage,
    });
  }
}

function deletedIdentity(userId: string): string {
  return `deleted_${createHash("sha256").update(userId).digest("hex").slice(0, 24)}`;
}

function withoutKey(value: unknown, key: string): Record<string, unknown> {
  const result = typeof value === "object" && value !== null && !Array.isArray(value)
    ? { ...(value as Record<string, unknown>) }
    : {};
  delete result[key];
  return result;
}

export class FirebaseMetaAccountErasureWorker
  implements MetaAccountErasureWorker
{
  constructor(
    private readonly firestore: Firestore,
    private readonly bucket: MetaErasureStorageBucket,
    private readonly auth: MetaErasureAuth,
    private readonly dataConnect: MetaErasureDataConnect,
    private readonly youtubeRevoker: MetaErasureYouTubeRevoker,
  ) {}

  async eraseUser(userId: string): Promise<void> {
    await this.eraseSocial(userId);
    await this.eraseChat(userId);
    await this.eraseYouTube(userId);
    await this.dataConnect.executeMutation(
      "EraseMoolSocialUser",
      { userId },
    );
    for (const collection of ["users", "profiles", "workspaces"]) {
      await this.firestore.collection(collection).doc(userId).delete();
    }
    await this.auth.deleteUser(userId).catch((error: unknown) => {
      const code = typeof error === "object" && error !== null && "code" in error
        ? (error as { readonly code?: unknown }).code
        : undefined;
      if (code !== "auth/user-not-found") throw error;
    });
  }

  private async eraseSocial(userId: string): Promise<void> {
    const posts = await this.firestore.collection("socialPosts")
      .where("authorId", "==", userId).get();
    for (const post of posts.docs) {
      const quotedBy = await this.firestore.collection("socialPosts")
        .where("quotedPost.id", "==", post.id).get();
      for (const quote of quotedBy.docs) {
        await quote.ref.update({ quotedPost: FieldValue.delete() });
      }
      await this.deleteQuery(
        this.firestore.collection("socialPostInteractions")
          .where("postId", "==", post.id),
      );
      await this.firestore.recursiveDelete(post.ref);
    }

    const comments = await this.firestore.collectionGroup("comments")
      .where("authorId", "==", userId).get();
    for (const comment of comments.docs) {
      await this.firestore.runTransaction(async (transaction) => {
        const current = await transaction.get(comment.ref);
        if (!current.exists) return;
        transaction.delete(comment.ref);
        const postRef = comment.ref.parent.parent;
        if (postRef) transaction.update(postRef, { replyCount: FieldValue.increment(-1) });
      });
    }

    await this.deleteQuery(this.firestore.collection("socialPostInteractions").where("userId", "==", userId));
    await this.deleteQuery(this.firestore.collection("socialPublishIdempotency").where("userId", "==", userId));
    await this.deleteQuery(this.firestore.collection("socialReplyIdempotency").where("userId", "==", userId));
    const following = await this.firestore.collection("socialFollowRelationships")
      .where("viewerUserId", "==", userId).get();
    for (const relationship of following.docs) {
      await this.firestore.runTransaction(async (transaction) => {
        const current = await transaction.get(relationship.ref);
        if (!current.exists) return;
        const authorId = current.get("authorId");
        const metricsRef = typeof authorId === "string"
          ? this.firestore.collection("socialAuthorMetrics").doc(authorId)
          : undefined;
        const metrics = metricsRef ? await transaction.get(metricsRef) : undefined;
        transaction.delete(relationship.ref);
        if (metricsRef && metrics?.exists) {
          transaction.update(metricsRef, {
            followerCount: FieldValue.increment(-1),
          });
        }
      });
    }
    await this.deleteQuery(this.firestore.collection("socialFollowRelationships").where("authorId", "==", userId));
    await this.firestore.collection("socialAuthorMetrics").doc(userId).delete();
    await this.bucket.deleteFiles({ prefix: `social-media/${userId}/` });
  }

  private async eraseChat(userId: string): Promise<void> {
    const replacementId = deletedIdentity(userId);
    const threads = await this.firestore.collection("chatThreads")
      .where("participantIds", "array-contains", userId).get();
    for (const thread of threads.docs) {
      const messages = await thread.ref.collection("messages").get();
      const authoredIds = new Set(
        messages.docs
          .filter((message) => message.get("senderId") === userId)
          .map((message) => message.id),
      );
      for (const message of messages.docs) {
        await this.anonymizeMessage(message, userId, replacementId, authoredIds);
      }
      await this.deleteQuery(
        thread.ref.collection("attachmentReceipts").where("senderId", "==", userId),
      );
      const participantIds = Array.isArray(thread.get("participantIds"))
        ? thread.get("participantIds").map(String)
        : [];
      await thread.ref.update({
        participantIds: participantIds.map((value: string) => value === userId ? replacementId : value),
        participantProfiles: {
          ...withoutKey(thread.get("participantProfiles"), userId),
          [replacementId]: { userId: replacementId, name: "Deleted account", handle: "" },
        },
        unreadCounts: withoutKey(thread.get("unreadCounts"), userId),
        lastReadAtBy: withoutKey(thread.get("lastReadAtBy"), userId),
      });
    }
  }

  private async anonymizeMessage(
    message: QueryDocumentSnapshot,
    userId: string,
    replacementId: string,
    authoredIds: ReadonlySet<string>,
  ): Promise<void> {
    const reactions = withoutKey(message.get("reactions"), userId);
    const patch: Record<string, unknown> = { reactions };
    if (message.get("senderId") === userId) {
      patch.senderId = replacementId;
      patch.senderName = "Deleted account";
      const photo = message.get("photo");
      if (typeof photo === "object" && photo !== null) {
        const objectPath = (photo as Record<string, unknown>).objectPath;
        const generation = (photo as Record<string, unknown>).generation;
        if (typeof objectPath === "string") {
          await this.bucket.file(
            objectPath,
            typeof generation === "string" ? { generation } : undefined,
          ).delete({ ignoreNotFound: true });
        }
        patch.photo = FieldValue.delete();
        patch.messageType = "text";
        patch.attachmentDeleted = true;
      }
    }
    const replyTo = message.get("replyTo");
    if (typeof replyTo === "object" && replyTo !== null) {
      const reply = replyTo as Record<string, unknown>;
      if (typeof reply.messageId === "string" && authoredIds.has(reply.messageId)) {
        patch.replyTo = { ...reply, senderName: "Deleted account" };
      }
    }
    await message.ref.update(patch);
  }

  private async eraseYouTube(userId: string): Promise<void> {
    await this.youtubeRevoker.revokeAndDelete(userId);
    const connections = await this.firestore.collection("youtubeProviderConnections")
      .where("userId", "==", userId).get();
    for (const connection of connections.docs) {
      const key = connection.get("connectionKey");
      if (typeof key === "string") {
        await this.firestore.collection("youtubeProviderCredentials").doc(key).delete();
      }
      await connection.ref.delete();
    }
    await this.deleteQuery(this.firestore.collection("youtubeProviderOAuthAttempts").where("userId", "==", userId));
    await this.deleteQuery(this.firestore.collection("youtubeProviderPublicationJobs").where("userId", "==", userId));
    const audit = await this.firestore.collection("youtubeProviderAuditEvents")
      .where("userId", "==", userId).get();
    for (const event of audit.docs) {
      await event.ref.update({ userId: FieldValue.delete(), identityErased: true });
    }
  }

  private async deleteQuery(query: Query): Promise<void> {
    const snapshot = await query.get();
    for (const document of snapshot.docs) await document.ref.delete();
  }
}
