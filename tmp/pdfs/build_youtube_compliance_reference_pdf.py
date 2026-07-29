from __future__ import annotations

import hashlib
from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(r"C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION")
OUTPUT = (
    ROOT
    / "output"
    / "pdf"
    / "MoolSocial-YouTube-API-Compliance-Reference-r20.pdf"
)
TMP = ROOT / "tmp" / "pdfs" / "youtube-compliance-reference-r20-assets"
SCREENSHOTS = (
    ROOT
    / "artifacts"
    / "quality"
    / "youtube-compliance-follow-up-20260729-01"
    / "founder-approval-r20"
)
OAUTH_EVIDENCE = (
    ROOT
    / "artifacts"
    / "quality"
    / "youtube-api-submission-readiness-20260725-01"
)
VIDEO = (
    ROOT
    / "output"
    / "video"
    / "MoolSocial-YouTube-API-Compliance-Walkthrough-r20.mp4"
)

NAVY = colors.HexColor("#090083")
ORANGE = colors.HexColor("#FF982F")
GREEN = colors.HexColor("#159447")
INK = colors.HexColor("#14162A")
MUTED = colors.HexColor("#62677D")
PALE = colors.HexColor("#F3F4FB")
PALE_GREEN = colors.HexColor("#EAF7ED")
PALE_ORANGE = colors.HexColor("#FFF0DD")
LINE = colors.HexColor("#D9DCEB")
WHITE = colors.white

APK_NAME = "moolsocial-youtube-compliance-review-private-dev-r20.apk"
APK_SHA256 = "641957A49AFC9F6A8D742CF71A4F22E65832F2443701BDB89F7C06BEE6EAC8FC"
CHANNEL_ID = "UC7rn0BIzhULpyw1NYXh-mWQ"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def prepared_image(source: Path, name: str, max_width: int = 1100) -> Path:
    if not source.exists():
        raise FileNotFoundError(source)
    TMP.mkdir(parents=True, exist_ok=True)
    target = TMP / f"{name}.jpg"
    with PILImage.open(source) as image:
        image = image.convert("RGB")
        if image.width > max_width:
            height = round(image.height * max_width / image.width)
            image = image.resize((max_width, height), PILImage.Resampling.LANCZOS)
        image.save(target, "JPEG", quality=91, optimize=True, progressive=True)
    return target


def scaled_image(path: Path, max_width: float, max_height: float) -> Image:
    with PILImage.open(path) as image:
        width, height = image.size
    ratio = min(max_width / width, max_height / height)
    return Image(str(path), width=width * ratio, height=height * ratio)


class ComplianceDoc(BaseDocTemplate):
    def __init__(self, filename: str):
        super().__init__(
            filename,
            pagesize=A4,
            leftMargin=16 * mm,
            rightMargin=16 * mm,
            topMargin=17 * mm,
            bottomMargin=17 * mm,
            title="MoolSocial YouTube API Client - Step-by-Step Visual and Endpoint Reference",
            author="SUPERMANDI TECH PRIVATE LIMITED",
            subject="YouTube API Services compliance review supporting reference",
        )
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="main",
        )
        self.addPageTemplates(
            PageTemplate(id="compliance", frames=[frame], onPage=self._decorate)
        )

    def _decorate(self, canvas, doc):
        canvas.saveState()
        canvas.setFillColor(NAVY)
        canvas.rect(0, A4[1] - 8 * mm, A4[0], 8 * mm, fill=1, stroke=0)
        canvas.setFillColor(ORANGE)
        canvas.rect(0, A4[1] - 8 * mm, A4[0] / 3, 1.1 * mm, fill=1, stroke=0)
        canvas.setFillColor(WHITE)
        canvas.rect(A4[0] / 3, A4[1] - 8 * mm, A4[0] / 3, 1.1 * mm, fill=1, stroke=0)
        canvas.setFillColor(GREEN)
        canvas.rect(
            2 * A4[0] / 3,
            A4[1] - 8 * mm,
            A4[0] / 3,
            1.1 * mm,
            fill=1,
            stroke=0,
        )
        canvas.setStrokeColor(LINE)
        canvas.line(16 * mm, 12 * mm, A4[0] - 16 * mm, 12 * mm)
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(
            16 * mm,
            7.5 * mm,
            "MoolSocial YouTube API Services compliance review reference",
        )
        canvas.drawRightString(
            A4[0] - 16 * mm,
            7.5 * mm,
            f"Page {doc.page}",
        )
        canvas.restoreState()


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="CoverTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=25,
        leading=29,
        textColor=NAVY,
        alignment=TA_LEFT,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="CoverSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=11.5,
        leading=16,
        textColor=MUTED,
        spaceAfter=10,
    )
)
styles.add(
    ParagraphStyle(
        name="SectionTitle",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=19,
        leading=23,
        textColor=NAVY,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="StepLabel",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=8.5,
        leading=11,
        textColor=GREEN,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="Body",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9.3,
        leading=13.2,
        textColor=INK,
        spaceAfter=6,
    )
)
styles.add(
    ParagraphStyle(
        name="Small",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=7.6,
        leading=10.3,
        textColor=MUTED,
    )
)
styles.add(
    ParagraphStyle(
        name="TableText",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=7.5,
        leading=10,
        textColor=INK,
    )
)
styles.add(
    ParagraphStyle(
        name="TableHead",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=10,
        textColor=WHITE,
        alignment=TA_LEFT,
    )
)
styles.add(
    ParagraphStyle(
        name="CenteredSmall",
        parent=styles["Small"],
        alignment=TA_CENTER,
    )
)


def p(text: str, style: str = "Body") -> Paragraph:
    return Paragraph(text, styles[style])


def bullet(text: str) -> Paragraph:
    return Paragraph(f"&#8226;&nbsp; {text}", styles["Body"])


def fact_box(rows, widths=None):
    data = [[p(str(key), "TableText"), p(str(value), "TableText")] for key, value in rows]
    table = Table(data, colWidths=widths or [43 * mm, 124 * mm], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PALE),
                ("BOX", (0, 0), (-1, -1), 0.7, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.35, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("TEXTCOLOR", (0, 0), (0, -1), NAVY),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def banner(text: str, fill=PALE_GREEN, stroke=GREEN):
    table = Table([[p(text, "Body")]], colWidths=[167 * mm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), fill),
                ("BOX", (0, 0), (-1, -1), 1, stroke),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return table


def image_pair(left: Path, right: Path, captions: tuple[str, str], height=144 * mm):
    table = Table(
        [
            [
                scaled_image(left, 77 * mm, height),
                scaled_image(right, 77 * mm, height),
            ],
            [
                p(captions[0], "CenteredSmall"),
                p(captions[1], "CenteredSmall"),
            ],
        ],
        colWidths=[82.5 * mm, 82.5 * mm],
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ALIGN", (0, 0), (-1, 0), "CENTER"),
                ("LEFTPADDING", (0, 0), (-1, -1), 2),
                ("RIGHTPADDING", (0, 0), (-1, -1), 2),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def matrix_table(rows):
    data = [
        [
            p("Visible journey", "TableHead"),
            p("Operation or provider surface", "TableHead"),
            p("Current status", "TableHead"),
        ]
    ]
    for row in rows:
        data.append([p(cell, "TableText") for cell in row])
    table = Table(data, colWidths=[54 * mm, 62 * mm, 49 * mm], repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("BOX", (0, 0), (-1, -1), 0.7, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.35, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    for row_index in range(2, len(data), 2):
        table.setStyle(
            TableStyle(
                [("BACKGROUND", (0, row_index), (-1, row_index), PALE)]
            )
        )
    return table


def build() -> None:
    if not VIDEO.exists():
        raise FileNotFoundError(VIDEO)
    video_hash = sha256(VIDEO)
    video_size_mb = VIDEO.stat().st_size / (1024 * 1024)

    assets = {
        "catalogue": prepared_image(
            SCREENSHOTS / "01-video-discovery.png",
            "01-video-discovery",
        ),
        "cued": prepared_image(
            SCREENSHOTS / "02-video-cued.png",
            "02-video-cued",
        ),
        "playing": prepared_image(
            SCREENSHOTS / "03-video-playing.png",
            "03-video-playing",
        ),
        "short_cued": prepared_image(
            SCREENSHOTS / "04-shorts-cued.png",
            "04-shorts-cued",
        ),
        "short_playing": prepared_image(
            SCREENSHOTS / "05-shorts-playing.png",
            "05-shorts-playing",
        ),
        "short_next": prepared_image(
            SCREENSHOTS / "06-shorts-next-cued.png",
            "06-shorts-next-cued",
        ),
        "details": prepared_image(
            SCREENSHOTS / "08-short-details.png",
            "08-short-details",
        ),
        "oauth": prepared_image(
            OAUTH_EVIDENCE / "owner-connect-proof-03-youtube-consent-02.png",
            "veto-news-oauth",
        ),
    }

    story = []
    story.append(Spacer(1, 7 * mm))
    story.append(p("MOOLSOCIAL / YOUTUBE API SERVICES", "StepLabel"))
    story.append(
        p(
            "Step-by-Step Visual and Endpoint Reference",
            "CoverTitle",
        )
    )
    story.append(
        p(
            "Supporting attachment for YouTube's request for a complete visual "
            "reference of how the API Client uses YouTube API Services and the "
            "visible end results.",
            "CoverSubtitle",
        )
    )
    story.append(
        banner(
            "<b>Reviewer package:</b> one 90.20-second MP4 walkthrough recorded from "
            "a physical OPPO device, plus this endpoint and policy-boundary reference."
        )
    )
    story.append(Spacer(1, 6 * mm))
    story.append(
        fact_box(
            [
                ("Company", "SUPERMANDI TECH PRIVATE LIMITED"),
                ("API Client", "MoolSocial"),
                ("Preferred contact", "Dharmendra Choudhary - hello@moolsocial.com"),
                ("Google Cloud project", "moolsocial-dev-503018"),
                ("Android package", "com.moolsocial.app"),
                ("Review build", "youtube-compliance-followup-20260729-20"),
                ("Physical device", "OPPO CPH2375, Android 13"),
                ("Evidence time", "29 July 2026, 18:15-18:16 IST"),
                ("Review APK", APK_NAME),
                ("APK SHA-256", APK_SHA256),
                ("MP4 SHA-256", video_hash),
            ]
        )
    )
    story.append(Spacer(1, 6 * mm))
    story.append(p("Current demonstrated boundary", "SectionTitle"))
    for item in [
        "Eligible public YouTube video discovery and returned public metadata.",
        "Official YouTube embedded playback initiated by a deliberate user tap.",
        "A bounded, YouTube-only Shorts lane with distinct eligible public items.",
        "A separately supervised read-only VetoNews channel connection.",
    ]:
        story.append(bullet(item))
    story.append(
        banner(
            "<b>Scope correction:</b> the broad method selections in the original "
            "quota form included a staged roadmap. Uploads, viewer mutations, "
            "Analytics/Reporting and Live management are not active in this build "
            "and are not represented as working.",
            fill=PALE_ORANGE,
            stroke=ORANGE,
        )
    )

    story.append(PageBreak())
    story.append(p("STEP 1", "StepLabel"))
    story.append(p("Discover eligible public videos", "SectionTitle"))
    story.append(
        p(
            "The recording starts on the source-attributed MoolSocial Videos "
            "library. The low-quota starting source is "
            "<b>videos.list(chart=mostPopular, regionCode=IN)</b>. "
            "<b>channels.list</b> enriches only the channel IDs returned with the "
            "selected items.",
        )
    )
    story.append(
        KeepTogether(
            [
                scaled_image(assets["catalogue"], 108 * mm, 166 * mm),
                p(
                    "Physical-device result: real titles, thumbnails, channels, "
                    "public metadata and visible YouTube source attribution.",
                    "CenteredSmall",
                ),
            ]
        )
    )
    story.append(Spacer(1, 4 * mm))
    story.append(
        banner(
            "<b>End result:</b> genuine public YouTube items appear in a clearly "
            "MoolSocial-owned catalogue. MoolSocial does not present this as YouTube "
            "Home or as YouTube's personalized recommendation feed."
        )
    )

    story.append(PageBreak())
    story.append(p("STEP 2", "StepLabel"))
    story.append(p("Play one selected video", "SectionTitle"))
    story.append(
        p(
            "Selecting an eligible item mounts one official YouTube embedded player "
            "inside the OS-provided Android WebView. Playback begins only after the "
            "user taps the provider-owned play surface. YouTube branding, controls, "
            "advertising and links remain visible and unobstructed.",
        )
    )
    story.append(
        image_pair(
            assets["cued"],
            assets["playing"],
            (
                "Official player cued before the user's deliberate play tap.",
                "A genuine later frame in the same official YouTube player.",
            ),
            height=149 * mm,
        )
    )
    story.append(
        banner(
            "<b>End result:</b> YouTube-hosted audiovisual content plays through the "
            "official player. MoolSocial does not download, store, transcode or proxy "
            "the audiovisual content and does not place controls or commerce over it."
        )
    )

    story.append(PageBreak())
    story.append(p("STEP 3", "StepLabel"))
    story.append(p("Open the bounded Shorts lane", "SectionTitle"))
    story.append(
        p(
            "The Shorts lane uses bounded, quota-sensitive <b>search.list</b> "
            "candidate discovery followed by <b>videos.list</b> metadata hydration. "
            "An item is admitted only when it is public, processed, embeddable and "
            "available in India; creator-declared metadata and the returned duration "
            "support the lane classification. Duration alone is not treated as proof."
        )
    )
    story.append(
        image_pair(
            assets["short_cued"],
            assets["short_playing"],
            (
                "First selected public Short, cued before playback.",
                "The same Short playing in the official YouTube player.",
            ),
            height=146 * mm,
        )
    )
    story.append(
        banner(
            "<b>End result:</b> an eligible public Short plays in the official "
            "YouTube player. The lane is a bounded MoolSocial selection and is not "
            "described as access to YouTube's native Shorts recommendation feed."
        )
    )

    story.append(PageBreak())
    story.append(p("STEP 3, CONTINUED", "StepLabel"))
    story.append(p("Change item and inspect public details", "SectionTitle"))
    story.append(
        p(
            "A vertical user gesture releases the previous selection and moves to a "
            "different eligible public Short. The details surface shows only returned "
            "public metadata and explicitly states that playback uses the official "
            "YouTube player."
        )
    )
    story.append(
        image_pair(
            assets["short_next"],
            assets["details"],
            (
                "A distinct next Short remains cued until the user taps play.",
                "Public title, channel, views and likes with provider disclosure.",
            ),
            height=148 * mm,
        )
    )
    story.append(
        banner(
            "<b>End result:</b> the reviewer can verify the distinct item, its "
            "YouTube source identity and the separation between the official player "
            "and MoolSocial-owned Save, Discuss, Share and Details actions."
        )
    )

    story.append(PageBreak())
    story.append(p("SEPARATE DATED EVIDENCE", "StepLabel"))
    story.append(p("Read-only VetoNews channel connection", "SectionTitle"))
    story.append(
        p(
            "The owner-channel authorization is a separate supervised private-Dev "
            "flow, dated 26 July 2026, and is not presented as part of the continuous "
            "public-playback recording. MoolSocial sign-in and YouTube authorization "
            "remain separate. The OAuth flow uses the system browser and the narrow "
            "<b>youtube.readonly</b> scope."
        )
    )
    story.append(
        KeepTogether(
            [
                scaled_image(assets["oauth"], 104 * mm, 151 * mm),
                p(
                    "Standard Google system-browser step showing the founder-controlled "
                    "VetoNews identity used for the supervised connection.",
                    "CenteredSmall",
                ),
            ]
        )
    )
    story.append(Spacer(1, 4 * mm))
    story.append(
        fact_box(
            [
                ("Authorized identity", "vetonewslive@gmail.com"),
                ("Selected channel", "VetoNews"),
                ("Channel ID", CHANNEL_ID),
                ("Scope", "youtube.readonly"),
                (
                    "Result",
                    "Backend exact-channel reconciliation completed; refresh "
                    "credentials remain server-side.",
                ),
            ]
        )
    )
    story.append(Spacer(1, 4 * mm))
    story.append(
        banner(
            "<b>Return boundary:</b> the app return route contains no OAuth code, "
            "state, access token, refresh token, email address, channel ID or internal "
            "MoolSocial user ID. Backend connection status remains authoritative."
        )
    )

    story.append(PageBreak())
    story.append(p("API-TO-SCREEN MATRIX", "StepLabel"))
    story.append(p("Exact current API Client boundary", "SectionTitle"))
    story.append(
        matrix_table(
            [
                (
                    "Videos starting library",
                    "videos.list(chart=mostPopular, regionCode=IN)",
                    "Active and shown in MP4",
                ),
                (
                    "Public details and eligibility",
                    "videos.list returned metadata",
                    "Active and shown in MP4",
                ),
                (
                    "Channel enrichment",
                    "channels.list for returned channel IDs",
                    "Active and visible",
                ),
                (
                    "Bounded Shorts candidates",
                    "search.list, followed by videos.list hydration",
                    "Active and shown in MP4",
                ),
                (
                    "Video and Shorts playback",
                    "Official YouTube embedded player",
                    "Active on physical OPPO",
                ),
                (
                    "Owner channel connection",
                    "OAuth 2.0 system browser, youtube.readonly, exact-channel reconciliation",
                    "Separate dated proof",
                ),
                (
                    "Browser-to-app return",
                    "OAuth callback plus token-free MoolSocial deep link",
                    "Device-proven separately",
                ),
                (
                    "Uploads and viewer mutations",
                    "videos.insert; Like/Comment/Subscribe or playlist mutations",
                    "Not active; not claimed",
                ),
                (
                    "Analytics, Reporting and Live",
                    "Owner-authorized analytics/reporting/live resources",
                    "Not active; not claimed",
                ),
            ]
        )
    )
    story.append(Spacer(1, 7 * mm))
    story.append(p("How the original form is reconciled", "SectionTitle"))
    story.append(
        p(
            "The original method inventory described a staged production roadmap as "
            "well as the implemented slice. The email asks YouTube to assess this "
            "demonstrated current boundary and to advise whether the form should be "
            "replaced with a narrower current-method inventory before the quota "
            "decision. Future capabilities will be submitted only after they are "
            "implemented, consented, quota-modelled and reviewable."
        )
    )
    story.append(
        banner(
            "<b>No overclaim:</b> this package does not claim public uploads, "
            "YouTube viewer mutations, owner analytics, reporting, live management, "
            "Production approval, or an unlimited/global YouTube catalogue.",
            fill=PALE_ORANGE,
            stroke=ORANGE,
        )
    )

    story.append(PageBreak())
    story.append(p("POLICY AND PRODUCT BOUNDARIES", "StepLabel"))
    story.append(p("Playback integrity and independent value", "SectionTitle"))
    story.append(
        fact_box(
            [
                (
                    "Player integrity",
                    "No MoolSocial overlay, frame, commerce control or gesture "
                    "interceptor obscures any official YouTube player pixel or control.",
                ),
                (
                    "User choice",
                    "Playback is initiated by a deliberate user tap. MoolSocial does "
                    "not reward, coerce or compensate a user for watching.",
                ),
                (
                    "Provider content",
                    "MoolSocial does not download YouTube video or audio, offer "
                    "background play, suppress advertising, or replace provider links.",
                ),
                (
                    "Commerce separation",
                    "MoolSocial advertising or commerce does not appear inside or over "
                    "the YouTube player. Any separate native content must provide "
                    "independent value or a real disclosed campaign relationship.",
                ),
                (
                    "Independent value",
                    "MoolSocial is a broader AI-enabled social-commerce application. "
                    "YouTube surfaces are source-attributed provider experiences within "
                    "the larger customer journey, not a clone of YouTube.",
                ),
                (
                    "Data clarity",
                    "YouTube-returned public metadata is labelled by source and is not "
                    "merged into an invented cross-platform metric or suitability score.",
                ),
            ],
            widths=[42 * mm, 125 * mm],
        )
    )
    story.append(Spacer(1, 6 * mm))
    story.append(p("Customer controls and legal surfaces", "SectionTitle"))
    for item in [
        "Homepage: https://moolsocial.com/",
        "Privacy: https://moolsocial.com/privacy",
        "Terms: https://moolsocial.com/terms",
        "Support: https://moolsocial.com/support",
        "Disconnect: https://moolsocial.com/disconnect",
        "Account deletion: https://moolsocial.com/delete-account",
        "YouTube Terms of Service: https://www.youtube.com/t/terms",
        "Google Privacy Policy: https://policies.google.com/privacy",
    ]:
        story.append(bullet(item))

    story.append(PageBreak())
    story.append(p("ATTACHMENTS AND VERIFICATION", "StepLabel"))
    story.append(p("Files supplied with the email", "SectionTitle"))
    story.append(
        fact_box(
            [
                (
                    "Screencast",
                    f"{VIDEO.name} - 90.20 seconds - {video_size_mb:.2f} MiB",
                ),
                ("MP4 SHA-256", video_hash),
                ("Reference PDF", OUTPUT.name),
                ("Review APK", APK_NAME),
                ("APK SHA-256", APK_SHA256),
                ("Preferred contact", "hello@moolsocial.com; no additional CC requested"),
            ]
        )
    )
    story.append(Spacer(1, 7 * mm))
    story.append(p("Reviewer sequence", "SectionTitle"))
    for item in [
        "Open the MP4 and verify the project, package, build and physical device on the title card.",
        "Observe API-backed public discovery and YouTube source attribution.",
        "Observe user-initiated official video playback with provider controls unobstructed.",
        "Observe the bounded Shorts lane, a distinct next item and returned public details.",
        "Use this PDF for the exact endpoint mapping, separate OAuth proof and out-of-scope boundary.",
    ]:
        story.append(bullet(item))
    story.append(Spacer(1, 6 * mm))
    story.append(p("Official YouTube references checked 29 July 2026", "SectionTitle"))
    for item in [
        "Developer Policies: https://developers.google.com/youtube/terms/developer-policies",
        "Policy compliance guide: https://developers.google.com/youtube/terms/developer-policies-guide",
        "Required Minimum Functionality: https://developers.google.com/youtube/terms/required-minimum-functionality",
        "Branding Guidelines: https://developers.google.com/youtube/terms/branding-guidelines",
        "Terms of Service: https://developers.google.com/youtube/terms/api-services-terms-of-service",
    ]:
        story.append(bullet(item))
    story.append(Spacer(1, 6 * mm))
    story.append(
        banner(
            "<b>Requested review:</b> please assess the current demonstrated API "
            "Client boundary for compliance and the applicable quota decision. If a "
            "corrected narrower method inventory is required, MoolSocial will provide "
            "it before later capabilities are represented as active."
        )
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = ComplianceDoc(str(OUTPUT))
    doc.build(story)
    print(f"PDF={OUTPUT}")
    print(f"BYTES={OUTPUT.stat().st_size}")
    print(f"SHA256={sha256(OUTPUT)}")


if __name__ == "__main__":
    build()
