from __future__ import annotations

import hashlib
import textwrap
from datetime import date
from pathlib import Path

from PIL import Image
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
TMP = ROOT / "tmp" / "pdfs"
GENERATED = TMP / "generated"
OUTPUT = ROOT / "output" / "pdf"
EVIDENCE = ROOT / "artifacts" / "quality"
AUDIT = EVIDENCE / "youtube-api-submission-readiness-20260725-01"
PUBLIC = EVIDENCE / "youtube-private-dev-oppo-public-viewing-20260725-01"

CAPTURE_DATE = date(2026, 7, 26)
PROJECT_ID = "moolsocial-dev-503018"
PROJECT_NUMBER = "760290687711"
CHANNEL_ID = "UC7rn0BIzhULpyw1NYXh-mWQ"

NAVY = colors.HexColor("#070A5B")
MID_NAVY = colors.HexColor("#111D77")
ORANGE = colors.HexColor("#FF922E")
GREEN = colors.HexColor("#198E3D")
INK = colors.HexColor("#12142B")
MUTED = colors.HexColor("#5E6478")
PALE = colors.HexColor("#F3F5FF")
LINE = colors.HexColor("#D7DBEC")
WHITE = colors.white
AMBER = colors.HexColor("#FFF3D8")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_directories() -> None:
    GENERATED.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)


def trim_text(value: str, width: float, font: str, size: float) -> str:
    if stringWidth(value, font, size) <= width:
        return value
    suffix = "..."
    candidate = value
    while candidate and stringWidth(candidate + suffix, font, size) > width:
        candidate = candidate[:-1]
    return candidate + suffix


def draw_wrapped(
    pdf: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    font: str = "Helvetica",
    size: float = 10,
    leading: float = 14,
    color=INK,
) -> float:
    pdf.setFont(font, size)
    pdf.setFillColor(color)
    words = text.split()
    line = ""
    lines: list[str] = []
    for word in words:
        candidate = f"{line} {word}".strip()
        if not line or stringWidth(candidate, font, size) <= width:
            line = candidate
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    for current in lines:
        pdf.drawString(x, y, current)
        y -= leading
    return y


def page_header(pdf: canvas.Canvas, title: str, page_number: int) -> None:
    width, height = pdf._pagesize
    pdf.setFillColor(NAVY)
    pdf.rect(0, height - 45, width, 45, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(28, height - 29, trim_text(title, width - 120, "Helvetica-Bold", 12))
    pdf.setFillColor(ORANGE)
    pdf.rect(28, height - 38, 45, 3, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica", 8)
    pdf.drawRightString(width - 28, height - 28, f"Page {page_number}")


def page_footer(pdf: canvas.Canvas, source: str, file_path: Path | None = None) -> None:
    width, _ = pdf._pagesize
    pdf.setStrokeColor(LINE)
    pdf.line(28, 30, width - 28, 30)
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica", 7)
    pdf.drawString(28, 18, trim_text(source, width - 260, "Helvetica", 7))
    if file_path is not None:
        pdf.drawRightString(width - 28, 18, f"SHA-256 {sha256(file_path)[:16]}...")


def cover_page(
    pdf: canvas.Canvas,
    title: str,
    subtitle: str,
    purpose: str,
    notice: str | None = None,
) -> None:
    width, height = pdf._pagesize
    pdf.setFillColor(NAVY)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)
    pdf.setFillColor(ORANGE)
    pdf.circle(width - 90, height - 80, 46, fill=1, stroke=0)
    pdf.setFillColor(GREEN)
    pdf.circle(width - 53, height - 46, 13, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 15)
    pdf.drawString(42, height - 70, "MoolSocial")
    pdf.setFillColor(ORANGE)
    pdf.rect(42, height - 82, 48, 4, fill=1, stroke=0)
    pdf.setFillColor(GREEN)
    pdf.rect(94, height - 82, 32, 4, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 27)
    y = height - 140
    for line in textwrap.wrap(title, width=42):
        pdf.drawString(42, y, line)
        y -= 34
    pdf.setFont("Helvetica", 13)
    pdf.setFillColor(colors.HexColor("#DDE2FF"))
    y = draw_wrapped(pdf, subtitle, 42, y - 7, width - 84, "Helvetica", 13, 18, colors.HexColor("#DDE2FF"))
    y = draw_wrapped(pdf, purpose, 42, y - 20, width - 84, "Helvetica", 10, 15, WHITE)
    if notice:
        pdf.setFillColor(AMBER)
        pdf.roundRect(42, 92, width - 84, 58, 10, fill=1, stroke=0)
        draw_wrapped(pdf, notice, 56, 128, width - 112, "Helvetica-Bold", 9, 13, INK)
    pdf.setFillColor(colors.HexColor("#C7CFF7"))
    pdf.setFont("Helvetica", 8.5)
    rows = [
        f"Applicant: SUPERMANDI TECH PRIVATE LIMITED",
        f"API client: MoolSocial",
        f"Dev project: {PROJECT_ID} ({PROJECT_NUMBER})",
        f"Owner-proof channel: VetoNews ({CHANNEL_ID})",
        f"Prepared: {CAPTURE_DATE.strftime('%d %B %Y')}",
    ]
    row_y = 72
    for row in rows:
        pdf.drawString(42, row_y, row)
        row_y -= 11
    pdf.showPage()


def create_slice(source: Path, start_y: int, height: int, name: str) -> Path:
    target = GENERATED / f"{name}.jpg"
    with Image.open(source) as image:
        top = max(0, min(start_y, image.height - 1))
        bottom = min(image.height, top + height)
        cropped = image.crop((0, top, image.width, bottom)).convert("RGB")
        cropped.save(target, "JPEG", quality=84, optimize=True, progressive=True)
    return target


def draw_image_contain(
    pdf: canvas.Canvas,
    image_path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
    background=colors.white,
) -> None:
    with Image.open(image_path) as image:
        image_width, image_height = image.size
    scale = min(width / image_width, height / image_height)
    draw_width = image_width * scale
    draw_height = image_height * scale
    draw_x = x + (width - draw_width) / 2
    draw_y = y + (height - draw_height) / 2
    pdf.setFillColor(background)
    pdf.roundRect(x, y, width, height, 8, fill=1, stroke=0)
    pdf.drawImage(
        ImageReader(str(image_path)),
        draw_x,
        draw_y,
        draw_width,
        draw_height,
        preserveAspectRatio=True,
        mask="auto",
    )


def screenshot_page(
    pdf: canvas.Canvas,
    document_title: str,
    page_number: int,
    image_path: Path,
    caption: str,
    source: str,
) -> None:
    width, height = pdf._pagesize
    page_header(pdf, document_title, page_number)
    pdf.setFillColor(PALE)
    pdf.rect(0, 0, width, height - 45, fill=1, stroke=0)
    draw_image_contain(pdf, image_path, 32, 73, width - 64, height - 140)
    draw_wrapped(pdf, caption, 36, 59, width - 72, "Helvetica", 8.5, 11, INK)
    page_footer(pdf, source, image_path)
    pdf.showPage()


def two_phone_page(
    pdf: canvas.Canvas,
    document_title: str,
    page_number: int,
    left: Path,
    left_label: str,
    right: Path,
    right_label: str,
    source: str,
) -> None:
    width, height = pdf._pagesize
    page_header(pdf, document_title, page_number)
    pdf.setFillColor(PALE)
    pdf.rect(0, 0, width, height - 45, fill=1, stroke=0)
    gap = 24
    box_width = (width - 96 - gap) / 2
    box_height = height - 136
    draw_image_contain(pdf, left, 36, 68, box_width, box_height)
    draw_image_contain(pdf, right, 36 + box_width + gap, 68, box_width, box_height)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawCentredString(36 + box_width / 2, 55, left_label)
    pdf.drawCentredString(36 + box_width + gap + box_width / 2, 55, right_label)
    page_footer(pdf, source)
    pdf.showPage()


def build_policy_pdf(
    filename: str,
    title: str,
    subtitle: str,
    url: str,
    screenshot: Path,
    addressbar_screenshot: Path,
    starts: list[int],
    captions: list[str],
) -> None:
    path = OUTPUT / filename
    pdf = canvas.Canvas(str(path), pagesize=landscape(A4), pageCompression=1)
    pdf.setTitle(title)
    cover_page(
        pdf,
        title,
        subtitle,
        f"Live public evidence captured from {url}. The PDF preserves the visible policy surface used in the YouTube API audit draft.",
    )
    for index, (start, caption) in enumerate(zip(starts, captions), start=2):
        image = (
            addressbar_screenshot
            if index == 2
            else create_slice(screenshot, start, 900, f"{Path(filename).stem}-{index}")
        )
        screenshot_page(pdf, title, index, image, caption, url)
    pdf.save()


def build_homepage_pdf() -> None:
    title = "MoolSocial public homepage evidence"
    path = OUTPUT / "moolsocial-youtube-homepage-evidence.pdf"
    source = TMP / "moolsocial-home-full.png"
    pdf = canvas.Canvas(str(path), pagesize=landscape(A4), pageCompression=1)
    pdf.setTitle(title)
    cover_page(
        pdf,
        title,
        "Public product identity, company presentation and legal-navigation evidence",
        "Captured from https://moolsocial.com/. This is the live website associated with the MoolSocial API client.",
    )
    slices = [
        (None, "Live browser first view: MoolSocial brand, HTTPS address and customer-facing product presentation."),
        (900, "Public product experience and application presentation."),
        (2700, "Public company and participation information."),
        (4226, "Public footer and legal-navigation area, including Privacy, Terms and support access."),
    ]
    for page_number, (start, caption) in enumerate(slices, start=2):
        image = (
            TMP / "moolsocial-home-addressbar.png"
            if start is None
            else create_slice(source, start, 900, f"homepage-{page_number}")
        )
        screenshot_page(pdf, title, page_number, image, caption, "https://moolsocial.com/")
    pdf.save()


def build_conditional_evidence_pdf() -> None:
    title = "MoolSocial YouTube current verified evidence"
    path = OUTPUT / "moolsocial-youtube-conditional-evidence.pdf"
    pdf = canvas.Canvas(str(path), pagesize=landscape(A4), pageCompression=1)
    pdf.setTitle(title)
    cover_page(
        pdf,
        title,
        "Bounded private-Dev owner connection, app return and official playback evidence",
        "This pack documents only capabilities demonstrated against the Dev reviewer slice. It does not represent broad Production approval.",
        "Submission gate: live private-upload, owner-Analytics, provider revocation and retained-data deletion evidence are not included yet. Keep those use cases out of the final form unless matching evidence is added.",
    )
    account = AUDIT / "owner-connect-proof-03-google-account-chooser.png"
    warning = AUDIT / "owner-connect-proof-03-youtube-scope.png"
    returned = AUDIT / "oppo-youtube-return-r10-cold-success-visible.png"
    catalogue = PUBLIC / "oppo-real-youtube-r4-active-catalogue.png"
    player = PUBLIC / "oppo-real-youtube-r4-player-cued.png"
    eligibility = AUDIT / "CHANNEL-FEATURE-ELIGIBILITY-VETONEWS-20260726.png"
    two_phone_page(
        pdf,
        title,
        2,
        account,
        "Founder-controlled Google/brand-account selection",
        warning,
        "Current Dev OAuth warning - verification still pending",
        "Physical OPPO evidence - 26 July 2026",
    )
    two_phone_page(
        pdf,
        title,
        3,
        returned,
        "Token-free browser return to the same MoolSocial surface",
        catalogue,
        "Eligible public YouTube catalogue in the bounded Dev client",
        "Physical OPPO evidence - 26 July 2026",
    )
    screenshot_page(
        pdf,
        title,
        4,
        player,
        "Official YouTube embedded player ready on the physical OPPO, with YouTube identity and Watch on YouTube visible. YouTube remains the host and streaming provider.",
        "Physical OPPO evidence - 26 July 2026",
    )
    screenshot_page(
        pdf,
        title,
        5,
        eligibility,
        "Founder-supplied YouTube Studio evidence shows Standard, Intermediate and Advanced channel features enabled for VetoNews. This is channel readiness, not API-audit or OAuth approval.",
        "YouTube Studio channel settings - founder-supplied evidence",
    )
    width, height = pdf._pagesize
    page_header(pdf, title, 6)
    pdf.setFillColor(PALE)
    pdf.rect(0, 0, width, height - 45, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.roundRect(40, 75, width - 80, height - 155, 14, fill=1, stroke=0)
    pdf.setFillColor(NAVY)
    pdf.setFont("Helvetica-Bold", 19)
    pdf.drawString(60, height - 100, "Truthful evidence boundary")
    y = height - 133
    items = [
        ("Verified now", "Selected public metadata discovery, official embedded playback, OAuth account selection, exact app return and VetoNews channel eligibility evidence."),
        ("Still pending", "One private resumable upload, owner-authorised Analytics result, Google/provider revocation, retained-data deletion and representative quota measurement."),
        ("Environment", f"Evidence targets Dev project {PROJECT_ID} ({PROJECT_NUMBER}). Production remains a separately authorised project and approval decision."),
        ("Data boundary", "MoolSocial does not download, proxy or offer offline YouTube audiovisual content. Playback remains within the official YouTube player."),
    ]
    for heading, body in items:
        pdf.setFillColor(ORANGE)
        pdf.circle(67, y + 3, 4, fill=1, stroke=0)
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawString(80, y, heading)
        y = draw_wrapped(pdf, body, 80, y - 18, width - 150, "Helvetica", 10, 14, MUTED) - 13
    page_footer(pdf, "MoolSocial YouTube API audit draft - evidence boundary")
    pdf.showPage()
    pdf.save()


def flow_box(pdf: canvas.Canvas, x: float, y: float, w: float, h: float, title: str, body: str, fill) -> None:
    pdf.setFillColor(fill)
    pdf.roundRect(x, y, w, h, 10, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawCentredString(x + w / 2, y + h - 18, title)
    draw_wrapped(pdf, body, x + 12, y + h - 36, w - 24, "Helvetica", 8, 10, INK)


def arrow(pdf: canvas.Canvas, x1: float, y1: float, x2: float, y2: float) -> None:
    pdf.setStrokeColor(ORANGE)
    pdf.setFillColor(ORANGE)
    pdf.setLineWidth(2)
    pdf.line(x1, y1, x2, y2)
    pdf.circle(x2, y2, 3, fill=1, stroke=0)


def build_architecture_pdf() -> None:
    title = "MoolSocial YouTube architecture and data flow"
    path = OUTPUT / "moolsocial-youtube-architecture.pdf"
    pdf = canvas.Canvas(str(path), pagesize=landscape(A4), pageCompression=1)
    pdf.setTitle(title)
    cover_page(
        pdf,
        title,
        "Bounded Dev reviewer architecture, OAuth custody and deletion flow",
        "A concise architecture reference for the official YouTube API Services audit form. No credential or secret is included.",
    )
    width, height = pdf._pagesize
    page_header(pdf, title, 2)
    pdf.setFillColor(PALE)
    pdf.rect(0, 0, width, height - 45, fill=1, stroke=0)
    pdf.setFillColor(NAVY)
    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawString(40, height - 88, "Request, playback and OAuth boundaries")
    boxes = [
        (38, 265, 130, 105, "MoolSocial app", "Native Flutter customer surfaces. Explicit customer actions start discovery, connection or upload.", colors.HexColor("#FFF0E0")),
        (204, 265, 137, 105, "Firebase boundary", "Firebase Auth and App Check protect privileged calls. Unauthorised calls fail closed.", colors.HexColor("#E7F0FF")),
        (377, 265, 145, 105, "Privileged functions", "Server-controlled endpoint allow-list, quota caps, validation and rollback controls.", colors.HexColor("#E8F7ED")),
        (558, 265, 126, 105, "Token vault", "Encrypted refresh-token custody. No refresh token is returned to the app.", colors.HexColor("#F4EBFF")),
        (720, 265, 85, 105, "YouTube APIs", "Data and Analytics calls use the minimum authorised scope.", colors.HexColor("#FFE8E8")),
    ]
    for box in boxes:
        flow_box(pdf, *box)
    for left, right in zip(boxes, boxes[1:]):
        arrow(pdf, left[0] + left[2], left[1] + left[3] / 2, right[0], right[1] + right[3] / 2)
    flow_box(
        pdf,
        203,
        100,
        215,
        92,
        "Official playback path",
        "Eligible item metadata is selected in MoolSocial. Audiovisual playback goes directly from the device to the official YouTube embedded player.",
        colors.HexColor("#FFF9DC"),
    )
    flow_box(
        pdf,
        472,
        100,
        215,
        92,
        "OAuth browser return",
        "System browser -> fixed HTTPS callback -> server exchanges code -> encrypted token custody -> token-free deep link returns to the same app screen.",
        colors.HexColor("#E8F7ED"),
    )
    arrow(pdf, 310, 265, 310, 192)
    arrow(pdf, 580, 265, 580, 192)
    page_footer(pdf, f"Dev project {PROJECT_ID} ({PROJECT_NUMBER})")
    pdf.showPage()

    page_header(pdf, title, 3)
    pdf.setFillColor(PALE)
    pdf.rect(0, 0, width, height - 45, fill=1, stroke=0)
    pdf.setFillColor(NAVY)
    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawString(40, height - 88, "Disconnect, revocation and retained-data deletion")
    flow_box(pdf, 65, 245, 170, 105, "1. Customer disconnects", "The customer starts disconnect from MoolSocial account settings or the public connected-services page.", colors.HexColor("#FFF0E0"))
    flow_box(pdf, 335, 245, 170, 105, "2. Provider revocation", "The privileged service calls the provider revocation path. Failure is surfaced and retried under bounded controls.", colors.HexColor("#FFE8E8"))
    flow_box(pdf, 605, 245, 170, 105, "3. Local deletion", "Stored provider tokens and retained provider-linked data are deleted within the stated policy period.", colors.HexColor("#E8F7ED"))
    arrow(pdf, 235, 297, 335, 297)
    arrow(pdf, 505, 297, 605, 297)
    pdf.setFillColor(WHITE)
    pdf.roundRect(65, 95, 710, 92, 12, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(86, 160, "Live-proof status at attachment preparation")
    draw_wrapped(
        pdf,
        "The public policy and connected-services surfaces are live. The complete provider-revocation and retained-data-deletion replay is still pending and must be added before these operations are claimed as reviewer-complete.",
        86,
        138,
        665,
        "Helvetica",
        10,
        14,
        MUTED,
    )
    page_footer(pdf, "https://moolsocial.com/disconnect and https://moolsocial.com/privacy")
    pdf.showPage()
    pdf.save()


def write_manifest() -> None:
    manifest = OUTPUT / "youtube-audit-attachment-manifest.txt"
    lines = [
        "MoolSocial YouTube API audit attachment manifest",
        f"Prepared: {CAPTURE_DATE.isoformat()}",
        f"Dev project: {PROJECT_ID} ({PROJECT_NUMBER})",
        "",
    ]
    for pdf_path in sorted(OUTPUT.glob("moolsocial-youtube-*.pdf")):
        lines.append(f"{pdf_path.name}\t{pdf_path.stat().st_size}\t{sha256(pdf_path)}")
    manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_all(web_only: bool = False) -> None:
    ensure_directories()
    build_homepage_pdf()
    build_policy_pdf(
        "moolsocial-youtube-privacy-policy-evidence.pdf",
        "MoolSocial privacy policy evidence",
        "Live privacy, service-integration, retention and customer-control disclosures",
        "https://moolsocial.com/privacy",
        TMP / "moolsocial-privacy-full.png",
        TMP / "moolsocial-privacy-addressbar.png",
        [0, 900, 1800, 2700, 3594],
        [
            "Live privacy-policy identity and effective-date area.",
            "Customer data and service-integration disclosures.",
            "Provider, Google and YouTube-related policy disclosures.",
            "Retention, security and customer-control disclosures.",
            "Public legal navigation and contact area.",
        ],
    )
    build_policy_pdf(
        "moolsocial-youtube-terms-evidence.pdf",
        "MoolSocial terms of use evidence",
        "Live customer terms associated with the MoolSocial API client",
        "https://moolsocial.com/terms",
        TMP / "moolsocial-terms-full.png",
        TMP / "moolsocial-terms-addressbar.png",
        [0, 800, 1600, 2291],
        [
            "Live Terms of Use identity and effective-date area.",
            "Customer responsibilities and service-use terms.",
            "Third-party service and platform terms.",
            "Public legal navigation and contact area.",
        ],
    )
    build_policy_pdf(
        "moolsocial-youtube-disconnect-evidence.pdf",
        "MoolSocial connected-services evidence",
        "Public disconnect, provider access removal and retained-data control surface",
        "https://moolsocial.com/disconnect",
        TMP / "moolsocial-disconnect-full.png",
        TMP / "moolsocial-disconnect-addressbar.png",
        [0, 845],
        [
            "Public connected-services and account-control instructions.",
            "Provider revocation, retained-data deletion and support guidance.",
        ],
    )
    if web_only:
        write_manifest()
        return
    build_conditional_evidence_pdf()
    build_architecture_pdf()
    write_manifest()


if __name__ == "__main__":
    import sys

    build_all(web_only="--web-only" in sys.argv[1:])
