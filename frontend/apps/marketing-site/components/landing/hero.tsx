import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { HeartHandshake, Phone, Smile, UserRound } from "lucide-react"
import { getAppUrl, getHelpPhoneDisplay, getHelpPhoneTelHref } from "@/lib/site-config"

export function Hero() {
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const appUrl = getAppUrl()

  return (
    <section className="relative flex items-center pt-14 sm:pt-16 overflow-hidden min-h-[88svh] sm:min-h-[100svh]">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-1/4 left-1/4 w-64 h-64 sm:w-96 sm:h-96 bg-primary/20 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-64 h-64 sm:w-96 sm:h-96 bg-accent/20 rounded-full blur-3xl" />
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f1f1f_1px,transparent_1px),linear-gradient(to_bottom,#1f1f1f_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_110%)]" />
      </div>

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8 sm:py-16 lg:py-24 w-full">
        <div className="grid lg:grid-cols-2 gap-6 sm:gap-8 lg:gap-20 items-center">
          <div className="text-center lg:text-left">
            <Badge
              variant="outline"
              className="mb-3 sm:mb-4 px-2.5 sm:px-3 py-1 border-primary/50 text-foreground text-[11px] sm:text-sm"
            >
              Hilfe-Telefon · für Sie da
            </Badge>

            <h1 className="text-2xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold tracking-tight leading-tight text-balance">
              Rufen Sie an – wir helfen{" "}
              <span className="text-primary">persönlich</span> und verständlich
            </h1>

            <p className="mt-3 sm:mt-4 text-sm sm:text-lg text-foreground/85 leading-relaxed max-w-xl mx-auto lg:mx-0">
              Unsere kostenfreie Hotline richtet sich an ältere Menschen und an alle, die Unterstützung
              brauchen: beim Lesen von Briefen, bei Fragen zur Technik oder wenn Ihnen das Formulieren
              schwerfällt. Sie erklären uns in Ruhe, worum es geht – wir antworten ohne Fachchinesisch.
            </p>

            <div className="mt-5 sm:mt-6 flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center lg:justify-start">
              <Button
                size="lg"
                className="min-h-12 bg-primary hover:bg-primary/90 text-primary-foreground px-6"
                asChild
              >
                <a href={helpTel} className="inline-flex items-center gap-2">
                  <Phone className="h-4 w-4 shrink-0" aria-hidden />
                  Hotline: {helpDisplay}
                </a>
              </Button>
              <Button size="lg" variant="outline" className="min-h-12 px-6" asChild>
                <a href={appUrl}>Zur App</a>
              </Button>
            </div>

            <p className="mt-3 text-xs sm:text-sm text-foreground/70 max-w-xl mx-auto lg:mx-0">
              „Zur App“ nur für eingeloggte Mitarbeitende – für Hilfe am Telefon genügt der erste Button.
            </p>

            <div className="mt-6 flex flex-wrap gap-x-6 gap-y-3 justify-center lg:justify-start text-xs sm:text-sm text-foreground/80">
              <div className="flex items-center gap-1.5">
                <UserRound className="h-3.5 w-3.5 text-primary shrink-0" aria-hidden />
                <span>Echte Menschen, kein Roboter</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Smile className="h-3.5 w-3.5 text-primary shrink-0" aria-hidden />
                <span>Ruhig &amp; freundlich</span>
              </div>
              <div className="flex items-center gap-1.5">
                <HeartHandshake className="h-3.5 w-3.5 text-primary shrink-0" aria-hidden />
                <span>Barrierebewusst</span>
              </div>
            </div>
          </div>

          <div className="relative hidden sm:block">
            <div className="relative rounded-2xl border border-border/50 bg-card/50 p-5 sm:p-6 shadow-2xl backdrop-blur-sm">
              <p className="text-sm font-medium text-foreground mb-4">So ungefähr läuft ein Anruf ab</p>
              <ol className="space-y-4">
                {[
                  "Sie wählen die Nummer – wir melden uns mit Namen.",
                  "Sie sagen in eigenen Worten, was Sie beschäftigt.",
                  "Wir erklären Schritt für Schritt und fragen nach, ob es passt.",
                  "Wenn Sie möchten, notieren wir eine E-Mail-Adresse für eine kurze Zusammenfassung.",
                ].map((step, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/15 text-sm font-semibold text-primary">
                      {i + 1}
                    </span>
                    <span className="text-sm text-foreground/90 leading-relaxed pt-0.5">{step}</span>
                  </li>
                ))}
              </ol>
              <div className="mt-5 rounded-lg border border-primary/30 bg-primary/5 px-4 py-3 text-sm text-foreground/90">
                <strong className="text-foreground">Wichtig:</strong> Bei Notfällen wählen Sie bitte 112
                bzw. 110 – unsere Hotline ist keine Notrufleitung.
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
