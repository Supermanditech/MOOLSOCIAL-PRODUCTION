import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

import { FirebaseMetaAccountErasureWorker } from "./meta_account_erasure_firebase.js";

const projectId = "moolsocial-fix7-local";
const userId = "firebase_user_1";
let environment: RulesTestEnvironment;
let adminApp: App;
let firestore: Firestore;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { host: "127.0.0.1", port: 8080 },
  });
  adminApp = initializeApp({ projectId }, "fix7-emulator");
  firestore = getFirestore(adminApp);
});

beforeEach(async () => environment.clearFirestore());

after(async () => {
  await deleteApp(adminApp);
  await environment.cleanup();
});

test("erases owned data and preserves shared chat text as Deleted account", async () => {
  const authoredPost = firestore.collection("socialPosts").doc("post_owned");
  const sharedPost = firestore.collection("socialPosts").doc("post_shared");
  await authoredPost.set({ authorId: userId, body: "delete me" });
  await authoredPost.collection("comments").doc("reply_other").set({
    authorId: "other_user",
    text: "reply",
  });
  await sharedPost.set({
    authorId: "other_user",
    body: "keep me",
    replyCount: 1,
    quotedPost: { id: authoredPost.id, body: "delete me" },
  });
  await sharedPost.collection("comments").doc("reply_owned").set({
    authorId: userId,
    text: "remove reply",
  });
  await firestore.collection("socialPostInteractions").doc("interaction").set({
    postId: authoredPost.id,
    userId: "other_user",
  });
  await firestore.collection("socialPublishIdempotency").doc("publish").set({
    userId,
  });
  await firestore.collection("socialReplyIdempotency").doc("reply").set({
    userId,
  });
  await firestore.collection("socialFollowRelationships").doc("following").set({
    viewerUserId: userId,
    authorId: "other_user",
  });
  await firestore.collection("socialAuthorMetrics").doc("other_user").set({
    followerCount: 3,
  });
  await firestore.collection("socialAuthorMetrics").doc(userId).set({
    followerCount: 1,
  });

  const thread = firestore.collection("chatThreads").doc("thread_1");
  await thread.set({
    participantIds: [userId, "other_user"],
    participantProfiles: {
      [userId]: { userId, name: "Private name", handle: "@private" },
      other_user: { userId: "other_user", name: "Other", handle: "@other" },
    },
    unreadCounts: { [userId]: 0, other_user: 1 },
    lastReadAtBy: { [userId]: "2026-08-21T00:00:00.000Z" },
  });
  await thread.collection("messages").doc("message_owned").set({
    senderId: userId,
    senderName: "Private name",
    text: "Retained shared text",
    reactions: { [userId]: true, other_user: true },
    messageType: "photo",
    photo: {
      objectPath: "chat-private/v1/upload-1",
      generation: "1",
    },
  });
  await thread.collection("messages").doc("message_other").set({
    senderId: "other_user",
    senderName: "Other",
    text: "Other text",
    reactions: { [userId]: true },
    replyTo: {
      messageId: "message_owned",
      senderName: "Private name",
      text: "Retained shared text",
    },
  });
  await thread.collection("attachmentReceipts").doc("upload-1").set({
    senderId: userId,
  });

  await firestore.collection("youtubeProviderConnections").doc("connection").set({
    connectionKey: "connection",
    userId,
  });
  await firestore.collection("youtubeProviderCredentials").doc("connection").set({
    encryptedRefreshToken: "ciphertext",
  });
  await firestore.collection("youtubeProviderOAuthAttempts").doc("attempt").set({
    userId,
  });
  await firestore.collection("youtubeProviderPublicationJobs").doc("job").set({
    userId,
  });
  await firestore.collection("youtubeProviderAuditEvents").doc("audit").set({
    userId,
    eventType: "connected",
  });
  for (const collection of ["users", "profiles", "workspaces"]) {
    await firestore.collection(collection).doc(userId).set({ userId });
  }

  const deletedObjects: string[] = [];
  const dataConnectUsers: string[] = [];
  const revokedUsers: string[] = [];
  const deletedAuthUsers: string[] = [];
  const worker = new FirebaseMetaAccountErasureWorker(
    firestore,
    {
      async deleteFiles(options): Promise<void> {
        deletedObjects.push(options.prefix);
      },
      file(path) {
        return {
          async delete(): Promise<void> {
            deletedObjects.push(path);
          },
        };
      },
    },
    {
      async deleteUser(id): Promise<void> {
        deletedAuthUsers.push(id);
      },
    },
    {
      async executeMutation(name, variables): Promise<void> {
        assert.equal(name, "EraseMoolSocialUser");
        dataConnectUsers.push(String(variables.userId));
      },
    },
    {
      async revokeAndDelete(id): Promise<void> {
        revokedUsers.push(id);
      },
    },
  );

  await worker.eraseUser(userId);

  assert.equal((await authoredPost.get()).exists, false);
  assert.equal((await sharedPost.collection("comments").doc("reply_owned").get()).exists, false);
  assert.equal((await sharedPost.get()).get("replyCount"), 0);
  assert.equal((await sharedPost.get()).get("quotedPost"), undefined);
  assert.equal((await firestore.collection("socialPostInteractions").doc("interaction").get()).exists, false);
  assert.equal((await firestore.collection("socialAuthorMetrics").doc("other_user").get()).get("followerCount"), 2);
  assert.equal((await firestore.collection("socialAuthorMetrics").doc(userId).get()).exists, false);

  const savedThread = await thread.get();
  const replacementId = String(savedThread.get("participantIds")[0]);
  assert.match(replacementId, /^deleted_[0-9a-f]{24}$/u);
  assert.equal(savedThread.get(`participantProfiles.${replacementId}`).name, "Deleted account");
  const savedOwnedMessage = await thread.collection("messages").doc("message_owned").get();
  assert.equal(savedOwnedMessage.get("text"), "Retained shared text");
  assert.equal(savedOwnedMessage.get("senderName"), "Deleted account");
  assert.equal(savedOwnedMessage.get("photo"), undefined);
  assert.deepEqual(savedOwnedMessage.get("reactions"), { other_user: true });
  const savedOtherMessage = await thread.collection("messages").doc("message_other").get();
  assert.equal(savedOtherMessage.get("replyTo.senderName"), "Deleted account");
  assert.deepEqual(savedOtherMessage.get("reactions"), {});
  assert.equal((await thread.collection("attachmentReceipts").doc("upload-1").get()).exists, false);

  assert.deepEqual(revokedUsers, [userId]);
  assert.deepEqual(dataConnectUsers, [userId]);
  assert.deepEqual(deletedAuthUsers, [userId]);
  assert.deepEqual(deletedObjects.sort(), [
    "chat-private/v1/upload-1",
    `social-media/${userId}/`,
  ]);
  assert.equal((await firestore.collection("youtubeProviderConnections").doc("connection").get()).exists, false);
  assert.equal((await firestore.collection("youtubeProviderCredentials").doc("connection").get()).exists, false);
  assert.equal((await firestore.collection("youtubeProviderAuditEvents").doc("audit").get()).get("identityErased"), true);
  assert.equal((await firestore.collection("youtubeProviderAuditEvents").doc("audit").get()).get("userId"), undefined);

  await worker.eraseUser(userId);
});
