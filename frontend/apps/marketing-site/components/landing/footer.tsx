"use client"

import Link from "next/link"
import { Mail, Headphones } from "lucide-react"
import { APP_NAME, getHelpPhoneDisplay, getHelpPhoneTelHref, getSiteUrl, getSupportEmail } from "@/lib/site-config"

const footerLinks = {
  seite: [
    { label: "Funktionen", href: "/#funktionen" },
    { label: "Ablauf", href: "/#ablauf" },
    { label: "Hilfe-Telefon", href: "/#hilfe" },
    { label: "Barrierefreiheit", href: "/#barrierefrei" },
    { label: "FAQ", href: "/#faq" },
  ],
  rechtliches: [
    { label: "Impressum", href: "/impressum" },
    { label: "Datenschutz", href: "/datenschutz" },
    { label: "AGB", href: "/agb" },
  ],
}

export function Footer() {
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const email = getSupportEmail()
  const siteUrl = getSiteUrl()

  return (
    <footer className="border-t border-border/50 bg-card/30">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="py-5 sm:py-12 lg:py-14 grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-x-4 gap-y-5 sm:gap-x-6 sm:gap-y-8 lg:gap-12">
          <div className="col-span-2 md:col-span-3 lg:col-span-2">
            <Link href="/" className="inline-flex items-center gap-2 mb-2 sm:mb-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/15 border border-primary/30">
                <Headphones className="h-4 w-4 text-primary" />
              </div>
              <span className="font-bold text-lg">{APP_NAME}</span>
            </Link>
            <p className="text-muted-foreground text-[11px] sm:text-sm leading-snug sm:leading-relaxed mb-2.5 sm:mb-4 max-w-sm">
              Admin-Oberfläche für eingehende Anrufe: Live, Historie, Kunden, Voice-API und
              Moderation – mit kostenfreier Hilfe per Telefon für alle, die lieber sprechen als
              schreiben.
            </p>

            <div className="flex flex-col gap-2 sm:gap-3 text-xs sm:text-sm text-muted-foreground">
              <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                <Mail className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-primary shrink-0" />
                <a
                  href={`mailto:${email}`}
                  className="hover:text-foreground transition-colors truncate"
                >
                  {email}
                </a>
              </div>
              <div className="flex items-center gap-2 sm:gap-3">
                <Headphones className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-primary shrink-0" />
                <a href={helpTel} className="hover:text-foreground transition-colors font-medium">
                  Hilfe: {helpDisplay}
                </a>
              </div>
              <p className="text-[11px] text-muted-foreground/80">
                Website:{" "}
                <a href={siteUrl} className="hover:text-foreground underline-offset-2 hover:underline">
                  {siteUrl.replace(/^https?:\/\//, "")}
                </a>
              </p>
            </div>
          </div>

          <div>
            <h4 className="font-semibold text-xs sm:text-base mb-1.5 sm:mb-4 text-muted-foreground sm:text-foreground">
              Seite
            </h4>
            <ul className="space-y-1 sm:space-y-3">
              {footerLinks.seite.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-xs sm:text-sm text-muted-foreground hover:text-foreground transition-colors leading-tight block py-0.5 sm:py-0"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-xs sm:text-base mb-1.5 sm:mb-4 text-muted-foreground sm:text-foreground">
              Rechtliches
            </h4>
            <ul className="space-y-1 sm:space-y-3">
              {footerLinks.rechtliches.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-xs sm:text-sm text-muted-foreground hover:text-foreground transition-colors leading-tight block py-0.5 sm:py-0"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div className="col-span-2 md:col-span-1">
            <h4 className="font-semibold text-xs sm:text-base mb-1.5 sm:mb-4 text-muted-foreground sm:text-foreground">
              Notfall-Info
            </h4>
            <p className="text-[11px] sm:text-sm text-muted-foreground leading-relaxed">
              Diese Hotline ersetzt keine Notruf-112/110-Leitungen. Bei medizinischen und polizeilichen
              Notfällen wählen Sie die offiziellen Notrufnummern.
            </p>
          </div>
        </div>

        <div className="py-3 sm:py-6 border-t border-border/50 flex flex-row flex-wrap justify-between items-center gap-x-3 gap-y-1.5">
          <p className="text-[11px] sm:text-sm text-muted-foreground leading-tight">
            © {new Date().getFullYear()} {APP_NAME}. Alle Rechte vorbehalten.
          </p>
        </div>
      </div>
    </footer>
  )
}
