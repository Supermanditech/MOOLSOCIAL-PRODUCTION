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
      "Build a trusted work record through local jobs, delivery, sales, service and outcome-based assignments.",
    action: "Join for work",
  },
  {
    id: "business",
    number: "04",
    name: "Businesses",
    shortName: "Grow my business",
    promise: "Reach customers, creators and local talent from one place.",
    description:
      "Launch products, demand campaigns, sales targets and specialised offers for the people you serve.",
    action: "Join as a business",
  },
];

const launchDate = new Date("2026-10-16T09:00:00+05:30");

type SignupResult = {
  referralUrl: string;
  existing: boolean;
};

export function LandingPage() {
  const [selectedRole, setSelectedRole] = useState<RoleId>("member");
  const [status, setStatus] = useState<
    "idle" | "submitting" | "success" | "error"
  >("idle");
  const [message, setMessage] = useState("");
  const [result, setResult] = useState<SignupResult | null>(null);
  const [daysToLaunch, setDaysToLaunch] = useState(90);
  const activeRole = useMemo(
    () => roles.find((role) => role.id === selectedRole) ?? roles[0],
    [selectedRole],
  );

  useEffect(() => {
    const updateCountdown = () => {
      const remaining = Math.max(0, launchDate.getTime() - Date.now());
      setDaysToLaunch(Math.ceil(remaining / 86_400_000));
    };
    updateCountdown();
    const timer = window.setInterval(updateCountdown, 60_000);
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
            <span className="brand-tagline">India Ka Socio Commerce App</span>
          </a>
          <a className="nav-action" href="#early-access">
            Join early access
          </a>
        </nav>

        <div className="hero-content shell">
          <div className="hero-copy">
            <p className="eyebrow">Launching first in India</p>
            <h1>
              One app.
              <span>More ways to live, earn and grow.</span>
            </h1>
            <p className="hero-intro">
              MoolSocial is bringing people, creators, work and businesses into
              one outcome-driven network.
            </p>
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
            <div className="launch-date">
              <div>
                <span>Public launch target</span>
                <strong>16 October 2026</strong>
              </div>
              <p>
                <strong>{daysToLaunch}</strong>
                <span>{daysToLaunch === 1 ? "day" : "days"} remaining</span>
              </p>
            </div>
          </div>

          <div className="network-card" aria-label="MoolSocial network preview">
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
            <p className="network-foot">
              Choose your intent. Reach the outcome. Build your value.
            </p>
          </div>
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
          <h2>Four ways to join. One connected economy.</h2>
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
            We are inviting interest for pre-launch roles, creator
            partnerships, city operations, business onboarding, field work and
            verified earning opportunities across India.
          </p>
          <a
            className="button opportunity-button"
            href="mailto:hello@moolsocial.com?subject=MoolSocial%20India%20Opportunity"
          >
            Contact hello@moolsocial.com
          </a>
          <span className="opportunity-note">
            Mention your city, experience and the role or partnership you want.
          </span>
        </div>

        <div className="social-card">
          <p className="eyebrow dark">Build the community before launch</p>
          <h2>Follow MoolSocial. Grow with MoolSocial.</h2>
          <p>
            Follow <strong>@MoolSocial</strong>, turn on updates and invite
            people who want to buy, create, work or grow a business.
          </p>
          <div className="social-list" aria-label="MoolSocial social channels">
            <div>
              <span>X</span>
              <strong>@MoolSocial</strong>
              <small>Follow</small>
            </div>
            <div>
              <span>YouTube</span>
              <strong>@MoolSocial</strong>
              <small>Subscribe</small>
            </div>
            <div>
              <span>Instagram</span>
              <strong>@MoolSocial</strong>
              <small>Follow</small>
            </div>
            <div>
              <span>Facebook</span>
              <strong>@MoolSocial</strong>
              <small>Follow</small>
            </div>
          </div>
          <div className="creator-callout">
            <span>For creators</span>
            <p>
              Start building genuine followers now. Your trusted audience and
              consistent content can unlock verified campaigns and earning
              opportunities when MoolSocial launches.
            </p>
          </div>
          <p className="social-pending">
            Official profile links will activate here after the social accounts
            are verified.
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
                placeholder="you@example.com"
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
          <p>India Ka Socio Commerce App</p>
          <a href="mailto:hello@moolsocial.com">hello@moolsocial.com</a>
          <p>© {new Date().getFullYear()} SuperMandi Tech Pvt Ltd</p>
        </div>
      </footer>
    </main>
  );
}
