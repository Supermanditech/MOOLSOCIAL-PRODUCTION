import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

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
import { SocialContentService } from "./service.js";

const author: SocialAuthor = {
  userId: "user-1",
  name: "Verified Person",
  handle: "@verified",
};

class FakeRepository implements SocialContentRepository {
  publishes: Array<{ author: SocialAuthor; input: SocialPublishInput }> = [];
  interactions: Array<{ userId: string; input: SocialInteractionInput }> = [];
  feedCalls: Array<{ userId?: string; cursor?: string; limit: number }> = [];
  commentCalls: Array<{ postId: string; cursor?: string; limit: number }> = [];
  replies: Array<{ author: SocialAuthor; input: SocialReplyInput }> = [];
  authorCalls: Array<{ viewerUserId?: string; authorId: string; limit: number }> = [];
  followCalls: Array<{ viewer: SocialAuthor; authorId: string; followed: boolean }> = [];

  async publish(resolvedAuthor: SocialAuthor, input: SocialPublishInput): Promise<SocialPostRecord> {
    this.publishes.push({ author: resolvedAuthor, input });
    return post({
      id: "post-1",
      type: input.type,
      body: input.body,
      authorName: resolvedAuthor.name,
      authorHandle: resolvedAuthor.handle,
    });
  }

  async feed(userId: string | undefined, cursor: string | undefined, limit: number): Promise<SocialFeedPage> {
    this.feedCalls.push({ ...(userId ? { userId } : {}), ...(cursor ? { cursor } : {}), limit });
    return { items: [post()] };
  }

  async interact(userId: string, input: SocialInteractionInput): Promise<SocialPostRecord> {
    this.interactions.push({ userId, input });
    return post({ liked: input.type === "like" });
  }

  async comments(
    postId: string,
    cursor: string | undefined,
    limit: number,
  ): Promise<SocialCommentPage> {
    this.commentCalls.push({ postId, ...(cursor ? { cursor } : {}), limit });
    return { items: [comment({ postId })], nextCursor: "next-comment-page" };
  }

  async reply(author: SocialAuthor, input: SocialReplyInput): Promise<SocialReplyResult> {
    this.replies.push({ author, input });
    return {
      comment: comment({
        id: "comment-created",
        postId: input.postId,
        authorId: author.userId,
        authorName: author.name,
        authorHandle: author.handle,
        body: input.body,
      }),
      post: post({ id: input.postId, replyCount: 1 }),
    };
  }

  async author(
    viewerUserId: string | undefined,
    authorId: string,
    limit: number,
  ): Promise<SocialAuthorProfileRecord> {
    this.authorCalls.push({ ...(viewerUserId ? { viewerUserId } : {}), authorId, limit });
    return profile({
      authorId,
      followed: viewerUserId === "user-1",
      isSelf: viewerUserId === authorId,
    });
  }

  async follow(
    viewer: SocialAuthor,
    authorId: string,
    followed: boolean,
  ): Promise<SocialAuthorProfileRecord> {
    this.followCalls.push({ viewer, authorId, followed });
    return profile({ authorId, followed });
  }
}

test("publish uses the verified server author and a stable request digest", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);
  const request = {
    idempotencyKey: "publish-retry-key-0001",
    contentType: "post",
    body: "A durable public post",
    audience: "Public",
    mediaSlots: [],
    media: [],
    choices: [],
  };

  const first = await service.publish("user-1", request);
  await service.publish("user-1", request);

  assert.equal(first.authorName, "Verified Person");
  assert.equal(repository.publishes[0]?.author.userId, "user-1");
  assert.equal(
    repository.publishes[0]?.input.requestDigest,
    repository.publishes[1]?.input.requestDigest,
  );
});

test("publish verifies selected media bytes before repository acknowledgement", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);
  const bytes = Buffer.from([0xff, 0xd8, 0xff, 0x01, 0x02, 0x03]);
  const result = await service.publish("user-1", {
    idempotencyKey: "publish-retry-key-0002",
    contentType: "post",
    body: "Image post",
    audience: "Public",
    mediaSlots: ["media:0"],
    media: [{
      slot: "media:0",
      fileName: "image.jpg",
      contentType: "image/jpeg",
      byteLength: bytes.length,
      sha256: createHash("sha256").update(bytes).digest("hex"),
      bytesBase64: bytes.toString("base64"),
    }],
    choices: [],
  });

  assert.equal(result.id, "post-1");
  assert.deepEqual(repository.publishes[0]?.input.media[0]?.bytes, bytes);

  const wrongFormat = Buffer.from("not-a-jpeg");
  await assert.rejects(
    service.publish("user-1", {
      idempotencyKey: "publish-retry-key-0002-format",
      contentType: "post",
      body: "Image post",
      audience: "Public",
      mediaSlots: ["media:0"],
      media: [{
        slot: "media:0",
        fileName: "image.jpg",
        contentType: "image/jpeg",
        byteLength: wrongFormat.length,
        sha256: createHash("sha256").update(wrongFormat).digest("hex"),
        bytesBase64: wrongFormat.toString("base64"),
      }],
      choices: [],
    }),
    /selected image format/u,
  );
});

test("publish rejects MoolSocial-hosted reels and mismatched media", async () => {
  const service = new SocialContentService(new FakeRepository(), async () => author);
  await assert.rejects(
    service.publish("user-1", {
      idempotencyKey: "publish-retry-key-0003",
      contentType: "reel",
      body: "",
      audience: "Public",
      mediaSlots: [],
      media: [],
      choices: [],
    }),
    (error: unknown) => error instanceof SocialContentError && error.code === "bad_request",
  );
});

test("quoted publish requires thoughts and preserves the exact source id", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);

  await service.publish("user-1", {
    idempotencyKey: "quoted-publish-key-0001",
    contentType: "post",
    body: "My verified thoughts",
    audience: "Public",
    mediaSlots: [],
    media: [],
    choices: [],
    quotedPostId: "original-post-1",
  });
  assert.equal(repository.publishes[0]?.input.quotedPostId, "original-post-1");

  await assert.rejects(
    service.publish("user-1", {
      idempotencyKey: "quoted-publish-key-0002",
      contentType: "post",
      body: "",
      audience: "Public",
      mediaSlots: [],
      media: [],
      choices: [],
      quotedPostId: "original-post-1",
    }),
    /Add your thoughts/u,
  );
});

test("interactions persist like, save, repost and one valid vote contract", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);
  await service.interact("user-1", {
    postId: "post-1",
    interaction: "vote",
    choiceIndex: 1,
  });
  assert.deepEqual(repository.interactions[0], {
    userId: "user-1",
    input: { postId: "post-1", type: "vote", choiceIndex: 1 },
  });
  await service.interact("user-1", {
    postId: "post-1",
    interaction: "repost",
  });
  assert.deepEqual(repository.interactions[1], {
    userId: "user-1",
    input: { postId: "post-1", type: "repost" },
  });
  await assert.rejects(
    service.interact("user-1", { postId: "post-1", interaction: "share" }),
    /not available yet/u,
  );
});

test("feed bounds the page size before reading durable state", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);
  await service.feed("user-1", { cursor: "cursor-1", limit: 30 });
  assert.deepEqual(repository.feedCalls[0], {
    userId: "user-1",
    cursor: "cursor-1",
    limit: 30,
  });
  await assert.rejects(service.feed("user-1", { limit: 31 }), /between 1 and 30/u);
});

test("comments are a public bounded read with stable pagination", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => {
    throw new Error("public comments must not resolve an authenticated author");
  });

  const page = await service.comments({
    postId: "post-1",
    cursor: "comment-cursor-1",
    limit: 30,
  });

  assert.equal(page.items[0]?.body, "Public reply");
  assert.equal(page.nextCursor, "next-comment-page");
  assert.deepEqual(repository.commentCalls[0], {
    postId: "post-1",
    cursor: "comment-cursor-1",
    limit: 30,
  });
  await assert.rejects(service.comments({ postId: "post-1", limit: 31 }), /between 1 and 30/u);
});

test("reply uses the verified author, bounded body and stable retry digest", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);
  const request = {
    postId: "post-1",
    idempotencyKey: "reply-retry-key-0001",
    body: "A verified public reply",
  };

  const first = await service.reply("user-1", request);
  await service.reply("user-1", request);

  assert.equal(first.comment.authorName, "Verified Person");
  assert.equal(first.post.replyCount, 1);
  assert.equal(repository.replies[0]?.author.userId, "user-1");
  assert.equal(repository.replies[0]?.input.requestDigest, repository.replies[1]?.input.requestDigest);
  await assert.rejects(
    service.reply("user-1", { ...request, body: "x".repeat(501) }),
    /500 characters/u,
  );
  await assert.rejects(
    service.reply("user-1", { ...request, idempotencyKey: "short" }),
    /valid reply retry key/u,
  );
});

test("author is a bounded public read and does not resolve private identity", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => {
    throw new Error("public author reads must not resolve an identity");
  });

  const result = await service.author(undefined, { authorId: "author-1", limit: 20 });

  assert.equal(result.authorId, "author-1");
  assert.equal(result.followed, false);
  assert.deepEqual(repository.authorCalls[0], { authorId: "author-1", limit: 20 });
  await assert.rejects(
    service.author(undefined, { authorId: "author-1", limit: 21 }),
    /between 1 and 20/u,
  );
});

test("follow uses the verified viewer and rejects self-follow before repository work", async () => {
  const repository = new FakeRepository();
  const service = new SocialContentService(repository, async () => author);

  const followed = await service.follow("user-1", {
    authorId: "author-2",
    followed: true,
  });

  assert.equal(followed.followed, true);
  assert.equal(repository.followCalls[0]?.viewer.userId, "user-1");
  assert.deepEqual(repository.followCalls[0], {
    viewer: author,
    authorId: "author-2",
    followed: true,
  });
  await assert.rejects(
    service.follow("user-1", { authorId: "user-1", followed: true }),
    /cannot follow your own/u,
  );
  await assert.rejects(
    service.follow("user-1", { authorId: "author-2", followed: "yes" }),
    /Follow or Unfollow/u,
  );
  assert.equal(repository.followCalls.length, 1);
});

function post(overrides: Partial<SocialPostRecord> = {}): SocialPostRecord {
  return {
    id: "post-1",
    type: "post",
    authorId: "user-1",
    authorName: "Verified Person",
    authorHandle: "@verified",
    body: "Body",
    audience: "Public",
    publishedAt: "2026-08-11T12:00:00.000Z",
    mediaUrls: [],
    choices: [],
    liked: false,
    saved: false,
    likeCount: 0,
    replyCount: 0,
    repostCount: 0,
    shareCount: 0,
    ...overrides,
  };
}

function comment(overrides: Partial<SocialCommentRecord> = {}): SocialCommentRecord {
  return {
    id: "comment-1",
    postId: "post-1",
    authorId: "commenter-1",
    authorName: "Public Reader",
    authorHandle: "@reader",
    body: "Public reply",
    publishedAt: "2026-08-13T12:00:00.000Z",
    ...overrides,
  };
}

function profile(
  overrides: Partial<SocialAuthorProfileRecord> = {},
): SocialAuthorProfileRecord {
  return {
    authorId: "author-1",
    authorName: "Public Author",
    authorHandle: "@publicauthor",
    followerCount: 4,
    followed: false,
    isSelf: false,
    posts: [post({ authorId: "author-1" })],
    ...overrides,
  };
}
