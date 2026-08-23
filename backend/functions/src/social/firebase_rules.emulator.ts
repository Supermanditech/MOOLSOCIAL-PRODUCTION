import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { after, before, test } from "node:test";

import {
  assertFails,
  type RulesTestContext,
  type RulesTestEnvironment,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { getBytes, ref, uploadBytes } from "firebase/storage";

const projectId = "moolsocial-c29p-local";
let environment: RulesTestEnvironment;
let signedIn: RulesTestContext;
let signedOut: RulesTestContext;

before(async () => {
  const repositoryRoot = resolve(__dirname, "../../../..");
  const [firestoreRules, storageRules] = await Promise.all([
    readFile(resolve(repositoryRoot, "backend/firestore/youtube-private-dev.rules"), "utf8"),
    readFile(resolve(repositoryRoot, "backend/storage/moolsocial-private-dev.rules"), "utf8"),
  ]);
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules: firestoreRules, host: "127.0.0.1", port: 8080 },
    storage: { rules: storageRules, host: "127.0.0.1", port: 9199 },
  });
  signedIn = environment.authenticatedContext("user-1");
  signedOut = environment.unauthenticatedContext();
});

after(async () => environment.cleanup());

test("direct signed-in and signed-out Firestore clients cannot access Social content", async () => {
  for (const context of [signedIn, signedOut]) {
    const post = doc(context.firestore(), "socialPosts/post-1");
    await assertFails(getDoc(post));
    await assertFails(setDoc(post, { body: "bypass" }));
  }
});

test("direct signed-in and signed-out Storage clients cannot access Social media", async () => {
  for (const context of [signedIn, signedOut]) {
    const media = ref(
      context.storage(),
      "social-media/user-1/post-1/media-0.jpg",
    );
    await assertFails(getBytes(media));
    await assertFails(uploadBytes(media, Uint8Array.from([0xff, 0xd8, 0xff])));
  }
});
