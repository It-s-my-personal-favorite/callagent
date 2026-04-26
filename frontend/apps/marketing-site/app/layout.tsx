import type { Metadata, Viewport } from "next"
import { Geist, Geist_Mono } from "next/font/google"
import Script from "next/script"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { THEME_BOOT_SCRIPT } from "@/lib/theme-cookie"
import { APP_NAME, getSiteUrl } from "@/lib/site-config"
import "./globals.css"

const geistSans = Geist({
  subsets: ["latin"],
  variable: "--font-geist-sans",
})

const geistMono = Geist_Mono({
  subsets: ["latin"],
  variable: "--font-geist-mono",
})

const siteUrl = getSiteUrl()

export const metadata: Metadata = {
  title: `${APP_NAME} – Admin-Telefon-App`,
  description:
    "CallAgent bündelt Live-Anrufe, Historie, Kundenprofile, Sperrlisten und Sprach-API-Steuerung in einer übersichtlichen Admin-Oberfläche. Hilfe-Telefon für Seniorinnen und Senior sowie Menschen mit Einschränkungen.",
  keywords: [
    "Telefonie Admin",
    "Anrufverwaltung",
    "Call Center",
    "Voice API",
    "Hilfetelefon",
    "Barrierefreiheit",
  ],
  authors: [{ name: APP_NAME }],
  creator: APP_NAME,
  icons: {
    icon: [{ url: "/icon.svg", type: "image/svg+xml" }],
    shortcut: [{ url: "/icon.svg", type: "image/svg+xml" }],
    apple: "/icon.svg",
  },
  openGraph: {
    type: "website",
    locale: "de_DE",
    url: siteUrl,
    title: `${APP_NAME} – Admin-Telefon-App`,
    description:
      "Zentrale Steuerung Ihrer eingehenden Anrufe: Live, Historie, Kunden, Moderation, Voice-API – mit kostenfreier Hotline-Hilfe.",
    siteName: APP_NAME,
  },
  twitter: {
    card: "summary_large_image",
    title: `${APP_NAME} – Admin-Telefon-App`,
    description: "Admin-Oberfläche für eingehende Anrufe, Transkripte und Voice-API.",
  },
  robots: {
    index: true,
    follow: true,
  },
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#0f0f14" },
  ],
  width: "device-width",
  initialScale: 1,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="de" suppressHydrationWarning data-scroll-behavior="smooth">
      <head>
        <link rel="icon" href="/icon.svg" type="image/svg+xml" />
      </head>
      <body className={`${geistSans.variable} ${geistMono.variable} font-sans antialiased`}>
        <Script
          id="callagent-theme-boot"
          strategy="beforeInteractive"
          dangerouslySetInnerHTML={{ __html: THEME_BOOT_SCRIPT }}
        />
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem={false}
          disableTransitionOnChange={false}
        >
          {children}
          <Analytics />
        </ThemeProvider>
      </body>
    </html>
  )
}
