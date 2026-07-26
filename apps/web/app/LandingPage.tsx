"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";

type RoleId = "member" | "creator" | "worker" | "business";

type Role = {
  id: RoleId;
  number: string;
  name: string;
  shortName: string;
  promise: string;
  description: string;
  action: string;
};

const roles: Role[] = [
  {
    id: "member",
    number: "01",
    name: "People & families",
    shortName: "Use MoolSocial",
    promise: "Find, buy, book and get things done locally.",
    description:
      "Discover useful products, trusted services and everyday opportunities from one action-led app.",
    action: "Join as a user",
  },
  {
    id: "creator",
    number: "02",
    name: "Creators",
    shortName: "Create & earn",
    promise: "Turn trusted influence into measurable outcomes.",
    description:
      "Connect your audience, promote verified offers and earn through transparent campaigns and results.",
    action: "Join as a creator",
  },
  {
    id: "worker",
    number: "03",
    name: "Workers & job seekers",
    shortName: "Find verified work",
    promise: "Access work with clear tasks, proof and payout rules.",
    description:
      "Build a trusted work record through local jobs, quick-commerce delivery, sales, service and outcome-based assignments.",
    action: "Join for work",
  },
  {
    id: "business",
    number: "04",
    name: "Businesses",
    shortName: "Grow my business",
    promise: "Reach customers, creators and local talent from one place.",
    description:
      "Grow retail, wholesale, services and customer relationships through useful products, demand and accountable execution.",
    action: "Join as a business",
  },
];

const productViewSets = [
  [
    {
      src: "/app-preview-social-video.webp",
      alt: "MoolSocial Social with For You, Shorts, Videos and Live",
      height: 1820,
    },
    {
      src: "/app-preview-universal-actions.webp",
      alt: "MoolSocial home with Social, Shorts, Videos, Create, Earn, Buy, Ride, Pay and Work",
      height: 1821,
    },
    {
      src: "/app-preview-for-you.webp",
      alt: "MoolSocial For You for discovery, shopping, booking and local activity",
      height: 1821,
    },
  ],
  [
    {
      src: "/app-preview-shop-deliver.webp",
      alt: "MoolSocial shopping, quick commerce and delivery",
      height: 1821,
    },
    {
      src: "/app-preview-create-earn.webp",
      alt: "MoolSocial creator and freelancer workspace",
      height: 1821,
    },
    {
      src: "/app-preview-work-grow.webp",
      alt: "MoolSocial work opportunities and business operations",
      height: 1821,
    },
  ],
] as const;

type SignupResult = {
  referralUrl: string;
  existing: boolean;
};

const launchTarget = new Date("2026-10-24T00:00:00+05:30").getTime();
const monthMs = 30 * 24 * 60 * 60 * 1000;
const dayMs = 24 * 60 * 60 * 1000;
const hourMs = 60 * 60 * 1000;
const minuteMs = 60 * 1000;

function getLaunchCountdown(now: number | null) {
  if (now === null) {
    return {
      months: "--",
      days: "--",
      hours: "--",
      minutes: "--",
      seconds: "--",
    };
  }

  let remaining = Math.max(0, launchTarget - now);
  const months = Math.floor(remaining / monthMs);
  remaining -= months * monthMs;
  const days = Math.floor(remaining / dayMs);
  remaining -= days * dayMs;
  const hours = Math.floor(remaining / hourMs);
  remaining -= hours * hourMs;
  const minutes = Math.floor(remaining / minuteMs);
  remaining -= minutes * minuteMs;
  const seconds = Math.floor(remaining / 1000);

  return {
    months: String(months).padStart(2, "0"),
    days: String(days).padStart(2, "0"),
    hours: String(hours).padStart(2, "0"),
    minutes: String(minutes).padStart(2, "0"),
    seconds: String(seconds).padStart(2, "0"),
  };
}

export function LandingPage() {
  const [selectedRole, setSelectedRole] = useState<RoleId>("member");
  const [status, setStatus] = useState<
    "idle" | "submitting" | "success" | "error"
  >("idle");
  const [message, setMessage] = useState("");
  const [result, setResult] = useState<SignupResult | null>(null);
  const [countdownNow, setCountdownNow] = useState<number | null>(null);
  const activeRole = useMemo(
    () => roles.find((role) => role.id === selectedRole) ?? roles[0],
    [selectedRole],
  );
  const launchCountdown = useMemo(
    () => getLaunchCountdown(countdownNow),
    [countdownNow],
  );

  useEffect(() => {
    const update = () => setCountdownNow(Date.now());
    update();
    const timer = window.setInterval(update, 1000);
    return () => window.clearInterval(timer);
  }, []);

  function selectRole(role: RoleId) {
    setSelectedRole(role);
    document
      .getElementById("early-access")
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  async function submitWaitlist(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");
    setResult(null);

    const form = new FormData(event.currentTarget);
    const payload = {
      name: String(form.get("name") ?? ""),
      email: String(form.get("email") ?? ""),
      city: String(form.get("city") ?? ""),
      role: selectedRole,
      website: String(form.get("website") ?? ""),
      referredBy: new URLSearchParams(window.location.search).get("ref") ?? "",
      consent: form.get("consent") === "on",
    };

    try {
      const response = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = (await response.json()) as {
        error?: string;
        referralUrl?: string;
        existing?: boolean;
      };

      if (!response.ok || !data.referralUrl) {
        throw new Error(data.error ?? "We could not save your request.");
      }

      setResult({
        referralUrl: data.referralUrl,
        existing: Boolean(data.existing),
      });
      setStatus("success");
      setMessage(
        data.existing
          ? "You are already on the early-access list. Your details are updated."
          : "You are on the early-access list.",
      );
      event.currentTarget.reset();
    } catch (error) {
      setStatus("error");
      setMessage(
        error instanceof Error
          ? error.message
          : "Something went wrong. Please try again.",
      );
    }
  }

  async function shareInvite() {
    if (!result) return;
    const shareData = {
      title: "Join MoolSocial early access",
      text: "Join me on MoolSocial — one app to discover, create, work and grow.",
      url: result.referralUrl,
    };

    if (navigator.share) {
      await navigator.share(shareData).catch(() => undefined);
      return;
    }

    await navigator.clipboard.writeText(result.referralUrl);
    setMessage("Invite link copied. Share it with people you want to bring in.");
  }

  return (
    <main>
      <section className="hero" id="top">
        <div className="hero-grid" aria-hidden="true" />
        <div className="hero-orb hero-orb-saffron" aria-hidden="true" />
        <div className="hero-orb hero-orb-green" aria-hidden="true" />

        <nav className="nav shell" aria-label="Primary navigation">
          <a className="brand-lockup" href="#top" aria-label="MoolSocial home">
            <span className="brand-wordmark">MoolSocial</span>
            <span className="brand-line" aria-hidden="true" />
            <span className="brand-tagline">India Ka Social Commerce App</span>
          </a>
          <div className="nav-links">
            <a href="#audiences">Our story</a>
            <a href="#experience">Experience</a>
            <a href="#early-access">Join us</a>
            <a className="nav-action" href="mailto:hello@moolsocial.com?subject=MoolSocial%20contact">Contact</a>
          </div>
        </nav>

        <div className="hero-content shell">
          <div className="hero-copy">
            <p className="eyebrow">Designed across platforms</p>
            <h1>MoolSocial moves with you.</h1>
            <p className="hero-intro">
              MoolSocial is building a trusted AI-enabled ecosystem for the
              digital services, opportunities and relationships that shape
              everyday life in India.
            </p>
            <div className="launch-countdown">
              <div
                className="countdown-grid"
                aria-label="Time remaining until the MoolSocial launch"
              >
                <span><strong>{launchCountdown.months}</strong><small>Months</small></span>
                <span><strong>{launchCountdown.days}</strong><small>Days</small></span>
                <span><strong>{launchCountdown.hours}</strong><small>Hours</small></span>
                <span><strong>{launchCountdown.minutes}</strong><small>Minutes</small></span>
                <span><strong>{launchCountdown.seconds}</strong><small>Seconds</small></span>
              </div>
              <p>
                Launching across India
                <time dateTime="2026-10-24">24 October 2026</time>
              </p>
            </div>
            <div className="hero-actions">
              <a className="button button-primary" href="#early-access">
                Reserve my early access
              </a>
              <a className="button button-secondary" href="#audiences">
                See what is coming
              </a>
            </div>
            <div className="trust-row" aria-label="MoolSocial principles">
              <span>Useful actions</span>
              <span>Verified opportunities</span>
              <span>Clear outcomes</span>
            </div>
          </div>

          <a
            className="showcase-stage hero-showcase"
            href="mailto:hello@moolsocial.com?subject=Tell%20me%20more%20about%20MoolSocial"
            aria-label="Email MoolSocial about the connected product experience"
          >
            <span className="showcase-halo showcase-halo-one" aria-hidden="true" />
            <span className="showcase-halo showcase-halo-two" aria-hidden="true" />
            <span className="showcase-orbit" aria-hidden="true" />
            <span className="showcase-ribbon" aria-hidden="true" />
            {productViewSets.map((set, setIndex) => (
              <div
                className={`showcase-set showcase-set-${setIndex === 0 ? "one" : "two"}`}
                key={setIndex}
              >
                {set.map((view, viewIndex) => (
                  <figure
                    className={`showcase-phone-card ${
                      viewIndex === 1 ? "phone-platform-ios" : "phone-platform-android"
                    } showcase-phone-${
                      viewIndex === 0 ? "left" : viewIndex === 1 ? "center" : "right"
                    }`}
                    key={view.src}
                  >
                    <div className="showcase-phone">
                      <img
                        alt={view.alt}
                        height={view.height}
                        loading="eager"
                        src={view.src}
                        width="864"
                      />
                      <span className="motion-tap" aria-hidden="true" />
                    </div>
                  </figure>
                ))}
              </div>
            ))}
          </a>
        </div>
      </section>

      <section className="signal-strip" aria-label="MoolSocial value">
        <div className="shell signal-content">
          <p>Built for people who want to act—not just scroll.</p>
          <span>
            Buy • Create • Work • Sell • Serve • Grow
          </span>
        </div>
      </section>

      <section className="audiences shell" id="audiences">
        <header className="section-heading">
          <p className="eyebrow dark">Choose what MoolSocial should do for you</p>
          <h2>Every user type. One connected economy.</h2>
          <p>
            Tell us why you are joining so your launch experience starts with
            the right products, work and opportunities.
          </p>
        </header>

        <div className="role-grid">
          {roles.map((role) => (
            <article className="role-card" key={role.id}>
              <div className="role-topline">
                <span>{role.number}</span>
                <p>{role.name}</p>
              </div>
              <h3>{role.promise}</h3>
              <p>{role.description}</p>
              <button type="button" onClick={() => selectRole(role.id)}>
                {role.action}
                <span aria-hidden="true">→</span>
              </button>
            </article>
          ))}
        </div>
      </section>

      <section className="concept-section" id="experience">
        <div className="shell showcase-layout">
          <header className="section-heading">
            <p className="eyebrow dark">One connected ecosystem</p>
            <h2>One connected experience, built around real life.</h2>
            <p>
              Move naturally from discovery to meaningful action through one
              consistent MoolSocial experience.
            </p>
          </header>
          <div className="network-card" aria-label="MoolSocial network">
            <p className="network-label">Your MoolSocial network</p>
            <div className="network-center">
              <span className="network-brand">Mool</span>
              <span>One trusted starting point</span>
            </div>
            <div className="network-paths">
              {roles.map((role) => (
                <button
                  className="network-path"
                  key={role.id}
                  onClick={() => selectRole(role.id)}
                  type="button"
                >
                  <span>{role.number}</span>
                  <strong>{role.shortName}</strong>
                </button>
              ))}
            </div>
            <p className="network-foot">Live. Earn. Grow.</p>
          </div>
        </div>
      </section>

      <section className="outcome-section">
        <div className="shell outcome-grid">
          <div>
            <p className="eyebrow light">Why join before launch?</p>
            <h2>Your early signal helps shape your MoolSocial.</h2>
          </div>
          <div className="outcome-list">
            <div>
              <span>01</span>
              <p>
                Choose the role and city that matter to you, so we launch the
                right local experiences first.
              </p>
            </div>
            <div>
              <span>02</span>
              <p>
                Receive launch access, product updates and invitations relevant
                to your selected purpose.
              </p>
            </div>
            <div>
              <span>03</span>
              <p>
                Invite your network with a personal link and help bring useful
                demand, talent and opportunity together.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="growth-section shell">
        <div className="opportunity-card">
          <p className="eyebrow light">Opportunities across India</p>
          <h2>Help build MoolSocial in your city.</h2>
          <p>
            Applications and partnership enquiries are open for 100+ upcoming
            roles, freelancers, content creators, businesses, city operations
            and delivery partners across quick commerce, retail and wholesale
            in India.
          </p>
          <a
            className="button opportunity-button"
            href="mailto:hello@moolsocial.com?subject=MoolSocial%20India%20Opportunity"
          >
            Email your résumé or profile
          </a>
          <span className="opportunity-note">
            Mention your city, experience and preferred role. MoolSocial does
            not charge application or recruitment fees.
          </span>
        </div>

        <div className="social-card">
          <p className="eyebrow dark">Build the community before launch</p>
          <h2>Follow MoolSocial. Grow with MoolSocial.</h2>
          <p>
            Follow MoolSocial on X, YouTube, Instagram, Facebook and LinkedIn
            for launch news, opportunities, creator updates and business
            stories. Until each verified profile link is published, email us
            for the official account.
          </p>
          <div className="social-list" aria-label="MoolSocial social channels">
            <a href="mailto:hello@moolsocial.com?subject=Official%20MoolSocial%20X%20profile">
              <span className="social-brand-icon social-brand-icon-x" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M14.234 10.162 22.977 0h-2.072l-7.591 8.824L7.251 0H.258l9.168 13.343L.258 24H2.33l8.016-9.318L16.749 24h6.993zm-2.837 3.299-.929-1.329L3.076 1.56h3.182l5.965 8.532.929 1.329 7.754 11.09h-3.182z" /></svg>
              </span>
              <span>X</span>
              <strong>MoolSocial</strong>
              <small>Request link</small>
            </a>
            <a href="mailto:hello@moolsocial.com?subject=Official%20MoolSocial%20YouTube%20channel">
              <span className="social-brand-icon social-brand-icon-youtube" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814ZM9.545 15.568V8.432L15.818 12l-6.273 3.568Z" /></svg>
              </span>
              <span>YouTube</span>
              <strong>MoolSocial</strong>
              <small>Request link</small>
            </a>
            <a href="mailto:hello@moolsocial.com?subject=Official%20MoolSocial%20Instagram%20profile">
              <span className="social-brand-icon social-brand-icon-instagram" aria-hidden="true">
                <svg viewBox="0 0 448 512"><path d="M224.3 141a115 115 0 1 0-.6 230 115 115 0 1 0 .6-230Zm-.6 40.4a74.6 74.6 0 1 1 .6 149.2 74.6 74.6 0 1 1-.6-149.2Zm93.4-45.1a26.8 26.8 0 1 1 53.6 0 26.8 26.8 0 1 1-53.6 0Zm129.7 27.2c-1.7-35.9-9.9-67.7-36.2-93.9-26.2-26.2-58-34.4-93.9-36.2-37-2.1-147.9-2.1-184.9 0-35.8 1.7-67.6 9.9-93.9 36.1S3.5 127.5 1.7 163.4c-2.1 37-2.1 147.9 0 184.9 1.7 35.9 9.9 67.7 36.2 93.9s58 34.4 93.9 36.2c37 2.1 147.9 2.1 184.9 0 35.9-1.7 67.7-9.9 93.9-36.2 26.2-26.2 34.4-58 36.2-93.9 2.1-37 2.1-147.8 0-184.8ZM399 388c-7.8 19.6-22.9 34.7-42.6 42.6-29.5 11.7-99.5 9-132.1 9s-102.7 2.6-132.1-9c-19.6-7.8-34.7-22.9-42.6-42.6-11.7-29.5-9-99.5-9-132.1s-2.6-102.7 9-132.1c7.8-19.6 22.9-34.7 42.6-42.6 29.5-11.7 99.5-9 132.1-9s102.7-2.6 132.1 9c19.6 7.8 34.7 22.9 42.6 42.6 11.7 29.5 9 99.5 9 132.1s2.7 102.7-9 132.1Z" /></svg>
              </span>
              <span>Instagram</span>
              <strong>MoolSocial</strong>
              <small>Request link</small>
            </a>
            <a href="mailto:hello@moolsocial.com?subject=Official%20MoolSocial%20Facebook%20page">
              <span className="social-brand-icon social-brand-icon-facebook" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103.513.061.894.126 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z" /></svg>
              </span>
              <span>Facebook</span>
              <strong>MoolSocial</strong>
              <small>Request link</small>
            </a>
            <a href="mailto:hello@moolsocial.com?subject=Official%20MoolSocial%20LinkedIn%20page">
              <span className="social-brand-icon social-brand-icon-linkedin" aria-hidden="true">
                <img alt="" height="542" src="/social-linkedin.png" width="606" />
              </span>
              <span>LinkedIn</span>
              <strong>MoolSocial</strong>
              <small>Request link</small>
            </a>
          </div>
          <div className="community-callout">
            <span>For everyone</span>
            <p>
              People, job applicants, freelancers, creators, businesses,
              retailers, wholesalers and delivery partners can register early
              interest before the 24 October 2026 launch.
            </p>
          </div>
          <p className="social-pending">
            Verified profile links will activate here as each official account
            goes live.
          </p>
        </div>
      </section>

      <section className="waitlist-section shell" id="early-access">
        <div className="waitlist-copy">
          <p className="eyebrow dark">Founding access</p>
          <h2>Be part of MoolSocial from day one.</h2>
          <p>
            Join the early-access list now. We will contact you only about
            MoolSocial launch access, relevant opportunities and important
            product updates.
          </p>
          <div className="selected-purpose">
            <span>Your selected purpose</span>
            <strong>{activeRole.shortName}</strong>
            <p>{activeRole.promise}</p>
          </div>
        </div>

        <div className="form-card">
          <div className="role-picker" aria-label="Choose how you want to join">
            {roles.map((role) => (
              <button
                aria-pressed={selectedRole === role.id}
                className={selectedRole === role.id ? "active" : ""}
                key={role.id}
                onClick={() => setSelectedRole(role.id)}
                type="button"
              >
                {role.shortName}
              </button>
            ))}
          </div>

          <form onSubmit={submitWaitlist}>
            <label>
              Your name
              <input
                autoComplete="name"
                minLength={2}
                name="name"
                placeholder="What should we call you?"
                required
                type="text"
              />
            </label>
            <label>
              Email address
              <input
                autoComplete="email"
                name="email"
                placeholder="name@domain.com"
                required
                type="email"
              />
            </label>
            <label>
              City
              <input
                autoComplete="address-level2"
                minLength={2}
                name="city"
                placeholder="Your city"
                required
                type="text"
              />
            </label>
            <label className="honeypot" aria-hidden="true">
              Website
              <input
                autoComplete="off"
                name="website"
                tabIndex={-1}
                type="text"
              />
            </label>
            <label className="consent">
              <input name="consent" required type="checkbox" />
              <span>
                I agree to receive MoolSocial early-access and launch updates. I
                can unsubscribe anytime.
              </span>
            </label>
            <button
              className="button button-submit"
              disabled={status === "submitting"}
              type="submit"
            >
              {status === "submitting"
                ? "Saving your place…"
                : `Join — ${activeRole.shortName}`}
            </button>
          </form>

          {message ? (
            <div
              className={`form-message ${status}`}
              role={status === "error" ? "alert" : "status"}
            >
              <p>{message}</p>
              {result ? (
                <button onClick={shareInvite} type="button">
                  Share my invite link
                </button>
              ) : null}
            </div>
          ) : null}

          <p className="privacy-note">
            We collect only the details needed to manage early access. No
            payment is required.
          </p>
        </div>
      </section>

      <footer>
        <div className="shell footer-content">
          <a className="footer-brand" href="#top">
            MoolSocial
          </a>
          <nav className="footer-links" aria-label="Legal and support">
            <a href="/privacy">Privacy</a>
            <a href="/terms">Terms</a>
            <a href="/support">Support</a>
            <a href="mailto:hello@moolsocial.com?subject=MoolSocial%20contact">
              Contact
            </a>
          </nav>
          <a href="mailto:hello@moolsocial.com">hello@moolsocial.com</a>
          <p>© {new Date().getFullYear()} SuperMandi Tech Pvt Ltd</p>
        </div>
      </footer>
    </main>
  );
}
