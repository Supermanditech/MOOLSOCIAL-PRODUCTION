import {
  assertYouTubeChannelId,
  assertYouTubeVideoId,
  canonicalYouTubeWebSubProviderTimestamp,
  deriveYouTubeWebSubEventKey,
  YOUTUBE_WEBSUB_HUB_URL,
  type YouTubeWebSubEventKind,
} from "./websub_contract.js";
import {
  DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES,
  isYouTubeWebSubRawBodyBounded,
} from "./websub_security.js";

const ATOM_NAMESPACE = "http://www.w3.org/2005/Atom";
const YOUTUBE_NAMESPACE =
  "http://www.youtube.com/xml/schemas/2015";
const TOMBSTONE_NAMESPACE =
  "http://purl.org/atompub/tombstones/1.0";
const YOUTUBE_HUB_URL_WITHOUT_TRAILING_SLASH =
  "https://pubsubhubbub.appspot.com";
const XML_NAME_PATTERN = /^[A-Za-z_][A-Za-z0-9_.:-]*/u;

export interface YouTubeWebSubAtomLimits {
  readonly maxRawBodyBytes: number;
  readonly maxElements: number;
  readonly maxDepth: number;
  readonly maxTextCharacters: number;
  readonly maxEntries: number;
  readonly maxAttributesPerElement: number;
  readonly maxAttributeValueCharacters: number;
}

export const DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS: Readonly<
  YouTubeWebSubAtomLimits
> = Object.freeze({
  maxRawBodyBytes: DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES,
  maxElements: 1_024,
  maxDepth: 16,
  maxTextCharacters: 131_072,
  maxEntries: 50,
  maxAttributesPerElement: 64,
  maxAttributeValueCharacters: 4_096,
});

export type YouTubeWebSubAtomErrorCode =
  | "body_too_large"
  | "channel_mismatch"
  | "entry_limit_exceeded"
  | "invalid_atom"
  | "invalid_identifier"
  | "invalid_namespace"
  | "invalid_timestamp"
  | "invalid_xml"
  | "resource_limit_exceeded"
  | "unsafe_xml";

export class YouTubeWebSubAtomError extends TypeError {
  constructor(
    readonly code: YouTubeWebSubAtomErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "YouTubeWebSubAtomError";
  }
}

interface XmlElement {
  readonly qName: string;
  readonly localName: string;
  readonly namespaceUri?: string;
  readonly attributes: ReadonlyMap<string, string>;
  readonly namespaces: ReadonlyMap<string, string>;
  readonly children: XmlElement[];
  readonly textParts: string[];
}

interface MutableXmlElement {
  qName: string;
  localName: string;
  namespaceUri?: string;
  attributes: Map<string, string>;
  namespaces: Map<string, string>;
  children: MutableXmlElement[];
  textParts: string[];
}

export interface YouTubeWebSubAtomUpsertEvent {
  readonly kind: "UPSERT_CANDIDATE";
  readonly eventKey: string;
  readonly channelId: string;
  readonly videoId: string;
  readonly entryId: string;
  readonly publishedAt?: string;
  readonly updatedAt: string;
}

export interface YouTubeWebSubAtomDeleteHint {
  readonly kind: "DELETE_HINT";
  readonly eventKey: string;
  readonly channelId: string;
  readonly videoId: string;
  readonly entryId: string;
  readonly deletedAt: string;
  readonly requiresExistingSnapshotOriginCheck: true;
}

export type YouTubeWebSubAtomEvent =
  | YouTubeWebSubAtomUpsertEvent
  | YouTubeWebSubAtomDeleteHint;

export interface YouTubeWebSubAtomFeed {
  readonly channelId: string;
  readonly feedUpdatedAt?: string;
  readonly events: readonly YouTubeWebSubAtomEvent[];
}

function resolveLimits(
  partial: Partial<YouTubeWebSubAtomLimits> | undefined,
): Readonly<YouTubeWebSubAtomLimits> {
  const resolved = {
    ...DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS,
    ...partial,
  };
  for (const [name, value] of Object.entries(resolved)) {
    const hardMaximum =
      DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS[
        name as keyof YouTubeWebSubAtomLimits
      ];
    if (
      !Number.isSafeInteger(value) ||
      value <= 0 ||
      value > hardMaximum
    ) {
      throw new TypeError(
        `${name} must be a positive integer no greater than ${hardMaximum}.`,
      );
    }
  }
  return Object.freeze(resolved);
}

function xmlError(
  code: YouTubeWebSubAtomErrorCode,
  message: string,
): never {
  throw new YouTubeWebSubAtomError(code, message);
}

function validXmlCodePoint(codePoint: number): boolean {
  return (
    codePoint === 0x9 ||
    codePoint === 0xa ||
    codePoint === 0xd ||
    (codePoint >= 0x20 && codePoint <= 0xd7ff) ||
    (codePoint >= 0xe000 && codePoint <= 0xfffd) ||
    (codePoint >= 0x10000 && codePoint <= 0x10ffff)
  );
}

function assertValidXmlCharacters(value: string): void {
  for (const character of value) {
    const codePoint = character.codePointAt(0);
    if (codePoint === undefined || !validXmlCodePoint(codePoint)) {
      xmlError("invalid_xml", "XML contains an invalid character.");
    }
  }
}

function decodeXmlEntities(value: string): string {
  let result = "";
  let cursor = 0;
  while (cursor < value.length) {
    const ampersand = value.indexOf("&", cursor);
    if (ampersand < 0) {
      result += value.slice(cursor);
      break;
    }
    result += value.slice(cursor, ampersand);
    const semicolon = value.indexOf(";", ampersand + 1);
    if (semicolon < 0) {
      xmlError("invalid_xml", "XML entity reference is unterminated.");
    }
    const entity = value.slice(ampersand + 1, semicolon);
    const predefined: Readonly<Record<string, string>> = {
      amp: "&",
      apos: "'",
      gt: ">",
      lt: "<",
      quot: "\"",
    };
    let decoded = predefined[entity];
    if (decoded === undefined && /^#[0-9]+$/u.test(entity)) {
      const codePoint = Number(entity.slice(1));
      if (!Number.isSafeInteger(codePoint) || !validXmlCodePoint(codePoint)) {
        xmlError("invalid_xml", "XML numeric entity is invalid.");
      }
      decoded = String.fromCodePoint(codePoint);
    } else if (decoded === undefined && /^#x[0-9A-Fa-f]+$/u.test(entity)) {
      const codePoint = Number.parseInt(entity.slice(2), 16);
      if (!Number.isSafeInteger(codePoint) || !validXmlCodePoint(codePoint)) {
        xmlError("invalid_xml", "XML hexadecimal entity is invalid.");
      }
      decoded = String.fromCodePoint(codePoint);
    }
    if (decoded === undefined) {
      xmlError(
        "unsafe_xml",
        "Only predefined and numeric XML entities are accepted.",
      );
    }
    result += decoded;
    cursor = semicolon + 1;
  }
  assertValidXmlCharacters(result);
  return result;
}

function assertQualifiedName(value: string): void {
  const parts = value.split(":");
  if (
    parts.length > 2 ||
    parts.some(
      (part) =>
        part === "" ||
        !/^[A-Za-z_][A-Za-z0-9_.-]*$/u.test(part),
    )
  ) {
    xmlError("invalid_xml", "XML qualified name is invalid.");
  }
}

interface ParsedStartTag {
  readonly qName: string;
  readonly attributes: ReadonlyMap<string, string>;
}

function parseStartTag(
  content: string,
  limits: Readonly<YouTubeWebSubAtomLimits>,
): ParsedStartTag {
  let cursor = 0;
  const nameMatch = XML_NAME_PATTERN.exec(content);
  if (nameMatch === null) {
    xmlError("invalid_xml", "XML start tag has no valid name.");
  }
  const qName = nameMatch[0];
  assertQualifiedName(qName);
  cursor = qName.length;
  const attributes = new Map<string, string>();

  while (cursor < content.length) {
    while (cursor < content.length && /\s/u.test(content[cursor] ?? "")) {
      cursor += 1;
    }
    if (cursor >= content.length) {
      break;
    }
    const attributeMatch = XML_NAME_PATTERN.exec(content.slice(cursor));
    if (attributeMatch === null) {
      xmlError("invalid_xml", "XML attribute name is invalid.");
    }
    const attributeName = attributeMatch[0];
    assertQualifiedName(attributeName);
    cursor += attributeName.length;
    while (cursor < content.length && /\s/u.test(content[cursor] ?? "")) {
      cursor += 1;
    }
    if (content[cursor] !== "=") {
      xmlError("invalid_xml", "XML attribute is missing equals.");
    }
    cursor += 1;
    while (cursor < content.length && /\s/u.test(content[cursor] ?? "")) {
      cursor += 1;
    }
    const quote = content[cursor];
    if (quote !== "\"" && quote !== "'") {
      xmlError("invalid_xml", "XML attribute value must be quoted.");
    }
    cursor += 1;
    const end = content.indexOf(quote, cursor);
    if (end < 0) {
      xmlError("invalid_xml", "XML attribute value is unterminated.");
    }
    const decoded = decodeXmlEntities(content.slice(cursor, end));
    if (decoded.length > limits.maxAttributeValueCharacters) {
      xmlError(
        "resource_limit_exceeded",
        "XML attribute value exceeds the configured limit.",
      );
    }
    if (attributes.has(attributeName)) {
      xmlError("invalid_xml", "XML element contains a duplicate attribute.");
    }
    attributes.set(attributeName, decoded);
    if (attributes.size > limits.maxAttributesPerElement) {
      xmlError(
        "resource_limit_exceeded",
        "XML element exceeds the configured attribute limit.",
      );
    }
    cursor = end + 1;
  }
  return { qName, attributes };
}

function findTagEnd(xml: string, start: number): number {
  let quote: "\"" | "'" | undefined;
  for (let cursor = start; cursor < xml.length; cursor += 1) {
    const character = xml[cursor];
    if (quote !== undefined) {
      if (character === quote) {
        quote = undefined;
      }
      continue;
    }
    if (character === "\"" || character === "'") {
      quote = character;
    } else if (character === ">") {
      return cursor;
    } else if (character === "<") {
      xmlError("invalid_xml", "XML tag contains an unexpected less-than.");
    }
  }
  xmlError("invalid_xml", "XML tag is unterminated.");
}

function appendText(
  stack: readonly MutableXmlElement[],
  value: string,
  state: { textCharacters: number },
  limits: Readonly<YouTubeWebSubAtomLimits>,
): void {
  const decoded = decodeXmlEntities(value);
  if (stack.length === 0) {
    if (decoded.trim() !== "") {
      xmlError("invalid_xml", "XML contains text outside its root element.");
    }
    return;
  }
  state.textCharacters += decoded.length;
  if (state.textCharacters > limits.maxTextCharacters) {
    xmlError(
      "resource_limit_exceeded",
      "XML text exceeds the configured character limit.",
    );
  }
  stack[stack.length - 1]?.textParts.push(decoded);
}

function namespaceMap(
  parent: ReadonlyMap<string, string> | undefined,
  attributes: ReadonlyMap<string, string>,
): Map<string, string> {
  const namespaces = new Map(parent);
  for (const [name, value] of attributes) {
    if (name === "xmlns") {
      namespaces.set("", value);
    } else if (name.startsWith("xmlns:")) {
      const prefix = name.slice("xmlns:".length);
      if (
        prefix === "" ||
        prefix === "xmlns" ||
        (prefix === "xml" &&
          value !== "http://www.w3.org/XML/1998/namespace")
      ) {
        xmlError("invalid_namespace", "XML namespace declaration is invalid.");
      }
      namespaces.set(prefix, value);
    }
  }
  return namespaces;
}

function elementNamespace(
  qName: string,
  namespaces: ReadonlyMap<string, string>,
): string | undefined {
  const colon = qName.indexOf(":");
  const prefix = colon < 0 ? "" : qName.slice(0, colon);
  const namespaceUri = namespaces.get(prefix);
  if (colon >= 0 && namespaceUri === undefined) {
    xmlError("invalid_namespace", "XML element uses an unbound prefix.");
  }
  return namespaceUri;
}

function parseXmlDocument(
  xml: string,
  limits: Readonly<YouTubeWebSubAtomLimits>,
): XmlElement {
  const roots: MutableXmlElement[] = [];
  const stack: MutableXmlElement[] = [];
  const state = { textCharacters: 0, elements: 0 };
  let cursor = xml.charCodeAt(0) === 0xfeff ? 1 : 0;
  let declarationSeen = false;

  while (cursor < xml.length) {
    const lessThan = xml.indexOf("<", cursor);
    if (lessThan < 0) {
      appendText(stack, xml.slice(cursor), state, limits);
      cursor = xml.length;
      break;
    }
    appendText(stack, xml.slice(cursor, lessThan), state, limits);
    cursor = lessThan;

    if (xml.startsWith("<!--", cursor)) {
      const end = xml.indexOf("-->", cursor + 4);
      if (
        end < 0 ||
        xml.slice(cursor + 4, end).includes("--")
      ) {
        xmlError("invalid_xml", "XML comment is invalid.");
      }
      cursor = end + 3;
      continue;
    }
    if (xml.startsWith("<![CDATA[", cursor)) {
      if (stack.length === 0) {
        xmlError("invalid_xml", "CDATA is outside the root element.");
      }
      const end = xml.indexOf("]]>", cursor + 9);
      if (end < 0) {
        xmlError("invalid_xml", "CDATA section is unterminated.");
      }
      const value = xml.slice(cursor + 9, end);
      assertValidXmlCharacters(value);
      state.textCharacters += value.length;
      if (state.textCharacters > limits.maxTextCharacters) {
        xmlError(
          "resource_limit_exceeded",
          "XML text exceeds the configured character limit.",
        );
      }
      stack[stack.length - 1]?.textParts.push(value);
      cursor = end + 3;
      continue;
    }
    if (xml.startsWith("<?", cursor)) {
      const end = xml.indexOf("?>", cursor + 2);
      if (end < 0) {
        xmlError("invalid_xml", "XML processing instruction is unterminated.");
      }
      const instruction = xml.slice(cursor + 2, end).trim();
      if (
        declarationSeen ||
        roots.length > 0 ||
        stack.length > 0 ||
        !/^xml(?:\s|$)/u.test(instruction)
      ) {
        xmlError("unsafe_xml", "XML processing instruction is forbidden.");
      }
      declarationSeen = true;
      cursor = end + 2;
      continue;
    }
    if (xml.startsWith("<!", cursor)) {
      xmlError(
        "unsafe_xml",
        "XML declarations, DTDs and entity definitions are forbidden.",
      );
    }
    if (xml.startsWith("</", cursor)) {
      const end = xml.indexOf(">", cursor + 2);
      if (end < 0) {
        xmlError("invalid_xml", "XML end tag is unterminated.");
      }
      const qName = xml.slice(cursor + 2, end).trim();
      assertQualifiedName(qName);
      const active = stack.pop();
      if (active === undefined || active.qName !== qName) {
        xmlError("invalid_xml", "XML start and end tags do not match.");
      }
      cursor = end + 1;
      continue;
    }

    const end = findTagEnd(xml, cursor + 1);
    let content = xml.slice(cursor + 1, end).trim();
    const selfClosing = content.endsWith("/");
    if (selfClosing) {
      content = content.slice(0, -1).trimEnd();
    }
    const parsed = parseStartTag(content, limits);
    const parent = stack[stack.length - 1];
    const namespaces = namespaceMap(parent?.namespaces, parsed.attributes);
    const colon = parsed.qName.indexOf(":");
    const localName =
      colon < 0 ? parsed.qName : parsed.qName.slice(colon + 1);
    const namespaceUri = elementNamespace(parsed.qName, namespaces);
    const element: MutableXmlElement = {
      qName: parsed.qName,
      localName,
      ...(namespaceUri === undefined ? {} : { namespaceUri }),
      attributes: new Map(parsed.attributes),
      namespaces,
      children: [],
      textParts: [],
    };

    state.elements += 1;
    if (state.elements > limits.maxElements) {
      xmlError(
        "resource_limit_exceeded",
        "XML exceeds the configured element limit.",
      );
    }
    if (stack.length + 1 > limits.maxDepth) {
      xmlError(
        "resource_limit_exceeded",
        "XML exceeds the configured depth limit.",
      );
    }
    if (parent === undefined) {
      roots.push(element);
      if (roots.length > 1) {
        xmlError("invalid_xml", "XML must contain exactly one root element.");
      }
    } else {
      parent.children.push(element);
    }
    if (!selfClosing) {
      stack.push(element);
    }
    cursor = end + 1;
  }

  if (stack.length !== 0 || roots.length !== 1) {
    xmlError("invalid_xml", "XML document is incomplete.");
  }
  return roots[0] as XmlElement;
}

function directChildren(
  element: XmlElement,
  namespaceUri: string,
  localName: string,
): readonly XmlElement[] {
  return element.children.filter(
    (child) =>
      child.namespaceUri === namespaceUri &&
      child.localName === localName,
  );
}

function onlyChild(
  element: XmlElement,
  namespaceUri: string,
  localName: string,
  required: boolean,
): XmlElement | undefined {
  const matches = directChildren(element, namespaceUri, localName);
  if (matches.length > 1 || (required && matches.length !== 1)) {
    xmlError(
      "invalid_atom",
      `Atom element ${localName} must occur ${required ? "once" : "at most once"}.`,
    );
  }
  return matches[0];
}

function simpleText(element: XmlElement, name: string): string {
  if (element.children.length !== 0) {
    xmlError("invalid_atom", `${name} must contain only text.`);
  }
  const value = element.textParts.join("").trim();
  if (value === "") {
    xmlError("invalid_atom", `${name} must not be empty.`);
  }
  return value;
}

function childText(
  element: XmlElement,
  namespaceUri: string,
  localName: string,
  required: boolean,
): string | undefined {
  const child = onlyChild(element, namespaceUri, localName, required);
  return child === undefined ? undefined : simpleText(child, localName);
}

function validatedTimestamp(value: string, name: string): string {
  try {
    return canonicalYouTubeWebSubProviderTimestamp(value);
  } catch {
    xmlError("invalid_timestamp", `${name} is not a valid RFC 3339 timestamp.`);
  }
}

function requiredAttribute(
  element: XmlElement,
  name: string,
): string {
  const value = element.attributes.get(name)?.trim();
  if (value === undefined || value === "") {
    xmlError("invalid_atom", `Atom ${element.localName} is missing ${name}.`);
  }
  return value;
}

function validateFeedLink(
  link: XmlElement,
  expectedChannelId: string,
): void {
  const relation = link.attributes.get("rel");
  const href = link.attributes.get("href");
  if (relation === undefined || href === undefined) {
    return;
  }
  if (relation === "hub") {
    if (
      href !== YOUTUBE_WEBSUB_HUB_URL &&
      href !== YOUTUBE_HUB_URL_WITHOUT_TRAILING_SLASH
    ) {
      xmlError("invalid_atom", "Atom hub link does not match the fixed hub.");
    }
    return;
  }
  if (relation !== "self") {
    return;
  }

  let parsed: URL;
  try {
    parsed = new URL(href);
  } catch {
    xmlError("invalid_atom", "Atom self link is invalid.");
  }
  const allowedPath =
    parsed.pathname === "/feeds/videos.xml" ||
    parsed.pathname === "/xml/feeds/videos.xml";
  const providerIdentityProtocol =
    parsed.protocol === "https:" || parsed.protocol === "http:";
  const parameterNames = [...parsed.searchParams.keys()];
  if (
    !providerIdentityProtocol ||
    parsed.hostname !== "www.youtube.com" ||
    parsed.port !== "" ||
    parsed.username !== "" ||
    parsed.password !== "" ||
    parsed.hash !== "" ||
    !allowedPath ||
    parameterNames.length !== 1 ||
    parameterNames[0] !== "channel_id" ||
    parsed.searchParams.getAll("channel_id").length !== 1 ||
    parsed.searchParams.get("channel_id") !== expectedChannelId
  ) {
    xmlError(
      "invalid_atom",
      "Atom self link does not match an approved YouTube feed.",
    );
  }
}

function buildEventKey(
  kind: YouTubeWebSubEventKind,
  channelId: string,
  videoId: string,
  entryId: string,
  providerTimestamp: string,
): string {
  return deriveYouTubeWebSubEventKey({
    kind,
    channelId,
    videoId,
    entryId,
    providerTimestamp,
  });
}

function parseEntry(
  entry: XmlElement,
  expectedChannelId: string,
): YouTubeWebSubAtomUpsertEvent {
  const entryId = childText(entry, ATOM_NAMESPACE, "id", true) as string;
  const videoId = childText(
    entry,
    YOUTUBE_NAMESPACE,
    "videoId",
    true,
  ) as string;
  const channelId = childText(
    entry,
    YOUTUBE_NAMESPACE,
    "channelId",
    true,
  ) as string;
  try {
    assertYouTubeVideoId(videoId);
    assertYouTubeChannelId(channelId);
  } catch (error) {
    xmlError(
      "invalid_identifier",
      error instanceof Error ? error.message : "YouTube identifier is invalid.",
    );
  }
  if (channelId !== expectedChannelId) {
    xmlError(
      "channel_mismatch",
      "Atom entry channel does not match the callback subscription.",
    );
  }
  if (entryId !== `yt:video:${videoId}`) {
    xmlError(
      "invalid_identifier",
      "Atom entry ID does not match its YouTube video ID.",
    );
  }
  const published = childText(
    entry,
    ATOM_NAMESPACE,
    "published",
    false,
  );
  const updated = childText(
    entry,
    ATOM_NAMESPACE,
    "updated",
    true,
  ) as string;
  const publishedAt =
    published === undefined
      ? undefined
      : validatedTimestamp(published, "Atom published timestamp");
  const updatedAt = validatedTimestamp(
    updated,
    "Atom updated timestamp",
  );
  return {
    kind: "UPSERT_CANDIDATE",
    eventKey: buildEventKey(
      "UPSERT_CANDIDATE",
      channelId,
      videoId,
      entryId,
      updatedAt,
    ),
    channelId,
    videoId,
    entryId,
    ...(publishedAt === undefined ? {} : { publishedAt }),
    updatedAt,
  };
}

function parseTombstone(
  tombstone: XmlElement,
  expectedChannelId: string,
): YouTubeWebSubAtomDeleteHint {
  const entryId = requiredAttribute(tombstone, "ref");
  const match = /^yt:video:([A-Za-z0-9_-]{11})$/u.exec(entryId);
  if (match === null) {
    xmlError(
      "invalid_identifier",
      "Atom tombstone does not identify a YouTube video.",
    );
  }
  const videoId = match[1] as string;
  const deletedAt = validatedTimestamp(
    requiredAttribute(tombstone, "when"),
    "Atom tombstone timestamp",
  );
  return {
    kind: "DELETE_HINT",
    eventKey: buildEventKey(
      "DELETE_HINT",
      expectedChannelId,
      videoId,
      entryId,
      deletedAt,
    ),
    channelId: expectedChannelId,
    videoId,
    entryId,
    deletedAt,
    requiresExistingSnapshotOriginCheck: true,
  };
}

export function parseYouTubeWebSubAtomFeed(
  rawBody: Uint8Array,
  expectedChannelId: string,
  partialLimits?: Partial<YouTubeWebSubAtomLimits>,
): YouTubeWebSubAtomFeed {
  const limits = resolveLimits(partialLimits);
  if (
    !isYouTubeWebSubRawBodyBounded(
      rawBody,
      limits.maxRawBodyBytes,
    )
  ) {
    xmlError("body_too_large", "WebSub Atom body exceeds the byte limit.");
  }
  let xml: string;
  try {
    xml = new TextDecoder("utf-8", { fatal: true }).decode(rawBody);
  } catch {
    xmlError("invalid_xml", "WebSub Atom body is not valid UTF-8.");
  }
  const channelId = assertYouTubeChannelId(expectedChannelId);
  const root = parseXmlDocument(xml, limits);
  if (
    root.localName !== "feed" ||
    root.namespaceUri !== ATOM_NAMESPACE
  ) {
    xmlError(
      "invalid_namespace",
      "WebSub payload root must be an Atom feed.",
    );
  }
  for (const link of directChildren(root, ATOM_NAMESPACE, "link")) {
    validateFeedLink(link, channelId);
  }

  const feedUpdated = childText(
    root,
    ATOM_NAMESPACE,
    "updated",
    false,
  );
  const feedUpdatedAt =
    feedUpdated === undefined
      ? undefined
      : validatedTimestamp(feedUpdated, "Atom feed updated timestamp");
  const entries = directChildren(root, ATOM_NAMESPACE, "entry");
  const tombstones = directChildren(
    root,
    TOMBSTONE_NAMESPACE,
    "deleted-entry",
  );
  if (entries.length + tombstones.length > limits.maxEntries) {
    xmlError(
      "entry_limit_exceeded",
      "WebSub Atom feed exceeds the configured event limit.",
    );
  }

  const byEventKey = new Map<string, YouTubeWebSubAtomEvent>();
  for (const entry of entries) {
    const event = parseEntry(entry, channelId);
    byEventKey.set(event.eventKey, event);
  }
  for (const tombstone of tombstones) {
    const event = parseTombstone(tombstone, channelId);
    byEventKey.set(event.eventKey, event);
  }

  return {
    channelId,
    ...(feedUpdatedAt === undefined ? {} : { feedUpdatedAt }),
    events: [...byEventKey.values()],
  };
}
