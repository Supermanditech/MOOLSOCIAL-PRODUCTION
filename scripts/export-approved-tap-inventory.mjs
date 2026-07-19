import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDirectory, "..");
const approvedDirectory = path.resolve(
  root,
  "..",
  "supermandi-uiux-screenbook",
  "approved-final",
  "screens",
);
const outputPath = path.join(
  root,
  "docs",
  "quality",
  "APPROVED-TAP-INVENTORY.csv",
);

if (!fs.existsSync(approvedDirectory)) {
  throw new Error(`Approved screen source was not found: ${approvedDirectory}`);
}

const files = fs
  .readdirSync(approvedDirectory)
  .filter((name) => /^\d{2,3}-.+\.html$/i.test(name))
  .sort((left, right) => Number(left.split("-")[0]) - Number(right.split("-")[0]));

if (files.length !== 167) {
  throw new Error(`Expected 167 approved screens; found ${files.length}.`);
}

const expected = Array.from({ length: 167 }, (_, index) => index);
const actual = files.map((name) => Number(name.split("-")[0]));
if (actual.some((screen, index) => screen !== expected[index])) {
  throw new Error("Approved screen sequence must contain every screen from 000 to 166.");
}

function attribute(attributes, name) {
  const match = attributes.match(
    new RegExp(`${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, "i"),
  );
  return match?.[1] ?? match?.[2] ?? match?.[3] ?? "";
}

function clean(value) {
  return value
    .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&gt;/gi, ">")
    .replace(/&lt;/gi, "<")
    .replace(/&#39;/gi, "'")
    .replace(/&quot;/gi, '"')
    .replace(/\$\{[^}]+\}/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function compactLabel(tag, attributes, body) {
  const candidates = [
    attribute(attributes, "aria-label"),
    attribute(attributes, "data-action-label"),
    attribute(attributes, "title"),
    clean(body),
    attribute(attributes, "placeholder"),
    attribute(attributes, "name"),
    tag === "a" ? attribute(attributes, "href") : "",
  ];
  const value = clean(
    candidates.find((candidate) => clean(candidate).length > 0) ?? "",
  );
  if (
    !value ||
    /^(?:=+|button|a|input|select|textarea)$/i.test(value)
  ) {
    return `[unlabelled ${tag}]`;
  }
  return value.slice(0, 120);
}

function csv(value) {
  const text = String(value ?? "");
  return `"${text.replaceAll('"', '""')}"`;
}

const rows = files.map((fileName) => {
  const screen = Number(fileName.split("-")[0]);
  const source = fs.readFileSync(path.join(approvedDirectory, fileName), "utf8");
  const pattern =
    /<(button|a|select|textarea)\b([^>]*)>([\s\S]*?)<\/\1>|<input\b([^>]*)\/?>/gi;
  const scriptBodies = Array.from(
    source.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi),
    (script) => script[1],
  );
  const renderedSource = source
    .replace(/<style\b[\s\S]*?<\/style>/gi, "")
    .replace(/<script\b[\s\S]*?<\/script>/gi, "");
  const controls = [];

  function collect(segment, origin) {
    pattern.lastIndex = 0;
    let match;
    while ((match = pattern.exec(segment)) !== null) {
      const tag = (match[1] ?? "input").toLowerCase();
      const attributes = match[2] ?? match[4] ?? "";
      const body = match[3] ?? "";

      if (/\bscreen-link-home\b/i.test(attributes)) continue;
      if (
        tag === "input" &&
        attribute(attributes, "type").toLowerCase() === "hidden"
      ) {
        continue;
      }

      const href = tag === "a" ? attribute(attributes, "href") : "";
      if (href === "../index.html") continue;
      const nested =
        origin === "revealed" ||
        /\b(data-(?:open|close|sheet|dialog|modal|[^=\s>]*(?:action|control|submit))|aria-haspopup)\b/i.test(
          attributes,
        ) ||
        /\b(sheet|dialog|modal)\b/i.test(attributes);

      controls.push({
        tag,
        href,
        nested,
        origin,
        label: compactLabel(tag, attributes, body),
      });
    }
  }

  collect(renderedSource, "rendered");
  for (const scriptBody of scriptBodies) collect(scriptBody, "revealed");

  const unique = [];
  const seen = new Set();
  for (const control of controls) {
    const key = `${control.tag}|${control.label}|${control.href}`;
    if (!seen.has(key)) {
      seen.add(key);
      unique.push(control);
    }
  }

  const title = clean(source.match(/<title>([\s\S]*?)<\/title>/i)?.[1] ?? "");
  const navigation = unique.filter(
    (control) => control.tag === "a" && control.href && control.href !== "#",
  );
  const inputs = unique.filter((control) =>
    ["input", "select", "textarea"].includes(control.tag),
  );
  const nested = unique.filter((control) => control.nested);
  const rendered = unique.filter((control) => control.origin === "rendered");
  const revealed = unique.filter((control) => control.origin === "revealed");

  return {
    Screen: String(screen).padStart(3, "0"),
    ApprovedReference: fileName,
    Title: title,
    DirectAndReachableControls: unique.length,
    InitiallyRenderedControls: rendered.length,
    ScriptRevealedControls: revealed.length,
    NavigationLinks: navigation.length,
    Inputs: inputs.length,
    NestedSheetDialogActions: nested.length,
    ControlLabels: unique
      .map(
        (control) =>
          `${control.origin === "revealed" ? "nested " : ""}${control.tag}: ${control.label}`,
      )
      .join(" | "),
  };
});

const headers = Object.keys(rows[0]);
const csvText = [
  headers.map(csv).join(","),
  ...rows.map((row) => headers.map((header) => csv(row[header])).join(",")),
].join("\n");

fs.writeFileSync(outputPath, `${csvText}\n`, "utf8");

const totals = rows.reduce(
  (result, row) => ({
    controls: result.controls + row.DirectAndReachableControls,
    rendered: result.rendered + row.InitiallyRenderedControls,
    revealed: result.revealed + row.ScriptRevealedControls,
    links: result.links + row.NavigationLinks,
    inputs: result.inputs + row.Inputs,
    nested: result.nested + row.NestedSheetDialogActions,
  }),
  { controls: 0, rendered: 0, revealed: 0, links: 0, inputs: 0, nested: 0 },
);

process.stdout.write(
  `Approved tap inventory exported: ${rows.length} screens, ` +
    `${totals.controls} unique controls (${totals.rendered} initially rendered, ` +
    `${totals.revealed} script-revealed), ${totals.links} links, ` +
    `${totals.inputs} inputs and ${totals.nested} nested actions.\n`,
);
