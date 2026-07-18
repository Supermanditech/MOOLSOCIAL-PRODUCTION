import { eq } from "drizzle-orm";
import { getDb } from "../../../db";
import { waitlistLeads } from "../../../db/schema";

const allowedRoles = new Set(["member", "creator", "worker", "business"]);
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type WaitlistPayload = {
  name?: string;
  email?: string;
  city?: string;
  role?: string;
  website?: string;
  referredBy?: string;
  consent?: boolean;
};

function clean(value: unknown, maxLength: number) {
  return String(value ?? "")
    .trim()
    .replace(/\s+/g, " ")
    .slice(0, maxLength);
}

function newReferralCode() {
  return crypto.randomUUID().replaceAll("-", "").slice(0, 10).toUpperCase();
}

export async function POST(request: Request) {
  try {
    const payload = (await request.json()) as WaitlistPayload;
    const name = clean(payload.name, 80);
    const email = clean(payload.email, 160).toLowerCase();
    const city = clean(payload.city, 100);
    const role = clean(payload.role, 20);
    const referredBy = clean(payload.referredBy, 20).toUpperCase() || null;
    const honeypot = clean(payload.website, 160);

    if (honeypot) {
      return Response.json({
        ok: true,
        referralUrl: new URL("/", request.url).toString(),
        existing: false,
      });
    }

    if (name.length < 2) {
      return Response.json(
        { error: "Please enter your name." },
        { status: 400 },
      );
    }
    if (!emailPattern.test(email)) {
      return Response.json(
        { error: "Please enter a valid email address." },
        { status: 400 },
      );
    }
    if (city.length < 2) {
      return Response.json(
        { error: "Please enter your city." },
        { status: 400 },
      );
    }
    if (!allowedRoles.has(role)) {
      return Response.json(
        { error: "Please choose how you want to join." },
        { status: 400 },
      );
    }
    if (payload.consent !== true) {
      return Response.json(
        { error: "Please agree to receive early-access updates." },
        { status: 400 },
      );
    }

    const db = getDb();
    const [existing] = await db
      .select({
        id: waitlistLeads.id,
        referralCode: waitlistLeads.referralCode,
        referredBy: waitlistLeads.referredBy,
      })
      .from(waitlistLeads)
      .where(eq(waitlistLeads.email, email))
      .limit(1);

    let referralCode = existing?.referralCode;
    if (existing) {
      await db
        .update(waitlistLeads)
        .set({
          name,
          role,
          city,
          consent: true,
          referredBy: existing.referredBy ?? referredBy,
          updatedAt: new Date().toISOString(),
        })
        .where(eq(waitlistLeads.id, existing.id));
    } else {
      referralCode = newReferralCode();
      await db.insert(waitlistLeads).values({
        name,
        email,
        role,
        city,
        referralCode,
        referredBy,
        consent: true,
      });
    }

    const referralUrl = new URL("/", request.url);
    referralUrl.searchParams.set("ref", referralCode!);

    return Response.json(
      {
        ok: true,
        referralUrl: referralUrl.toString(),
        existing: Boolean(existing),
      },
      { status: existing ? 200 : 201 },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected error";
    const isMissingTable =
      message.includes("no such table") || message.includes("waitlist_leads");

    return Response.json(
      {
        error: isMissingTable
          ? "Early access is being prepared. Please try again shortly."
          : "We could not save your request. Please try again.",
      },
      { status: 500 },
    );
  }
}
