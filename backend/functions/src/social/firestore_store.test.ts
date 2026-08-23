import assert from "node:assert/strict";
import test from "node:test";

import type { Bucket } from "@google-cloud/storage";
import type { DocumentData, Firestore } from "firebase-admin/firestore";

import type { SocialPublishInput, SocialReplyInput } from "./contracts.js";
import {
  FirestoreSocialContentRepository,
  isValidSocialFeedCursor,
  isSocialPollClosed,
} from "./firestore_store.js";

test("accepts the exact server-generated Feed cursor shape", () => {
  assert.equal(
    isValidSocialFeedCursor("2026-08-11T12:34:56.789Z_8c16f72e-bccc-4bcb-a10c-4e4c2f857bcc"),
    true,
  );
});

test("rejects malformed or query-shaped Feed cursors", () => {
  assert.equal(isValidSocialFeedCursor("cursor-1"), false);
  assert.equal(
    isValidSocialFeedCursor("2026-08-11T12:34:56.789Z_post?limit=100"),
    false,
  );
  assert.equal(
    isValidSocialFeedCursor("2026-08-11T12:34:56.789Z_post/another"),
    false,
  );
});

test("poll closure uses the authoritative instant", () => {
  const now = new Date("2026-08-13T12:00:00.000Z");
  assert.equal(isSocialPollClosed(undefined, now), false);
  assert.equal(isSocialPollClosed("invalid", now), false);
  assert.equal(isSocialPollClosed("2026-08-13T12:00:00.001Z", now), false);
  assert.equal(isSocialPollClosed("2026-08-13T12:00:00.000Z", now), true);
  assert.equal(isSocialPollClosed("2026-08-13T11:59:59.999Z", now), true);
});

test("an expired poll vote is rejected before every Firestore write", async () => {
  const writes: string[] = [];
  const repository = new FirestoreSocialContentRepository(
    interactionFirestore(
      {
        type: "quickPoll",
        authorId: "author-1",
        authorName: "Verified Person",
        authorHandle: "@verified",
        body: "Choose one",
        audience: "Public",
        publishedAt: "2026-08-01T12:00:00.000Z",
        closesAt: "2026-08-13T11:59:59.999Z",
        media: [],
        choices: [
          { label: "One", votes: 0 },
          { label: "Two", votes: 0 },
          { label: "Three", votes: 0 },
          { label: "Four", votes: 0 },
        ],
        likeCount: 0,
        replyCount: 0,
        repostCount: 0,
        shareCount: 0,
      },
      writes,
    ) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-13T12:00:00.000Z"),
  );

  await assert.rejects(
    repository.interact("user-1", {
      postId: "expired-poll",
      type: "vote",
      choiceIndex: 1,
    }),
    /This poll is closed/u,
  );
  assert.deepEqual(writes, []);
});

test("repost changes durable count and per-user truth in one transaction", async () => {
  const writes: string[] = [];
  const repository = new FirestoreSocialContentRepository(
    interactionFirestore(committedPost(), writes) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-13T12:00:00.000Z"),
  );

  const result = await repository.interact("user-1", {
    postId: "public-post-1",
    type: "repost",
  });

  assert.equal(result.reposted, true);
  assert.equal(result.repostCount, 1);
  assert.deepEqual(writes, ["update", "set"]);
});

test("public comments return bounded durable rows and an exact next cursor", async () => {
  const cursor = "2026-08-13T11:59:00.000Z_comment-2";
  const repository = new FirestoreSocialContentRepository(
    commentReadFirestore([
      commentData("comment-1", "2026-08-13T12:00:00.000Z_comment-1"),
      commentData("comment-2", cursor),
    ]) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-13T12:00:00.000Z"),
  );

  const page = await repository.comments("public-post-1", undefined, 1);

  assert.equal(page.items.length, 1);
  assert.equal(page.items[0]?.body, "Reply comment-1");
  assert.equal(page.nextCursor, "2026-08-13T12:00:00.000Z_comment-1");
});

test("reply creates one durable comment and increments once across an idempotent retry", async () => {
  const state = replyFirestoreState();
  const repository = new FirestoreSocialContentRepository(
    replyFirestore(state) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-13T12:00:00.000Z"),
    () => "created-comment-1",
  );
  const input: SocialReplyInput = {
    postId: "public-post-1",
    idempotencyKey: "reply-retry-key-0001",
    body: "A durable reply",
    requestDigest: "reply-request-digest",
  };

  const first = await repository.reply(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    input,
  );
  const second = await repository.reply(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    input,
  );

  assert.equal(first.comment.id, "created-comment-1");
  assert.equal(second.comment.id, "created-comment-1");
  assert.equal(first.post.replyCount, 1);
  assert.equal(second.post.replyCount, 1);
  assert.equal(state.commentCreates, 1);
  assert.equal(state.idempotencyCreates, 1);
});

test("author returns only bounded public posts and no private profile fields", async () => {
  const state = authorFirestoreState();
  const repository = new FirestoreSocialContentRepository(
    authorFirestore(state) as unknown as Firestore,
    fakeBucket([], []),
  );

  const profile = await repository.author(undefined, "author-1", 1);

  assert.equal(profile.authorId, "author-1");
  assert.equal(profile.authorName, "Public Author");
  assert.equal(profile.posts.length, 1);
  assert.equal(profile.posts[0]?.body, "Newest public post");
  assert.equal(profile.followed, false);
  assert.equal(profile.followerCount, 4);
  assert.equal("email" in profile, false);
});

test("Follow and Unfollow update relationship and follower count idempotently", async () => {
  const state = authorFirestoreState();
  const repository = new FirestoreSocialContentRepository(
    authorFirestore(state) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-13T12:00:00.000Z"),
  );
  const viewer = { userId: "viewer-1", name: "Viewer", handle: "@viewer" };

  const followed = await repository.follow(viewer, "author-1", true);
  const repeated = await repository.follow(viewer, "author-1", true);
  const unfollowed = await repository.follow(viewer, "author-1", false);

  assert.equal(followed.followed, true);
  assert.equal(followed.followerCount, 5);
  assert.equal(repeated.followerCount, 5);
  assert.equal(unfollowed.followed, false);
  assert.equal(unfollowed.followerCount, 4);
  assert.equal(state.relationshipWrites, 3);
  assert.equal(state.metricsWrites, 3);
});

test("an idempotency race keeps the committed post media and removes only the losing upload", async () => {
  const saved: string[] = [];
  const deleted: string[] = [];
  const firestore = fakeFirestore({
    transactionWinner: {
      postId: "winner-post",
      requestDigest: "request-digest",
    },
  });
  const repository = new FirestoreSocialContentRepository(
    firestore as unknown as Firestore,
    fakeBucket(saved, deleted),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "candidate-post",
  );

  const result = await repository.publish(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    publishInput(),
  );

  assert.equal(result.id, "winner-post");
  assert.deepEqual(saved, ["social-media/user-1/candidate-post/media-0.jpg"]);
  assert.deepEqual(deleted, ["social-media/user-1/candidate-post/media-0.jpg"]);
});

test("a failed uncommitted publish removes its uploaded media", async () => {
  const saved: string[] = [];
  const deleted: string[] = [];
  const repository = new FirestoreSocialContentRepository(
    fakeFirestore({ transactionFailure: new Error("transaction failed") }) as unknown as Firestore,
    fakeBucket(saved, deleted),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "candidate-post",
  );

  await assert.rejects(
    repository.publish(
      { userId: "user-1", name: "Verified Person", handle: "@verified" },
      publishInput(),
    ),
    /transaction failed/u,
  );
  assert.deepEqual(saved, ["social-media/user-1/candidate-post/media-0.jpg"]);
  assert.deepEqual(deleted, ["social-media/user-1/candidate-post/media-0.jpg"]);
});

test("an ambiguous transaction result preserves media only when its own commit is recovered", async () => {
  const saved: string[] = [];
  const deleted: string[] = [];
  const repository = new FirestoreSocialContentRepository(
    fakeFirestore({
      transactionFailure: new Error("ambiguous transaction result"),
      recoveredIdempotency: {
        postId: "candidate-post",
        requestDigest: "request-digest",
      },
    }) as unknown as Firestore,
    fakeBucket(saved, deleted),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "candidate-post",
  );

  const result = await repository.publish(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    publishInput(),
  );

  assert.equal(result.id, "candidate-post");
  assert.deepEqual(saved, ["social-media/user-1/candidate-post/media-0.jpg"]);
  assert.deepEqual(deleted, []);
});

test("a recovered conflicting idempotency commit removes the rejected upload", async () => {
  const saved: string[] = [];
  const deleted: string[] = [];
  const repository = new FirestoreSocialContentRepository(
    fakeFirestore({
      transactionFailure: new Error("ambiguous transaction result"),
      recoveredIdempotency: {
        postId: "different-post",
        requestDigest: "different-digest",
      },
    }) as unknown as Firestore,
    fakeBucket(saved, deleted),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "candidate-post",
  );

  await assert.rejects(
    repository.publish(
      { userId: "user-1", name: "Verified Person", handle: "@verified" },
      publishInput(),
    ),
    /different post content/u,
  );
  assert.deepEqual(saved, ["social-media/user-1/candidate-post/media-0.jpg"]);
  assert.deepEqual(deleted, ["social-media/user-1/candidate-post/media-0.jpg"]);
});

test("a four-choice text poll omits every undefined Firestore field", async () => {
  const createdPosts: DocumentData[] = [];
  const repository = new FirestoreSocialContentRepository(
    fakeFirestore({ createdPosts }) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "quick-poll-post",
  );

  await repository.publish(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    {
      idempotencyKey: "social-quick-poll-key-0001",
      type: "quickPoll",
      body: "Choose one",
      audience: "Public",
      mediaSlots: [],
      media: [],
      choices: [
        { label: "One" },
        { label: "Two" },
        { label: "Three" },
        { label: "Four" },
      ],
      requestDigest: "quick-poll-digest",
    },
  );

  assert.equal(createdPosts.length, 1);
  assert.equal(hasUndefined(createdPosts[0]), false);
  assert.deepEqual(createdPosts[0]?.choices, [
    { label: "One", votes: 0 },
    { label: "Two", votes: 0 },
    { label: "Three", votes: 0 },
    { label: "Four", votes: 0 },
  ]);
});

test("quoted publish snapshots only the exact public source post", async () => {
  const createdPosts: DocumentData[] = [];
  const repository = new FirestoreSocialContentRepository(
    fakeFirestore({
      createdPosts,
      sourcePosts: {
        "original-post-1": {
          ...committedPost(),
          authorName: "Original author",
          authorHandle: "@original",
          body: "Original public post",
          audience: "Public",
          media: [{ url: "https://example.test/original.jpg" }],
        },
      },
    }) as unknown as Firestore,
    fakeBucket([], []),
    () => new Date("2026-08-11T12:34:56.789Z"),
    () => "quoted-post",
  );

  await repository.publish(
    { userId: "user-1", name: "Verified Person", handle: "@verified" },
    {
      idempotencyKey: "quoted-publish-key-0001",
      type: "post",
      body: "My thoughts",
      audience: "Public",
      mediaSlots: [],
      media: [],
      choices: [],
      quotedPostId: "original-post-1",
      requestDigest: "quoted-request-digest",
    },
  );

  assert.deepEqual(createdPosts[0]?.quotedPost, {
    id: "original-post-1",
    authorName: "Original author",
    authorHandle: "@original",
    body: "Original public post",
    mediaUrl: "https://example.test/original.jpg",
  });
});

function publishInput(): SocialPublishInput {
  return {
    idempotencyKey: "social-accepted-key-0001",
    type: "post",
    body: "Durable post",
    audience: "Public",
    mediaSlots: ["media:0"],
    media: [
      {
        slot: "media:0",
        fileName: "photo.jpg",
        contentType: "image/jpeg",
        byteLength: 1,
        sha256: "sha256",
        bytes: Buffer.from([1]),
      },
    ],
    choices: [],
    requestDigest: "request-digest",
  };
}

function fakeBucket(saved: string[], deleted: string[]): Bucket {
  return {
    name: "test.appspot.com",
    file: (path: string) => ({
      save: async () => {
        saved.push(path);
      },
      delete: async () => {
        deleted.push(path);
      },
    }),
  } as unknown as Bucket;
}

function fakeFirestore(options: {
  transactionWinner?: { postId: string; requestDigest: string };
  transactionFailure?: Error;
  recoveredIdempotency?: { postId: string; requestDigest: string };
  createdPosts?: DocumentData[];
  sourcePosts?: Record<string, DocumentData>;
}): object {
  let idempotencyReadCount = 0;
  const reference = (collectionName: string, id: string) => ({
    collectionName,
    id,
    get: async () => {
      if (collectionName === "socialPosts") {
        return document(id, options.sourcePosts?.[id]);
      }
      idempotencyReadCount += 1;
      return document(
        id,
        idempotencyReadCount > 1 ? options.recoveredIdempotency : undefined,
      );
    },
  });
  return {
    collection: (collectionName: string) => ({
      doc: (id: string) => reference(collectionName, id),
    }),
    runTransaction: async (callback: (transaction: object) => Promise<void>) => {
      if (options.transactionFailure) throw options.transactionFailure;
      await callback({
        get: async () => document("idempotency", options.transactionWinner),
        create: (
          target: { collectionName: string },
          data: DocumentData,
        ) => {
          if (target.collectionName === "socialPosts") {
            options.createdPosts?.push(data);
          }
        },
      });
    },
    getAll: async (...references: Array<{ collectionName: string; id: string }>) =>
      references.map((item) =>
        item.collectionName === "socialPosts"
          ? document(item.id, committedPost())
          : document(item.id, undefined),
      ),
    get idempotencyReadCount() {
      return idempotencyReadCount;
    },
  };
}

function interactionFirestore(postData: DocumentData, writes: string[]): object {
  const reference = (collectionName: string, id: string) => ({ collectionName, id });
  return {
    collection: (collectionName: string) => ({
      doc: (id: string) => reference(collectionName, id),
    }),
    runTransaction: async (callback: (transaction: object) => Promise<void>) => {
      await callback({
        get: async (target: { collectionName: string; id: string }) =>
          target.collectionName === "socialPosts"
            ? document(target.id, postData)
            : document(target.id, undefined),
        update: () => writes.push("update"),
        set: () => writes.push("set"),
      });
    },
  };
}

function commentReadFirestore(comments: DocumentData[]): object {
  const postDocument = document("public-post-1", {
    ...committedPost(),
    audience: "Public",
  });
  return {
    collection: (collectionName: string) => ({
      doc: (id: string) => ({
        id,
        get: async () => collectionName === "socialPosts"
          ? postDocument
          : document(id, undefined),
        collection: () => ({
          orderBy: () => ({
            limit: () => ({
              startAfter: () => ({ get: async () => ({ docs: comments }) }),
              get: async () => ({ docs: comments }),
            }),
          }),
        }),
      }),
    }),
  };
}

interface ReplyFirestoreState {
  post: DocumentData;
  comments: Map<string, DocumentData>;
  idempotency?: DocumentData;
  commentCreates: number;
  idempotencyCreates: number;
}

function replyFirestoreState(): ReplyFirestoreState {
  return {
    post: { ...committedPost(), audience: "Public" },
    comments: new Map<string, DocumentData>(),
    commentCreates: 0,
    idempotencyCreates: 0,
  };
}

function replyFirestore(state: ReplyFirestoreState): object {
  const reference = (
    collectionName: string,
    id: string,
    parentPostId?: string,
  ): Record<string, unknown> => {
    const ref: Record<string, unknown> = { collectionName, id, parentPostId };
    ref.get = async () => {
      if (collectionName === "socialPosts") return document(id, state.post);
      if (collectionName === "comments") return document(id, state.comments.get(id));
      if (collectionName === "socialReplyIdempotency") return document(id, state.idempotency);
      return document(id, undefined);
    };
    ref.collection = (name: string) => ({
      doc: (commentId: string) => reference(name, commentId, id),
    });
    return ref;
  };
  return {
    collection: (collectionName: string) => ({
      doc: (id: string) => reference(collectionName, id),
    }),
    runTransaction: async (callback: (transaction: object) => Promise<void>) => {
      await callback({
        get: async (target: Record<string, unknown>) => {
          const get = target.get as () => Promise<unknown>;
          return get();
        },
        create: (target: Record<string, unknown>, data: DocumentData) => {
          if (target.collectionName === "comments") {
            state.comments.set(String(target.id), data);
            state.commentCreates += 1;
          } else if (target.collectionName === "socialReplyIdempotency") {
            state.idempotency = data;
            state.idempotencyCreates += 1;
          }
        },
        update: (_target: Record<string, unknown>, data: DocumentData) => {
          state.post = { ...state.post, ...data };
        },
      });
    },
    getAll: async (...references: Array<Record<string, unknown>>) =>
      references.map((item) => item.collectionName === "socialPosts"
        ? document(String(item.id), state.post)
        : document(String(item.id), undefined)),
  };
}

interface AuthorFirestoreState {
  posts: Array<ReturnType<typeof document>>;
  followerCount: number;
  followed: boolean;
  relationshipWrites: number;
  metricsWrites: number;
}

function authorFirestoreState(): AuthorFirestoreState {
  return {
    posts: [
      document("public-new", {
        ...committedPost(),
        authorId: "author-1",
        authorName: "Public Author",
        authorHandle: "@publicauthor",
        body: "Newest public post",
        audience: "Public",
        publishedAt: "2026-08-13T12:00:00.000Z",
        sortKey: "2026-08-13T12:00:00.000Z_public-new",
      }),
      document("private-newer", {
        ...committedPost(),
        authorId: "author-1",
        authorName: "Public Author",
        authorHandle: "@publicauthor",
        body: "Private post",
        audience: "Private",
        publishedAt: "2026-08-13T13:00:00.000Z",
        sortKey: "2026-08-13T13:00:00.000Z_private-newer",
      }),
      document("public-old", {
        ...committedPost(),
        authorId: "author-1",
        authorName: "Public Author",
        authorHandle: "@publicauthor",
        body: "Older public post",
        audience: "Public",
        publishedAt: "2026-08-12T12:00:00.000Z",
        sortKey: "2026-08-12T12:00:00.000Z_public-old",
      }),
    ],
    followerCount: 4,
    followed: false,
    relationshipWrites: 0,
    metricsWrites: 0,
  };
}

function authorFirestore(state: AuthorFirestoreState): object {
  const reference = (collectionName: string, id: string) => ({
    collectionName,
    id,
    get: async () => collectionName === "socialAuthorMetrics"
      ? document(id, { followerCount: state.followerCount })
      : collectionName === "socialFollowRelationships"
        ? document(id, state.followed ? { followed: true } : undefined)
        : document(id, undefined),
  });
  return {
    collection: (collectionName: string) => ({
      doc: (id: string) => reference(collectionName, id),
      where: () => ({
        limit: () => ({ get: async () => ({ docs: state.posts }) }),
      }),
    }),
    runTransaction: async (callback: (transaction: object) => Promise<void>) => {
      await callback({
        get: async (target: { collectionName: string; id: string }) =>
          target.collectionName === "socialAuthorMetrics"
            ? document(target.id, { followerCount: state.followerCount })
            : document(target.id, state.followed ? { followed: true } : undefined),
        set: (
          target: { collectionName: string },
          data: DocumentData,
        ) => {
          if (target.collectionName === "socialFollowRelationships") {
            state.followed = data.followed === true;
            state.relationshipWrites += 1;
          } else if (target.collectionName === "socialAuthorMetrics") {
            state.followerCount = Number(data.followerCount);
            state.metricsWrites += 1;
          }
        },
      });
    },
  };
}

function commentData(id: string, sortKey: string): DocumentData {
  return document(id, {
    postId: "public-post-1",
    authorId: "reader-1",
    authorName: "Public Reader",
    authorHandle: "@reader",
    body: `Reply ${id}`,
    publishedAt: sortKey.slice(0, 24),
    sortKey,
  });
}

function hasUndefined(value: unknown): boolean {
  if (value === undefined) return true;
  if (Array.isArray(value)) return value.some(hasUndefined);
  if (value !== null && typeof value === "object") {
    return Object.values(value).some(hasUndefined);
  }
  return false;
}

function document(id: string, data: DocumentData | undefined) {
  return {
    id,
    exists: data !== undefined,
    data: () => data,
    get: (field: string) => data?.[field],
  };
}

function committedPost(): DocumentData {
  return {
    type: "post",
    authorId: "user-1",
    authorName: "Verified Person",
    authorHandle: "@verified",
    body: "Durable post",
    publishedAt: "2026-08-11T12:34:56.789Z",
    media: [],
    choices: [],
    likeCount: 0,
    replyCount: 0,
    repostCount: 0,
    shareCount: 0,
  };
}
