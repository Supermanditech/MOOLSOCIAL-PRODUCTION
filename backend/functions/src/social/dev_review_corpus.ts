import { createHash } from "node:crypto";
import { deflateSync } from "node:zlib";

import type { SocialContentType } from "./contracts.js";

export const DEV_REVIEW_PROJECT_ID = "moolsocial-dev-503018";
export const DEV_REVIEW_CORPUS_VERSION = "c30k-community-preview-v1";

export interface DevReviewPersona {
  readonly key: string;
  readonly uid: string;
  readonly email: string;
  readonly displayName: string;
  readonly theme: string;
}

export interface DevReviewCorpusPost {
  readonly persona: DevReviewPersona;
  readonly copy: 1 | 2;
  readonly type: SocialContentType;
  readonly body: string;
  readonly imageVariants: readonly number[];
  readonly choices: readonly string[];
  readonly correctChoiceIndex?: number;
  readonly idempotencyKey: string;
}

export interface DevReviewMediaInput {
  readonly slot: string;
  readonly fileName: string;
  readonly contentType: "image/png";
  readonly byteLength: number;
  readonly sha256: string;
  readonly bytesBase64: string;
}

export interface DevReviewPublishRequest {
  readonly idempotencyKey: string;
  readonly contentType: SocialContentType;
  readonly body: string;
  readonly audience: "Public";
  readonly mediaSlots: readonly string[];
  readonly media: readonly DevReviewMediaInput[];
  readonly choices: readonly Readonly<{
    label: string;
    mediaSlot?: string;
  }>[];
  readonly correctChoiceIndex?: number;
}

export const DEV_REVIEW_PERSONAS: readonly DevReviewPersona[] = [
  {
    key: "asha",
    uid: "moolsocial-c30k-community-asha",
    email: "preview.asha@dev.moolsocial.com",
    displayName: "MoolSocial Preview · Asha",
    theme: "weekday rituals",
  },
  {
    key: "kabir",
    uid: "moolsocial-c30k-community-kabir",
    email: "preview.kabir@dev.moolsocial.com",
    displayName: "MoolSocial Preview · Kabir",
    theme: "neighbourhood discoveries",
  },
  {
    key: "meera",
    uid: "moolsocial-c30k-community-meera",
    email: "preview.meera@dev.moolsocial.com",
    displayName: "MoolSocial Preview · Meera",
    theme: "creative learning",
  },
] as const;

const orderedTypes: readonly SocialContentType[] = [
  "post",
  "carousel",
  "imagePoll",
  "quickPoll",
  "quiz",
] as const;

const imageCache = new Map<number, Buffer>();

export function buildDevReviewCorpus(): readonly DevReviewCorpusPost[] {
  const posts: DevReviewCorpusPost[] = [];
  for (let personaIndex = 0; personaIndex < DEV_REVIEW_PERSONAS.length; personaIndex += 1) {
    const persona = DEV_REVIEW_PERSONAS[personaIndex]!;
    for (const copy of [1, 2] as const) {
      for (const type of orderedTypes) {
        if (type === "post") {
          posts.push(buildPost(persona, personaIndex, copy, false));
          posts.push(buildPost(persona, personaIndex, copy, true));
          continue;
        }
        posts.push(buildPost(persona, personaIndex, copy, type));
      }
    }
  }
  validateDevReviewCorpus(posts);
  return posts;
}

export function buildDevReviewPublishRequest(
  post: DevReviewCorpusPost,
): DevReviewPublishRequest {
  const mediaSlots: string[] = [];
  const media: DevReviewMediaInput[] = [];
  const choices: Array<{ label: string; mediaSlot?: string }> = [];

  if (post.type === "post" && post.imageVariants.length === 1) {
    const slot = "media:0";
    mediaSlots.push(slot);
    media.push(mediaInput(slot, post.imageVariants[0]!));
  } else if (post.type === "carousel") {
    post.imageVariants.forEach((variant, index) => {
      const slot = `media:${index}`;
      mediaSlots.push(slot);
      media.push(mediaInput(slot, variant));
    });
  } else if (post.type === "imagePoll") {
    post.choices.forEach((label, index) => {
      const slot = `choice:${index}`;
      media.push(mediaInput(slot, post.imageVariants[index]!));
      choices.push({ label, mediaSlot: slot });
    });
  } else {
    post.choices.forEach((label) => choices.push({ label }));
  }

  return {
    idempotencyKey: post.idempotencyKey,
    contentType: post.type,
    body: post.body,
    audience: "Public",
    mediaSlots,
    media,
    choices,
    ...(post.correctChoiceIndex === undefined
      ? {}
      : { correctChoiceIndex: post.correctChoiceIndex }),
  };
}

export function summarizeDevReviewCorpus(posts: readonly DevReviewCorpusPost[]): {
  readonly personas: number;
  readonly posts: number;
  readonly mediaObjects: number;
  readonly byType: Readonly<Record<SocialContentType, number>>;
} {
  const byType: Record<SocialContentType, number> = {
    post: 0,
    carousel: 0,
    imagePoll: 0,
    quickPoll: 0,
    quiz: 0,
  };
  let mediaObjects = 0;
  for (const post of posts) {
    byType[post.type] += 1;
    mediaObjects += post.imageVariants.length;
  }
  return {
    personas: DEV_REVIEW_PERSONAS.length,
    posts: posts.length,
    mediaObjects,
    byType,
  };
}

export function validateDevReviewCorpus(
  posts: readonly DevReviewCorpusPost[],
): void {
  if (DEV_REVIEW_PERSONAS.length !== 3) {
    throw new Error("The Dev review corpus requires exactly three personas.");
  }
  if (posts.length !== 36) {
    throw new Error("The Dev review corpus requires exactly 36 posts.");
  }
  if (new Set(posts.map((post) => post.idempotencyKey)).size !== posts.length) {
    throw new Error("Every Dev review post needs a unique idempotency key.");
  }
  for (const persona of DEV_REVIEW_PERSONAS) {
    const owned = posts.filter((post) => post.persona.uid === persona.uid);
    if (owned.length !== 12) {
      throw new Error("Every Dev review persona must own exactly 12 posts.");
    }
    for (const type of orderedTypes) {
      const expected = type === "post" ? 4 : 2;
      if (owned.filter((post) => post.type === type).length !== expected) {
        throw new Error("Every requested format must have exactly two review copies.");
      }
    }
  }
  for (const type of orderedTypes) {
    const expected = type === "post" ? 12 : 6;
    if (posts.filter((post) => post.type === type).length !== expected) {
      throw new Error("The Dev review corpus format distribution is incomplete.");
    }
  }
  for (const post of posts) {
    const poll = post.type === "imagePoll" ||
      post.type === "quickPoll" ||
      post.type === "quiz";
    if (poll && post.choices.length !== 4) {
      throw new Error("Every poll and Quiz requires exactly four choices.");
    }
    if (post.type === "quiz" &&
      (post.correctChoiceIndex === undefined ||
        post.correctChoiceIndex < 0 ||
        post.correctChoiceIndex >= post.choices.length)) {
      throw new Error("Every Quiz requires one valid correct answer.");
    }
    if (post.type !== "quiz" && post.correctChoiceIndex !== undefined) {
      throw new Error("Only a Quiz can declare a correct answer.");
    }
  }
}

function buildPost(
  persona: DevReviewPersona,
  personaIndex: number,
  copy: 1 | 2,
  kind: SocialContentType | boolean,
): DevReviewCorpusPost {
  const type: SocialContentType = typeof kind === "boolean" ? "post" : kind;
  const imagePost = kind === true;
  const variantBase = personaIndex * 4 + (copy - 1) * 2;
  const body = bodyFor(persona, copy, type, imagePost);
  const choices = choicesFor(persona, copy, type);
  const imageVariants = imageVariantsFor(type, imagePost, variantBase);
  const identity = imagePost ? "image" : type === "post" ? "text" : type;
  return {
    persona,
    copy,
    type,
    body,
    imageVariants,
    choices,
    ...(type === "quiz" ? { correctChoiceIndex: copy === 1 ? 1 : 0 } : {}),
    idempotencyKey:
      `${DEV_REVIEW_CORPUS_VERSION}.${persona.key}.${identity}.${copy}`,
  };
}

function bodyFor(
  persona: DevReviewPersona,
  copy: 1 | 2,
  type: SocialContentType,
  imagePost: boolean,
): string {
  if (type === "post" && !imagePost) {
    return copy === 1
      ? `What is one small win from your ${persona.theme} that you want to remember today?`
      : `Which part of your ${persona.theme} would you happily share with a friend this week?`;
  }
  if (type === "post") {
    return copy === 1
      ? `A colour study inspired by ${persona.theme}. Which detail catches your eye first?`
      : `One simple frame from ${persona.theme}, saved before the day moved on.`;
  }
  if (type === "carousel") {
    return copy === 1
      ? `Three frames from ${persona.theme}: start, pause and finish.`
      : `A short visual sequence about ${persona.theme}. Swipe for the full set.`;
  }
  if (type === "imagePoll") {
    return copy === 1
      ? `Which colour direction best fits ${persona.theme}?`
      : `Which cover should lead the next ${persona.theme} collection?`;
  }
  if (type === "quickPoll") {
    return copy === 1
      ? `What helps you make time for ${persona.theme}?`
      : `What should the next ${persona.theme} post include?`;
  }
  return copy === 1
    ? "Which MoolSocial post format can contain up to ten photos?"
    : "Which MoolSocial post asks people to choose from four image options?";
}

function choicesFor(
  persona: DevReviewPersona,
  copy: 1 | 2,
  type: SocialContentType,
): readonly string[] {
  if (type === "imagePoll") {
    return copy === 1
      ? ["Sunrise", "Leaf", "Ocean", "Plum"]
      : ["Bold", "Calm", "Warm", "Crisp"];
  }
  if (type === "quickPoll") {
    return copy === 1
      ? ["A short walk", "Music", "A tea break", "Quiet time"]
      : ["More photos", "A short guide", "A checklist", "A live chat"];
  }
  if (type === "quiz") {
    return copy === 1
      ? ["Text post", "Carousel", "Quick Poll", "Quiz"]
      : ["Image Poll", "Carousel", "Text post", "YouTube Short"];
  }
  void persona;
  return [];
}

function imageVariantsFor(
  type: SocialContentType,
  imagePost: boolean,
  base: number,
): readonly number[] {
  if (type === "post") return imagePost ? [base % 12] : [];
  if (type === "carousel") return [base % 12, (base + 1) % 12, (base + 2) % 12];
  if (type === "imagePoll") {
    return [base % 12, (base + 1) % 12, (base + 2) % 12, (base + 3) % 12];
  }
  return [];
}

function mediaInput(slot: string, variant: number): DevReviewMediaInput {
  const bytes = reviewPng(variant);
  return {
    slot,
    fileName: `moolsocial-community-preview-${variant + 1}.png`,
    contentType: "image/png",
    byteLength: bytes.length,
    sha256: createHash("sha256").update(bytes).digest("hex"),
    bytesBase64: bytes.toString("base64"),
  };
}

function reviewPng(variant: number): Buffer {
  const normalized = ((variant % 12) + 12) % 12;
  const cached = imageCache.get(normalized);
  if (cached) return cached;
  const width = 480;
  const height = 270;
  const rowBytes = width * 3 + 1;
  const raw = Buffer.alloc(rowBytes * height);
  const palette: readonly (readonly [number, number, number])[] = [
    [17, 45, 78], [28, 85, 96], [33, 128, 90], [241, 172, 56],
    [220, 88, 82], [118, 75, 162], [34, 115, 183], [236, 126, 45],
    [56, 76, 115], [60, 150, 130], [185, 72, 118], [114, 140, 52],
  ];
  const primary = palette[normalized]!;
  const secondary = palette[(normalized + 3) % palette.length]!;
  for (let y = 0; y < height; y += 1) {
    const row = y * rowBytes;
    raw[row] = 0;
    for (let x = 0; x < width; x += 1) {
      const offset = row + 1 + x * 3;
      const diagonal = ((x + y * 2 + normalized * 31) % width) / width;
      const circleX = width * (0.25 + (normalized % 3) * 0.25);
      const circleY = height * (0.35 + (normalized % 2) * 0.25);
      const inCircle = (x - circleX) ** 2 + (y - circleY) ** 2 < 58 ** 2;
      const light = inCircle ? 0.34 : 0;
      for (let channel = 0; channel < 3; channel += 1) {
        const mixed = primary[channel]! * (1 - diagonal) +
          secondary[channel]! * diagonal;
        raw[offset + channel] = Math.round(mixed + (255 - mixed) * light);
      }
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8;
  header[9] = 2;
  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    pngChunk("IHDR", header),
    pngChunk("IDAT", deflateSync(raw, { level: 9 })),
    pngChunk("IEND", Buffer.alloc(0)),
  ]);
  imageCache.set(normalized, png);
  return png;
}

function pngChunk(type: string, data: Buffer): Buffer {
  const typeBytes = Buffer.from(type, "ascii");
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  typeBytes.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 8 + data.length);
  return chunk;
}

function crc32(input: Buffer): number {
  let crc = 0xffffffff;
  for (const byte of input) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ ((crc & 1) === 1 ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}
