import { createHash } from "node:crypto";

export type MetaErasureProvider = "facebook" | "instagram";
export type MetaErasureState = "pending" | "completed" | "failed";

export interface MetaErasureRecord {
  readonly confirmationCode: string;
  readonly requestDigest: string;
  readonly provider: MetaErasureProvider;
  readonly firebaseUserIds: readonly string[];
  readonly state: MetaErasureState;
  readonly requestedAt: string;
  readonly dueAt: string;
  readonly attemptCount: number;
  readonly completedAt?: string;
  readonly failedAt?: string;
  readonly failureStage?: string;
}

export interface MetaErasurePublicStatus {
  readonly state: MetaErasureState;
  readonly requestedAt: string;
  readonly dueAt: string;
  readonly completedAt?: string;
}

export interface MetaAccountErasureStore {
  read(confirmationCode: string): Promise<MetaErasureRecord | undefined>;
  createPending(record: MetaErasureRecord): Promise<boolean>;
  markPending(confirmationCode: string, attemptCount: number): Promise<void>;
  markCompleted(confirmationCode: string, completedAt: string): Promise<void>;
  markFailed(
    confirmationCode: string,
    failedAt: string,
    failureStage: string,
  ): Promise<void>;
}

export interface MetaAccountErasureWorker {
  eraseUser(firebaseUserId: string): Promise<void>;
}

export class MetaAccountErasureError extends Error {
  readonly httpStatus: number;

  constructor(
    readonly code: "invalid_request" | "conflict" | "erasure_failed",
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = "MetaAccountErasureError";
    this.httpStatus = code === "invalid_request"
      ? 400
      : code === "conflict"
      ? 409
      : 503;
  }
}

export interface MetaAccountErasureCoordinatorOptions {
  readonly store: MetaAccountErasureStore;
  readonly worker: MetaAccountErasureWorker;
  readonly now?: () => Date;
  readonly completionTargetDays?: number;
}

export interface MetaAccountErasureRequest {
  readonly provider: MetaErasureProvider;
  readonly confirmationCode: string;
  readonly firebaseUserIds: readonly string[];
}

function validCode(value: string): boolean {
  return /^[A-Za-z0-9_-]{16,64}$/u.test(value);
}

function validUserId(value: string): boolean {
  return /^[A-Za-z0-9:_-]{1,128}$/u.test(value);
}

function requestDigest(
  provider: MetaErasureProvider,
  firebaseUserIds: readonly string[],
): string {
  return createHash("sha256")
    .update(provider, "utf8")
    .update("\0", "utf8")
    .update(firebaseUserIds.join("\0"), "utf8")
    .digest("base64url");
}

function publicStatus(record: MetaErasureRecord): MetaErasurePublicStatus {
  return {
    state: record.state,
    requestedAt: record.requestedAt,
    dueAt: record.dueAt,
    ...(record.completedAt === undefined
      ? {}
      : { completedAt: record.completedAt }),
  };
}

export class MetaAccountErasureCoordinator {
  private readonly now: () => Date;
  private readonly completionTargetDays: number;

  constructor(private readonly options: MetaAccountErasureCoordinatorOptions) {
    this.now = options.now ?? (() => new Date());
    this.completionTargetDays = options.completionTargetDays ?? 30;
    if (
      !Number.isInteger(this.completionTargetDays) ||
      this.completionTargetDays < 1 ||
      this.completionTargetDays > 30
    ) {
      throw new Error("Meta erasure completion target is invalid.");
    }
  }

  async request(
    input: MetaAccountErasureRequest,
  ): Promise<MetaErasurePublicStatus> {
    const confirmationCode = input.confirmationCode.trim();
    const userIds = [...new Set(input.firebaseUserIds.map((item) => item.trim()))]
      .sort();
    if (
      !validCode(confirmationCode) ||
      userIds.length > 100 ||
      userIds.some((item) => !validUserId(item))
    ) {
      throw new MetaAccountErasureError(
        "invalid_request",
        "The account deletion request is invalid.",
        false,
      );
    }

    const digest = requestDigest(input.provider, userIds);
    const now = this.now();
    const requestedAt = now.toISOString();
    const dueAt = new Date(
      now.getTime() + this.completionTargetDays * 24 * 60 * 60 * 1000,
    ).toISOString();
    const pending: MetaErasureRecord = {
      confirmationCode,
      requestDigest: digest,
      provider: input.provider,
      firebaseUserIds: userIds,
      state: "pending",
      requestedAt,
      dueAt,
      attemptCount: 1,
    };
    const created = await this.options.store.createPending(pending);
    const existing = created
      ? pending
      : await this.options.store.read(confirmationCode);
    if (!existing || existing.requestDigest !== digest) {
      throw new MetaAccountErasureError(
        "conflict",
        "That deletion confirmation belongs to another request.",
        false,
      );
    }
    if (existing.state === "completed") return publicStatus(existing);

    const attemptCount = created ? 1 : existing.attemptCount + 1;
    if (!created) {
      await this.options.store.markPending(confirmationCode, attemptCount);
    }
    try {
      for (const userId of existing.firebaseUserIds) {
        await this.options.worker.eraseUser(userId);
      }
      const completedAt = this.now().toISOString();
      await this.options.store.markCompleted(confirmationCode, completedAt);
      return {
        state: "completed",
        requestedAt: existing.requestedAt,
        dueAt: existing.dueAt,
        completedAt,
      };
    } catch {
      await this.options.store.markFailed(
        confirmationCode,
        this.now().toISOString(),
        "product_data_erasure",
      );
      throw new MetaAccountErasureError(
        "erasure_failed",
        "The account deletion request is still pending completion.",
        true,
      );
    }
  }

  async status(confirmationCode: string): Promise<MetaErasurePublicStatus> {
    const normalized = confirmationCode.trim();
    if (!validCode(normalized)) {
      throw new MetaAccountErasureError(
        "invalid_request",
        "The deletion confirmation code is invalid.",
        false,
      );
    }
    const record = await this.options.store.read(normalized);
    if (!record) {
      throw new MetaAccountErasureError(
        "invalid_request",
        "The deletion confirmation code was not found.",
        false,
      );
    }
    return publicStatus(record);
  }
}
