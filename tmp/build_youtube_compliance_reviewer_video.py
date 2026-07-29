from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION")
SOURCE = (
    ROOT
    / "artifacts"
    / "quality"
    / "youtube-compliance-follow-up-20260729-01"
    / "moolsocial-youtube-compliance-public-flow-r20-source-native-01.mp4"
)
ASSETS = ROOT / "tmp" / "youtube-compliance-reviewer-video-assets"
OUTPUT = (
    ROOT
    / "output"
    / "video"
    / "MoolSocial-YouTube-API-Compliance-Walkthrough-r20.mp4"
)

WIDTH = 720
HEIGHT = 1612
NAVY = (8, 5, 125)
DEEP_NAVY = (4, 2, 66)
WHITE = (255, 255, 255)
MUTED = (202, 207, 232)
ORANGE = (255, 151, 46)
GREEN = (21, 148, 71)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(Path(r"C:\Windows\Fonts") / name), size)


REGULAR = font("arial.ttf", 30)
SMALL = font("arial.ttf", 24)
LABEL = font("arialbd.ttf", 24)
TITLE = font("arialbd.ttf", 50)
HERO = font("arialbd.ttf", 64)


def wrapped_lines(
    draw: ImageDraw.ImageDraw,
    text: str,
    selected_font: ImageFont.FreeTypeFont,
    max_width: int,
) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textbbox((0, 0), candidate, font=selected_font)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def paragraph(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    selected_font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    max_width: int,
    line_gap: int = 12,
) -> int:
    x, y = xy
    for line in wrapped_lines(draw, text, selected_font, max_width):
        draw.text((x, y), line, font=selected_font, fill=fill)
        bbox = draw.textbbox((x, y), line, font=selected_font)
        y = bbox[3] + line_gap
    return y


def background() -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), DEEP_NAVY)
    pixels = image.load()
    for y in range(HEIGHT):
        blend = y / (HEIGHT - 1)
        for x in range(WIDTH):
            side = abs(x - WIDTH / 2) / (WIDTH / 2)
            glow = max(0.0, 1.0 - side) * (1.0 - 0.55 * blend)
            pixels[x, y] = (
                int(DEEP_NAVY[0] * blend + NAVY[0] * (1 - blend) + 8 * glow),
                int(DEEP_NAVY[1] * blend + NAVY[1] * (1 - blend) + 5 * glow),
                min(
                    255,
                    int(
                        DEEP_NAVY[2] * blend
                        + NAVY[2] * (1 - blend)
                        + 22 * glow
                    ),
                ),
            )
    return image


def brand(draw: ImageDraw.ImageDraw) -> None:
    draw.text((54, 76), "MoolSocial", font=TITLE, fill=WHITE)
    y = 144
    draw.rounded_rectangle((56, y, 188, y + 10), radius=5, fill=ORANGE)
    draw.rectangle((188, y, 244, y + 10), fill=WHITE)
    draw.rounded_rectangle((244, y, 330, y + 10), radius=5, fill=GREEN)


def card(
    filename: str,
    eyebrow: str,
    title: str,
    body: str,
    facts: list[tuple[str, str]],
    footer: str,
) -> Path:
    image = background()
    draw = ImageDraw.Draw(image)
    brand(draw)

    draw.text((56, 250), eyebrow.upper(), font=LABEL, fill=ORANGE)
    y = paragraph(draw, title, (56, 298), HERO, WHITE, 610, line_gap=18)
    y = paragraph(draw, body, (56, y + 28), REGULAR, MUTED, 610, line_gap=14)

    y += 34
    for key, value in facts:
        top = y
        value_lines = wrapped_lines(draw, value, SMALL, 540)
        height = max(106, 74 + 34 * len(value_lines))
        draw.rounded_rectangle(
            (54, top, 666, top + height),
            radius=22,
            fill=(22, 20, 123),
            outline=(90, 94, 180),
            width=2,
        )
        draw.text((78, top + 18), key, font=LABEL, fill=WHITE)
        value_y = top + 54
        for line in value_lines:
            draw.text((78, value_y), line, font=SMALL, fill=MUTED)
            value_y += 34
        y = top + height + 18

    draw.rounded_rectangle(
        (54, HEIGHT - 214, 666, HEIGHT - 82),
        radius=24,
        fill=(236, 247, 238),
    )
    paragraph(
        draw,
        footer,
        (78, HEIGHT - 185),
        SMALL,
        (10, 86, 43),
        560,
        line_gap=10,
    )

    ASSETS.mkdir(parents=True, exist_ok=True)
    target = ASSETS / filename
    image.save(target, "PNG", optimize=True)
    return target


def build() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)

    intro = card(
        "00-intro.png",
        "YouTube API Services",
        "Private-Dev compliance walkthrough",
        "A step-by-step visual reference of the API Client and its visible end results.",
        [
            ("Project", "moolsocial-dev-503018"),
            ("Package", "com.moolsocial.app"),
            ("Review build", "youtube-compliance-followup-20260729-20"),
            ("Physical device", "OPPO CPH2375 · Android 13"),
        ],
        "Public data and official embedded playback are demonstrated. No Production access is claimed.",
    )
    step_one = card(
        "01-discovery.png",
        "Step 1",
        "Discover eligible public videos",
        "The reviewer run begins on the live, source-attributed MoolSocial Videos library.",
        [
            ("Data operation", "videos.list · chart=mostPopular · India"),
            ("Enrichment", "channels.list for returned channel IDs"),
        ],
        "End result: genuine public items, metadata and YouTube source attribution inside a MoolSocial-owned catalogue.",
    )
    step_two = card(
        "02-playback.png",
        "Step 2",
        "Play one selected video",
        "A deliberate user tap mounts the official YouTube embedded player.",
        [
            ("Playback", "Official YouTube embedded player"),
            ("Separation", "MoolSocial actions remain outside the player"),
        ],
        "End result: YouTube branding, controls and Watch on YouTube remain visible and unobstructed.",
    )
    step_three = card(
        "03-shorts.png",
        "Step 3",
        "Open the bounded Shorts lane",
        "MoolSocial changes between distinct eligible public Shorts without claiming YouTube's native recommendation feed.",
        [
            ("Candidates", "Bounded, quota-sensitive search.list"),
            ("Eligibility", "videos.list metadata hydration"),
        ],
        "End result: public, processed, embeddable and India-available items play in the official YouTube player.",
    )
    step_four = card(
        "04-details.png",
        "Step 4",
        "Review returned public details",
        "The selected item's public metadata and provider-playback disclosure remain explicit.",
        [
            ("Visible metadata", "Title, channel, views, likes and age"),
            ("Player disclosure", "Playback uses the official YouTube player"),
        ],
        "End result: the source and playback boundary are clear to the reviewer and to the customer.",
    )
    closing = card(
        "05-closing.png",
        "Current demonstrated boundary",
        "What this reviewer build proves",
        "The broad endpoint selections in the original form included a staged roadmap. This recording shows only the current API Client.",
        [
            ("Demonstrated", "videos.list · channels.list · bounded search.list · official playback"),
            ("Separately proven", "youtube.readonly VetoNews channel connection"),
            ("Not active", "Uploads · viewer mutations · Analytics/Reporting · Live management"),
        ],
        "Contact: hello@moolsocial.com · No MoolSocial advertising or commerce appears inside or over the YouTube player.",
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    filter_graph = (
        "[0:v]trim=duration=6,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c0];"
        "[2:v]trim=duration=3.5,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c1];"
        "[1:v]trim=start=1:end=9,setpts=PTS-STARTPTS,fps=30,format=yuv420p[s1];"
        "[3:v]trim=duration=3.5,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c2];"
        "[1:v]trim=start=9:end=26,setpts=PTS-STARTPTS,fps=30,format=yuv420p[s2];"
        "[4:v]trim=duration=3.5,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c3];"
        "[1:v]trim=start=26:end=57,setpts=PTS-STARTPTS,fps=30,format=yuv420p[s3];"
        "[5:v]trim=duration=3.5,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c4];"
        "[1:v]trim=start=57:end=63,setpts=PTS-STARTPTS,fps=30,format=yuv420p[s4];"
        "[6:v]trim=duration=8,setpts=PTS-STARTPTS,fps=30,format=yuv420p[c5];"
        "[c0][c1][s1][c2][s2][c3][s3][c4][s4][c5]"
        "concat=n=10:v=1:a=0[outv]"
    )
    command = [
        "ffmpeg",
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(intro),
        "-i",
        str(SOURCE),
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(step_one),
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(step_two),
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(step_three),
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(step_four),
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(closing),
        "-filter_complex",
        filter_graph,
        "-map",
        "[outv]",
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "23",
        "-profile:v",
        "high",
        "-level",
        "4.1",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(OUTPUT),
    ]
    subprocess.run(command, check=True)
    print(f"VIDEO={OUTPUT}")
    print(f"BYTES={OUTPUT.stat().st_size}")


if __name__ == "__main__":
    build()
