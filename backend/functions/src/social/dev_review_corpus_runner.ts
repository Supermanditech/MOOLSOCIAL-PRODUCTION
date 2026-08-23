import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth, type UserRecord } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { FirestoreSocialContentRepository } from "./firestore_store.js";
import { SocialContentService } from "./service.js";
import {
  buildDevReviewCorpus,
  buildDevReviewPublishRequest,
  DEV_REVIEW_PERSONAS,
  DEV_REVIEW_PROJECT_ID,
  summarizeDevReviewCorpus,
  type DevReviewPersona,
} from "./dev_review_corpus.js";

class ReviewCorpusRunnerError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = "ReviewCorpusRunnerError";
  }
}

interface RunnerArguments {
  readonly apply: boolean;
  readonly projectId: string;
}

async function main(): Promise<void> {
  const arguments_ = parseArguments(process.argv.slice(2));
  const corpus = buildDevReviewCorpus();
  const summary = summarizeDevReviewCorpus(corpus);
  if (!arguments_.apply) {
    process.stdout.write(`${JSON.stringify({
      ok: true,
      mode: "dry-run",
      projectId: arguments_.projectId,
      ...summary,
      writesPerformed: false,
    })}\n`);
    return;
  }
  if (arguments_.projectId !== DEV_REVIEW_PROJECT_ID) {
    throw new ReviewCorpusRunnerError(
      "project_not_allowed",
      "The review corpus can be applied only to the exact MoolSocial Dev project.",
    );
  }
  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId: arguments_.projectId,
      storageBucket: `${arguments_.projectId}.firebasestorage.app`,
    });
  }

  const auth = getAuth();
  const firestore = getFirestore();
  const bucket = getStorage().bucket();
  try {
    await Promise.all([
      firestore.collection("socialPublishIdempotency").doc("c30k-read-probe").get(),
      bucket.getFiles({ prefix: "c30k-read-probe", maxResults: 1 }),
    ]);
  } catch (error) {
    throw stageError("service_read_preflight", error);
  }
  let createdPersonas = 0;
  for (const persona of DEV_REVIEW_PERSONAS) {
    let state: "created" | "verified";
    try {
      state = await ensurePersona(auth, persona);
    } catch (error) {
      throw stageError("persona_reconciliation", error);
    }
    if (state === "created") createdPersonas += 1;
  }

  const service = new SocialContentService(
    new FirestoreSocialContentRepository(
      firestore,
      bucket,
    ),
    async (userId) => authorFromUser(await auth.getUser(userId)),
  );
  const persistedIds = new Set<string>();
  const persistedByType = {
    post: 0,
    carousel: 0,
    imagePoll: 0,
    quickPoll: 0,
    quiz: 0,
  };
  for (const post of corpus) {
    let record;
    try {
      record = await service.publish(
        post.persona.uid,
        buildDevReviewPublishRequest(post),
      );
    } catch (error) {
      throw stageError(`publish_${post.type}`, error);
    }
    if (record.authorId !== post.persona.uid || record.type !== post.type) {
      throw new ReviewCorpusRunnerError(
        "persisted_record_mismatch",
        "A persisted review post did not match its authoritative author and format.",
      );
    }
    if ((post.type === "imagePoll" ||
        post.type === "quickPoll" ||
        post.type === "quiz") && record.choices.length !== 4) {
      throw new ReviewCorpusRunnerError(
        "persisted_choice_mismatch",
        "A persisted review poll did not retain all four choices.",
      );
    }
    persistedIds.add(record.id);
    persistedByType[record.type] += 1;
  }
  if (persistedIds.size !== corpus.length) {
    throw new ReviewCorpusRunnerError(
      "persisted_count_mismatch",
      "The persisted review corpus did not return 36 unique post records.",
    );
  }
  process.stdout.write(`${JSON.stringify({
    ok: true,
    mode: "applied",
    projectId: arguments_.projectId,
    personas: {
      expected: DEV_REVIEW_PERSONAS.length,
      created: createdPersonas,
      verifiedExisting: DEV_REVIEW_PERSONAS.length - createdPersonas,
    },
    posts: {
      expected: corpus.length,
      persistedUnique: persistedIds.size,
      byType: persistedByType,
    },
    mediaObjects: summary.mediaObjects,
    credentialsOutput: false,
  })}\n`);
}

function parseArguments(arguments_: readonly string[]): RunnerArguments {
  const apply = arguments_.includes("--apply");
  const projectArgument = arguments_.find((value) => value.startsWith("--project="));
  const projectId = projectArgument?.slice("--project=".length).trim() || DEV_REVIEW_PROJECT_ID;
  const supported = new Set(["--apply", `--project=${projectId}`]);
  const unknown = arguments_.filter((value) => !supported.has(value));
  if (unknown.length > 0) {
    throw new ReviewCorpusRunnerError(
      "unsupported_argument",
      "Use only --apply and --project=<exact-dev-project>.",
    );
  }
  return { apply, projectId };
}

async function ensurePersona(
  auth: ReturnType<typeof getAuth>,
  persona: DevReviewPersona,
): Promise<"created" | "verified"> {
  let existing: UserRecord;
  try {
    existing = await auth.getUser(persona.uid);
  } catch (error) {
    if (firebaseErrorCode(error) !== "auth/user-not-found") throw error;
    await auth.createUser({
      uid: persona.uid,
      email: persona.email,
      emailVerified: true,
      displayName: persona.displayName,
      disabled: true,
    });
    return "created";
  }
  if (existing.email !== persona.email ||
      existing.displayName !== persona.displayName ||
      existing.emailVerified !== true ||
      existing.disabled !== true ||
      existing.providerData.length !== 0 ||
      existing.phoneNumber !== undefined) {
    throw new ReviewCorpusRunnerError(
      "existing_persona_conflict",
      "An existing deterministic review identity does not match the sealed disabled passwordless profile. Nothing was changed.",
    );
  }
  return "verified";
}

function authorFromUser(user: UserRecord): {
  readonly userId: string;
  readonly name: string;
  readonly handle: string;
} {
  const emailPrefix = user.email?.split("@")[0]?.replace(/[^A-Za-z0-9._-]/gu, "") ?? "";
  return {
    userId: user.uid,
    name: user.displayName?.trim() || "MoolSocial member",
    handle: emailPrefix ? `@${emailPrefix}` : `@${user.uid.slice(0, 12)}`,
  };
}

function firebaseErrorCode(error: unknown): string | undefined {
  if (error === null || typeof error !== "object" || !("code" in error)) return undefined;
  if (typeof error.code === "string") return error.code;
  return typeof error.code === "number" ? `grpc_${error.code}` : undefined;
}

function stageError(stage: string, error: unknown): ReviewCorpusRunnerError {
  if (error instanceof ReviewCorpusRunnerError) return error;
  return new ReviewCorpusRunnerError(
    `${stage}_${firebaseErrorCode(error) ?? "failed"}`,
    `The Dev review corpus stopped during ${stage.replaceAll("_", " ")}. No retry was attempted.`,
  );
}

void main().catch((error: unknown) => {
  const known = error instanceof ReviewCorpusRunnerError;
  process.stderr.write(`${JSON.stringify({
    ok: false,
    code: known ? error.code : firebaseErrorCode(error) ?? "runner_failed",
    message: known
      ? error.message
      : "The Dev review corpus could not be applied with the current secure operator identity.",
    credentialsOutput: false,
  })}\n`);
  process.exitCode = 1;
});
