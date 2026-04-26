"use client"

import { Badge } from "@/components/ui/badge"
import {
  Activity,
  BarChart2,
  Headphones,
  ListChecks,
  MessageSquare,
  Server,
  Settings2,
  ShieldBan,
  UserCircle2,
} from "lucide-react"

const features = [
  {
    icon: Activity,
    title: "Live-Anrufe & Dashboard",
    description:
      "Aktive Gespräche in Echtzeit sehen, priorisieren und schnell den passenden Call öffnen.",
    highlight: true,
  },
  {
    icon: ListChecks,
    title: "Historie & Suche",
    description:
      "Vergangene Anrufe sortieren, filtern und Details inkl. Metriken und Status nachvollziehen.",
    highlight: true,
  },
  {
    icon: UserCircle2,
    title: "Kundenprofi",
    description:
      "Wiederkehrende Anrufer:innen bündeln, Statistiken und frühere Kontakte pro Nummer anzeigen.",
    highlight: false,
  },
  {
    icon: Headphones,
    title: "Mitschnitt & Transkript",
    description:
      "Aufnahmen abspielen, Zeitleiste, Transkripte lesen – ideal für Review und Qualitätssicherung.",
    highlight: false,
  },
  {
    icon: MessageSquare,
    title: "Notizen & interne Review",
    description:
      "Gespräche kommentieren, interne Bewertung und Feedback direkt an der Session festhalten.",
    highlight: false,
  },
  {
    icon: ShieldBan,
    title: "Moderation & Sperre",
    description:
      "Nötige Sperrungen verwalten und mit Begründung versehen, um Missbrauch sichtbar zu machen.",
    highlight: false,
  },
  {
    icon: Settings2,
    title: "Voice-API-Einstellungen",
    description:
      "Backend-URL, Zugangsdaten und Verbindungstest – Konfiguration an einem zentralen Ort.",
    highlight: false,
  },
  {
    icon: Server,
    title: "API-Kontrolle & Health",
    description:
      "Serverstatus, Quellen (z. B. Telefonie-Anbieter) und regelmäßige Health-Checks im Blick behalten.",
    highlight: false,
  },
  {
    icon: BarChart2,
    title: "Export & Prozesse",
    description:
      "Gesprächszusammenfassung als PDF exportieren (je nach App-Build) – für Doku an Kolleg:innen.",
    highlight: false,
  },
] as const

export function Features() {
  return (
    <section id="funktionen" className="py-10 sm:py-20 lg:py-28 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-7 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-primary text-xs">
            Funktionen
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Was die Admin-App leistet
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            CallAgent verbindet Telefonie-Backend, Audio und Ihre Abläufe in einer Oberfläche – von der
            Live-Ansicht bis zur technischen Anbindung.
          </p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-3 gap-2.5 sm:gap-5">
          {features.map((feature) => (
            <div
              key={feature.title}
              className={`group relative rounded-xl border p-3 sm:p-5 transition-all duration-300 hover:shadow-md ${
                feature.highlight
                  ? "border-primary/50 bg-primary/5 hover:border-primary hover:bg-primary/10"
                  : "border-border/50 bg-card/50 hover:border-border hover:bg-card"
              }`}
            >
              {feature.highlight && (
                <div className="absolute -top-2.5 right-3">
                  <Badge className="bg-primary text-primary-foreground text-xs px-2 py-0.5">Kern</Badge>
                </div>
              )}
              <div
                className={`flex h-9 w-9 sm:h-11 sm:w-11 items-center justify-center rounded-xl mb-3 ${
                  feature.highlight
                    ? "bg-primary/20 border border-primary/30"
                    : "bg-secondary/50 border border-border/50 group-hover:bg-primary/10 group-hover:border-primary/20"
                }`}
              >
                <feature.icon
                  className={`h-4 w-4 sm:h-5 sm:w-5 ${
                    feature.highlight
                      ? "text-primary"
                      : "text-muted-foreground group-hover:text-primary"
                  } transition-colors`}
                />
              </div>
              <h3 className="text-xs sm:text-base font-semibold mb-1 leading-tight">{feature.title}</h3>
              <p className="text-xs text-muted-foreground leading-relaxed hidden sm:block">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
