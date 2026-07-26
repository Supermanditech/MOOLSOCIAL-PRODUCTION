import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const siteUrl = "https://moolsocial.com";
const title = "MoolSocial — India Ka Social Commerce App";
const description =
  "MoolSocial is building an AI-enabled social commerce platform that brings content, commerce, services, mobility, payments and work together across India.";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title,
  description,
  applicationName: "MoolSocial",
  alternates: {
    canonical: "/",
    languages: {
      "en-IN": "/",
    },
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  openGraph: {
    title: "MoolSocial — AI-Enabled Social Commerce",
    description:
      "Content, commerce, services, mobility, payments and work in one MoolSocial experience. Launching across India on 24 October 2026.",
    type: "website",
    url: siteUrl,
    siteName: "MoolSocial",
    locale: "en_IN",
    images: [
      {
        url: "/og-2026-10-24.png",
        width: 1536,
        height: 1024,
        type: "image/png",
        alt: "MoolSocial — AI-Enabled Social Commerce",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "MoolSocial — AI-Enabled Social Commerce",
    description:
      "Content, commerce, services, mobility, payments and work in one MoolSocial experience. Launching across India on 24 October 2026.",
    images: ["/og-2026-10-24.png"],
  },
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
  },
  manifest: "/site.webmanifest",
};

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": `${siteUrl}/#organization`,
      name: "MoolSocial",
      legalName: "SuperMandi Tech Pvt Ltd",
      url: `${siteUrl}/`,
      logo: {
        "@type": "ImageObject",
        url: `${siteUrl}/moolsocial-workspace-logo.png`,
        width: 320,
        height: 132,
      },
      email: "hello@moolsocial.com",
      areaServed: {
        "@type": "Country",
        name: "India",
      },
      slogan: "India Ka Social Commerce App",
    },
    {
      "@type": "WebSite",
      "@id": `${siteUrl}/#website`,
      url: `${siteUrl}/`,
      name: "MoolSocial",
      description:
        "MoolSocial is building an AI-enabled social commerce platform across India.",
      inLanguage: "en-IN",
      publisher: {
        "@id": `${siteUrl}/#organization`,
      },
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en-IN">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(structuredData).replace(/</g, "\\u003c"),
          }}
        />
        {children}
      </body>
    </html>
  );
}
