import { createHash } from "node:crypto";

import {
  SOCIAL_CONTENT_TYPES,
  SocialContentError,
  type SocialChoiceInput,
  type SocialAuthorProfileRecord,
  type SocialCommentPage,
  type SocialContentRepository,
  type SocialContentType,
  type SocialFeedPage,
  type SocialInteractionInput,
  type SocialInteractionType,
  type SocialMediaInput,
  type SocialPostRecord,
  type SocialPublishInput,
  type SocialReplyInput,
  type SocialReplyResult,
  type SocialAuthorResolver,
  type VerifiedSocialMedia,
} from "./contracts.js";

const maximumBodyCharacters = 4_000;
const maximumReplyCharacters = 500;
const maximumMediaItems = 10;
const maximumMediaBytes = 8 * 1024 * 1024;
const maximumTotalMediaBytes = 20 * 1024 * 1024;
const supportedImageTypes = new Set(["image/jpeg", "image/png", "image/webp"]);

export class SocialContentService {
  constructor(
    private readonly repository: SocialContentRepository,
    private readonly resolveAuthor: SocialAuthorResolver,
  ) {}

  async publish(userId: string, raw: unknown): Promise<SocialPostRecord> {
    const body = object(raw);
    const input = parsePublishInput(body);
    const author = await this.resolveAuthor(userId);
    if (author.userId !== userId) {
      throw new SocialContentError(
        "permission_denied",
        "The signed-in profile could not be verified.",
        403,
      );
    }
    return this.repository.publish(author, input);
  }

  async feed(userId: string | undefined, raw: unknown): Promise<SocialFeedPage> {
    const body = object(raw);
    const cursor = optionalText(body, "cursor", 256);
    const limitValue = body.limit ?? 20;
    if (!Number.isSafeInteger(limitValue) || (limitValue as number) < 1 || (limitValue as number) > 30) {
      throw badRequest("Feed limit must be between 1 and 30.");
    }
    return this.repository.feed(userId, cursor, limitValue as number);
  }

  async interact(userId: string, raw: unknown): Promise<SocialPostRecord> {
    const body = object(raw);
    const postId = requiredText(body, "postId", 128);
    const type = requiredText(body, "interaction", 32) as SocialInteractionType;
    if (type !== "like" && type !== "save" && type !== "vote" && type !== "repost") {
      throw badRequest("That Feed action is not available yet.");
    }
    const choiceIndex = body.choiceIndex;
    if (type === "vote") {
      if (!Number.isSafeInteger(choiceIndex) || (choiceIndex as number) < 0 || (choiceIndex as number) > 3) {
        throw badRequest("Choose a valid poll option.");
      }
    } else if (choiceIndex !== undefined) {
      throw badRequest("A poll choice is valid only for voting.");
    }
    const input: SocialInteractionInput = {
      postId,
      type,
      ...(choiceIndex === undefined ? {} : { choiceIndex: choiceIndex as number }),
    };
    return this.repository.interact(userId, input);
  }

  async comments(raw: unknown): Promise<SocialCommentPage> {
    const body = object(raw);
    const postId = requiredText(body, "postId", 128);
    const cursor = optionalText(body, "cursor", 256);
    const limitValue = body.limit ?? 30;
    if (!Number.isSafeInteger(limitValue) || (limitValue as number) < 1 || (limitValue as number) > 30) {
      throw badRequest("Reply limit must be between 1 and 30.");
    }
    return this.repository.comments(postId, cursor, limitValue as number);
  }

  async reply(userId: string, raw: unknown): Promise<SocialReplyResult> {
    const body = object(raw);
    const postId = requiredText(body, "postId", 128);
    const idempotencyKey = requiredText(body, "idempotencyKey", 128);
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]{15,127}$/.test(idempotencyKey)) {
      throw badRequest("A valid reply retry key is required.");
    }
    const replyBody = typeof body.body === "string" ? body.body.trim() : "";
    if (replyBody.length < 1 || replyBody.length > maximumReplyCharacters) {
      throw badRequest("Reply must be between 1 and 500 characters.");
    }
    const input: SocialReplyInput = {
      postId,
      idempotencyKey,
      body: replyBody,
      requestDigest: createHash("sha256")
        .update(JSON.stringify({ postId, body: replyBody }))
        .digest("hex"),
    };
    const author = await this.resolveAuthor(userId);
    if (author.userId !== userId) {
      throw new SocialContentError(
        "permission_denied",
        "The signed-in profile could not be verified.",
        403,
      );
    }
    return this.repository.reply(author, input);
  }

  async author(
    viewerUserId: string | undefined,
    raw: unknown,
  ): Promise<SocialAuthorProfileRecord> {
    const body = object(raw);
    const authorId = requiredText(body, "authorId", 128);
    const limitValue = body.limit ?? 12;
    if (!Number.isSafeInteger(limitValue) || (limitValue as number) < 1 || (limitValue as number) > 20) {
      throw badRequest("Author post limit must be between 1 and 20.");
    }
    return this.repository.author(viewerUserId, authorId, limitValue as number);
  }

  async follow(
    viewerUserId: string,
    raw: unknown,
  ): Promise<SocialAuthorProfileRecord> {
    const body = object(raw);
    const authorId = requiredText(body, "authorId", 128);
    if (authorId === viewerUserId) {
      throw new SocialContentError(
        "conflict",
        "You cannot follow your own MoolSocial profile.",
        409,
      );
    }
    if (typeof body.followed !== "boolean") {
      throw badRequest("Choose Follow or Unfollow.");
    }
    const viewer = await this.resolveAuthor(viewerUserId);
    if (viewer.userId !== viewerUserId) {
      throw new SocialContentError(
        "permission_denied",
        "The signed-in profile could not be verified.",
        403,
      );
    }
    return this.repository.follow(viewer, authorId, body.followed);
  }
}

function parsePublishInput(body: Record<string, unknown>): SocialPublishInput {
  const idempotencyKey = requiredText(body, "idempotencyKey", 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{15,127}$/.test(idempotencyKey)) {
    throw badRequest("A valid publish retry key is required.");
  }
  const type = requiredText(body, "contentType", 32) as SocialContentType;
  if (!SOCIAL_CONTENT_TYPES.includes(type)) {
    throw badRequest("Choose a supported MoolSocial post format.");
  }
  const textBody = optionalText(body, "body", maximumBodyCharacters) ?? "";
  const audience = requiredText(body, "audience", 16);
  if (audience !== "Public") {
    throw badRequest("Only the Public audience is available for this Feed.");
  }
  const media = parseMedia(body.media);
  const mediaBySlot = new Map(media.map((item) => [item.slot, item]));
  const mediaSlots = textArray(body.mediaSlots, "mediaSlots", maximumMediaItems);
  const choices = parseChoices(body.choices);
  const referencedSlots = new Set(mediaSlots);
  for (const choice of choices) {
    if (choice.mediaSlot) referencedSlots.add(choice.mediaSlot);
  }
  for (const slot of referencedSlots) {
    if (!mediaBySlot.has(slot)) throw badRequest("One selected image is missing.");
  }
  if (referencedSlots.size !== media.length) {
    throw badRequest("Unreferenced media cannot be published.");
  }

  const correctChoiceIndex = optionalInteger(body, "correctChoiceIndex");
  const quotedPostId = optionalText(body, "quotedPostId", 128);
  if (quotedPostId !== undefined && textBody.length === 0) {
    throw badRequest("Add your thoughts before sharing this post.");
  }
  validateFormat(type, textBody, mediaSlots, choices, correctChoiceIndex);
  const digestPayload = JSON.stringify({
    type,
    body: textBody,
    audience,
    mediaSlots,
    media: media.map(({ slot, sha256, byteLength, contentType }) => ({
      slot,
      sha256,
      byteLength,
      contentType,
    })),
    choices,
    ...(correctChoiceIndex === undefined ? {} : { correctChoiceIndex }),
    ...(quotedPostId === undefined ? {} : { quotedPostId }),
  });
  return {
    idempotencyKey,
    type,
    body: textBody,
    audience,
    mediaSlots,
    media,
    choices,
    ...(correctChoiceIndex === undefined ? {} : { correctChoiceIndex }),
    ...(quotedPostId === undefined ? {} : { quotedPostId }),
    requestDigest: createHash("sha256").update(digestPayload).digest("hex"),
  };
}

function parseMedia(raw: unknown): VerifiedSocialMedia[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw) || raw.length > maximumMediaItems) {
    throw badRequest("Choose no more than 10 images.");
  }
  const slots = new Set<string>();
  let total = 0;
  return raw.map((entry) => {
    const item = object(entry) as Record<string, unknown> & SocialMediaInput;
    const slot = requiredText(item, "slot", 48);
    if (!/^[a-z]+:[0-9]$/.test(slot) || !slots.add(slot)) {
      throw badRequest("Each selected image needs one stable slot.");
    }
    const fileName = requiredText(item, "fileName", 128);
    const contentType = requiredText(item, "contentType", 64).toLowerCase();
    if (!supportedImageTypes.has(contentType)) {
      throw badRequest("Use a JPEG, PNG or WebP image.");
    }
    const byteLength = item.byteLength;
    if (!Number.isSafeInteger(byteLength) || byteLength < 1 || byteLength > maximumMediaBytes) {
      throw new SocialContentError(
        "payload_too_large",
        "Each image must be 8 MB or smaller.",
        413,
      );
    }
    total += byteLength;
    if (total > maximumTotalMediaBytes) {
      throw new SocialContentError(
        "payload_too_large",
        "The selected images must be 20 MB or smaller in total.",
        413,
      );
    }
    const sha256 = requiredText(item, "sha256", 64).toLowerCase();
    if (!/^[a-f0-9]{64}$/.test(sha256)) throw badRequest("Image identity is invalid.");
    const bytesBase64 = requiredText(item, "bytesBase64", Math.ceil(maximumMediaBytes * 4 / 3) + 8);
    const bytes = Buffer.from(bytesBase64, "base64");
    if (bytes.length !== byteLength || createHash("sha256").update(bytes).digest("hex") !== sha256) {
      throw badRequest("Image bytes do not match the selected file.");
    }
    if (!mediaMatchesContentType(bytes, contentType)) {
      throw badRequest("Image bytes do not match the selected image format.");
    }
    return { slot, fileName, contentType, byteLength, sha256, bytes };
  });
}

function mediaMatchesContentType(bytes: Buffer, contentType: string): boolean {
  if (contentType === "image/jpeg") {
    return bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  }
  if (contentType === "image/png") {
    return bytes.length >= 8 && bytes.subarray(0, 8).equals(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
  }
  return bytes.length >= 12 &&
    bytes.subarray(0, 4).toString("ascii") === "RIFF" &&
    bytes.subarray(8, 12).toString("ascii") === "WEBP";
}

function parseChoices(raw: unknown): SocialChoiceInput[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw) || raw.length > 4) throw badRequest("Use no more than four choices.");
  return raw.map((entry) => {
    const choice = object(entry);
    const mediaSlot = optionalText(choice, "mediaSlot", 48);
    return {
      label: requiredText(choice, "label", 120),
      ...(mediaSlot === undefined ? {} : { mediaSlot }),
    };
  });
}

function validateFormat(
  type: SocialContentType,
  body: string,
  mediaSlots: string[],
  choices: SocialChoiceInput[],
  correctChoiceIndex: number | undefined,
): void {
  if (type === "post") {
    if (!body && mediaSlots.length === 0) throw badRequest("Write something or add an image.");
    if (mediaSlots.length > 1 || choices.length > 0 || correctChoiceIndex !== undefined) {
      throw badRequest("A post supports text and one image.");
    }
    return;
  }
  if (type === "carousel") {
    if (mediaSlots.length < 2 || mediaSlots.length > 10 || choices.length > 0 || correctChoiceIndex !== undefined) {
      throw badRequest("A carousel needs between 2 and 10 images.");
    }
    return;
  }
  if (!body || choices.length < 2 || choices.length > 4) {
    throw badRequest("Add a question and between two and four choices.");
  }
  if (type === "imagePoll") {
    if (mediaSlots.length !== 0 || choices.some((choice) => !choice.mediaSlot) || correctChoiceIndex !== undefined) {
      throw badRequest("Every Image Poll choice needs one image.");
    }
    return;
  }
  if (mediaSlots.length !== 0 || choices.some((choice) => choice.mediaSlot)) {
    throw badRequest("This poll format does not accept images.");
  }
  if (type === "quiz") {
    if (correctChoiceIndex === undefined || correctChoiceIndex < 0 || correctChoiceIndex >= choices.length) {
      throw badRequest("Choose the correct Quiz answer.");
    }
  } else if (correctChoiceIndex !== undefined) {
    throw badRequest("Only a Quiz has a correct answer.");
  }
}

function object(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw badRequest("A valid request body is required.");
  }
  return value as Record<string, unknown>;
}

function requiredText(body: Record<string, unknown>, name: string, maximum: number): string {
  const value = body[name];
  if (typeof value !== "string" || !value.trim() || value.trim().length > maximum) {
    throw badRequest(`${name} is invalid.`);
  }
  return value.trim();
}

function optionalText(body: Record<string, unknown>, name: string, maximum: number): string | undefined {
  const value = body[name];
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value !== "string" || value.trim().length > maximum) {
    throw badRequest(`${name} is invalid.`);
  }
  return value.trim();
}

function optionalInteger(body: Record<string, unknown>, name: string): number | undefined {
  const value = body[name];
  if (value === undefined || value === null) return undefined;
  if (!Number.isSafeInteger(value)) throw badRequest(`${name} must be a whole number.`);
  return value as number;
}

function textArray(raw: unknown, name: string, maximum: number): string[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw) || raw.length > maximum) throw badRequest(`${name} is invalid.`);
  const values = raw.map((value) => {
    if (typeof value !== "string" || !/^[a-z]+:[0-9]$/.test(value)) {
      throw badRequest(`${name} is invalid.`);
    }
    return value;
  });
  if (new Set(values).size !== values.length) throw badRequest(`${name} contains duplicates.`);
  return values;
}

function badRequest(message: string): SocialContentError {
  return new SocialContentError("bad_request", message, 400);
}
