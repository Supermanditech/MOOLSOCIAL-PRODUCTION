import { YouTubeProviderError } from "./errors.js";

const YOUTUBE_IMAGE_HOSTS = new Set([
  "i.ytimg.com",
  "img.youtube.com",
  "yt3.ggpht.com",
  "yt3.googleusercontent.com",
  "lh3.googleusercontent.com",
]);
const NUMBERED_YTIMG_HOST = /^i[1-9]\.ytimg\.com$/u;
const UNSAFE_PLAIN_TEXT_CONTROLS =
  /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/gu;
const BIDI_EMBEDDING_AND_OVERRIDE_CONTROLS =
  /[\u202A-\u202E\u2066-\u2069]/gu;
const MAX_PROVIDER_IMAGE_URL_CHARACTERS = 4_096;

function rejectProviderContent(message: string): never {
  throw new YouTubeProviderError("provider_rejected", message, 502);
}

function replaceUnpairedSurrogates(value: string): string {
  let result = "";
  for (let index = 0; index < value.length; index += 1) {
    const first = value.charCodeAt(index);
    if (first >= 0xd800 && first <= 0xdbff) {
      const second =
        index + 1 < value.length ? value.charCodeAt(index + 1) : -1;
      if (second >= 0xdc00 && second <= 0xdfff) {
        result += value.slice(index, index + 2);
        index += 1;
      } else {
        result += "\uFFFD";
      }
    } else if (first >= 0xdc00 && first <= 0xdfff) {
      result += "\uFFFD";
    } else {
      result += value.slice(index, index + 1);
    }
  }
  return result;
}

export function safeYouTubeProviderImageUrl(
  value: unknown,
  message: string,
): string {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.length > MAX_PROVIDER_IMAGE_URL_CHARACTERS
  ) {
    return rejectProviderContent(message);
  }
  try {
    const url = new URL(value);
    const hostname = url.hostname.toLowerCase();
    if (
      url.protocol !== "https:" ||
      url.username ||
      url.password ||
      (url.port && url.port !== "443") ||
      (!YOUTUBE_IMAGE_HOSTS.has(hostname) &&
        !NUMBERED_YTIMG_HOST.test(hostname))
    ) {
      return rejectProviderContent(message);
    }
    url.hash = "";
    return url.toString();
  } catch (error) {
    if (error instanceof YouTubeProviderError) throw error;
    return rejectProviderContent(message);
  }
}

/**
 * YouTube is requested with textFormat=plainText. Keep the value as text for
 * native rendering, normalize line endings and replace non-rendering control
 * characters. HTML-like text remains literal and must never be interpreted as
 * markup by a presentation adapter.
 */
export function safeYouTubeProviderPlainText(
  value: unknown,
  message: string,
): string {
  if (typeof value !== "string" || !value.trim()) {
    return rejectProviderContent(message);
  }
  return replaceUnpairedSurrogates(value)
    .replace(/\r\n?/gu, "\n")
    .replace(UNSAFE_PLAIN_TEXT_CONTROLS, "\uFFFD")
    .replace(BIDI_EMBEDDING_AND_OVERRIDE_CONTROLS, "\uFFFD")
    .normalize("NFC");
}
