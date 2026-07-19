import { mkdir, readdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import sharp from "../apps/admin/node_modules/sharp/lib/index.js";

const [, , inputArg, outputArg, filterArg = ""] = process.argv;

if (!inputArg || !outputArg) {
  throw new Error(
    "Usage: node scripts/create-visual-audit-board.mjs <input-dir> <output.png> [name-filter]",
  );
}

const inputDirectory = resolve(inputArg);
const outputPath = resolve(outputArg);
const files = (await readdir(inputDirectory))
  .filter(
    (name) =>
      name.toLowerCase().endsWith(".png") &&
      name.toLowerCase().includes(filterArg.toLowerCase()),
  )
  .sort();

if (files.length === 0) {
  throw new Error(`No PNG files matched "${filterArg}" in ${inputDirectory}`);
}

const columns = Math.min(4, files.length);
const imageWidth = 206;
const imageHeight = 458;
const labelHeight = 42;
const gap = 12;
const cellWidth = imageWidth + gap * 2;
const cellHeight = imageHeight + labelHeight + gap * 2;
const rows = Math.ceil(files.length / columns);

const composites = [];

for (const [index, name] of files.entries()) {
  const column = index % columns;
  const row = Math.floor(index / columns);
  const left = column * cellWidth + gap;
  const top = row * cellHeight + gap;
  const image = await sharp(resolve(inputDirectory, name))
    .resize(imageWidth, imageHeight, { fit: "contain" })
    .png()
    .toBuffer();
  const escapedName = name
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
  const label = Buffer.from(
    `<svg width="${imageWidth}" height="${labelHeight}">
      <rect width="100%" height="100%" fill="#ffffff"/>
      <text x="8" y="17" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#07006f">${escapedName}</text>
      <text x="8" y="33" font-family="Arial, sans-serif" font-size="10" fill="#5d5b75">${index + 1} of ${files.length}</text>
    </svg>`,
  );
  composites.push(
    { input: image, left, top },
    { input: label, left, top: top + imageHeight },
  );
}

await mkdir(dirname(outputPath), { recursive: true });
await sharp({
  create: {
    width: columns * cellWidth,
    height: rows * cellHeight,
    channels: 4,
    background: "#eef1f8",
  },
})
  .composite(composites)
  .png()
  .toFile(outputPath);

console.log(`Created ${outputPath} from ${files.length} screenshot(s).`);
